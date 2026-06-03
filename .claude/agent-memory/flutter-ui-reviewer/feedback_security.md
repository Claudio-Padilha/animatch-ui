---
name: Security Review Findings
description: Security-relevant patterns observed in Animatch production review — hardcoded keys, leaking tokens via print, stream subscription leaks
type: project
---

## Confirmed Security Issues (May 2026 Review)

### Hardcoded Credentials
- Auth0 domain `dev-akrxwodm47ylsucp.us.auth0.com` and client ID `NZ6SL0brELjh8JqbsVG5ROfT1ujt9dYN` are in `defaultValue` of `String.fromEnvironment` — compiled into all builds.
- Stream Chat API key `chbd9fpt9qxu` is a raw Dart const in `stream_chat_service.dart:4`.
- Firebase API key `AIzaSyCvCNoknoZIt0QtKrUSsdv8R4_LNz5ce1A` is in both `firebase_options.dart` and `google-services.json`. File is gitignored but exists on disk and appears tracked.
- Auth0 domain also hardcoded in `build.gradle.kts:33` manifest placeholder.

**Why:** These were likely set for rapid development iteration and never extracted before the codebase matured.
**How to apply:** Flag any new config values and require `String.fromEnvironment` with no defaultValue for anything non-trivially public.

### FCM Token Exposure
FCM device token and breeder internal ID are printed to logcat on every login (`app.dart:72–77`). These calls have `// ignore: avoid_print` so they pass analysis but remain in release builds.

### Release Signing
Android release build uses debug keystore (`build.gradle.kts:41`). No production keystore configured. Must be resolved before any Play Store submission.

### Missing iOS Permissions
`NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` absent from `Info.plist`. Will cause crash on first camera/gallery access. Must be added before any TestFlight or App Store build.
