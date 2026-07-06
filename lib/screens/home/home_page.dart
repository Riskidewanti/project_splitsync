import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../authentication/auth_service.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/expenses/presentation/pages/add_expense_page.dart';
import '../../features/groups/data/datasources/group_remote_data_source.dart';
import '../../features/groups/data/models/group_expense_model.dart';
import '../../features/groups/data/models/group_member_model.dart';
import '../../features/groups/data/models/group_model.dart';
import '../../features/groups/data/repositories/group_repository_impl.dart';
import '../../features/groups/presentation/pages/create_group_page.dart';
import '../../features/groups/presentation/pages/group_detail_page.dart';
import '../../features/groups/presentation/pages/group_home_page.dart';
import '../../features/groups/presentation/widgets/group_card.dart';
import '../../reports/reports_page.dart';
import '../../features/settlements/presentation/pages/person_payment_request_page.dart';
import '../../features/settlements/presentation/pages/settlement_page.dart';
import '../../widgets/responsive.dart';
import '../profile_setting/profile_settings_page.dart';

enum _ExpenseQuickAction { addExpense, createGroup }

enum _PaymentRequestMode { group, person }

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

  void _refreshHomeData() {
    if (!mounted) return;
    setState(() {
      _groupsFuture = _loadGroups();
      _dashboardFuture = _loadDashboardData();
    });
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
    final List<Object> results = await Future.wait<Object>(<Future<Object>>[
      _groupRepository.getGroupMembers(group.id),
      _groupRepository.getGroupExpenses(group.id),
    ]);

    return _HomeGroupData(
      group: group,
      members: results[0] as List<GroupMemberModel>,
      expenses: results[1] as List<GroupExpenseModel>,
    );
  }

  Future<void> _openGroupDetail(GroupModel group) async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GroupDetailPage(groupId: group.id),
      ),
    );

    _refreshHomeData();
  }

  void _openSplitBillOcr() {
    Navigator.of(context).pushNamed('/scan');
  }

  Future<void> _openCreateGroup() async {
    final Object? created = await Navigator.of(
      context,
    ).push(MaterialPageRoute<bool>(builder: (_) => const CreateGroupPage()));

    if (created == true && mounted) {
      _refreshHomeData();
    }
  }

  Future<void> _openPaymentRequest() async {
    try {
      final _PaymentRequestMode? mode = await _selectPaymentRequestMode();
      if (!mounted || mode == null) return;

      if (mode == _PaymentRequestMode.person) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => const PersonPaymentRequestPage(),
          ),
        );
        return;
      }

      final String? currentUserId = await _groupRepository.getCurrentUserId();
      if (!mounted) return;

      if (currentUserId == null || currentUserId.trim().isEmpty) {
        _showHomeMessage('Silakan masuk untuk meminta pembayaran.');
        return;
      }

      final List<GroupModel> groups = await _groupRepository.getGroups();
      if (!mounted) return;

      if (groups.isEmpty) {
        await _openCreateGroup();
        return;
      }

      final GroupModel? selectedGroup = groups.length == 1
          ? groups.first
          : await _selectGroupForExpense(groups, title: 'Pilih Grup');
      if (selectedGroup == null || !mounted) return;

      final _PaymentRequestDetails? details = await _requestPaymentDetails();
      if (details == null || !mounted) return;

      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => SettlementPage(
            groupId: selectedGroup.id,
            userId: currentUserId,
            totalBill: details.amount,
            billTitle: details.title,
          ),
        ),
      );

      _refreshHomeData();
    } catch (error) {
      if (!mounted) return;
      _showHomeMessage('Gagal membuka minta pembayaran: $error');
    }
  }

  Future<_PaymentRequestMode?> _selectPaymentRequestMode() {
    return showModalBottomSheet<_PaymentRequestMode>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Minta Pembayaran',
                  style: TextStyle(
                    color: Color(0xFF111B2C),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.groups_outlined,
                    color: Color(0xFFC8152B),
                  ),
                  title: const Text(
                    'Request ke Grup',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Pilih grup lalu bagi nominal request'),
                  onTap: () =>
                      Navigator.of(context).pop(_PaymentRequestMode.group),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.person_add_alt_1_outlined,
                    color: Color(0xFFC8152B),
                  ),
                  title: const Text(
                    'Request per Orang',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Minta pembayaran ke satu teman'),
                  onTap: () =>
                      Navigator.of(context).pop(_PaymentRequestMode.person),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<_PaymentRequestDetails?> _requestPaymentDetails() async {
    final TextEditingController titleController = TextEditingController(
      text: 'Minta Pembayaran',
    );
    final TextEditingController amountController = TextEditingController();
    String? errorText;

    final _PaymentRequestDetails? details = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return SafeArea(
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  18,
                  20,
                  MediaQuery.viewInsetsOf(context).bottom + 24,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Minta Pembayaran',
                      style: TextStyle(
                        color: Color(0xFF111B2C),
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'Judul',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: amountController,
                      keyboardType: TextInputType.number,
                      decoration: InputDecoration(
                        labelText: 'Nominal',
                        prefixText: 'Rp ',
                        errorText: errorText,
                        border: const OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFC8152B),
                          foregroundColor: Colors.white,
                        ),
                        onPressed: () {
                          final double amount = _parseCurrencyInput(
                            amountController.text,
                          );
                          final String title = titleController.text.trim();

                          if (amount <= 0) {
                            setModalState(() {
                              errorText = 'Nominal wajib lebih dari 0';
                            });
                            return;
                          }

                          Navigator.of(context).pop(
                            _PaymentRequestDetails(
                              title: title.isEmpty ? 'Minta Pembayaran' : title,
                              amount: amount,
                            ),
                          );
                        },
                        child: const Text('Lanjutkan'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      titleController.dispose();
      amountController.dispose();
    });
    return details;
  }

  Future<void> _openExpenseQuickOptions() async {
    final action = await showModalBottomSheet<_ExpenseQuickAction>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Tambah Pengeluaran',
                  style: TextStyle(
                    color: Color(0xFF111B2C),
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.receipt_long_outlined,
                    color: Color(0xFFC8152B),
                  ),
                  title: const Text(
                    'Tambah Pengeluaran Manual',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Pilih grup lalu isi detail transaksi'),
                  onTap: () =>
                      Navigator.of(context).pop(_ExpenseQuickAction.addExpense),
                ),
                const Divider(height: 1),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(
                    Icons.group_add_outlined,
                    color: Color(0xFFC8152B),
                  ),
                  title: const Text(
                    'Buat Grup Baru',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  subtitle: const Text('Buka halaman pembuatan grup'),
                  onTap: () => Navigator.of(
                    context,
                  ).pop(_ExpenseQuickAction.createGroup),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted || action == null) return;

    switch (action) {
      case _ExpenseQuickAction.addExpense:
        await _openManualExpense();
      case _ExpenseQuickAction.createGroup:
        await _openCreateGroup();
    }
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
        await _openCreateGroup();
        return;
      }

      final GroupModel? selectedGroup = groups.length == 1
          ? groups.first
          : await _selectGroupForExpense(groups);
      if (selectedGroup == null || !mounted) return;

      final List<GroupMemberModel> groupMembers = await _groupRepository
          .getGroupMembers(selectedGroup.id);
      if (!mounted) return;

      await Navigator.of(context).push(
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

      _refreshHomeData();
    } catch (error) {
      if (!mounted) return;
      _showHomeMessage('Gagal membuka tambah pengeluaran: $error');
    }
  }

  Future<GroupModel?> _selectGroupForExpense(
    List<GroupModel> groups, {
    String title = 'Pilih Grup',
  }) {
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
                return Padding(
                  padding: const EdgeInsets.only(bottom: 14),
                  child: Text(
                    title,
                    style: const TextStyle(
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
                      _QuickActions(
                        onAddExpense: _openExpenseQuickOptions,
                        onRequestPayment: _openPaymentRequest,
                      ),
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
                      _ActivityPanel(
                        dataFuture: _dashboardFuture,
                        onViewAll: () => Navigator.of(
                          context,
                        ).pushReplacementNamed('/reports'),
                      ),
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
  const _HomeGroupData({
    required this.group,
    required this.members,
    required this.expenses,
  });

  final GroupModel group;
  final List<GroupMemberModel> members;
  final List<GroupExpenseModel> expenses;

  double get totalExpense {
    return expenses.fold<double>(
      0,
      (double total, GroupExpenseModel expense) => total + expense.totalAmount,
    );
  }

  String get statusLabel {
    if (expenses.isEmpty) return 'Belum ada pengeluaran';
    return '${expenses.length} pengeluaran';
  }

  GroupCardStatusStyle get statusStyle {
    return expenses.isEmpty
        ? GroupCardStatusStyle.gray
        : GroupCardStatusStyle.red;
  }
}

class _PaymentRequestDetails {
  const _PaymentRequestDetails({required this.title, required this.amount});

  final String title;
  final double amount;
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

double _parseCurrencyInput(String value) {
  final String normalized = value
      .replaceAll(RegExp(r'[^0-9,\.]'), '')
      .replaceAll('.', '')
      .replaceAll(',', '.');
  return double.tryParse(normalized) ?? 0;
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
  const _QuickActions({
    required this.onAddExpense,
    required this.onRequestPayment,
  });

  final VoidCallback onAddExpense;
  final VoidCallback onRequestPayment;

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
              onTap: onRequestPayment,
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
                  amount: topGroups[index].totalExpense,
                  statusLabel: topGroups[index].statusLabel,
                  statusStyle: topGroups[index].statusStyle,
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
  const _ActivityPanel({required this.dataFuture, required this.onViewAll});

  final Future<_HomeDashboardData> dataFuture;
  final VoidCallback onViewAll;

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
                    onAction: onViewAll,
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

class SmoothTransitionRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothTransitionRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const curve = Curves.easeInOutCubic;
            final CurvedAnimation curvedAnimation = CurvedAnimation(
              parent: animation,
              curve: curve,
            );
            return FadeTransition(
              opacity: curvedAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0.0, 0.02),
                  end: Offset.zero,
                ).animate(curvedAnimation),
                child: child,
              ),
            );
          },
          transitionDuration: const Duration(milliseconds: 250),
        );
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({required this.onCreateSplit, required this.onProfile});

  final VoidCallback onCreateSplit;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: AppSpacing.bottomNavHeight,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
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
            onTap: () => Navigator.of(context).pushReplacement(
              SmoothTransitionRoute(page: const GroupHomePage()),
            ),
          ),
          _CenterSplitButton(onCreateSplit: onCreateSplit),
          _NavItem(
            icon: Icons.bar_chart,
            label: 'Laporan',
            onTap: () => Navigator.of(context).pushReplacement(
              SmoothTransitionRoute(page: const ReportsPage()),
            ),
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
      width: 56,
      height: 56,
      child: Center(
        child: SizedBox(
          width: 56,
          height: 56,
          child: FloatingActionButton(
            elevation: 4,
            backgroundColor: const Color(0xFFC70F1B),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.lg),
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
        width: 56,
        height: 56,
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFFFFDADB),
                borderRadius: BorderRadius.circular(AppRadius.md),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 20, color: color),
            const SizedBox(height: 4),
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
