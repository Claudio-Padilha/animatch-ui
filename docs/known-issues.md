# Known Issues

Lightweight tracker for bugs found outside the main `production-review.md` pass — e.g. surfaced incidentally while auditing something else. Numbered `K-#`, independent of that doc's `M-#`/`L-#`/`H-#` series.

---

## K-1 — `addAnimal`/`updateAnimal` send different JSON keys for the same field

**Status:** Fixed 2026-09-05
**Found by:** `flutter-test-engineer` while drafting `docs/testing-plan.md` (2026-08-04)
**File:** `lib/features/herd/providers/herd_provider.dart`

`AddAnimalNotifier.addAnimal` and `UpdateAnimalNotifier.updateAnimal` build near-identical payloads for the herd API, but disagree on the registration-number key:

```dart
// addAnimal — line 108
if (registrationNumber != null && registrationNumber.isNotEmpty)
  'registrationNumber': registrationNumber,

// updateAnimal — line 174
if (registrationNumber != null && registrationNumber.isNotEmpty)
  'registration_number': registrationNumber,
```

One sends camelCase, the other snake_case. Every other key in both payloads (`breederId`, `zipCode`, `geneticIndices`, etc.) is camelCase, so `registration_number` in `updateAnimal` looks like the actual mistake, not `addAnimal`.

**Impact:** if the backend only recognizes one casing, updating an animal's registration number either silently no-ops (backend ignores the unknown key) or 400s, while creating an animal with the same field works fine — or vice versa, depending on which casing the backend actually expects. Needs to be checked against the Node.js API's actual DTO, not guessed from the client alone.

**Fix:** pick one casing (camelCase, to match the rest of both payloads) and use it in both notifiers. Add a unit test asserting the exact payload shape for both `addAnimal` and `updateAnimal` so this can't drift again silently — tracked as a P0 item in `docs/testing-plan.md`.

**Update 2026-08-16 — casing assumption above may be backwards:** while writing `test/herd/herd_provider_test.dart`, found that `HerdAnimal.fromJson` reads the registration number back out of the **GET** `/animals` response via the snake_case key `registration_number` — evidence the backend might use snake_case. Did not change either notifier at the time — pinned current behavior with a regression test instead.

**Resolution 2026-09-05:** checked against the backend's actual `CreateAnimalBody` DTO (via the `p2-production-readiness-polish` session): the canonical key is **camelCase `registrationNumber`** on both `POST /animals` and `PATCH /animals/:id`. `updateAnimal`'s `registration_number` was the bug — and because Fastify *strips* unknown keys rather than 400ing, the update silently "succeeded" while never persisting the registration number. Fixed: both notifiers now go through a shared `buildAnimalPayload()` helper (`herd_provider.dart`) that emits `registrationNumber`. `HerdAnimal.fromJson` now reads `registrationNumber` (with a `registration_number` fallback). Same pass also fixed two adjacent latent bugs exposed by the strip-don't-400 behaviour: the animal `status` payload was `'inactive'` (not in the `'active'|'paused'` enum) and `geneticIndices` was sent as a *partial* object with nulls filtered out (the DTO requires all 4 keys, each `>0` or `null`). Regression tests updated in `test/herd/herd_provider_test.dart`.

---

## K-2 — Ungated `debugPrint` in `profile_verification_screen.dart`

**Status:** Fixed 2026-08-16
**Found by:** `flutter-test-engineer` while drafting `docs/testing-plan.md` (2026-08-04)
**File:** `lib/features/profile/ui/profile_verification_screen.dart:94`

```dart
} catch (e, st) {
  debugPrint('ProfileVerificationScreen.activate error: $e\n$st');
```

`docs/production-review.md`'s **H-1** fix established that bare `debugPrint()` does **not** get stripped in release builds — only `if (kDebugMode) { debugPrint(...); }` does — and went through `app.dart` and `match_provider.dart` fixing every call site to that pattern (see H-1 and the L-2 resolution note in that doc). This call site in `profile_verification_screen.dart` wasn't part of that sweep and still uses the bare form.

**Impact:** on a profile-activation failure in production, this logs the exception, stack trace, and (indirectly, via the error message) whatever the backend/network layer surfaces about the request to stdout on real devices — same class of leak H-1 was written to close, just missed in one file.

**Fix:** wrap in `if (kDebugMode) { debugPrint(...); }` to match the established H-1 pattern. Worth a quick repo-wide grep for `debugPrint(` to confirm no other call sites were missed by the same sweep.

**Resolution 2026-08-16:** wrapped in `if (kDebugMode) { ... }` while writing `test/profile/profile_verification_screen_test.dart`. Re-ran the suggested repo-wide grep for `debugPrint(` — every other call site (`app.dart`, `match_provider.dart`, `register_screen.dart`) is already correctly guarded; this was the only miss.

---

## K-3 — `MatchDetailScreen` unmatch flow navigates away even when `deleteMatch` fails

**Status:** Fixed 2026-09-05
**Found by:** `flutter-test-engineer` while writing `test/matches/match_detail_screen_test.dart` (2026-08-16)
**File:** `lib/features/matches/ui/match_detail_screen.dart:435-463` (`_UnmatchButton._confirmUnmatch`)

```dart
await ref
    .read(deleteMatchProvider.notifier)
    .deleteMatch(match.id, animalId: animalId);

if (context.mounted) context.go(AppRoutes.matches);
```

`context.go(AppRoutes.matches)` runs unconditionally after the `deleteMatch` call, regardless of whether `deleteMatchProvider`'s resulting state is `AsyncData` or `AsyncError`. A regression test confirming this (`test/matches/match_detail_screen_test.dart`, `'unmatch flow navigates to /matches even when deleteMatch fails'`) passes today because it's asserting the *current* (arguably buggy) behavior, not because the behavior is correct.

**Impact:** if the DELETE request fails (network error, 5xx, race with the other breeder already having deleted the match), the breeder is silently kicked back to the matches list with no error shown, while the match may still exist server-side. This is the same asymmetric-error-handling shape flagged for `edit_animal_screen.dart`'s delete flow in `docs/testing-plan.md` §5.8, which — unlike this screen — *does* gate navigation on success and shows an "Erro ao apagar" SnackBar on failure. `match_detail_screen.dart` should probably follow that same pattern.

**Fix:** gate the `context.go(AppRoutes.matches)` call on `deleteMatchProvider`'s state being non-error (mirroring `edit_animal_screen.dart`'s delete flow), and show an error SnackBar on failure instead of silently navigating away.

**Resolution 2026-09-05:** fixed as part of the backend Part-2 migration (`MatchDetailScreen` was being reworked to load via `GET /matches/:id` anyway). `_UnmatchButton._confirmUnmatch` now returns early with an "Erro ao cancelar o match" SnackBar when `deleteMatchProvider` is `AsyncError`, and only calls `context.go(AppRoutes.matches)` on success. The regression test in `test/matches/match_detail_screen_test.dart` was flipped to assert the fixed behavior (`'unmatch flow does NOT navigate when deleteMatch fails'`).

---

## K-4 — `HerdScreen` overflows horizontally at standard iPhone width (390pt), and marginally even at 430pt

**Status:** Open
**Found by:** `flutter-test-engineer` while writing `test/herd/herd_screen_test.dart` (2026-08-16)
**File:** `lib/features/herd/ui/herd_screen.dart`

Two separate `Row`s in this screen overflow horizontally at a 390×844 test surface (the logical size of the iPhone 12 through 16 standard models — `CLAUDE.md`: "Primary platform: iOS — elite breeders predominantly use iPhone"):

1. **`_QuotaBar`'s header row** (`herd_screen.dart:199-218`) — `Row(mainAxisAlignment: spaceBetween, children: [Text('$count / $limit animais'), <"Plano Gratuito" chip>])`. Neither child is wrapped in `Expanded`/`Flexible`, so if their combined intrinsic width exceeds the available width, it overflows outright rather than wrapping or eliding. Overflowed by ~40px at 390pt in the `count == limit` case ("5 / 5 animais" is wider than "2 / 5 animais"). Still overflowing by 0.3px even at 430pt — this is right at the edge, not comfortably fixed by a slightly bigger phone.
2. **`_AnimalCard`'s info row** (`herd_screen.dart:334`, the row wrapping `_AvailabilityChip`, combined with the adjacent `_SelectButton` at `herd_screen.dart:345`) — overflowed by 15-40px at 390pt depending on whether the select button reads "Selecionar" or the wider "Selecionado" state.
3. **`_StatusRow` in `my_animal_detail_screen.dart:429`** (same pattern — icon + `Text('Disponível para matching' / 'Indisponível para matching')` in a `Row` with no `Expanded`/`Flexible`) — found while writing `test/herd/my_animal_detail_screen_test.dart`; still overflowed by 11px even at 430pt, needed 480pt to clear. This confirms the pattern isn't isolated to `herd_screen.dart` — it's a repeated shape (unconstrained icon+text `Row` for a status/badge line) across the herd feature's screens.

**Impact:** on the actual primary target device width, the herd list — the screen breeders spend the most time on to manage their animals — renders with visible yellow/black overflow warning stripes in debug builds, and clipped/truncated content in release builds. This isn't a rare edge case; it reproduces on the *default* "populated herd" state, not a stress-test scenario.

**How found:** widget tests in `test/herd/herd_screen_test.dart` originally used the project's standard 390×844 test device size (per the `flutter-test-engineer` agent's own convention for this repo) and immediately hit `RenderFlex overflowed` assertions on states that have nothing to do with what was being tested (loading/error/quota-bar/availability-chip states all triggered it). Widened the test viewport to 480×1200 to route around it and keep the tests focused on their actual subject — this does **not** fix the underlying issue, it only avoids it being a false test failure unrelated to what each test is checking.

**Fix:** wrap the `Text`/chip pair in `_QuotaBar`'s header row with `Expanded`/`Flexible` (likely on the count text, with `overflow: TextOverflow.ellipsis` as a fallback), and similarly constrain `_AnimalCard`'s info column vs. `_SelectButton` — the `Expanded` around the info `Column` exists already (`herd_screen.dart:323`) but its own inner `Row` (line 334) doesn't reserve space correctly once `_SelectButton`'s width varies by state. Wrap `_StatusRow`'s label `Text` in `my_animal_detail_screen.dart:429` the same way. Needs an actual device/simulator check once fixed, not just widening test viewports further — and worth a quick grep for other icon+text `Row`s in `lib/features/herd/ui/` following this same unconstrained shape, since three independent instances of it turning up while writing tests suggests it may be a repeated copy-paste pattern rather than three unrelated bugs.

**Methodology note (applies to K-5 too):** these `Row`s use `GoogleFonts`-styled `Text` (`app_theme.dart` uses `GoogleFonts.inter`/`.merriweather` throughout), and this repo had no global test config disabling `GoogleFonts.config.allowRuntimeFetching` — only `test/widget_test.dart` set it locally, in its own `setUpAll`. Every other widget test (including the ones that found K-4) was rendering text with whatever `google_fonts` falls back to when a real network fetch isn't available in this sandboxed test environment (observed as `family: Roboto` in the failure output), not the real Merriweather/Inter used in production — so pixel-level overflow amounts measured here may not match a real device exactly. Added `test/flutter_test_config.dart` (repo-wide, auto-picked-up by the test runner) to make this deterministic across every test file going forward, and re-confirmed K-4's overflows are **not** an artifact of the fetch race — they reproduce identically with runtime fetching disabled. The underlying "unconstrained `Row`, text sized off whatever font actually loads" shape is still worth fixing regardless of which exact font is in play.

---

## K-5 — `LoginScreen` (and likely `RegisterScreen`) overflow horizontally well past 480pt, not just at standard iPhone width

**Status:** Open
**Found by:** `flutter-test-engineer` while writing `test/auth/login_screen_test.dart` (2026-08-16)
**File:** `lib/features/auth/ui/login_screen.dart`

Two more instances of the K-4 pattern, but noticeably worse in magnitude:

1. **`AnimatchLogo`'s internal `Row`** (`lib/shared/widgets/animatch_logo.dart:12-29`) — `Row(mainAxisSize: min, children: [Image.asset(...), SizedBox(width: 8), Text('Animatch', style: GoogleFonts.merriweather(fontSize: size, fontWeight: bold))])`, used at `login_screen.dart:59` with `size: 44` (unusually large — most other call sites use the 32pt default). `mainAxisSize: min` means the `Row` sizes itself to its content regardless of the parent's available width, so it overflows outright rather than shrinking. Overflowed by ~72px at 390×844.
2. **The "Não tem uma conta? Criar conta" row** (`login_screen.dart:87`, `mainAxisAlignment: center`, two `Text` children, no `Expanded`/`Flexible`) — overflowed by 94px at 390×844.

Unlike K-4 (which cleared at 430-480pt), **this screen needed a 500pt-wide test viewport to render without overflow** — meaning it doesn't just barely miss on standard iPhones, it's overflowing by a wide margin on every current iPhone model (390-430pt logical width), not just the smallest ones. `register_screen.dart` uses the same `AnimatchLogo` at its default 32pt size (not the login screen's oversized 44pt) and the same "Já tem uma conta? Entrar" row pattern at `register_screen.dart:82` — **confirmed via `test/auth/register_screen_test.dart`**: overflows by 8px at 390×844, clears at 410×844. Much smaller than login's ~72-94px, consistent with `size: 44` (vs. register's default 32) being the dominant factor in `login_screen.dart`'s overflow.

**Impact:** this is the **login screen** — the first thing a returning user sees, on every session start until `authInitializedProvider` settles them elsewhere. An overflow this size isn't a subtle edge case; it's plausibly visible on real devices as clipped/overlapping content on the app's most-trafficked screen.

**Fix:** give `AnimatchLogo` a `Flexible`/`Expanded` wrapper around its `Text` (with `overflow: TextOverflow.ellipsis` or a `FittedBox`) so a large `size` doesn't force unbounded width, or reconsider whether `size: 44` on the login screen is intentional at all (every other call site in the codebase should be checked). Wrap the "Criar conta"/"Entrar" link row's leading `Text` in `Flexible` so it wraps or ellipses instead of overflowing. Check `register_screen.dart`'s equivalent row while in there. Needs a real device/simulator check once fixed — this was found and sized via `flutter test`'s font-fallback rendering (see the methodology note under K-4), so exact pixel counts may differ with the real production fonts loaded, but the underlying unconstrained-layout shape is the same class of bug either way.

---

## K-6 — No way to edit breeder associations after activation

**Status:** Fixed 2026-09-05
**Found by:** backend contract reconcile during the Part-2 migration (2026-09-05)
**File:** `lib/features/profile/ui/edit_profile_screen.dart`, `lib/features/profile/data/profile_repository.dart`

`PATCH /breeders/:id` does **not** accept an `associations` key — the backend silently strips it (Fastify `removeAdditional`, no 400). Associations can only be set through `PATCH /breeders/:id/activate`, which is a one-time onboarding step.

`EditProfileScreen` still renders an `AssociationsPicker` (pre-filled from the current profile, with an `onChanged` handler). Before this migration it passed the edited list to `updateProfile` → the backend dropped it → the edit **silently did nothing**. As of 2026-09-05 the client no longer sends `associations` on `updateProfile` (the dead key was removed), but the picker is still shown and still looks editable.

**Impact:** a breeder who adds/removes an association or edits a registration number in the edit-profile screen sees the UI accept it, gets a "Perfil atualizado" success toast, and the change is never persisted (and reverts on next profile fetch).

**Fix options:** (a) backend adds a dedicated associations endpoint (`PATCH /breeders/:id/associations` or accept the key on the main PATCH); then re-wire `updateProfile`. (b) Until then, make the picker in `EditProfileScreen` read-only / informational, or drop it from that screen and point users to re-verification. Decision pending — flagged to the backend team.

**Resolution 2026-09-05:** the backend took option (a) — `PATCH /breeders/:id` now accepts `associations: [{ code, registration_number? }]` (replaces the whole set; `[]` clears; omit the key to leave untouched; unknown code → 422), and both `PATCH /breeders/:id` and `/activate` now return the `associations` array in the response. FE re-wired: `ProfileRepository.updateProfile` / `ProfileNotifier.updateProfile` take an optional `List<BreederAssociation>? associations` (null → key omitted). `EditProfileScreen` tracks an `_associationsDirty` flag set by the picker's `onChanged` and only passes the list when the picker was actually touched, so a name/phone-only edit doesn't disturb the set. Tests in `test/profile/profile_repository_test.dart` (null-omits / list-replaces / `[]`-clears) and `test/profile/edit_profile_screen_test.dart` (untouched picker → key omitted).

---

## PROD-VERIFY-1 — `AssociationsPicker` uploads a document per association, but the backend doesn't store or review it yet

**Status:** Open — client-only, needs backend contract
**File:** `lib/shared/widgets/associations_picker.dart`, `lib/shared/domain/breeder_association.dart`

Each association row now lets the breeder attach a photo of their association membership card ("carteirinha") or an animal's Certificado de Registro Genealógico, as evidence backing the self-reported registration number — uploaded via the existing `CloudinaryUploader` (`folder: 'breeder-documents'`) the same way the profile selfie and animal photos already are. `BreederAssociation.toJson()` includes the resulting URL as `document_url` (mirroring the existing `registration_number` snake_case convention on the `/activate` and `/breeders/:id` payloads).

**Gap:** the backend (separate Node repo) does not currently declare `document_url` on either endpoint's schema. Given `removeAdditional` behavior already observed for `associations` in [[K-6]], the key is almost certainly silently stripped today rather than erroring — the upload succeeds (real Cloudinary URL, shown in the UI), but it isn't persisted or visible to whoever reviews activation requests.

**Also unverified:** the "membership card" framing was checked directly only for ABCCMM (a photo ID card, per `abccmm.org.br`); the other four associations (ABCZ, ABQM, ABCCrioulo, ABCAngus) likely have an equivalent but weren't individually confirmed — worth a quick check before finalizing review-team guidance on what a valid attachment looks like.

**Fix:** backend adds `document_url` (string, optional) to the `associations[]` item schema on both endpoints, persists it, and surfaces it to whatever tooling/queue the team uses to approve `pending` breeders. Flagged to the backend team the same way as [[K-6]] was.
