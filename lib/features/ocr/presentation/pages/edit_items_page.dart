import 'package:flutter/material.dart';

import '../../../expenses/presentation/pages/split_calculation_page.dart';

class ReceiptItem {
  const ReceiptItem({
    required this.name,
    required this.quantity,
    required this.price,
  });

  final String name;
  final int quantity;
  final double price;

  ReceiptItem copyWith({String? name, int? quantity, double? price}) {
    return ReceiptItem(
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      price: price ?? this.price,
    );
  }
}

class EditItemsPage extends StatefulWidget {
  const EditItemsPage({
    super.key,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceFee,
  });

  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double serviceFee;

  @override
  State<EditItemsPage> createState() => _EditItemsPageState();
}

class _EditItemsPageState extends State<EditItemsPage> {
  late final List<ReceiptItem> _items = List<ReceiptItem>.from(widget.items);

  double get subtotal {
    return _items.fold<double>(
      0,
      (double total, ReceiptItem item) => total + item.price,
    );
  }

  double get tax => widget.tax;

  double get serviceFee => widget.serviceFee;

  double get total => subtotal + tax + serviceFee;

  Future<void> _addItem() async {
    final ReceiptItem? item = await _showItemDialog();
    if (item == null) {
      return;
    }

    setState(() {
      _items.add(item);
    });
  }

  Future<void> _editItem(ReceiptItem item) async {
    final ReceiptItem? updatedItem = await _showItemDialog(item: item);
    if (updatedItem == null) {
      return;
    }

    setState(() {
      final int index = _items.indexOf(item);
      if (index != -1) {
        _items[index] = updatedItem;
      }
    });
  }

  void _deleteItem(ReceiptItem item) {
    setState(() {
      _items.remove(item);
    });
  }

  Future<ReceiptItem?> _showItemDialog({ReceiptItem? item}) {
    final TextEditingController nameController = TextEditingController(
      text: item?.name ?? '',
    );
    final TextEditingController priceController = TextEditingController(
      text: item == null ? '' : item.price.toStringAsFixed(2),
    );

    return showDialog<ReceiptItem>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(item == null ? 'Tambah Barang' : 'Edit Barang'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Nama barang',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 14),
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Harga',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: <Widget>[
            if (item != null)
              TextButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                  _deleteItem(item);
                },
                child: const Text('Hapus'),
              ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final String name = nameController.text.trim();
                final double? price = double.tryParse(
                  priceController.text.trim().replaceAll(',', '.'),
                );

                if (name.isEmpty || price == null || price <= 0) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Nama dan harga barang wajib valid.'),
                      ),
                    );
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  ReceiptItem(
                    name: name,
                    quantity: item?.quantity ?? 1,
                    price: price,
                  ),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      priceController.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text(
          'SplitSync',
          style: TextStyle(
            color: Color(0xFFD70F1F),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Tinjau Barang',
                    style: TextStyle(
                      color: Color(0xFF1D2430),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Verifikasi harga dan atur barang sebelum dikirim ke grup',
                    style: TextStyle(
                      color: Color(0xFF5F6671),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: ListView(
                      children: <Widget>[
                        _ItemsCard(
                          items: _items,
                          onAddItem: _addItem,
                          onEditItem: _editItem,
                        ),
                        const SizedBox(height: 18),
                        _SummaryCard(
                          subtotal: subtotal,
                          tax: tax,
                          serviceFee: serviceFee,
                          total: total,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC70F1B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return SplitCalculationPage(
                                totalAmount: total,
                                members: const <SplitMember>[
                                  SplitMember(
                                    name: 'You',
                                    avatarText: 'Y',
                                    amount: 61.50,
                                  ),
                                  SplitMember(
                                    name: 'Alex',
                                    avatarText: 'A',
                                    amount: 31.50,
                                  ),
                                  SplitMember(
                                    name: 'Sarah',
                                    avatarText: 'S',
                                    amount: 31.50,
                                  ),
                                ],
                              );
                            },
                          ),
                        );
                      },
                      label: const Text(
                        'KONFIRMASI & SPLIT',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                        ),
                      ),
                      icon: const Icon(Icons.arrow_forward, size: 18),
                      iconAlignment: IconAlignment.end,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({
    required this.items,
    required this.onAddItem,
    required this.onEditItem,
  });

  final List<ReceiptItem> items;
  final VoidCallback onAddItem;
  final ValueChanged<ReceiptItem> onEditItem;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      padding: EdgeInsets.zero,
      child: Column(
        children: <Widget>[
          const Padding(
            padding: EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'DETAIL BARANG',
                    style: TextStyle(
                      color: Color(0xFF6B7280),
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                Text(
                  'HARGA',
                  style: TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1.1,
                  ),
                ),
                SizedBox(width: 34),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFE8EAEE)),
          if (items.isEmpty)
            const _EmptyItemsRow()
          else
            for (final ReceiptItem item in items) ...<Widget>[
              _ItemRow(item: item, onEdit: () => onEditItem(item)),
              if (item != items.last)
                const Divider(height: 1, color: Color(0xFFE8EAEE)),
            ],
          const Divider(height: 1, color: Color(0xFFE8EAEE)),
          TextButton.icon(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFD71920),
              minimumSize: const Size.fromHeight(48),
              alignment: Alignment.centerLeft,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(
                  bottom: Radius.circular(12),
                ),
              ),
            ),
            onPressed: onAddItem,
            icon: const Icon(Icons.add_circle_outline, size: 17),
            label: const Text(
              'Tambah Barang',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
            ),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item, required this.onEdit});

  final ReceiptItem item;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 13, 10, 13),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF1F2933),
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Qty: ${item.quantity}',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(item.price),
            style: const TextStyle(
              color: Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 16),
          IconButton(
            constraints: const BoxConstraints.tightFor(width: 32, height: 32),
            padding: EdgeInsets.zero,
            visualDensity: VisualDensity.compact,
            onPressed: onEdit,
            icon: const Icon(
              Icons.edit_outlined,
              size: 17,
              color: Color(0xFF4B5563),
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyItemsRow extends StatelessWidget {
  const _EmptyItemsRow();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(18),
      child: Center(
        child: Text(
          'Belum ada barang',
          style: TextStyle(
            color: Color(0xFF6B7280),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.subtotal,
    required this.tax,
    required this.serviceFee,
    required this.total,
  });

  final double subtotal;
  final double tax;
  final double serviceFee;
  final double total;

  @override
  Widget build(BuildContext context) {
    return _CardShell(
      child: Column(
        children: <Widget>[
          _SummaryRow(label: 'Subtotal', amount: subtotal),
          const SizedBox(height: 14),
          _SummaryRow(label: 'Tax', amount: tax),
          const SizedBox(height: 14),
          _SummaryRow(
            label: 'Service Fee / Tip',
            amount: serviceFee,
            amountColor: const Color(0xFFD71920),
          ),
          const SizedBox(height: 18),
          const Divider(height: 1, color: Color(0xFFE8EAEE)),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Total',
                  style: TextStyle(
                    color: Color(0xFF1F2933),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                _formatCurrency(total),
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFF111827),
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  height: 1,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({
    required this.label,
    required this.amount,
    this.amountColor = const Color(0xFF111827),
  });

  final String label;
  final double amount;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5F6671),
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            color: amountColor,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _CardShell extends StatelessWidget {
  const _CardShell({
    required this.child,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

String _formatCurrency(double value) {
  final String fixed = value.toStringAsFixed(2);
  final List<String> parts = fixed.split('.');
  final String whole = parts.first;
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < whole.length; i++) {
    final int reverseIndex = whole.length - i;
    buffer.write(whole[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '\$${buffer.toString()}.${parts.last}';
}
