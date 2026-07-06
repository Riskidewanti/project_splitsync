import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../ocr/presentation/pages/edit_items_page.dart';
import 'confirm_expense_page.dart';
import 'split_bill_group_selection_page.dart';

final NumberFormat _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class SplitBillPage extends StatefulWidget {
  const SplitBillPage({
    super.key,
    this.groupId = '',
    this.userId = '',
    this.totalBill = 124.50,
    this.billTitle = "Dinner at Luigi's",
    this.itemCount = 0,
    this.subtotal = 0,
    this.taxAmount = 0,
    this.serviceFee = 0,
    this.category = 'Belanja',
    this.items = const <ReceiptItem>[],
  });

  final String groupId;
  final String userId;
  final double totalBill;
  final String billTitle;
  final int itemCount;
  final double subtotal;
  final double taxAmount;
  final double serviceFee;
  final String category;
  final List<ReceiptItem> items;

  @override
  State<SplitBillPage> createState() => _SplitBillPageState();
}

class _SplitBillPageState extends State<SplitBillPage> {
  static const Color _primary = Color(0xFFC8101B);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF8A8282);
  static const Color _surface = Color(0xFFFFFAF7);
  static const Color _line = Color(0xFFE8E8EC);

  final List<_SettlementFriend> _participants = <_SettlementFriend>[];
  final Map<String, double> _customAmounts = <String, double>{};
  final Map<String, double> _percentages = <String, double>{};
  int _selectedTabIndex = 0;
  bool _isLoading = true;
  bool _didRedirectToGroupSelection = false;

  @override
  void initState() {
    super.initState();
    if (!_hasValidGroupContext) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _redirectToGroupSelection();
      });
      return;
    }
    _loadFriendsFromSupabase();
  }

  bool get _hasValidGroupContext {
    return _isUuid(widget.groupId) && _isUuid(widget.userId);
  }

  Future<void> _redirectToGroupSelection() async {
    if (!mounted || _didRedirectToGroupSelection) return;
    _didRedirectToGroupSelection = true;

    final SplitBillGroupSelectionResult? result = await Navigator.of(context)
        .push<SplitBillGroupSelectionResult>(
          MaterialPageRoute<SplitBillGroupSelectionResult>(
            builder: (_) => SplitBillGroupSelectionPage(
              totalBill: widget.totalBill,
              billTitle: widget.billTitle,
              itemCount: widget.itemCount,
              subtotal: widget.subtotal,
              taxAmount: widget.taxAmount,
              serviceFee: widget.serviceFee,
              category: widget.category,
              items: widget.items,
            ),
          ),
        );

    if (!mounted) return;
    if (result == null) {
      Navigator.of(context).maybePop();
      return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(
        builder: (_) => SplitBillPage(
          groupId: result.groupId,
          userId: result.userId,
          totalBill: widget.totalBill,
          billTitle: widget.billTitle,
          itemCount: widget.itemCount,
          subtotal: widget.subtotal,
          taxAmount: widget.taxAmount,
          serviceFee: widget.serviceFee,
          category: widget.category,
          items: widget.items,
        ),
      ),
    );
  }

  Future<void> _loadFriendsFromSupabase() async {
    setState(() => _isLoading = true);

    if (!_hasValidGroupContext) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final List<dynamic> rows = await _fetchParticipantRows();
      final List<_SettlementFriend> participants = rows
          .map((dynamic row) => row as Map<String, dynamic>)
          .map(_friendFromRow)
          .whereType<_SettlementFriend>()
          .toList();
      participants.sort((_SettlementFriend first, _SettlementFriend second) {
        if (first.id == widget.userId) return -1;
        if (second.id == widget.userId) return 1;
        return first.name.toLowerCase().compareTo(second.name.toLowerCase());
      });

      if (!mounted) return;
      setState(() {
        _participants
          ..clear()
          ..addAll(participants);
        _isLoading = false;
      });
    } catch (error) {
      debugPrint('Error fetching settlement friends: $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<List<dynamic>> _fetchParticipantRows() async {
    try {
      return await Supabase.instance.client
          .from('group_members')
          .select(
            'id,user_id,status,profiles!group_members_user_id_fkey(user_name,email,avatar_url)',
          )
          .eq('group_id', widget.groupId)
          .eq('status', 'active');
    } catch (_) {
      return await Supabase.instance.client
          .from('group_members')
          .select()
          .eq('group_id', widget.groupId)
          .eq('status', 'active');
    }
  }

  _SettlementFriend? _friendFromRow(Map<String, dynamic> row) {
    final String id = (row['user_id'] ?? row['id'] ?? '').toString();
    if (id.isEmpty) return null;

    final Object? profile = row['profiles'] ?? row['users'] ?? row['user'];
    final Map<String, dynamic>? profileMap = profile is Map<String, dynamic>
        ? profile
        : null;

    return _SettlementFriend(
      id: id,
      name: _firstNotEmpty(<Object?>[
        profileMap?['user_name'],
        row['name'],
        'Teman ${id.length >= 4 ? id.substring(0, 4) : id}',
      ]),
      account: _firstNotEmpty(<Object?>[
        profileMap?['email'],
        row['email'],
        id,
      ], fallback: id),
      avatarUrl: _firstNotEmpty(<Object?>[
        profileMap?['avatar_url'],
        row['avatar_url'],
      ], fallback: ''),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_hasValidGroupContext) {
      return const Scaffold(
        backgroundColor: _surface,
        body: SafeArea(
          child: Center(child: CircularProgressIndicator(color: _primary)),
        ),
      );
    }

    final List<_SettlementFriend> participants = _participants;
    final bool hasParticipants = participants.isNotEmpty;
    final double splitAmount = hasParticipants
        ? widget.totalBill / participants.length
        : 0;
    _syncMaps(participants);

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
        title: const Text(
          'SplitSync',
          style: TextStyle(
            color: _primary,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: _primary))
            : Padding(
                padding: const EdgeInsets.fromLTRB(31, 22, 31, 16),
                child: Column(
                  children: <Widget>[
                    _Header(
                      totalBill: widget.totalBill,
                      title: widget.billTitle,
                    ),
                    const SizedBox(height: 22),
                    _SegmentedTabs(
                      selectedIndex: _selectedTabIndex,
                      onChanged: (int index) {
                        setState(() => _selectedTabIndex = index);
                      },
                    ),
                    const SizedBox(height: 18),
                    if (hasParticipants) ...<Widget>[
                      _ParticipantsCard(
                        participants: participants,
                        splitAmount: splitAmount,
                        percentages: _percentages,
                        customAmounts: _customAmounts,
                        selectedTabIndex: _selectedTabIndex,
                        totalBill: widget.totalBill,
                        onEditCustomAmount: _editCustomAmount,
                        onEditPercentage: _editPercentage,
                      ),
                      const SizedBox(height: 14),
                    ] else ...<Widget>[
                      const _EmptyParticipantsCard(),
                      const SizedBox(height: 14),
                    ],
                    _AddFriendButton(onTap: _showAddFriendDialog),
                    const Spacer(),
                    _SubmitButton(
                      onPressed: hasParticipants ? _handleSubmit : null,
                    ),
                  ],
                ),
              ),
      ),
    );
  }

  void _showAddFriendDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Tambah Teman'),
          content: TextField(
            controller: controller,
            autofocus: true,
            decoration: const InputDecoration(hintText: 'Nama teman'),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final String name = controller.text.trim();
                if (name.isEmpty) return;
                setState(() {
                  _participants.add(
                    _SettlementFriend(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name,
                      account: 'manual',
                      avatarUrl: '',
                    ),
                  );
                });
                Navigator.pop(context);
              },
              child: const Text('Tambah'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _editCustomAmount(_SettlementFriend friend) async {
    // Calculate the maximum this person can be assigned.
    double othersTotal = 0;
    for (final MapEntry<String, double> entry in _customAmounts.entries) {
      if (entry.key != friend.id) othersTotal += entry.value;
    }
    final double maxForThisPerson = widget.totalBill - othersTotal;

    final TextEditingController controller = TextEditingController(
      text: (_customAmounts[friend.id] ?? 0).toInt().toString(),
    );

    final double? amount = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Atur nominal ${friend.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  labelText: 'Nominal',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Maks: ${_rupiahFormat.format(maxForThisPerson)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: _SplitBillPageState._muted,
                ),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () {
                final double? value = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );
                if (value == null || value < 0) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(content: Text('Nominal wajib valid.')),
                    );
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (amount == null) return;

    _updateCustomAmount(friend.id, amount);
  }

  Future<void> _editPercentage(_SettlementFriend friend) async {
    final double currentPct = _percentages[friend.id] ?? 0;
    final TextEditingController controller = TextEditingController(
      text: currentPct == currentPct.roundToDouble()
          ? currentPct.toInt().toString()
          : currentPct.toStringAsFixed(1),
    );

    final double? pct = await showDialog<double>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Atur persentase ${friend.name}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              suffixText: '%',
              labelText: 'Persentase',
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
                final double? value = double.tryParse(
                  controller.text.trim().replaceAll(',', '.'),
                );
                if (value == null || value < 0 || value > 100) {
                  ScaffoldMessenger.of(context)
                    ..hideCurrentSnackBar()
                    ..showSnackBar(
                      const SnackBar(
                        content: Text('Persentase harus antara 0 – 100.'),
                      ),
                    );
                  return;
                }
                Navigator.pop(dialogContext, value);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (pct == null) return;

    _updatePercentage(friend.id, pct);
  }

  void _handleSubmit() {
    final List<_SettlementFriend> participants = <_SettlementFriend>[
      ..._participants,
    ];
    if (participants.isEmpty) return;
    _syncMaps(participants);

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return ConfirmExpensePage(
            title: widget.billTitle,
            totalAmount: widget.totalBill,
            itemCount: widget.itemCount,
            splitMethod: _splitMethod,
            groupId: widget.groupId,
            userId: widget.userId,
            category: widget.category,
            subtotal: widget.subtotal,
            taxAmount: widget.taxAmount,
            serviceFee: widget.serviceFee,
            participants: <SplitBillParticipantInput>[
              for (int index = 0; index < participants.length; index++)
                SplitBillParticipantInput(
                  displayName: participants[index].name,
                  userId: participants[index].id,
                  avatarUrl: participants[index].avatarUrl.isEmpty
                      ? null
                      : participants[index].avatarUrl,
                  percentage: _selectedTabIndex == 1
                      ? _percentages[participants[index].id] ?? 0
                      : null,
                  amount: _amountForParticipant(participants[index]),
                  isPayer: index == 0,
                ),
            ],
          );
        },
      ),
    );
  }

  String get _splitMethod {
    if (_selectedTabIndex == 1) return 'percentage';
    if (_selectedTabIndex == 2) return 'exact';
    return 'equal';
  }

  double _amountForParticipant(_SettlementFriend participant) {
    final int count = _participants.length;
    if (_selectedTabIndex == 1) {
      final double pct = _percentages[participant.id] ?? 0;
      return widget.totalBill * pct / 100;
    }
    if (_selectedTabIndex == 2) {
      return _customAmounts[participant.id] ??
          (count > 0 ? widget.totalBill / count : 0);
    }
    return count > 0 ? widget.totalBill / count : 0;
  }

  // ── Bidirectional sync helpers ──────────────────────────────────────────

  /// Recalculates every participant's percentage from their custom amount.
  /// Formula: percentage = (exact_amount / total_bill) * 100
  void _recalculatePercentagesFromAmounts() {
    if (widget.totalBill <= 0) return;
    for (final _SettlementFriend f in _participants) {
      final double amount = _customAmounts[f.id] ?? 0;
      _percentages[f.id] = (amount / widget.totalBill) * 100;
    }
  }

  /// Recalculates every participant's custom amount from their percentage.
  /// Formula: exact_amount = total_bill * (percentage / 100)
  void _recalculateAmountsFromPercentages() {
    for (final _SettlementFriend f in _participants) {
      final double pct = _percentages[f.id] ?? 0;
      _customAmounts[f.id] = widget.totalBill * pct / 100;
    }
  }

  /// Updates a single participant's custom amount with validation, then
  /// recalculates all percentages so the Presentase tab stays in sync.
  void _updateCustomAmount(String id, double newAmount) {
    // Calculate how much budget the *other* participants are already using.
    double othersTotal = 0;
    for (final MapEntry<String, double> entry in _customAmounts.entries) {
      if (entry.key != id) othersTotal += entry.value;
    }

    // Cap the new amount so the grand total never exceeds totalBill.
    final double maxAllowed = widget.totalBill - othersTotal;
    final double clampedAmount = newAmount.clamp(0, maxAllowed);

    setState(() {
      _customAmounts[id] = clampedAmount;
      _recalculatePercentagesFromAmounts();
    });

    // Warn the user if their input was capped.
    if (newAmount > maxAllowed && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Nominal disesuaikan ke ${_rupiahFormat.format(clampedAmount)} '
            'agar total tidak melebihi ${_rupiahFormat.format(widget.totalBill)}',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Updates a single participant's percentage with validation, then
  /// recalculates all custom amounts so the Kustom tab stays in sync.
  void _updatePercentage(String id, double newPct) {
    // Calculate how much percentage the *other* participants are using.
    double othersPct = 0;
    for (final MapEntry<String, double> entry in _percentages.entries) {
      if (entry.key != id) othersPct += entry.value;
    }

    // Cap so total percentage never exceeds 100%.
    final double maxPct = 100.0 - othersPct;
    final double clampedPct = newPct.clamp(0, maxPct);

    setState(() {
      _percentages[id] = clampedPct;
      _recalculateAmountsFromPercentages();
    });

    if (newPct > maxPct && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Persentase disesuaikan ke ${clampedPct.toStringAsFixed(1)}% '
            'agar total tidak melebihi 100%',
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── Sync & init helpers ────────────────────────────────────────────────

  /// Keeps both maps in sync with the current participant list.
  /// Removes stale entries, adds defaults for new participants.
  void _syncMaps(List<_SettlementFriend> participants) {
    final Set<String> ids = participants
        .map((_SettlementFriend p) => p.id)
        .toSet();
    _customAmounts.removeWhere((String id, double _) => !ids.contains(id));
    _percentages.removeWhere((String id, double _) => !ids.contains(id));

    if (participants.isEmpty) return;

    final double equalAmount = widget.totalBill / participants.length;
    final double equalPct = 100.0 / participants.length;

    for (final _SettlementFriend p in participants) {
      _customAmounts.putIfAbsent(p.id, () => equalAmount);
      _percentages.putIfAbsent(p.id, () => equalPct);
    }
  }

  String _firstNotEmpty(List<Object?> values, {String fallback = 'Teman'}) {
    for (final Object? value in values) {
      final String text = (value ?? '').toString().trim();
      if (text.isNotEmpty) return text;
    }
    return fallback;
  }

  bool _isUuid(String value) {
    return RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    ).hasMatch(value);
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.totalBill, required this.title});

  final double totalBill;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Text(
          'Total Bill ($title)',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: _SplitBillPageState._muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _rupiahFormat.format(totalBill),
          style: const TextStyle(
            color: _SplitBillPageState._ink,
            fontSize: 35,
            fontWeight: FontWeight.w800,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _SegmentedTabs extends StatelessWidget {
  const _SegmentedTabs({required this.selectedIndex, required this.onChanged});

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['Pembagian', 'Presentase', 'Kustom'];

    return Container(
      height: 30,
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: const Color(0xFFE2E3E7),
        borderRadius: BorderRadius.circular(7),
      ),
      child: Row(
        children: <Widget>[
          for (int index = 0; index < labels.length; index++)
            Expanded(
              child: GestureDetector(
                onTap: () => onChanged(index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 160),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selectedIndex == index
                        ? Colors.white
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(5),
                    boxShadow: selectedIndex == index
                        ? <BoxShadow>[
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.06),
                              blurRadius: 6,
                              offset: const Offset(0, 1),
                            ),
                          ]
                        : null,
                  ),
                  child: Text(
                    labels[index],
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: selectedIndex == index
                          ? _SplitBillPageState._primary
                          : const Color(0xFF726D75),
                      fontSize: 9,
                      fontWeight: selectedIndex == index
                          ? FontWeight.w800
                          : FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({
    required this.participants,
    required this.splitAmount,
    required this.percentages,
    required this.customAmounts,
    required this.selectedTabIndex,
    required this.totalBill,
    required this.onEditCustomAmount,
    required this.onEditPercentage,
  });

  final List<_SettlementFriend> participants;
  final double splitAmount;
  final Map<String, double> percentages;
  final Map<String, double> customAmounts;
  final int selectedTabIndex;
  final double totalBill;
  final ValueChanged<_SettlementFriend> onEditCustomAmount;
  final ValueChanged<_SettlementFriend> onEditPercentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SplitBillPageState._line),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: participants.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(
            height: 1,
            color: _SplitBillPageState._line,
            indent: 52,
          );
        },
        itemBuilder: (BuildContext context, int index) {
          final _SettlementFriend friend = participants[index];
          return _ParticipantTile(
            friend: friend,
            amount: _amountFor(friend),
            isCurrentUser: index == 0,
            percentage: percentages[friend.id] ?? 0,
            showPercentage: selectedTabIndex == 1,
            showCustomEdit: selectedTabIndex == 2,
            onEditCustomAmount: () => onEditCustomAmount(friend),
            onEditPercentage: () => onEditPercentage(friend),
          );
        },
      ),
    );
  }

  double _amountFor(_SettlementFriend friend) {
    if (selectedTabIndex == 2) {
      return customAmounts[friend.id] ?? splitAmount;
    }
    if (selectedTabIndex == 1) {
      final double pct = percentages[friend.id] ?? 0;
      return totalBill * pct / 100;
    }
    return splitAmount;
  }
}

class _EmptyParticipantsCard extends StatelessWidget {
  const _EmptyParticipantsCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SplitBillPageState._line),
      ),
      child: const Text(
        'Belum ada anggota aktif di grup ini.',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: _SplitBillPageState._muted,
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.friend,
    required this.amount,
    required this.isCurrentUser,
    required this.percentage,
    required this.showPercentage,
    required this.showCustomEdit,
    required this.onEditCustomAmount,
    required this.onEditPercentage,
  });

  final _SettlementFriend friend;
  final double amount;
  final bool isCurrentUser;
  final double percentage;
  final bool showPercentage;
  final bool showCustomEdit;
  final VoidCallback onEditCustomAmount;
  final VoidCallback onEditPercentage;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: Row(
        children: <Widget>[
          const SizedBox(width: 13),
          _Avatar(friend: friend, isCurrentUser: isCurrentUser),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  friend.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _SplitBillPageState._ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  friend.account,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: _SplitBillPageState._muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (showPercentage) ...<Widget>[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: onEditPercentage,
              child: _PercentagePill(percentage: percentage),
            ),
            const SizedBox(width: 12),
          ],
          Text(
            _rupiahFormat.format(amount),
            style: TextStyle(
              color: isCurrentUser
                  ? _SplitBillPageState._primary
                  : _SplitBillPageState._ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (showCustomEdit)
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: onEditCustomAmount,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 9, vertical: 12),
                child: Icon(Icons.edit, color: Color(0xFF4D4B52), size: 16),
              ),
            )
          else
            const SizedBox(width: 15),
        ],
      ),
    );
  }
}

class _PercentagePill extends StatelessWidget {
  const _PercentagePill({required this.percentage});

  final double percentage;

  @override
  Widget build(BuildContext context) {
    final String label = percentage == percentage.roundToDouble()
        ? percentage.toInt().toString()
        : percentage.toStringAsFixed(1);

    return Container(
      width: 50,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF2F3FF),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(
              color: _SplitBillPageState._ink,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 4),
          const Text(
            '%',
            style: TextStyle(
              color: Color(0xFF64687A),
              fontSize: 10,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.friend, required this.isCurrentUser});

  final _SettlementFriend friend;
  final bool isCurrentUser;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 15,
      backgroundColor: isCurrentUser
          ? const Color(0xFFE8F2F4)
          : const Color(0xFFE8E2D7),
      foregroundImage: friend.avatarUrl.isEmpty
          ? null
          : NetworkImage(friend.avatarUrl),
      child: Text(
        friend.name.characters.first.toUpperCase(),
        style: const TextStyle(
          color: _SplitBillPageState._primary,
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _AddFriendButton extends StatelessWidget {
  const _AddFriendButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
        child: Row(
          children: <Widget>[
            Container(
              width: 24,
              height: 24,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: Color(0xFFFFECEE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add,
                color: _SplitBillPageState._primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'TAMBAH TEMAN',
              style: TextStyle(
                color: _SplitBillPageState._primary,
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _SplitBillPageState._primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        onPressed: onPressed,
        child: const Text(
          'KIRIM',
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _SettlementFriend {
  const _SettlementFriend({
    required this.id,
    required this.name,
    required this.account,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String account;
  final String avatarUrl;
}

