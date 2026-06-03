---
name: Animatch Codebase Patterns
description: Architecture observations, model migration debt, routing patterns, and recurring issues found in the May 2026 production readiness review
type: project
---

## Architecture — What Is Working Well

- All HTTP calls go through repository classes (no direct Dio from widgets or providers). Convention is strictly followed.
- go_router named routes used throughout — no Navigator.push bypasses found.
- Riverpod provider scoping is correct: AsyncNotifierProvider for server data, autoDispose on family providers.
- `ref.watch` in build, `ref.read` in callbacks — correctly applied.
- Auth0 via `webAuthentication` with credential manager for token refresh — solid auth foundation.
- `cached_network_image` used for all remote images consistently.
- `const` constructors used broadly.
- All user-facing strings are in pt_BR Portuguese.

## Model Migration Debt

`Breeder`, `HerdAnimal`, `GeneticIndices`, and `MatchItem` are NOT on freezed — they are hand-rolled mutable classes with manual `copyWith`. A TODO in `breeder.dart:1` acknowledges this. Migration is a longer-term task. Freezed models DO exist for discover and some shared domain objects.

**Why it matters:** No generated equality means Riverpod cannot deduplicate state updates. Manual copyWith on Breeder silently excludes `id` and `email` from the signature.

## Hardcoded Secrets / Credentials Pattern

Auth0 uses `String.fromEnvironment` correctly but with hardcoded `defaultValue` fallbacks, meaning the dev credentials are compiled into every build. Stream Chat API key is a raw const string with no environment override. Firebase options are generated Dart source committed to the repo.

**Standard for this codebase:** Config values should use `String.fromEnvironment` with NO defaultValue for production secrets. CI must pass `--dart-define-from-file`.

## Routing — state.extra Pattern

The router passes complex objects (HerdAnimal, MatchItem, AnimalDetailData) via `state.extra`. All six object-carrying routes use `state.extra!` (force unwrap), which crashes on deep-link or OS-restored navigation where extra is null. IDs should be in path parameters; data should be loaded from providers by ID in the screen.

## Notification / Stream Subscription Leaks

- `onTokenRefresh` stream in `app.dart._onLogin()` is not stored or cancelled — recreated on every login.
- Firebase `onMessageOpenedApp` and `onLocalTap` subscriptions in `routerProvider` are not cancelled.
- `NotificationService.onMessage` subscription (in `init()`) is also not stored — single instance, lower risk.

## Android Release Configuration

Release build in `build.gradle.kts` uses debug signing config (explicit TODO comment). No ProGuard/R8 enabled. Not production-ready for Play Store.

## iOS Missing Permissions

`NSCameraUsageDescription` and `NSPhotoLibraryUsageDescription` are absent from `Info.plist`. Camera is used in `profile_verification_screen.dart` and `add_animal_screen.dart`. App will crash on first photo pick on iOS.

## Test Coverage

Near-zero. One smoke test in `test/widget_test.dart` that will fail in CI due to unmocked Firebase/Auth0. No provider unit tests, no repository mock tests, no router redirect tests.

## print() Usage Pattern

All production print() calls carry `// ignore: avoid_print` suppressor comments, which satisfies the linter but leaves them active in release builds. Pattern exists in: `app.dart` (8 calls), `match_provider.dart` (9 calls), `register_screen.dart` (1 call with stack trace). Should be replaced with `debugPrint()`.
