# Lab 9 Notes — One Cart, Four Ways

## Part 1: Setup and Shared Code

1. **Why is `CartLine` immutable with a `copyWith` instead of a mutable `qty` field? Which of the four styles would still "work" with mutation, and why is that a trap?**
   - Immutability guarantees that every state transition produces a fresh object reference / value, so change detection (`==` checks in Riverpod, Cubit, and Bloc) reliably sees a new state and triggers UI updates, undo snapshots never get silently corrupted by later edits, and tests/observers see an accurate history of transitions.
   - `setState` would still "work" if you mutated `qty` in place (e.g., `line.qty++`) inside `setState(() { ... })`, because `setState` unconditionally marks the `Element` dirty and schedules a rebuild without comparing old and new state.
   - That is a trap because: (a) Riverpod, Cubit, and Bloc compare `previousState == newState` (and `List` uses identity equality by default), so mutating a line in place and reassigning/emitting the same list causes the state holder to think nothing changed and silently drop the update; (b) `Undo` history snapshots sharing references to the same mutable `CartLine` objects would all mutate together, breaking undo; and (c) pure helpers and widgets can no longer rely on referential/value stability.

2. **Why does `CartBody` take callbacks rather than importing a provider or a bloc directly?**
   - Keeping `CartBody` as a pure ("dumb") presentation widget decoupled from any state-management library lets all four pages (`setState`, Riverpod, Cubit, Bloc) share the exact same UI without duplication or conditional logic. It also makes the widget easier to preview, test in isolation, and reuse regardless of where state lives.


## Part 2: Baseline (`setState`)

- **T3 — Why is storing `total` a bug waiting to happen?**
  - `total` is completely derived from `lines` and `coupon`. Storing it as a separate field creates duplicate state that can drift out of sync whenever a line is added, removed, or edited, or when a coupon is applied or cleared—forgetting to recompute `total` in just one code path silently displays and submits the wrong price.

- **T4 — What happens without `if (!mounted) return;` after the `await`?**
  - If the user navigates back (`Navigator.pop`) while `CheckoutApi.submit` is still in flight, Flutter disposes the `State` object and unmounts it. When the `Future` resolves, calling `setState(...)` or `ScaffoldMessenger.of(context)` on an unmounted `State` throws a `FlutterError` (`setState() called after dispose()` / deactivated widget ancestor lookup error).

- **After T4, how would a second page (say an order history) read the cart? What would you have to change?**
  - A sibling or second page cannot read `_state` directly because it is private inside `_SetStateCartPageState` and destroyed when `SetStateCartPage` is popped. To share it with plain Flutter state, you would have to lift `_state` (and callbacks) up into a shared ancestor `StatefulWidget` above `Navigator` (or `InheritedWidget` / `ChangeNotifier` / global singleton) and pass it down to every route.

- **After T5, where does `_history` live, and what happens to it on hot restart versus hot reload?**
  - `_history` is a field on `_SetStateCartPageState`, which lives inside the `Element` tree in memory for as long as `SetStateCartPage` stays mounted.
  - On **hot reload**, Flutter preserves existing `State` instances and updates code in place, so `_history` (and `_state`) survives.
  - On **hot restart**, the entire Dart VM isolate and widget/element tree are destroyed and `main()` re-runs from scratch, so `_history` is wiped out.

## Part 3: Riverpod (`Notifier` and `NotifierProvider`)

- **T2 — Does `state = state.copyWith(coupon: code)` notify if `code` is unchanged (before vs after overriding `==` and `hashCode`)?**
  - Without overriding `==` and `hashCode` on `CartState`, Dart inherits reference equality from `Object`. Because `copyWith` allocates a brand-new `CartState` instance, `newState == oldState` evaluates to `false`, so Riverpod notifies listeners (`ref.listen` fires) even when every field is identical.
  - Once `==` and `hashCode` are overridden by value on `CartState` (and `CartLine`), assigning an unchanged `CartState` satisfies `newState == oldState`, so Riverpod skips notifying listeners (`ref.listen` does not print on the duplicate `SAVE10` apply).

- **T4 — Why is no widget `mounted` check needed in `CartNotifier.checkout()` / `RiverpodCartPage`?**
  - In T4, `cartProvider` is a non-`autoDispose` `NotifierProvider` whose state lives in the root `ProviderContainer` owned by `ProviderScope`, not in the popped page's `State` object. When the user pops `RiverpodCartPage`, Riverpod automatically cancels the widget's `ref.listen` subscription, while `CartNotifier` remains alive in `ProviderScope` to finish updating `state` safely without touching a deactivated `BuildContext`. (Once `cartProvider` is switched to `autoDispose` in T5, popping the page disposes the `Notifier`, so checking `if (!ref.mounted) return;` inside `checkout()` guards against `UnmountedRefException`.)

- **T5 — After making `cartProvider` `autoDispose`, what happens to `_history` when you pop the page and return, and why?**
  - `_history` is completely lost and starts empty again when returning to `RiverpodCartPage`. Because `autoDispose` tears down the `ProviderElement` and discards the `CartNotifier` instance as soon as the last listener (`RiverpodCartPage`) unmounts, reopening the page creates a fresh `CartNotifier` with an empty `_history` and runs `build()` again.

- **Name the three places you used `ref.read` and the two places you used `ref.watch`, and justify each.**
  - **`ref.read` (3 places):**
    1. `final cart = ref.read(cartProvider.notifier);` inside `RiverpodCartPage.build` to obtain a handle for passing method callbacks (`cart.add`, `cart.undo`, `cart.checkout`, etc.) to `CartBody` and the `AppBar` without subscribing to notifier rebuilds.
    2. `ref.read(checkoutApiProvider)` inside `CartNotifier.checkout()` to inject the `CheckoutApi` dependency on demand inside an async action rather than reacting to rebuilds.
    3. `ref.read(cartProvider).orderId` / `.checkoutError` inside `ref.listen` callbacks (and `ref.read(cartProvider.notifier).canUndo` inside `canUndoProvider` after `ref.watch(cartProvider)`) to inspect the current value during an event without adding redundant watch subscriptions inside callbacks.
  - **`ref.watch` (2 places):**
    1. `ref.watch(cartProvider)` / `ref.watch(canUndoProvider)` inside `RiverpodCartPage.build` (and `ref.watch(cartProvider)` inside `canUndoProvider`) so the page and undo button automatically rebuild whenever the cart state changes.
    2. `ref.watch(cartProvider.select((s) => (itemCount: s.itemCount, subtotal: s.subtotal, discount: s.discount, total: s.total)))` inside `_RiverpodSummaryCard.build` so the summary card subscribes only to derived summary numbers.

- **Why does the summary card in T3 rebuild less often than the `setState` version?**
  - In `setState`, any state update marks the whole page dirty and calls `build`, passing fresh props down to `CartBody` and `CartSummaryCard`. In Riverpod, `_RiverpodSummaryCard` is a `const ConsumerWidget` that uses `cartProvider.select(...)`; typing in the coupon `TextField`, triggering an invalid coupon error, or toggling `CheckoutStatus` (`submitting` / `failure`) does not change the selected summary values, so Riverpod does not schedule a rebuild of `_RiverpodSummaryCard`.

## Part 4: Cubit (`methods that emit`)

- **T4 — What does `emit` do after `close()` when you leave the page mid-checkout?**
  - Calling `emit(...)` after a `Cubit` / `Bloc` has been closed throws a `StateError` (`Cannot emit new states after calling close`). Checking `if (isClosed) return;` after `await _api.submit(...)` prevents emitting on a closed stream when the user pops `CubitCartPage` while checkout is still pending.

- **What would break if you put `BlocProvider` inside `CartBody`?**
  - Two things would break: (1) `CubitCartPage`'s `AppBar` Undo button and `BlocListener` live above `CartBody`, so `context.read<CartCubit>()` / `BlocSelector<CartCubit, ...>` in `AppBar` and `BlocListener` would throw `ProviderNotFoundException` because `BlocProvider` would only be visible to descendants below `CartBody`; and (2) `CartBody` is supposed to remain a stateless, state-management-agnostic UI shared by all four implementations, so tying it to `BlocProvider` would couple `setState`, Riverpod, and Bloc to `CartCubit`.

- **Give the Riverpod equivalent of each:**
  - `BlocProvider` -> `ProviderScope` (plus `NotifierProvider` / `Provider`, and `ProviderScope(overrides: ...)` for subtree scoping)
  - `BlocBuilder` -> `Consumer` / `ConsumerWidget` calling `ref.watch(provider)`
  - `BlocListener` -> `ref.listen(provider, (prev, next) { ... })`
  - `context.read` -> `ref.read`
  - `buildWhen` -> `provider.select((s) => ...)` inside `ref.watch`

## Part 5: Bloc (`events in, states out`)

- **T2 — Compare `BlocObserver.onTransition` with `CartCubit.onChange`: what extra information do you get?**
  - `Cubit.onChange` only shows `currentState -> nextState`; you know *what* changed, not *which user action* caused it.
  - `BlocObserver.onTransition` includes `transition.event` (`currentState -> event -> nextState`), giving a full audit trail of the exact named event (`CartProductAdded`, `CartCouponApplied`, `CartCheckoutRequested`, `CartUndone`) alongside the before/after states.

- **T4 — What happens when tapping Checkout three times quickly with `transformer: droppable()` on `CartBloc`, and what would have happened with `CartCubit`?**
  - With `transformer: droppable()`, `CartBloc` accepts the first `CartCheckoutRequested` event and drops the second and third events while the first handler's async `Future` is still running—so `CheckoutApi.submit` runs only once and only one `submitting` state is emitted.
  - In `CartCubit` (without a manual `if (state.status == CheckoutStatus.submitting) return;` guard), tapping Checkout three times launches three concurrent `checkout()` calls, calling `CheckoutApi.submit` three times and letting out-of-order responses overwrite state.

- **T5 — Which events are undoable?**
  - Defined via an exhaustive `switch` on the sealed `CartEvent` hierarchy (`CartEvent.isUndoable`):
    - **Undoable (`true`):** `CartProductAdded`, `CartProductRemoved`, `CartQtyChanged`, `CartCouponApplied` — these edit the user's cart items or coupon.
    - **Not undoable (`false`):** `CartCheckoutRequested` (async side effect / network submission status should not be pushed onto cart-edit history) and `CartUndone` (pops history rather than pushing to it).

- **When is the event layer worth its boilerplate? Give one feature in this cart where Bloc is clearly better than Cubit and one where it is pure overhead.**
  - The event layer pays off when you need event-stream concurrency control (`droppable()`, `restartable()`, `debounce()`), strict decoupling of UI intent from execution, or full event+transition audit logging/analytics.
  - **Clearly better in this cart:** T4's duplicate-tap checkout protection (`transformer: droppable()` on `CartCheckoutRequested`)—a single declarative line handles concurrency without manual boolean flags.
  - **Pure overhead in this cart:** T1's quantity stepper (`CartQtyChanged`)—wrapping `(productId, delta)` in an event class and registering a handler adds ~10 lines of boilerplate compared to calling `cubit.changeQty(id, delta)` directly.

- **Which of the four styles let you implement T4's "drop duplicate taps" declaratively, and how would you do it in the others?**
  - Only **Bloc** supports it declaratively via `transformer: droppable()` from `bloc_concurrency`.
  - In **setState**, **Riverpod**, and **Cubit**, you implement it imperatively with an early guard at the top of `checkout()`: `if (_state.status == CheckoutStatus.submitting) return;` (or `if (state.status == CheckoutStatus.submitting) return;` / disabling the button while submitting).

---

## Checkpoint Questions

1. **For each of the four styles, state in one line where the state lives and when it dies.**
   - **`setState`:** Lives on the `State` object in the widget/element tree and dies when `SetStateCartPage` is popped/unmounted.
   - **Riverpod (`autoDispose`):** Lives in the root `ProviderContainer` (`ProviderScope`), and with `autoDispose` dies as soon as its last listener (`RiverpodCartPage`) unmounts (without `autoDispose`, it lives as long as `ProviderScope`).
   - **Cubit:** Lives on the `CartCubit` instance owned by the subtree's `BlocProvider`, and dies when `BlocProvider` is removed from the tree and calls `close()`.
   - **Bloc:** Lives on the `CartBloc` instance owned by the subtree's `BlocProvider`, and dies when `BlocProvider` is removed from the tree and calls `close()`.

2. **What is the single public mutation API in Riverpod's `Notifier`, in `Cubit` and in `Bloc`? Which style has none?**
   - **Riverpod `Notifier`:** Setting the `state` property (`state = newState`, permitted only inside the `Notifier` via its methods).
   - **`Cubit`:** Calling `emit(newState)` (via public methods on the `Cubit`).
   - **`Bloc`:** Calling `bloc.add(event)` (the UI never calls `emit` or mutates state directly; only event handlers call `emit`).
   - **Style with none:** `setState` has no encapsulated mutation API or external state holder—any callback inside the `State` class can mutate fields directly and call `setState(() { ... })`.

3. **Map these to each other: `ref.watch` / `ref.read` / `ref.listen` versus `BlocBuilder` / `context.read` / `BlocListener`. Where does `setState` fit?**
   - `ref.watch` <-> `BlocBuilder` (and `provider.select(...)` <-> `BlocSelector` / `buildWhen`): subscribe the widget and rebuild UI when watched state changes.
   - `ref.read` <-> `context.read`: one-off lookup without subscribing, used inside callbacks (`onPressed`) and imperative actions.
   - `ref.listen` <-> `BlocListener`: run side effects (`SnackBar`, `MaterialBanner`, navigation) once per state change without rebuilding widgets.
   - **`setState`:** Does not separate `watch`, `read`, and `listen`—calling `setState` unconditionally re-runs `build` for the whole `State` subtree, methods/fields are accessed directly on `this` (`_add`, `_state`), and side effects run imperatively inside async/callback methods guarded by `if (!mounted) return;`.

4. **Why do Riverpod, Cubit and Bloc all skip notifying when the new state `==` the old one, and what two things must you do to `CartState` so that this behaves correctly?**
   - They skip equal emissions to avoid redundant widget rebuilds, duplicate stream events, and infinite listener loops when an action produces an identical state (e.g., applying `'SAVE10'` twice).
   - Two things you must do to `CartState`:
     1. Keep `CartState` (and nested `CartLine` / `List<CartLine>`) **immutable** so mutations always return new objects rather than mutating fields in place (which would compare `old == old` as `true` and swallow real updates).
     2. Override **`==` and `hashCode`** by value (comparing `lines` element-wise and all scalar/history fields, either by hand or with `Equatable`/`freezed`) so two distinct instances with identical field values compare equal.

5. **After the `await` in checkout, what guard did each style need (`mounted`, nothing, `isClosed`, `emit.isDone`) and why do they differ?**
   - **`setState` (`if (!mounted) return;`):** The `State` object is tied to the `BuildContext` / `Element`; popping the route unmounts it, so calling `setState` or `ScaffoldMessenger.of(context)` afterward throws.
   - **Riverpod (`nothing` when non-`autoDispose`; `if (!ref.mounted) return;` once `autoDispose` is enabled):** Non-`autoDispose` providers outlive the popped route in `ProviderScope`, and Riverpod auto-detaches widget `ref.listen` subscriptions; when `autoDispose` is enabled, popping disposes the `Ref`, so `ref.mounted` guards against `UnmountedRefException`.
   - **Cubit (`if (isClosed) return;`):** `BlocProvider` calls `cubit.close()` when the route pops, and `Cubit.emit` throws a `StateError` if called after `close()`.
   - **Bloc (`if (emit.isDone) return;`):** Even while `Bloc` is closing or an event handler has been superseded/canceled (e.g. by a transformer), `emit.isDone` tells that specific `on<E>` handler whether its `Emitter` is still active before calling `emit(...)`.

---

## Comparison Table

| Style | Lines of code (T1–T5) | Lines of test code | Number of files (impl / test) | One strength | One weakness |
| :--- | :---: | :---: | :---: | :--- | :--- |
| **`setState`** | 134 (`cart_page_setstate.dart`) | 23 (`setstate_cart_test.dart`) | 1 / 1 | Zero dependencies and minimal indirection—state, logic, and UI live in one file. | State dies on pop, cannot be shared across sibling routes without lifting, and widget tests must pump the full UI tree. |
| **Riverpod** | 197 (`cart_notifier.dart`: 89, `cart_page_riverpod.dart`: 108) | 49 (`riverpod_cart_test.dart`) | 2 / 1 | Dependency injection (`checkoutApiProvider`), granular `.select(...)` rebuilds, and widget-free `ProviderContainer` tests. | Provider lifecycle (`autoDispose` vs keep-alive) and `ref.mounted` / `container.listen` rules have subtle gotchas. |
| **Cubit** | 199 (`cart_cubit.dart`: 91, `cart_page_cubit.dart`: 108) | 58 (`cubit_cart_test.dart`) | 2 / 1 | Simple method-based API with stream equality deduplication, `BlocSelector`, and deterministic sequence testing via `blocTest`. | No built-in event objects or concurrency transformers (`droppable`) and requires folding UI flags like `canUndo` into state. |
| **Bloc** | 240 (`cart_event.dart`: 47, `cart_bloc.dart`: 109, `cart_page_bloc.dart`: 84; reuses `BlocSummaryCard`) | 81 (`bloc_cart_test.dart`) | 3 / 1 | Exhaustive sealed events, declarative `droppable()` concurrency control, and full `event -> transition` audit logging via `BlocObserver`. | Highest boilerplate (separate event classes and handlers even for trivial mutations like `CartQtyChanged`). |
