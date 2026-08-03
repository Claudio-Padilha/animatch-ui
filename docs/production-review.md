# Production Readiness Review — Animatch Flutter App

**Date:** 2026-05-10 | **Branch:** main | **Flutter:** 3.41.6 / Dart 3.11.4

---

## Executive Summary

The codebase is architecturally solid: repositories own all HTTP, Riverpod providers are correctly scoped, named routes are used consistently, and there are no direct Dio calls from widgets. However, **five critical blockers** make the app unshippable to either app store today, and seven high-severity issues would cause production incidents within the first week of real traffic.

| Severity | Count |
|---|---|
| Critical | 5 |
| High | 7 |
| Medium | 5 |
| Low | 5 |

---

## Critical Issues

### C-1 — Release APK Signed with Debug Keystore

**File:** `android/app/build.gradle.kts:41`

```kotlin
release {
    // TODO: Add your own signing config for the release build.
    signingConfig = signingConfigs.getByName("debug")
}
```

The debug keystore is a well-known shared credential (`password: android`). Play Store requires a production keystore. Switching keystores after first submission is rejected by Play Console. R8/ProGuard minification is also not enabled.

**Status: Resolved.** `android/app/build.gradle.kts` now loads `android/key.properties` (gitignored, per-machine) and signs `release` builds with a real upload keystore, falling back to debug signing only if `key.properties` is absent. `isMinifyEnabled`, `isShrinkResources`, and `proguardFiles` (default Android rules + `android/app/proguard-rules.pro`) are enabled for `release`. Verified with `./gradlew :app:signingReport` (release variant resolves the real cert) and `flutter build apk --release` (builds successfully with R8 on, 71.2MB signed APK).

`proguard-rules.pro` currently only suppresses the well-known Flutter/Play-Core "missing classes" R8 warning (deferred-components loader references split-install classes not present in this app). It does **not** yet contain plugin-specific `-keep` rules for Firebase Messaging, Auth0, Stream Chat, or google_maps_flutter.

**Remaining before shipping:** a manual **release-build verification pass** — R8 minification only runs in release builds, so bugs it introduces (via renaming/stripping classes referenced through reflection or native platform-channel bridges) won't surface in normal debug development or in `flutter test`. Install `app-release.apk` on a real device or emulator and manually exercise: login/logout/token refresh (Auth0), push notification delivery and tap-to-navigate (Firebase Messaging), chat (Stream Chat), maps rendering, and JSON-backed screens (matches list, animal profile, etc.). Anything that works in debug but breaks only in this release build indicates R8 stripped/renamed something it shouldn't have — fix by adding a targeted `-keep` rule to `proguard-rules.pro`, not by disabling minification.

---

### C-2 — Missing iOS Permission Strings — App Crashes on First Photo Pick

**File:** `ios/Runner/Info.plist`

`NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` are absent. iOS throws `NSInternalInconsistencyException` the moment `image_picker` presents the camera or photo library — which happens in `add_animal_screen.dart` and `profile_verification_screen.dart:53`. The app crashes before showing the permission dialog. This also causes App Store Review rejection.

**Status: Resolved.** Added `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, and `NSPhotoLibraryAddUsageDescription` to `ios/Runner/Info.plist`, with Portuguese purpose strings. Validated the file parses as well-formed plist. Not yet verified on an actual iOS device/simulator (not possible from this Linux dev machine) — confirm the camera/gallery permission dialogs appear correctly during the first iOS build/test pass.

**Fix — added to `ios/Runner/Info.plist`:**

```xml
<key>NSCameraUsageDescription</key>
<string>O Animatch usa a câmera para adicionar fotos de animais e do seu perfil.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>O Animatch acessa a galeria para adicionar fotos de animais e do seu perfil.</string>
<key>NSPhotoLibraryAddUsageDescription</key>
<string>O Animatch pode salvar fotos dos seus animais na galeria.</string>
```

---

### C-3 — Firebase API Key Committed to Version Control

**Files:**
- `lib/firebase_options.dart:28` — `apiKey: 'AIzaSyCvCNoknoZIt0QtKrUSsdv8R4_LNz5ce1A'`
- `android/app/google-services.json` — same key present

`firebase_options.dart` is not gitignored and contains the `apiKey`, `messagingSenderId`, `appId`, and `storageBucket`. Firebase mobile API keys are not server secrets but if Firebase Console key restrictions are not tightened the key can be used to write to Firebase Storage or exhaust quota externally.

**Status: Resolved.**
- `git ls-files android/app/google-services.json` confirms it was **never tracked** — already correctly gitignored (`.gitignore:56`), no `git rm --cached` needed.
- `lib/firebase_options.dart` **is tracked** and does contain the `apiKey`. This matches standard FlutterFire convention (`flutterfire configure` generates this file expecting it to be committed) — the security boundary here is meant to be Firebase/Google Cloud Console API key restrictions, not keeping the file out of git, so leaving it tracked is not itself a bug.
- Added debug + release SHA-1/SHA-256 fingerprints to the Firebase Android app (Project Settings), re-downloaded `google-services.json` to match.
- In Google Cloud Console → Credentials → "Android key (auto created by Firebase)": set **Application restrictions** to Android apps, with `com.animatch.animatch` + both the debug and release SHA-1 fingerprints. Set **API restrictions** to "Restringir chave", scoped down to only the 3 APIs this app's dependencies actually need — confirmed against `pubspec.yaml` (only `firebase_core` + `firebase_messaging` are used, no Firestore/Storage/Phone Auth/Hosting/In-App Messaging): **FCM Registration API**, **Firebase Installations API**, **Token Service API**. The other 5 previously-selected APIs (Management, Hosting, In-App Messaging, Phone Number Verification, Rules) were unchecked.
- Documented the manual distribution step for `google-services.json`/`key.properties` in `README.md` (teammates need their own copy of each — neither is committed).

**Optional further hardening:** disabling the unused Firebase APIs project-wide (APIs & Services → APIs ativadas), not just on this key — lower priority since the key restriction above already blocks this specific key from calling them.

**Key rotation:** not needed. Confirmed the repository has never been public and the key has only ever been seen by the sole developer on the project — no exposure occurred, so there is nothing to rotate against.

---

### C-4 — Auth0 Credentials Hardcoded as Default Values

**File:** `lib/core/config/auth0_config.dart:2-9`

```dart
static const domain = String.fromEnvironment(
  'AUTH0_DOMAIN',
  defaultValue: 'dev-akrxwodm47ylsucp.us.auth0.com',  // always compiled in
);
static const clientId = String.fromEnvironment(
  'AUTH0_CLIENT_ID',
  defaultValue: 'NZ6SL0brELjh8JqbsVG5ROfT1ujt9dYN',  // always compiled in
);
```

The `defaultValue` means the dev Auth0 tenant and client ID are compiled into every build where `--dart-define` is not passed, including local release builds. The domain also appears hardcoded in `build.gradle.kts:33`.

**Status: Resolved.**

- `lib/core/config/auth0_config.dart`: removed `defaultValue` from `domain`, `clientId`, **and `audience`** (the audience had the same hardcoded-default problem, not originally called out, but same category of bug — silently pointing at the wrong API otherwise).
- `lib/main.dart`: added a startup check that **throws `StateError`** if any of the three are empty. Deliberately **not** `assert()` as originally proposed here — `assert()` is stripped out entirely in `--release` builds, which is exactly the build type this check exists to protect; an assert would have been a silent no-op in production.
- `android/app/build.gradle.kts:42`: `manifestPlaceholders["auth0Domain"]` (used by the Android intent-filter that catches the Auth0 callback redirect) now reads `System.getenv("AUTH0_DOMAIN")`, falling back to the dev tenant only for convenience of a plain `flutter run`. Gradle can't read Dart's `--dart-define` values directly, so this is a separate environment variable that must be kept in sync with whatever `AUTH0_DOMAIN` is passed to `flutter build` for release/staging builds — see the new `config/*.env.json` files below, which are the intended single source of truth developers should read the value from before exporting it. `auth0Scheme` was left as-is (it's the app's own bundle ID, not environment-specific, not a bug).
- Replaced ad hoc `--dart-define=KEY=value` flags with **`--dart-define-from-file`**, matching what this fix already recommended for CI:
  - `config/local.env.json` — created, holds the dev tenant values (gitignored, but these values were already plaintext in tracked source before this fix, so no new exposure)
  - `config/staging.env.json` / `config/production.env.json` — gitignored, created with `"REPLACE_ME"` placeholders (no real staging/prod Auth0 values available to this review)
  - `.vscode/launch.json` (gitignored) updated to reference these files
  - Documented in `README.md` under "Local Configuration Files (Not in Git)"
- Verified: `flutter analyze` clean, `flutter build web --dart-define-from-file=config/local.env.json` and `flutter build apk --release --dart-define-from-file=config/local.env.json` both succeed.

**TODO — still needs a human with real credentials:** fill in the actual staging and production Auth0 tenant values in `config/staging.env.json` and `config/production.env.json`, replacing the `"REPLACE_ME"` placeholders. Note the placeholders are non-empty strings, so the `StateError` fail-fast check will **not** catch them — a build using the placeholders as-is will compile and launch, then fail later with a confusing Auth0 "unknown client/tenant" error instead of the clean startup error. Don't mistake "it launched" for "it's configured."

**Not yet verified:** actual runtime behavior of the `StateError` path (i.e., confirming the app truly refuses to start when `config/*.env.json` is missing/incomplete) and the Auth0 login flow itself on a real device — both require the release-build verification pass already flagged under [[C-1]].

---

### C-5 — iOS Release Build Has No Signing Identity or Provisioning Configured

**File:** `ios/Runner.xcodeproj/project.pbxproj`

```
CODE_SIGN_STYLE = Automatic;
"CODE_SIGN_IDENTITY[sdk=iphoneos*]" = "iPhone Developer";
```

`CODE_SIGN_STYLE` is `Automatic` but no `DEVELOPMENT_TEAM` is set on any target/configuration, and there is no `ExportOptions.plist`. Unlike Android's self-generated keystore, iOS signing requires an Apple Developer Program membership, a Distribution Certificate, an App ID registered for `com.animatch.animatch`, and a Provisioning Profile binding them together — none of which exist yet in this repo or (as far as this review can tell) in App Store Connect. `flutter build ipa` will fail at the archive/export step without these, and this is only buildable on macOS or a macOS CI runner (Codemagic / GitHub Actions `macos-latest`) — not on the Linux dev machine.

**Fix:**
1. Confirm an Apple Developer Program membership exists for the Animatch team.
2. Register the App ID `com.animatch.animatch` in the Apple Developer portal with required capabilities (Push Notifications, Sign in with Apple if used).
3. Generate a Distribution Certificate and an App Store provisioning profile for that App ID.
4. Set `DEVELOPMENT_TEAM` in Xcode (or `ios/Flutter/Release.xcconfig`) to the team ID, and add an `ExportOptions.plist` with `method: app-store`.
5. For CI, use Fastlane `match` (syncs certs/profiles via an encrypted private repo) or Codemagic's automatic signing via an App Store Connect API key — do not commit certificates or profiles to this repo.

---

## High-Priority Issues

### H-1 — FCM Tokens and Breeder IDs Logged to Stdout in Production

**File:** `lib/app.dart:68-106` (8 calls)

```dart
print('[FCM] device token: ${token ?? "NULL — FCM token unavailable"}');
print('[FCM] token registered with backend for breederId=${breeder.id}');
```

`print()` is live in release builds. On Android, any app with `READ_LOGS` can read `logcat`. All calls use `// ignore: avoid_print` to silence the linter.

**Status: Resolved for `app.dart`** (this file's 8 calls — `match_provider.dart`/`register_screen.dart` are tracked separately as L-2/L-3 below).

**Correction to this doc's own fix:** the original suggestion — replace `print()` with `debugPrint()`, "which is a no-op in release mode" — is **factually wrong**. Verified against the Flutter SDK source (`packages/flutter/lib/src/foundation/print.dart`): `debugPrint`'s default implementation (`debugPrintThrottled`) unconditionally calls `print()` in every build mode, release included. It only throttles output to avoid Android's log-rate-limit dropping lines; it does not strip itself out of release builds. A plain `print → debugPrint` rename would have left the actual vulnerability — FCM tokens and breeder IDs visible in release `logcat` — completely unfixed.

**Actual fix applied:** every log call in `app.dart` is now wrapped in `if (kDebugMode) { debugPrint(...); }`. `kDebugMode` (from `flutter/foundation.dart`) is a compile-time constant that the Dart compiler genuinely tree-shakes out of release builds, so the sensitive strings are absent from the release binary, not just optimistically hidden. Verified with `flutter analyze` (clean).

**When applying the same fix to L-2 (`match_provider.dart`) and L-3 (`register_screen.dart`), use this same `kDebugMode`-gated pattern, not a bare `debugPrint()` swap.**

---

### H-2 — `onTokenRefresh` Stream Subscription Never Cancelled — Memory Leak

**File:** `lib/app.dart:83-87`

```dart
notificationService.onTokenRefresh.listen((newToken) {
  deviceTokenService.register(newToken, breederId: breeder.id);
});
```

The `StreamSubscription` is never stored or cancelled. On logout and re-login a second subscription stacks on top, registering the token twice per refresh with stale `breeder.id` captures.

**Status: Resolved.** Implemented exactly as proposed below — `_tokenRefreshSub` field added, cancelled+reassigned in `_onLogin`, cancelled+nulled in `_onLogout`, cancelled in `dispose()`. Verified with `flutter analyze` (clean) and `flutter build web` (succeeds).

**Fix:**

```dart
StreamSubscription<String>? _tokenRefreshSub;

Future<void> _onLogin() async {
  // ...existing code...
  _tokenRefreshSub?.cancel();
  _tokenRefreshSub = notificationService.onTokenRefresh.listen((newToken) {
    deviceTokenService.register(newToken, breederId: breeder.id);
  });
}

Future<void> _onLogout(Breeder breeder) async {
  _tokenRefreshSub?.cancel();
  _tokenRefreshSub = null;
  // ...existing code...
}

@override
void dispose() {
  _tokenRefreshSub?.cancel();
  super.dispose();
}
```

---

### H-3 — Firebase and Notification Stream Subscriptions in `routerProvider` Never Cancelled

**File:** `lib/core/router/app_router.dart:164-179`

```dart
FirebaseMessaging.onMessageOpenedApp.listen((message) { ... });
ref.read(notificationServiceProvider).onLocalTap.listen((route) { ... });
```

Both `StreamSubscription` handles are discarded. In development (hot restart) duplicate subscriptions cause double navigation events.

**Status: Resolved.** Implemented as proposed — both subscriptions stored, cancelled via `ref.onDispose`. Verified with `flutter analyze` (clean) and `flutter build web` (succeeds).

**Fix:**

```dart
final msgSub = FirebaseMessaging.onMessageOpenedApp.listen(...);
final tapSub = ref.read(notificationServiceProvider).onLocalTap.listen(...);
ref.onDispose(() {
  msgSub.cancel();
  tapSub.cancel();
});
```

---

### H-4 — `sendTimeout` Not Set — Image Uploads Can Block Indefinitely

**File:** `lib/core/network/api_client.dart:9-14`

`connectTimeout` and `receiveTimeout` are set to 10 seconds. `sendTimeout` is `null` (infinite). For `CloudinaryUploader`, a stalled image upload never times out. The separate `_cdnDio` instance also has no timeouts at all.

**Status: Resolved.** Applied exactly as proposed — `sendTimeout` added to `dioProvider`'s `BaseOptions`, `receiveTimeout` bumped to 30s; `_cdnDio` now has all three timeouts instead of none. Verified with `flutter analyze` (clean) and `flutter build web` (succeeds).

**Fix:**

```dart
// api_client.dart
BaseOptions(
  connectTimeout: const Duration(seconds: 10),
  receiveTimeout: const Duration(seconds: 30),
  sendTimeout: const Duration(seconds: 60),
)

// cloudinary_uploader.dart
static final _cdnDio = Dio(BaseOptions(
  connectTimeout: const Duration(seconds: 10),
  sendTimeout: const Duration(seconds: 120),
  receiveTimeout: const Duration(seconds: 30),
));
```

---

### H-5 — Local Dev Uses Plaintext HTTP With No Android Network Security Config

**File:** `lib/core/config/app_env.dart:28`

```dart
_Env.local => 'http://$_localHost:3000',
```

Android 9+ blocks cleartext HTTP by default. There is no `network_security_config.xml`. A developer on a physical Android device gets a silent connection failure with no clear error.

**Status: Resolved.** Applied exactly as proposed. Verified the merge behavior directly (not just that the build succeeded) by inspecting Gradle's merged manifest output: `android:networkSecurityConfig="@xml/network_security_config"` is present in `build/app/intermediates/merged_manifests/debug/.../AndroidManifest.xml`, and confirmed **absent** from the equivalent `release` merged manifest — so this is genuinely debug-only, not just assumed to be.

**Fix — debug-only manifest overlay:**

`android/app/src/debug/res/xml/network_security_config.xml`:
```xml
<?xml version="1.0" encoding="utf-8"?>
<network-security-config>
    <domain-config cleartextTrafficPermitted="true">
        <domain includeSubdomains="false">10.0.2.2</domain>
        <domain includeSubdomains="false">localhost</domain>
    </domain-config>
</network-security-config>
```

`android/app/src/debug/AndroidManifest.xml`:
```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <application android:networkSecurityConfig="@xml/network_security_config"/>
</manifest>
```

Zero effect on release APKs.

---

### H-6 — All `state.extra!` Routes Crash on Deep-Link or OS State Restoration

**File:** `lib/core/router/app_router.dart:91-134` (6 routes)

```dart
animalId: state.extra! as String,         // MyAnimalDetailScreen
animal: state.extra! as HerdAnimal,       // EditAnimalScreen
animal: state.extra! as AnimalDetailData, // AnimalDetailScreen (×2)
match: state.extra! as MatchItem,         // MatchDetailScreen, ChatScreen
```

`state.extra` is `null` when navigation originates from a push notification deep-link, Universal Link, or OS stack restoration. Force-unwrap throws `Null check operator used on a null value`.

**Fix:** Move IDs into path parameters; load objects from providers in the target screen. Pass the in-memory object via `extra` as an optimization when available, with a provider fetch as the fallback.

**Status: Resolved for 4/6 routes; 2 blocked on a backend gap (documented, not silently skipped).**

- **`myAnimalDetail` — Resolved.** This route only ever carried a `String` id via `extra` (the screen already loaded the actual `HerdAnimal` from `herdProvider`, filtered by id). Changed the route to `/rebanho/animal/:animalId`, reading `state.pathParameters['animalId']!`. Added `AppRoutes.myAnimalDetailPath(id)` call-site helper.
  - **Caught a real regression risk before it shipped:** verified `go_router`'s matching behavior by reading its source (`configuration.dart:_getLocRouteMatches`) rather than assuming — it matches top-level routes strictly in declaration order, with **no** literal-vs-parameter prioritization. The literal sibling route `editAnimal` (`/rebanho/animal/editar`) was declared *after* the old `myAnimalDetail`, so parameterizing the latter would have made `/rebanho/animal/editar` incorrectly match with `animalId: "editar"`. Fixed by reordering.

- **`editAnimal` — Resolved.** Converted `EditAnimalScreen` from a `required this.animal` (`HerdAnimal`) constructor to `required this.animalId`, loading via the existing `animalDetailProvider` (same one `myAnimalDetail` uses) with loading/error states, delegating the actual form to a renamed inner `_EditAnimalForm` widget. Route path is now `/rebanho/animal/editar/:animalId` (`AppRoutes.editAnimalPath(id)`). Since this route now has 4 path segments vs. `myAnimalDetail`'s 3, the declaration-order collision risk above no longer applies here (segment-count mismatch means they can't match each other regardless of order) — the reordering fix/comment for that specific collision was updated accordingly. Deliberately **does not** accept `extra` as a fast-path optimization, unlike the other fixed routes below — always fetching fresh avoids editing stale cached data if the animal was updated elsewhere since the herd list was last loaded, which matters here specifically because this is an edit-and-save flow, not a read-only view.

- **`animalDetail` / `matchAnimalDetail` — Resolved**, using the extra-as-optimization + provider-as-fallback pattern this fix originally asked for (unlike `editAnimal`, these are read-only views where refetching on every tap would be wasteful). Added `AnimalDetailData.fromHerdAnimal()` (a new factory alongside the existing `fromDiscoverAnimal`/`fromMatchAnimal`) and `animalDetailDataProvider`, both backed by `GET /animals/:id` (not scoped to the current breeder, so it can look up any animal by id). Added an `AnimalDetailLoader` wrapper widget: uses `extra` immediately if present, otherwise watches the provider. Routes are now `/animal/:animalId` and `/matches/animal/:animalId`; call sites in `discover_screen.dart` and `match_detail_screen.dart` updated to pass the id in the URL while still passing `extra` for the fast path.
  - **Open assumption, not verified:** this relies on `GET /animals/:id` permitting cross-breeder lookups (needed since these routes display *other* breeders' animals, not the current breeder's own herd). This client repo has no visibility into the backend's authorization rules for that endpoint (separate Node.js repo). If it's actually scoped to the requesting breeder's own animals, this fallback will 403/404 for other breeders' animals specifically — the one case it exists to handle. Needs confirmation against the actual backend before relying on it in production.
  - `MatchAnimal.id` is nullable; `match_detail_screen.dart`'s `_openDetail` now guards against `null` (no-ops rather than pushing a route with an empty path segment) — should never trigger for real match data in practice.

- **`matchDetail` / `chat` — Blocked on a backend gap, not fixed the same way.** Checked `match_repository.dart`: the backend only exposes `GET /matches?animalId=X` (a list scoped to one of *my* animals) — there is no `GET /matches/:matchId`. Worse, `MatchItem.fromJson` requires an explicit `animalId` parameter just to determine which side of the match is "yours" vs "theirs", so even a single-match endpoint wouldn't be sufficient on its own without also knowing an animal id you own. This needs a backend change — ideally a new endpoint that resolves yours-vs-theirs server-side from the authenticated breeder, removing the client-side `animalId` dependency entirely. Out of reach from this client-only repo.
  - **Mitigation applied instead of leaving the crash in place:** added a `redirect:` to both `GoRoute`s — if `extra` is `null`, redirect to `AppRoutes.matches` before the builder runs, so `state.extra!` is never reached with a null value. This stops the crash but does **not** restore the intended deep-link/notification-tap destination (user lands on the matches list, not the specific match) — a real fix still needs the backend endpoint described above.

**Verified across all changes:** `flutter analyze` (clean, whole project), `flutter build apk --debug` (exercises `go_router`'s assert-based route-table validation, stripped in release), `flutter build apk --release`, and `flutter build web` all succeed. **Not verified:** actual on-device navigation through any of these flows (tapping into each screen, backgrounding/restoring, an actual notification tap) — same recurring device-testing gap as the rest of this review.

---

### H-7 — Stream Chat API Key Hardcoded in Source

**File:** `lib/core/services/stream_chat_service.dart:3-4`

```dart
static const _apiKey = 'chbd9fpt9qxu';
```

Unlike Auth0, there is no `String.fromEnvironment` override mechanism. The key is compiled into every build.

**Status: Resolved.** Applied as proposed, and wired into the same `config/*.env.json` mechanism built for [[C-4]] rather than a one-off `--dart-define`, for consistency: `STREAM_CHAT_API_KEY` added to `local.env.json` (existing dev-tenant value, no new exposure since it was already plaintext in tracked source) and to `staging.env.json`/`production.env.json` as a `REPLACE_ME` placeholder (real values needed from whoever holds them, same caveat as the Auth0 placeholders — these don't trip any fail-fast check since they're non-empty). Unlike Auth0, a missing/placeholder key does not block app startup — it will only surface as a broken chat feature. `flutter analyze` clean, `flutter build web` succeeds.

**Fix:**

```dart
static const _apiKey = String.fromEnvironment('STREAM_CHAT_API_KEY');
```

Add to `--dart-define-from-file` CI config.

---

## Medium-Priority Issues

### M-1 — `Breeder` Not Migrated to Freezed

**File:** `lib/features/auth/domain/breeder.dart`

Hand-rolled mutable class. Its `copyWith` silently excludes `id` and `email` — callers get no compiler error when passing those fields. No generated `==` means Riverpod cannot suppress redundant rebuilds when the same breeder is returned from the server.

**Status: Resolved.** Migrated to `@freezed`. One wrinkle worth recording: freezed automatically wires full JSON serialization (expecting a `.g.dart` part) for **any** factory literally named `fromJson`, regardless of what the body does — an initial attempt to keep a hand-written `fromJson` (to sidestep needing a companion file) failed to compile once other files were analyzed, because the generated `_Breeder` class unconditionally calls `_$BreederFromJson`/`_$BreederToJson`. Switched to proper `json_serializable` integration instead: `@JsonKey(name: ...)` for the three renamed fields (`pictureUrl`→`avatarUrl`, `propertyName`→`farmName`, `profileStatus`→`status`), and `@JsonKey(fromJson:, toJson:)` for the `BreederStatus` enum conversion (confirmed via `json_serializable`'s own README that nested types with a conventional `fromJson`/`toJson` — like the existing `BreederAssociation` — are picked up automatically with no annotation needed). This also required adding `analyzer: errors: invalid_annotation_target: ignore` to `analysis_options.yaml` — an expected, documented side effect of combining `@JsonKey` with freezed's primary-constructor pattern, not a workaround.

Verified with a throwaway test (written, run, then deleted — not left in the repo) covering: full-payload key mapping, missing-field defaults, unknown `profileStatus` falling back to `pending`, `copyWith(id:, email:)` now working (the actual bug this item reported), and generated equality. `flutter analyze` (clean, whole project) and `flutter build web` both succeed.

---

### M-2 — `HerdAnimal` and `MatchItem` Not on Freezed

**Files:** `lib/features/herd/domain/herd_animal.dart`, `lib/features/matches/domain/match_item.dart`

Same reasoning as M-1. Both are passed via `state.extra!` (compounding H-6) and updated via manual `copyWith`.

**Status: Resolved.** Migrated `GeneticIndices`, `HerdAnimal`, `MatchAnimal`, `MatchContact`, and `MatchItem` to `@freezed`.

Unlike [[M-1]] (`Breeder`), these classes' `fromJson` does non-trivial derived-field logic — computing Portuguese display labels for `breed`/`sex`, collapsing `status` into a bool, flattening a nested `address` object into `city`/`state`/`zipCode`/`location`, and (for `MatchItem`) resolving yours-vs-theirs from an extra `animalId` parameter a generated single-arg `fromJson` couldn't accept anyway. Forcing that through `@JsonKey(fromJson:, toJson:)`/`readValue` per field would have been exactly the fragile path M-1 already warned about. Instead, `fromJson` on these four classes is a **static method**, not a `factory` constructor — freezed only special-cases a literal `factory ClassName.fromJson(...)`, and a static method is invisible to that codegen while still supporting the identical `HerdAnimal.fromJson(json)` call syntax at every existing call site, so no caller needed to change. `GeneticIndices` *is* a plain factory `fromJson` backed by `json_serializable` (`part '*.g.dart'`), since its fields are a straightforward key-renaming case, same as `Breeder`.

Verified with a throwaway test (written, run, then deleted) covering: `HerdAnimal.fromJson` (label/bool/address derivation), generated equality (`copyWith` producing a distinct-but-equal-by-value instance, original left untouched), and `MatchItem.fromJson`'s yours/theirs resolution + generated equality. `flutter analyze` (clean, whole project) and `flutter build web` both succeed.

---

### M-3 — `restoreSession` Swallows All Exceptions

**File:** `lib/features/auth/data/auth_repository.dart:87-93`

```dart
} catch (_) {
  return null; // network errors, 500s, JSON failures all treated as "logged out"
}
```

A user who is offline at cold start is redirected to onboarding and must log in again even though their Auth0 credentials are valid. Only `CredentialsManagerException` should be treated as "truly logged out"; network errors should propagate.

---

### M-4 — `editProfile` Guard Uses Stale Client-Side Verification Status

**File:** `lib/core/router/router_notifier.dart:48-50`

```dart
if (loc == AppRoutes.editProfile && !breeder.verifiedBreeder) {
  return AppRoutes.profile;
}
```

If an admin revokes verification server-side, the client holds the old status until restart. A periodic breeder profile refresh on app foreground would keep this in sync. The backend must also enforce this server-side.

---

### M-5 — CPF Validated by Digit Count Only — No Checksum

**File:** `lib/features/profile/ui/profile_verification_screen.dart:207`

```dart
if (digits.length != 11) return 'CPF inválido';
```

`00000000000` and `11111111111` both pass. CPF has a two-digit Luhn-style checksum that should be validated client-side before submission.

---

## Low-Priority / Informational

**L-1** — `onboarding_screen.dart:101`: TODO to write `hasSeenOnboarding` Hive flag is unimplemented. Hive is already initialized; ~15-minute fix.

**L-2** — ~~`match_provider.dart`: 9 `print()` calls log channel IDs and user IDs. Replace with `debugPrint()`.~~ **Resolved** — all 9 wrapped in `if (kDebugMode) { debugPrint(...); }`, not bare `debugPrint()` (see corrected reasoning under [[H-1]]).

**L-3** — ~~`register_screen.dart:26`: Full exception stack trace printed on signup error. Replace with `debugPrint()`.~~ **Resolved** — same `kDebugMode`-gated fix applied.

**L-4** — `profile_picture_store.dart`: Local profile picture in `getApplicationDocumentsDirectory` is never deleted on logout. Next user on a shared device sees previous user's photo. `AuthNotifier.logout()` should call `ProfilePictureStore` cleanup.

**L-5** — `test/widget_test.dart`: Single smoke test; will fail in CI due to unmocked Firebase/Auth0 initialization. Zero coverage for auth flow, router redirects, providers, repositories, or form validation.

---

## What Is Done Well

- **Repository pattern strictly enforced.** Zero instances of Dio called from a widget or provider directly.
- **Riverpod usage is idiomatic.** `ref.watch` in build, `ref.read` in callbacks, autoDispose on family providers, `AsyncValue.guard` used correctly.
- **Named routes everywhere.** Zero `Navigator.push` calls. `go_router` used consistently.
- **Auth0 credential manager** handles token refresh silently via the interceptor in `api_client.dart`.
- **Error and loading states handled** in every async widget. No silent empty states or missing spinners.
- **Cloudinary upload uses server-side signatures** — the Cloudinary secret is never on the client.
- **Notifications service disposal** wired correctly: `ref.onDispose(service.dispose)` in both providers.
- **Portuguese strings throughout.** All user-facing text is in pt_BR.
- **`cached_network_image` used consistently** for all remote images with placeholder and error widgets.

---

## Action Checklist

### Before any app store submission
- [x] **C-1** Generate production keystore; configure release signing and R8 in `build.gradle.kts` — signing and R8 config done; **manual release-build verification pass (device install + smoke test of Auth0/FCM/Stream Chat/maps/JSON screens) still outstanding**
- [x] **C-2** Add `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` to `ios/Runner/Info.plist` — added; **still needs verification on a real iOS device/simulator**
- [x] **C-3** Verify `google-services.json` is not git-tracked; restrict Firebase API key in Console (package + debug/release SHA-1 allowlist, scoped to 3 needed APIs) — fully resolved, no rotation needed (repo confirmed never public)
- [x] **C-4** Remove hardcoded `defaultValue` from `Auth0Config`; configure `--dart-define-from-file` — done (`config/local.env.json` + `StateError` fail-fast); **TODO: fill real values into `config/staging.env.json` / `config/production.env.json` (currently `REPLACE_ME` placeholders); login flow still needs on-device verification**
- [ ] **C-5** Register Apple Developer account/App ID, generate Distribution Certificate + provisioning profile, set `DEVELOPMENT_TEAM` and `ExportOptions.plist`

### Before production traffic
- [x] **H-1** Replace all `print()` in `app.dart` with `kDebugMode`-gated `debugPrint()` (8 calls) — done; note bare `debugPrint()` alone does **not** strip in release, see corrected reasoning in H-1 above
- [x] **H-2** Store and cancel `onTokenRefresh` subscription in `_AnimatchAppState` — done
- [x] **H-3** Store and cancel Firebase/notification subscriptions via `ref.onDispose` in `routerProvider` — done
- [x] **H-4** Add `sendTimeout` to both Dio instances (`api_client.dart` and `cloudinary_uploader.dart`) — done
- [x] **H-5** Add debug-only `network_security_config.xml` for Android cleartext to localhost — done, merge behavior verified
- [x] **H-6** Migrate `state.extra!` routes to path parameters with provider-based loading — **4/6 fully resolved** (`myAnimalDetail`, `editAnimal`, `animalDetail`, `matchAnimalDetail`); **`matchDetail`/`chat` mitigated with a safe redirect, not fully fixed — blocked on a missing `GET /matches/:id` backend endpoint**; also unverified: whether `GET /animals/:id` permits cross-breeder lookups (needed for the `animalDetail` fallback)
- [x] **H-7** Move Stream Chat API key to `String.fromEnvironment('STREAM_CHAT_API_KEY')` — done, wired into `config/*.env.json`; staging/production values still `REPLACE_ME`
- [x] **L-2/L-3** Replace `print()` in `match_provider.dart` and `register_screen.dart` with `kDebugMode`-gated `debugPrint()` — done

### Medium priority
- [x] **M-1/M-2** Migrate `Breeder`, `HerdAnimal`, `GeneticIndices`, `MatchItem` to freezed — done (`Breeder` under M-1; `HerdAnimal`/`GeneticIndices`/`MatchAnimal`/`MatchContact`/`MatchItem` under M-2)
- [ ] **M-3** Refine `restoreSession` to catch only `CredentialsManagerException`, not all exceptions
- [ ] **M-4** Add server-side enforcement for `editProfile` access; add client-side profile refresh on foreground
- [ ] **M-5** Add CPF Luhn checksum validation in `profile_verification_screen.dart`
- [ ] **L-1** Implement `hasSeenOnboarding` Hive flag in `onboarding_screen.dart`
- [ ] **L-4** Delete local profile picture on logout in `AuthNotifier.logout()`
- [ ] **L-5** Write provider unit tests, repository mock tests, and router redirect tests
