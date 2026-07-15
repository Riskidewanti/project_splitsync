import 'package:flutter/material.dart';

import 'add_friends_page.dart';
import 'friend_request_service.dart';

class FriendsListPage extends StatefulWidget {
  const FriendsListPage({super.key});

  @override
  State<FriendsListPage> createState() => _FriendsListPageState();
}

class _FriendsListPageState extends State<FriendsListPage> {
  final _searchController = TextEditingController();
  late Future<List<FriendProfile>> _friendsFuture;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _friendsFuture = FriendRequestService.friends();
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _reload() async {
    setState(() => _friendsFuture = FriendRequestService.friends());
  }

  Future<void> _removeFriend(FriendProfile friend) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Hapus teman?'),
          content: Text('${friend.name} akan dihapus dari daftar teman.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    try {
      await FriendRequestService.removeFriend(friend.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Teman berhasil dihapus.'),
          backgroundColor: Color(0xFF9A0010),
        ),
      );
      _reload();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFF9A0010),
        ),
      );
    }
  }

  void _inviteAnother() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const AddFriendsPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final layout = _FriendsLayout.of(context);
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
                        const _FriendsHeader(),
                        Padding(
                          padding: EdgeInsets.fromLTRB(
                            layout.pagePadding,
                            layout.space(38),
                            layout.pagePadding,
                            layout.space(112),
                          ),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _FriendsSearchBox(
                                    controller: _searchController,
                                  ),
                                  SizedBox(height: layout.space(42)),
                                  FutureBuilder<List<FriendProfile>>(
                                    future: _friendsFuture,
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(
                                            color: Color(0xFFC8152B),
                                          ),
                                        );
                                      }

                                      if (snapshot.hasError) {
                                        return _FriendsEmptyState(
                                          text: snapshot.error.toString(),
                                        );
                                      }

                                      final allFriends =
                                          snapshot.data ?? const [];
                                      final visibleFriends = allFriends.where((
                                        friend,
                                      ) {
                                        if (_query.isEmpty) return true;
                                        return friend.name
                                                .toLowerCase()
                                                .contains(_query) ||
                                            friend.handle
                                                .toLowerCase()
                                                .contains(_query);
                                      }).toList();

                                      return Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'SEMUA TEMAN (${allFriends.length})',
                                            style: TextStyle(
                                              color: const Color(0xFF5F4444),
                                              fontSize: layout.font(20),
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          SizedBox(height: layout.space(18)),
                                          if (visibleFriends.isEmpty)
                                            const _FriendsEmptyState(
                                              text:
                                                  'Belum ada teman yang cocok.',
                                            )
                                          else
                                            ...visibleFriends.map(
                                              (friend) => Padding(
                                                padding: EdgeInsets.only(
                                                  bottom: layout.space(16),
                                                ),
                                                child: _FriendListTile(
                                                  friend: friend,
                                                  onDelete: () =>
                                                      _removeFriend(friend),
                                                ),
                                              ),
                                            ),
                                        ],
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
                  layout.space(28),
                ),
                color: const Color(0xFFFFFBF8),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: SizedBox(
                      width: double.infinity,
                      height: layout.space(64).clamp(56, 66),
                      child: FilledButton(
                        onPressed: _inviteAnother,
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
                        child: const Text('Undang Teman Lain'),
                      ),
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

class _FriendsLayout {
  const _FriendsLayout(this.size);

  final Size size;

  static _FriendsLayout of(BuildContext context) {
    return _FriendsLayout(MediaQuery.sizeOf(context));
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

  double get pagePadding => isNarrow ? 20 : 28;

  double space(double value) => value * scale;

  double font(double value) {
    final factor = isNarrow ? scale * 0.92 : scale;
    return (value * factor).clamp(value * 0.82, value * 1.08);
  }
}

class _FriendsHeader extends StatelessWidget {
  const _FriendsHeader();

  @override
  Widget build(BuildContext context) {
    final layout = _FriendsLayout.of(context);
    return Container(
      height: layout.space(116).clamp(94, 118),
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: layout.space(28).clamp(20, 30)),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: layout.space(32).clamp(27, 33),
              color: const Color(0xFF111B2C),
            ),
          ),
          SizedBox(width: layout.space(54).clamp(28, 62)),
          Expanded(
            child: Text(
              'Daftar Teman',
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

class _FriendsSearchBox extends StatelessWidget {
  const _FriendsSearchBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendsLayout.of(context);
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        prefixIcon: Icon(
          Icons.search_rounded,
          color: const Color(0xFF5F4444),
          size: layout.space(32).clamp(26, 34),
        ),
        hintText: 'Cari nama atau username...',
        hintStyle: TextStyle(
          color: const Color(0xFF697080),
          fontSize: layout.font(20),
          fontWeight: FontWeight.w500,
        ),
        filled: true,
        fillColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(
          horizontal: layout.space(18),
          vertical: layout.space(24).clamp(18, 24),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFE1D7D2)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFF9A0010)),
        ),
      ),
    );
  }
}

class _FriendListTile extends StatelessWidget {
  const _FriendListTile({required this.friend, required this.onDelete});

  final FriendProfile friend;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendsLayout.of(context);
    return Container(
      padding: EdgeInsets.all(layout.space(18).clamp(14, 18)),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _FriendAvatar(friend: friend),
          SizedBox(width: layout.space(20).clamp(14, 22)),
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
                    fontSize: layout.font(22),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: layout.space(4)),
                Text(
                  friend.handle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF5F4444),
                    fontSize: layout.font(20),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onDelete,
            icon: Icon(
              Icons.delete_outline_rounded,
              color: const Color(0xFF8F1D1D),
              size: layout.space(31).clamp(26, 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _FriendAvatar extends StatelessWidget {
  const _FriendAvatar({required this.friend});

  final FriendProfile friend;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendsLayout.of(context);
    final size = layout.space(64).clamp(52, 66).toDouble();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: const Color(0xFFECE6E6),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFFFD3D3), width: 2),
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
    );
  }
}

class _FriendsEmptyState extends StatelessWidget {
  const _FriendsEmptyState({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final layout = _FriendsLayout.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(layout.space(22)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFF5F4444),
          fontSize: layout.font(16),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
