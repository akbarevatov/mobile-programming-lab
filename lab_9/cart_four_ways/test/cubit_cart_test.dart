import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cart_four_ways/cubit/cart_cubit.dart';
import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class _MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  final keyboard = catalog.first;
  const s0 = CartState();
  final s1 = s0.copyWith(lines: s0.lines.withProduct(keyboard), history: [s0]);
  final s2 = s1.copyWith(lines: s1.lines.withProduct(keyboard), history: [s0, s1]);
  final s3 = s2.withAppliedCoupon('SAVE10').copyWith(history: [s0, s1, s2]);

  late _MockCheckoutApi mockApi;

  setUp(() {
    mockApi = _MockCheckoutApi();
  });

  blocTest<CartCubit, CartState>(
    'adding Keyboard twice and applying SAVE10 emits 3 states ending at 88.20',
    build: () => CartCubit(mockApi),
    act: (c) {
      c.add(keyboard);
      c.add(keyboard);
      c.applyCoupon('SAVE10');
    },
    expect: () => [s1, s2, s3],
    verify: (c) {
      expect(c.state.total, 88.2);
    },
  );

  blocTest<CartCubit, CartState>(
    'failed checkout emits submitting followed by failure and keeps lines',
    setUp: () {
      when(() => mockApi.submit(any()))
          .thenThrow(const CheckoutException('Card declined'));
    },
    build: () => CartCubit(mockApi),
    act: (c) async {
      c.add(keyboard);
      await c.checkout();
    },
    expect: () => [
      s1,
      s1.copyWith(status: CheckoutStatus.submitting),
      s1.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: 'Card declined',
      ),
    ],
  );
}

