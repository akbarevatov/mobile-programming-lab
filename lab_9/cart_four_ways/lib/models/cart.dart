class Product {
  const Product({required this.id, required this.name, required this.price});

  final String id;
  final String name;
  final double price;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Product &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          price == other.price;

  @override
  int get hashCode => Object.hash(id, name, price);
}

const catalog = [
  Product(id: 'p1', name: 'Keyboard', price: 49),
  Product(id: 'p2', name: 'Mouse', price: 25),
  Product(id: 'p3', name: 'Monitor', price: 199),
];

class CartLine {
  const CartLine({required this.product, required this.qty});

  final Product product;
  final int qty;

  double get subtotal => product.price * qty;

  CartLine copyWith({int? qty}) =>
      CartLine(product: product, qty: qty ?? this.qty);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartLine &&
          runtimeType == other.runtimeType &&
          product == other.product &&
          qty == other.qty;

  @override
  int get hashCode => Object.hash(product, qty);
}

/// Pure, style-independent cart logic. Every state holder calls these.
extension CartLines on List<CartLine> {
  List<CartLine> withProduct(Product p) {
    final i = indexWhere((l) => l.product.id == p.id);
    if (i == -1) return [...this, CartLine(product: p, qty: 1)];
    return [
      for (final l in this)
        l.product.id == p.id ? l.copyWith(qty: l.qty + 1) : l,
    ];
  }

  List<CartLine> without(String productId) =>
      [for (final l in this) if (l.product.id != productId) l];

  List<CartLine> changeQty(String productId, int delta) {
    final result = <CartLine>[];
    for (final l in this) {
      if (l.product.id != productId) {
        result.add(l);
      } else {
        final nextQty = l.qty + delta;
        if (nextQty > 0) {
          result.add(l.copyWith(qty: nextQty));
        }
      }
    }
    return result;
  }

  double get subtotal => fold(0, (s, l) => s + l.subtotal);
  int get itemCount => fold(0, (s, l) => s + l.qty);
}

enum CheckoutStatus { idle, submitting, success, failure }

const _unset = Object();

class CartState {
  const CartState({
    this.lines = const [],
    this.coupon,
    this.couponError,
    this.status = CheckoutStatus.idle,
    this.orderId,
    this.checkoutError,
    this.history = const [],
  });

  static const validCoupon = 'SAVE10';

  final List<CartLine> lines;
  final String? coupon;
  final String? couponError;
  final CheckoutStatus status;
  final String? orderId;
  final String? checkoutError;
  final List<CartState> history;

  int get itemCount => lines.itemCount;
  double get subtotal => lines.subtotal;
  double get discount => coupon == validCoupon ? subtotal * 0.10 : 0.0;
  double get total => subtotal - discount;
  bool get canUndo => history.isNotEmpty;

  CartState copyWith({
    List<CartLine>? lines,
    Object? coupon = _unset,
    Object? couponError = _unset,
    CheckoutStatus? status,
    Object? orderId = _unset,
    Object? checkoutError = _unset,
    List<CartState>? history,
  }) {
    return CartState(
      lines: lines ?? this.lines,
      coupon: identical(coupon, _unset) ? this.coupon : coupon as String?,
      couponError: identical(couponError, _unset)
          ? this.couponError
          : couponError as String?,
      status: status ?? this.status,
      orderId: identical(orderId, _unset) ? this.orderId : orderId as String?,
      checkoutError: identical(checkoutError, _unset)
          ? this.checkoutError
          : checkoutError as String?,
      history: history ?? this.history,
    );
  }

  CartState asHistorySnapshot() => copyWith(
        status: CheckoutStatus.idle,
        orderId: null,
        checkoutError: null,
      );

  CartState withAppliedCoupon(String rawCode) {
    final code = rawCode.trim();
    if (code == validCoupon) {
      return copyWith(
        coupon: validCoupon,
        couponError: null,
        status: CheckoutStatus.idle,
        orderId: null,
        checkoutError: null,
      );
    }
    return copyWith(
      coupon: null,
      couponError: 'Invalid coupon code',
      status: CheckoutStatus.idle,
      orderId: null,
      checkoutError: null,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartState &&
          runtimeType == other.runtimeType &&
          _listEquals(lines, other.lines) &&
          coupon == other.coupon &&
          couponError == other.couponError &&
          status == other.status &&
          orderId == other.orderId &&
          checkoutError == other.checkoutError &&
          _listEquals(history, other.history);

  @override
  int get hashCode => Object.hash(
        Object.hashAll(lines),
        coupon,
        couponError,
        status,
        orderId,
        checkoutError,
        Object.hashAll(history),
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
