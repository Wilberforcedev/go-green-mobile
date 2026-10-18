# Go Green Mates mobile app

A Flutter mobile client for the Go Green Mates website. It includes Home, Campaigns, About, and Impact Hub tabs. The Impact Hub uses the same Supabase project and database as the website for accounts, activity listings, sign-ups, organizer verification, and server-recorded Green Points.

## Requirements

- Flutter 3.22 or newer (Dart 3.3+)
- The Supabase project and migration from the website repository

## Run

```sh
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Use only the Supabase public anon/publishable key in the mobile app. Never bundle the service-role key. The application needs the same database migration and organizer role setup described in the website repository README.

Without Supabase values the app opens normally and displays setup guidance in Impact Hub. Authentication, role permissions, capacity limits, attendance verification, and point calculations remain enforced by Supabase policies and RPC functions.

## Included features

- Native Material 3 mobile navigation and layouts
- Email/password participant registration and sign-in
- Shared published activities, category filter, and search
- Capacity-aware registration through `join_activity`
- Organizer activity publishing
- Organizer attendance verification through `verify_attendance`
- Participant sign-up history and Green Points ledger total
- Refreshable data and accessible labels on main controls

## Build

```sh
flutter analyze
flutter test
flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

The repository should be opened and generated with the Flutter SDK to add platform runner directories (`android/`, `ios/`) for the target development machine. Those generated folders are SDK-version-specific and could not be produced in the current environment because Flutter is not installed.
