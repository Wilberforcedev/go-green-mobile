-- Prevent attendance verification and point awards for cancelled activities.
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
  activity_status text;
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
    a.status,
    a.points
  into
    signup_status,
    signup_participant_id,
    activity_organizer_id,
    activity_start,
    activity_status,
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

  if activity_status <> 'published' then
    raise exception using errcode = '22023', message = 'Attendance cannot be verified for a cancelled activity.';
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
