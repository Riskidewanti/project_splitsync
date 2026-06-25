import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SettlementPage extends StatefulWidget {
  const SettlementPage({
    super.key,
    this.groupId = '',
    this.userId = '',
    this.totalBill = 124.50,
    this.billTitle = "Dinner at Luigi's",
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

  @override
  Widget build(BuildContext context) {
    final List<_SettlementFriend> participants = <_SettlementFriend>[
      const _SettlementFriend(id: 'current-user', name: 'You', avatarUrl: ''),
      ..._friends,
    ];
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
                      _ParticipantsCard(
                        participants: participants,
                        splitAmount: splitAmount,
                      ),
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
                  _friends.add(
                    _SettlementFriend(
                      id: DateTime.now().microsecondsSinceEpoch.toString(),
                      name: name,
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

  void _handleSubmit() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settlement berhasil dikirim')),
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
          _formatCurrency(totalBill),
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
      decoration: BoxDecoration(
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
      ),
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
            _formatCurrency(amount),
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
      height: 45,
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: _SettlementPageState._primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
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
