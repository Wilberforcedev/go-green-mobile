-- Account deletion removes a participant's profile, registrations, and points.
-- Published activities remain available with their organizer identity detached.
alter table public.activities
  alter column organizer_id drop not null;

alter table public.activities
  drop constraint activities_organizer_id_fkey;

alter table public.activities
  add constraint activities_organizer_id_fkey
  foreign key (organizer_id)
  references public.profiles (id)
  on delete set null;
