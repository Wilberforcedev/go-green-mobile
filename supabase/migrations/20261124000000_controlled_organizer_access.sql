-- Keep organizer access changes in an admin-only audit log and expose a guarded
-- RPC for routine role changes after the first administrator is bootstrapped.
create table public.admin_role_change_log (
  id uuid primary key default gen_random_uuid(),
  changed_by uuid not null,
  changed_user uuid not null,
  old_role text not null check (old_role in ('participant', 'organizer')),
  new_role text not null check (new_role in ('participant', 'organizer')),
  created_at timestamptz not null default now()
);

alter table public.admin_role_change_log enable row level security;
revoke all on public.admin_role_change_log from public, anon, authenticated;
grant select on public.admin_role_change_log to authenticated;

create policy "admins_read_role_change_log"
  on public.admin_role_change_log
  for select
  to authenticated
  using (public.current_user_has_role('admin'));

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
begin
  if caller_id is null then
    raise exception using errcode = '28000', message = 'Sign in to manage account access.';
  end if;

  if not public.current_user_has_role('admin') then
    raise exception using errcode = '42501', message = 'Only administrators can manage account access.';
  end if;

  if new_role not in ('participant', 'organizer') then
    raise exception using errcode = '22023', message = 'Choose participant or organizer access.';
  end if;

  select p.role
  into previous_role
  from public.profiles as p
  where p.id = target_profile_uuid
    and p.role in ('participant', 'organizer')
  for update;

  if not found then
    raise exception using errcode = 'P0002', message = 'The account was not found or is an administrator.';
  end if;

  if previous_role = new_role then
    return;
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

revoke all on function public.set_profile_role(uuid, text) from public, anon;
grant execute on function public.set_profile_role(uuid, text) to authenticated;
