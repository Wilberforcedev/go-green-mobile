# Go Green Mates mobile app

A Flutter mobile app for Go Green Mates with Home, Campaigns, About and Impact Hub sections. The Impact Hub provides participant accounts, activity registration, organizer publishing, attendance verification and Green Points.

## Supabase backend

This repository includes the Supabase schema used by the mobile app in `supabase/migrations`. Apply it to a dedicated Supabase project before connecting real users:

```sh
supabase link --project-ref YOUR_PROJECT_REF
supabase db push
```

To apply migrations in a local Supabase development stack, run `supabase start` and then `supabase db reset`. The latter resets the local database.

The companion website repository currently describes its Impact Hub as a browser-local prototype. It does not use this schema, so website and mobile activity data do not currently sync. Connecting the website to this backend is a separate integration.

New accounts receive the `participant` role. Promote trusted organizers through the Supabase SQL editor or another privileged backend process:

```sql
update public.profiles
set role = 'organizer'
where id = 'AUTH_USER_UUID';
```

Never allow the mobile client to change roles. The migration restricts data access with row-level security and keeps join/attendance operations in server-side functions.

## Supabase configuration

Pass the project URL and **public anon/publishable key** when running the app:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Never bundle a service-role key. The Impact Hub displays setup guidance when configuration is missing.

For production, configure a custom SMTP provider for Supabase Auth, email confirmation templates and redirect allowlists. Account confirmation and password recovery return to `io.supabase.flutter://reset-callback/`. Add that URI to Supabase Auth’s allowed redirects and register the `io.supabase.flutter` URL scheme in the generated Android and iOS projects. The app handles Supabase’s password-recovery event and asks the user to set a new password.

## Run locally

```sh
flutter create --platforms=android,ios .
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Commit the generated `pubspec.lock` and reviewed platform projects before release. Android and iOS runner folders are not currently checked into this repository.

## Checks

GitHub Actions runs Flutter analysis and widget tests, builds an Android release-mode APK as a compile smoke check, and applies the Supabase migrations to a local database. The APK is not signed for store submission.

Run the Flutter checks locally:

```sh
flutter create --platforms=android .
flutter pub get
flutter analyze
flutter test --coverage
flutter build apk --release
```

Run the migration locally with Supabase CLI and Docker:

```sh
supabase start
supabase db reset
supabase stop
```

## Before store submission

The project still needs the following release work:

1. Generate, configure and commit Android/iOS runner projects. Set final application/bundle IDs, app icons, launch screens and deep-link URL scheme settings.
2. Publish a privacy policy and support details that accurately describe account, activity, attendance and points data.
3. Verify production row-level security, organizer role administration, email confirmation and password recovery against the real Supabase project.
4. Implement and test account deletion and define data retention, especially for organizer accounts and historical activity records.
5. Configure Android signing and Play Console release access. For iOS, use macOS/Xcode, Apple signing and App Store Connect.
6. Test registration, sign-in, email confirmation, password recovery, joining, publishing and attendance verification on physical devices.

Android releases require Android SDK and signing configuration. iOS builds require macOS and Xcode.
