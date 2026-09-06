---
name: project-herd-ui-batch-review
description: Review findings on the herd UI-layer test batch (testing-plan.md §5.6-5.9 — herd_screen/add_animal_screen/edit_animal_screen/my_animal_detail_screen), landed 2026-08-16
metadata:
  type: project
---

Reviewed `test/herd/{herd_screen,add_animal_screen,edit_animal_screen,my_animal_detail_screen}_test.dart`
(2026-08-16). All 62 herd tests pass, `flutter analyze test/herd/` clean. None of the three
previously-flagged anti-patterns recur (see [[feedback_riverpod_invalidate_testing]] and prior batch
reviews): no `Future.delayed` hacks, `FakeHerdRepository`'s arg-capturing gap from the last review is
fixed (`getAnimalsCallArgs` now captures `breederId`), and `retry: (retryCount, error) => null` is
present on every `ProviderContainer` that actually drives an `AsyncError` state.

## K-4 (herd_screen.dart / my_animal_detail_screen.dart overflow) — independently reproduced, real

Wrote a throwaway test rendering `HerdScreen` with 5 animals at 390×844 — got an actual
`RenderFlex overflowed by 15 pixels` at `herd_screen.dart:334` (`_AnimalCard`'s info row wrapping
`_AvailabilityChip`, which shares its row's available width with the adjacent `_SelectButton`).
Confirms K-4 in `docs/known-issues.md` is a real production layout bug, not a test-viewport artifact.

## Riverpod 3.1.0 `AsyncValue.whenData` swallows callback exceptions — independently reconfirmed

Read `~/.pub-cache/hosted/pub.dev/riverpod-3.1.0/lib/src/core/async_value.dart:168-188` directly: the
`data` branch of `whenData` wraps `cb(d.value)` in `try/catch` and converts a thrown error into
`AsyncError`. So `my_animal_detail_screen.dart`'s `herdProvider.whenData((list) => list.firstWhere(...))`
does NOT crash uncaught when the id isn't in the list — it renders the normal error/retry UI. This
was flagged as a possible unguarded-crash concern in testing-plan.md §5.9 and correctly resolved as
"not a bug" — verified against source twice now (once by the test's own author, once independently
in this review). Safe to trust this conclusion going forward without re-deriving it, provided the
Riverpod major version pinned in `pubspec.yaml` is still `^3.0.0`.

## K-4-style viewport widening is only demonstrated for 2 of the 4 herd UI test files

`herd_screen_test.dart` (480×1200) and `my_animal_detail_screen_test.dart` (480×1400) genuinely need
widening — confirmed by reproducing real overflow at 390pt. But `add_animal_screen_test.dart` (430×1600)
and `edit_animal_screen_test.dart` (430×1800) pass cleanly when rerun at 390pt width (with adequate
height so the submit button stays on-screen for `tap()` — the original 844pt-height default was too
short and caused an unrelated off-screen-tap failure, not a width/overflow issue). The 430pt choice in
those two files looks like defensive copy-paste of the pattern rather than a demonstrated need — harmless
(doesn't mask anything, since nothing overflows at 390 either), but if `docs/known-issues.md` or
`docs/testing-plan.md` is revised, the "viewport widening was required across the herd feature" framing
should be scoped to just the 2 files that actually need it.

## `_selectDropdown` test helper (`add_animal_screen_test.dart:71-81`) is index-based, not label/key-based

`find.byType(DropdownButtonFormField<String>).at(index)` relies on the current Espécie(0)/Raça(1)/Sexo(2)
field order in `add_animal_screen.dart`. The widget already carries distinguishing `ValueKey`s
(`breed-${species.name}`, `sex-${species.name}`) that a `find.byWidgetPredicate` could target instead —
worth suggesting if this helper gets reused/extended (e.g. for `edit_animal_screen.dart`, which doesn't
use it yet since its tests don't drive dropdown menus directly). Not broken today, just fragile to
reordering with no clear failure signal if it breaks.

Relatedly: the "species change resets breed/sex" test's pass/fail is driven mostly by the `_Dropdown`
widget's own `ValueKey` change forcing a full remount on species switch, not primarily by the explicit
`_selectedBreed = null` / `_selectedSexLabel = null` lines in `_onSpeciesChanged` — a regression that
dropped just those two state-reset lines would likely still pass this test, since the dropdown's own
internal value resets via remount regardless, and the form validator checks the dropdown's own value,
not the state variable. The test is still legitimate coverage of user-visible behavior, just a weaker
guard against that specific internal-state bug than it might appear.

See also [[project_herd_batch_review]] (repository/provider layer, batch 1) and
[[feedback_riverpod_invalidate_testing]].
