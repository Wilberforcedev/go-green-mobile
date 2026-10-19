# Go Green Mates mobile app

A Flutter mobile client for Go Green Mates. A branded Go Green Mates splash screen appears first while the app initializes, then the app opens five bottom navigation screens: **Home, Services, Go Green, Events, and Wallet**. Events includes Upcoming and My Tickets views with event details and a ticket display. The Go Green tab retains the Supabase-powered Impact Hub for accounts, activity listings, registrations, organizer attendance verification, and Green Points.

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

Without Supabase values, the app opens normally and displays setup guidance in Go Green and Wallet. Authentication, role permissions, capacity limits, attendance verification, and point calculations remain enforced by Supabase policies and RPC functions.

## Included features

- Native Material 3 mobile navigation and layouts
- Home, Services, Go Green, Events, and Wallet screens
- Email/password participant registration and sign-in
- Shared published activities, category filter, and search
- Capacity-aware registration through `join_activity`
- Organizer activity publishing
- Organizer attendance verification through `verify_attendance`
- Participant sign-up history and Green Points ledger total
- Events list, event detail sheet, My Tickets list, and ticket display preview
- Wallet balance from the authenticated participant's Green Points ledger
- Refreshable data and accessible labels on main controls

**Ticket checkout is a UI preview.** It saves a sample ticket on the current device only. Payment processing and scannable ticket validation are not connected; the displayed cUSD amount does not charge a user.

## Build

```sh
flutter analyze
flutter test
flutter build apk --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...
```

The repository should be opened and generated with the Flutter SDK to add platform runner directories (`android/`, `ios/`) for the target development machine. Those generated folders are SDK-version-specific and could not be produced in this environment because Flutter is not installed.
