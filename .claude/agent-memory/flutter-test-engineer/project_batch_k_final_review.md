---
name: project-batch-k-final-review
description: Review findings on Batch K (app_router_edge_cases_test, animal_detail_loader_test, cloudinary_uploader_test, discover _seenIds group), 2026-08-16
metadata:
  type: project
---

Reviewed the 4 files closing out `docs/testing-plan.md`'s final P0/P1 batch (2026-08-16). All 320
tests pass, `flutter analyze` clean. Two concrete issues found, both worth fixing next time this area
is touched.

## Confirmed bug in the batch's own claim: no real "declaration-order" collision exists for editAnimal/myAnimalDetail

`test/router/app_router_edge_cases_test.dart`'s `'editAnimalPath is not shadowed by myAnimalDetail
despite the path-prefix collision (declaration-order regression)'` test, and the matching P2 item in
`docs/testing-plan.md` (§ line ~52), both claim a one-line reordering of the two `GoRoute`s in
`app_router.dart` would silently reintroduce a routing bug. **Empirically false** — swapped the
declaration order of `AppRoutes.editAnimal`/`AppRoutes.myAnimalDetail` in `app_router.dart`, reran
just that test, it still passed; reverted immediately after. Root cause (confirmed via go_router
14.8.1 source, `lib/src/match.dart:_matchByNavigatorKeyForGoRoute`): a `GoRoute`'s prefix-regex match
is only accepted as final if it consumes the **entire** remaining location, or the route has child
`routes:` to consume what's left. `editAnimal` (`/rebanho/animal/editar/:animalId`, 4 segments) and
`myAnimalDetail` (`/rebanho/animal/:animalId`, 3 segments) are flat siblings with no children, so
`myAnimalDetail` can never match a 4-segment location regardless of list order — segment-count
mismatch rules it out structurally, not by declaration order.

This is not a new discovery — `docs/production-review.md`'s own H-6 section (line 315) **already
documents this exact conclusion**, from when `editAnimal` was converted from 3 to 4 segments: *"Since
this route now has 4 path segments vs. myAnimalDetail's 3, the declaration-order collision risk above
no longer applies here... the reordering fix/comment for that specific collision was updated
accordingly."* The stale "declaration-order" framing in `testing-plan.md`/the new test's docstring
appears to have been written without cross-checking that earlier, correct resolution note. The test
itself still has minor value (confirms the URL resolves to the right screen with the right id), but
its stated rationale is wrong and should be corrected — either reframe the test as a plain
route-resolution regression check, or drop the "declaration-order" framing from both the test
docstring and the testing-plan.md item.

## `FakeHerdRepository` has no call counter for `getAnimal` (singular) — one assertion in `animal_detail_loader_test.dart` is vacuous

`test/helpers/fakes.dart`'s `FakeHerdRepository` tracks `getAnimalsCalls`/`getAnimalsCallArgs` for the
**list** method (`getAnimals(breederId)`) but has **no counter at all** for `getAnimal(id)` (singular)
— see `fakes.dart:283-299`. `animalDetailDataProvider` (what `AnimalDetailLoader`'s extra-absent
fallback path uses, `herd_provider.dart:24-27`) calls `getAnimal(id)`, not `getAnimals`.

`test/shared/animal_detail_loader_test.dart`'s first test, `'extra present: renders it directly,
without touching the repository (no fetch)'`, asserts `expect(repo.getAnimalsCalls, 0)` as proof of
"no fetch." This assertion is currently true only because `AnimalDetailLoader`'s `animal != null`
branch returns before evaluating `ref.watch(animalDetailDataProvider(...))` at all — but even if a
future refactor accidentally made the extra-present branch also call
`animalDetailDataProvider`/`getAnimal(id)`, `getAnimalsCalls` would **still read 0**, because that
counter only increments for the unrelated plural method. The test would keep passing straight through
the exact regression it's named to catch. Fix: add a `getAnimalCalls` counter (singular) to
`FakeHerdRepository.getAnimal` and assert against that instead.

Not the same pattern elsewhere — `app_router_edge_cases_test.dart`'s `myAnimalDetailPath`/`editAnimal`
tests correctly rely on `getAnimals` (plural), since those screens genuinely read through
`herdProvider`'s list, not the singular fetch.

See also [[project_herd_ui_batch_review]], [[project_test_infrastructure]].
