import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import 'cart_cubit.dart';

class BlocSummaryCard<B extends StateStreamable<CartState>>
    extends StatelessWidget {
  const BlocSummaryCard({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocSelector<B, CartState,
        ({int itemCount, double subtotal, double discount, double total})>(
      selector: (s) => (
        itemCount: s.itemCount,
        subtotal: s.subtotal,
        discount: s.discount,
        total: s.total,
      ),
      builder: (context, summary) {
        debugPrint(
          '[BlocSummaryCard<$B>] build total=${summary.total.toStringAsFixed(2)}',
        );
        return CartSummaryCard(
          itemCount: summary.itemCount,
          subtotal: summary.subtotal,
          discount: summary.discount,
          total: summary.total,
        );
      },
    );
  }
}

class CubitCartPage extends StatelessWidget {
  const CubitCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartCubit(CheckoutApi()),
        child: BlocListener<CartCubit, CartState>(
          listenWhen: (p, c) => p.status != c.status,
          listener: (context, state) {
            final messenger = ScaffoldMessenger.of(context);
            if (state.status == CheckoutStatus.success) {
              messenger
                ..hideCurrentMaterialBanner()
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(content: Text('Order placed: ${state.orderId}')),
                );
            } else if (state.status == CheckoutStatus.failure) {
              messenger
                ..hideCurrentMaterialBanner()
                ..hideCurrentSnackBar()
                ..showMaterialBanner(
                  MaterialBanner(
                    content: Text(
                      'Checkout failed: ${state.checkoutError ?? 'Checkout failed'}',
                    ),
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
          child: Scaffold(
            appBar: AppBar(
              title: const Text('Cart · Cubit'),
              actions: [
                BlocSelector<CartCubit, CartState, bool>(
                  selector: (s) => s.canUndo,
                  builder: (context, canUndo) => IconButton(
                    icon: const Icon(Icons.undo),
                    tooltip: 'Undo',
                    onPressed: canUndo ? context.read<CartCubit>().undo : null,
                  ),
                ),
              ],
            ),
            body: BlocBuilder<CartCubit, CartState>(
              builder: (context, state) {
                final cubit = context.read<CartCubit>();
                return CartBody(
                  lines: state.lines,
                  onAdd: cubit.add,
                  onRemove: cubit.remove,
                  onQtyChanged: cubit.changeQty,
                  coupon: state.coupon,
                  couponError: state.couponError,
                  onApplyCoupon: cubit.applyCoupon,
                  isSubmitting: state.status == CheckoutStatus.submitting,
                  onCheckout: cubit.checkout,
                  summary: const BlocSummaryCard<CartCubit>(),
                );
              },
            ),
          ),
        ),
      );
}
