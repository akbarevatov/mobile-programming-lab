import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';

class CartCubit extends Cubit<CartState> {
  CartCubit(this._api) : super(const CartState());

  final CheckoutApi _api;

  void _mutate(CartState Function(CartState current) transform) {
    final next = transform(state);
    if (next == state) {
      // Calling emit(state) demonstrates BlocBase's equality deduplication.
      emit(state);
      return;
    }
    emit(
      next.copyWith(history: [...state.history, state.asHistorySnapshot()]),
    );
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
    if (state.history.isEmpty) return;
    emit(state.history.last);
  }

  Future<void> checkout() async {
    emit(
      state.copyWith(
        status: CheckoutStatus.submitting,
        orderId: null,
        checkoutError: null,
      ),
    );
    try {
      final orderId = await _api.submit(state.total);
      if (isClosed) return;
      emit(CartState(status: CheckoutStatus.success, orderId: orderId));
    } on CheckoutException catch (e) {
      if (isClosed) return;
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: e.message,
        ),
      );
    }
  }

  @override
  void onChange(Change<CartState> change) {
    super.onChange(change);
    debugPrint(
      '[CartCubit] onChange: '
      '${change.currentState.coupon}/${change.currentState.total.toStringAsFixed(2)} '
      '-> ${change.nextState.coupon}/${change.nextState.total.toStringAsFixed(2)} '
      '(${change.nextState.status.name})',
    );
  }
}

