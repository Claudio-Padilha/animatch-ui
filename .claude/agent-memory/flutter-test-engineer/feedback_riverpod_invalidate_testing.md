---
name: feedback-riverpod-invalidate-testing
description: Riverpod 3.x idiomatic way to assert ref.invalidate(provider) side effects fired in a plain ProviderContainer test — don't hand-roll a delay
metadata:
  type: feedback
---

Don't use `Future<void>.delayed(Duration.zero)` (a hand-rolled "settle" helper) to wait for a
fire-and-forget `ref.invalidate(someProvider)` to take effect in a `ProviderContainer`-based test.
It happens to work today but reimplements an internal scheduler timing detail rather than using a
public API.

**Why:** Verified against `flutter_riverpod: ^3.0.0` (resolves to riverpod 3.1.0,
`~/.pub-cache/hosted/pub.dev/riverpod-3.1.0/lib/src/core/`):
- `Ref.invalidate`/`invalidateSelf` (`element.dart:738`) does NOT rebuild synchronously — it sets
  `_mustRecomputeState = true` and calls `container.scheduler.scheduleProviderRefresh(this)`.
- The default scheduler vsync (`scheduler.dart:23-27`, used whenever there's no Flutter widget
  tree attached, i.e. every plain `ProviderContainer()` test) is `Timer(Duration.zero, task.call)`
  — a macrotask, not a microtask.
- `Future<void>.delayed(Duration.zero)` also compiles to a zero-duration `Timer`. It "works" only
  because Dart's event loop fires equal-delay timers in FIFO registration order, so a `_settle()`
  helper called *after* the invalidate happens to run after the scheduler's own timer. This is an
  undocumented ordering coincidence, not a contract — a future Riverpod scheduler change, or a
  second chained invalidation needing two ticks, could silently reintroduce flakiness.

**How to apply — two real fixes, either is fine, no delay hack needed:**
1. `await container.pump();` — `ProviderContainer.pump()` (`provider_container.dart:895`, fully
   public, not `@internal`) is *built for exactly this*: "Awaits for providers to rebuild/be
   disposed and for listeners to be notified." Recursive up the container tree too.
2. Or just re-read the invalidated provider's `.future` (e.g.
   `await container.read(breederStatisticsProvider.future);`) right after the action that
   triggered the invalidate. `container.read(...)` → `readSafe()` → `element.flush()`
   (`provider_subscription.dart:80`, `element.dart:463/650`) forces an *immediate synchronous*
   rebuild-if-dirty, bypassing the scheduler timer entirely — no waiting at all, and it matches
   the `await container.read(x.future)` idiom these test files already use elsewhere for
   awaiting initial builds.

Found while reviewing `test/herd/herd_provider_test.dart`'s `_settle()` helper (used for
`AddAnimalNotifier`/`ToggleAnimalNotifier`/`DeleteAnimalNotifier` tests asserting
`breederStatisticsProvider` invalidation side effects, 2026-08-16). This exact
invalidate-on-success pattern recurs across `docs/testing-plan.md` §6 (`suggestionsProvider`
cache invalidation), §7 (`CancelMatchNotifier`/`DeleteMatchNotifier` invalidate
`matchesProvider`), and §8 (profile activate/updateProfile syncing `authNotifierProvider`) — fix
the idiom before it gets copy-pasted into those files too.
