-- Allow a participant to read the activity attached to their own signup,
-- including its cancellation status, without creating an RLS policy cycle.
create or replace function public.caller_has_activity_signup(activity_uuid uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.activity_signups as s
    where s.activity_id = activity_uuid
      and s.participant_id = (select auth.uid())
  );
$$;

revoke all on function public.caller_has_activity_signup(uuid) from public, anon;
grant execute on function public.caller_has_activity_signup(uuid) to authenticated;

drop policy if exists "activities_select_published_or_owned" on public.activities;
create policy "activities_select_published_or_owned"
  on public.activities
  for select
  to authenticated
  using (
    status = 'published'
    or organizer_id = (select auth.uid())
    or public.current_user_has_role('admin')
    or public.caller_has_activity_signup(id)
  );

create or replace function public.cancel_activity_signup(signup_uuid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  signup_participant uuid;
  signup_status text;
  activity_start timestamptz;
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Sign in to cancel a registration.';
  end if;

  select s.participant_id, s.status, a.starts_at
  into signup_participant, signup_status, activity_start
  from public.activity_signups as s
  join public.activities as a on a.id = s.activity_id
  where s.id = signup_uuid
  for update of s;

  if not found then
    raise exception using errcode = 'P0002', message = 'Registration not found.';
  end if;
  if signup_participant <> caller_id then
    raise exception using errcode = '42501', message = 'You cannot cancel this registration.';
  end if;
  if signup_status <> 'registered' then
    raise exception using errcode = '22023', message = 'Only a current registration can be cancelled.';
  end if;
  if activity_start <= now() then
    raise exception using errcode = '22023', message = 'Registration cannot be cancelled after the activity starts.';
  end if;

  update public.activity_signups
  set status = 'cancelled'
  where id = signup_uuid;
end;
$$;

create or replace function public.cancel_activity(activity_uuid uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  activity_organizer uuid;
  activity_start timestamptz;
  activity_status text;
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Sign in to cancel an activity.';
  end if;

  select a.organizer_id, a.starts_at, a.status
  into activity_organizer, activity_start, activity_status
  from public.activities as a
  where a.id = activity_uuid
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Activity not found.';
  end if;
  if caller_id <> activity_organizer
     and not public.current_user_has_role('admin') then
    raise exception using errcode = '42501', message = 'You cannot cancel this activity.';
  end if;
  if activity_status <> 'published' then
    raise exception using errcode = '22023', message = 'Only a published activity can be cancelled.';
  end if;
  if activity_start <= now() then
    raise exception using errcode = '22023', message = 'An activity cannot be cancelled after it starts.';
  end if;

  update public.activities
  set status = 'cancelled'
  where id = activity_uuid;
end;
$$;

revoke all on function public.cancel_activity_signup(uuid) from public, anon;
revoke all on function public.cancel_activity(uuid) from public, anon;
grant execute on function public.cancel_activity_signup(uuid) to authenticated;
grant execute on function public.cancel_activity(uuid) to authenticated;
