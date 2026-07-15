import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../ocr/presentation/pages/edit_items_page.dart';
import 'split_bill_page.dart';
import 'split_bill_group_selection_page.dart';

class ReviewItemsPage extends StatefulWidget {
  const ReviewItemsPage({
    super.key,
    this.items = const <ReceiptItem>[],
    this.tax = 0,
    this.serviceFee = 0,
  });

  final List<ReceiptItem> items;
  final double tax;
  final double serviceFee;

  @override
  State<ReviewItemsPage> createState() => _ReviewItemsPageState();
}

class _ReviewItemsPageState extends State<ReviewItemsPage> {
  static const Color _primary = Color(0xFFC8101B);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF6F6868);
  static const Color _surface = Color(0xFFFFFAF7);
  static const Color _line = Color(0xFFE7E7EB);

  late final List<ReceiptItem> _items;
  late double _tax;
  late double _serviceFee;

  @override
  void initState() {
    super.initState();
    _items = widget.items.isEmpty
        ? <ReceiptItem>[
            const ReceiptItem(name: 'Truffle Fries', quantity: 1, price: 12),
            const ReceiptItem(name: 'Red Wine (Glass)', quantity: 2, price: 45),
            const ReceiptItem(name: 'Ribeye Steak', quantity: 1, price: 65),
          ]
        : List<ReceiptItem>.from(widget.items);
    _tax = widget.tax;
    _serviceFee = widget.serviceFee;

    if (widget.items.isEmpty && _tax == 0 && _serviceFee == 0) {
      _tax = 10.83;
      _serviceFee = 24.40;
    }
  }

  double get _subtotal {
    return _items.fold<double>(0, (double sum, ReceiptItem item) {
      return sum + item.price;
    });
  }

  double get _total => _subtotal + _tax + _serviceFee;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 22),
          onPressed: () => Navigator.maybePop(context),
        ),
        centerTitle: true,
        title: const Text(
          'SplitSync',
          style: TextStyle(
            color: _primary,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16),
                child: _Header(),
              ),
              const SizedBox(height: 15),
              Expanded(
                child: ListView(
                  children: <Widget>[
                    _ItemsCard(
                      items: _items,
                      onAddItem: _addItem,
                      onEditItem: _editItem,
                    ),
                    const SizedBox(height: 16),
                    _SummaryCard(
                      subtotal: _subtotal,
                      tax: _tax,
                      serviceFee: _serviceFee,
                      total: _total,
                      onEditTax: () => _editAmount(
                        title: 'Edit Tax',
                        initialValue: _tax,
                        onSaved: (double value) => setState(() => _tax = value),
                      ),
                      onEditServiceFee: () => _editAmount(
                        title: 'Edit Service Fee / Tip',
                        initialValue: _serviceFee,
                        onSaved: (double value) {
                          setState(() => _serviceFee = value);
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: _items.isEmpty ? null : _confirmAndSplit,
                  label: const Text(
                    'KONFIRMASI & SPLIT',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
                  ),
                  icon: const Icon(Icons.arrow_forward, size: 18),
                  iconAlignment: IconAlignment.end,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _addItem() async {
    final ReceiptItem? item = await _showItemDialog();
    if (item == null) return;
    setState(() => _items.add(item));
  }

  Future<void> _editItem(ReceiptItem item) async {
    final ReceiptItem? updated = await _showItemDialog(item: item);
    if (updated == null) return;
    setState(() {
      final int index = _items.indexOf(item);
      if (index != -1) _items[index] = updated;
    });
  }

  void _deleteItem(ReceiptItem item) {
    setState(() => _items.remove(item));
  }

  Future<ReceiptItem?> _showItemDialog({ReceiptItem? item}) {
    final TextEditingController nameController = TextEditingController(
      text: item?.name ?? '',
    );
    final TextEditingController quantityController = TextEditingController(
      text: (item?.quantity ?? 1).toString(),
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
              const SizedBox(height: 12),
              TextField(
                controller: quantityController,
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Qty',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
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
                final int? quantity = int.tryParse(
                  quantityController.text.trim(),
                );
                final double? price = _parseAmount(priceController.text);

                if (name.isEmpty ||
                    quantity == null ||
                    quantity <= 0 ||
                    price == null ||
                    price <= 0) {
                  _showMessage('Nama, qty, dan harga wajib valid.');
                  return;
                }

                Navigator.pop(
                  dialogContext,
                  ReceiptItem(name: name, quantity: quantity, price: price),
                );
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    ).whenComplete(() {
      nameController.dispose();
      quantityController.dispose();
      priceController.dispose();
    });
  }

  Future<void> _editAmount({
    required String title,
    required double initialValue,
    required ValueChanged<double> onSaved,
  }) async {
    final TextEditingController controller = TextEditingController(
      text: initialValue.toStringAsFixed(2),
    );

    final double? value = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Nominal',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final double? parsed = _parseAmount(controller.text);
                if (parsed == null || parsed < 0) {
                  _showMessage('Nominal wajib valid.');
                  return;
                }
                Navigator.pop(dialogContext, parsed);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (value != null) onSaved(value);
  }

  Future<void> _confirmAndSplit() async {
    final SplitBillGroupSelectionResult? result = await Navigator.push(
      context,
      MaterialPageRoute<SplitBillGroupSelectionResult>(
        builder: (BuildContext context) {
          return SplitBillGroupSelectionPage(
            totalBill: _total,
            billTitle: 'Whole Foods Market',
            itemCount: _items.length,
            subtotal: _subtotal,
            taxAmount: _tax,
            serviceFee: _serviceFee,
            items: List<ReceiptItem>.from(_items),
          );
        },
      ),
    );

    if (!mounted || result == null) return;

    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return SplitBillPage(
            groupId: result.groupId,
            userId: result.userId,
            totalBill: _total,
            billTitle: 'Whole Foods Market',
            itemCount: _items.length,
            subtotal: _subtotal,
            taxAmount: _tax,
            serviceFee: _serviceFee,
            items: List<ReceiptItem>.from(_items),
          );
        },
      ),
    );
  }

  double? _parseAmount(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Tinjau Barang',
          style: TextStyle(
            color: _ReviewItemsPageState._ink,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 4),
        Text(
          'Verifikasi harga dan atur barang sebelum dikirim ke grup!',
          style: TextStyle(
            color: _ReviewItemsPageState._muted,
            fontSize: 12,
            height: 1.35,
          ),
        ),
      ],
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
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          const _ItemsHeader(),
          if (items.isEmpty)
            const _EmptyItemsRow()
          else
            for (int index = 0; index < items.length; index++) ...<Widget>[
              _ItemRow(
                item: items[index],
                onEdit: () => onEditItem(items[index]),
              ),
              if (index != items.length - 1)
                const Divider(height: 1, color: _ReviewItemsPageState._line),
            ],
          _AddItemRow(onTap: onAddItem),
        ],
      ),
    );
  }
}

class _ItemsHeader extends StatelessWidget {
  const _ItemsHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 38,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: const BoxDecoration(
        color: Color(0xFFF8F8FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(8)),
      ),
      child: const Row(
        children: <Widget>[
          Expanded(
            child: Text(
              'DETAIL BARANG',
              style: TextStyle(
                color: Color(0xFF69636D),
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
          ),
          Text(
            'HARGA',
            style: TextStyle(
              color: Color(0xFF69636D),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          SizedBox(width: 34),
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
    return SizedBox(
      height: 58,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ReviewItemsPageState._ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Qty: ${item.quantity}',
                  style: const TextStyle(
                    color: _ReviewItemsPageState._muted,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Text(
            _formatCurrency(item.price),
            style: const TextStyle(
              color: _ReviewItemsPageState._ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          IconButton(
            tooltip: 'Edit item',
            onPressed: onEdit,
            icon: const Icon(Icons.edit, color: Color(0xFF4D4B52), size: 18),
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
          'Belum ada barang dari hasil scan',
          style: TextStyle(
            color: _ReviewItemsPageState._muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AddItemRow extends StatelessWidget {
  const _AddItemRow({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: const BorderRadius.vertical(bottom: Radius.circular(8)),
      child: Container(
        height: 41,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: const BoxDecoration(
          color: Color(0xFFFBFBFD),
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(8)),
        ),
        child: const Row(
          children: <Widget>[
            Icon(
              Icons.add_circle_outline,
              color: _ReviewItemsPageState._primary,
              size: 17,
            ),
            SizedBox(width: 7),
            Text(
              'Tambah Barang',
              style: TextStyle(
                color: _ReviewItemsPageState._primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
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
    required this.onEditTax,
    required this.onEditServiceFee,
  });

  final double subtotal;
  final double tax;
  final double serviceFee;
  final double total;
  final VoidCallback onEditTax;
  final VoidCallback onEditServiceFee;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
            child: Column(
              children: <Widget>[
                _SummaryLine(label: 'Subtotal', value: subtotal),
                const SizedBox(height: 22),
                _SummaryLine(
                  label: 'Tax (8.875%)',
                  value: tax,
                  editable: true,
                  onTap: onEditTax,
                ),
                const SizedBox(height: 22),
                _SummaryLine(
                  label: 'Service Fee / Tip',
                  value: serviceFee,
                  editable: true,
                  isHighlighted: true,
                  onTap: onEditServiceFee,
                ),
              ],
            ),
          ),
          const Divider(height: 25, color: _ReviewItemsPageState._line),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 15),
            child: Row(
              children: <Widget>[
                const Text(
                  'Total',
                  style: TextStyle(
                    color: _ReviewItemsPageState._ink,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const Spacer(),
                Text(
                  _formatCurrency(total),
                  style: const TextStyle(
                    color: _ReviewItemsPageState._ink,
                    fontSize: 36,
                    fontWeight: FontWeight.w500,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryLine extends StatelessWidget {
  const _SummaryLine({
    required this.label,
    required this.value,
    this.editable = false,
    this.isHighlighted = false,
    this.onTap,
  });

  final String label;
  final double value;
  final bool editable;
  final bool isHighlighted;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Widget row = Row(
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            color: _ReviewItemsPageState._muted,
            fontSize: 12,
          ),
        ),
        if (editable) ...<Widget>[
          const SizedBox(width: 5),
          const Icon(Icons.edit, color: Color(0xFFD4D1D1), size: 13),
        ],
        const Spacer(),
        Text(
          _formatCurrency(value),
          style: TextStyle(
            color: isHighlighted
                ? _ReviewItemsPageState._primary
                : _ReviewItemsPageState._ink,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );

    if (!editable) return row;
    return InkWell(onTap: onTap, child: row);
  }
}

String _formatCurrency(double value) {
  return NumberFormat.currency(locale: 'id_ID', symbol: 'Rp ', decimalDigits: 0)
      .format(value);
}
