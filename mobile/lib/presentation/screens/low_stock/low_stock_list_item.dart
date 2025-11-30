import 'package:flutter/material.dart';
import 'package:mobile/data/models/low_stock_item.dart';

class LowStockListItem extends StatefulWidget {
  final LowStockItem item;

  const LowStockListItem({super.key, required this.item});

  @override
  State<LowStockListItem> createState() => _LowStockListItemState();
}

class _LowStockListItemState extends State<LowStockListItem> {
  bool _isInCart = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      color: widget.item.isCritical ? Colors.red.shade50 : null,
      child: CheckboxListTile(
        value: _isInCart,
        onChanged: (val) => setState(() => _isInCart = val ?? false),
        title: Text(
          widget.item.name,
          style: TextStyle(
            fontWeight: widget.item.isCritical
                ? FontWeight.bold
                : FontWeight.normal,
            color: widget.item.isCritical ? Colors.red.shade900 : null,
            decoration: _isInCart ? TextDecoration.lineThrough : null,
          ),
        ),
        subtitle: Text(
          'Stock: ${widget.item.currentStock} / Min: ${widget.item.minStock}\nBuy: ${widget.item.recommendedBuyQuantity}',
        ),
        secondary: widget.item.isCritical
            ? Icon(Icons.warning, color: Colors.red.shade700)
            : const Icon(Icons.shopping_cart_outlined),
      ),
    );
  }
}
