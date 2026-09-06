---
name: project-profile-batch-review
description: Review of profile domain/repository/provider/screen tests closing out testing-plan §8.1-§8.7, landed 2026-08-16
metadata:
  type: project
---

Reviewed `test/profile/{breeder_profile,breeder_statistics,profile_repository,profile_provider,
profile_screen,edit_profile_screen,profile_completion_screen,profile_verification_screen}_test.dart`
and the `FakeProfileRepository`/`FakeCloudinaryUploader`/`FakeAuthRepository` extensions to
`test/helpers/fakes.dart` (2026-08-16). All 41 tests in `test/profile/` pass (6/6 isolated reruns,
no flakiness), `flutter analyze test/profile/ test/helpers/fakes.dart
lib/features/profile/ui/profile_verification_screen.dart` clean. Neither prior recurring gotcha
reappeared: `FakeProfileRepository.activateCalls`/`updateProfileCalls` capture real argument maps
(not counts), and `profile_provider_test.dart` uses `container.listen(...) + await
container.pump()` — not the old delay hack. See [[feedback_riverpod_invalidate_testing]].

## Riverpod 3.x AsyncNotifier/FutureProvider default retry — confirmed real, confirmed canonical fix

Independently verified against `riverpod-3.1.0/lib/src/core/{element.dart:694,
provider_container.dart:830-838}`: `ProviderContainer.defaultRetry` retries any thrown error that
isn't `Error`/`ProviderException` (exponential backoff 200ms→6400ms, up to 10 attempts) *by
default* on every plain `ProviderContainer()`. A test that directly `container.read(provider)`s
looking for `isA<AsyncError>()` right after a repository throw will instead see
`AsyncLoading(...retrying: true)` and can hang up to the test framework's default timeout.

**Fix, confirmed as the idiomatic one** (not an improvised workaround) — grepped
`riverpod-3.1.0/test/`: `ProviderContainer(retry: (_, _) => null, ...)` (or the `.test(retry: ...)`
factory) is the exact pattern Riverpod's own test suite uses dozens of times
(`async_notifier_test.dart`, `stream_notifier_test.dart`, `provider_element_test.dart`, etc.) for
this exact situation. Safe to apply container-wide even in tests that don't strictly need it
(widget tests routing through `AsyncValue.when()` aren't affected either way, since they key off
`hasError`, not the `retrying` flag).

**How to apply:** any future provider-level test asserting a direct `AsyncError` state (not routed
through a widget's `.when()`) on an `AsyncNotifierProvider`/`FutureProvider`/`StreamNotifierProvider`
needs `retry: (retryCount, error) => null` passed to its `ProviderContainer`. `test/herd/herd_screen_test.dart`'s
error-state case and `test/profile/profile_provider_test.dart`'s `BreederStatisticsNotifier error
surfaces as AsyncError` both now do this correctly, and it's cited in `docs/testing-plan.md` §8.3.

## K-2 fix re-confirmed correct and complete

`profile_verification_screen.dart:95-97` now wraps the bare `debugPrint` in `if (kDebugMode) { ... }`.
Re-ran the repo-wide `grep -rn "debugPrint(" lib/` sweep independently — every other call site
(`app.dart`, `register_screen.dart`, `match_provider.dart`) is already correctly guarded. No misses.

## Prior flaky-teardown note in profile_provider_test.dart is resolved

[[project_matches_batch2_review]] flagged `test/profile/profile_provider_test.dart` as
intermittently timing out/disposing-early during a full-suite run (pre-existing file at the time).
This batch rewrote that file; reran it 5× standalone with zero failures and it's clean inside 3
full-suite runs too. Consider that prior flake note closed.

## Unrelated flake found running the full suite (not caused by this batch)

`flutter test` (full suite, not `test/profile/`) intermittently fails ~3/6 runs, always and only in
`test/herd/my_animal_detail_screen_test.dart` — a real `RenderFlex overflowed by 11 pixels on the
right` in `_StatusRow` (`lib/features/herd/ui/my_animal_detail_screen.dart:429`), order-dependent
(never reproduces when `test/profile/` or `test/herd/` run in isolation). Smells like shared
`tester.view` physical-size state bleeding across test files in the same suite run, or a
close-to-the-edge layout that only overflows under certain preceding-test viewport state. Untouched
by the profile batch — flagging so it isn't misattributed later. Worth a dedicated look before
trusting full-suite CI green/red as a herd-feature signal.

## Minor, non-blocking nits from this batch (not worth blocking on)

- `profile_repository_test.dart`'s "one address field set" case only exercises the `city`-alone
  branch of `updateProfile`'s 4-way OR condition (directions/zipCode/city/state) — the other three
  fields triggering the `address` wrapper alone aren't independently tested. Low risk (symmetric
  boolean logic) but a table-driven case would close it fully if this file is touched again.
- A few widget assertions use `findsWidgets` where exactly one match is expected (sign-out spinner
  in `profile_screen_test.dart`, empty-CPF case in `profile_verification_screen_test.dart`) —
  looser than necessary, not a correctness bug.
