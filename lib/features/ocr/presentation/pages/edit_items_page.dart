import 'package:flutter/material.dart';

import '../../../../authentication/auth_service.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../expenses/presentation/pages/split_calculation_page.dart';
import '../../../groups/data/datasources/group_remote_data_source.dart';
import '../../../groups/data/models/group_member_model.dart';
import '../../../groups/data/repositories/group_repository_impl.dart';
import '../../../split_bill/presentation/pages/split_bill_group_selection_page.dart';

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
    required this.merchantName,
    required this.expenseDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceFee,
    this.groupId,
  });

  final String merchantName;
  final DateTime? expenseDate;
  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double serviceFee;
  final String? groupId;

  @override
  State<EditItemsPage> createState() => _EditItemsPageState();
}

class _EditItemsPageState extends State<EditItemsPage> {
  final GroupRepositoryImpl _groupRepository = GroupRepositoryImpl(
    remoteDataSource: GroupRemoteDataSourceImpl(),
  );
  late final List<ReceiptItem> _items = List<ReceiptItem>.from(widget.items);
  String? _currentUserId;
  bool _isLoadingMembers = true;

  @override
  void initState() {
    super.initState();
    debugPrint(
      'EditItemsPage widget.items length=${widget.items.length}, '
      '_items length=${_items.length}',
    );
    _loadGroupMembers();
  }

  Future<void> _loadGroupMembers() async {
    final SessionProfile? profile = await AuthService.currentSession();
    final String? currentUserId = profile?.id;

    if (currentUserId == null) {
      if (!mounted) {
        return;
      }

      setState(() {
        _currentUserId = null;
        _isLoadingMembers = false;
      });
      return;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _currentUserId = currentUserId;
      _isLoadingMembers = false;
    });
  }

  List<SplitMember> _buildSplitMembers(
    List<GroupMemberModel> groupMembers,
    SessionProfile currentUser,
  ) {
    if (groupMembers.isEmpty) {
      return const <SplitMember>[];
    }

    final double splitAmount = total / groupMembers.length;

    return groupMembers.map((GroupMemberModel member) {
      final String displayName = _memberDisplayName(member, currentUser);

      return SplitMember(
        userId: member.userId,
        displayName: displayName,
        avatarText: _avatarText(displayName),
        amount: splitAmount,
      );
    }).toList();
  }

  String _memberDisplayName(
    GroupMemberModel member,
    SessionProfile currentUser,
  ) {
    if (member.userId == currentUser.id) {
      return _currentUserDisplayName(currentUser);
    }

    final String? displayName = member.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final String? email = member.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return _fallbackDisplayName(member.userId);
  }

  String _currentUserDisplayName(SessionProfile currentUser) {
    if (currentUser.username.trim().isNotEmpty) {
      return currentUser.username.trim();
    }

    if (currentUser.email.trim().isNotEmpty) {
      return currentUser.email.trim();
    }

    return _fallbackDisplayName(currentUser.id);
  }

  String _fallbackDisplayName(String userId) {
    final String shortId = userId.length <= 8 ? userId : userId.substring(0, 8);
    return 'Member $shortId';
  }

  String _avatarText(String displayName) {
    final String trimmedName = displayName.trim();
    if (trimmedName.isEmpty) {
      return '?';
    }

    return trimmedName.characters.first.toUpperCase();
  }

  double get subtotal {
    return _items.fold<double>(
      0,
      (double total, ReceiptItem item) => total + item.price,
    );
  }

  double get tax => widget.tax;

  double get serviceFee => widget.serviceFee;

  double get total => subtotal + tax + serviceFee;

  Future<void> _openSplitCalculation() async {
    final String? currentUserId = _currentUserId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Login diperlukan untuk split.')),
        );
      return;
    }

    final SplitBillGroupSelectionResult? result = await Navigator.push(
      context,
      MaterialPageRoute<SplitBillGroupSelectionResult>(
        builder: (BuildContext context) {
          return SplitBillGroupSelectionPage(
            totalBill: total,
            billTitle: widget.merchantName,
            itemCount: _items.length,
            subtotal: subtotal,
            taxAmount: tax,
            serviceFee: serviceFee,
            items: List<ReceiptItem>.unmodifiable(_items),
          );
        },
      ),
    );

    if (!mounted || result == null) {
      return;
    }

    try {
      final SessionProfile? profile = await AuthService.currentSession();
      if (profile == null) {
        if (!mounted) {
          return;
        }

        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(content: Text('Login diperlukan untuk split.')),
          );
        return;
      }

      final List<GroupMemberModel> groupMembers = await _groupRepository
          .getGroupMembers(result.groupId);
      final List<SplitMember> selectedMembers = _buildSplitMembers(
        groupMembers,
        profile,
      );

      if (!mounted) {
        return;
      }

      Navigator.push(
        context,
        MaterialPageRoute<void>(
          builder: (BuildContext context) {
            return SplitCalculationPage(
              merchantName: widget.merchantName,
              expenseDate: widget.expenseDate,
              items: List<ReceiptItem>.unmodifiable(_items),
              subtotal: subtotal,
              tax: tax,
              serviceFee: serviceFee,
              totalAmount: total,
              members: selectedMembers,
              currentUserId: result.userId,
              groupId: result.groupId,
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
        ..showSnackBar(
          SnackBar(content: Text('Gagal memuat anggota grup: $error')),
        );
    }
  }

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

  Future<ReceiptItem?> _showItemDialog({ReceiptItem? item}) async {
    final _ItemDialogResult? result = await showDialog<_ItemDialogResult>(
      context: context,
      builder: (BuildContext dialogContext) {
        return _ItemDialog(item: item);
      },
    );

    if (result == null) {
      return null;
    }

    if (result.delete) {
      if (item != null) {
        _deleteItem(item);
      }
      return null;
    }

    return result.item;
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
                height: 48,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC70F1B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: _isLoadingMembers
                          ? null
                          : _openSplitCalculation,
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

class _ItemDialogResult {
  const _ItemDialogResult.save(this.item) : delete = false;

  const _ItemDialogResult.delete() : item = null, delete = true;

  final ReceiptItem? item;
  final bool delete;
}

class _ItemDialog extends StatefulWidget {
  const _ItemDialog({required this.item});

  final ReceiptItem? item;

  @override
  State<_ItemDialog> createState() => _ItemDialogState();
}

class _ItemDialogState extends State<_ItemDialog> {
  late final TextEditingController _nameController = TextEditingController(
    text: widget.item?.name ?? '',
  );
  late final TextEditingController _priceController = TextEditingController(
    text: widget.item == null ? '' : _formatInputAmount(widget.item!.price),
  );
  final FocusNode _nameFocusNode = FocusNode();
  final FocusNode _priceFocusNode = FocusNode();

  @override
  void dispose() {
    _nameFocusNode.dispose();
    _priceFocusNode.dispose();
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _submit() {
    final String name = _nameController.text.trim();
    final double? price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );

    if (name.isEmpty || price == null || price <= 0) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Nama dan harga barang wajib valid.')),
        );
      return;
    }

    Navigator.pop(
      context,
      _ItemDialogResult.save(
        ReceiptItem(
          name: name,
          quantity: widget.item?.quantity ?? 1,
          price: price,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.item == null ? 'Tambah Barang' : 'Edit Barang'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          TextField(
            controller: _nameController,
            focusNode: _nameFocusNode,
            autofocus: true,
            textInputAction: TextInputAction.next,
            onSubmitted: (_) => _priceFocusNode.requestFocus(),
            decoration: const InputDecoration(
              labelText: 'Nama barang',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _priceController,
            focusNode: _priceFocusNode,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            textInputAction: TextInputAction.done,
            onSubmitted: (_) => _submit(),
            decoration: const InputDecoration(
              labelText: 'Harga',
              border: OutlineInputBorder(),
            ),
          ),
        ],
      ),
      actions: <Widget>[
        if (widget.item != null)
          TextButton(
            onPressed: () =>
                Navigator.pop(context, const _ItemDialogResult.delete()),
            child: const Text('Hapus'),
          ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Batal'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Simpan')),
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
            formatRupiah(item.price),
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
                formatRupiah(total),
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
          formatRupiah(amount),
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

String _formatInputAmount(double value) {
  final int rounded = value.round();
  if ((value - rounded).abs() < 0.01) {
    return rounded.toString();
  }

  return value.toStringAsFixed(2);
}
