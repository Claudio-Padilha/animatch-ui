---
name: project-herd-batch-review
description: Review findings on the herd repository/provider test batch (testing-plan.md §5.3-5.5), landed 2026-08-16 — two real gaps worth fixing before copying the pattern forward
metadata:
  type: project
---

Reviewed `test/herd/herd_repository_test.dart`, `test/herd/herd_provider_test.dart`, and the
`FakeHerdRepository`/`FakeProfileRepository`/`SeededAuthNotifier` additions to
`test/helpers/fakes.dart` (2026-08-16). All 34 herd tests pass, `flutter analyze` clean. Two real,
not-yet-fixed gaps to carry into the next batch (discover/matches/profile use the same fake
patterns):

1. **`FakeHerdRepository.getAnimals(String breederId)` doesn't capture the `breederId` argument**
   (`test/helpers/fakes.dart`) — it only increments a call counter, ignoring the parameter. This
   means `herd_provider_test.dart`'s test titled *"fetches via the repository using the logged-in
   breeder id"* only proves `getAnimals` was called once; it does not prove which id was passed.
   A bug that hardcoded/dropped the breeder id would slip through silently. Fix: add a
   `getAnimalsCallArgs`/`List<String>` (or similar) field, same pattern already used for
   `addAnimalPayloads`/`updateAnimalCalls`/`deleteAnimalCalls` in the same fake — those three
   already capture args correctly, `getAnimals` is the one inconsistent one.
2. **`UpdateAnimalNotifier.updateAnimal` and `ToggleAnimalNotifier.toggle` have no failure-path
   test** in `herd_provider_test.dart`, unlike their siblings `AddAnimalNotifier.addAnimal` and
   `DeleteAnimalNotifier.deleteAnimal`, which both explicitly assert `AsyncError` state +
   no-`updateOne`/no-`invalidate` on failure. All four notifiers share the identical
   `if (result is AsyncData...) { ...; ref.invalidate(breederStatisticsProvider); }` guard shape
   (`lib/features/herd/providers/herd_provider.dart`) — the failure branch is exactly the kind of
   silent-regression risk the file's own comments call out elsewhere (e.g. the "no ghost removal"
   delete-failure test). Cheap to add symmetric failure tests for these two.

See also [[feedback_riverpod_invalidate_testing]] for the `_settle()` vs `container.pump()`
finding from the same review.

K-1 in `docs/known-issues.md` was independently re-checked and confirmed correct: `HerdAnimal.fromJson`
(`lib/features/herd/domain/herd_animal.dart:80`) does read the registration number from the
snake_case `registration_number` key on the GET response, contradicting the doc's original
"camelCase is obviously correct" framing. No action needed, just confirming the other engineer's
read was accurate, not backwards.
