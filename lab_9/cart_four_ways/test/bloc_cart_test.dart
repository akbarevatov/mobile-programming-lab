import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cart_four_ways/bloc/cart_bloc.dart';
import 'package:cart_four_ways/bloc/cart_event.dart';
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

  blocTest<CartBloc, CartState>(
    'adding Keyboard twice and applying SAVE10 emits 3 states ending at 88.20',
    build: () => CartBloc(mockApi),
    act: (b) => b
      ..add(CartProductAdded(keyboard))
      ..add(CartProductAdded(keyboard))
      ..add(const CartCouponApplied('SAVE10')),
    expect: () => [s1, s2, s3],
    verify: (b) {
      expect(b.state.total, 88.2);
    },
  );

  blocTest<CartBloc, CartState>(
    'failed checkout emits submitting followed by failure and keeps lines',
    setUp: () {
      when(() => mockApi.submit(any()))
          .thenThrow(const CheckoutException('Card declined'));
    },
    build: () => CartBloc(mockApi),
    act: (b) => b
      ..add(CartProductAdded(keyboard))
      ..add(const CartCheckoutRequested()),
    expect: () => [
      s1,
      s1.copyWith(status: CheckoutStatus.submitting),
      s1.copyWith(
        status: CheckoutStatus.failure,
        checkoutError: 'Card declined',
      ),
    ],
  );

  blocTest<CartBloc, CartState>(
    'droppable drops duplicate CartCheckoutRequested so only one submitting state emits',
    setUp: () {
      when(() => mockApi.submit(any())).thenAnswer((_) async {
        await Future<void>.delayed(const Duration(milliseconds: 50));
        return 'ORD-42';
      });
    },
    build: () => CartBloc(mockApi),
    act: (b) => b
      ..add(CartProductAdded(keyboard))
      ..add(const CartCheckoutRequested())
      ..add(const CartCheckoutRequested()),
    wait: const Duration(milliseconds: 100),
    expect: () => [
      s1,
      s1.copyWith(status: CheckoutStatus.submitting),
      const CartState(status: CheckoutStatus.success, orderId: 'ORD-42'),
    ],
    verify: (_) {
      verify(() => mockApi.submit(49)).called(1);
    },
  );
}

