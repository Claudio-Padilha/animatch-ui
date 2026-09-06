---
name: project-matches-batch2-review
description: Review of match_item/match_provider/matches_screen/match_detail_screen tests closing out testing-plan §7.1/7.3/7.5/7.6, landed 2026-08-16
metadata:
  type: project
---

Reviewed `test/matches/match_item_test.dart`, `test/matches/match_provider_test.dart` (new),
`test/matches/matches_screen_test.dart` (new), `test/matches/match_detail_screen_test.dart` (new),
and the `FakeMatchRepository` addition to `test/helpers/fakes.dart` (2026-08-16). All 39 tests in
`test/matches/` pass, `flutter analyze test/matches/ test/helpers/fakes.dart` clean. Neither of the
two recurring gotchas from prior reviews reappeared: `FakeMatchRepository` captures real args in
lists (`getMatchesCallArgs`/`rejectMatchCalls`/`deleteMatchCalls`), and `match_provider_test.dart`
uses `container.pump()` (with `container.listen(matchesProvider(id), ...)` to keep the
`.autoDispose` family member alive across the invalidate) — not the old delay hack. See
[[feedback_riverpod_invalidate_testing]].

## K-3 diagnosis independently re-confirmed correct

`_UnmatchButton._confirmUnmatch` (`lib/features/matches/ui/match_detail_screen.dart:456-463`) calls
`context.go(AppRoutes.matches)` unconditionally after `await ...deleteMatch(...)`, with no check of
`deleteMatchProvider`'s resulting state anywhere — `build()` only reads `.isLoading` for the
spinner, never the error state. `AsyncValue.guard` swallows the thrown exception so `deleteMatch()`
returns normally either way, so there is no subtlety being missed: the bug is real, K-3's file:line
citation is accurate, and the regression test correctly pins current (buggy) behavior rather than
asserting the fix.

## GestureDetector index disambiguation — verified safe, not coincidental

`match_detail_screen_test.dart` uses `find.byType(GestureDetector).at(1)` to mean "their animal's
photo", with a comment noting render order `[yourAnimal photo, theirAnimal photo]`. Checked whether
this is fragile given `_ContactCard`'s email row (`_ContactRow` with `onTap`) also wraps in a
`GestureDetector`, plus the fact that Material `InkWell`/`InkResponse` (used internally by
`FilledButton`/`TextButton` — the Chat CTA and Cancelar-match/dialog buttons on this same screen)
also builds a real `GestureDetector` internally (`ink_well.dart`'s `_InkResponseState.build`).
Conclusion: **safe**. `find.byType` does a pre-order DFS matching build order, and
`_AnimalPairWidget` (2 GestureDetectors, index 0/1) is the first child of the screen's body
`Column`, built entirely before `_ContactCard`/`_ActionButtons`/`_UnmatchButton` and their internal
InkWell-driven GestureDetectors. So index 1 is stable regardless of how many GestureDetectors exist
later in the tree — it only breaks if something is inserted *before* the animal-pair section, or if
`_AnimalPairWidget`'s own child order changes. Still a nit: `find.descendant(of:
find.byType(_AnimalPhotoWithName).at(1), matching: find.byType(GestureDetector))` or a `Key` would
be self-documenting instead of relying on this analysis being redone by the next reader — flag as a
style suggestion, not a defect, if it recurs elsewhere.

**General lesson for future `find.byType(GestureDetector)` reviews in this repo:** don't assume the
count equals only the widget's own explicit `GestureDetector` usages — `InkWell`/`InkResponse`
(and therefore every Material button) contributes one too. Position-from-start indices into an
early, isolated section of the tree are fine; total-count assertions (`findsNWidgets(n)`) against
`GestureDetector` specifically would NOT be safe on a screen with buttons, and none of these tests
make that mistake (they only ever use `.at(n)` for small n against known-early widgets).

## Real (non-test-code) finding: `cancelMatchProvider`/`CancelMatchNotifier` is dead code

`grep -rn "cancelMatchProvider\|CancelMatchNotifier" lib/` only matches its own definition in
`match_provider.dart` — nothing in `matches_screen.dart` or elsewhere calls it. `_MatchCard` in
`matches_screen.dart` has no reject/cancel action wired up for pending matches today. The new tests
faithfully cover `CancelMatchNotifier`'s invalidate-on-success/error behavior as pure provider
logic, which is legitimate, but testing-plan.md §7.3 reads as if this closes out real product
surface — worth flagging to the user as a product gap (no way to actually reject a pending match
from the UI yet), not a test defect.

## Unrelated flaky/failing test spotted while running the full suite

Full `flutter test` (not just `test/matches/`) has `test/profile/profile_provider_test.dart`'s
`BreederStatisticsNotifier error surfaces as AsyncError` intermittently time out after 30s with
`Bad state: Tried to read a provider from a ProviderContainer that was already disposed` — smells
like a missing/late `addTearDown(container.dispose)` ordering or a listener firing after dispose in
that file. Out of scope for this matches-focused review (pre-existing file, untouched by this
batch) but worth a dedicated look before it's trusted in CI.
