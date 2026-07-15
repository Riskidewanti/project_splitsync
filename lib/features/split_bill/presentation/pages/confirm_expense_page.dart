import 'dart:math';

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SplitBillParticipantInput {
  const SplitBillParticipantInput({
    required this.displayName,
    required this.amount,
    this.expenseItemId = '',
    this.userId = '',
    this.avatarUrl,
    this.percentage,
    this.isPayer = false,
  });

  final String displayName;
  final double amount;
  final String expenseItemId;
  final String userId;
  final String? avatarUrl;
  final double? percentage;
  final bool isPayer;
}

class ConfirmExpensePage extends StatefulWidget {
  const ConfirmExpensePage({
    super.key,
    required this.title,
    required this.totalAmount,
    required this.itemCount,
    required this.splitMethod,
    this.groupId = '',
    this.userId = '',
    this.category = 'Belanja',
    this.tags = const <String>['dinner', 'supplies'],
    this.participants = const <SplitBillParticipantInput>[],
    this.subtotal = 0,
    this.taxAmount = 0,
    this.serviceFee = 0,
  });

  final String title;
  final double totalAmount;
  final int itemCount;
  final String splitMethod;
  final String groupId;
  final String userId;
  final String category;
  final List<String> tags;
  final List<SplitBillParticipantInput> participants;
  final double subtotal;
  final double taxAmount;
  final double serviceFee;

  @override
  State<ConfirmExpensePage> createState() => _ConfirmExpensePageState();
}

class _ConfirmExpensePageState extends State<ConfirmExpensePage> {
  static const Color _primary = Color(0xFFC8101B);
  static const Color _ink = Color(0xFF171A1F);
  static const Color _muted = Color(0xFF67656A);
  static const Color _surface = Color(0xFFFFFAF7);
  static const Color _tile = Color(0xFFF4F4F6);

  final TextEditingController _noteController = TextEditingController();
  late final List<String> _tags = List<String>.from(widget.tags);
  late final String _fallbackExpenseItemId = _newUuid();
  bool _isSaving = false;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF102033),
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, size: 30),
        ),
        centerTitle: true,
        title: const Text(
          'SplitSync',
          style: TextStyle(
            color: _primary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(40, 32, 40, 28),
                children: <Widget>[
                  const Text(
                    'Konfirmasi Pengeluaran',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _ink,
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Perhatikan detail sebelum dikirim ke grup',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: _muted,
                      fontSize: 19,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 36),
                  _ExpenseCard(
                    title: widget.title,
                    totalAmount: widget.totalAmount,
                    itemCount: widget.itemCount,
                    splitLabel: 'Teman',
                    category: widget.category,
                  ),
                  const SizedBox(height: 32),
                  _NoteField(controller: _noteController),
                  const SizedBox(height: 22),
                  _TagsRow(tags: _tags, onAddTag: _showAddTagDialog),
                ],
              ),
            ),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(40, 24, 40, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(
                  top: BorderSide(color: Colors.black.withValues(alpha: 0.06)),
                ),
              ),
              child: SizedBox(
                height: 74,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: _isSaving
                      ? null
                      : () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Halaman ini sudah tidak digunakan',
                              ),
                            ),
                          );
                        },
                  child: _isSaving
                      ? const SizedBox.square(
                          dimension: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.4,
                          ),
                        )
                      : const Text(
                          'Konfirmasi',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showAddTagDialog() async {
    final TextEditingController controller = TextEditingController();
    final String? tag = await showDialog<String>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Tambah Tag'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Tag',
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
                final String value = controller.text.trim();
                if (value.isEmpty) return;
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (tag == null) return;
    setState(() => _tags.add(tag.replaceFirst(RegExp(r'^#'), '')));
  }

  void _putUuidIfValid(Map<String, dynamic> data, String key, String value) {
    if (_isUuid(value)) {
      data[key] = value;
    }
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }

  String _newUuid() {
    final Random random = Random();
    const String hex = '0123456789abcdef';
    String randomHex(int length) {
      return List<String>.generate(
        length,
        (_) => hex[random.nextInt(hex.length)],
      ).join();
    }

    return '${randomHex(8)}-${randomHex(4)}-4${randomHex(3)}-'
        '${(8 + random.nextInt(4)).toRadixString(16)}${randomHex(3)}-'
        '${randomHex(12)}';
  }
}

class _ExpenseCard extends StatelessWidget {
  const _ExpenseCard({
    required this.title,
    required this.totalAmount,
    required this.itemCount,
    required this.splitLabel,
    required this.category,
  });

  final String title;
  final double totalAmount;
  final int itemCount;
  final String splitLabel;
  final String category;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Container(
            height: 7,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Color(0xFFC8101B), Color(0xFFFFD7D7)],
              ),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(32, 25, 32, 32),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Container(
                      width: 68,
                      height: 68,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA9DDE0),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.shopping_bag_outlined,
                        color: Colors.white,
                        size: 31,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: _ConfirmExpensePageState._ink,
                              fontSize: 27,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Hari ini, 2:45 PM',
                            style: TextStyle(
                              color: _ConfirmExpensePageState._muted,
                              fontSize: 19,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 28),
                Divider(color: Colors.black.withValues(alpha: 0.12)),
                const SizedBox(height: 42),
                Text(
                  _formatRupiah(totalAmount),
                  style: const TextStyle(
                    color: _ConfirmExpensePageState._ink,
                    fontSize: 56,
                    fontWeight: FontWeight.w400,
                    height: 1,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  '$itemCount barang',
                  style: const TextStyle(
                    color: _ConfirmExpensePageState._muted,
                    fontSize: 19,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  children: <Widget>[
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.people_outline,
                        label: 'Split dengan',
                        value: splitLabel,
                      ),
                    ),
                    const SizedBox(width: 24),
                    Expanded(
                      child: _InfoTile(
                        icon: Icons.category_outlined,
                        label: 'Kategori',
                        value: category,
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
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 84,
      padding: const EdgeInsets.symmetric(horizontal: 18),
      decoration: BoxDecoration(
        color: _ConfirmExpensePageState._tile,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, color: _ConfirmExpensePageState._muted, size: 30),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ConfirmExpensePageState._muted,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _ConfirmExpensePageState._ink,
                    fontSize: 20,
                    fontWeight: FontWeight.w500,
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
  const _NoteField({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        filled: true,
        fillColor: Colors.white,
        hintText: 'Tambah catatan (opsional)',
        hintStyle: const TextStyle(color: Color(0xFF747887), fontSize: 24),
        prefixIcon: const Icon(
          Icons.notes,
          color: _ConfirmExpensePageState._muted,
          size: 28,
        ),
        contentPadding: const EdgeInsets.symmetric(vertical: 25),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Color(0xFFDADDE4), width: 1.4),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(
            color: _ConfirmExpensePageState._primary,
          ),
        ),
      ),
      style: const TextStyle(
        color: _ConfirmExpensePageState._ink,
        fontSize: 20,
      ),
    );
  }
}

class _TagsRow extends StatelessWidget {
  const _TagsRow({required this.tags, required this.onAddTag});

  final List<String> tags;
  final VoidCallback onAddTag;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      children: <Widget>[
        for (final String tag in tags) _TagPill(label: '#$tag'),
        ActionChip(
          onPressed: onAddTag,
          backgroundColor: _ConfirmExpensePageState._surface,
          side: BorderSide(
            color: _ConfirmExpensePageState._primary.withValues(alpha: 0.25),
            width: 1.5,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          label: const Text(
            '+ Tag',
            style: TextStyle(
              color: _ConfirmExpensePageState._primary,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TagPill extends StatelessWidget {
  const _TagPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      backgroundColor: _ConfirmExpensePageState._tile,
      side: BorderSide.none,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      label: Text(
        label,
        style: const TextStyle(
          color: _ConfirmExpensePageState._muted,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

String _formatRupiah(double value) {
  final int rounded = value.round();
  final String digits = rounded.toString();
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < digits.length; i++) {
    final int reverseIndex = digits.length - i;
    buffer.write(digits[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'Rp${buffer.toString()}';
}
