begin;

select plan(33);

select has_function('public', 'cancel_activity_signup', array['uuid'], 'participant cancellation RPC exists');
select has_function('public', 'cancel_activity', array['uuid'], 'organizer cancellation RPC exists');
select ok(not has_function_privilege('anon', 'public.cancel_activity_signup(uuid)', 'EXECUTE'), 'anonymous users cannot cancel registrations');
select ok(not has_function_privilege('anon', 'public.cancel_activity(uuid)', 'EXECUTE'), 'anonymous users cannot cancel activities');
select ok(has_function_privilege('authenticated', 'public.cancel_activity_signup(uuid)', 'EXECUTE'), 'authenticated users can call the guarded registration RPC');
select ok(has_function_privilege('authenticated', 'public.cancel_activity(uuid)', 'EXECUTE'), 'authenticated users can call the guarded activity RPC');
select ok(not has_table_privilege('anon', 'public.activity_signups', 'UPDATE'), 'anonymous users cannot change registrations directly');
select ok(not has_table_privilege('authenticated', 'public.activity_signups', 'UPDATE'), 'authenticated users cannot change registrations outside the RPC');
select ok(not has_table_privilege('authenticated', 'public.activities', 'UPDATE'), 'authenticated users cannot change activity status directly');
select ok((select relrowsecurity from pg_class where oid = 'public.profiles'::regclass), 'profiles enforce row-level security');
select ok((select relrowsecurity from pg_class where oid = 'public.activity_signups'::regclass), 'registrations enforce row-level security');
select ok((select relrowsecurity from pg_class where oid = 'public.point_ledger'::regclass), 'points enforce row-level security');

insert into auth.users (
  id, instance_id, aud, role, email, encrypted_password, email_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values
  ('11111111-1111-4111-8111-111111111111', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'participant-one@example.test', '', now(),
   '{"provider":"email","providers":["email"]}', '{"display_name":"Participant One"}', now(), now()),
  ('11111111-1111-4111-8111-111111111112', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'participant-two@example.test', '', now(),
   '{"provider":"email","providers":["email"]}', '{"display_name":"Participant Two"}', now(), now()),
  ('11111111-1111-4111-8111-111111111113', '00000000-0000-0000-0000-000000000000',
   'authenticated', 'authenticated', 'organizer@example.test', '', now(),
   '{"provider":"email","providers":["email"]}', '{"display_name":"Test Organizer"}', now(), now());

update public.profiles
set role = 'organizer'
where id = '11111111-1111-4111-8111-111111111113';

insert into public.activities (
  id, organizer_id, title, category, place, starts_at, capacity, points,
  description, impact_measure, status
) values
  ('22222222-2222-4222-8222-222222222221',
   '11111111-1111-4111-8111-111111111113',
   'Future test activity', 'Tree planting', 'Test Garden', now() + interval '2 days',
   1, 0, 'A valid future activity for database integration tests.',
   'Trees planted', 'published'),
  ('22222222-2222-4222-8222-222222222222',
   '11111111-1111-4111-8111-111111111113',
   'Past test activity', 'Clean-ups', 'Test Park', now() - interval '2 days',
   5, 25, 'A valid past activity for attendance verification tests.',
   'Bags collected', 'published');

insert into public.activity_signups (
  id, activity_id, participant_id, status
) values (
  '33333333-3333-4333-8333-333333333331',
  '22222222-2222-4222-8222-222222222222',
  '11111111-1111-4111-8111-111111111112',
  'registered'
);

select has_function('public', 'join_activity', array['uuid'], 'join RPC exists');
select has_function('public', 'verify_attendance', array['uuid'], 'attendance RPC exists');
select ok(
  position(
    'FOR UPDATE' in upper(pg_get_functiondef('public.join_activity(uuid)'::regprocedure))
  ) > 0,
  'join RPC locks the activity row before checking capacity'
);

set local role authenticated;
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
  true
);

select is(
  (select count(*)::integer from public.profiles
   where id <> '11111111-1111-4111-8111-111111111111'),
  0,
  'a participant cannot read other profiles'
);
select ok(
  public.join_activity('22222222-2222-4222-8222-222222222221') is not null,
  'a participant can join an available activity'
);
select is(
  (select count(*)::integer from public.activity_signups
   where activity_id = '22222222-2222-4222-8222-222222222221'
     and participant_id = '11111111-1111-4111-8111-111111111111'),
  1,
  'joining creates one registration'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111112","role":"authenticated"}',
  true
);
select throws_ok(
  $$select public.join_activity('22222222-2222-4222-8222-222222222221')$$,
  '23514',
  'This activity is fully booked.',
  'a full activity rejects another participant'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
  true
);
select lives_ok(
  $$select public.cancel_activity_signup(
      (select id from public.activity_signups
       where activity_id = '22222222-2222-4222-8222-222222222221'
         and participant_id = '11111111-1111-4111-8111-111111111111')
    )$$,
  'a participant can cancel their own future registration'
);
select is(
  (select status from public.activity_signups
   where activity_id = '22222222-2222-4222-8222-222222222221'
     and participant_id = '11111111-1111-4111-8111-111111111111'),
  'cancelled',
  'cancellation releases the registration'
);
select ok(
  public.join_activity('22222222-2222-4222-8222-222222222221') is not null,
  'a participant can rejoin after cancelling'
);
select is(
  (select status from public.activity_signups
   where activity_id = '22222222-2222-4222-8222-222222222221'
     and participant_id = '11111111-1111-4111-8111-111111111111'),
  'registered',
  'rejoining restores the existing registration'
);
select throws_ok(
  $$select public.join_activity('22222222-2222-4222-8222-222222222221')$$,
  '23505',
  'You are already registered for this activity.',
  'a participant cannot create a duplicate active registration'
);
select throws_ok(
  $$select public.cancel_activity_signup('33333333-3333-4333-8333-333333333331')$$,
  '42501',
  'You cannot cancel this registration.',
  'a participant cannot cancel another participant registration'
);
select throws_ok(
  $select public.verify_attendance('33333333-3333-4333-8333-333333333331')$,
  '42501',
  'You cannot verify this activity.',
  'a participant cannot verify attendance'
);
select throws_ok(
  $select public.cancel_activity('22222222-2222-4222-8222-222222222221')$,
  '42501',
  'You cannot cancel this activity.',
  'a participant cannot cancel an organizer activity'
);

select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111113","role":"authenticated"}',
  true
);
select is(
  public.verify_attendance('33333333-3333-4333-8333-333333333331'),
  25,
  'the organizer awards the activity points at verification'
);
select is(
  public.verify_attendance('33333333-3333-4333-8333-333333333331'),
  25,
  'repeating verification returns the original award'
);
select lives_ok(
  $select public.cancel_activity('22222222-2222-4222-8222-222222222221')$,
  'the organizer can cancel their future activity'
);
select is(
  (select status from public.activities
   where id = '22222222-2222-4222-8222-222222222221'),
  'cancelled',
  'organizer cancellation updates the activity status'
);
select set_config(
  'request.jwt.claims',
  '{"sub":"11111111-1111-4111-8111-111111111111","role":"authenticated"}',
  true
);
select throws_ok(
  $select public.join_activity('22222222-2222-4222-8222-222222222221')$,
  'P0002',
  'This activity is not available.',
  'participants cannot join a cancelled activity'
);
reset role;

select is(
  (select count(*)::integer from public.point_ledger
   where signup_id = '33333333-3333-4333-8333-333333333331'),
  1,
  'repeated verification creates only one points ledger row'
);

select * from finish();
rollback;
