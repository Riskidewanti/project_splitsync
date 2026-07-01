import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/auth_service.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../features/groups/data/datasources/group_remote_data_source.dart';
import '../../features/groups/data/models/group_member_model.dart';
import '../../features/groups/data/models/group_model.dart';
import '../../features/groups/data/repositories/group_repository_impl.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/groups/presentation/widgets/group_card.dart';
import '../../widgets/responsive.dart';
import '../profile_setting/profile_settings_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GroupRepositoryImpl _groupRepository = GroupRepositoryImpl(
    remoteDataSource: GroupRemoteDataSourceImpl(),
  );
  final SupabaseClient _client = Supabase.instance.client;

  late Future<List<_HomeGroupData>> _groupsFuture;
  late Future<_HomeDashboardData> _dashboardFuture;

  @override
  void initState() {
    super.initState();
    _groupsFuture = _loadGroups();
    _dashboardFuture = _loadDashboardData();
  }

  Future<List<_HomeGroupData>> _loadGroups() async {
    final List<GroupModel> groups = await _groupRepository.getGroups();
    return Future.wait(groups.take(2).map(_buildGroupData));
  }

  Future<_HomeDashboardData> _loadDashboardData() async {
    final SessionProfile? session = await AuthService.currentSession();
    final String? currentUserId = session?.id;
    if (currentUserId == null || currentUserId.trim().isEmpty) {
      throw const AuthException('Akun aktif belum ditemukan.');
    }

    final List<GroupModel> groups = await _groupRepository.getGroups();
    final List<String> groupIds = groups
        .map((GroupModel group) => group.id)
        .toList();

    final double debtAmount = await _loadCurrentUserDebt(currentUserId);
    final double paidByUser = groupIds.isEmpty
        ? 0
        : await _loadUserPaidTotal(groupIds, currentUserId);
    final List<_HomeActivityData> activities = groupIds.isEmpty
        ? const <_HomeActivityData>[]
        : await _loadRecentActivities(groupIds, currentUserId);

    return _HomeDashboardData(
      cleanBalance: paidByUser - debtAmount,
      receivableAmount: paidByUser,
      debtAmount: debtAmount,
      activities: activities,
    );
  }

  Future<double> _loadCurrentUserDebt(String currentUserId) async {
    try {
      final List<dynamic> rows = await _client
          .from('split_bill')
          .select('exact_amount,is_paid')
          .eq('user_id', currentUserId)
          .eq('is_paid', false)
          .gt('exact_amount', 0);

      return rows.fold<double>(0, (double total, dynamic row) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(row as Map);
        return total + _asDouble(data['exact_amount']);
      });
    } catch (error) {
      final String message = error.toString();
      if (!message.contains('is_paid')) rethrow;

      final List<dynamic> rows = await _client
          .from('split_bill')
          .select('exact_amount')
          .eq('user_id', currentUserId)
          .gt('exact_amount', 0);

      return rows.fold<double>(0, (double total, dynamic row) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(row as Map);
        return total + _asDouble(data['exact_amount']);
      });
    }
  }

  Future<double> _loadUserPaidTotal(
    List<String> groupIds,
    String currentUserId,
  ) async {
    final List<dynamic> rows = await _client
        .from('expenses')
        .select('total_amount')
        .inFilter('group_id', groupIds)
        .eq('payer_id', currentUserId);

    return rows.fold<double>(0, (double total, dynamic row) {
      final Map<String, dynamic> data = Map<String, dynamic>.from(row as Map);
      return total + _asDouble(data['total_amount']);
    });
  }

  Future<List<_HomeActivityData>> _loadRecentActivities(
    List<String> groupIds,
    String currentUserId,
  ) async {
    final List<dynamic> rows = await _client
        .from('expenses')
        .select(
          'id,group_id,payer_id,title,merchant_name,total_amount,created_at,expense_date',
        )
        .inFilter('group_id', groupIds)
        .order('created_at', ascending: false)
        .limit(3);

    final Map<String, String> groupNames = <String, String>{
      for (final GroupModel group in await _groupRepository.getGroups())
        group.id: group.name,
    };

    return rows
        .map((dynamic row) {
          return _HomeActivityData.fromRow(
            Map<String, dynamic>.from(row as Map),
            currentUserId: currentUserId,
            groupNames: groupNames,
          );
        })
        .toList(growable: false);
  }

  Future<_HomeGroupData> _buildGroupData(GroupModel group) async {
    final List<GroupMemberModel> members = await _groupRepository
        .getGroupMembers(group.id);
    return _HomeGroupData(group: group, members: members);
  }

  void _openGroupDetail(GroupModel group) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailPage(groupId: group.id),
      ),
    );
  }

  void _openSplitBillOcr() {
    Navigator.of(context).pushNamed('/scan');
  }

  Future<void> _openManualExpense() async {
    try {
      final String? currentUserId = await _groupRepository.getCurrentUserId();
      if (!mounted) return;

      if (currentUserId == null || currentUserId.trim().isEmpty) {
        _showHomeMessage('Silakan masuk untuk menambah pengeluaran.');
        return;
      }

      final List<GroupModel> groups = await _groupRepository.getGroups();
      if (!mounted) return;

      if (groups.isEmpty) {
        _showHomeMessage(
          'Buat grup terlebih dahulu sebelum menambah pengeluaran.',
        );
        return;
      }

      final GroupModel? selectedGroup = groups.length == 1
          ? groups.first
          : await _selectGroupForExpense(groups);
      if (selectedGroup == null || !mounted) return;

      final List<GroupMemberModel> groupMembers = await _groupRepository
          .getGroupMembers(selectedGroup.id);
      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => AddExpensePage(
            groupId: selectedGroup.id,
            groupName: selectedGroup.name,
            userId: currentUserId,
            members: groupMembers
                .where((GroupMemberModel member) {
                  return member.status == GroupMemberStatus.active &&
                      member.userId != currentUserId;
                })
                .map(_expenseMemberFromGroupMember)
                .toList(),
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      _showHomeMessage('Gagal membuka tambah pengeluaran: $error');
    }
  }

  Future<GroupModel?> _selectGroupForExpense(List<GroupModel> groups) {
    return showModalBottomSheet<GroupModel>(
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
            itemCount: groups.length + 1,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (BuildContext context, int index) {
              if (index == 0) {
                return const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: Text(
                    'Pilih Grup',
                    style: TextStyle(
                      color: Color(0xFF111B2C),
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                );
              }

              final GroupModel group = groups[index - 1];
              return ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(
                  Icons.groups_outlined,
                  color: Color(0xFFC8152B),
                ),
                title: Text(
                  group.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(_subtitleFor(group)),
                onTap: () => Navigator.of(context).pop(group),
              );
            },
          ),
        );
      },
    );
  }

  Member _expenseMemberFromGroupMember(GroupMemberModel member) {
    return Member(
      id: member.userId,
      name: _memberName(member),
      avatarUrl: member.avatarUrl ?? '',
    );
  }

  void _showHomeMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  String _memberName(GroupMemberModel member) {
    final String? displayName = member.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) return displayName;
    final String? email = member.email?.trim();
    if (email != null && email.isNotEmpty) return email;
    return 'Member ${member.userId.substring(0, 8)}';
  }

  List<String> _memberInitials(List<GroupMemberModel> members) {
    final List<String> initials = members.take(3).map((
      GroupMemberModel member,
    ) {
      final String name = _memberName(member).trim();
      return name.isEmpty ? '?' : name.characters.first.toUpperCase();
    }).toList();
    return initials.isEmpty ? const <String>['?'] : initials;
  }

  String _subtitleFor(GroupModel group) {
    final DateTime createdAt = group.createdAt.toLocal();
    return 'Dibuat ${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  IconData _iconForGroup(String name) {
    final String lowerName = name.toLowerCase();
    if (lowerName.contains('trip') || lowerName.contains('travel')) {
      return Icons.flight_takeoff;
    }
    if (lowerName.contains('home') || lowerName.contains('apartment')) {
      return Icons.apartment;
    }
    if (lowerName.contains('food') || lowerName.contains('dinner')) {
      return Icons.restaurant;
    }
    return Icons.groups_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        child: Column(
          children: [
            _Header(responsive: responsive),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  responsive.clamp(30, 20, 34),
                  responsive.space(28),
                  responsive.clamp(30, 20, 34),
                  responsive.space(26),
                ),
                child: ResponsivePage(
                  maxWidth: 430,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _BalanceCard(dataFuture: _dashboardFuture),
                      SizedBox(height: responsive.space(22)),
                      _QuickActions(onAddExpense: _openManualExpense),
                      SizedBox(height: responsive.space(26)),
                      _SectionTitle(
                        title: 'Grup Teratas',
                        action: 'Lihat Semua',
                        titleSize: responsive.font(26),
                        onAction: () =>
                            Navigator.of(context).pushNamed('/groups'),
                      ),
                      SizedBox(height: responsive.space(22)),
                      _TopGroups(
                        groupsFuture: _groupsFuture,
                        onOpenGroup: _openGroupDetail,
                        subtitleFor: _subtitleFor,
                        iconForGroup: _iconForGroup,
                        memberInitials: _memberInitials,
                      ),
                      SizedBox(height: responsive.space(26)),
                      _ActivityPanel(dataFuture: _dashboardFuture),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(
        onCreateSplit: _openSplitBillOcr,
        onProfile: () {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute<void>(builder: (_) => ProfileSettingsPage()),
          );
        },
      ),
    );
  }
}

class _HomeGroupData {
  const _HomeGroupData({required this.group, required this.members});

  final GroupModel group;
  final List<GroupMemberModel> members;
}

class _HomeDashboardData {
  const _HomeDashboardData({
    required this.cleanBalance,
    required this.receivableAmount,
    required this.debtAmount,
    required this.activities,
  });

  final double cleanBalance;
  final double receivableAmount;
  final double debtAmount;
  final List<_HomeActivityData> activities;
}

class _HomeActivityData {
  const _HomeActivityData({
    required this.title,
    required this.groupName,
    required this.amount,
    required this.createdAt,
    required this.isPaidByCurrentUser,
  });

  final String title;
  final String groupName;
  final double amount;
  final DateTime createdAt;
  final bool isPaidByCurrentUser;

  factory _HomeActivityData.fromRow(
    Map<String, dynamic> row, {
    required String currentUserId,
    required Map<String, String> groupNames,
  }) {
    final String groupId = (row['group_id'] ?? '').toString();
    final String title = _firstFilledString(<Object?>[
      row['merchant_name'],
      row['title'],
      'Pengeluaran',
    ]);
    final DateTime createdAt =
        _asDateTime(row['created_at']) ??
        _asDateTime(row['expense_date']) ??
        DateTime.now();

    return _HomeActivityData(
      title: title,
      groupName: groupNames[groupId] ?? 'Grup',
      amount: _asDouble(row['total_amount']),
      createdAt: createdAt,
      isPaidByCurrentUser: (row['payer_id'] ?? '').toString() == currentUserId,
    );
  }
}

double _asDouble(Object? value) {
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? 0;
  return 0;
}

DateTime? _asDateTime(Object? value) {
  if (value is DateTime) return value;
  if (value is String && value.isNotEmpty) return DateTime.tryParse(value);
  return null;
}

String _firstFilledString(List<Object?> values) {
  for (final Object? value in values) {
    final String text = (value ?? '').toString().trim();
    if (text.isNotEmpty) return text;
  }

  return '';
}

class _Header extends StatelessWidget {
  const _Header({required this.responsive});

  final Responsive responsive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: responsive.clamp(112, 96, 116),
      padding: EdgeInsets.symmetric(horizontal: responsive.clamp(30, 24, 34)),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x11000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Text(
            'SplitSync',
            style: TextStyle(
              color: const Color(0xFFC8152B),
              fontSize: responsive.font(30),
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          IconButton(
            onPressed: () => Navigator.of(context).pushNamed('/notifications'),
            icon: Icon(
              Icons.notifications_none_rounded,
              color: const Color(0xFF4B3333),
              size: responsive.clamp(30, 26, 32),
            ),
          ),
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.dataFuture});

  final Future<_HomeDashboardData> dataFuture;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        responsive.clamp(24, 18, 24),
        responsive.clamp(28, 22, 30),
        responsive.clamp(24, 18, 24),
        responsive.clamp(26, 20, 26),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFA4161D),
        borderRadius: BorderRadius.circular(16),
      ),
      child: FutureBuilder<_HomeDashboardData>(
        future: dataFuture,
        builder:
            (BuildContext context, AsyncSnapshot<_HomeDashboardData> snapshot) {
              final _HomeDashboardData data =
                  snapshot.data ??
                  const _HomeDashboardData(
                    cleanBalance: 0,
                    receivableAmount: 0,
                    debtAmount: 0,
                    activities: <_HomeActivityData>[],
                  );

              return Column(
                children: [
                  Text(
                    'Total Saldo Bersih',
                    style: TextStyle(
                      color: const Color(0xFFDFA5A8),
                      fontSize: responsive.font(17),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: responsive.space(10)),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 11),
                      child: CircularProgressIndicator(color: Colors.white),
                    )
                  else
                    FittedBox(
                      child: Text(
                        formatRupiah(data.cleanBalance),
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: responsive.font(46),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  SizedBox(height: responsive.space(24)),
                  Row(
                    children: [
                      Expanded(
                        child: _BalanceMiniCard(
                          color: const Color(0xFF8C0010),
                          title: 'Hutang ke Anda',
                          value: formatRupiah(data.receivableAmount),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _BalanceMiniCard(
                          color: const Color(0xFF26384B),
                          title: 'Hutang Kamu',
                          value: formatRupiah(data.debtAmount),
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
      ),
    );
  }
}

class _BalanceMiniCard extends StatelessWidget {
  const _BalanceMiniCard({
    required this.color,
    required this.title,
    required this.value,
  });

  final Color color;
  final String title;
  final String value;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      padding: EdgeInsets.all(responsive.clamp(16, 12, 17)),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white,
              fontSize: responsive.font(14),
            ),
          ),
          SizedBox(height: responsive.space(8)),
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.font(24),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickActions extends StatelessWidget {
  const _QuickActions({required this.onAddExpense});

  final VoidCallback onAddExpense;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final itemWidth = constraints.maxWidth >= 350
            ? (constraints.maxWidth - 30) / 4
            : (constraints.maxWidth - 10) / 2;
        return Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _QuickAction(
              width: itemWidth,
              icon: Icons.receipt_long_outlined,
              label: 'Tambah\nPengeluaran',
              iconBg: const Color(0xFFFFD9DC),
              iconColor: const Color(0xFF9A0010),
              onTap: onAddExpense,
            ),
            _QuickAction(
              width: itemWidth,
              icon: Icons.payments_outlined,
              label: 'Lunasi\nTagihan',
              onTap: () => Navigator.of(context).pushNamed('/settlements'),
            ),
            _QuickAction(
              width: itemWidth,
              icon: Icons.request_quote_outlined,
              label: 'Minta\nPembayaran',
            ),
            _QuickAction(
              width: itemWidth,
              icon: Icons.view_agenda_outlined,
              label: 'Split\nBill',
              onTap: () => Navigator.of(context).pushNamed('/scan'),
            ),
          ],
        );
      },
    );
  }
}

class _QuickAction extends StatelessWidget {
  const _QuickAction({
    required this.icon,
    required this.label,
    required this.width,
    this.iconBg = const Color(0xFFDCEBFF),
    this.iconColor = const Color(0xFF0D213A),
    this.onTap,
  });

  final IconData icon;
  final String label;
  final double width;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return SizedBox(
      width: width,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          height: responsive.clamp(124, 116, 128),
          padding: EdgeInsets.symmetric(
            horizontal: responsive.space(7),
            vertical: responsive.space(13),
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE0E0E0)),
            boxShadow: const [
              BoxShadow(
                color: Color(0x10000000),
                blurRadius: 8,
                offset: Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              CircleAvatar(
                radius: responsive.clamp(23, 20, 24),
                backgroundColor: iconBg,
                child: Icon(
                  icon,
                  color: iconColor,
                  size: responsive.clamp(27, 23, 28),
                ),
              ),
              SizedBox(height: responsive.space(8)),
              Expanded(
                child: Center(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF0D213A),
                      fontSize: responsive.font(13),
                      fontWeight: FontWeight.w900,
                      height: 1.18,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.titleSize,
    this.onAction,
  });

  final String title;
  final String action;
  final double titleSize;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Row(
      children: [
        Text(
          title,
          style: TextStyle(
            color: const Color(0xFF111B2C),
            fontSize: titleSize,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        GestureDetector(
          onTap: onAction,
          child: Text(
            action,
            style: TextStyle(
              color: const Color(0xFF9A0010),
              fontSize: responsive.font(16),
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

class _TopGroups extends StatelessWidget {
  const _TopGroups({
    required this.groupsFuture,
    required this.onOpenGroup,
    required this.subtitleFor,
    required this.iconForGroup,
    required this.memberInitials,
  });

  final Future<List<_HomeGroupData>> groupsFuture;
  final ValueChanged<GroupModel> onOpenGroup;
  final String Function(GroupModel group) subtitleFor;
  final IconData Function(String name) iconForGroup;
  final List<String> Function(List<GroupMemberModel> members) memberInitials;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<_HomeGroupData>>(
      future: groupsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return _HomeGroupsError(message: snapshot.error.toString());
        }

        final List<_HomeGroupData> groups =
            snapshot.data ?? const <_HomeGroupData>[];
        if (groups.isEmpty) {
          return GroupEmptyState();
        }

        final List<_HomeGroupData> topGroups = groups.take(2).toList();

        return Column(
          children: [
            for (int index = 0; index < topGroups.length; index++) ...[
              InkWell(
                borderRadius: BorderRadius.circular(8),
                onTap: () => onOpenGroup(topGroups[index].group),
                child: GroupCard(
                  title: topGroups[index].group.name,
                  subtitle: subtitleFor(topGroups[index].group),
                  amount: 0,
                  statusLabel: 'Belum ada saldo',
                  statusStyle: GroupCardStatusStyle.gray,
                  icon: iconForGroup(topGroups[index].group.name),
                  memberInitials: memberInitials(topGroups[index].members),
                  extraMemberCount: topGroups[index].members.length > 3
                      ? topGroups[index].members.length - 3
                      : 0,
                ),
              ),
              if (index != topGroups.length - 1) const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _HomeGroupsError extends StatelessWidget {
  const _HomeGroupsError({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.clamp(18, 14, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Text(
        'Gagal memuat grup: $message',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFF5E5656),
          fontSize: responsive.font(13),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class GroupEmptyState extends StatelessWidget {
  const GroupEmptyState({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(responsive.clamp(18, 14, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_outlined,
            color: const Color(0xFFC8152B),
            size: responsive.clamp(42, 36, 44),
          ),
          SizedBox(height: responsive.space(10)),
          Text(
            'Belum ada grup untuk ditampilkan.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF5E5656),
              fontSize: responsive.font(14),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel({required this.dataFuture});

  final Future<_HomeDashboardData> dataFuture;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      padding: EdgeInsets.fromLTRB(
        responsive.clamp(24, 18, 24),
        responsive.clamp(26, 20, 26),
        responsive.clamp(24, 18, 24),
        responsive.clamp(24, 18, 24),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E4)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: FutureBuilder<_HomeDashboardData>(
        future: dataFuture,
        builder:
            (BuildContext context, AsyncSnapshot<_HomeDashboardData> snapshot) {
              final List<_HomeActivityData> activities =
                  snapshot.data?.activities ?? const <_HomeActivityData>[];

              return Column(
                children: [
                  _SectionTitle(
                    title: 'Aktivitas Terbaru',
                    action: 'Lihat semua',
                    titleSize: responsive.font(24),
                  ),
                  SizedBox(height: responsive.space(26)),
                  if (snapshot.connectionState == ConnectionState.waiting)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 28),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else if (snapshot.hasError)
                    const _ActivityMessage(message: 'Gagal memuat aktivitas.')
                  else if (activities.isEmpty)
                    const _ActivityMessage(
                      message: 'Belum ada aktivitas terbaru.',
                    )
                  else
                    for (final _HomeActivityData activity in activities)
                      _ActivityRow(
                        icon: _activityIcon(activity.title),
                        bg: activity.isPaidByCurrentUser
                            ? const Color(0xFFD7E7FF)
                            : const Color(0xFFFFD9DC),
                        title: activity.title,
                        subtitle:
                            '${activity.groupName}\n${_relativeTime(activity.createdAt)}',
                        amount: formatRupiah(activity.amount),
                        status: activity.isPaidByCurrentUser
                            ? 'Anda membayar'
                            : 'Dibayar anggota',
                      ),
                ],
              );
            },
      ),
    );
  }

  IconData _activityIcon(String title) {
    final String lowerTitle = title.toLowerCase();
    if (lowerTitle.contains('taxi') || lowerTitle.contains('uber')) {
      return Icons.local_taxi;
    }
    if (lowerTitle.contains('flight') || lowerTitle.contains('trip')) {
      return Icons.flight;
    }
    if (lowerTitle.contains('food') ||
        lowerTitle.contains('makan') ||
        lowerTitle.contains('dinner')) {
      return Icons.restaurant;
    }
    return Icons.receipt_long_outlined;
  }

  String _relativeTime(DateTime createdAt) {
    final Duration difference = DateTime.now().difference(createdAt.toLocal());
    if (difference.inMinutes < 1) return 'Baru saja';
    if (difference.inHours < 1) return '${difference.inMinutes} menit lalu';
    if (difference.inDays < 1) return '${difference.inHours} jam lalu';
    if (difference.inDays == 1) return 'Kemarin';
    return '${difference.inDays} hari lalu';
  }
}

class _ActivityMessage extends StatelessWidget {
  const _ActivityMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.space(18)),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: const Color(0xFF5E5656),
          fontSize: responsive.font(14),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({
    required this.icon,
    required this.bg,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.status,
  });

  final IconData icon;
  final Color bg;
  final String title;
  final String subtitle;
  final String amount;
  final String status;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.space(20)),
      child: Row(
        children: [
          CircleAvatar(
            radius: responsive.clamp(27, 23, 28),
            backgroundColor: bg,
            child: Icon(
              icon,
              color: const Color(0xFF0D213A),
              size: responsive.clamp(27, 23, 28),
            ),
          ),
          SizedBox(width: responsive.space(16)),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF111B2C),
                    fontSize: responsive.font(17),
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF5E5656),
                    fontSize: responsive.font(14),
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.space(8)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: TextStyle(
                  color: const Color(0xFF111B2C),
                  fontSize: responsive.font(18),
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                status,
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: const Color(0xFFB51B2E),
                  fontSize: responsive.font(14),
                  height: 1.15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onCreateSplit, required this.onProfile});

  final VoidCallback onCreateSplit;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _NavItem(icon: Icons.home, label: 'Beranda', selected: true),
          _NavItem(
            icon: Icons.groups_outlined,
            label: 'Grup',
            onTap: () => Navigator.of(context).pushReplacementNamed('/groups'),
          ),
          _CenterSplitButton(onCreateSplit: onCreateSplit),
          _NavItem(
            icon: Icons.bar_chart,
            label: 'Laporan',
            onTap: () => Navigator.of(context).pushReplacementNamed('/reports'),
          ),
          _NavItem(
            icon: Icons.person_outline,
            label: 'Profil',
            onTap: onProfile,
          ),
        ],
      ),
    );
  }
}

class _CenterSplitButton extends StatelessWidget {
  const _CenterSplitButton({required this.onCreateSplit});

  final VoidCallback onCreateSplit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      height: 50,
      child: Center(
        child: SizedBox(
          width: 52,
          height: 52,
          child: FloatingActionButton(
            elevation: 4,
            backgroundColor: const Color(0xFFC70F1B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            onPressed: onCreateSplit,
            child: const Icon(Icons.add, size: 34),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFFC8152B) : const Color(0xFF5A5A5A);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 54,
        height: 50,
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFFFFDADB),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
