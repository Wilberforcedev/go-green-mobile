-- Let organizers correct the details of their own future published activities.
-- Updates are serialized with joins and cannot make capacity lower than active sign-ups.
create or replace function public.update_activity(
  activity_uuid uuid,
  new_title text,
  new_category text,
  new_place text,
  new_starts_at timestamptz,
  new_capacity integer,
  new_points integer,
  new_description text,
  new_impact_measure text,
  new_impact_source_url text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  selected_activity public.activities%rowtype;
  active_signups integer;
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Sign in to edit an activity.';
  end if;

  select a.*
  into selected_activity
  from public.activities as a
  where a.id = activity_uuid
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'Activity not found.';
  end if;

  if caller_id <> selected_activity.organizer_id
     and not public.current_user_has_role('admin') then
    raise exception using errcode = '42501', message = 'You cannot edit this activity.';
  end if;

  if selected_activity.status <> 'published'
     or selected_activity.starts_at <= now() then
    raise exception using errcode = '22023', message = 'Only a future published activity can be edited.';
  end if;

  if new_starts_at is null or new_starts_at <= now()
     or char_length(trim(coalesce(new_title, ''))) not between 5 and 140
     or new_category not in ('Tree planting', 'Clean-ups', 'Learning', 'Clean energy')
     or char_length(trim(coalesce(new_place, ''))) not between 2 and 160
     or new_capacity not between 1 and 5000
     or new_points not between 0 and 10000
     or char_length(trim(coalesce(new_description, ''))) not between 20 and 3000
     or char_length(trim(coalesce(new_impact_measure, ''))) not between 3 and 300
     or (new_impact_source_url is not null and new_impact_source_url not like 'https://%') then
    raise exception using errcode = '22023', message = 'Activity details are invalid.';
  end if;

  select count(*)::integer
  into active_signups
  from public.activity_signups as s
  where s.activity_id = activity_uuid
    and s.status in ('registered', 'attended');

  if new_capacity < active_signups then
    raise exception using errcode = '23514', message = 'Activity capacity cannot be less than current registrations.';
  end if;

  update public.activities
  set title = trim(new_title),
      category = new_category,
      place = trim(new_place),
      starts_at = new_starts_at,
      capacity = new_capacity,
      points = new_points,
      description = trim(new_description),
      impact_measure = trim(new_impact_measure),
      impact_source_url = nullif(trim(new_impact_source_url), '')
  where id = activity_uuid;
end;
$$;

revoke all on function public.update_activity(uuid, text, text, text, timestamptz, integer, integer, text, text, text)
  from public, anon;
grant execute on function public.update_activity(uuid, text, text, text, timestamptz, integer, integer, text, text, text)
  to authenticated;
