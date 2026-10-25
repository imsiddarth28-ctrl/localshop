import 'package:flutter/material.dart';
import 'package:the_local_shop/core/theme/app_tokens.dart';
import 'package:the_local_shop/core/widgets/glass/glass.dart';
import 'package:the_local_shop/features/orders/domain/models/order.dart';

class BillBuilderDialog extends StatefulWidget {
  final CustomerOrder order;
  final Function(List<OrderItem> items, double deliveryFee, double packingFee)
      onBillSubmitted;

  const BillBuilderDialog({
    super.key,
    required this.order,
    required this.onBillSubmitted,
  });

  @override
  State<BillBuilderDialog> createState() => _BillBuilderDialogState();
}

class _BillBuilderDialogState extends State<BillBuilderDialog> {
  final List<OrderItem> _items = [];
  final _nameController = TextEditingController();
  final _qtyController = TextEditingController(text: '1');
  final _priceController = TextEditingController();
  final String _selectedUnit = '1 kg';

  late double _deliveryFee;
  final double _packingFee = 2.0;

  final List<Map<String, dynamic>> _frequentCatalog = [
    {'name': 'Aashirvaad Atta', 'unit': '5 kg', 'price': 250.0},
    {'name': 'Madhur Pure Sugar', 'unit': '1 kg', 'price': 46.0},
    {'name': 'Fortune Sunflower Oil', 'unit': '1 L', 'price': 140.0},
    {'name': 'Tata Salt', 'unit': '1 kg', 'price': 28.0},
    {'name': 'Heritage Milk Blue', 'unit': '500 ml', 'price': 34.0},
    {'name': 'Farm Fresh Eggs', 'unit': '6 pcs', 'price': 48.0},
    {'name': 'Toor Dal Premium', 'unit': '1 kg', 'price': 165.0},
    {'name': 'Fresh Onions', 'unit': '1 kg', 'price': 35.0},
    {'name': 'Fresh Potatoes', 'unit': '1 kg', 'price': 30.0},
    {'name': 'Vim Bar Large', 'unit': '1 pc', 'price': 20.0},
  ];

  @override
  void initState() {
    super.initState();
    _deliveryFee = widget.order.deliveryFee;
    if (widget.order.items.isNotEmpty) {
      _items.addAll(widget.order.items);
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _qtyController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  double get _itemsSubtotal =>
      _items.fold(0.0, (acc, item) => acc + item.total);
  double get _grandTotal => _itemsSubtotal + _deliveryFee + _packingFee;

  void _addFromCatalog(Map<String, dynamic> cat) {
    setState(() {
      _items.add(OrderItem(
        name: cat['name'] as String,
        quantity: 1,
        unit: cat['unit'] as String,
        pricePerUnit: cat['price'] as double,
      ));
    });
  }

  void _addCustomItem() {
    final name = _nameController.text.trim();
    final qty = double.tryParse(_qtyController.text.trim()) ?? 1.0;
    final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

    if (name.isEmpty || price <= 0) return;

    setState(() {
      _items.add(OrderItem(
        name: name,
        quantity: qty,
        unit: _selectedUnit,
        pricePerUnit: price,
      ));
      _nameController.clear();
      _qtyController.text = '1';
      _priceController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTokens.spacing20,
        top: AppTokens.spacing16,
        left: AppTokens.spacing20,
        right: AppTokens.spacing20,
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Build Itemized Bill',
                      style: AppTokens.headingMedium.copyWith(
                        fontSize: 20,
                        color: isDark
                            ? AppTokens.textPrimaryDark
                            : AppTokens.textPrimaryLight,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'For: ${widget.order.customerName} (${widget.order.customerAddress})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTokens.bodySmall.copyWith(
                        color: isDark
                            ? AppTokens.textSecondaryDark
                            : AppTokens.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(
                  Icons.close_rounded,
                  size: 24,
                  color: isDark
                      ? AppTokens.textSecondaryDark
                      : AppTokens.textSecondaryLight,
                ),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacing12),

          // Frequent Items Bar
          Text(
            'Tap to Add Frequent Items:',
            style: AppTokens.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark
                  ? AppTokens.textPrimaryDark
                  : AppTokens.textPrimaryLight,
            ),
          ),
          const SizedBox(height: AppTokens.spacing8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _frequentCatalog.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => _addFromCatalog(cat),
                    borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.06)
                            : Colors.black.withOpacity(0.04),
                        borderRadius:
                            BorderRadius.circular(AppTokens.radiusChip),
                        border: Border.all(
                          color: isDark
                              ? AppTokens.glassBorderDark
                              : AppTokens.glassBorderLight,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.add_rounded,
                            size: 14,
                            color: AppTokens.primary(isDark),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${cat['name']} (₹${(cat['price'] as double).toInt()})',
                            style: AppTokens.bodySmall.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppTokens.textPrimaryDark
                                  : AppTokens.textPrimaryLight,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppTokens.spacing16),

          // Add Custom Item Row
          Row(
            children: [
              Expanded(
                flex: 4,
                child: GlassTextField(
                  controller: _nameController,
                  label: 'Item Name',
                  hint: 'e.g. Red Chilli',
                  prefixIcon: Icons.shopping_basket_outlined,
                ),
              ),
              const SizedBox(width: AppTokens.spacing8),
              Expanded(
                flex: 2,
                child: GlassTextField(
                  controller: _qtyController,
                  label: 'Qty',
                  keyboardType: TextInputType.number,
                ),
              ),
              const SizedBox(width: AppTokens.spacing8),
              Expanded(
                flex: 3,
                child: GlassTextField(
                  controller: _priceController,
                  label: 'Price ₹',
                  keyboardType: TextInputType.number,
                  prefixIcon: Icons.currency_rupee_rounded,
                ),
              ),
              const SizedBox(width: AppTokens.spacing8),
              SizedBox(
                height: 52,
                width: 52,
                child: GlassButton(
                  icon: Icons.add_rounded,
                  variant: GlassButtonVariant.filled,
                  height: 52,
                  onPressed: _addCustomItem,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.spacing16),

          // Added items list
          Expanded(
            child: _items.isEmpty
                ? Center(
                    child: Text(
                      'No items added yet.\nTap quick items above or type custom items.',
                      textAlign: TextAlign.center,
                      style: AppTokens.bodySmall.copyWith(
                        color: isDark
                            ? AppTokens.textSecondaryDark
                            : AppTokens.textSecondaryLight,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, idx) {
                      final item = _items[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTokens.spacing12,
                          vertical: AppTokens.spacing8,
                        ),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.04)
                              : Colors.black.withOpacity(0.03),
                          borderRadius:
                              BorderRadius.circular(AppTokens.radiusButton),
                          border: Border.all(
                            color: isDark
                                ? AppTokens.glassBorderDark.withOpacity(0.5)
                                : AppTokens.glassBorderLight.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} (${item.quantity.toInt()} × ₹${item.pricePerUnit.toInt()})',
                                style: AppTokens.bodyMedium.copyWith(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? AppTokens.textPrimaryDark
                                      : AppTokens.textPrimaryLight,
                                ),
                              ),
                            ),
                            Text(
                              '₹${item.total.toInt()}',
                              style: AppTokens.headingSmall.copyWith(
                                fontSize: 15,
                                color: isDark
                                    ? AppTokens.textPrimaryDark
                                    : AppTokens.textPrimaryLight,
                              ),
                            ),
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: AppTokens.danger,
                                size: 18,
                              ),
                              onPressed: () =>
                                  setState(() => _items.removeAt(idx)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Total Summary Card
          GlassCard(
            useRealBlur: false,
            padding: const EdgeInsets.all(AppTokens.spacing12),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Items Subtotal:',
                      style: AppTokens.bodySmall.copyWith(
                        color: isDark
                            ? AppTokens.textSecondaryDark
                            : AppTokens.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '₹${_itemsSubtotal.toInt()}',
                      style: AppTokens.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTokens.textPrimaryDark
                            : AppTokens.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Delivery Fee (${widget.order.slot.name.toUpperCase()}):',
                      style: AppTokens.bodySmall.copyWith(
                        color: isDark
                            ? AppTokens.textSecondaryDark
                            : AppTokens.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '₹${_deliveryFee.toInt()}',
                      style: AppTokens.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTokens.textPrimaryDark
                            : AppTokens.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Eco Packing Fee:',
                      style: AppTokens.bodySmall.copyWith(
                        color: isDark
                            ? AppTokens.textSecondaryDark
                            : AppTokens.textSecondaryLight,
                      ),
                    ),
                    Text(
                      '₹${_packingFee.toInt()}',
                      style: AppTokens.bodyMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark
                            ? AppTokens.textPrimaryDark
                            : AppTokens.textPrimaryLight,
                      ),
                    ),
                  ],
                ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grand Total:',
                      style: AppTokens.headingSmall.copyWith(
                        fontSize: 16,
                        color: AppTokens.primary(isDark),
                      ),
                    ),
                    Text(
                      '₹${_grandTotal.toInt()}',
                      style: AppTokens.headingMedium.copyWith(
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        color: AppTokens.primary(isDark),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppTokens.spacing14),

          GlassButton(
            text: 'Send Bill to Customer (₹${_grandTotal.toInt()})',
            icon: Icons.send_rounded,
            variant: GlassButtonVariant.filled,
            onPressed: _items.isEmpty
                ? null
                : () {
                    widget.onBillSubmitted(_items, _deliveryFee, _packingFee);
                    Navigator.pop(context);
                  },
          ),
        ],
      ),
    );
  }
}
