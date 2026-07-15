import 'package:flutter/material.dart';

import '../../../groups/data/datasources/group_remote_data_source.dart';
import '../../../groups/data/models/group_model.dart';
import '../../../groups/data/repositories/group_repository_impl.dart';
import '../../../groups/presentation/pages/create_group_page.dart';
import '../../../ocr/presentation/pages/edit_items_page.dart';

class SplitBillGroupSelectionResult {
  const SplitBillGroupSelectionResult({
    required this.groupId,
    required this.userId,
  });

  final String groupId;
  final String userId;
}

class SplitBillGroupSelectionPage extends StatefulWidget {
  const SplitBillGroupSelectionPage({
    super.key,
    required this.totalBill,
    required this.billTitle,
    required this.itemCount,
    required this.subtotal,
    required this.taxAmount,
    required this.serviceFee,
    required this.items,
    this.category = 'Belanja',
  });

  final double totalBill;
  final String billTitle;
  final int itemCount;
  final double subtotal;
  final double taxAmount;
  final double serviceFee;
  final String category;
  final List<ReceiptItem> items;

  @override
  State<SplitBillGroupSelectionPage> createState() =>
      _SplitBillGroupSelectionPageState();
}

class _SplitBillGroupSelectionPageState
    extends State<SplitBillGroupSelectionPage> {
  static const Color _primary = Color(0xFFC8101B);
  static const Color _ink = Color(0xFF111827);
  static const Color _muted = Color(0xFF6F6868);
  static const Color _surface = Color(0xFFFFFAF7);
  static const Color _line = Color(0xFFE7E7EB);

  final GroupRepositoryImpl _groupRepository = GroupRepositoryImpl(
    remoteDataSource: GroupRemoteDataSourceImpl(),
  );

  List<_GroupChoiceData> _groups = const <_GroupChoiceData>[];
  String? _currentUserId;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String? currentUserId = await _groupRepository.getCurrentUserId();
      if (currentUserId == null || currentUserId.isEmpty) {
        throw const FormatException('Akun aktif belum ditemukan.');
      }

      final List<GroupModel> groups = await _groupRepository.getGroups();
      final List<_GroupChoiceData> groupChoices = await Future.wait(
        groups.map((GroupModel group) async {
          final int memberCount = await _groupRepository
              .getGroupMembers(group.id)
              .then((members) => members.length)
              .catchError((_) => 0);
          return _GroupChoiceData(group: group, memberCount: memberCount);
        }),
      );

      if (!mounted) return;
      setState(() {
        _currentUserId = currentUserId;
        _groups = groupChoices;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  Future<void> _openCreateGroup() async {
    final Object? created = await Navigator.of(
      context,
    ).push(MaterialPageRoute<bool>(builder: (_) => const CreateGroupPage()));

    if (!mounted || created != true) return;
    await _loadGroups();
  }

  void _openSplitBill(GroupModel group) {
    final String? currentUserId = _currentUserId;
    if (currentUserId == null || currentUserId.isEmpty) return;

    Navigator.of(context).pop(
      SplitBillGroupSelectionResult(groupId: group.id, userId: currentUserId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        toolbarHeight: 95,
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 1,
        shadowColor: Colors.black.withValues(alpha: 0.08),
        leadingWidth: 82,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, size: 26),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: const Text(
          'SplitSync',
          style: TextStyle(
            color: _primary,
            fontSize: 30,
            fontWeight: FontWeight.w800,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: _primary,
          onRefresh: _loadGroups,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(38, 64, 38, 32),
            children: <Widget>[
              const Text(
                'Pilih Grup',
                style: TextStyle(
                  color: Color(0xFF7E0010),
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Sinkronkan pengeluaran bersama teman\n'
                'dengan mudah, dengan pilih grup yang sudah\n'
                'ada atau buat grup baru.',
                style: TextStyle(
                  color: _muted,
                  fontSize: 21,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 58),
              SizedBox(
                height: 72,
                child: FilledButton.icon(
                  onPressed: _openCreateGroup,
                  style: FilledButton.styleFrom(
                    backgroundColor: _primary,
                    foregroundColor: Colors.white,
                    elevation: 6,
                    shadowColor: Colors.black.withValues(alpha: 0.22),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(36),
                    ),
                  ),
                  icon: const Icon(Icons.add, size: 30),
                  label: const Text(
                    'Buat Grup Baru',
                    style: TextStyle(fontSize: 23, fontWeight: FontWeight.w500),
                  ),
                ),
              ),
              const SizedBox(height: 36),
              if (_isLoading)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 70),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _GroupSelectionMessage(
                  message: 'Gagal memuat grup: $_error',
                  buttonLabel: 'Coba Lagi',
                  onPressed: _loadGroups,
                )
              else if (_groups.isEmpty)
                _GroupSelectionMessage(
                  message: 'Belum ada grup yang kamu ikuti.',
                  buttonLabel: 'Buat Grup',
                  onPressed: _openCreateGroup,
                )
              else
                Column(
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Expanded(
                          child: Text(
                            'GRUP ANDA',
                            style: TextStyle(
                              color: Color(0xFF756D70),
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 3.2,
                            ),
                          ),
                        ),
                        Text(
                          '${_groups.length} Grup Aktif',
                          style: const TextStyle(
                            color: _muted,
                            fontSize: 21,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: _line),
                        boxShadow: <BoxShadow>[
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.025),
                            blurRadius: 14,
                            offset: const Offset(0, 7),
                          ),
                        ],
                      ),
                      child: Column(
                        children: <Widget>[
                          for (int index = 0; index < _groups.length; index++)
                            _GroupChoiceTile(
                              data: _groups[index],
                              showDivider: index != _groups.length - 1,
                              onTap: () => _openSplitBill(_groups[index].group),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _GroupChoiceData {
  const _GroupChoiceData({required this.group, required this.memberCount});

  final GroupModel group;
  final int memberCount;
}

class _GroupChoiceTile extends StatelessWidget {
  const _GroupChoiceTile({
    required this.data,
    required this.showDivider,
    required this.onTap,
  });

  final _GroupChoiceData data;
  final bool showDivider;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final GroupModel group = data.group;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 118,
        padding: const EdgeInsets.fromLTRB(40, 18, 28, 18),
        decoration: BoxDecoration(
          border: showDivider
              ? const Border(
                  bottom: BorderSide(
                    color: _SplitBillGroupSelectionPageState._line,
                  ),
                )
              : null,
        ),
        child: Row(
          children: <Widget>[
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: const Color(0xFFF7EFF0),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                _iconForGroup(group.name),
                color: _SplitBillGroupSelectionPageState._primary,
                size: 31,
              ),
            ),
            const SizedBox(width: 26),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    group.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SplitBillGroupSelectionPageState._ink,
                      fontSize: 23,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${data.memberCount} Anggota',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: _SplitBillGroupSelectionPageState._muted,
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF5F5A5D), size: 34),
          ],
        ),
      ),
    );
  }

  IconData _iconForGroup(String name) {
    final String lowerName = name.toLowerCase();
    if (lowerName.contains('trip') || lowerName.contains('travel')) {
      return Icons.flight_takeoff_rounded;
    }
    if (lowerName.contains('apart') || lowerName.contains('home')) {
      return Icons.apartment_rounded;
    }
    if (lowerName.contains('makan') ||
        lowerName.contains('food') ||
        lowerName.contains('dinner')) {
      return Icons.restaurant_rounded;
    }
    return Icons.groups_2_rounded;
  }
}

class _GroupSelectionMessage extends StatelessWidget {
  const _GroupSelectionMessage({
    required this.message,
    required this.buttonLabel,
    required this.onPressed,
  });

  final String message;
  final String buttonLabel;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 24, 18, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _SplitBillGroupSelectionPageState._line),
      ),
      child: Column(
        children: <Widget>[
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: _SplitBillGroupSelectionPageState._muted,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          TextButton(onPressed: onPressed, child: Text(buttonLabel)),
        ],
      ),
    );
  }
}
