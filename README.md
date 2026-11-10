# Go Green Mates mobile app

A Flutter mobile client for the Go Green Mates community. It includes Home,
Campaigns, Impact Hub, and About tabs. The Impact Hub uses the same Supabase
project and database as the website for accounts, activity listings, sign-ups,
organizer verification, and server-recorded Green Points.

## Requirements

- Flutter 3.35.4 or newer (Dart 3.9+)
- The Supabase project and database migration from the website repository
- Android SDK for Android builds; macOS and Xcode for iOS builds

The platform runner projects (`android/`, `ios/`) are not checked in. Generate
them once with the helper script:

```sh
sh tool/bootstrap_platforms.sh
```

The script runs `flutter create --platforms=android,ios --project-name
grinmates_mobile .` and preserves existing files, including the committed
Android manifest override.

## Run

```sh
flutter pub get
flutter run \
  --dart-define=SUPABASE_URL=https://YOUR_PROJECT.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
```

Commit the generated `pubspec.lock` after the first successful dependency
resolution so release builds use the same package versions.

Without Supabase values the app still opens and shows setup guidance in the
Impact Hub. If the values are invalid, the app starts in a read-only state and
shows the configuration problem in the Impact Hub instead of crashing.

## Security and configuration

- Use only the Supabase **public anon/publishable key** in the mobile app.
  Never bundle the service-role key. At startup the app decodes the key and
  refuses to connect if it detects the `service_role` claim.
- `SUPABASE_URL` must be an `https://` project URL.
- Authentication, role permissions, capacity limits, attendance verification,
  and point calculations are enforced by Supabase row-level security and RPC
  functions. The app never calculates points locally.
- All network requests have a 20 second timeout and surface friendly errors.

## Checks

```sh
flutter analyze
flutter test
```

CI runs both on every push and pull request, then generates an Android runner
and builds a debug APK to verify the app compiles for Android.

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
     --dart-define=SUPABASE_ANON_KEY=YOUR_PUBLIC_ANON_KEY
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
  confirmation and password recovery use Supabase's hosted email flows;
  configure the project's site URL and redirect URLs in the Supabase dashboard
  before launch.
- Organizers publish activities and verify attendance; points are written by
  the `verify_attendance` RPC and read from the `point_ledger` table.
- Green Points have no cash value.
- Store listings require a privacy policy and support contact. The app collects
  an email address and display name for accounts.
