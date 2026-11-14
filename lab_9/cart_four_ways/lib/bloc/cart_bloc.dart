import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import 'cart_event.dart';

class CartBloc extends Bloc<CartEvent, CartState> {
  CartBloc(this._api) : super(const CartState()) {
    on<CartProductAdded>(
      (event, emit) => _mutate(
        event,
        emit,
        (s) => s.copyWith(
          lines: s.lines.withProduct(event.product),
          status: CheckoutStatus.idle,
          orderId: null,
          checkoutError: null,
        ),
      ),
    );
    on<CartProductRemoved>(
      (event, emit) => _mutate(
        event,
        emit,
        (s) => s.copyWith(
          lines: s.lines.without(event.productId),
          status: CheckoutStatus.idle,
          orderId: null,
          checkoutError: null,
        ),
      ),
    );
    on<CartQtyChanged>(
      (event, emit) => _mutate(
        event,
        emit,
        (s) => s.copyWith(
          lines: s.lines.changeQty(event.productId, event.delta),
          status: CheckoutStatus.idle,
          orderId: null,
          checkoutError: null,
        ),
      ),
    );
    on<CartCouponApplied>(
      (event, emit) => _mutate(
        event,
        emit,
        (s) => s.withAppliedCoupon(event.code),
      ),
    );
    on<CartCheckoutRequested>(
      _onCheckoutRequested,
      transformer: droppable(),
    );
    on<CartUndone>(_onUndone);
  }

  final CheckoutApi _api;

  void _mutate(
    CartEvent event,
    Emitter<CartState> emit,
    CartState Function(CartState current) transform,
  ) {
    final next = transform(state);
    if (next == state) {
      emit(state);
      return;
    }
    emit(
      event.isUndoable
          ? next.copyWith(history: [...state.history, state.asHistorySnapshot()])
          : next,
    );
  }

  Future<void> _onCheckoutRequested(
    CartCheckoutRequested event,
    Emitter<CartState> emit,
  ) async {
    emit(
      state.copyWith(
        status: CheckoutStatus.submitting,
        orderId: null,
        checkoutError: null,
      ),
    );
    try {
      final orderId = await _api.submit(state.total);
      if (emit.isDone) return;
      emit(CartState(status: CheckoutStatus.success, orderId: orderId));
    } on CheckoutException catch (e) {
      if (emit.isDone) return;
      emit(
        state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: e.message,
        ),
      );
    }
  }

  void _onUndone(CartUndone event, Emitter<CartState> emit) {
    if (state.history.isEmpty) return;
    emit(state.history.last);
  }
}

