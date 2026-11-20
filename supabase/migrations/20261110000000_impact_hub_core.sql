-- Go Green Mates Impact Hub schema.
-- Apply this migration to a fresh Supabase project before configuring the app.
-- Role promotion is an operator action; public clients cannot change profile roles.

create table public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  display_name text not null check (char_length(display_name) between 1 and 80),
  role text not null default 'participant'
    check (role in ('participant', 'organizer', 'admin')),
  created_at timestamptz not null default now()
);

create table public.activities (
  id uuid primary key default gen_random_uuid(),
  organizer_id uuid not null references public.profiles (id) on delete restrict,
  title text not null check (char_length(trim(title)) between 5 and 140),
  category text not null check (
    category in ('Tree planting', 'Clean-ups', 'Learning', 'Clean energy')
  ),
  place text not null check (char_length(trim(place)) between 2 and 160),
  starts_at timestamptz not null,
  capacity integer not null check (capacity between 1 and 5000),
  points integer not null default 0 check (points between 0 and 10000),
  description text not null check (char_length(trim(description)) between 20 and 3000),
  impact_measure text not null check (char_length(trim(impact_measure)) between 3 and 300),
  impact_source_url text check (
    impact_source_url is null or impact_source_url like 'https://%'
  ),
  image_url text check (image_url is null or image_url like 'https://%'),
  status text not null default 'published'
    check (status in ('draft', 'published', 'cancelled')),
  created_at timestamptz not null default now()
);

create table public.activity_signups (
  id uuid primary key default gen_random_uuid(),
  activity_id uuid not null references public.activities (id) on delete cascade,
  participant_id uuid not null references public.profiles (id) on delete cascade,
  status text not null default 'registered'
    check (status in ('registered', 'attended', 'cancelled')),
  created_at timestamptz not null default now(),
  unique (activity_id, participant_id)
);

create table public.point_ledger (
  id uuid primary key default gen_random_uuid(),
  participant_id uuid not null references public.profiles (id) on delete cascade,
  signup_id uuid not null unique references public.activity_signups (id) on delete cascade,
  points integer not null check (points >= 0),
  created_at timestamptz not null default now()
);

create index activities_status_starts_at_idx
  on public.activities (status, starts_at);
create index activities_organizer_id_idx
  on public.activities (organizer_id);
create index activity_signups_participant_created_idx
  on public.activity_signups (participant_id, created_at desc);
create index activity_signups_activity_status_idx
  on public.activity_signups (activity_id, status);
create index point_ledger_participant_idx
  on public.point_ledger (participant_id);

-- New sign-ups always start as participants. Role changes are performed by an
-- authorized operator through the Supabase SQL editor or a trusted backend.
create or replace function public.create_profile_for_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_name text;
begin
  requested_name := nullif(
    left(trim(coalesce(new.raw_user_meta_data ->> 'display_name', '')), 80),
    ''
  );

  insert into public.profiles (id, display_name, role)
  values (
    new.id,
    coalesce(
      requested_name,
      nullif(split_part(coalesce(new.email, ''), '@', 1), ''),
      'Participant'
    ),
    'participant'
  )
  on conflict (id) do nothing;

  return new;
end;
$$;

create trigger on_auth_user_created_profile
  after insert on auth.users
  for each row execute function public.create_profile_for_auth_user();

-- Backfill accounts that existed before this migration.
insert into public.profiles (id, display_name, role)
select
  u.id,
  coalesce(
    nullif(
      left(trim(coalesce(u.raw_user_meta_data ->> 'display_name', '')), 80),
      ''
    ),
    nullif(split_part(coalesce(u.email, ''), '@', 1), ''),
    'Participant'
  ),
  'participant'
from auth.users as u
on conflict (id) do nothing;

-- This helper can inspect only the caller's own role and avoids recursive RLS
-- checks when policies need to grant admin access.
create or replace function public.current_user_has_role(required_role text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles as p
    where p.id = (select auth.uid())
      and p.role = required_role
  );
$$;

revoke all on function public.create_profile_for_auth_user() from public, anon, authenticated;
revoke all on function public.current_user_has_role(text) from public, anon;
grant execute on function public.current_user_has_role(text) to authenticated;

alter table public.profiles enable row level security;
alter table public.activities enable row level security;
alter table public.activity_signups enable row level security;
alter table public.point_ledger enable row level security;

create policy "profiles_select_self_or_activity_participants"
  on public.profiles
  for select
  to authenticated
  using (
    id = (select auth.uid())
    or public.current_user_has_role('admin')
    or exists (
      select 1
      from public.activity_signups as s
      join public.activities as a on a.id = s.activity_id
      where s.participant_id = profiles.id
        and a.organizer_id = (select auth.uid())
        and s.status in ('registered', 'attended')
    )
  );

create policy "activities_select_published_or_owned"
  on public.activities
  for select
  to authenticated
  using (
    status = 'published'
    or organizer_id = (select auth.uid())
    or public.current_user_has_role('admin')
  );

create policy "activities_insert_as_organizer"
  on public.activities
  for insert
  to authenticated
  with check (
    organizer_id = (select auth.uid())
    and status = 'published'
    and (
      public.current_user_has_role('organizer')
      or public.current_user_has_role('admin')
    )
  );

create policy "activity_signups_select_self_or_managed"
  on public.activity_signups
  for select
  to authenticated
  using (
    participant_id = (select auth.uid())
    or public.current_user_has_role('admin')
    or exists (
      select 1
      from public.activities as a
      where a.id = activity_signups.activity_id
        and a.organizer_id = (select auth.uid())
    )
  );

create policy "point_ledger_select_self_or_admin"
  on public.point_ledger
  for select
  to authenticated
  using (
    participant_id = (select auth.uid())
    or public.current_user_has_role('admin')
  );

-- Only authenticated users can access these objects. Participants and
-- organizers receive read access; activity creation is column-limited.
revoke all on table
  public.profiles,
  public.activities,
  public.activity_signups,
  public.point_ledger
from public, anon, authenticated;
grant usage on schema public to authenticated;
grant select on public.profiles, public.activities, public.activity_signups, public.point_ledger
  to authenticated;
grant insert (
  organizer_id,
  title,
  category,
  place,
  starts_at,
  capacity,
  points,
  description,
  impact_measure,
  impact_source_url,
  status
)
on public.activities to authenticated;

-- The view intentionally returns only public activity fields and an aggregate
-- seat count. Standard view-owner permissions let it count all registrations
-- while underlying signup rows remain protected by RLS.
create view public.activity_listing
as
select
  a.id,
  a.organizer_id,
  a.title,
  a.category,
  a.place,
  a.starts_at,
  a.capacity,
  a.points,
  a.description,
  a.impact_measure,
  a.impact_source_url,
  a.image_url,
  greatest(a.capacity - count(s.id)::integer, 0) as spots_remaining
from public.activities as a
left join public.activity_signups as s
  on s.activity_id = a.id
  and s.status in ('registered', 'attended')
where a.status = 'published'
group by
  a.id,
  a.organizer_id,
  a.title,
  a.category,
  a.place,
  a.starts_at,
  a.capacity,
  a.points,
  a.description,
  a.impact_measure,
  a.impact_source_url,
  a.image_url;

revoke all on public.activity_listing from public, anon, authenticated;
grant select on public.activity_listing to authenticated;

create or replace function public.join_activity(activity_uuid uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  selected_activity public.activities%rowtype;
  signup_id uuid;
  active_signups integer;
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Sign in to join an activity.';
  end if;

  if not public.current_user_has_role('participant') then
    raise exception using errcode = '42501', message = 'Only participant accounts can join activities.';
  end if;

  -- Lock the activity row so concurrent registrations cannot exceed capacity.
  select a.*
  into selected_activity
  from public.activities as a
  where a.id = activity_uuid
    and a.status = 'published'
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'This activity is not available.';
  end if;

  if selected_activity.starts_at <= now() then
    raise exception using errcode = '22023', message = 'This activity has already started.';
  end if;

  if exists (
    select 1
    from public.activity_signups as s
    where s.activity_id = selected_activity.id
      and s.participant_id = caller_id
  ) then
    raise exception using errcode = '23505', message = 'You are already registered for this activity.';
  end if;

  select count(*)::integer
  into active_signups
  from public.activity_signups as s
  where s.activity_id = selected_activity.id
    and s.status in ('registered', 'attended');

  if active_signups >= selected_activity.capacity then
    raise exception using errcode = '23514', message = 'This activity is fully booked.';
  end if;

  insert into public.activity_signups (activity_id, participant_id, status)
  values (selected_activity.id, caller_id, 'registered')
  returning id into signup_id;

  return signup_id;
end;
$$;

create or replace function public.verify_attendance(signup_uuid uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  signup_status text;
  signup_participant_id uuid;
  activity_organizer_id uuid;
  activity_start timestamptz;
  activity_points integer;
  awarded_points integer;
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Sign in to verify attendance.';
  end if;

  select
    s.status,
    s.participant_id,
    a.organizer_id,
    a.starts_at,
    a.points
  into
    signup_status,
    signup_participant_id,
    activity_organizer_id,
    activity_start,
    activity_points
  from public.activity_signups as s
  join public.activities as a on a.id = s.activity_id
  where s.id = signup_uuid
  for update of s;

  if not found then
    raise exception using errcode = 'P0002', message = 'Registration not found.';
  end if;

  if caller_id <> activity_organizer_id
     and not public.current_user_has_role('admin') then
    raise exception using errcode = '42501', message = 'You cannot verify this activity.';
  end if;

  if activity_start > now() then
    raise exception using errcode = '22023', message = 'Attendance can be verified only after the activity starts.';
  end if;

  if signup_status not in ('registered', 'attended') then
    raise exception using errcode = '22023', message = 'This registration cannot be verified.';
  end if;

  if signup_status = 'registered' then
    update public.activity_signups
    set status = 'attended'
    where id = signup_uuid;
  end if;

  insert into public.point_ledger (participant_id, signup_id, points)
  values (signup_participant_id, signup_uuid, activity_points)
  on conflict (signup_id) do nothing;

  select l.points
  into awarded_points
  from public.point_ledger as l
  where l.signup_id = signup_uuid;

  return awarded_points;
end;
$$;

revoke all on function public.join_activity(uuid) from public, anon;
revoke all on function public.verify_attendance(uuid) from public, anon;
grant execute on function public.join_activity(uuid) to authenticated;
grant execute on function public.verify_attendance(uuid) to authenticated;
