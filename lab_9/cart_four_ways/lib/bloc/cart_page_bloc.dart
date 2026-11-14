import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/cart_page_cubit.dart';
import '../models/cart.dart';
import '../services/checkout_api.dart';
import '../widgets/cart_body.dart';
import 'cart_bloc.dart';
import 'cart_event.dart';

class BlocCartPage extends StatelessWidget {
  const BlocCartPage({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
        create: (_) => CartBloc(CheckoutApi()),
        child: BlocListener<CartBloc, CartState>(
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
              title: const Text('Cart · Bloc'),
              actions: [
                BlocSelector<CartBloc, CartState, bool>(
                  selector: (s) => s.canUndo,
                  builder: (context, canUndo) => IconButton(
                    icon: const Icon(Icons.undo),
                    tooltip: 'Undo',
                    onPressed: canUndo
                        ? () => context.read<CartBloc>().add(const CartUndone())
                        : null,
                  ),
                ),
              ],
            ),
            body: BlocBuilder<CartBloc, CartState>(
              builder: (context, state) {
                final bloc = context.read<CartBloc>();
                return CartBody(
                  lines: state.lines,
                  onAdd: (p) => bloc.add(CartProductAdded(p)),
                  onRemove: (id) => bloc.add(CartProductRemoved(id)),
                  onQtyChanged: (id, delta) =>
                      bloc.add(CartQtyChanged(id, delta)),
                  coupon: state.coupon,
                  couponError: state.couponError,
                  onApplyCoupon: (code) => bloc.add(CartCouponApplied(code)),
                  isSubmitting: state.status == CheckoutStatus.submitting,
                  onCheckout: () => bloc.add(const CartCheckoutRequested()),
                  summary: const BlocSummaryCard<CartBloc>(),
                );
              },
            ),
          ),
        ),
      );
}
