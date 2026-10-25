import 'package:flutter/material.dart';
import 'package:the_local_shop/core/theme/app_colors.dart';
import 'package:the_local_shop/core/widgets/elder_friendly_button.dart';
import 'package:the_local_shop/features/orders/domain/models/order.dart';

class BillBuilderDialog extends StatefulWidget {
  final CustomerOrder order;
  final Function(List<OrderItem> items, double deliveryFee, double packingFee) onBillSubmitted;

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

  double get _itemsSubtotal => _items.fold(0.0, (acc, item) => acc + item.total);
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
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 20,
        left: 20,
        right: 20,
      ),
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Build Itemized Bill',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.secondary),
                  ),
                  Text(
                    'For: ${widget.order.customerName} (${widget.order.customerAddress})',
                    style: const TextStyle(fontSize: 14, color: Colors.black54),
                  ),
                ],
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 28),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(),

          // Frequent Items Chips
          const Text('Tap to Add Frequent Items:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _frequentCatalog.map((cat) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ActionChip(
                    avatar: const Icon(Icons.add, size: 16, color: AppColors.secondary),
                    label: Text('${cat['name']} (₹${(cat['price'] as double).toInt()})'),
                    onPressed: () => _addFromCatalog(cat),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 14),

          // Custom item form
          Row(
            children: [
              Expanded(
                flex: 3,
                child: TextField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Item Name',
                    hintText: 'e.g. Red Chilli',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: TextField(
                  controller: _qtyController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Qty',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: TextField(
                  controller: _priceController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Price ₹',
                    isDense: true,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton.filled(
                icon: const Icon(Icons.add),
                style: IconButton.styleFrom(backgroundColor: AppColors.secondary),
                onPressed: _addCustomItem,
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Added items list
          Expanded(
            child: _items.isEmpty
                ? const Center(
                    child: Text('No items added yet. Tap items above or type custom item.'),
                  )
                : ListView.builder(
                    itemCount: _items.length,
                    itemBuilder: (context, idx) {
                      final item = _items[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: AppColors.cardLight,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${item.name} (${item.quantity.toInt()} × ₹${item.pricePerUnit.toInt()})',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ),
                            Text(
                              '₹${item.total.toInt()}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                              onPressed: () => setState(() => _items.removeAt(idx)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Total Summary
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Items Subtotal:', style: TextStyle(fontSize: 15)),
                    Text('₹${_itemsSubtotal.toInt()}', style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Delivery Fee (${widget.order.slot.name.toUpperCase()}):', style: const TextStyle(fontSize: 14)),
                    Text('₹${_deliveryFee.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Eco Packing Fee:', style: TextStyle(fontSize: 14)),
                    Text('₹${_packingFee.toInt()}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  ],
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Grand Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
                    Text('₹${_grandTotal.toInt()}', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          ElderFriendlyButton(
            text: 'Send Bill to Customer (₹${_grandTotal.toInt()})',
            icon: Icons.send_rounded,
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
