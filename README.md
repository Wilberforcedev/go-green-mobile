# Go Green Mates mobile app

A Flutter mobile client for the Go Green Mates community. It includes Home,
Campaigns, Impact Hub, and About tabs. The Impact Hub uses this repository's Supabase backend for participant accounts,
activity listings, sign-ups, organizer verification, and server-recorded Green
Points. The companion website remains a separate browser-local prototype; its
data do not sync with this app.

## Requirements

- Flutter 3.35.4 or newer (Dart 3.9+)
- A Supabase project for live Impact Hub data; this repository includes its migration
- Android SDK for Android builds; macOS and Xcode for iOS builds

The platform runner projects (`android/`, `ios/`) are not checked in. Generate
them once with the helper script:

```sh
sh tool/bootstrap_platforms.sh
```

The script runs `flutter create --platforms=android,ios --project-name
grinmates_mobile .`, preserves existing files, including the committed
Android manifest override, and registers the Supabase callback scheme in the
generated Android and iOS runners.

## Run

```sh
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
```

Commit the generated `pubspec.lock` after the first successful dependency
resolution so release builds use the same package versions.

Without Supabase values the app still opens and shows setup guidance in the
Impact Hub. If the values are invalid, the app starts in a read-only state and
shows the configuration problem in the Impact Hub instead of crashing.

## Security and configuration

- Use the Supabase **publishable key** in the mobile app. A legacy anon key is
  also accepted for existing projects. Never bundle a secret or service-role
  key; startup rejects those key formats.
- `SUPABASE_URL` must be an `https://` project URL. Pass the publishable key
  as `SUPABASE_PUBLISHABLE_KEY`; `SUPABASE_ANON_KEY` remains a legacy fallback.
- Authentication, role permissions, capacity limits, attendance verification,
  and point calculations are enforced by Supabase row-level security and RPC
  functions. The app never calculates points locally.
- All network requests have a 20 second timeout and surface friendly errors.

## Checks

```sh
flutter analyze
flutter test
```

CI runs analysis and widget tests on every push and pull request. It also
generates an Android runner and builds a release-mode APK smoke artifact to
check Android compilation. The artifact is not store-signed.

## Supabase backend

Apply this repository's migrations to a dedicated Supabase project before connecting real users. For local checks, run:

```sh
supabase start
supabase db reset
supabase test db
supabase stop
```

New accounts default to the participant role. A trusted operator must bootstrap the first administrator. After that, administrators can grant or remove organizer access from the Impact Hub’s Account access panel; the admin-only RPC records each change in an audit log. Organizers can edit or cancel their own future activities and cancel a participant’s future signup. Participants can cancel their own future registrations. Server-side functions enforce permissions, capacity and start-time limits. Account deletion follows the retention rule above: profiles, registrations, and points are removed; activities remain with the organizer detached, and role-change audit records retain account IDs. The user-initiated `delete-account` Edge Function requires a valid session and protects the last administrator account. Deploy it with `supabase functions deploy delete-account` before offering account deletion in a live app. Never put the service-role key in the mobile app.

## Production release

1. Generate the platform runners and set a real application id (for example
   `com.googreenmates.app`) in `android/app/build.gradle.kts`.
2. Set the app name, icon, and splash screen. `flutter_launcher_icons` is a
   convenient way to generate Android and iOS icons from one source image.
3. Create an upload keystore and keep it outside version control:

   ```sh
   keytool -genkeypair -v -keystore android/app/upload-keystore.jks \
     -keyalg RSA -keysize 2048 -validity 10000 -alias upload
   ```

   Add `android/key.properties` (ignored by git):

   ```properties
   storePassword=YOUR_STORE_PASSWORD
   keyPassword=YOUR_KEY_PASSWORD
   keyAlias=upload
   storeFile=upload-keystore.jks
   ```

   Configure the generated `android/app/build.gradle.kts`:

   ```kotlin
   import java.io.FileInputStream
   import java.util.Properties

   val keystoreProperties = Properties()
   val keystorePropertiesFile = rootProject.file("key.properties")
   if (keystorePropertiesFile.exists()) {
       keystoreProperties.load(FileInputStream(keystorePropertiesFile))
   }

   android {
       signingConfigs {
           create("release") {
               keyAlias = keystoreProperties["keyAlias"] as String
               keyPassword = keystoreProperties["keyPassword"] as String
               storeFile = file(keystoreProperties["storeFile"] as String)
               storePassword = keystoreProperties["storePassword"] as String
           }
       }
       buildTypes {
           release {
               signingConfig = signingConfigs.getByName("release")
           }
       }
   }
   ```

4. Build a release bundle with symbols kept for crash reporting:

   ```sh
   flutter build appbundle --release \
     --build-name=1.0.0 --build-number=2 \
     --obfuscate --split-debug-info=build/symbols \
     --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
     --dart-define=SUPABASE_PUBLISHABLE_KEY=YOUR_PUBLISHABLE_KEY
   ```

5. Verify the build on a physical device before submitting to the store.

The committed `android/app/src/main/AndroidManifest.xml` adds the `INTERNET`
permission required by release builds and sets the launcher label to
"Go Green Mates". `flutter create` preserves it, but if the platform folder is
ever regenerated with `--overwrite`, re-add the permission.

## Repository layout

- `lib/main.dart` — app setup, configuration validation, navigation shell
- `lib/screens.dart` — Home, Campaigns, About, and Impact Hub screens
- `lib/widgets.dart` — shared cards, forms, and dashboard widgets
- `test/` — widget tests covering navigation and setup states

## Operational notes

- New accounts may require email confirmation before first sign-in. Email
  confirmation and password recovery use Supabase's hosted email flows. The
  app returns to `io.supabase.flutter://reset-callback/`; run the platform
  bootstrap script and add that exact URI to Supabase Auth's redirect allowlist
  before launch. Verify the link flow on Android and iOS devices.
- Organizers publish activities and verify attendance; points are written by
  the `verify_attendance` RPC and read from the `point_ledger` table.
- Green Points have no cash value.
- Store listings require a privacy policy and support contact. The app collects
  an email address and display name for accounts.
