#!/usr/bin/env bash
set -euo pipefail

db_url="${SUPABASE_DB_URL:-}"
if [[ -z "$db_url" ]]; then
  db_url="$(supabase status -o env | sed -n 's/^DB_URL=//p' | tr -d '"' | head -n 1)"
fi
if [[ -z "$db_url" ]]; then
  echo "Supabase did not report a local DB_URL." >&2
  exit 1
fi

participant_one="11111111-1111-4111-8111-111111111121"
participant_two="11111111-1111-4111-8111-111111111122"
organizer="11111111-1111-4111-8111-111111111123"
activity="22222222-2222-4222-8222-222222222229"
first_log="$(mktemp)"
second_log="$(mktemp)"

cleanup() {
  psql -X "$db_url" -v ON_ERROR_STOP=1 -q -c \
    "delete from public.activities where id = '$activity';
     delete from auth.users where id in ('$participant_one', '$participant_two', '$organizer');" \
    >/dev/null 2>&1 || true
  rm -f "$first_log" "$second_log"
}
trap cleanup EXIT

psql -X "$db_url" -v ON_ERROR_STOP=1 -q <<SQL
insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('$participant_one', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'capacity-one@example.test', '', now(),
   '{"provider":"email","providers":["email"]}', '{"display_name":"Capacity One"}', now(), now()),
  ('$participant_two', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'capacity-two@example.test', '', now(),
   '{"provider":"email","providers":["email"]}', '{"display_name":"Capacity Two"}', now(), now()),
  ('$organizer', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'capacity-organizer@example.test', '', now(),
   '{"provider":"email","providers":["email"]}', '{"display_name":"Capacity Organizer"}', now(), now());

update public.profiles set role = 'organizer' where id = '$organizer';

insert into public.activities (
  id, organizer_id, title, category, place, starts_at, capacity, points,
  description, impact_measure, status
) values (
  '$activity', '$organizer', 'Concurrent capacity test', 'Clean-ups',
  'Test Park', now() + interval '2 days', 1, 0,
  'A valid future activity for concurrent capacity validation.',
  'Bags collected', 'published'
);
SQL

first_sql="
BEGIN;
SET LOCAL request.jwt.claims = '{\"sub\":\"$participant_one\",\"role\":\"authenticated\"}';
SELECT id FROM public.activities WHERE id = '$activity' FOR UPDATE;
SELECT pg_sleep(2);
SELECT public.join_activity('$activity');
COMMIT;
"
psql -X "$db_url" -v ON_ERROR_STOP=1 -q -c "$first_sql" >"$first_log" 2>&1 &
first_pid=$!
sleep 0.2

second_sql="
SET request.jwt.claims = '{\"sub\":\"$participant_two\",\"role\":\"authenticated\"}';
SELECT public.join_activity('$activity');
"
psql -X "$db_url" -v ON_ERROR_STOP=1 -q -c "$second_sql" >"$second_log" 2>&1 &
second_pid=$!

wait "$first_pid"
if wait "$second_pid"; then
  echo "Both concurrent joins succeeded for a capacity-one activity." >&2
  exit 1
fi
if ! grep -Fq "This activity is fully booked." "$second_log"; then
  cat "$second_log" >&2
  echo "The second concurrent join failed for an unexpected reason." >&2
  exit 1
fi

active_count="$(psql -X "$db_url" -Atq -v ON_ERROR_STOP=1 -c \
  "select count(*) from public.activity_signups where activity_id = '$activity' and status in ('registered', 'attended')")"
if [[ "$active_count" != "1" ]]; then
  echo "Expected exactly one active registration; found $active_count." >&2
  exit 1
fi

echo "Concurrent capacity check passed: exactly one registration was accepted."
