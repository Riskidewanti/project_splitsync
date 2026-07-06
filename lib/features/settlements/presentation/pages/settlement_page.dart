import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final NumberFormat _rupiahFormat = NumberFormat.currency(
  locale: 'id_ID',
  symbol: 'Rp ',
  decimalDigits: 0,
);

class SettlementPage extends StatefulWidget {
  const SettlementPage({
    super.key,
    this.groupId = '',
    this.userId = '',
    this.totalBill = 124500,
    this.billTitle = 'Minta Pembayaran',
  });

  final String groupId;
  final String userId;
  final double totalBill;
  final String billTitle;

  @override
  State<SettlementPage> createState() => _SettlementPageState();
}

class _SettlementPageState extends State<SettlementPage> {
  static const Color _primary = Color(0xFFC8101B);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF8A8282);
  static const Color _surface = Color(0xFFFFFAF7);
  static const Color _line = Color(0xFFE8E8EC);

  final List<_SettlementFriend> _friends = <_SettlementFriend>[];
  int _selectedTabIndex = 0;
  bool _isLoading = true;

  /// Per-friend percentage values for the "Presentase" tab.
  final Map<String, double> _percentages = <String, double>{};

  /// Per-friend custom amounts for the "Kustom" tab.
  final Map<String, double> _customAmounts = <String, double>{};

  @override
  void initState() {
    super.initState();
    _loadFriendsFromSupabase();
  }

  Future<void> _loadFriendsFromSupabase() async {
    setState(() => _isLoading = true);

    if (!_isUuid(widget.groupId) || !_isUuid(widget.userId)) {
      setState(() => _isLoading = false);
      return;
    }

    try {
      final List<dynamic> rows = await _fetchFriendRows();
      final List<_SettlementFriend> friends = rows
          .map((dynamic row) => row as Map<String, dynamic>)
          .map(_friendFromRow)
          .whereType<_SettlementFriend>()
          .toList();

      if (!mounted) return;
      setState(() {
        _friends
          ..clear()
          ..addAll(friends);
        _isLoading = false;
        _initPerFriendMaps();
      });
    } catch (error) {
      debugPrint('Error fetching settlement friends: $error');
      if (!mounted) return;
      setState(() => _isLoading = false);
    }
  }

  Future<List<dynamic>> _fetchFriendRows() async {
    try {
      return await Supabase.instance.client
          .from('group_members')
          .select(
            'id,user_id,status,profiles:user_id(full_name,display_name,name,avatar_url,photo_url)',
          )
          .eq('group_id', widget.groupId)
          .eq('status', 'active')
          .neq('user_id', widget.userId);
    } catch (_) {
      return await Supabase.instance.client
          .from('group_members')
          .select()
          .eq('group_id', widget.groupId)
          .eq('status', 'active')
          .neq('user_id', widget.userId);
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
        profileMap?['full_name'],
        profileMap?['display_name'],
        profileMap?['name'],
        row['name'],
        'Teman ${id.length >= 4 ? id.substring(0, 4) : id}',
      ]),
      avatarUrl: _firstNotEmpty(<Object?>[
        profileMap?['avatar_url'],
        profileMap?['photo_url'],
        row['avatar_url'],
      ], fallback: ''),
    );
  }

  /// Initialises per-friend percentage and custom amount maps with sensible
  /// defaults whenever the friend list changes.
  void _initPerFriendMaps() {
    final List<_SettlementFriend> all = _allParticipants;
    final double equalPercent =
        all.isEmpty ? 0 : (100.0 / all.length);
    final double equalAmount =
        all.isEmpty ? 0 : (widget.totalBill / all.length);

    for (final _SettlementFriend f in all) {
      _percentages.putIfAbsent(f.id, () => equalPercent);
      _customAmounts.putIfAbsent(f.id, () => equalAmount);
    }
  }

  List<_SettlementFriend> get _allParticipants => <_SettlementFriend>[
        const _SettlementFriend(id: 'current-user', name: 'You', avatarUrl: ''),
        ..._friends,
      ];

  /// Returns the split_method string for the currently selected tab.
  String get _splitMethod {
    switch (_selectedTabIndex) {
      case 1:
        return 'percentage';
      case 2:
        return 'exact';
      default:
        return 'equal';
    }
  }

  /// Recalculates every participant's percentage from their custom amount.
  /// Formula: percentage = (exact_amount / total_bill) * 100
  void _recalculatePercentages() {
    if (widget.totalBill <= 0) return;
    for (final _SettlementFriend f in _allParticipants) {
      final double amount = _customAmounts[f.id] ?? 0;
      _percentages[f.id] = (amount / widget.totalBill) * 100;
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
      _recalculatePercentages();
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

  @override
  Widget build(BuildContext context) {
    final List<_SettlementFriend> participants = _allParticipants;
    final bool hasFriends = _friends.isNotEmpty;
    final double splitAmount = widget.totalBill / participants.length;

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
                    if (hasFriends) ...<Widget>[
                      // ── Tab Content ───────────────────────────
                      _buildTabContent(participants, splitAmount),
                      const SizedBox(height: 14),
                    ],
                    _AddFriendButton(onTap: _showAddFriendDialog),
                    const Spacer(),
                    _SubmitButton(onPressed: _handleSubmit),
                  ],
                ),
              ),
      ),
    );
  }

  /// Builds the correct list card depending on which tab is active.
  Widget _buildTabContent(
    List<_SettlementFriend> participants,
    double equalSplitAmount,
  ) {
    switch (_selectedTabIndex) {
      // ── Tab 1 : Presentase ────────────────────────────────────
      case 1:
        return _PercentageCard(
          participants: participants,
          totalBill: widget.totalBill,
          percentages: _percentages,
          onPercentageChanged: (String id, double value) {
            setState(() => _percentages[id] = value);
          },
        );
      // ── Tab 2 : Kustom ────────────────────────────────────────
      case 2:
        return _CustomAmountCard(
          participants: participants,
          totalBill: widget.totalBill,
          customAmounts: _customAmounts,
          onAmountChanged: _updateCustomAmount,
        );
      // ── Tab 0 : Pembagian (default – equal split) ─────────────
      default:
        return _ParticipantsCard(
          participants: participants,
          splitAmount: equalSplitAmount,
        );
    }
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
                  final _SettlementFriend newFriend = _SettlementFriend(
                    id: DateTime.now().microsecondsSinceEpoch.toString(),
                    name: name,
                    avatarUrl: '',
                  );
                  _friends.add(newFriend);
                  _initPerFriendMaps();
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

  void _handleSubmit() {
    debugPrint('split_method: $_splitMethod');
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Settlement berhasil dikirim (split_method: $_splitMethod)',
        ),
      ),
    );
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

// ─────────────────────────────────────────────────────────────────────────────
// Shared Widgets
// ─────────────────────────────────────────────────────────────────────────────

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
            color: _SettlementPageState._muted,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          _rupiahFormat.format(totalBill),
          style: const TextStyle(
            color: _SettlementPageState._ink,
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
                          ? _SettlementPageState._primary
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

// ─────────────────────────────────────────────────────────────────────────────
// Tab 0 – Pembagian (Equal Split)
// ─────────────────────────────────────────────────────────────────────────────

class _ParticipantsCard extends StatelessWidget {
  const _ParticipantsCard({
    required this.participants,
    required this.splitAmount,
  });

  final List<_SettlementFriend> participants;
  final double splitAmount;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: participants.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(
            height: 1,
            color: _SettlementPageState._line,
            indent: 52,
          );
        },
        itemBuilder: (BuildContext context, int index) {
          return _ParticipantTile(
            friend: participants[index],
            amount: splitAmount,
            isCurrentUser: index == 0,
          );
        },
      ),
    );
  }
}

class _ParticipantTile extends StatelessWidget {
  const _ParticipantTile({
    required this.friend,
    required this.amount,
    required this.isCurrentUser,
  });

  final _SettlementFriend friend;
  final double amount;
  final bool isCurrentUser;

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
            child: Text(
              friend.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: _SettlementPageState._ink,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(
            _rupiahFormat.format(amount),
            style: TextStyle(
              color: isCurrentUser
                  ? _SettlementPageState._primary
                  : _SettlementPageState._ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 15),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 1 – Presentase (Percentage Split)
// ─────────────────────────────────────────────────────────────────────────────

class _PercentageCard extends StatelessWidget {
  const _PercentageCard({
    required this.participants,
    required this.totalBill,
    required this.percentages,
    required this.onPercentageChanged,
  });

  final List<_SettlementFriend> participants;
  final double totalBill;
  final Map<String, double> percentages;
  final void Function(String id, double value) onPercentageChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: participants.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(
            height: 1,
            color: _SettlementPageState._line,
            indent: 52,
          );
        },
        itemBuilder: (BuildContext context, int index) {
          final _SettlementFriend friend = participants[index];
          final double pct = percentages[friend.id] ?? 0;
          final double amount = totalBill * pct / 100;

          return SizedBox(
            height: 62,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 13),
                _Avatar(friend: friend, isCurrentUser: index == 0),
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
                          color: _SettlementPageState._ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _rupiahFormat.format(amount),
                        style: const TextStyle(
                          color: _SettlementPageState._muted,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  width: 60,
                  child: TextField(
                    controller: TextEditingController(
                      text: pct == pct.roundToDouble()
                          ? pct.toInt().toString()
                          : pct.toStringAsFixed(1),
                    ),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: index == 0
                          ? _SettlementPageState._primary
                          : _SettlementPageState._ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                    decoration: const InputDecoration(
                      isDense: true,
                      contentPadding:
                          EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                      suffixText: '%',
                      suffixStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _SettlementPageState._muted,
                      ),
                      border: OutlineInputBorder(),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _SettlementPageState._line,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: _SettlementPageState._primary,
                        ),
                      ),
                    ),
                    onChanged: (String value) {
                      final double? parsed = double.tryParse(value);
                      if (parsed != null) {
                        onPercentageChanged(friend.id, parsed);
                      }
                    },
                  ),
                ),
                const SizedBox(width: 15),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Tab 2 – Kustom (Custom / Exact Amounts)
// ─────────────────────────────────────────────────────────────────────────────

class _CustomAmountCard extends StatelessWidget {
  const _CustomAmountCard({
    required this.participants,
    required this.totalBill,
    required this.customAmounts,
    required this.onAmountChanged,
  });

  final List<_SettlementFriend> participants;
  final double totalBill;
  final Map<String, double> customAmounts;
  final void Function(String id, double value) onAmountChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: _cardDecoration(),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: participants.length,
        separatorBuilder: (BuildContext context, int index) {
          return const Divider(
            height: 1,
            color: _SettlementPageState._line,
            indent: 52,
          );
        },
        itemBuilder: (BuildContext context, int index) {
          final _SettlementFriend friend = participants[index];
          final double amount = customAmounts[friend.id] ?? 0;

          return SizedBox(
            height: 58,
            child: Row(
              children: <Widget>[
                const SizedBox(width: 13),
                _Avatar(friend: friend, isCurrentUser: index == 0),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    friend.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SettlementPageState._ink,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                Text(
                  _rupiahFormat.format(amount),
                  style: TextStyle(
                    color: index == 0
                        ? _SettlementPageState._primary
                        : _SettlementPageState._ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                // Pencil icon to edit nominal
                IconButton(
                  icon: const Icon(Icons.edit, size: 16),
                  color: _SettlementPageState._muted,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 28, minHeight: 28),
                  splashRadius: 18,
                  onPressed: () => _showEditDialog(context, friend, amount),
                ),
                const SizedBox(width: 8),
              ],
            ),
          );
        },
      ),
    );
  }

  void _showEditDialog(
    BuildContext context,
    _SettlementFriend friend,
    double currentAmount,
  ) {
    // Calculate the maximum this person can be assigned.
    double othersTotal = 0;
    for (final MapEntry<String, double> entry in customAmounts.entries) {
      if (entry.key != friend.id) othersTotal += entry.value;
    }
    final double maxForThisPerson = totalBill - othersTotal;

    final TextEditingController controller = TextEditingController(
      text: currentAmount.toInt().toString(),
    );

    showDialog<void>(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: Text('Edit nominal – ${friend.name}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              TextField(
                controller: controller,
                autofocus: true,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  prefixText: 'Rp ',
                  hintText: 'Masukkan nominal',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Maks: ${_rupiahFormat.format(maxForThisPerson)}',
                style: const TextStyle(
                  fontSize: 11,
                  color: _SettlementPageState._muted,
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
                final double? parsed = double.tryParse(controller.text.trim());
                if (parsed != null) {
                  onAmountChanged(friend.id, parsed);
                }
                Navigator.pop(dialogContext);
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared Helper Widgets & Utilities
// ─────────────────────────────────────────────────────────────────────────────

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
          color: _SettlementPageState._primary,
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
                color: _SettlementPageState._primary,
                size: 16,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              'TAMBAH TEMAN',
              style: TextStyle(
                color: _SettlementPageState._primary,
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

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _SettlementPageState._primary,
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
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String avatarUrl;
}

/// Shared card decoration used by all three tab cards.
BoxDecoration _cardDecoration() {
  return BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(8),
    border: Border.all(color: _SettlementPageState._line),
    boxShadow: <BoxShadow>[
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.035),
        blurRadius: 16,
        offset: const Offset(0, 8),
      ),
    ],
  );
}
