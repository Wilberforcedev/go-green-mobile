-- Reuse a participant's cancelled signup row when they rejoin the same activity.
-- The activity row lock serializes joins so capacity remains safe under contention.
create or replace function public.join_activity(activity_uuid uuid)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  selected_activity public.activities%rowtype;
  existing_signup_id uuid;
  existing_signup_status text;
  signup_id uuid;
  active_signups integer;
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Sign in to join an activity.';
  end if;

  if not public.current_user_has_role('participant') then
    raise exception using errcode = '42501', message = 'Only participant accounts can join activities.';
  end if;

  -- Serialize joins to this activity before checking its remaining capacity.
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

  select s.id, s.status
  into existing_signup_id, existing_signup_status
  from public.activity_signups as s
  where s.activity_id = selected_activity.id
    and s.participant_id = caller_id
  for update;

  if found and existing_signup_status <> 'cancelled' then
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

  if existing_signup_id is not null then
    update public.activity_signups
    set status = 'registered',
        created_at = now()
    where id = existing_signup_id;

    return existing_signup_id;
  end if;

  insert into public.activity_signups (activity_id, participant_id, status)
  values (selected_activity.id, caller_id, 'registered')
  returning id into signup_id;

  return signup_id;
end;
$$;
