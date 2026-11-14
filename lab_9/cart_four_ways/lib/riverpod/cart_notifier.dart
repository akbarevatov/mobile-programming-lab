import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

final checkoutApiProvider = Provider<CheckoutApi>((ref) => CheckoutApi());

class CartNotifier extends Notifier<CartState> {
  final _history = <CartState>[];

  bool get canUndo => _history.isNotEmpty;

  @override
  CartState build() => const CartState();

  void _mutate(CartState Function(CartState current) transform) {
    final next = transform(state);
    if (next == state) return;
    _history.add(state.asHistorySnapshot());
    state = next;
  }

  void add(Product p) => _mutate(
        (s) => s.copyWith(
          lines: s.lines.withProduct(p),
          status: CheckoutStatus.idle,
          orderId: null,
          checkoutError: null,
        ),
      );

  void remove(String id) => _mutate(
        (s) => s.copyWith(
          lines: s.lines.without(id),
          status: CheckoutStatus.idle,
          orderId: null,
          checkoutError: null,
        ),
      );

  void changeQty(String id, int delta) => _mutate(
        (s) => s.copyWith(
          lines: s.lines.changeQty(id, delta),
          status: CheckoutStatus.idle,
          orderId: null,
          checkoutError: null,
        ),
      );

  void applyCoupon(String code) => _mutate((s) => s.withAppliedCoupon(code));

  void undo() {
    if (_history.isEmpty) return;
    state = _history.removeLast();
  }

  Future<void> checkout() async {
    state = state.copyWith(
      status: CheckoutStatus.submitting,
      orderId: null,
      checkoutError: null,
    );
    final api = ref.read(checkoutApiProvider);
    try {
      final orderId = await api.submit(state.total);
      if (!ref.mounted) return;
      _history.clear();
      state = CartState(
        status: CheckoutStatus.success,
        orderId: orderId,
      );
    } on CheckoutException catch (e) {
      if (!ref.mounted) return;
      state = state.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: e.message,
      );
    }
  }
}

final cartProvider = NotifierProvider.autoDispose<CartNotifier, CartState>(
  CartNotifier.new,
);

final canUndoProvider = Provider.autoDispose<bool>((ref) {
  ref.watch(cartProvider);
  return ref.read(cartProvider.notifier).canUndo;
});

