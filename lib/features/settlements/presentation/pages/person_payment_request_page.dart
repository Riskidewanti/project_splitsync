import 'package:flutter/material.dart';

import '../../../../add_friends_page.dart';
import '../../../../friend_request_service.dart';
import '../../../../core/utils/currency_formatter.dart';

class PersonPaymentRequestPage extends StatefulWidget {
  const PersonPaymentRequestPage({super.key});

  @override
  State<PersonPaymentRequestPage> createState() =>
      _PersonPaymentRequestPageState();
}

class _PersonPaymentRequestPageState extends State<PersonPaymentRequestPage> {
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF8E7F7F);
  static const Color _surface = Color(0xFFFFFAF7);

  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _noteController = TextEditingController();

  late Future<List<FriendProfile>> _friendsFuture;
  FriendProfile? _selectedFriend;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _friendsFuture = FriendRequestService.friends();
    _amountController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  double get _amount => _parseCurrencyInput(_amountController.text);

  Future<void> _reloadFriends() async {
    setState(() => _friendsFuture = FriendRequestService.friends());
    await _friendsFuture;
  }

  Future<void> _openAddFriend() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute<void>(builder: (_) => const AddFriendsPage()));
    if (mounted) await _reloadFriends();
  }

  Future<void> _showAllFriends(List<FriendProfile> friends) async {
    if (friends.isEmpty) {
      await _openAddFriend();
      return;
    }

    final FriendProfile? selected = await showModalBottomSheet<FriendProfile>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: ListView.separated(
            shrinkWrap: true,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            itemCount: friends.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Pilih Teman',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }

              final FriendProfile friend = friends[index - 1];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: _FriendAvatar(friend: friend, selected: false),
                title: Text(
                  friend.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(friend.handle),
                onTap: () => Navigator.of(context).pop(friend),
              );
            },
          ),
        );
      },
    );

    if (selected != null) {
      setState(() => _selectedFriend = selected);
    }
  }

  Future<void> _editAmount() async {
    final TextEditingController controller = TextEditingController(
      text: _amountController.text,
    );

    final String? value = await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Masukkan jumlah'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              prefixText: 'Rp ',
              border: OutlineInputBorder(),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(controller.text),
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );

    controller.dispose();
    if (value != null) {
      _amountController.text = value;
    }
  }

  Future<void> _submitRequest() async {
    if (_isSubmitting) return;

    final FriendProfile? friend = _selectedFriend;
    if (friend == null) {
      _showMessage('Pilih teman terlebih dahulu.');
      return;
    }

    if (_amount <= 0) {
      _showMessage('Masukkan nominal request yang valid.');
      return;
    }

    setState(() => _isSubmitting = true);
    await Future<void>.delayed(const Duration(milliseconds: 350));

    if (!mounted) return;
    setState(() => _isSubmitting = false);
    _showMessage('Request pembayaran dikirim ke ${friend.name}.');
    Navigator.of(context).maybePop(true);
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final _RequestLayout layout = _RequestLayout.of(context);
    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const _RequestHeader(),
            Expanded(
              child: FutureBuilder<List<FriendProfile>>(
                future: _friendsFuture,
                builder:
                    (
                      BuildContext context,
                      AsyncSnapshot<List<FriendProfile>> snapshot,
                    ) {
                      final List<FriendProfile> friends =
                          snapshot.data ?? const <FriendProfile>[];

                      return SingleChildScrollView(
                        padding: EdgeInsets.fromLTRB(
                          layout.pagePadding,
                          layout.space(26),
                          layout.pagePadding,
                          layout.space(84),
                        ),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 430),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  'Request Uang',
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: layout.font(28),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: layout.space(8)),
                                Text(
                                  'Minta dana dari grup atau teman Anda.',
                                  style: TextStyle(
                                    color: _muted,
                                    fontSize: layout.font(17),
                                    fontWeight: FontWeight.w400,
                                  ),
                                ),
                                SizedBox(height: layout.space(28)),
                                _AmountCard(
                                  amount: _amount,
                                  onTap: _editAmount,
                                ),
                                SizedBox(height: layout.space(26)),
                                _FriendsPicker(
                                  friends: friends,
                                  selectedFriend: _selectedFriend,
                                  isLoading:
                                      snapshot.connectionState ==
                                      ConnectionState.waiting,
                                  errorMessage: snapshot.error?.toString(),
                                  onAddFriend: _openAddFriend,
                                  onViewAll: () => _showAllFriends(friends),
                                  onSelect: (FriendProfile friend) {
                                    setState(() => _selectedFriend = friend);
                                  },
                                ),
                                SizedBox(height: layout.space(26)),
                                Text(
                                  'Untuk apa?',
                                  style: TextStyle(
                                    color: _ink,
                                    fontSize: layout.font(20),
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(height: layout.space(14)),
                                _NoteBox(controller: _noteController),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
              ),
            ),
            _SubmitBar(isLoading: _isSubmitting, onSubmit: _submitRequest),
          ],
        ),
      ),
    );
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: IconButton(
              onPressed: () => Navigator.of(context).maybePop(),
              icon: const Icon(
                Icons.arrow_back,
                color: _PersonPaymentColors.ink,
              ),
              iconSize: 28,
            ),
          ),
          const Text(
            'Request',
            style: TextStyle(
              color: _PersonPaymentColors.ink,
              fontSize: 24,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _AmountCard extends StatelessWidget {
  const _AmountCard({required this.amount, required this.onTap});

  final double amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final _RequestLayout layout = _RequestLayout.of(context);
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.fromLTRB(
            layout.space(20),
            layout.space(24),
            layout.space(20),
            layout.space(26),
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _PersonPaymentColors.line),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.025),
                blurRadius: 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: <Widget>[
              Text(
                'MASUKKAN JUMLAH',
                style: TextStyle(
                  color: const Color(0xFF5D4747),
                  fontSize: layout.font(14),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: layout.space(18)),
              SizedBox(
                height: layout.clamp(58, 48, 62),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: <Widget>[
                      Text(
                        'Rp',
                        style: TextStyle(
                          color: _PersonPaymentColors.primary,
                          fontSize: layout.font(38),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(width: layout.space(22)),
                      Text(
                        amount <= 0 ? '0.000' : _amountLabel(amount),
                        style: TextStyle(
                          color: const Color(0xFF737B8B),
                          fontSize: layout.font(48),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: layout.space(8)),
              Text(
                'Ketuk untuk mengubah nominal',
                style: TextStyle(
                  color: const Color(0xFF9B8E8E),
                  fontSize: layout.font(12),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FriendsPicker extends StatelessWidget {
  const _FriendsPicker({
    required this.friends,
    required this.selectedFriend,
    required this.isLoading,
    required this.errorMessage,
    required this.onAddFriend,
    required this.onViewAll,
    required this.onSelect,
  });

  final List<FriendProfile> friends;
  final FriendProfile? selectedFriend;
  final bool isLoading;
  final String? errorMessage;
  final VoidCallback onAddFriend;
  final VoidCallback onViewAll;
  final ValueChanged<FriendProfile> onSelect;

  @override
  Widget build(BuildContext context) {
    final _RequestLayout layout = _RequestLayout.of(context);
    final List<FriendProfile> previewFriends = friends.take(3).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              'Dari',
              style: TextStyle(
                color: _PersonPaymentColors.ink,
                fontSize: layout.font(19),
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: onViewAll,
              child: Text(
                'Lihat semuanya',
                style: TextStyle(
                  color: _PersonPaymentColors.primary,
                  fontSize: layout.font(16),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        SizedBox(height: layout.space(14)),
        if (isLoading)
          const SizedBox(
            height: 94,
            child: Center(
              child: CircularProgressIndicator(
                color: _PersonPaymentColors.primary,
              ),
            ),
          )
        else if (errorMessage != null)
          _InlineMessage(message: errorMessage!)
        else
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: <Widget>[
                _AddFriendCircle(onTap: onAddFriend),
                for (final FriendProfile friend in previewFriends)
                  Padding(
                    padding: const EdgeInsets.only(left: 18),
                    child: _FriendChoice(
                      friend: friend,
                      selected: selectedFriend?.id == friend.id,
                      onTap: () => onSelect(friend),
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _AddFriendCircle extends StatelessWidget {
  const _AddFriendCircle({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFFF0DDDD),
                  width: 2,
                  strokeAlign: BorderSide.strokeAlignInside,
                ),
              ),
              child: const Icon(
                Icons.add,
                color: _PersonPaymentColors.ink,
                size: 30,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tambah',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Color(0xFF5B4646),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendChoice extends StatelessWidget {
  const _FriendChoice({
    required this.friend,
    required this.selected,
    required this.onTap,
  });

  final FriendProfile friend;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 70,
        child: Column(
          children: <Widget>[
            Stack(
              clipBehavior: Clip.none,
              children: <Widget>[
                _FriendAvatar(friend: friend, selected: selected),
                if (selected)
                  Positioned(
                    right: -1,
                    bottom: -1,
                    child: Container(
                      width: 25,
                      height: 25,
                      decoration: BoxDecoration(
                        color: _PersonPaymentColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Colors.white,
                        size: 16,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              _shortName(friend.name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: selected
                    ? _PersonPaymentColors.ink
                    : const Color(0xFF5B4646),
                fontSize: 15,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.friend, required this.selected});

  final FriendProfile friend;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 58,
      padding: EdgeInsets.all(selected ? 2 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: _PersonPaymentColors.primary, width: 2.5)
            : null,
      ),
      child: CircleAvatar(
        backgroundColor: const Color(0xFFE6E3E1),
        backgroundImage: friend.avatarUrl.isEmpty
            ? null
            : NetworkImage(friend.avatarUrl),
        child: friend.avatarUrl.isEmpty
            ? Text(
                friend.initials,
                style: const TextStyle(
                  color: _PersonPaymentColors.ink,
                  fontWeight: FontWeight.w800,
                ),
              )
            : null,
      ),
    );
  }
}

class _NoteBox extends StatelessWidget {
  const _NoteBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final _RequestLayout layout = _RequestLayout.of(context);
    return Container(
      height: layout.clamp(140, 124, 152),
      padding: const EdgeInsets.fromLTRB(18, 10, 16, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _PersonPaymentColors.line),
      ),
      child: Column(
        children: <Widget>[
          Expanded(
            child: TextField(
              controller: controller,
              maxLines: null,
              expands: true,
              textAlignVertical: TextAlignVertical.top,
              decoration: InputDecoration(
                border: InputBorder.none,
                hintText: 'Tambahkan catatan (e.g. Dinner at Lo Jules Verne)',
                hintStyle: TextStyle(
                  color: const Color(0xFFB8B0B0),
                  fontSize: layout.font(16),
                  height: 1.5,
                ),
              ),
              style: TextStyle(
                color: _PersonPaymentColors.ink,
                fontSize: layout.font(15),
                height: 1.4,
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: const <Widget>[
              Icon(Icons.mood_outlined, color: Color(0xFF9B8E8E), size: 26),
              SizedBox(width: 18),
              Icon(Icons.attach_file, color: Color(0xFF9B8E8E), size: 27),
            ],
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.isLoading, required this.onSubmit});

  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final _RequestLayout layout = _RequestLayout.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        layout.pagePadding,
        14,
        layout.pagePadding,
        layout.space(18),
      ),
      color: const Color(0xFFFEFCFF),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 430),
          child: SizedBox(
            width: double.infinity,
            height: layout.clamp(58, 54, 62),
            child: FilledButton.icon(
              onPressed: isLoading ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: _PersonPaymentColors.primary,
                disabledBackgroundColor: _PersonPaymentColors.primary
                    .withValues(alpha: 0.55),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              icon: isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.send, size: 26),
              label: Text(
                isLoading ? 'Mengirim...' : 'Kirim Request',
                style: TextStyle(
                  fontSize: layout.font(22),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InlineMessage extends StatelessWidget {
  const _InlineMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _PersonPaymentColors.line),
      ),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: _PersonPaymentColors.muted,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _PersonPaymentColors {
  const _PersonPaymentColors._();

  static const Color primary = Color(0xFF8D000B);
  static const Color ink = Color(0xFF111827);
  static const Color muted = Color(0xFF8E7F7F);
  static const Color line = Color(0xFFF0E7E7);
}

class _RequestLayout {
  const _RequestLayout(this.size);

  final Size size;

  factory _RequestLayout.of(BuildContext context) {
    return _RequestLayout(MediaQuery.sizeOf(context));
  }

  double get pagePadding => clamp(24, 20, 28);

  double font(double value) => clamp(value, value * 0.88, value * 1.04);

  double space(double value) => clamp(value, value * 0.78, value * 1.08);

  double clamp(double value, double min, double max) {
    final double scaled = value * (size.width / 390);
    return scaled.clamp(min, max).toDouble();
  }
}

double _parseCurrencyInput(String value) {
  final String normalized = value
      .replaceAll(RegExp(r'[^0-9,\.]'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
}

String _amountLabel(double amount) {
  return formatRupiah(amount).replaceFirst('Rp', '').trim();
}

String _shortName(String name) {
  final List<String> parts = name.trim().split(RegExp(r'\s+'));
  if (parts.isEmpty || parts.first.isEmpty) return 'Teman';
  if (parts.length == 1) return parts.first;
  return '${parts.first} ${parts.last.substring(0, 1)}.';
}
