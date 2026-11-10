# Go Green Mates mobile app

A Flutter app for Go Green Mates. It provides Home, Campaigns, About and Impact Hub sections. The Impact Hub connects to the same Supabase project as the website for accounts, activities, registrations, attendance verification and Green Points.

## Requirements

- Flutter SDK on the stable channel
- Access to the Go Green Mates Supabase project and its website database migration

## Configure Supabase

Pass the project URL and **public anon/publishable key** at build or run time:

```sh
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Never put a Supabase service-role key in the app. The public key is intended for client apps; access must be restricted by the project’s row-level security policies and server-side functions.

The Impact Hub can open without Supabase configuration and shows setup guidance. Authentication, organizer permissions, activity capacity, attendance verification and point calculations depend on the configured Supabase project and migration.

For password recovery, configure the Supabase Auth email template and redirect allowlist for the intended mobile or website reset flow.

## Run locally

```sh
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Commit the generated `pubspec.lock` after resolving dependencies so local and CI builds use the same package versions.

## Checks

The GitHub Actions workflow runs formatting checks, static analysis, widget tests and an Android debug APK build. The Android runner project is generated in CI because native platform directories are not currently checked into this repository.

Run the same checks locally:

```sh
flutter create --platforms=android .
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test --coverage
flutter build apk --debug
```

## Preparing a store release

The repository is not yet ready for direct Play Store or App Store submission. Before publishing:

1. Generate and review the native projects: `flutter create --platforms=android,ios .`. Commit the generated folders and confirm the Android application ID and iOS bundle ID.
2. Add app icons, launch screens, store screenshots, support details and a privacy policy that accurately explains account, activity, attendance and points data.
3. Configure production Supabase URL/key values and verify the website migration, row-level security policies, organizer role setup, email confirmation and password recovery redirects.
4. Set up Android signing and Play Console release access. For iOS, use macOS/Xcode, Apple signing and App Store Connect.
5. Test registration, sign-in, password recovery, activity registration, organizer publishing and attendance verification on physical devices against the production Supabase project.
6. Review account deletion and data retention requirements before store submission. Account deletion needs a secure server-side implementation; the mobile client must not use an admin/service-role key.

Android release builds require Android SDK and signing configuration. iOS builds require macOS and Xcode.
