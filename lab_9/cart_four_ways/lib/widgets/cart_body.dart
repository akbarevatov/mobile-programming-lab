import 'package:flutter/material.dart';
import '../models/cart.dart';

class CartSummaryCard extends StatelessWidget {
  const CartSummaryCard({
    super.key,
    required this.itemCount,
    required this.subtotal,
    required this.discount,
    required this.total,
  });

  final int itemCount;
  final double subtotal;
  final double discount;
  final double total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            _SummaryRow(label: 'Items', value: '$itemCount'),
            _SummaryRow(label: 'Subtotal', value: subtotal.toStringAsFixed(2)),
            _SummaryRow(
              label: 'Discount',
              value: '-${discount.toStringAsFixed(2)}',
            ),
            const Divider(height: 16),
            _SummaryRow(
              label: 'Total',
              value: total.toStringAsFixed(2),
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.value,
    this.style,
  });

  final String label;
  final String value;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: style),
            Text(value, style: style),
          ],
        ),
      );
}

class CartBody extends StatefulWidget {
  const CartBody({
    super.key,
    required this.lines,
    required this.onAdd,
    required this.onQtyChanged,
    required this.onApplyCoupon,
    required this.onCheckout,
    this.onRemove,
    this.coupon,
    this.couponError,
    this.isSubmitting = false,
    this.summary,
  });

  final List<CartLine> lines;
  final void Function(Product) onAdd;
  final void Function(String productId, int delta) onQtyChanged;
  final void Function(String productId)? onRemove;
  final String? coupon;
  final String? couponError;
  final void Function(String code) onApplyCoupon;
  final bool isSubmitting;
  final VoidCallback onCheckout;
  final Widget? summary;

  @override
  State<CartBody> createState() => _CartBodyState();
}

class _CartBodyState extends State<CartBody> {
  final _couponController = TextEditingController();

  @override
  void dispose() {
    _couponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final fallbackSubtotal = widget.lines.subtotal;
    final fallbackDiscount =
        widget.coupon == CartState.validCoupon ? fallbackSubtotal * 0.10 : 0.0;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Wrap(
            spacing: 8,
            children: [
              for (final p in catalog)
                ActionChip(
                  label: Text('${p.name} · ${p.price.toStringAsFixed(0)}'),
                  onPressed: () => widget.onAdd(p),
                ),
            ],
          ),
        ),
        Expanded(
          child: widget.lines.isEmpty
              ? const Center(child: Text('Cart is empty'))
              : ListView(
                  children: [
                    for (final l in widget.lines)
                      ListTile(
                        key: ValueKey(l.product.id),
                        title: Text(l.product.name),
                        subtitle: Text(
                          '${l.product.price.toStringAsFixed(0)} × ${l.qty} = ${l.subtotal.toStringAsFixed(2)}',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove),
                              tooltip: 'Decrease ${l.product.name}',
                              onPressed: () =>
                                  widget.onQtyChanged(l.product.id, -1),
                            ),
                            Text('${l.qty}'),
                            IconButton(
                              icon: const Icon(Icons.add),
                              tooltip: 'Increase ${l.product.name}',
                              onPressed: () =>
                                  widget.onQtyChanged(l.product.id, 1),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextField(
                  controller: _couponController,
                  decoration: InputDecoration(
                    labelText: 'Coupon code',
                    hintText: 'SAVE10',
                    errorText: widget.couponError,
                    helperText: widget.coupon != null
                        ? 'Applied: ${widget.coupon} (10% off)'
                        : null,
                    border: const OutlineInputBorder(),
                    isDense: true,
                  ),
                  onSubmitted: widget.onApplyCoupon,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: FilledButton.tonal(
                  onPressed: () =>
                      widget.onApplyCoupon(_couponController.text),
                  child: const Text('Apply'),
                ),
              ),
            ],
          ),
        ),
        widget.summary ??
            CartSummaryCard(
              itemCount: widget.lines.itemCount,
              subtotal: fallbackSubtotal,
              discount: fallbackDiscount,
              total: fallbackSubtotal - fallbackDiscount,
            ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: widget.lines.isEmpty ? null : widget.onCheckout,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (widget.isSubmitting) ...[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Text(widget.isSubmitting ? 'Submitting...' : 'Checkout'),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
