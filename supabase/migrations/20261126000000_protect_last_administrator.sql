-- Allow administrators to transfer access safely while preventing removal of
-- the last administrator. Keep administrator changes in the same audit log.
alter table public.admin_role_change_log
  drop constraint admin_role_change_log_old_role_check,
  drop constraint admin_role_change_log_new_role_check;

alter table public.admin_role_change_log
  add constraint admin_role_change_log_old_role_check
    check (old_role in ('participant', 'organizer', 'admin')),
  add constraint admin_role_change_log_new_role_check
    check (new_role in ('participant', 'organizer', 'admin'));

create or replace function public.set_profile_role(
  target_profile_uuid uuid,
  new_role text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  caller_id uuid := (select auth.uid());
  previous_role text;
  admin_count integer;
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Sign in to manage account access.';
  end if;

  if not public.current_user_has_role('admin') then
    raise exception using errcode = '42501', message = 'Only administrators can manage account access.';
  end if;

  if new_role is null or new_role not in ('participant', 'organizer', 'admin') then
    raise exception using errcode = '22023', message = 'Choose participant, organizer, or administrator access.';
  end if;

  -- Serialize administrator changes so two concurrent requests cannot remove
  -- the final administrator at the same time.
  perform pg_catalog.pg_advisory_xact_lock(5126910182400001::bigint);

  select p.role
  into previous_role
  from public.profiles as p
  where p.id = target_profile_uuid
    and p.role in ('participant', 'organizer', 'admin')
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'The account was not found.';
  end if;

  if previous_role = new_role then
    return;
  end if;

  if previous_role = 'admin' and new_role <> 'admin' then
    select count(*)::integer
    into admin_count
    from public.profiles as p
    where p.role = 'admin';

    if admin_count <= 1 then
      raise exception using errcode = '23514', message = 'At least one administrator must remain.';
    end if;
  end if;

  update public.profiles
  set role = new_role
  where id = target_profile_uuid;

  insert into public.admin_role_change_log (
    changed_by,
    changed_user,
    old_role,
    new_role
  ) values (
    caller_id,
    target_profile_uuid,
    previous_role,
    new_role
  );
end;
$$;
