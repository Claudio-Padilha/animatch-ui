---
name: project-discover-matches-locations-batch-review
description: Review findings for match_repository_test.dart, discover_screen_test.dart (first mocktail usage), address_form_fields_test.dart, municipalities/locations_repository tests — landed 2026-08-16
metadata:
  type: project
---

Reviewed `test/matches/match_repository_test.dart`, `test/discover/discover_screen_test.dart`,
`test/shared/address_form_fields_test.dart`, `test/shared/municipalities_test.dart`, and
`test/shared/locations_repository_test.dart` (2026-08-16). All 27 tests pass, `flutter analyze`
clean on every touched file. One real gap found; everything else checked out non-trivially.

## Real gap (moderate severity)

`match_repository_test.dart`'s `getMatches` test (lines 26-39) only asserts `matches.single.id ==
'm1'`. `MatchItem.fromJson(json, {required String animalId})`
(`lib/features/matches/domain/match_item.dart:103-113`) uses `first.id == animalId` to resolve
which side is `yourAnimal` vs `theirAnimal` — a real, product-visible branch. The repo test's
fixture already has `firstAnimal.id: 'a1'` and calls `getMatches('a1')`, so asserting
`matches.single.yourAnimal.name` (or similar) would nearly-free lock in that `getMatches` forwards
its `animalId` argument correctly into `MatchItem.fromJson`. As written, a bug that dropped/mangled
that forwarding (e.g. hardcoded `''`) would not be caught here — `match_item_test.dart` tests the
resolution logic itself but not through the repository's wiring. Cheap fix, worth doing before
copying this pattern to other multi-field repository tests.

## Confirmed correct via source-level verification (don't re-derive next time)

- **mocktail 1.0.5's named-argument matching is exact-key-set, not subset.**
  `~/.pub-cache/hosted/pub.dev/mocktail-1.0.5/lib/src/_invocation_matcher.dart`'s
  `_isArgumentsMatches` checks `invocation.namedArguments.length ==
  roleInvocation.namedArguments.length` *and* a full key-set difference, before comparing values.
  Combined with the language fact that Dart's `noSuchMethod`-routed `Invocation.namedArguments`
  only contains keys the caller actually passed (unspecified optional named params are absent, not
  filled with `null`) — `when()`/`verify()` registered with N named-arg matchers will **not** match
  a real call that passes an extra `foo: null` key, and vice versa. This means mocktail genuinely
  distinguishes "called with no `status` key" from "called with `status: null`" — exploit this
  directly (register the stub/verify with exactly the named args the real call site passes) rather
  than defensively over-specifying with `status: any(named: 'status')` everywhere. Confirmed
  correct usage in `discover_screen_test.dart`'s `_onLike`/`_onReject` tests.
- **`http_mock_adapter` 0.6.1 matches `data`/`queryParameters` via a full sorted-map
  string-signature equality**, not a subset/contains check
  (`lib/src/utils.dart`'s `buildRequestSignature`/`sortMap`, used as the lookup key in
  `RequestMatcher`). An extra or missing key anywhere in the request causes a hard "no matching
  route" test failure, not a silent pass. This means body-shape tests like `createMatch`'s "omits
  status entirely when not provided" and `getChatToken`'s "breederId as query param, not body" are
  real assertions, not coincidental passes — safe to keep writing tests in this style without extra
  defensive assertions.
- **`DiscoverScreen`'s `CardSwiper` is configured with `allowedSwipeDirection:
  AllowedSwipeDirection.none()`** (`lib/features/discover/ui/discover_screen.dart:136`). Verified
  against `flutter_card_swiper` 7.2.0 source
  (`lib/src/widget/card_swiper_state.dart:_isValidDirection`): with `.none()`, every real user drag
  gesture's release direction is rejected and the card always snaps back via `_goBack()` —
  `onSwipe` can **never** fire from an actual drag in this app. `CardSwiperController.swipe()`
  (used by `_ActionButtons`'s Curtir/Passar buttons) is the *only* way `onSwipe` fires in
  production. So `discover_screen_test.dart`'s pattern of tapping the button to trigger the swipe
  is not a shortcut around a real drag-path risk — it's the actual (only) production interaction
  path. Don't ask for a drag-gesture variant of this test; there's nothing for it to cover that the
  button-tap path doesn't already exercise identically (same `onSwipe` callback either way).

## Widget test note

`_MatchCelebrationDialog` has an infinitely-`repeat()`-ing pulse `AnimationController`
(`discover_screen.dart:637-640`). `discover_screen_test.dart` correctly avoids `pumpAndSettle()`
throughout `_tapAction` (bounded `pump()`/`pump(duration)` calls instead) — `pumpAndSettle()` would
hang/timeout on this screen once the celebration dialog is showing. Any future test that pumps
through to the celebration dialog must follow the same bounded-`pump()` pattern, not
`pumpAndSettle()`.

## Gotchas from prior reviews NOT repeated in this batch (good sign)

Neither the fake-arg-capture gap nor the `Future.delayed(Duration.zero)` invalidate-waiting hack
(see [[feedback_riverpod_invalidate_testing]], [[project_herd_batch_review]]) reappear here.
`locations_repository_test.dart`'s "fetched once per session" test correctly uses
`container.read(municipalitiesProvider.future)` re-reads, matching the recommended idiom.

## Test-infra note

Hit one transient `flutter test` failure running all 5 files together in a single invocation —
a bogus "return type mismatch" compile error on `FakeMatchRepository.getMatches` in
`test/helpers/fakes.dart` that `flutter analyze` did not reproduce and that vanished on immediate
re-run. Looked like a `frontend_server` incremental-compile cache artifact, not a real type error
(the file's actual declared return type is `Future<List<MatchItem>>`, correctly typed). If this
recurs, re-run before treating it as a real regression.
