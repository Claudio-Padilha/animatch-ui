# Animatch — Store Launch Plan

**Author:** Claudio (padilha86@gmail.com) + Claude (animatch-ui repo)
**Date:** 2026-09-19
**Order:** Google Play first, App Store second (iOS is the primary target platform long-term, but Play can ship sooner — no Apple Developer enrollment/CI dependency blocks it).
**Current app version:** `1.0.0+1` (`pubspec.yaml`)
**Bundle/application ID (both platforms):** `com.animatch.animatch`

This plan reflects the actual current state of the repo as of this date — see `docs/production-review.md` (2026-05-10 audit, nearly all items resolved) and `docs/known-issues.md` (all K-1…K-6 and PROD-VERIFY-1 fixed) for the detailed trail. It does not restate resolved work; it lists what's left.

---

## Status snapshot

| Track | State |
|---|---|
| Code quality / security audit (`production-review.md`) | All Critical/High/Medium items resolved except **C-5 (iOS signing)** |
| Known functional bugs (`known-issues.md`) | All closed |
| Test suite | 364 tests passing, `flutter analyze` clean |
| Android release signing | Done — real upload keystore since 2026-07-30, R8/minify on |
| Android manual release-build device pass | **Not done** — required before submission (see below) |
| iOS signing / provisioning | **Not started** — no Apple Developer account artifacts in repo |
| iOS CI (Codemagic / GH Actions macOS) | **Not set up** |
| Privacy policy | Drafted (`docs/privacy-policy.md`, pt-BR/LGPD) — **has `[PREENCHER]` placeholders, not legally reviewed, not published** |
| Store listing assets (screenshots, feature graphic, descriptions) | **Not started** |
| Play Console / App Store Connect accounts | Not confirmed — verify with Claudio |

---

## Phase 1 — Google Play (target: first submission)

### 1.1 Final engineering gate
- [ ] Run `flutter test` and `flutter analyze` one more time immediately before cutting the release build (catch any regression since 2026-09-19).
- [ ] Build the real artifact: `flutter build appbundle --release --dart-define-from-file=config/production.env.json`.
  - **Blocker:** `config/production.env.json` currently holds `REPLACE_ME` placeholders for `AUTH0_DOMAIN`, `AUTH0_CLIENT_ID`, `AUTH0_AUDIENCE`, `STREAM_CHAT_API_KEY`. These do not fail fast (non-empty strings) — a build with placeholders will compile and launch, then fail at first Auth0 call. **Get real production values before building** (Auth0 prod tenant, Stream Chat prod key) — see backend coordination section.
- [ ] **Manual release-build verification pass** (never done — `production-review.md` C-1's own open item): install the signed release AAB/APK on a real Android device or emulator and exercise, specifically because R8 minification only runs in this build type:
  - Login / logout / token refresh (Auth0)
  - Push notification delivery + tap-to-navigate (Firebase Messaging)
  - Chat (Stream Chat)
  - Maps rendering (google_maps_flutter)
  - JSON-backed screens: herd, matches, discover, animal detail
  - Association document upload + verification status display
- [ ] Confirm `--dart-define-from-file=config/production.env.json` (not `local.env.json`) is what any build script/CI actually uses — `app_env.dart` silently defaults to `ENV=local` if the flag is dropped.

### 1.2 Play Console setup
- [ ] Confirm a Google Play Developer account exists (or create one — one-time $25 fee, Google identity verification can take a few days; start this early, it's the most likely schedule blocker in this phase).
- [ ] Create the app listing under the existing `com.animatch.animatch` package.
- [ ] **Enroll in Google Play App Signing** at first upload (per prior audit note — not yet enrolled, nothing uploaded yet).
- [ ] Set up an internal testing track first (not straight to production) — upload the AAB there, add Claudio + any other reviewers as internal testers.

### 1.3 Store listing content
- [ ] Short description, full description (pt-BR) — not yet written.
- [ ] Screenshots — **none exist locally.** Need phone screenshots (and optionally 7"/10" tablet if supporting tablets) for: onboarding, discover/match, herd, animal detail, chat. Capture from the Android emulator or a real device once the release build is verified.
- [ ] Feature graphic (1024×500) — not yet made.
- [ ] App icon — already generated via `flutter_launcher_icons` (`assets/images/animatch_icon.png` source), reusable for the Play listing icon.
- [ ] Category, contact email, and (if applicable) website.

### 1.4 Data safety form (Play Console) — **backend answers received 2026-09-19, two real gaps found**
Confirmed directly against backend source by the backend session (not a guess):

- **Hosting region:** only Stream Chat has an explicit region — `sa-east-1` (São Paulo), deliberately chosen for LGPD. Railway app/Postgres region, Cloudinary account region, Firebase project region, and the Auth0 tenant region are **dashboard settings, not in version control** — unconfirmed, don't assume Brazil. **Action: check each of the 4 consoles directly before filling the data-safety form's "where is data stored" question.**
- **Deletion — partially built, real gap:** `DELETE /breeders/:id` exists (JWT-authed, self-only, immediate hard delete). DB cascade correctly removes the breeder row plus `animals`, `matches`, `breeder_associations`, `device_tokens`; `address` is orphaned via FK-null (non-PII geo data only, not a concern). **But it only deletes Postgres rows.** It does NOT delete: Cloudinary-hosted images (profile photo, animal photos, association documents — only the URL string is removed, files stay hosted), the Stream Chat user/message history, or the Auth0 identity (email + auth0Id remain in the Auth0 tenant). **If either store's deletion requirement means "erase personal data across all systems" (common interpretation for LGPD/GDPR-style disclosures), this endpoint alone does not satisfy it today.** Decision needed: close the gap (cascade deletes into Cloudinary/Stream/Auth0 too) before submission, or document it as a known limitation and disclose accordingly. Not purely an engineering call — flag to Claudio.
- **Encryption at rest — not implemented, plaintext today.** `docs/lgpd-pii-encryption.md` (backend repo) is a design spec only (app-layer AES-GCM + HMAC blind index for email/phone/cpf), not built. CPF, email, phone are plaintext in Postgres; only TLS-in-transit exists. Correction to this plan's earlier assumption: there is no dedicated "selfie" field — the two Cloudinary-URL fields are `breeders.pictureUrl` (profile photo) and `breeder_associations.documentUrl` (association card photo); the actual image bytes' at-rest protection is Cloudinary's infrastructure, unverified/uncontrolled by us. **The privacy policy's "how we protect your data" language must say "in transit only" today, not "encrypted at rest," until this is built** — don't let the policy overstate protection that doesn't exist yet.
- **Subprocessors — confirmed, matches this doc's existing list, no additions:** Auth0, Stream Chat, Firebase (Admin SDK/FCM), Cloudinary, Railway. Geocoding is fully internal (static municipalities table, no external API); no email/SMS provider integrated.
- Backend has its own `docs/launch-plan.md` (backend readiness) and independently flagged the same encryption gap as its top open item — this is a live, unresolved decision on both sides, not settled anywhere yet.

**Action before filling either store's privacy form:** Claudio needs to decide (a) whether the deletion gap (Cloudinary/Stream/Auth0 remnants) gets closed pre-launch or disclosed as a limitation, and (b) the honest at-rest-encryption answer, before the privacy policy's placeholder sections are filled in for real.

### 1.5 Privacy policy — **hard blocker, explicitly held by Claudio**
- `docs/privacy-policy.md` exists but is intentionally not published: has `[PREENCHER]` placeholders (razão social, CNPJ, endereço, contact email, DPO) and has not had legal review. **Do not publish or link it from any store listing until Claudio provides the real values and signs off** — this was an explicit instruction in a prior session and still applies.
- Play requires a live privacy policy URL before submission — this blocks 1.2 onward until resolved.

### 1.6 Submission
- [ ] Submit AAB to internal testing → verify install/update flow → promote to closed or open testing if desired → production.
- [ ] Expect Play's standard review (usually hours to ~a few days for a first submission, longer if data-safety or permissions flags trigger manual review — camera/photo/location-adjacent permissions and financial-sounding domain content, given this app's high-value transaction framing, are worth double-checking don't trip extra scrutiny).

---

## Phase 2 — Apple App Store (starts in parallel where possible, submission after Play)

### 2.1 Apple Developer Program
- [ ] Confirm/enroll Animatch's Apple Developer Program membership ($99/yr). This is the actual critical-path item — start immediately, do not wait for Phase 1 to finish, since Apple enrollment can take days.

### 2.2 iOS signing (`production-review.md` C-5 — not started)
- [ ] Register App ID `com.animatch.animatch` in the Apple Developer portal with required capabilities (Push Notifications; Sign in with Apple only if actually used — confirm against `auth0_config.dart`, currently just standard Auth0 login).
- [ ] Generate a Distribution Certificate + App Store provisioning profile.
- [ ] Set `DEVELOPMENT_TEAM` in Xcode / `ios/Flutter/Release.xcconfig`, add `ExportOptions.plist` (`method: app-store`).
- [ ] Recommended: Fastlane `match` or Codemagic automatic signing via an App Store Connect API key — do not commit certs/profiles to this repo.

### 2.3 iOS CI (no macOS dev machine)
- [ ] Stand up Codemagic (Flutter-native, free tier) or a GitHub Actions `macos-latest` workflow that runs `flutter build ipa --release --dart-define-from-file=config/production.env.json` and uploads to TestFlight. This repo currently has no `.github/workflows` at all.

### 2.4 iOS-specific engineering checks
- [ ] Confirm `PrivacyInfo.xcprivacy` (Apple's privacy manifest) is present/correct given Firebase, Auth0, and image_picker usage — missing manifest is a common upload-time rejection as of current App Store rules. `production-review.md` flagged this as worth checking; verify current status.
- [ ] `NSCameraUsageDescription` / `NSPhotoLibraryUsageDescription` / `NSPhotoLibraryAddUsageDescription` are already added to `Info.plist` (C-2, resolved) but **never verified on a real device/simulator** — do this on first TestFlight build.
- [ ] Real device or Mac simulator UI fidelity pass — iOS is the primary target platform per `CLAUDE.md`, and the K-4/K-5 overflow bugs were only caught because of prior visual under-testing on this platform. Don't skip this.

### 2.5 App Store Connect listing
- [ ] Screenshots for required device sizes (6.7", 6.5", 5.5" iPhone at minimum — check current Apple requirements at submission time, they change).
- [ ] App Store description, keywords, category, support URL, marketing URL (optional).
- [ ] App Privacy "nutrition label" questionnaire — same underlying data-collection facts as the Play data-safety form (1.4), so fill both from one shared source of truth to avoid inconsistency between the two stores' privacy disclosures.
- [ ] Same privacy-policy blocker as Play (2.1 above) — needs the same real, legally-reviewed URL.

### 2.6 Submission
- [ ] TestFlight internal testing first, given the iPhone visual-fidelity gap noted above.
- [ ] Submit for App Review. Apple review is typically 1–3 days but first-time submissions from a new developer account can take longer and are more likely to get a human reviewer flagging things like the CPF/selfie identity-verification flow — be ready to explain that flow in App Review notes (what it's for, that it's not a payment/KYC-regulated flow if that's accurate, or clarify if it is).

---

## Cross-cutting blockers (apply to both stores)

1. **Privacy policy finalization** — waiting on Claudio for real business/legal details; do not self-serve this. Now also blocked on Claudio deciding the deletion-gap and encryption-at-rest questions below, since the policy's own accuracy depends on those answers.
2. **Production config values** — `config/staging.env.json` is now **fully real, no placeholders left** (filled 2026-09-19 with values from `animatch-5d`): `AUTH0_DOMAIN`/`AUTH0_CLIENT_ID` reuse the shared dev tenant, `AUTH0_AUDIENCE` is staging-specific (`https://api-staging.animatch.app`), `STREAM_CHAT_API_KEY` reuses the same dev/local key (`chbd9fpt9qxu`) — Stream Chat is intentionally shared across all environments for now, no dedicated staging app. Also fixed a real bug found in the process: `apiBaseUrl` for staging was hardcoded to the wrong host (`staging-api.animatch.com.br` instead of the actual `animatch-staging.up.railway.app`). **Still open:** `config/production.env.json` is untouched, still all `REPLACE_ME` — nobody has supplied real production Auth0/Stream Chat values yet.
3. **Manual release-build device verification** — Android done-but-unverified, iOS not yet possible without a Mac/CI.
4. **Account/data deletion — RESOLVED for Cloudinary/Stream, Auth0 residual by design.** `DELETE /breeders/:id` now cleans up Postgres, Cloudinary assets, and the Stream Chat user/history; verified with a real (non-mocked) staging run, see the "Account deletion" section below. Only the Auth0 identity is intentionally left behind (deferred, documented limitation, disclosed in the in-app confirm copy) — not an open gap, a scoped decision.
5. **No encryption at rest** — CPF/email/phone are plaintext in Postgres today (TLS-in-transit only); a design spec exists (`docs/lgpd-pii-encryption.md`, backend repo) but is unbuilt. Privacy policy language must not claim at-rest encryption until this ships.
6. **Hosting region unconfirmed for 4 of 5 subprocessors** — only Stream Chat has a verified region (`sa-east-1`, São Paulo). Railway, Cloudinary, Firebase, and Auth0 regions are dashboard settings not visible in either repo's source — check each console before answering the "where is data stored" question on both stores' forms.
7. **Staging login/signup — RESOLVED and confirmed working end-to-end, 2026-09-19.** Root cause (found by `animatch-5d`): the original "Animatch API (staging)" Resource Server had a literal leading space baked into its identifier in Auth0 (`" https://api-staging.animatch.app"`, 33 chars vs. the 32-char string every client correctly sent) — invisible in the dashboard UI, only caught by comparing character counts. Since Auth0 API identifiers are immutable once set, the fix was creating a replacement API with a byte-verified-clean identifier and re-granting the app's User-delegated Access to it. **Verified for real, not just via a dashboard check:** ran a full signup on the Android emulator against staging (`animatch.qa.staging1@mailinator.com`) — Auth0 signup succeeded, the app reached "Complete seu perfil" (profile completion), a native push-notification permission prompt fired (confirms Firebase works too), and killing + relaunching the app restored the session correctly (confirms `restoreSession()`/credentials persistence works against staging). This is real evidence the full auth pipeline — client config, Auth0, and the backend's JWT handling — works end to end against staging.
8. **Full profile-completion → chat/photo-upload pass not completed this session** — hit ADB/emulator touch-input flakiness on the "Complete seu perfil" form (taps intermittently not registering on specific fields; root-caused to miscalibrated tap coordinates on this screen combined with some genuine input-injection unreliability, not an app bug) and stopped rather than keep burning time on tooling issues. Auth is proven working; finishing profile completion and reaching chat/photo-upload is a quick follow-up, not a new investigation.

## Backend alignment — resolved 2026-09-19

Backend session (`animatch-6e`) confirmed the facts above directly against source (not from memory/assumption). Subprocessor list matches what was already in the privacy-policy draft (Auth0, Stream Chat, Firebase, Cloudinary, Railway) — no additions. The two real open items (deletion completeness, encryption at rest) are backend-repo work-tracking items too — the backend's own `docs/launch-plan.md` independently flags the same encryption gap as its top open item, so both repos agree this needs a Claudio decision before either store's privacy disclosures are finalized.

## Account deletion — combined FE/BE recommendation (pending Claudio's go-ahead)

Follow-up gap found 2026-09-19: `DELETE /breeders/:id` exists on the backend, but **there is no UI entry point anywhere in the app** — a breeder has no way to trigger it today. Aligned with the backend session on a joint recommendation:

**Recommendation: build the in-app "excluir conta" flow now, not a manual/support-email stopgap.** Apple App Store Review Guideline 5.1.1(v) requires in-app account deletion for any app with in-app account creation — a support-email path is a known Apple rejection reason (in force since 2022; re-verify current wording before relying on this). Play's Data Safety form is more lenient, but since this plan ships Play first then Apple, a manual stopgap now would just be redone as in-app work for the Apple submission anyway.

**Scope, split by size:**
- **Client (small):** profile settings → "Excluir conta" → confirmation dialog → call `DELETE /breeders/:id` → on `204`, proactively clear the local Auth0 session/tokens and navigate to login (the API **cannot** force this — JWTs are stateless, deleting the Postgres row does not revoke the token; skipping this step means the app silently starts getting `403 { message: "Breeder profile required" }` on the next call instead of a clean logout). Handle `403`/`404` explicitly; the endpoint returns `204 No Content`, no body to key UI feedback off of.
- **Backend (small, do pre-launch):** add Cloudinary `destroy` + Stream Chat delete-user calls into the existing `DELETE /breeders/:id` handler — same shape as the existing animal soft-delete → match cascade transaction.
- **Backend (larger, defer post-launch):** full Auth0 identity erasure needs a new Auth0 M2M application scoped to `delete:users` against the Management API — treat as a separate ticket, not bundled into the pre-launch delete work.

**Disclosure requirement for the privacy policy / store forms:** because the Auth0 identity isn't deleted, a breeder can log back in immediately with the same credentials and get a **brand-new** profile via `sync-breeder` — deletion wipes Animatch app data, not the login itself. Copy must say something like "sua conta e dados no Animatch são excluídos; seu login (Auth0) permanece ativo e pode ser reutilizado" — not "your account is gone forever."

**Status: approved by Claudio 2026-09-19. Client side implemented same day; backend implementation in progress.**

Client-side done:
- `AuthRepository.deleteAccount(breederId)` (`lib/features/auth/data/auth_repository.dart`) — calls `DELETE /breeders/:id`, then clears the local Auth0 credentials manager (the JWT itself can't be revoked client- or server-side, so this only stops the app from silently restoring the old session on next launch).
- `AuthNotifier.deleteAccount()` (`lib/features/auth/providers/auth_provider.dart`) — no-op if already logged out; on success clears in-memory state, which `RouterNotifier` already redirects to login for (same mechanism `logout()` uses — no new routing logic needed). Propagates failures (unlike `logout()`) so the UI can surface an error rather than falsely implying success.
- UI: "Excluir conta" button in `lib/features/profile/ui/profile_screen.dart`, confirm dialog with the required disclosure copy (data deleted, login remains active, re-login creates a fresh profile).
- Tests: `test/auth/auth_provider_test.dart` (no-op logged out / success clears state / failure preserves session) and `test/profile/profile_screen_test.dart` (cancel / confirm / failure-shows-snackbar). 364 tests passing, `flutter analyze` clean.

Backend side landed 2026-09-19 (no contract change needed): `DELETE /breeders/:id` now also best-effort deletes the breeder's Cloudinary assets (profile photo, animal photos, association documents — Admin API bulk destroy) and hard-deletes their Stream Chat user (message history + match chat channels). A Cloudinary/Stream failure is caught and logged, not surfaced as a 500 — the Postgres delete (the part that matters for the deletion guarantee) always completes first. Backend verified with an integration test forcing a Cloudinary 500 (still returns 204) and one asserting the exact bulk-delete/`deleteUser` calls fire with the right IDs. Full backend suite green (327 tests), new services at 100% coverage.

Auth0 identity deletion remains the documented residual — unchanged by this work, still the deferred post-launch ticket (new M2M app + Management API `delete:users` scope).

**End-to-end verification — PASSED, 2026-09-19.** Run for real by `animatch-5d` (a second backend-repo session doing staging-environment setup) directly on the staging Railway console — not mocked. They wrote `src/scripts/verify-cleanup-staging.ts` (commits `fc772a8`, `6b11d4e` — the latter fixing a `NODE_ENV`-vs-`RAILWAY_ENVIRONMENT_NAME` environment-guard bug the script shared with `seed-staging.ts`) and ran it against a real delete flow using the actual `account-deletion.service.ts` functions. **Result: Cloudinary asset, Stream Chat user, and the Postgres row were all confirmed removed.** `animatch-6e` (who the task was originally assigned to) was notified to stand down — this closes the account-deletion feature's launch-readiness verification.

Still open: Claudio eyeballing the Railway deploy log for "Migrations complete" on the latest staging deploy, to independently confirm the exact commit that's live (neither agent session has Railway dashboard/CLI access) — lower priority now that the functional E2E result already passed on that deploy.

## Suggested sequencing

```
Week 1: Apple Developer enrollment (start now, longest lead time)
        Fill production.env.json with real Auth0/Stream Chat values
        Manual Android release-build device verification pass
        Backend alignment call/thread on data-safety facts
Week 1-2: Claudio finalizes privacy policy real values + legal review
        Screenshots + store listing copy (Play first)
Week 2: Play Console listing + internal testing submission
Week 2-3: iOS signing + CI pipeline (Codemagic/GH Actions) setup
        TestFlight internal build once CI is green
Week 3+: Play production rollout (staged %) once internal testing is clean
        App Store submission once TestFlight smoke test passes
```

Dates intentionally omitted — this depends on Apple enrollment turnaround and Claudio's availability for the privacy-policy sign-off, both outside engineering's control.
