# Animatch Testing Plan

**Date:** 2026-08-04 | **Author:** flutter-test-engineer | **Baseline:** ~10% line coverage (415/3978 lines), 9 test files / 35 tests, no CI, no `integration_test/`.

---

## How to use this document

- Organized by `lib/features/*`, plus a cross-cutting `core/` + `shared/` section.
- Every leaf item is a `- [ ]` checkbox — tick it off as it lands, so this doubles as a backlog.
- Every checkbox is tagged **P0** / **P1** / **P2**:
  - **P0** — money paths (auth, match confirmation, herd CRUD that touches the backend) and regressions for bugs already fixed once in `docs/production-review.md`. If this breaks, a breeder can't use the app or a real deal is lost.
  - **P1** — important feature correctness (validation, empty/error states, navigation guards) that would cause visible bugs or support tickets but not a hard outage.
  - **P2** — polish, rare edge cases, cosmetic states.
- "Mocking" column/notes tell you which approach to use, per project convention (see below) — don't leave it to the implementer to guess.

## Mocking policy (recap — see `.claude/agents/flutter-test-engineer.md` for full reasoning)

- **mocktail** — introduce it for any test that needs `verify()` (assert a dependency was *called*, not just stub a return value) or stubs a class with several methods (e.g. `MatchRepository` has 6 methods; `StreamChatService`/`NotificationService` have several). Added to `pubspec.yaml` (`^1.0.5`) as Phase 0 infrastructure work on 2026-08-13, along with `http_mock_adapter` (`^0.6.1`) for table-style multi-endpoint repository tests. Not yet used in any test file — the tests themselves are separate, later work.
- **Hand-rolled fakes** (`test/helpers/fakes.dart` pattern) — keep for simple state-holding doubles: `FakeAuthRepository`, `FakeOnboardingNotifier`, a `NoopNotificationService`. Extend this file rather than duplicating fakes per test file.
- **Dio** — hand-rolled `HttpClientAdapter` fake (`test/auth/auth_repository_test.dart` pattern) for repositories with 1-3 endpoints. For `HerdRepository`/`MatchRepository`/`ProfileRepository` (4-6 endpoints each, worth covering table-style), consider `http_mock_adapter` instead of hand-rolling six response builders — call this out per-repository below.
- **Do not** mock freezed value objects (`Breeder`, `HerdAnimal`, `MatchItem`, …) — construct real instances with `const`/factory constructors.
- **Do not** add mockito.

---

## 0. Integration test setup (do this once, before any integration_test scenario below)

This repo has **zero** `integration_test/` infrastructure today. Before any scenario in this doc's "Integration test candidates" subsections can run, the harness itself needs to exist.

- [ ] **P1** Add `integration_test: sdk: flutter` to `dev_dependencies` in `pubspec.yaml`.
- [ ] **P1** Create `integration_test/` directory at repo root with an `integration_test/app_test.dart` entrypoint that boots `AnimatchApp` via `IntegrationTestWidgetsFlutterBinding.ensureInitialized()`.
- [ ] **P1** Decide the backend strategy for integration runs — this app has **no test/staging backend configured** (`config/staging.env.json`/`config/production.env.json` are still `REPLACE_ME` per `docs/production-review.md` C-4). Two options, pick one and document it:
  - (a) Point integration tests at a local/dockerized instance of the separate Node.js backend repo, seeded with fixture breeders/animals.
  - (b) Run integration tests against the app with `dioProvider`/`authRepositoryProvider` overridden to fakes at the `ProviderScope` level in the test's `main()` — this only exercises UI/navigation/state wiring, not real network behavior, but requires no backend and no credentials.
  - Recommendation: start with (b) for CI (fast, no secrets), add (a) later behind a manual-trigger CI job once a staging backend exists.
- [ ] **P1** Auth0 in integration tests: real Auth0 login requires a device-level web view / browser handoff (`webAuthentication().login()`), which is not automatable in CI without a headless browser + a dedicated Auth0 test tenant + stored test credentials (secrets management, out of scope for this plan to set up). Until that exists, integration scenarios below use provider overrides to seed a logged-in `Breeder` directly into `authNotifierProvider`, skipping the real Auth0 hop — document this limitation inline in the test file.
- [ ] **P2** Wire an `integration_test` CI job (GitHub Actions, since iOS builds already need `macos-latest` per `CLAUDE.md`) — run on Android emulator at minimum; iOS simulator run is a stretch goal once C-5 (signing) is resolved.

---

## 1. `core/` — router, app bootstrap, network, services

### 1.1 Router (`core/router/router_notifier.dart`, `core/router/app_router.dart`)

Already the best-covered file (`test/router/router_notifier_test.dart`, 8 cases). Gaps:

- [x] Splash gating, onboarding-vs-login, deep-link-to-protected-route, profile-completion gating, editProfile verified/unverified guard — covered.
- [x] **P1** `matchDetail`/`matchAnimalDetail`/`chat` routes: redirect-to-`/matches` when `state.extra` is null (the H-6 mitigation for the missing `GET /matches/:id` backend endpoint). Widget test against the minimal standalone router already used in `router_notifier_test.dart` — push `AppRoutes.matchDetail` and `AppRoutes.chat` with `extra: null`, assert landing on the matches marker. **Done 2026-08-16:** `test/router/app_router_edge_cases_test.dart`, against the real production `routerProvider`. Also covers the non-null-extra case (renders `MatchDetailScreen` normally, no redirect).
- [x] **P1** `animalDetail`/`matchAnimalDetail` routes: when `extra` is present, the loader uses it directly (no provider fetch); when absent, falls back to `animalDetailDataProvider`. Widget test both paths against `AnimalDetailLoader` directly (not the full router) — mock/fake `herdRepositoryProvider` for the fallback path (hand-rolled fake `HerdRepository` subclass, since it's a single method under test: `getAnimal`). **Done 2026-08-16:** `test/shared/animal_detail_loader_test.dart` — 3 cases (extra present skips the fetch, extra absent fetches by id, fetch failure shows the error/retry state). Needed a minimal `GoRouter` (not a bare `MaterialApp`) since `AnimalDetailScreen` renders `AppBottomNav`, which reads `GoRouterState` from context.
- [x] **P1** `myAnimalDetail`/`editAnimal` path-parameter routes resolve `animalId` from `state.pathParameters`, not `extra` — regression test for the H-6 fix (a deep link with no `extra` must not crash). Push the route directly with only a path, no `extra`. **Done 2026-08-16:** `test/router/app_router_edge_cases_test.dart`, against the real production `routerProvider`.
- [x] **P2** ~~Declaration-order regression~~ `editAnimal` (`/rebanho/animal/editar/:animalId`) resolving correctly despite sharing a path prefix with `myAnimalDetail` (`/rebanho/animal/:animalId`) — add a route-table test that pushes `/rebanho/animal/editar/abc123` and asserts it resolves to `EditAnimalScreen`, not `MyAnimalDetailScreen` with `animalId: "editar"`. **Done 2026-08-16:** `test/router/app_router_edge_cases_test.dart`. Needed a 480pt-wide test viewport and a `municipalitiesProvider` override (real impl hits the network and never settles) — both incidental to this test's actual subject; see the file's `_pumpRealRouter` helper. **Correction (flutter-test-engineer review):** the original framing above ("a one-line reordering mistake would reintroduce it silently") is factually wrong and has been struck through — verified both empirically (swapping the two routes' declaration order and rerunning the test still passes) and against go_router 14.8.1 source: a childless route only matches if it consumes the *entire* remaining URL, so the 3-segment `myAnimalDetail` structurally cannot shadow the 4-segment `editAnimal` regardless of order. `docs/production-review.md`'s own H-6 section already reached this same conclusion (line 315) — this item's original wording just didn't cross-check it. The test itself still has value (pins the correct resolution) and was kept, just renamed and re-commented in the test file to not imply a declaration-order hazard that doesn't exist.
- [x] **P1** `routerProvider` notification-tap wiring (`app_router.dart:182-204`): `getInitialMessage()`, `onMessageOpenedApp`, `onLocalTap` each drive `router.go(...)` for `match_confirmed`/`new_message` types. Unit-style test: override `notificationServiceProvider` with a fake that exposes controllable streams, pump a message through each stream, assert `router.location` (or the rendered marker screen) lands on `/matches`. **Mocking:** hand-rolled fake (`NoopNotificationService` subclass) is enough — only 3 stream getters + `getInitialMessage()` are exercised, no verify() needed. Currently **zero coverage** — H-3 in the production review fixed a leak here but never added a test for the actual navigation behavior it protects. **Done 2026-08-16:** `test/core/router_notification_tap_test.dart` — exercises the real production `routerProvider` (not a rebuilt minimal router) via a new `FakeNotificationService` in `test/helpers/fakes.dart` with controllable `StreamController`s; seeded an unverified-but-city-set breeder so it lands on real screens (`MatchesScreen`/`HerdScreen`) without needing to fake out network dependencies, distinguishing them via `AppBar` title since both render an identical `UnverifiedProfilePrompt`. Covers all 3 entry points plus the unrecognized-type no-op case.
- [ ] **P2** Subscription cleanup: `ref.onDispose` cancels `msgSub`/`tapSub` — test via `ProviderContainer.dispose()` + a spy stream (mocktail `verify(() => stream.listen(...).cancel())` is awkward for `Stream.listen`; simplest is a hand-rolled `StreamController` fake asserting `hasListener == false` after dispose).

### 1.2 `AnimatchApp` (`lib/app.dart`)

Currently only exercised indirectly by the `widget_test.dart` smoke test (renders once, no lifecycle/login/logout behavior asserted).

- [x] **P0** `_onLogin`: on `authNotifierProvider` transitioning null → non-null, requests notification permission, registers FCM token via `deviceTokenServiceProvider`, and subscribes to `onTokenRefresh`. Widget test: pump `AnimatchApp` with `authNotifierProvider` overridden to a controllable `Notifier`, fake `notificationServiceProvider` + `deviceTokenServiceProvider` (mocktail — `DeviceTokenService.register()` call needs `verify()`), transition state, assert `register()` was called once with the right `breederId`. **Known blocker:** `_onLogin`/`_onLogout` are gated `if (kIsWeb) return;` — this logic is untestable under `flutter test`'s default web-like test environment unless `kIsWeb` is forced false, which isn't possible via a simple override (it's a compile-time constant from `flutter/foundation.dart`). Flutter widget tests actually run under the VM (not web) by default, so `kIsWeb` is `false` in `flutter test` — confirm this before writing the test, don't assume. **Done 2026-08-16:** `test/app_test.dart` — confirmed the blocker note (`kIsWeb` is false under `flutter test`); used call-tracking `FakeDeviceTokenService`/`FakeNotificationService` (plain fakes, not mocktail — matches this repo's "verify() needs → mocktail, simple state-holding → hand-rolled fake" convention) rather than mocktail. Landing screen after login needed a `city` on the seeded `Breeder` plus a `herdRepositoryProvider` override, otherwise the router lands on `ProfileCompletionScreen`'s `AddressFormFields`, which hits the real (unmockable-in-this-test) `municipalitiesProvider` and leaves a perpetually-animating spinner that `pumpAndSettle` never clears.
- [x] **P0** Double-subscription regression (H-2): calling `_onLogin` twice (e.g. login → logout → login) must not stack `onTokenRefresh` listeners. Assert `_tokenRefreshSub` is cancelled+reassigned, not accumulated — observable via a fake `onTokenRefresh` stream counting active listeners. **Done 2026-08-16:** `test/app_test.dart` — asserts both `StreamController.hasListener` transitions (true → false on logout → true again on re-login) and, more precisely, that a single `onTokenRefresh` event after the second login produces exactly one new `register()` call, not two (which a stacked listener would produce).
- [x] **P1** `_onLogout`: unregisters the FCM token via `deviceTokenServiceProvider.unregister()`. Same fake/mocktail setup as above. **Done 2026-08-16:** `test/app_test.dart`.
- [x] **P1** `didChangeAppLifecycleState(resumed)` calls `authNotifierProvider.notifier.refreshBreeder()` (the M-4 foreground-refresh fix). Widget test: drive `WidgetsBinding.instance.handleAppLifecycleStateChanged(AppLifecycleState.resumed)` (or the tester equivalent) after pumping `AnimatchApp`, assert a fake `AuthRepository.refreshBreeder()` was invoked. Currently **zero coverage** — this is a real fix from the production review with no regression test. **Done 2026-08-16:** `test/app_test.dart`, via `tester.binding.handleAppLifecycleStateChanged(...)`.
- [ ] **P1** `_initAuthAndOnboarding`: awaits both `restoreSession()` and `hasSeenOnboardingProvider.load()` before setting `authInitializedProvider = true`. Assert the router stays on splash until both resolve (already indirectly covered by `router_notifier_test.dart`'s "stays on splash" case, but not from `AnimatchApp`'s actual bootstrap path — add one test that goes through `_initAuthAndOnboarding` itself with a deliberately slow fake `restoreSession()`). **Not done** — `test/app_test.dart` covers `_onLogin`/`_onLogout`/lifecycle but not this specific bootstrap-ordering path; genuine remaining gap.
- [x] **P2** `kDebugMode`-gated log lines (H-1 fix) — not worth a dedicated test (nothing user-observable to assert); covered implicitly by the above tests exercising the code paths without crashing. **Confirmed 2026-08-16** — `test/app_test.dart`'s tests exercise every `_onLogin`/`_onLogout` code path (including the `[FCM]` debug log lines, visible in test stdout) without a dedicated assertion, as this item recommended.

### 1.3 `core/network/api_client.dart`

- [ ] **P0** Auth interceptor attaches `Authorization: Bearer <token>` when `auth0.credentialsManager.credentials()` succeeds. **Known blocker:** `dioProvider` constructs its own `Auth0` client internally from `Auth0Config` (same pattern/limitation as `AuthRepository` — not constructor-injectable). Cannot unit test the interceptor's Auth0-success branch without either a DI refactor (inject an `Auth0`-like interface) or a device. Flag as a gap, do not attempt a workaround. **Still blocked 2026-08-16** — unlike `AuthRepository`, `dioProvider` itself was not refactored to accept an injectable `Auth0` (item #2 in the "Known blockers" table below remains open); doing so would touch the app's core network provider used by every other repository, judged out of scope for this pass. Flagging as a deliberate, not forgotten, gap.
- [x] **P1** Auth interceptor proceeds without the header when credentials fail (not logged in) — same blocker as above; this branch is at least reachable in a fresh `Dio()` + real `Auth0Config` (no stored credentials in a test environment naturally fails `credentials()`), so this specific branch **is** testable today: construct via `ref.read(dioProvider)` in a `ProviderContainer`, issue a request against a fake adapter, assert no `Authorization` header when no credentials are stored. Confirm this doesn't hang/timeout waiting on a real network call inside `credentialsManager.credentials()` — if it does, this is blocked too and should be documented as such rather than left flaky. **Done 2026-08-16:** `test/core/api_client_test.dart` — confirmed not blocked (fails fast under `flutter test`'s lack of a real platform channel, doesn't hang); bounded with an explicit `.timeout()` + descriptive failure message so a future regression that *does* hang fails clearly instead of silently blocking the test run. Verified stable across repeated runs.
- [x] **P2** `connectTimeout`/`receiveTimeout`/`sendTimeout` values (H-4 fix) — one assertion against `dio.options` reading back the configured `BaseOptions`, no network needed. **Done 2026-08-16:** `test/core/api_client_test.dart`.

### 1.4 `core/services/notification_service.dart`

- [ ] **P1** `_showForeground` message routing: `message.data['type']` of `message.new` vs `match_confirmed` vs unknown builds the right title/body/payload and calls `_local.show(...)`. **Known blocker:** `_local` is a real `FlutterLocalNotificationsPlugin()` field, not injected — calling `.show()` hits a platform channel that isn't available in `flutter test`. Needs either a constructor-injectable plugin instance or a platform-channel mock (`TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler` on the `flutter_local_notifications` channel) to unblock — flag as a gap; the mock-channel approach is the more surgical fix if pursued, cheaper than a DI refactor for this single service.
- [ ] **P1** `getToken()`/`onTokenRefresh`/`requestPermission()`/`getInitialMessage()`/`onMessageOpenedApp` — all thin wrappers around `FirebaseMessaging.instance`. **Known blocker:** same as above, `_fcm` calls the real Firebase plugin. The lazy-getter fix (already done, per L-5 in the production review) makes *subclassing* `NotificationService` and overriding these methods viable (as `NoopNotificationService` already demonstrates) — so this class itself isn't unit-testable beyond "does a fake subclass satisfy the interface," which is already implicitly covered by `widget_test.dart`. No further action needed here beyond what H-3's router test (1.1) already exercises via the fake.
- [ ] **P2** `_onBackgroundMessage` top-level function — same platform-channel blocker, plus it's documented to run in a separate isolate; not practically unit-testable. Skip; note the gap.

### 1.5 `core/services/device_token_service.dart`

- [x] **P0** `register()` POSTs `{breederId, token, platform}` with the right platform string. **Mocking:** hand-rolled Dio `HttpClientAdapter` fake (same pattern as `auth_repository_test.dart`) — capture the request body and assert `platform` matches `Platform.isIOS` (note: `Platform.isIOS`/`isAndroid` read the *host* OS running the test, not a mockable value in a plain `flutter test` run on Linux CI — this will always resolve to `'android'` in CI. If asserting the iOS branch matters, it needs `Platform` to be injected/overridden, which isn't currently possible; document as a minor gap, not worth a refactor for one string). **Done 2026-08-16:** `test/core/device_token_service_test.dart` (used `http_mock_adapter` instead of hand-rolled, for consistency with the rest of this batch) — asserts against `Platform.isIOS ? 'ios' : 'android'` rather than a hardcoded string, so the test doesn't itself assume the CI host OS.
- [x] **P1** `unregister()` DELETEs the right URL-encoded token path. Same fake pattern. **Done 2026-08-16:** `test/core/device_token_service_test.dart`.

### 1.6 `core/services/cloudinary_uploader.dart`

- [x] **P1** `pickAndUpload()` returns `null` when the user cancels the picker (`ImagePicker().pickImage()` returns `null`). **Blocker resolved 2026-08-13:** `CloudinaryUploader(this._dio, {ImagePicker? imagePicker})` now accepts an injected `ImagePicker` (default `ImagePicker()` unchanged for real callers; note the constructor is no longer `const`, since `ImagePicker` has no const constructor to default to). A mocktail `MockImagePicker` can now drive every branch of this method. **Done 2026-08-16:** `test/core/cloudinary_uploader_test.dart` — cancellation returns null with no network call, and `source`/`imageQuality: 80` are passed through correctly to the picker. **New sub-blocker found:** the actual signature-fetch + Cloudinary-upload round trip (success/failure branches) is *not* reachable from a unit test — the upload itself goes through a private `static final _cdnDio = Dio(...)` field (a plain, uninjectable Dio hardcoded to `api.cloudinary.com`), unlike `_dio` which is constructor-injected. Would need the same DI treatment (`Dio? cdnDio` constructor param) to unblock; not attempted here since it's a production code change beyond just adding tests.
- [ ] **P1** Once unblocked: signature request hits `/upload/signature` with the right `folder` query param, and the upload POST includes `api_key`/`timestamp`/`signature`/`folder`/`file` fields, returning `secure_url`. **Mocking:** hand-rolled fake for the auth'd `_dio`; the `_cdnDio` static field is harder to intercept (it's a `static final` built once) — same DI gap, would need to become instance-level and injectable too.

### 1.7 `core/services/stream_chat_service.dart`

- [ ] **P1** `connectUser()`: no-ops when the same user is already connected; disconnects a different user first; otherwise connects. **Mocking:** mocktail against `StreamChatClient` — this is exactly the "several methods, need to verify call sequencing" case mocktail is for (`client.state.currentUser`, `disconnectUser()`, `connectUser()` — asserting `disconnectUser()` is/isn't called depending on prior state needs `verify()`/`verifyNever()`). **Known blocker:** `client` is constructed in a field initializer from `StreamChatClient(_apiKey, ...)` — not injectable. Needs a constructor parameter (`StreamChatService({StreamChatClient? client})`) to allow a mocktail `MockStreamChatClient` to be passed in. Flag as a source change needed before this is testable at all.
- [ ] **P2** `openChannel()` calls `client.channel(type, id: id).watch()` and returns it — same DI blocker as above.

### 1.8 `core/theme/app_theme.dart`

Already ~100% covered per the coverage audit — no further action.

---

## 2. `features/auth`

### 2.1 Domain: `Breeder` (freezed)

- [x] **P0** `fromJson` field mapping: `pictureUrl`→`avatarUrl`, `propertyName`→`farmName`, `profileStatus`→`status` (via `BreederStatus.fromJson`), default `associations: []`. Currently **zero direct test** — M-1 in the production review says this was "verified with a throwaway test... then deleted." Re-add it permanently; this is core session-state parsing. **Done 2026-08-13:** `test/auth/breeder_test.dart`.
- [x] **P0** `BreederStatus.fromJson`: `'active'` → active, `'rejected'` → rejected, anything else (including `'pending_activation'` and unknown values) → pending. Table-driven test over all four cases. **Done 2026-08-13:** `test/auth/breeder_test.dart` (also covers `null`→pending).
- [x] **P1** `copyWith(id:, email:)` actually works (the M-1 bug: hand-rolled `copyWith` used to silently exclude these two fields). One-line regression test now that it's freezed-generated. **Done 2026-08-13:** `test/auth/breeder_test.dart`.
- [x] **P1** `verifiedBreeder` getter (`status == BreederStatus.active`). **Done 2026-08-13:** `test/auth/breeder_test.dart`.
- [x] **P2** Generated equality/hashCode for `Breeder` (two same-value instances equal, one differing field not). **Done 2026-08-13:** `test/auth/breeder_test.dart`.

### 2.2 `AuthRepository` (`data/auth_repository.dart`)

- [x] `refreshBreeder()` — success, network error, 5xx — covered in `test/auth/auth_repository_test.dart`.
- [x] **P0** `login()`: on 422/404 from `/auth/sync-breeder` (no backend account yet), falls back to `_breederFromCredentials()` built from the JWT. On any other error, rethrows. **Known blocker:** `login()` first calls `_auth0.webAuthentication(...).login()`, which requires a real browser handoff — not testable without a device or a DI refactor to inject an `Auth0`/`WebAuthentication` interface. This blocks the *whole* method, not just the fallback branch. Flag clearly: `login()` and `signUp()` are **not unit-testable today**; the fix is making `AuthRepository` accept an `Auth0`-shaped dependency in its constructor (same fix needed for 2.2's `restoreSession()` Auth0 branch and `getFreshToken()`). **Done 2026-08-16 — blocker fully resolved:** `test/auth/auth_repository_test.dart` now uses mocktail `MockAuth0`/`MockWebAuthentication`/`MockCredentialsManager` (both `Auth0` and `CredentialsManager` are plain/abstract classes, mockable via `implements`; `Credentials`/`UserProfile` from `auth0_flutter_platform_interface` have real public constructors for building fixtures). Covers both the 404 and 422 fallback cases and the rethrow-on-other-errors case.
- [x] **P0** `syncBreeder()`: posts the given name/address, and — if the response omits city (edge case, backend inconsistency), merges the form's `city`/`state` back in. This part **is** testable today (no Auth0 call, pure Dio) — hand-rolled `HttpClientAdapter` fake, two cases: response includes city (pass-through) vs response omits city (merge fallback). Currently zero coverage despite being fully testable now. **Done 2026-08-16:** `test/auth/auth_repository_test.dart`.
- [x] `restoreSession()` — backend-sync-fails-but-Auth0-valid fallback path is *not* directly testable (per M-3's own note: `CredentialsManagerException` branch needs Auth0). But note: the current test file only covers `refreshBreeder()`; **`restoreSession()` has zero test coverage at all**, including its testable-in-principle "backend call throws → falls back to `_breederFromCredentials`" branch, which is blocked by the same "no injectable Auth0 client" issue as `login()`. **Done 2026-08-16:** `test/auth/auth_repository_test.dart` — all three branches now covered (no creds → null, valid creds + sync success, valid creds + sync failure → JWT fallback), the M-3 blocker is resolved.
- [x] **P1** `logout()` — thin Auth0 wrapper, same blocker. **Done 2026-08-16:** `test/auth/auth_repository_test.dart`.
- [x] **P1** `getFreshToken()` — returns `null` on any `credentialsManager.credentials()` failure — same blocker. **Done 2026-08-16:** `test/auth/auth_repository_test.dart`.
- [x] **P0** `_breederFromCredentials()` — private, but its logic (falls back through `user.email ?? sub` for name/email, `user.name ?? user.nickname ?? email`) is exercised indirectly by `login()`/`signUp()`/`restoreSession()` fallback paths — all blocked by the same Auth0 DI gap. Once `Auth0` is injectable, this becomes trivially testable via a fake `Credentials`/`UserProfile`. **Done 2026-08-16:** `test/auth/auth_repository_test.dart`, exercised via `signUp()` (which never syncs, so every case goes through this fallback) — email??sub, name??nickname??email, and the all-null-down-to-sub case.

**Summary blocker for this whole section:** `AuthRepository` constructs `Auth0(Auth0Config.domain, Auth0Config.clientId)` in its own constructor initializer list (`auth_repository.dart:11`). Every method that touches `_auth0` (`login`, `signUp`, `restoreSession`'s credentials-fetch, `logout`, `getFreshToken`) is unreachable in a unit test. **Recommended fix:** add an optional constructor parameter (`AuthRepository(this._dio, {Auth0? auth0}) : _auth0 = auth0 ?? Auth0(...)`), then a mocktail `MockAuth0`/hand-rolled fake can drive every branch above. This single change unblocks roughly half of this file's untested surface — worth prioritizing as **P0 infrastructure work**, not a "nice to have."

- [x] **P0** *(infrastructure)* Refactor `AuthRepository` to accept an injectable `Auth0` dependency, as described above. Unblocks `login()`, `signUp()`, `restoreSession()`'s credentials branch, `logout()`, `getFreshToken()`. **Done 2026-08-13:** `AuthRepository(this._dio, {Auth0? auth0})`, optional param, default behavior unchanged. Tests for the unblocked methods are still not written — that's separate follow-up work, not part of this infra item.

### 2.3 `AuthNotifier` (`providers/auth_provider.dart`)

- [x] `restoreSession()` sets/leaves-null state — covered.
- [x] `refreshBreeder()` no-op-when-logged-out / updates-on-success / leaves-cached-on-failure (M-4) — covered.
- [x] **P0** `login()`/`signUp()`/`syncBreeder()` — set `state` to the repository's return value. Trivial with `FakeAuthRepository` (already exists in `test/helpers/fakes.dart` — just needs `loginResult`/`signUpResult`/`syncBreederResult` fields added, following the existing `restoreSessionResult` pattern). **Zero coverage today** despite being cheap to add — these are the actual login/signup/profile-completion state transitions. **Done 2026-08-16:** `test/auth/auth_provider_test.dart`.
- [x] **P1** `updateBreeder()` — direct state set, used by `profile_screen.dart`'s `currentBreederProvider` listener and `profile_provider.dart`'s `activate()`/`updateProfile()`. One-line test. **Done 2026-08-16:** `test/auth/auth_provider_test.dart`.
- [x] **P0** `logout()` — calls repository logout then clears state. `FakeAuthRepository` extension needed (track `logoutCalls`, assert state becomes null after). **Done 2026-08-16:** `test/auth/auth_provider_test.dart`.
- [x] `authInitializedProvider` — implicitly covered via router tests; no dedicated unit test but low-value to add one (single boolean flip).

### 2.4 UI: `login_screen.dart` / `register_screen.dart`

- [x] **P1** Tapping "Entrar"/"Criar conta" calls `authNotifierProvider.notifier.login()`/`signUp()`, shows a loading spinner while pending, disables the button. Widget test with `authRepositoryProvider` overridden to a fake with a controllable `Future` (delay via `Completer`) to assert the intermediate loading state — per persona convention, prefer explicit `pump()` over `pumpAndSettle()` here specifically to catch the spinner mid-flight. **Done 2026-08-16:** `test/auth/login_screen_test.dart`, `test/auth/register_screen_test.dart` — `_SlowLoginAuthRepository`/`_SlowSignUpAuthRepository` local test doubles with a controllable `Completer`, same pattern as §8.4's `_SlowLogoutAuthRepository`. **Writing this test surfaced a real, significant layout bug** — filed as **K-5** in `docs/known-issues.md`: `LoginScreen` overflows by ~70-95px at standard iPhone width, needing a 500pt-wide test viewport to clear (not just the 430-480pt seen elsewhere); `RegisterScreen` overflows more mildly (8px, clears at 410pt).
- [x] **P1** On a non-cancellation error, shows the Portuguese SnackBar (`'Não foi possível entrar. Tente novamente.'` / signup equivalent). On a `UserCancelled`/`user_cancelled` error string, shows nothing. Fake repository throwing each error type. **Done 2026-08-16:** `test/auth/login_screen_test.dart`, `test/auth/register_screen_test.dart`.
- [x] **P2** Navigation: "Criar conta"/"Entrar" links navigate between the two screens (`context.go`). Widget test against a minimal router with both routes registered (same pattern as `router_notifier_test.dart`'s `_buildRouter`). **Done 2026-08-16:** `test/auth/login_screen_test.dart`, `test/auth/register_screen_test.dart`.

### Integration test candidates (auth)

- [ ] **P0** Full flow: onboarding → register → (mocked) signup success → profile completion → herd screen. Uses the provider-override approach from §0 (seed `authNotifierProvider` after "login" rather than driving real Auth0).
- [ ] **P1** Logout from profile screen → back to login screen, confirm no stale herd/match data is visible after logging back in as a different seeded breeder (guards against provider state leaking across sessions — no existing test covers this at all).

---

## 3. `features/onboarding`

- [x] `OnboardingNotifier`/`hasSeenOnboardingProvider` — default false, `markSeen()` sync state flip + persistence, survives fresh `ProviderContainer` — covered (`test/onboarding/onboarding_provider_test.dart`).
- [x] **P1** `OnboardingScreen` widget behavior: `_finish()` (last slide "Começar" or "Pular") and `_goToLogin()` ("Já tenho conta") both call `markSeen()` before navigating — regression test for the L-1 fix ("reaching the screen at all, via either exit, counts as seen"), which is currently only asserted end-to-end via the router test, not directly against `OnboardingScreen`. Use `FakeOnboardingNotifier`, assert `markSeenCalls == 1` after each exit path. **Done 2026-08-16:** `test/onboarding/onboarding_screen_test.dart` — covers all three exits (Pular, Começar on last slide, Já tenho conta).
- [x] **P1** Page swiping updates `_currentPage`/dots indicator/button label (`'Continuar'` → `'Começar'` on the last slide). Widget test driving `PageView` via `tester.drag()` or `pageController.jumpToPage()`. **Done 2026-08-16:** `test/onboarding/onboarding_screen_test.dart` — advanced via the `Continuar`/`Começar` `FilledButton` (which calls `_next()`, driving the same `PageController.nextPage()` path as a real swipe) rather than `tester.drag()`, simpler and exercises the same `_onPageChanged` callback.
- [x] **P2** `errorMessage` constructor param shows `AppErrorAlert` on first frame and resets to slide 0. Widget test pumping `OnboardingScreen(errorMessage: '...')` directly. **Done 2026-08-16:** `test/onboarding/onboarding_screen_test.dart` — this test (and the page-swiping one) surfaced the same GoogleFonts-fallback fixed-height overflow already documented in `test/widget_test.dart` for this exact screen; applied the same established mute-and-move-on mitigation rather than re-litigating it as a new bug.

---

## 4. `features/splash`

- [x] Fully covered per the coverage audit (static content, no logic). No further action — flag as complete, don't add redundant tests.

---

## 5. `features/herd`

### 5.1 Domain: `HerdAnimal` / `GeneticIndices` (freezed)

- [x] `fromJson` label/bool/address derivation, equality, `copyWith` — covered (`test/herd/herd_animal_test.dart`).
- [x] **P1** `HerdAnimal.fromJson` breed-label fallback: unknown `breed` API value (not in `AnimalBreed` enum) falls back to the raw API value string instead of throwing (`_breedLabel`'s `catch (_)`). Currently untested — a backend adding a new breed value before the client's enum is updated would previously crash the whole `fromJson` chain without this guard; worth a regression test for exactly that scenario. **Done 2026-08-16:** `test/herd/herd_animal_test.dart`.
- [x] **P2** `AnimalSex.fromApiValue` default-to-male on unknown value; `GeneticIndices.fromJson` full field mapping (only tested via `HerdAnimal`'s partial payload today, not standalone with all four+`conformacao` fields populated). **Done 2026-08-16:** `AnimalSex.fromApiValue` in `test/herd/animal_enums_test.dart`; `GeneticIndices.fromJson` standalone in `test/herd/herd_animal_test.dart`.

### 5.2 `animal_enums.dart`

- [x] **P1** `AnimalBreed.label` word-capitalization logic, specifically the lowercase-preposition exception list (`de`, `do`, `da`, `e`) — e.g. `mangalarga_marchador` → `Mangalarga Marchador`, but check a multi-word breed with a preposition renders correctly (none currently exist in the enum, but `fromLabel`/`label` round-tripping for every enum value is cheap and catches a typo in any future addition). Table-driven test over all `AnimalBreed.values`, asserting `fromLabel(label) == original` round-trips for each. **Done 2026-08-16:** `test/herd/animal_enums_test.dart` — `quarto_de_milha` (`AnimalBreed.quartoDeMillha`, note the enum identifier's own typo vs. the apiValue) is the one existing multi-word-with-preposition case, confirmed it renders "Quarto de Milha".
- [x] **P2** `AnimalSex.displayLabel` — 4 combinations (male/female × cattle/horse) → Touro/Vaca/Garanhão/Égua. **Done 2026-08-16:** `test/herd/animal_enums_test.dart`.
- [ ] **P2** `breedsBySpecies`/`sexLabelsBySpecies` — static data, low value to test directly; implicitly covered by any widget test exercising the add/edit animal dropdowns.

### 5.3 `HerdRepository` (`data/herd_repository.dart`)

Zero coverage today. **Mocking:** given 5 endpoints (`getAnimals`, `getAnimal`, `addAnimal`, `updateAnimal`, `deleteAnimal`), consider `http_mock_adapter` for a table-style test file rather than 5 separate hand-rolled adapter setups — first repository in the suite big enough to justify it.

- [x] **P0** `getAnimals(breederId)` — GET `/animals?breederId=X`, parses list via `HerdAnimal.fromJson`. **Done 2026-08-16:** `test/herd/herd_repository_test.dart`.
- [x] **P0** `getAnimal(id)` — GET `/animals/:id`, single object. **Done 2026-08-16:** `test/herd/herd_repository_test.dart`.
- [x] **P0** `addAnimal(payload)` — POST `/animals` with the payload as-is (repository doesn't transform it — the notifier does), returns parsed `HerdAnimal`. **Done 2026-08-16:** `test/herd/herd_repository_test.dart`.
- [x] **P0** `updateAnimal(id, payload)` — PATCH `/animals/:id`. **Done 2026-08-16:** `test/herd/herd_repository_test.dart`.
- [x] **P0** `deleteAnimal(id)` — DELETE `/animals/:id`, void return. **Done 2026-08-16:** `test/herd/herd_repository_test.dart`.
- [x] **P1** All 5 methods propagate `DioException` on failure rather than swallowing it (unlike `AuthRepository`, this repository has **no** try/catch — errors bubble to the calling `AsyncNotifier`, which wraps them via `AsyncValue.guard`). Confirm this is the intended contract (it matches the "repository layer must normalize errors, never throw uncaught" convention only loosely — here "normalizing" means "let `AsyncValue.guard` catch it," not swallow-to-null like `AuthRepository`. Worth one test per method asserting the `DioException` surfaces, so a future accidental try/catch addition doesn't silently break error states). **Done 2026-08-16:** `test/herd/herd_repository_test.dart`.

### 5.4 `HerdNotifier` / `AddAnimalNotifier` / `UpdateAnimalNotifier` / `ToggleAnimalNotifier` / `DeleteAnimalNotifier` (`providers/herd_provider.dart`)

Zero coverage today — this is one of the largest untested files (246 lines, 5 notifiers, all the herd CRUD money paths). **Mocking:** hand-rolled fake `HerdRepository` subclass (5 methods, no complex verify-sequencing needed — state-holding fakes suffice).

- [x] **P0** `HerdNotifier.build()` — returns `[]` when logged out (`authNotifierProvider` is null), otherwise fetches via the repository using the logged-in breeder's id. **Done 2026-08-16:** `test/herd/herd_provider_test.dart`.
- [x] **P0** `HerdNotifier.refresh()` — sets loading, then data/error via `AsyncValue.guard`. No-op if logged out. **Done 2026-08-16:** `test/herd/herd_provider_test.dart`.
- [x] **P1** `HerdNotifier.remove(id)` — filters the given id out of current `AsyncData`, no-ops if state isn't `AsyncData` (e.g. still loading). **Done 2026-08-16:** `test/herd/herd_provider_test.dart`.
- [x] **P1** `HerdNotifier.updateOne(animal)` — replaces matching-id entry in place, preserves others. **Done 2026-08-16:** `test/herd/herd_provider_test.dart`.
- [x] **P0** `AddAnimalNotifier.addAnimal()` — builds the correct payload shape (species/breed/sex API values, nested `address`, conditional `description`/`age`/`registrationNumber`/`photoUrls`/`geneticIndices` — note `geneticIndices` filters out null-valued entries before inclusion). On success: refreshes `herdProvider` **and** invalidates `breederStatisticsProvider` (cross-feature side effect — easy to regress silently, worth its own assertion). On failure: state is `AsyncError`, no refresh/invalidate side effects fire. **Done 2026-08-16:** `test/herd/herd_provider_test.dart`.
- [x] **P0** `UpdateAnimalNotifier.updateAnimal()` — same payload-shape assertions as above (note: uses `'registration_number'` key here vs `'registrationNumber'` in `addAnimal` — **this asymmetry looks like a real bug**, not a documented API contract difference; flag it in the test's own comment when writing this, and separately raise it as a bug candidate, not just a test gap). On success: calls `herdProvider.notifier.updateOne()` (not a full refresh, unlike `addAnimal`) — this is a meaningful behavioral difference worth locking in via test. **Done 2026-08-16:** `test/herd/herd_provider_test.dart` — see updated K-1 note in `docs/known-issues.md`, the "which casing is the bug" assumption flipped on further evidence, left unresolved pending backend confirmation.
- [x] **P0** `ToggleAnimalNotifier.toggle()` — flips `status` between `'active'`/`'paused'` based on `currentlyActive`, calls `updateOne` + invalidates `breederStatisticsProvider` on success. **Done 2026-08-16:** `test/herd/herd_provider_test.dart`.
- [x] **P0** `DeleteAnimalNotifier.deleteAnimal()` — calls `herdProvider.notifier.remove()` + invalidates `breederStatisticsProvider` on success only (not on failure — confirm this branch explicitly, since a failed delete leaving a "ghost" removed-from-UI animal would be a real bug to catch here). **Done 2026-08-16:** `test/herd/herd_provider_test.dart`.

### 5.5 `selectedAnimalProvider`

- [x] **P1** `select()`/`build()` — trivial `Notifier<HerdAnimal?>`, but it's the linchpin connecting Herd → Discover → Matches (an unselected animal blocks both of those screens). One test: default null, `select(animal)` updates state, `select(null)` clears it (used by the "Trocar" flow in `discover_screen.dart`). **Done 2026-08-16:** `test/herd/herd_provider_test.dart`.

### 5.6 UI: `herd_screen.dart`

- [x] **P0** Unverified breeder sees `UnverifiedProfilePrompt`, not the herd list (regression surface for the verification gating pattern reused across herd/discover/matches — currently **zero widget-level test** of this gating anywhere, only the router-level `editProfile` guard is tested). **Done 2026-08-16:** `test/herd/herd_screen_test.dart`.
- [x] **P0** Loading / error (with retry button invalidating `herdProvider`) / empty (`_EmptyHerd` CTA) / populated states — table-driven widget test overriding `herdProvider` via `AsyncNotifier` overrides for each `AsyncValue` state. **Done 2026-08-16:** `test/herd/herd_screen_test.dart` — the error case needed `ProviderContainer(retry: (retryCount, error) => null, ...)`, same Riverpod 3.x retry-disabling fix noted in §8.3.
- [x] **P1** Selecting an animal (`_SelectButton`) updates `selectedAnimalProvider` and navigates to Discover (`context.go`) — needs a router in the widget test, not just `pumpWidget` in isolation. **Done 2026-08-16:** `test/herd/herd_screen_test.dart`.
- [x] **P1** Quota bar (`_QuotaBar`) — `count/limit` fraction and "limit atingido" copy switch at `count >= 5`. Pure widget test, no provider mocking needed beyond a fixed animal list. **Done 2026-08-16:** `test/herd/herd_screen_test.dart` — writing this test surfaced a real layout bug, filed as **K-4** in `docs/known-issues.md`: `_QuotaBar`'s header row overflows horizontally at 390pt (standard iPhone width) and even marginally at 430pt; the test viewport was widened to 480pt to route around it, which does not fix the underlying issue.
- [x] **P2** Tapping an animal card navigates to `myAnimalDetailPath`. **Done 2026-08-16:** `test/herd/herd_screen_test.dart`.
- [x] **P2** `_AvailabilityChip` label/color for available vs unavailable. **Done 2026-08-16:** `test/herd/herd_screen_test.dart` — label only, not color (low value beyond label per the original note).

### 5.7 UI: `add_animal_screen.dart`

- [x] **P0** Form validation: name, breed, sex required (property name / address also validated via `AddressFormFields`); submit blocked with visible error text when any required field is empty. This is the **first form-validation widget test in the repo** — production review's L-5 explicitly called out "form-validator coverage beyond CPF" as an open gap. **Done 2026-08-16:** `test/herd/add_animal_screen_test.dart`.
- [x] **P0** Species change resets breed/sex selection (`_onSpeciesChanged` — regression-worthy since it's a stateful side effect a naive refactor could drop). **Done 2026-08-16:** `test/herd/add_animal_screen_test.dart`.
- [x] **P1** Successful submit calls `addAnimalProvider.notifier.addAnimal()` with the exact expected payload derived from form input (mirrors 5.4's payload test, but from the UI entry point — catches wiring bugs between the widget and the provider, e.g. a controller not being `.trim()`-ed, that a provider-only test wouldn't). **Done 2026-08-16:** `test/herd/add_animal_screen_test.dart`.
- [x] **P1** Photo picker: `AnimalPhotoStrip` add/remove wired to `_photoUrls`; max 3 photos enforced (widget disappears when `photoUrls.length >= 3` — see 5.14). **Done 2026-08-16:** `test/herd/add_animal_screen_test.dart` — extended `_pumpScreen` to accept an overridable `cloudinaryUploaderProvider` (default `FakeCloudinaryUploader()`); added a round-trip test (choosing a source uploads and adds a photo tile) and a max-3 test (the add tile/icon disappears after 3 uploads). `onRemove` itself is not separately tested here — considered adequately covered by `AnimalPhotoStrip`'s own widget behavior (removing an index from a list), not worth a dedicated repo-level test.
- [x] **P1** Error SnackBar shown when `addAnimalProvider` resolves to `AsyncError` after submit. **Done 2026-08-16:** `test/herd/add_animal_screen_test.dart`.
- [ ] **P2** DEP/genetic-indices collapsible section expands/collapses; fertility index field only shown when sex is `'Fêmea'`. **Not done** — skipped per this batch's P0/P1 focus.

### 5.8 UI: `edit_animal_screen.dart`

- [x] **P0** Loading/error/data states for `animalDetailProvider(animalId)` (the provider-based fetch this route now requires post-H-6, replacing the old `extra`-only `HerdAnimal` constructor param). **Done 2026-08-16:** `test/herd/edit_animal_screen_test.dart`.
- [x] **P0** Form pre-populated from the loaded `HerdAnimal` (every controller's initial text, dropdown initial values, `_showDep` initial expansion state derived from whether `geneticIndices.isEmpty`). **Done 2026-08-16:** `test/herd/edit_animal_screen_test.dart` covers controller text and dropdown initial values; `_showDep` initial-expansion state was not separately asserted (low value beyond the field-population check).
- [x] **P0** Save: same payload-shape assertions as `AddAnimalNotifier`/`UpdateAnimalNotifier`, from the UI entry point. **Done 2026-08-16:** `test/herd/edit_animal_screen_test.dart`.
- [x] **P0** Delete flow: confirm dialog → `deleteAnimalProvider.deleteAnimal()` → on success navigates to herd (`context.go`); on `AsyncError`, shows the "Erro ao apagar" SnackBar and stays on screen. **Mocking:** the confirm dialog itself (`showConfirmDialog`) returns a real `Future<bool>` from a real `showDialog` — drive it via `tester.tap()` on the dialog's own buttons rather than mocking the dialog function, to keep this an integration-flavored widget test of the real user flow. **Done 2026-08-16:** `test/herd/edit_animal_screen_test.dart`, following exactly this real-dialog approach.
- [x] **P0** Toggle (pause/activate) flow: same confirm-dialog pattern, asserts `_available` flips locally after a successful toggle and the button label/icon swap (Pausar ↔ Ativar). **Done 2026-08-16:** `test/herd/edit_animal_screen_test.dart`.
- [ ] **P2** Breed-from-label parse failure (`_breedFromLabel`'s `catch (_)` returning null) when the animal's stored `breed` string doesn't match any current `AnimalBreed` label — form should render with no breed pre-selected rather than crashing. **Not done** — skipped per this batch's P0/P1 focus.

### 5.9 UI: `my_animal_detail_screen.dart`

- [x] **P1** Resolves the animal by filtering `herdProvider`'s list by id (`list.firstWhere(...)`) — **known edge case, currently unguarded:** if the id isn't in the list (e.g. herd was refreshed and the animal was deleted elsewhere between navigation and render), `firstWhere` throws `StateError`, which `AsyncValue.guard`... actually does **not** wrap this, since the `.whenData` transform runs outside `AsyncValue.guard` — trace this carefully when writing the test; it may be a real unguarded-crash bug worth flagging alongside the test, not just a coverage gap. **Done 2026-08-16 — turns out NOT a bug:** `test/herd/my_animal_detail_screen_test.dart` traced this by reading Riverpod 3.1.0's own `AsyncValue.whenData` source (`riverpod-3.1.0/lib/src/core/async_value.dart`) — it wraps the callback in try/catch internally and converts a thrown error into `AsyncError`, so `firstWhere` throwing when the id isn't in the list correctly renders the "Erro ao carregar animal" retry UI, not an uncaught crash. The concern was reasonable to raise but the current Riverpod version already handles it safely; test asserts this explicitly (empty herd list → error state, not a crash).
- [x] **P1** Loading/error states (delegated to `herdProvider`, with retry via `ref.invalidate(herdProvider)`). **Done 2026-08-16:** `test/herd/my_animal_detail_screen_test.dart`.
- [x] **P2** Photo carousel dot indicator page-sync; edit button navigates to `editAnimalPath`. **Done 2026-08-16:** edit button navigation covered in `test/herd/my_animal_detail_screen_test.dart`; the dot-indicator page-sync itself wasn't (low value, cosmetic).
- [x] **P2** Conditional sections (description, location, genetic indices) only render when present/non-empty. **Done 2026-08-16:** `test/herd/my_animal_detail_screen_test.dart` — writing this surfaced a third instance of the unconstrained icon+text `Row` overflow pattern (`_StatusRow`), folded into **K-4** in `docs/known-issues.md`.

### 5.10 Cross-cutting: verification gating (herd/discover/matches all repeat this pattern)

- [ ] **P1** Extract this into one parameterized/shared widget-test helper (`expectUnverifiedPromptWhenNotVerified(screen)`) exercised against `HerdScreen`, `DiscoverScreen`, `MatchesScreen` — avoids writing the same override-`authNotifierProvider`-with-unverified-breeder boilerplate three times, and guarantees the three screens stay behaviorally consistent if one is refactored.

### Integration test candidates (herd)

- [ ] **P0** Add animal → appears in herd list → edit it → change reflected → delete it → removed from list. End-to-end through real widgets + a faked network boundary (per §0's provider-override strategy).
- [ ] **P1** Hit the 5-animal free-tier quota, confirm the "limite atingido" messaging renders (no hard block exists client-side today per the code read — confirm whether the backend enforces it or if this is purely cosmetic; if purely cosmetic, note that as a product gap alongside the test).

---

## 6. `features/discover`

### 6.1 Domain: `DiscoverAnimal`

- [x] **P0** `fromJson` — breed-label lookup with fallback to raw API value on unknown breed (same pattern/gap as `HerdAnimal`, currently **also untested**), sex label, address flattening, `pendingMatchId`/`geneticIndices` optionality. Zero coverage today despite this being the primary swipe-card data source. **Done 2026-08-16:** `test/discover/discover_animal_test.dart`.
- [x] **P1** `locationFull` / `ageLabel` getters (singular "1 ano" vs plural "X anos" — a pt_BR pluralization edge case worth locking in). **Done 2026-08-16:** `test/discover/discover_animal_test.dart`.

### 6.2 `DiscoverRepository`

- [x] **P0** `getSuggestions(animalId)` — GET `/matches/suggestions/:animalId`, parses list. Zero coverage; single-method repository, hand-rolled Dio fake is sufficient (no need for `http_mock_adapter` here). **Done 2026-08-16:** `test/discover/discover_repository_test.dart` (used `http_mock_adapter` for consistency with the other repository test files, not a hand-rolled adapter — negligible either way for one endpoint).

### 6.3 `suggestionsProvider`

- [x] **P1** `FutureProvider.family` wraps the repository call per-animal-id, `autoDispose` — test cache invalidation behavior (`ref.invalidate(suggestionsProvider(id))`, used when a swipe stack empties) actually triggers a re-fetch. `ProviderContainer` test, hand-rolled fake repository. **Done 2026-08-16:** `test/discover/suggestions_provider_test.dart`.

### 6.4 UI: `discover_screen.dart`

This is the largest untested screen (734 lines) and sits on the primary matching flow (CLAUDE.md: "Primary matching signal: geo-proximity" via this exact screen).

- [x] **P0** Unverified → prompt; no animal selected → `_NoAnimalSelected` CTA to herd; both currently untested. **Done 2026-08-16:** `test/discover/discover_screen_test.dart`'s new "screen states" group.
- [x] **P0** Loading/error/no-suggestions/populated states for `suggestionsProvider`. **Done 2026-08-16:** `test/discover/discover_screen_test.dart`.
- [x] **P0** Like flow (`_onLike`): calls `createMatch` (new) or `confirmMatch` (existing `pendingMatchId`) depending on whether the suggestion already has a pending match from the other side — **this branch (pending-match vs fresh) is a real business-logic fork with zero test coverage**, and getting it wrong either double-creates matches or fails to confirm a mutual like. On `status == 'confirmed'` response, shows the celebration dialog; on any other status (still pending — first-side like), does not. **Mocking:** mocktail for `MatchRepository` here specifically — need to verify *which* of `createMatch`/`confirmMatch` was called based on `pendingMatchId`, a clear verify() case. **Done 2026-08-16:** `test/discover/discover_screen_test.dart` — this is the repo's first mocktail usage; swipe triggered via `CardSwiperController.swipe()` by tapping the Curtir/Passar `CircleActionButton`s (scoped past the ambiguous `favorite_rounded` icon reused by `_SelectedAnimalBanner`).
- [x] **P0** Reject flow (`_onReject`): same `pendingMatchId`-branching logic as like, via `rejectMatch`/`createMatch(status: 'rejected')`. Same mocktail rationale. **Done 2026-08-16:** `test/discover/discover_screen_test.dart`.
- [x] **P1** Network failure during like/reject shows the Portuguese SnackBar, doesn't crash the swiper. **Done 2026-08-16:** `test/discover/discover_screen_test.dart`.
- [x] **P1** `_seenIds` bookkeeping: swiping past a card marks it seen and it's excluded from `unseen` on the next provider read; when `unseen` is exhausted mid-session, `suggestionsProvider` is invalidated to re-fetch (fresh suggestions after exhausting the current batch). **Partially done 2026-08-16:** `test/discover/discover_screen_test.dart` — the swipe-marks-seen half is covered (two candidates, swipe one via the action button, assert it disappears while the other remains). The re-fetch-on-exhaustion half (`ref.invalidate(suggestionsProvider(...))` when `newIndex == null`) is **not** covered — would need to assert a second call into the suggestions repository/provider after the batch is exhausted, not attempted in this pass.
- [x] **P1** Tapping a card navigates to `animalDetailPath` with `extra: AnimalDetailData.fromDiscoverAnimal(...)`; a `true` pop result (liked/passed from the detail screen) marks that id seen back on this screen — cross-screen state sync currently untested. **Done 2026-08-16:** `test/discover/discover_screen_test.dart` — covers the pushed route + extra, `pop(true)` marking seen (last candidate disappears → `_NoSuggestions`), and `pop(false/null)` (system back) leaving it visible. Used a minimal `GoRouter` with a stub `animalDetail` route rather than the full router.
- [ ] **P2** `_FilterBar`/distance filter — currently **client-side only** (`_selectedDistance` local state, not actually wired into `suggestionsProvider`'s query per the code read — confirm this and flag as a product gap, not a missing test, if the filter genuinely does nothing to the results today).
- [ ] **P2** Match celebration dialog pulse animation, "Ver Match"/"Continuar explorando" button actions.

### Integration test candidates (discover)

- [ ] **P0** Two seeded animals (fixture data via §0's fake-backend approach) mutually liking each other → confirmed match → celebration dialog → navigates into match detail. This is the actual product core loop and has zero coverage at any level today.

---

## 7. `features/matches`

### 7.1 `MatchItem` / `MatchAnimal` / `MatchContact` (freezed)

- [x] `fromJson` yours/theirs resolution, equality, `imagePath`, `depPeso`/`depConf` — covered (`test/matches/match_item_test.dart`).
- [x] **P1** `_timeLabelFrom`: "Hoje" (0 days), "1 dia atrás" (singular), "X dias atrás" (plural), and the `DateTime.tryParse` failure fallback (`?? DateTime.now()` — malformed `createdAt` shouldn't crash `fromJson`). Currently untested; the singular/plural boundary and the malformed-date fallback are both real edge cases. **Done 2026-08-16:** `test/matches/match_item_test.dart`.
- [x] **P2** `MatchAnimal.fromJson`'s own breed/sex/address derivation (separate code path from `HerdAnimal`'s, duplicated logic — same unknown-breed fallback gap noted in 5.1/6.1 applies here too). **Done 2026-08-16:** `test/matches/match_item_test.dart`.

### 7.2 `MatchRepository`

Zero coverage — 6 methods (`getMatches`, `confirmMatch`, `rejectMatch`, `deleteMatch`, `getChatToken`, `createMatch`). **Mocking:** `http_mock_adapter` candidate, same rationale as `HerdRepository`.

- [x] **P0** `getMatches(animalId)` — GET with query param, parses via `MatchItem.fromJson(e, animalId: animalId)`. **Done 2026-08-16:** `test/matches/match_repository_test.dart`.
- [x] **P0** `confirmMatch`/`rejectMatch` — PATCH `/matches/:id/status` with the right body; `confirmMatch` returns the parsed payload, `rejectMatch` returns void. **Done 2026-08-16:** `test/matches/match_repository_test.dart`.
- [x] **P0** `createMatch` — POST with `firstLikeAnimalId`/`secondLikeAnimalId`/optional `status`. **Done 2026-08-16:** `test/matches/match_repository_test.dart`.
- [x] **P1** `deleteMatch` — DELETE. **Done 2026-08-16:** `test/matches/match_repository_test.dart`.
- [x] **P0** `getChatToken(matchId, breederId:)` — POST with `breederId` as a query param (not body — worth locking in, easy to get backwards), returns raw token/channelId/channelType map. **Done 2026-08-16:** `test/matches/match_repository_test.dart`.

### 7.3 `matchesProvider` / `CancelMatchNotifier` / `DeleteMatchNotifier`

- [x] **P0** `matchesProvider` family — thin wrapper, one test confirming the `animalId` family key actually scopes results (two different ids don't share cached data). **Done 2026-08-16:** `test/matches/match_provider_test.dart`.
- [x] **P1** `CancelMatchNotifier.cancel()` — on success, invalidates `matchesProvider(animalId)` so the list re-fetches; on error, does not invalidate (stale list stays visible rather than silently vanishing an item that wasn't actually cancelled server-side). **Done 2026-08-16:** `test/matches/match_provider_test.dart`.
- [x] **P1** `DeleteMatchNotifier.deleteMatch()` — same invalidate-on-success-only pattern. **Done 2026-08-16:** `test/matches/match_provider_test.dart`.

### 7.4 `chatChannelProvider` (Stream Chat integration)

- [ ] **P1** Happy path: fetches chat token → connects Stream user → opens channel → (mobile only) registers FCM device with Stream via `addDevice`, with `addDevice` failures being non-fatal (caught and logged, doesn't fail the whole provider). **Known blocker:** depends on both `MatchRepository` (mockable) and `StreamChatService`, which itself is blocked on the DI gap noted in §1.7 (`StreamChatService()` constructs its own `StreamChatClient`). This provider cannot be meaningfully unit tested until `StreamChatService` accepts an injectable client — same fix, one investment unblocks both.
- [ ] **P1** *(infrastructure, depends on §1.7's fix)* Once unblocked: error path — token fetch or `connectUser`/`openChannel` failure surfaces as `AsyncError`, is caught by `chat_screen.dart`'s error state with a retry button that invalidates the provider.

### 7.5 UI: `matches_screen.dart`

- [x] **P0** Unverified/no-animal-selected/loading/error/empty/populated states — currently zero widget-level coverage. **Done 2026-08-16:** `test/matches/matches_screen_test.dart`.
- [x] **P1** Tapping a confirmed match navigates to `matchDetail` with `extra`; tapping a pending match is a no-op (`InkWell.onTap: null` when not confirmed) — this distinction is easy to accidentally regress and currently untested. **Done 2026-08-16:** `test/matches/matches_screen_test.dart`.
- [x] **P2** `_StatusBadge` label/color/icon per `MatchStatus`. **Done 2026-08-16:** label coverage in `test/matches/matches_screen_test.dart`'s populated-state test (color/icon not asserted separately — low value beyond label per the original note).

### 7.6 UI: `match_detail_screen.dart`

- [x] **P0** Renders both animals, contact card, DEP rows (only when `depPeso`/`depConf` non-null). **Done 2026-08-16:** `test/matches/match_detail_screen_test.dart`.
- [x] **P1** Chat CTA navigates to `AppRoutes.chat` with `extra: match`. **Done 2026-08-16:** `test/matches/match_detail_screen_test.dart`.
- [x] **P1** Unmatch flow: confirm dialog → `deleteMatchProvider.deleteMatch()` → navigates to `/matches` on completion (note: navigates unconditionally after the call, not gated on success/failure the way `edit_animal_screen.dart`'s delete is — confirm this is intentional when writing the test, flag if it looks like a second instance of the asymmetric-error-handling issue noted in 5.4). **Done 2026-08-16:** `test/matches/match_detail_screen_test.dart` — confirmed **not** intentional, filed as **K-3** in `docs/known-issues.md` (navigates away even on delete failure).
- [x] **P2** Tapping either animal photo navigates to `matchAnimalDetailPath`, guarded against `animal.id == null` (defensive no-op, per the H-6 notes — worth a regression test since it's specifically a "don't crash" guard). **Done 2026-08-16:** `test/matches/match_detail_screen_test.dart`.
- [ ] **P2** Email contact row launches `mailto:` (via `url_launcher` — this touches a platform channel; assert the `Uri` construction and `onTap` wiring only, don't attempt to assert the OS actually opens a mail client).

### 7.7 UI: `chat_screen.dart`

- [ ] **P1** Loading/error(+retry)/data states for `chatChannelProvider`. **Known blocker:** the `data` case renders real `StreamChat`/`StreamChannel`/`StreamMessageListView`/`StreamMessageInput` widgets from `stream_chat_flutter`, which likely make their own network/platform assumptions in a widget test — confirm whether these render inertly with a fake `Channel`/`StreamChatClient` or require their own test scaffolding; if they don't render cleanly in `flutter test`, scope this test down to just asserting the `channelAsync.when()` branch selection (loading/error paths only), and flag the `data` case as needing either a fake `Channel` deep enough to satisfy the Stream widgets or an integration/device test instead.

### Integration test candidates (matches)

- [ ] **P0** Confirmed match → chat screen opens → (if unblocked per the Stream DI fix) send a message → appears in the list. If Stream Chat DI remains unfixed, scope this down to "chat screen reaches the loaded state without crashing," which is still meaningfully more coverage than today's zero.

---

## 8. `features/profile`

### 8.1 Domain: `BreederProfile`, `BreederStatistics`

- [x] **P1** `BreederProfile.copyWith` (hand-rolled, not freezed — confirm every field is included, since `Breeder`'s hand-rolled `copyWith` was exactly this kind of bug before M-1's freezed migration; this class wasn't migrated and could have the same silent-field-drop risk). `location` getter (empty when either city/state missing). **Done 2026-08-16:** `test/profile/breeder_profile_test.dart` — confirmed every field survives `copyWith` today, no M-1-style drop.
- [x] **P1** `BreederStatistics.fromJson` — snake_case key mapping (`active_animals`, `breeder_matches`), zero coverage today. **Done 2026-08-16:** `test/profile/breeder_statistics_test.dart`.
- [ ] **P2** Consider migrating `BreederProfile` to freezed while adding its tests, mirroring the M-1 rationale — flag as a "test-motivated cleanup," not required, but cheap to bundle if touching this file anyway.

### 8.2 `ProfileRepository`

Zero coverage — 4 methods. Hand-rolled Dio fakes are fine here (not as many endpoints as Herd/Match).

- [x] **P0** `getBreeder(id)` — GET, parses `Breeder`. **Done 2026-08-16:** `test/profile/profile_repository_test.dart`.
- [x] **P1** `getAssociations()` — GET list, parses `Association`. **Done 2026-08-16:** `test/profile/profile_repository_test.dart`.
- [x] **P0** `getStatistics()` — GET, parses `BreederStatistics`. **Done 2026-08-16:** `test/profile/profile_repository_test.dart`.
- [x] **P0** `activate()` — PATCH `/breeders/:id/activate`, conditional body fields (cpf/farmName/associations/pictureUrl only included when non-empty/non-null) — payload-shape test, same rationale as herd's add/update. **Done 2026-08-16:** `test/profile/profile_repository_test.dart`.
- [x] **P0** `updateProfile()` — PATCH `/breeders/:id`, same conditional-field logic **plus** the compound `address` object only included if *any* of directions/zipCode/city/state is non-empty (multi-condition boolean logic worth a few table-driven cases: all empty → no `address` key; one field set → `address` present with only that key). **Done 2026-08-16:** `test/profile/profile_repository_test.dart`.

### 8.3 `ProfileNotifier` / `BreederStatisticsNotifier`

- [x] **P0** `ProfileNotifier.build()` — derives `BreederProfile` from `authNotifierProvider`'s `Breeder`, or `stubProfile` when logged out. Field-by-field mapping test (this is essentially a second `fromJson`-shaped transform, deserves the same scrutiny as the domain model transforms). **Done 2026-08-16:** `test/profile/profile_provider_test.dart`.
- [x] **P0** `activate()` — calls repository, then updates `authNotifierProvider` with the result **plus** force-sets `status: BreederStatus.active` and preserves the *current* (pre-activation) `city`/`state` rather than trusting the response — this override-on-top-of-response pattern is non-obvious and worth locking in explicitly (if the backend response already had the right city/state, this is redundant but harmless; if the backend's `/activate` response omits address entirely, this is load-bearing). **Done 2026-08-16:** `test/profile/profile_provider_test.dart`.
- [x] **P0** `updateProfile()` — calls repository, updates `authNotifierProvider` with the raw result (no override, unlike `activate()` — the asymmetry is intentional per the different endpoints but worth a comment + test making the contrast explicit). **Done 2026-08-16:** `test/profile/profile_provider_test.dart`.
- [x] **P1** `BreederStatisticsNotifier` — thin `AsyncNotifier` wrapper, loading/success/error via a fake repository. **Done 2026-08-16:** `test/profile/profile_provider_test.dart` — the error case needed `ProviderContainer(retry: (retryCount, error) => null, ...)` to disable Riverpod 3.x's default AsyncNotifier retry-with-backoff, otherwise the state sits in `AsyncLoading(...retrying: true)` well past a normal test's patience; worth remembering for any future direct-state-type-check test against a provider that hits a repository error (`.when()`-based widget tests aren't affected — they route on `hasError` regardless of the retrying flag).

### 8.4 UI: `profile_screen.dart`

- [x] **P1** `ref.listen(currentBreederProvider, ...)` side effect: on successful fetch, pushes the result into `authNotifierProvider` (keeps `profileProvider`, which derives from auth state, in sync) — this listen-and-sync pattern is easy to break silently on a refactor and currently untested. **Done 2026-08-16:** `test/profile/profile_screen_test.dart`.
- [x] **P1** Verified vs unverified header rendering (`_VerificationCta` vs the verified badge + associations list). **Done 2026-08-16:** `test/profile/profile_screen_test.dart`.
- [x] **P1** Statistics card loading/error/data states. **Done 2026-08-16:** `test/profile/profile_screen_test.dart`.
- [x] **P0** Sign-out flow: confirm dialog → `authNotifierProvider.notifier.logout()` → (via router redirect, already covered at the router level) lands on login. Widget-level: assert the dialog appears, cancel does nothing, confirm calls logout and shows the loading spinner meanwhile. **Done 2026-08-16:** `test/profile/profile_screen_test.dart` — needed a `_SlowLogoutAuthRepository` test double with a controllable `Completer` to catch the loading spinner mid-flight, since the base fake's `logout()` resolves within a single microtask (too fast for `pump()` to observe).

### 8.5 UI: `edit_profile_screen.dart`

- [x] **P0** Form pre-populated from `profileProvider` on init; required-field validation (`name` only — confirm this matches product intent, phone/farm are optional here despite being required-looking fields elsewhere). **Done 2026-08-16:** `test/profile/edit_profile_screen_test.dart` — confirmed only `name` is required, matches product intent as coded.
- [x] **P0** Save flow: calls `updateProfile()` with trimmed/nulled-when-empty values for every optional field — payload-shape assertion from the UI layer, same rationale as herd forms. **Done 2026-08-16:** `test/profile/edit_profile_screen_test.dart`.
- [x] **P1** Avatar photo picker — same `CloudinaryUploader` DI blocker as 5.7; scope down to "opens source chooser" until unblocked. **Done 2026-08-16:** `test/profile/edit_profile_screen_test.dart` — extended `_pumpEditProfile` with an overridable `cloudinaryUploaderProvider` (default `FakeCloudinaryUploader()`); one test covers tapping the camera button opening the source chooser, then choosing a source uploading and swapping the avatar's `CachedNetworkImage.imageUrl`. Needed bounded `tester.pump()`s instead of `pumpAndSettle()` post-upload — `CachedNetworkImage`'s placeholder is an indeterminate `CircularProgressIndicator`, which never settles.
- [x] **P1** CPF field is `readOnly` and pre-filled empty (not editable post-verification, per the code) — regression test, since accidentally making this editable would let a verified CPF be silently changed client-side with no validation re-run. **Done 2026-08-16:** `test/profile/edit_profile_screen_test.dart` — `TextFormField.readOnly` isn't a public getter, so this is asserted behaviorally (typing into the field has no effect on its controller text) rather than via widget introspection.
- [ ] **P2** "Gerenciar plano" button shows the coming-soon sheet. **Not done** — low value, skipped per this batch's P0/P1 focus.

### 8.6 UI: `profile_completion_screen.dart`

- [x] **P0** Required-field validation (name + address, via `AddressFormFields(required: true)`). **Done 2026-08-16:** `test/profile/profile_completion_screen_test.dart` — this screen also passes a `streetController`, making "Logradouro" required too (unlike `edit_profile_screen.dart`, where it's optional); the submit-success test fills it accordingly.
- [x] **P0** Submit calls `authNotifierProvider.notifier.syncBreeder()` — success relies on the router redirect (already covered at router level: "logged in with a city → herd"), but the screen-level submit wiring itself (trimmed values, `directions` nulled when empty) is untested. **Done 2026-08-16:** `test/profile/profile_completion_screen_test.dart` — note the "directions null when empty" half of this item isn't actually reachable through this screen's UI, since `AddressFormFields(required: true)` blocks submission with an empty Logradouro before `_submit()`'s null-when-empty ternary is ever exercised with a truly empty value; the test fills it and asserts the trimmed value passes through instead.
- [x] **P1** Error SnackBar on failure, loading state on the submit button. **Done 2026-08-16:** `test/profile/profile_completion_screen_test.dart` — SnackBar covered; the mid-flight loading-spinner half was dropped from this test (the fake repository's error resolves within a single microtask, too fast for `pump()` to catch without a controllable-delay double like §8.4's `_SlowLogoutAuthRepository` — not worth the extra machinery here since §8.4 already locks in that pattern works).

### 8.7 UI: `profile_verification_screen.dart`

- [x] **P0** CPF field: uses `isValidCpf` (already unit-tested at the util level per `test/shared/cpf_validator_test.dart`) — this screen-level integration (invalid CPF blocks submit with the right error text) is untested. Also verify `CpfInputFormatter` (in `address_form_fields.dart`, applied here) formats-as-you-type correctly (`000.000.000-00`). **Done 2026-08-16:** `test/profile/profile_verification_screen_test.dart` covers the screen-level integration; `CpfInputFormatter`'s own formatting logic was already unit-tested directly in `test/shared/address_form_fields_test.dart` (§11), not duplicated here.
- [x] **P0** Photo required before submit — validated *outside* the `Form` (`_pictureUrl == null` check with its own SnackBar, not a `TextFormField` validator) — easy to miss in a naive "just check form validation" test; needs its own explicit case. **Done 2026-08-16:** `test/profile/profile_verification_screen_test.dart`.
- [x] **P0** Submit calls `profileProvider.notifier.activate()` with the right args, success message + navigates to `/perfil`; failure shows the generic error SnackBar (and per the code, logs via bare `debugPrint` without a `kDebugMode` guard — this is a **latent H-1-style issue reintroduced after that fix landed elsewhere**; flag as a bug candidate alongside the test, not just a coverage note). **Done 2026-08-16:** `test/profile/profile_verification_screen_test.dart` covers the success path (added a `FakeCloudinaryUploader` test double to `test/helpers/fakes.dart` to supply a picture URL without touching the real picker). The `debugPrint` issue was **K-2** in `docs/known-issues.md` — fixed directly (wrapped in `if (kDebugMode)`) rather than just flagged, since it was a one-line, unambiguous fix matching an already-established pattern; re-ran the doc's own suggested repo-wide `debugPrint(` grep and confirmed no other call sites were missed.
- [x] **P1** Photo picker uses camera-only source (`ImageSource.camera`, unlike the gallery-or-camera chooser elsewhere) — confirm this is intentional product behavior when writing the test, not an oversight (verification photos plausibly need to be a live camera capture, not a gallery upload, to deter fraud — but this should be a deliberate, documented choice, not silently assumed). **Confirmed 2026-08-16:** reads as intentional (verification-specific anti-fraud rationale is plausible and the code path is explicit, not a copy-paste artifact), but it isn't documented anywhere as a deliberate choice — worth a one-line code comment from someone who can confirm the actual product intent; not changing behavior here.

### Integration test candidates (profile)

- [ ] **P0** Profile completion (post-signup) → verification submission → admin-side confirmation is out of scope (backend), but confirm the client correctly reflects `status: pending` immediately after submission and would reflect `active` after a `refreshBreeder()` foreground-refresh — this exercises the M-4 fix end-to-end, which today only has a provider-level test, not a UI-through-router one.

---

## 9. `features/locations`

### 9.1 `Municipalities`

- [x] **P1** `fromJson` — state→cities map parsing; `states` getter returns sorted keys; `citiesOf(state)` returns `[]` for an unknown state rather than throwing. Zero coverage today, feeds every address form in the app (`AddressFormFields`). **Done 2026-08-16:** `test/shared/municipalities_test.dart`.

### 9.2 `LocationsRepository` / `municipalitiesProvider`

- [x] **P1** `getMunicipalities()` — single GET, parses via `Municipalities.fromJson`. Hand-rolled Dio fake. **Done 2026-08-16:** `test/shared/locations_repository_test.dart` (used `http_mock_adapter` instead — single-endpoint repo, but consistent with the other repository test files in this batch).
- [x] **P2** `municipalitiesProvider` is a plain (non-family) `FutureProvider`, deliberately app-session-cached — worth one test confirming a second `ref.watch` doesn't re-fetch (asserts the "fetched once per session" doc comment is actually true, not just aspirational). **Done 2026-08-16:** `test/shared/locations_repository_test.dart`.

---

## 10. `shared/domain`

- [x] **P1** `AnimalDetailData.fromDiscoverAnimal` / `.fromMatchAnimal` / `.fromHerdAnimal` — three different source-shape adapters into one display model, currently **zero coverage** despite being the data source for the shared animal detail screen used from 3 different entry points (discover swipe card, match detail, own-herd fallback). Particular attention to `fromMatchAnimal`'s `_parseCity`/`_parseState` string-splitting of the combined `"City, State"` field — a city name containing a comma (unlikely but not impossible in Brazilian municipality names) would silently misparse; at minimum test the no-comma and single-comma cases. **Done 2026-08-16:** `test/shared/animal_detail_data_test.dart` — also added a 3-part-comma case pinning the actual (silently lossy) current behavior, since the plan's own "at minimum" cases don't cover it.
- [x] **P2** `AnimalDetailData.locationFull`/`ageLabel` getters — same singular/plural pattern as `DiscoverAnimal`'s equivalent getters (7.1/6.1) — consider whether this duplicated getter logic across `HerdAnimal`, `DiscoverAnimal`, `MatchAnimal`'s time label, and `AnimalDetailData` is worth consolidating into one shared pt_BR pluralization helper while adding tests for all four; flag as a cleanup opportunity, not required for this plan. **Done 2026-08-16:** `test/shared/animal_detail_data_test.dart`. Consolidation opportunity still stands, not acted on.
- [x] **P1** `DistanceRange` — `label`/`maxKm` switch completeness (compiler enforces exhaustiveness, but a test still documents the km values against product intent) and `fromLabel` round-trip. Zero coverage; currently unused in a network request (per 6.4's flagged gap) but the enum itself is simple to lock in regardless. **Done 2026-08-16:** `test/shared/distance_range_test.dart`.
- [x] **P1** `BreederAssociation.fromJson`/`toJson` round-trip, including the `name` fallback to `code` when absent. **Done 2026-08-16:** `test/shared/breeder_association_test.dart`.
- [x] **P2** `Association.fromJson` — same fallback pattern, simpler shape. **Done 2026-08-16:** `test/shared/breeder_association_test.dart`.

---

## 11. `shared/widgets`

Zero coverage across the board. Prioritize widgets with actual logic (not pure-presentational) and widgets used on P0 screens.

- [x] **P1** `AddressFormFields` — this is the highest-value shared widget to test: state→city dependent dropdown (`_StateCityDropdowns`, changing state clears city), loading state (`_StateCityLoading`), and the **fallback to free-text fields** when `municipalitiesProvider` errors (`_StateCityFreeText`) — this fallback is a real resilience feature (form stays usable if the locations API is down) and is completely untested. Also: `ZipInputFormatter`/`CpfInputFormatter`/`UpperCaseInputFormatter` — pure `TextInputFormatter` logic, cheap and valuable to unit test directly (no widget pump needed, just call `formatEditUpdate` with `TextEditingValue`s). **Done 2026-08-16:** `test/shared/address_form_fields_test.dart`.
- [x] **P1** `AssociationsPicker` — add/remove association rows, `_selectedCodes` preventing duplicates, the "already added all available associations" state hiding the add button, registration-number-required validation per row. Non-trivial internal state (`_entries` list with individually-disposed controllers) — a disposal-leak test (adding then removing several rows, confirming no `TextEditingController used after dispose` assertion fires) is worth including given the manual controller lifecycle management here. **Done 2026-08-16:** `test/shared/associations_picker_test.dart`.
- [x] **P1** `AnimalPhotoStrip` — add-tile hidden at `_kMaxPhotos` (3), remove button per tile, loading state disables the add tile. Pure widget test, no provider needed (all state is parent-owned). **Done 2026-08-16:** `test/shared/animal_photo_strip_test.dart`.
- [x] **P2** `AppBottomNav` / `AppNavTabs.selectedIndex` — index-from-route logic, specifically the discover-tab exact-match special case (`route != discover || location == discover`) that prevents every other route from falsely highlighting the discover tab as a prefix match. This is a subtle off-by-default bug shape (prefix matching without the exception would highlight "Explorar" on nearly every screen) — worth a regression test given how easy it'd be to "simplify" away during a refactor. **Done 2026-08-16:** `test/shared/app_bottom_nav_test.dart`.
- [ ] **P2** `ConfirmDialog`/`showConfirmDialog` — returns `true`/`false` per button tap, defaults to `false` on dismiss-without-choice (barrier tap). Used by 2 P0 delete/unmatch flows (5.8, 7.6) but the dialog itself is simple enough that those callers' own tests likely cover it adequately; a dedicated test is only worth it for the destructive-styling branch (`destructive: true` → red confirm button).
- [ ] **P2** `FilterDropdown` — active/inactive chip styling, clear option only shown when active. Low product impact today per 6.4's flagged gap (filter doesn't affect results yet).
- [ ] **P2** `UnverifiedProfilePrompt`, `BreederAssociationsCard`/`BreederAssociationsList`, `ComingSoonSheet`, `CircleActionButton`, `AnimatchLogo`, `AppErrorAlert` — pure presentational, low logic. Skip dedicated tests; these are adequately exercised as dependencies of the P0/P1 screen tests above. Don't spend budget here.
- [x] `cpf_validator.dart` — covered (`test/shared/cpf_validator_test.dart`).

---

## Known blockers — consolidated list

Repeated here in one place so infrastructure work can be planned/prioritized independent of feature area. All of these block *unit* testing specifically; device/manual testing remains the fallback per `docs/production-review.md`'s own repeated caveat.

| # | Class / area | Blocker | Fix | Unblocks |
|---|---|---|---|---|
| 1 | `AuthRepository` | ~~Builds its own `Auth0` client in the constructor~~ **Fixed 2026-08-13, tests written 2026-08-16** | Accept optional injected `Auth0` param | §2.2 `login`, `signUp`, `restoreSession` (credentials branch), `logout`, `getFreshToken` — roughly half the auth surface. **Resolved:** `test/auth/auth_repository_test.dart` covers all of these via mocktail `MockAuth0`/`MockWebAuthentication`/`MockCredentialsManager`. |
| 2 | `dioProvider`'s interceptor | Same — builds its own `Auth0` client | Same fix, applied to `api_client.dart` | §1.3's Auth0-success branch |
| 3 | `CloudinaryUploader` | ~~Constructs `ImagePicker()` inline~~ **Fixed 2026-08-13** | Accept optional injected `ImagePicker` param | §1.6, and every screen's photo-upload flow (5.7, 5.8, 8.5, 8.7) |
| 4 | `StreamChatService` | Constructs `StreamChatClient` in a field initializer | Accept optional injected client param | §1.7, and §7.4's `chatChannelProvider` |
| 5 | `NotificationService._local` | Real `FlutterLocalNotificationsPlugin()`, not injected | Either DI or mock the plugin's platform channel directly | §1.4's `_showForeground`/background message display |
| 6 | `DeviceTokenService.register()`'s `Platform.isIOS` check | `dart:io` `Platform` isn't mockable without indirection | Low priority — inject a platform-string instead of checking `Platform` inline, only if this branch ever needs real coverage | §1.5 (iOS branch only; Android branch already testable) |
| 7 | `stream_chat_flutter` widgets (`StreamChat`, `StreamMessageListView`, etc.) | Unknown whether they render inertly under `flutter test` with a fake `Channel` | Spike/confirm before committing to full chat-screen widget tests | §7.7 |
| 8 | Backend: no `GET /matches/:id` | Not a client bug — see H-6 in `docs/production-review.md` | Backend work, out of this repo's reach | Would allow removing the `matchDetail`/`chat` null-`extra` redirect entirely, simplifying §1.1/§7.6/§7.7 |
| 9 | No staging/prod Auth0 or backend credentials | `config/staging.env.json`/`config/production.env.json` still `REPLACE_ME` per C-4 | Needs a human with real credentials | §0's integration-test backend strategy — blocks option (a) until resolved |

Infrastructure items 1-4 are flagged **P0** in their respective sections above because they each unblock a cluster of otherwise-untestable P0 business logic — treat them as test-writing prerequisites, not optional cleanup.

---

## Suggested execution order (first ~2-3 weeks of this backlog)

1. **Infra unblocks first** (table above, items 1 & 3): `AuthRepository` and `CloudinaryUploader` DI refactors — small, low-risk, each unlocks a cluster of P0 tests that are otherwise stuck.
2. **`HerdRepository` + `HerdNotifier` family** (§5.3, §5.4) — largest zero-coverage cluster of pure money-path logic (add/edit/delete/toggle), no blockers, straightforward fakes.
3. **`MatchRepository` + like/reject branching in `discover_screen.dart`** (§7.2, §6.4) — the actual product core loop (mutual-like → confirmed match) has literally zero coverage today at any level.
4. **`Breeder.fromJson` / `BreederStatus.fromJson` permanent tests** (§2.1) — cheap, high-value, was already written once and thrown away per M-1's own notes; re-add it for good this time.
5. **`AddressFormFields`'s municipalities-API-down fallback** (§11) — a real resilience feature with zero coverage; regressing it silently would only surface when the locations API has an outage, the worst time to discover a fallback doesn't work.

Everything else follows from the priority tags already assigned per-item above.
