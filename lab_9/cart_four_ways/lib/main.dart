import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'bloc/cart_page_bloc.dart';
import 'cubit/cart_page_cubit.dart';
import 'models/cart.dart';
import 'riverpod/cart_page_riverpod.dart';
import 'setstate/cart_page_setstate.dart';

class AppBlocObserver extends BlocObserver {
  const AppBlocObserver();

  @override
  void onTransition(
    Bloc<dynamic, dynamic> bloc,
    Transition<dynamic, dynamic> transition,
  ) {
    super.onTransition(bloc, transition);
    final current = transition.currentState;
    final next = transition.nextState;
    if (current is CartState && next is CartState) {
      debugPrint(
        '[BlocObserver] ${bloc.runtimeType} on ${transition.event.runtimeType}: '
        '${current.coupon}/${current.total.toStringAsFixed(2)} (${current.status.name}) '
        '-> ${next.coupon}/${next.total.toStringAsFixed(2)} (${next.status.name})',
      );
    } else {
      debugPrint('[BlocObserver] ${bloc.runtimeType}: $transition');
    }
  }
}

void main() {
  Bloc.observer = const AppBlocObserver();
  runApp(const ProviderScope(child: CartFourWaysApp()));
}

class CartFourWaysApp extends StatelessWidget {
  const CartFourWaysApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Cart Four Ways',
      theme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final destinations = <(String, WidgetBuilder)>[
      ('1. setState', (_) => const SetStateCartPage()),
      ('2. Riverpod', (_) => const RiverpodCartPage()),
      ('3. Cubit', (_) => const CubitCartPage()),
      ('4. Bloc', (_) => const BlocCartPage()),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('One Cart, Four Ways')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 320),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (label, builder) in destinations) ...[
                FilledButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(builder: builder),
                  ),
                  child: Text(label),
                ),
                const SizedBox(height: 12),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
