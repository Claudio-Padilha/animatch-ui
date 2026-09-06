---
name: Animatch Test Infrastructure Notes
description: DI blockers preventing unit tests, mocking-library status, and test suite layout as of the 2026-08-04 testing plan
type: project
---

## Full testing plan exists

`docs/testing-plan.md` (written 2026-08-04) is a feature-by-feature, checkbox-tracked backlog covering every `lib/` file, tagged P0/P1/P2, with per-item mocking guidance (mocktail vs hand-rolled fake) and a consolidated "known blockers" table. Read it first before re-deriving coverage gaps from scratch — it already enumerates them.

## Phase 1 progress

§2.1 (`Breeder`/`BreederStatus` domain tests) landed 2026-08-13 as `test/auth/breeder_test.dart` (14 tests) — fromJson field mapping, `BreederStatus.fromJson` table over active/rejected/pending_activation/unknown/null, `copyWith(id:, email:)` regression, `verifiedBreeder`, generated equality. No mocking needed (pure freezed domain logic, per policy). All corresponding checkboxes in `docs/testing-plan.md` §2.1 ticked. `BreederAssociation` is a plain (non-freezed) class with **no overridden `==`/`hashCode`** — equality tests that embed it inside a `Breeder` only work because `const BreederAssociation(...)` instances with identical field values get canonicalized to the same object by Dart's const-canonicalization; don't rely on this for non-const-constructed `BreederAssociation`s elsewhere (e.g. from `fromJson`), since plain identity equality would fail there.

## Mocking library status

`mocktail` (^1.0.5) and `http_mock_adapter` (^0.6.1) were added to `dev_dependencies` on 2026-08-13 (Phase 0 of `docs/testing-plan.md`), both resolved cleanly against `sdk: ^3.11.4` and `dio: ^5.7.0`. `mockito` appears in `pubspec.lock` only as a `dependency: transitive` (pulled in by something else in the tree, not by us) — confirm it stays transitive-only if `pub get` output looks different in a future check; we never add it directly. The existing 9 test files still use hand-rolled fakes (`test/helpers/fakes.dart`) and a hand-rolled Dio `HttpClientAdapter` fake (`test/auth/auth_repository_test.dart` pattern) — mocktail/http_mock_adapter are unblocked but not yet *used* in any test file as of 2026-08-13; that's Phase 1+ work.

## Constructor-injection blockers (recurring pattern — check before assuming something is testable)

Several classes build their own real dependency inline instead of accepting it via constructor, which blocks unit testing of any method touching that dependency.

**Fixed 2026-08-13** (Phase 0 infra work, both are optional-param seams, default behavior unchanged):
- `AuthRepository` (`lib/features/auth/data/auth_repository.dart`) — now `AuthRepository(this._dio, {Auth0? auth0}) : _auth0 = auth0 ?? Auth0(Auth0Config.domain, Auth0Config.clientId)`. Unblocks `login()`, `signUp()`, `restoreSession()`'s credentials branch, `logout()`, `getFreshToken()` — pass a mocktail `MockAuth0` or hand-rolled fake now.
- `CloudinaryUploader` (`lib/core/services/cloudinary_uploader.dart`) — now `CloudinaryUploader(this._dio, {ImagePicker? imagePicker}) : _imagePicker = imagePicker ?? ImagePicker()`. **Note: the class's constructor is no longer `const`** — `ImagePicker` has no explicit const constructor (verified via `dart analyze`: `const ImagePicker()` fails with `const_with_non_const`), so a const default value made the whole constructor non-const necessarily. No caller used `const CloudinaryUploader(...)` at the call site (checked via grep before changing), so this was a safe drop. Unblocks `pickAndUpload()` photo-upload flow tests (add/edit animal, edit profile, verification screen) via a mocktail `MockImagePicker`.

**Still open** (not touched in this pass):
- `dioProvider`'s interceptor (`lib/core/network/api_client.dart`) — same pattern, builds its own `Auth0` client for the token-attach interceptor. Not the same class as `AuthRepository`, needs its own fix.
- `StreamChatService` (`lib/core/services/stream_chat_service.dart`) — constructs `StreamChatClient` in a field initializer. Blocks `connectUser()`/`openChannel()` and `chatChannelProvider`.
- `NotificationService._local` (`lib/core/services/notification_service.dart`) — real `FlutterLocalNotificationsPlugin()`, not injected. The Firebase-facing methods (`_fcm` getter) are already fixed to be lazy/overridable (subclass pattern works, see `NoopNotificationService` in `test/helpers/fakes.dart`), but `_local.show()` in `_showForeground` still isn't reachable from a widget test without a platform-channel mock.

Recommended fix shape for all remaining ones: optional constructor param defaulting to the real thing, same shape as the two fixed above. Small, low-risk, and each one unblocks a cluster of otherwise-stuck P0 tests — treat as test-writing prerequisite work, not optional cleanup.

## Known asymmetries worth flagging as possible bugs (not just test gaps) if touched again

- `HerdRepository`'s add vs update payload: `addAnimal` payload uses key `'registrationNumber'`, `updateAnimal` payload uses `'registration_number'` (see `lib/features/herd/providers/herd_provider.dart`). Looks like an unintentional inconsistency, not a documented API contract difference.
- `updateAnimal` calls `herdProvider.notifier.updateOne()` on success; `addAnimal` calls a full `herdProvider.notifier.refresh()`. Different side-effect strategies for what looks like a symmetric operation — confirm intentional before treating as a bug.
- `profile_verification_screen.dart`'s `_submit()` catch block logs via bare `debugPrint(...)` with no `kDebugMode` guard — everywhere else in the codebase this exact pattern was deliberately fixed to be `kDebugMode`-gated (see H-1 in `docs/production-review.md`). This one screen looks like it was added/missed after that fix pass. Worth a real bug report, not just a test note.

## Backend / integration test environment

No staging/prod backend credentials exist yet (`config/staging.env.json` / `config/production.env.json` are still `REPLACE_ME` placeholders per `docs/production-review.md` C-4). `integration_test/` package + directory does not exist in the repo at all as of 2026-08-04 — needs to be added from scratch (see `docs/testing-plan.md` §0) before any device-flow integration test can run. Auth0 login cannot be automated in CI without a dedicated test tenant + headless browser, so integration tests should seed `authNotifierProvider` directly via provider overrides rather than driving a real Auth0 login.

## google_maps_flutter is listed in CLAUDE.md's tech stack table but not actually used

`grep -r "google_maps" lib/` and `pubspec.yaml` both come back empty as of 2026-08-04. Don't plan Maps-related test/blocker work — it's aspirational in the docs, not present in code.
