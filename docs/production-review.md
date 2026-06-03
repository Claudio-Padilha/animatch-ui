# Production Readiness Review — Animatch Flutter App

**Date:** 2026-05-10 | **Branch:** main | **Flutter:** 3.41.6 / Dart 3.11.4

---

## Executive Summary

The codebase is architecturally solid: repositories own all HTTP, Riverpod providers are correctly scoped, named routes are used consistently, and there are no direct Dio calls from widgets. However, **four critical blockers** make the app unshippable to either app store today, and seven high-severity issues would cause production incidents within the first week of real traffic.

| Severity | Count |
|---|---|
| Critical | 4 |
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

**Fix:** Generate a production keystore, store credentials in `android/key.properties`, and update `build.gradle.kts`:

```kotlin
val keyProperties = Properties().apply {
    load(FileInputStream(rootProject.file("key.properties")))
}
signingConfigs {
    create("release") {
        keyAlias = keyProperties["keyAlias"] as String
        keyPassword = keyProperties["keyPassword"] as String
        storeFile = file(keyProperties["storeFile"] as String)
        storePassword = keyProperties["storePassword"] as String
    }
}
buildTypes {
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(getDefaultProguardFile("proguard-android-optimize.txt"), "proguard-rules.pro")
    }
}
```

---

### C-2 — Missing iOS Permission Strings — App Crashes on First Photo Pick

**File:** `ios/Runner/Info.plist`

`NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` are absent. iOS throws `NSInternalInconsistencyException` the moment `image_picker` presents the camera or photo library — which happens in `add_animal_screen.dart` and `profile_verification_screen.dart:53`. The app crashes before showing the permission dialog. This also causes App Store Review rejection.

**Fix — add to `ios/Runner/Info.plist`:**

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

**Fix:**
1. In the Firebase Console, restrict the Android API key to the `com.animatch.animatch` package + production SHA-1. Disable any Firebase APIs not in use.
2. Run `git ls-files android/app/google-services.json` to confirm tracking status. If tracked, run `git rm --cached android/app/google-services.json`.
3. Rotate the key if the repository has ever had public or semi-public access.

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

**Fix:** Remove `defaultValue` for both. Fail loudly at startup if defines are missing:

```dart
abstract final class Auth0Config {
  static const domain = String.fromEnvironment('AUTH0_DOMAIN');
  static const clientId = String.fromEnvironment('AUTH0_CLIENT_ID');
  static const scheme = 'com.animatch.animatch';
}
```

Add in `main()`:
```dart
assert(Auth0Config.domain.isNotEmpty, 'AUTH0_DOMAIN must be set via --dart-define');
assert(Auth0Config.clientId.isNotEmpty, 'AUTH0_CLIENT_ID must be set via --dart-define');
```

Configure CI to use `--dart-define-from-file=config/prod.env.json`.

---

## High-Priority Issues

### H-1 — FCM Tokens and Breeder IDs Logged to Stdout in Production

**File:** `lib/app.dart:68-106` (8 calls)

```dart
print('[FCM] device token: ${token ?? "NULL — FCM token unavailable"}');
print('[FCM] token registered with backend for breederId=${breeder.id}');
```

`print()` is live in release builds. On Android, any app with `READ_LOGS` can read `logcat`. All calls use `// ignore: avoid_print` to silence the linter.

**Fix:** Replace every `print()` in `app.dart`, `match_provider.dart` (9 calls), and `register_screen.dart` (1 call with full stack trace) with `debugPrint()`, which is a no-op in release mode.

---

### H-2 — `onTokenRefresh` Stream Subscription Never Cancelled — Memory Leak

**File:** `lib/app.dart:83-87`

```dart
notificationService.onTokenRefresh.listen((newToken) {
  deviceTokenService.register(newToken, breederId: breeder.id);
});
```

The `StreamSubscription` is never stored or cancelled. On logout and re-login a second subscription stacks on top, registering the token twice per refresh with stale `breeder.id` captures.

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

---

### H-7 — Stream Chat API Key Hardcoded in Source

**File:** `lib/core/services/stream_chat_service.dart:3-4`

```dart
static const _apiKey = 'chbd9fpt9qxu';
```

Unlike Auth0, there is no `String.fromEnvironment` override mechanism. The key is compiled into every build.

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

---

### M-2 — `HerdAnimal` and `MatchItem` Not on Freezed

**Files:** `lib/features/herd/domain/herd_animal.dart`, `lib/features/matches/domain/match_item.dart`

Same reasoning as M-1. Both are passed via `state.extra!` (compounding H-6) and updated via manual `copyWith`.

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

**L-2** — `match_provider.dart`: 9 `print()` calls log channel IDs and user IDs. Replace with `debugPrint()`.

**L-3** — `register_screen.dart:26`: Full exception stack trace printed on signup error. Replace with `debugPrint()`.

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
- [ ] **C-1** Generate production keystore; configure release signing and R8 in `build.gradle.kts`
- [ ] **C-2** Add `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription`, `NSPhotoLibraryAddUsageDescription` to `ios/Runner/Info.plist`
- [ ] **C-3** Verify `google-services.json` is not git-tracked; restrict Firebase API key in Firebase Console
- [ ] **C-4** Remove hardcoded `defaultValue` from `Auth0Config`; configure CI `--dart-define-from-file`

### Before production traffic
- [ ] **H-1** Replace all `print()` in `app.dart` with `debugPrint()` (8 calls)
- [ ] **H-2** Store and cancel `onTokenRefresh` subscription in `_AnimatchAppState`
- [ ] **H-3** Store and cancel Firebase/notification subscriptions via `ref.onDispose` in `routerProvider`
- [ ] **H-4** Add `sendTimeout` to both Dio instances (`api_client.dart` and `cloudinary_uploader.dart`)
- [ ] **H-5** Add debug-only `network_security_config.xml` for Android cleartext to localhost
- [ ] **H-6** Migrate `state.extra!` routes to path parameters with provider-based loading
- [ ] **H-7** Move Stream Chat API key to `String.fromEnvironment('STREAM_CHAT_API_KEY')`
- [ ] **L-2/L-3** Replace `print()` in `match_provider.dart` and `register_screen.dart` with `debugPrint()`

### Medium priority
- [ ] **M-1/M-2** Migrate `Breeder`, `HerdAnimal`, `GeneticIndices`, `MatchItem` to freezed
- [ ] **M-3** Refine `restoreSession` to catch only `CredentialsManagerException`, not all exceptions
- [ ] **M-4** Add server-side enforcement for `editProfile` access; add client-side profile refresh on foreground
- [ ] **M-5** Add CPF Luhn checksum validation in `profile_verification_screen.dart`
- [ ] **L-1** Implement `hasSeenOnboarding` Hive flag in `onboarding_screen.dart`
- [ ] **L-4** Delete local profile picture on logout in `AuthNotifier.logout()`
- [ ] **L-5** Write provider unit tests, repository mock tests, and router redirect tests
