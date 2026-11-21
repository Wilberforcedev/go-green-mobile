-- Extend participant cancellation so the activity owner and admins can also remove a signup.
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
  activity_owner uuid;
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Sign in to cancel a registration.';
  end if;

  select s.participant_id, s.status, a.starts_at, a.organizer_id
  into signup_participant, signup_status, activity_start, activity_owner
  from public.activity_signups as s
  join public.activities as a on a.id = s.activity_id
  where s.id = signup_uuid
  for update of s;

  if not found then
    raise exception using errcode = 'P0002', message = 'Registration not found.';
  end if;
  if caller_id <> signup_participant
     and caller_id <> activity_owner
     and not public.current_user_has_role('admin') then
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

revoke all on function public.cancel_activity_signup(uuid) from public, anon;
grant execute on function public.cancel_activity_signup(uuid) to authenticated;
