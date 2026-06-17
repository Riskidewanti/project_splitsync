import 'package:flutter/material.dart';

import '../../../ocr/presentation/pages/edit_items_page.dart';
import '../../data/datasources/expense_remote_data_source.dart';
import 'success_page.dart';

class ConfirmExpensePage extends StatefulWidget {
  const ConfirmExpensePage({
    super.key,
    required this.merchantName,
    required this.expenseDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceFee,
    required this.totalAmount,
    required this.itemCount,
    required this.participantCount,
    required this.splitMethod,
    required this.currentUserSplitAmount,
    required this.currentUserPercentage,
    this.note,
    this.tags = const <String>[],
  });

  final String merchantName;
  final DateTime? expenseDate;
  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double serviceFee;
  final double totalAmount;
  final int itemCount;
  final int participantCount;
  final String splitMethod;
  final double currentUserSplitAmount;
  final double? currentUserPercentage;
  final String? note;
  final List<String> tags;

  @override
  State<ConfirmExpensePage> createState() => _ConfirmExpensePageState();
}

class _ConfirmExpensePageState extends State<ConfirmExpensePage> {
  final ExpenseRemoteDataSource _expenseRemoteDataSource =
      ExpenseRemoteDataSource();
  bool _isSaving = false;

  Future<void> _confirmExpense() async {
    if (_isSaving) {
      return;
    }

    setState(() {
      _isSaving = true;
    });

    try {
      await _expenseRemoteDataSource.createExpense(
        merchantName: widget.merchantName,
        expenseDate: widget.expenseDate ?? DateTime.now(),
        items: widget.items
            .map(
              (ReceiptItem item) => ExpenseItemDraft(
                name: item.name,
                quantity: item.quantity,
                unitPrice: item.price,
              ),
            )
            .toList(),
        subtotal: widget.subtotal,
        taxAmount: widget.tax,
        serviceChargeAmount: widget.serviceFee,
        discountAmount: 0,
        totalAmount: widget.totalAmount,
        splitMethod: widget.splitMethod,
        currentUserSplitAmount: widget.currentUserSplitAmount,
        currentUserPercentage: widget.currentUserPercentage,
      );

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return SuccessPage(
              totalAmount: widget.totalAmount,
              participantCount: widget.participantCount,
            );
          },
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Gagal menyimpan: $error')));
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
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
            child: Column(
              children: <Widget>[
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
                    children: <Widget>[
                      const Text(
                        'Konfirmasi Pengeluaran',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF1D2430),
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Perhatikan detail sebelum dikirim ke grup',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _ExpenseCard(
                        merchantName: widget.merchantName,
                        totalAmount: widget.totalAmount,
                        itemCount: widget.itemCount,
                      ),
                      const SizedBox(height: 18),
                      _NoteField(initialText: widget.note),
                      const SizedBox(height: 14),
                      _TagsSection(tags: widget.tags),
                    ],
                  ),
                ),
                _BottomButton(isSaving: _isSaving, onPressed: _confirmExpense),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.merchantName,
    required this.totalAmount,
    required this.itemCount,
  });

  final String merchantName;
  final double totalAmount;
  final int itemCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF1B9B9)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
            child: Row(
              children: <Widget>[
                Container(
                  width: 46,
                  height: 46,
                  decoration: const BoxDecoration(
                    color: Color(0xFFB9E5E2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.storefront_outlined,
                    color: Color(0xFF4B9F99),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        merchantName,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      const Text(
                        'Hari ini, 2:45 PM',
                        style: TextStyle(
                          color: Color(0xFF6B7280),
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEDEEF0)),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 24, 16, 18),
            child: Column(
              children: <Widget>[
                Text(
                  _formatCurrency(totalAmount),
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 40,
                    fontWeight: FontWeight.w800,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '$itemCount barang',
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 20),
                const Row(
                  children: <Widget>[
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.group_outlined,
                        title: 'Split dengan',
                        value: 'Teman',
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.category_outlined,
                        title: 'Kategori',
                        value: 'Belanja',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  final IconData icon;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F5F7),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: const Color(0xFF4B5563), size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  title,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
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

class _NoteField extends StatelessWidget {
  const _NoteField({required this.initialText});

  final String? initialText;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: initialText,
      readOnly: true,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Tambah catatan (opsional)',
        hintStyle: const TextStyle(
          color: Color(0xFF8A92A3),
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        prefixIcon: const Icon(
          Icons.notes_outlined,
          color: Color(0xFF6B7280),
          size: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFFE2E5EA)),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
      ),
    );
  }
}

class _TagsSection extends StatelessWidget {
  const _TagsSection({required this.tags});

  final List<String> tags;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final String tag in tags) _TagChip(label: _normalizeTag(tag)),
        const _TagChip(label: '+ Tag', outlined: true),
      ],
    );
  }

  String _normalizeTag(String tag) {
    if (tag.startsWith('#')) {
      return tag;
    }

    return '#$tag';
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label, this.outlined = false});

  final String label;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: outlined ? Colors.white : const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(20),
        border: outlined ? Border.all(color: const Color(0xFFF0B5B5)) : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          color: outlined ? const Color(0xFFD71920) : const Color(0xFF4B5563),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _BottomButton extends StatelessWidget {
  const _BottomButton({required this.isSaving, required this.onPressed});

  final bool isSaving;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
      child: SizedBox(
        height: 54,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC70F1B),
            foregroundColor: Colors.white,
            disabledBackgroundColor: const Color(0xFFC70F1B),
            disabledForegroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          onPressed: isSaving ? null : onPressed,
          child: isSaving
              ? const SizedBox.square(
                  dimension: 20,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.4,
                  ),
                )
              : const Text(
                  'Konfirmasi',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800),
                ),
        ),
      ),
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
