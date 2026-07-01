import 'package:flutter/material.dart';

import 'friend_request_service.dart';
import 'friends_list_page.dart';

class AddFriendsPage extends StatefulWidget {
  const AddFriendsPage({super.key});

  @override
  State<AddFriendsPage> createState() => _AddFriendsPageState();
}

class _AddFriendsPageState extends State<AddFriendsPage> {
  final _searchController = TextEditingController();
  late Future<List<FriendProfile>> _recommendationsFuture;
  FriendProfile? _selectedFriend;
  FriendProfile? _sentFriend;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _recommendationsFuture = FriendRequestService.recommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _searchFriend(String value) async {
    final friend = await FriendRequestService.findFriend(value);
    if (!mounted) return;
    setState(() => _selectedFriend = friend);
    if (friend == null && value.trim().isNotEmpty) {
      _showMessage('User tidak ditemukan.');
    }
  }

  Future<void> _sendRequest({FriendProfile? friend}) async {
    if (_sending) return;
    var target = friend ?? _selectedFriend;
    final query = _searchController.text.trim();
    if (target == null && query.isEmpty) {
      _showMessage('Masukkan ID atau username terlebih dahulu.');
      return;
    }

    setState(() => _sending = true);
    try {
      if (target != null) {
        await FriendRequestService.sendRequestToProfile(target.id);
      } else {
        target = await FriendRequestService.sendRequest(query);
      }
      if (!mounted) return;
      setState(() {
        _sentFriend = FriendProfile(
          id: target!.id,
          name: target.name,
          handle: target.handle,
          avatarUrl: target.avatarUrl,
          email: target.email,
          sent: true,
        );
        _selectedFriend = _sentFriend;
        _recommendationsFuture = FriendRequestService.recommendations();
      });
    } catch (error) {
      _showMessage(error.toString());
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: const Color(0xFF9A0010),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_sentFriend != null) {
      return _RequestSentPage(
        friend: _sentFriend!,
        onDone: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          }
        },
        onInviteAnother: () {
          setState(() {
            _sentFriend = null;
            _selectedFriend = null;
            _searchController.clear();
            _recommendationsFuture = FriendRequestService.recommendations();
          });
        },
      );
    }

    final layout = _FriendRequestLayout.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        const _RequestHeader(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            layout.pagePadding,
                            layout.space(38),
                            layout.pagePadding,
                            layout.space(118),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _SearchBox(
                                    controller: _searchController,
                                    onSubmitted: _searchFriend,
                                  ),
                                  SizedBox(height: layout.space(28)),
                                  const _FriendsListShortcut(),
                                  if (_selectedFriend != null) ...[
                                    SizedBox(height: layout.space(28)),
                                    _FriendTile(
                                      friend: _selectedFriend!,
                                      onAdd: _selectedFriend!.sent
                                          ? null
                                          : () => _sendRequest(
                                              friend: _selectedFriend,
                                            ),
                                    ),
                                  ],
                                  SizedBox(height: layout.space(36)),
                                  FutureBuilder<List<FriendProfile>>(
                                    future: _recommendationsFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return Center(
                                          child: Padding(
                                            padding: EdgeInsets.all(
                                              layout.space(18),
                                            ),
                                            child:
                                                const CircularProgressIndicator(
                                                  color: Color(0xFFC8152B),
                                                ),
                                          ),
                                        );
                                      }

                                      final friends = snapshot.data ?? const [];
                                      if (friends.isEmpty) {
                                        return const SizedBox.shrink();
                                      }

                                      return _RecommendationList(
                                        friends: friends,
                                        onAdd: (friend) =>
                                            _sendRequest(friend: friend),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                padding: EdgeInsets.fromLTRB(
                  layout.pagePadding,
                  layout.space(14),
                  layout.pagePadding,
                  layout.space(22),
                ),
                color: const Color(0xFFFFFBF8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: _RequestButton(
                      sending: _sending,
                      onPressed: _sendRequest,
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
}

class _FriendRequestLayout {
  const _FriendRequestLayout(this.size);

  final Size size;

  static _FriendRequestLayout of(BuildContext context) {
    return _FriendRequestLayout(MediaQuery.sizeOf(context));
  }

  bool get isNarrow => size.width < 380;

  double get scale {
    final widthScale = size.width / 393;
    final heightScale = size.height / 852;
    return (widthScale < heightScale ? widthScale : heightScale).clamp(
      0.82,
      1.08,
    );
  }

  double get pagePadding => isNarrow ? 20 : 24;

  double space(double value) => value * scale;

  double font(double value) {
    final factor = isNarrow ? scale * 0.92 : scale;
    return (value * factor).clamp(value * 0.82, value * 1.08);
  }
}

class _RequestSentPage extends StatelessWidget {
  const _RequestSentPage({
    required this.friend,
    required this.onDone,
    required this.onInviteAnother,
  });

  final FriendProfile friend;
  final VoidCallback onDone;
  final VoidCallback onInviteAnother;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendRequestLayout.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        bottom: false,
        child: Stack(
          children: [
            LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: Column(
                      children: [
                        const _RequestHeader(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            layout.pagePadding,
                            layout.space(70),
                            layout.pagePadding,
                            layout.space(196),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Column(
                                children: [
                                  Container(
                                    width: layout.space(112).clamp(92, 116),
                                    height: layout.space(112).clamp(92, 116),
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFA4161D),
                                      shape: BoxShape.circle,
                                      boxShadow: [
                                        BoxShadow(
                                          color: Color(0x22A4161D),
                                          blurRadius: 30,
                                          offset: Offset(0, 14),
                                        ),
                                      ],
                                    ),
                                    child: Icon(
                                      Icons.check_rounded,
                                      color: Colors.white,
                                      size: layout.space(68).clamp(52, 70),
                                    ),
                                  ),
                                  SizedBox(height: layout.space(38)),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Friend Request Sent',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(
                                        color: const Color(0xFF8F0010),
                                        fontSize: layout.font(43),
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: layout.space(22)),
                                  Text(
                                    'Undangan telah dikirim kepada ${friend.name}.\n'
                                    'Anda akan menerima notifikasi\n'
                                    'setelah undangan diterima.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: const Color(0xFF68625F),
                                      fontSize: layout.font(22),
                                      fontWeight: FontWeight.w500,
                                      height: 1.45,
                                    ),
                                  ),
                                  SizedBox(height: layout.space(56)),
                                  _PendingFriendCard(friend: friend),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 0,
              child: Container(
                color: const Color(0xFFFFFBF8),
                padding: EdgeInsets.fromLTRB(
                  layout.pagePadding,
                  layout.space(14),
                  layout.pagePadding,
                  layout.space(28),
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: double.infinity,
                          height: layout.space(64).clamp(56, 66),
                          child: FilledButton(
                            onPressed: onDone,
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF8F0010),
                              foregroundColor: Colors.white,
                              textStyle: TextStyle(
                                fontSize: layout.font(20),
                                fontWeight: FontWeight.w900,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: const Text('Selesai'),
                          ),
                        ),
                        SizedBox(height: layout.space(18)),
                        SizedBox(
                          width: double.infinity,
                          height: layout.space(64).clamp(56, 66),
                          child: OutlinedButton(
                            onPressed: onInviteAnother,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF8F0010),
                              side: const BorderSide(
                                color: Color(0xFFE3B9B9),
                                width: 1.4,
                              ),
                              textStyle: TextStyle(
                                fontSize: layout.font(20),
                                fontWeight: FontWeight.w800,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(32),
                              ),
                            ),
                            child: const Text('Undang teman lain'),
                          ),
                        ),
                      ],
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
}

class _PendingFriendCard extends StatelessWidget {
  const _PendingFriendCard({required this.friend});

  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendRequestLayout.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.space(24).clamp(18, 24)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(friend: friend),
          SizedBox(width: layout.space(22).clamp(14, 22)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF111B2C),
                    fontSize: layout.font(26),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: layout.space(4)),
                Text(
                  friend.handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF68625F),
                    fontSize: layout.font(18),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: layout.space(12)),
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: layout.space(18).clamp(14, 20),
              vertical: layout.space(10).clamp(8, 11),
            ),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F1F1),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Text(
              'PENDING',
              style: TextStyle(
                color: const Color(0xFF68625F),
                fontSize: layout.font(16),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RequestHeader extends StatelessWidget {
  const _RequestHeader();

  @override
  Widget build(BuildContext context) {
    final layout = _FriendRequestLayout.of(context);
    return Container(
      height: layout.space(116).clamp(94, 118),
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: layout.space(28).clamp(20, 30)),
      child: Row(
        children: [
          IconButton(
            onPressed: () {
              if (Navigator.of(context).canPop()) Navigator.of(context).pop();
            },
            icon: Icon(
              Icons.arrow_back_rounded,
              size: layout.space(32).clamp(27, 33),
              color: const Color(0xFF111B2C),
            ),
          ),
          SizedBox(width: layout.space(78).clamp(46, 86)),
          Expanded(
            child: Text(
              'Request',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF111B2C),
                fontSize: layout.font(29),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchBox extends StatelessWidget {
  const _SearchBox({required this.controller, required this.onSubmitted});

  final TextEditingController controller;
  final ValueChanged<String> onSubmitted;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendRequestLayout.of(context);
    return TextField(
      controller: controller,
      textInputAction: TextInputAction.search,
      onSubmitted: onSubmitted,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.search_rounded,
          color: const Color(0xFF806E6E),
          size: layout.space(30).clamp(25, 31),
        ),
        hintText: 'Cari dengan nama atau namapengguna',
        hintStyle: TextStyle(
          color: const Color(0xFF8B8585),
          fontSize: layout.font(20),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: layout.space(18),
          vertical: layout.space(24).clamp(18, 24),
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class _FriendsListShortcut extends StatelessWidget {
  const _FriendsListShortcut();

  @override
  Widget build(BuildContext context) {
    final layout = _FriendRequestLayout.of(context);
    return InkWell(
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const FriendsListPage()));
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.fromLTRB(
          layout.space(24).clamp(18, 26),
          layout.space(22).clamp(18, 24),
          layout.space(22).clamp(16, 24),
          layout.space(22).clamp(18, 24),
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFF0DADA)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 12,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: layout.space(64).clamp(52, 66),
              height: layout.space(64).clamp(52, 66),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD3D3),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.groups_2_rounded,
                color: const Color(0xFF8F0010),
                size: layout.space(34).clamp(28, 36),
              ),
            ),
            SizedBox(width: layout.space(24).clamp(16, 24)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Lihat Daftar Teman',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF8F0010),
                      fontSize: layout.font(25),
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  SizedBox(height: layout.space(6)),
                  Text(
                    'Kelola dan lihat semua teman yang\nsudah terhubung',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF5F4444),
                      fontSize: layout.font(18),
                      fontWeight: FontWeight.w500,
                      height: 1.35,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: layout.space(12)),
            Icon(
              Icons.chevron_right_rounded,
              color: const Color(0xFF8E7474),
              size: layout.space(34).clamp(28, 36),
            ),
          ],
        ),
      ),
    );
  }
}

class _RecommendationList extends StatelessWidget {
  const _RecommendationList({required this.friends, required this.onAdd});

  final List<FriendProfile> friends;
  final ValueChanged<FriendProfile> onAdd;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendRequestLayout.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Disarankan',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: const Color(0xFF111B2C),
                  fontSize: layout.font(27),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            Text(
              'Lihat Kontak',
              style: TextStyle(
                color: const Color(0xFF8F0010),
                fontSize: layout.font(18),
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
        SizedBox(height: layout.space(24)),
        ...friends.map(
          (friend) => Padding(
            padding: EdgeInsets.only(bottom: layout.space(18)),
            child: _FriendTile(
              friend: friend,
              onAdd: friend.sent ? null : () => onAdd(friend),
            ),
          ),
        ),
      ],
    );
  }
}

class _FriendTile extends StatelessWidget {
  const _FriendTile({required this.friend, required this.onAdd});

  final FriendProfile friend;
  final VoidCallback? onAdd;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendRequestLayout.of(context);
    final sent = friend.sent || onAdd == null;
    return Container(
      padding: EdgeInsets.all(layout.space(18).clamp(14, 18)),
      decoration: BoxDecoration(
        color: sent ? const Color(0xFFF2F1FF) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          _Avatar(friend: friend),
          SizedBox(width: layout.space(18).clamp(12, 18)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF111B2C),
                    fontSize: layout.font(23),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: layout.space(3)),
                Text(
                  friend.handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF625D5D),
                    fontSize: layout.font(17),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: layout.space(12).clamp(8, 12)),
          sent
              ? Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: layout.space(18).clamp(14, 22),
                    vertical: layout.space(12).clamp(10, 13),
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE6C7C7),
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.check_rounded,
                        color: const Color(0xFF8F3939),
                        size: layout.space(18).clamp(15, 18),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Terkirim',
                        style: TextStyle(
                          color: const Color(0xFF8F3939),
                          fontSize: layout.font(17),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                )
              : FilledButton(
                  onPressed: onAdd,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF8F0010),
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: layout.space(28).clamp(18, 28),
                      vertical: layout.space(14).clamp(11, 14),
                    ),
                    textStyle: TextStyle(
                      fontSize: layout.font(17),
                      fontWeight: FontWeight.w800,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(22),
                    ),
                  ),
                  child: const Text('Tambah'),
                ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.friend});

  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendRequestLayout.of(context);
    final size = layout.space(64).clamp(52, 64).toDouble();
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: const Color(0xFFECE6E6),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFFDADA), width: 2),
            image: friend.avatarUrl.isEmpty
                ? null
                : DecorationImage(
                    image: NetworkImage(friend.avatarUrl),
                    fit: BoxFit.cover,
                  ),
          ),
          child: friend.avatarUrl.isEmpty
              ? Center(
                  child: Text(
                    friend.initials,
                    style: TextStyle(
                      color: const Color(0xFF625D5D),
                      fontSize: layout.font(18),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                )
              : null,
        ),
        if (!friend.sent)
          Positioned(
            right: 2,
            bottom: 0,
            child: Container(
              width: layout.space(16).clamp(13, 16),
              height: layout.space(16).clamp(13, 16),
              decoration: BoxDecoration(
                color: const Color(0xFF18C769),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }
}

class _RequestButton extends StatelessWidget {
  const _RequestButton({required this.sending, required this.onPressed});

  final bool sending;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendRequestLayout.of(context);
    return SizedBox(
      width: double.infinity,
      height: layout.space(68).clamp(58, 70),
      child: FilledButton.icon(
        onPressed: sending ? null : onPressed,
        icon: sending
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Icon(Icons.send_rounded, size: layout.space(30).clamp(24, 30)),
        label: FittedBox(child: Text(sending ? 'Mengirim' : 'Kirim Request')),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF8F0010),
          disabledBackgroundColor: const Color(0xFF8F0010),
          foregroundColor: Colors.white,
          textStyle: TextStyle(
            fontSize: layout.font(26),
            fontWeight: FontWeight.w900,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(34),
          ),
        ),
      ),
    );
  }
}
