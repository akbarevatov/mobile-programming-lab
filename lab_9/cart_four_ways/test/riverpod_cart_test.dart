import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:cart_four_ways/models/cart.dart';
import 'package:cart_four_ways/riverpod/cart_notifier.dart';
import 'package:cart_four_ways/services/checkout_api.dart';

class _MockCheckoutApi extends Mock implements CheckoutApi {}

void main() {
  test('adding Keyboard twice and applying SAVE10 yields 88.2 total', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final keyboard = catalog.first;
    final notifier = container.read(cartProvider.notifier);
    notifier.add(keyboard);
    notifier.add(keyboard);
    notifier.applyCoupon('SAVE10');

    expect(container.read(cartProvider).total, 88.2);
  });

  test('failed checkout sets status to failure and preserves lines', () async {
    final mockApi = _MockCheckoutApi();
    when(() => mockApi.submit(any()))
        .thenThrow(const CheckoutException('Card declined'));

    final container = ProviderContainer(
      overrides: [checkoutApiProvider.overrideWithValue(mockApi)],
    );
    addTearDown(container.dispose);

    // Keep the autoDispose provider alive across the async checkout gap.
    container.listen(cartProvider, (_, _) {});

    final keyboard = catalog.first;
    final notifier = container.read(cartProvider.notifier);
    notifier.add(keyboard);

    await notifier.checkout();

    final state = container.read(cartProvider);
    expect(state.status, CheckoutStatus.failure);
    expect(state.checkoutError, 'Card declined');
    expect(state.lines, [CartLine(product: keyboard, qty: 1)]);
  });
}

