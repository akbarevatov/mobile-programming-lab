import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/cart.dart';
import '../widgets/cart_body.dart';
import 'cart_notifier.dart';

class RiverpodCartPage extends ConsumerWidget {
  const RiverpodCartPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<CartState>(cartProvider, (prev, next) {
      debugPrint(
        '[Riverpod] state changed: items=${next.itemCount}, '
        'coupon=${next.coupon}, status=${next.status}',
      );
    });

    ref.listen<CheckoutStatus>(
      cartProvider.select((s) => s.status),
      (prev, next) {
        if (prev == next) return;
        final messenger = ScaffoldMessenger.of(context);
        if (next == CheckoutStatus.success) {
          final orderId = ref.read(cartProvider).orderId;
          messenger
            ..hideCurrentMaterialBanner()
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text('Order placed: $orderId')));
        } else if (next == CheckoutStatus.failure) {
          final error =
              ref.read(cartProvider).checkoutError ?? 'Checkout failed';
          messenger
            ..hideCurrentMaterialBanner()
            ..hideCurrentSnackBar()
            ..showMaterialBanner(
              MaterialBanner(
                content: Text('Checkout failed: $error'),
                actions: [
                  TextButton(
                    onPressed: messenger.hideCurrentMaterialBanner,
                    child: const Text('Dismiss'),
                  ),
                ],
              ),
            );
        }
      },
    );

    final state = ref.watch(cartProvider);
    final canUndo = ref.watch(canUndoProvider);
    final cart = ref.read(cartProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart · Riverpod'),
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Undo',
            onPressed: canUndo ? cart.undo : null,
          ),
        ],
      ),
      body: CartBody(
        lines: state.lines,
        onAdd: cart.add,
        onRemove: cart.remove,
        onQtyChanged: cart.changeQty,
        coupon: state.coupon,
        couponError: state.couponError,
        onApplyCoupon: cart.applyCoupon,
        isSubmitting: state.status == CheckoutStatus.submitting,
        onCheckout: cart.checkout,
        summary: const _RiverpodSummaryCard(),
      ),
    );
  }
}

class _RiverpodSummaryCard extends ConsumerWidget {
  const _RiverpodSummaryCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(
      cartProvider.select(
        (s) => (
          itemCount: s.itemCount,
          subtotal: s.subtotal,
          discount: s.discount,
          total: s.total,
        ),
      ),
    );
    debugPrint(
      '[RiverpodSummaryCard] build total=${summary.total.toStringAsFixed(2)}',
    );
    return CartSummaryCard(
      itemCount: summary.itemCount,
      subtotal: summary.subtotal,
      discount: summary.discount,
      total: summary.total,
    );
  }
}
