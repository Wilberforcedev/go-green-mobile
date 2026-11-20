begin;

select plan(12);
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

select * from finish();
rollback;
