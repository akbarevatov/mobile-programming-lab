import 'package:flutter/material.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';

class SetStateCartPage extends StatefulWidget {
  const SetStateCartPage({super.key, this.api});

  final CheckoutApi? api;

  @override
  State<SetStateCartPage> createState() => _SetStateCartPageState();
}

class _SetStateCartPageState extends State<SetStateCartPage> {
  late final CheckoutApi _api = widget.api ?? CheckoutApi();
  CartState _state = const CartState();
  final List<CartState> _history = [];

  void _mutate(CartState Function(CartState current) transform) {
    final next = transform(_state);
    if (next == _state) return;
    _history.add(_state.asHistorySnapshot());
    setState(() => _state = next);
  }

  void _add(Product p) => _mutate(
        (s) => s.copyWith(
          lines: s.lines.withProduct(p),
          status: CheckoutStatus.idle,
          orderId: null,
          checkoutError: null,
        ),
      );

  void _remove(String id) => _mutate(
        (s) => s.copyWith(
          lines: s.lines.without(id),
          status: CheckoutStatus.idle,
          orderId: null,
          checkoutError: null,
        ),
      );

  void _changeQty(String id, int delta) => _mutate(
        (s) => s.copyWith(
          lines: s.lines.changeQty(id, delta),
          status: CheckoutStatus.idle,
          orderId: null,
          checkoutError: null,
        ),
      );

  void _applyCoupon(String code) => _mutate((s) => s.withAppliedCoupon(code));

  void _undo() {
    if (_history.isEmpty) return;
    setState(() => _state = _history.removeLast());
  }

  Future<void> _checkout() async {
    setState(
      () => _state = _state.copyWith(
        status: CheckoutStatus.submitting,
        orderId: null,
        checkoutError: null,
      ),
    );
    try {
      final orderId = await _api.submit(_state.total);
      if (!mounted) return;
      _history.clear();
      setState(
        () => _state = CartState(
          status: CheckoutStatus.success,
          orderId: orderId,
        ),
      );
      ScaffoldMessenger.of(context)
        ..hideCurrentMaterialBanner()
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Order placed: $orderId')));
    } on CheckoutException catch (e) {
      if (!mounted) return;
      setState(
        () => _state = _state.copyWith(
          status: CheckoutStatus.failure,
          checkoutError: e.message,
        ),
      );
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentMaterialBanner()
        ..hideCurrentSnackBar()
        ..showMaterialBanner(
          MaterialBanner(
            content: Text('Checkout failed: ${e.message}'),
            actions: [
              TextButton(
                onPressed: messenger.hideCurrentMaterialBanner,
                child: const Text('Dismiss'),
              ),
            ],
          ),
        );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          title: const Text('Cart · setState'),
          actions: [
            IconButton(
              icon: const Icon(Icons.undo),
              tooltip: 'Undo',
              onPressed: _history.isEmpty ? null : _undo,
            ),
          ],
        ),
        body: CartBody(
          lines: _state.lines,
          onAdd: _add,
          onRemove: _remove,
          onQtyChanged: _changeQty,
          coupon: _state.coupon,
          couponError: _state.couponError,
          onApplyCoupon: _applyCoupon,
          isSubmitting: _state.status == CheckoutStatus.submitting,
          onCheckout: _checkout,
        ),
      );
}
