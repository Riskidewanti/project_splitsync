import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../data/datasources/group_remote_data_source.dart';
import '../../data/models/group_expense_model.dart';
import '../../data/models/group_member_model.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../../expenses/presentation/pages/add_expense_page.dart';

class GroupDetailPage extends StatefulWidget {
  const GroupDetailPage({super.key, required this.groupId});

  final String groupId;

  static const Color primaryColor = Color(0xFFC70F1B);
  static const Color backgroundColor = Color(0xFFFBF7F4);
  static const Color textDarkColor = Color(0xFF1F2933);
  static const Color borderColor = Color(0xFFE5E7EB);

  @override
  State<GroupDetailPage> createState() => _GroupDetailPageState();
}

class _GroupDetailPageState extends State<GroupDetailPage> {
  final GroupRepositoryImpl _groupRepository = GroupRepositoryImpl(
    remoteDataSource: GroupRemoteDataSourceImpl(),
  );

  GroupModel? _group;
  List<GroupMemberModel> _members = const <GroupMemberModel>[];
  List<GroupExpenseModel> _expenses = const <GroupExpenseModel>[];
  String? _currentUserId;
  String? _removingUserId;
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroupDetail();
  }

  Future<void> _loadGroupDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final String? currentUserId = await _groupRepository.getCurrentUserId();
      final GroupModel? group = await _groupRepository.getGroupById(
        widget.groupId,
      );
      final List<GroupMemberModel> members = await _groupRepository
          .getGroupMembers(widget.groupId);
      final List<GroupExpenseModel> expenses = await _groupRepository
          .getGroupExpenses(widget.groupId);

      if (!mounted) {
        return;
      }

      setState(() {
        _currentUserId = currentUserId;
        _group = group;
        _members = members;
        _expenses = expenses;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _error = error;
        _isLoading = false;
      });
    }
  }

  double get _totalExpense {
    return _expenses.fold<double>(
      0,
      (double total, GroupExpenseModel expense) => total + expense.totalAmount,
    );
  }

  List<_BalanceMember> get _balanceMembers {
    return _members.map((GroupMemberModel member) {
      final String name = _memberName(member);
      return _BalanceMember(
        name: name,
        initial: _initialFor(name),
        status: 'Saldo belum dihitung',
        avatarColor: const Color(0xFFD9EAFE),
        statusColor: const Color(0xFF6B7280),
        textColor: GroupDetailPage.textDarkColor,
      );
    }).toList();
  }

  List<_ExpenseItem> get _expenseItems {
    return _expenses.map((GroupExpenseModel expense) {
      return _ExpenseItem(
        title: expense.merchantName?.trim().isNotEmpty == true
            ? expense.merchantName!
            : expense.title,
        subtitle:
            '${_payerLabel(expense.payerId)} membayar - ${_dateLabel(expense.expenseDate)}',
        amount: formatRupiah(expense.totalAmount),
        note: expense.status,
        noteColor: GroupDetailPage.textDarkColor,
        icon: Icons.receipt_long_outlined,
      );
    }).toList();
  }

  bool get _canManageMembers {
    final String? currentUserId = _currentUserId;
    if (currentUserId == null) {
      return false;
    }

    return _members.any((GroupMemberModel member) {
      return member.userId == currentUserId &&
          member.role == GroupMemberRole.owner;
    });
  }

  int get _adminCount {
    return _members.where((GroupMemberModel member) {
      return member.role == GroupMemberRole.owner ||
          member.role == GroupMemberRole.admin;
    }).length;
  }

  bool _isLastAdminSelf(GroupMemberModel member) {
    return member.userId == _currentUserId &&
        (member.role == GroupMemberRole.owner ||
            member.role == GroupMemberRole.admin) &&
        _adminCount <= 1;
  }

  Future<void> _confirmRemoveMember(GroupMemberModel member) async {
    if (!_canManageMembers || _removingUserId != null) {
      return;
    }

    if (_isLastAdminSelf(member)) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Tidak bisa menghapus admin terakhir dari grup.'),
          ),
        );
      return;
    }

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hapus anggota?'),
          content: Text('${_memberName(member)} akan dihapus dari grup ini.'),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Batal'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: FilledButton.styleFrom(
                backgroundColor: GroupDetailPage.primaryColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() => _removingUserId = member.userId);

    try {
      await _groupRepository.removeMember(
        groupId: widget.groupId,
        userId: member.userId,
      );
      await _loadGroupDetail();
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Gagal menghapus anggota: $error')),
        );
    } finally {
      if (mounted) {
        setState(() => _removingUserId = null);
      }
    }
  }

  Future<void> _openAddExpense() async {
    final GroupModel? group = _group;
    final String? currentUserId = _currentUserId;
    if (group == null || currentUserId == null || currentUserId.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(content: Text('Data grup belum siap. Coba lagi.')),
        );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => AddExpensePage(
          groupId: group.id,
          groupName: group.name,
          userId: currentUserId,
          members: _members
              .where((GroupMemberModel member) {
                return member.status == GroupMemberStatus.active &&
                    member.userId != currentUserId;
              })
              .map(_expenseMemberFromGroupMember)
              .toList(),
        ),
      ),
    );

    if (mounted) {
      await _loadGroupDetail();
    }
  }

  Member _expenseMemberFromGroupMember(GroupMemberModel member) {
    final String name = _memberName(member);
    return Member(
      id: member.userId,
      name: name,
      avatarUrl: member.avatarUrl ?? '',
    );
  }

  String _memberName(GroupMemberModel member) {
    if (member.displayName != null && member.displayName!.trim().isNotEmpty) {
      return member.displayName!.trim();
    }
    if (member.email != null && member.email!.trim().isNotEmpty) {
      return member.email!.trim();
    }
    return 'Member ${member.userId.substring(0, 8)}';
  }

  String _payerLabel(String payerId) {
    for (final GroupMemberModel member in _members) {
      if (member.userId == payerId) {
        return _memberName(member);
      }
    }
    return 'Member ${payerId.substring(0, 8)}';
  }

  String _initialFor(String name) {
    final String trimmed = name.trim();
    return trimmed.isEmpty ? '?' : trimmed.characters.first.toUpperCase();
  }

  String _dateLabel(DateTime dateTime) {
    final DateTime local = dateTime.toLocal();
    return '${local.day}/${local.month}/${local.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: GroupDetailPage.backgroundColor,
      appBar: AppBar(
        toolbarHeight: 96,
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        leadingWidth: 72,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20, top: 18),
          child: IconButton(
            onPressed: () => Navigator.of(context).maybePop(),
            icon: const Icon(
              Icons.arrow_back,
              color: GroupDetailPage.textDarkColor,
              size: 24,
            ),
          ),
        ),
        centerTitle: true,
        title: Padding(
          padding: const EdgeInsets.only(top: 18),
          child: Text(
            _group?.name ?? 'Detail Group',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: GroupDetailPage.textDarkColor,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: GroupDetailPage.borderColor),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: RefreshIndicator(
              onRefresh: _loadGroupDetail,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(23, 18, 23, 112),
                children: <Widget>[
                  if (_isLoading)
                    const _DetailLoadingState()
                  else if (_error != null)
                    _DetailErrorState(error: _error!, onRetry: _loadGroupDetail)
                  else if (_group == null)
                    const _DetailEmptyState(message: 'Grup tidak ditemukan.')
                  else ...<Widget>[
                    _SummaryCard(
                      totalExpense: _totalExpense,
                      balanceLabel: 'Split balance belum tersedia',
                    ),
                    const SizedBox(height: 12),
                    const _ActionButtons(),
                    const SizedBox(height: 32),
                    const _SectionTitle(title: 'Saldo'),
                    const SizedBox(height: 8),
                    if (_balanceMembers.isEmpty)
                      const _DetailEmptyState(
                        message: 'Belum ada anggota aktif.',
                      )
                    else
                      _BalanceList(balances: _balanceMembers),
                    const SizedBox(height: 32),
                    _MemberManagementSection(
                      members: _members,
                      canManage: _canManageMembers,
                      currentUserId: _currentUserId,
                      removingUserId: _removingUserId,
                      isLastAdminSelf: _isLastAdminSelf,
                      onRemove: _confirmRemoveMember,
                    ),
                    const SizedBox(height: 32),
                    const _ExpenseHeader(),
                    const SizedBox(height: 14),
                    if (_expenseItems.isEmpty)
                      const _DetailEmptyState(
                        message:
                            'Belum ada pengeluaran grup. TODO: hubungkan alur tambah pengeluaran ke groupId aktif.',
                      )
                    else
                      _ExpenseList(expenses: _expenseItems),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddExpense,
        elevation: 5,
        backgroundColor: GroupDetailPage.primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
        child: const Icon(Icons.add, size: 34),
      ),
    );
  }
}

class _BalanceMember {
  const _BalanceMember({
    required this.name,
    required this.initial,
    required this.status,
    required this.avatarColor,
    required this.statusColor,
    required this.textColor,
  });

  final String name;
  final String initial;
  final String status;
  final Color avatarColor;
  final Color statusColor;
  final Color textColor;
}

class _ExpenseItem {
  const _ExpenseItem({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.note,
    required this.noteColor,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final String amount;
  final String note;
  final Color noteColor;
  final IconData icon;
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.totalExpense, required this.balanceLabel});

  final double totalExpense;
  final String balanceLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GroupDetailPage.borderColor),
      ),
      child: Column(
        children: <Widget>[
          const Text(
            'TOTAL PENGELUARAN GRUP',
            style: TextStyle(
              color: Color(0xFF5C6670),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              formatRupiah(totalExpense),
              style: const TextStyle(
                color: GroupDetailPage.textDarkColor,
                fontSize: 34,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFDDEBFF),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Text(
              balanceLabel,
              style: const TextStyle(
                color: GroupDetailPage.primaryColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButtons extends StatelessWidget {
  const _ActionButtons();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Expanded(
          child: SizedBox(
            height: AppSpacing.buttonHeight,
            child: FilledButton.icon(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: GroupDetailPage.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              icon: const Icon(Icons.payments_outlined, size: 19),
              label: const Text(
                'Selesaikan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: SizedBox(
            height: AppSpacing.buttonHeight,
            child: OutlinedButton.icon(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                foregroundColor: GroupDetailPage.textDarkColor,
                side: const BorderSide(color: GroupDetailPage.borderColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppRadius.pill),
                ),
              ),
              icon: const Icon(Icons.file_download_outlined, size: 19),
              label: const Text(
                'Laporan',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        color: GroupDetailPage.textDarkColor,
        fontSize: 16,
        fontWeight: FontWeight.w900,
      ),
    );
  }
}

class _BalanceList extends StatelessWidget {
  const _BalanceList({required this.balances});

  final List<_BalanceMember> balances;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: <Widget>[
          for (int index = 0; index < balances.length; index++) ...<Widget>[
            if (index > 0) const SizedBox(width: 12),
            _BalanceCard(member: balances[index]),
          ],
        ],
      ),
    );
  }
}

class _BalanceCard extends StatelessWidget {
  const _BalanceCard({required this.member});

  final _BalanceMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(
        minHeight: 103,
        minWidth: 110,
        maxWidth: 110,
      ),
      padding: const EdgeInsets.fromLTRB(9, 13, 9, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: GroupDetailPage.borderColor),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            CircleAvatar(
              radius: 18,
              backgroundColor: member.avatarColor,
              child: Text(
                member.initial,
                style: TextStyle(
                  color: member.textColor,
                  fontSize: 15,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              member.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: GroupDetailPage.textDarkColor,
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              member.status,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: member.statusColor,
                fontSize: 10,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberManagementSection extends StatelessWidget {
  const _MemberManagementSection({
    required this.members,
    required this.canManage,
    required this.currentUserId,
    required this.removingUserId,
    required this.isLastAdminSelf,
    required this.onRemove,
  });

  final List<GroupMemberModel> members;
  final bool canManage;
  final String? currentUserId;
  final String? removingUserId;
  final bool Function(GroupMemberModel member) isLastAdminSelf;
  final ValueChanged<GroupMemberModel> onRemove;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const _SectionTitle(title: 'Anggota Grup'),
        const SizedBox(height: 10),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: GroupDetailPage.borderColor),
          ),
          child: Column(
            children: <Widget>[
              for (int index = 0; index < members.length; index++)
                _MemberManagementTile(
                  member: members[index],
                  showDivider: index != members.length - 1,
                  canManage: canManage,
                  isCurrentUser: members[index].userId == currentUserId,
                  isRemoving: members[index].userId == removingUserId,
                  removeDisabled: isLastAdminSelf(members[index]),
                  onRemove: () => onRemove(members[index]),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberManagementTile extends StatelessWidget {
  const _MemberManagementTile({
    required this.member,
    required this.showDivider,
    required this.canManage,
    required this.isCurrentUser,
    required this.isRemoving,
    required this.removeDisabled,
    required this.onRemove,
  });

  final GroupMemberModel member;
  final bool showDivider;
  final bool canManage;
  final bool isCurrentUser;
  final bool isRemoving;
  final bool removeDisabled;
  final VoidCallback onRemove;

  String get _displayName {
    final String? displayName = member.displayName?.trim();
    if (displayName != null && displayName.isNotEmpty) {
      return displayName;
    }

    final String? email = member.email?.trim();
    if (email != null && email.isNotEmpty) {
      return email;
    }

    return 'Member ${member.userId.substring(0, 8)}';
  }

  String get _initial {
    final String name = _displayName.trim();
    return name.isEmpty ? '?' : name.substring(0, 1).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 12, 8, 12),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: GroupDetailPage.borderColor),
              )
            : null,
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 18,
            backgroundColor: const Color(0xFFDDEBFF),
            backgroundImage: member.avatarUrl == null
                ? null
                : NetworkImage(member.avatarUrl!),
            child: member.avatarUrl == null
                ? Text(
                    _initial,
                    style: const TextStyle(
                      color: GroupDetailPage.textDarkColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w900,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  isCurrentUser ? '$_displayName (Anda)' : _displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GroupDetailPage.textDarkColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${member.role.value} - ${member.email ?? member.userId}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6B7280),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          if (canManage)
            IconButton(
              tooltip: removeDisabled
                  ? 'Admin terakhir tidak bisa dihapus'
                  : 'Hapus anggota',
              onPressed: isRemoving || removeDisabled ? null : onRemove,
              icon: isRemoving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline, size: 20),
              color: GroupDetailPage.primaryColor,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _ExpenseHeader extends StatelessWidget {
  const _ExpenseHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(child: _SectionTitle(title: 'Pengeluaran Terkini')),
        TextButton(
          onPressed: () {},
          style: TextButton.styleFrom(
            foregroundColor: GroupDetailPage.primaryColor,
            minimumSize: Size.zero,
            padding: EdgeInsets.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          child: const Text(
            'Lihat semua',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
          ),
        ),
      ],
    );
  }
}

class _ExpenseList extends StatelessWidget {
  const _ExpenseList({required this.expenses});

  final List<_ExpenseItem> expenses;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 72),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
        child: ListView.builder(
          itemCount: expenses.length,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: EdgeInsets.zero,
          itemBuilder: (BuildContext context, int index) {
            return _ExpenseTile(
              expense: expenses[index],
              showDivider: index != expenses.length - 1,
            );
          },
        ),
      ),
    );
  }
}

class _ExpenseTile extends StatelessWidget {
  const _ExpenseTile({required this.expense, required this.showDivider});

  final _ExpenseItem expense;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 14, 14, 13),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(
                bottom: BorderSide(color: GroupDetailPage.borderColor),
              )
            : null,
      ),
      child: Row(
        children: <Widget>[
          SizedBox(
            width: 28,
            child: Icon(
              expense.icon,
              color: GroupDetailPage.textDarkColor,
              size: 19,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  expense.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GroupDetailPage.textDarkColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  expense.subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF4B5563),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: <Widget>[
              Text(
                expense.amount,
                style: const TextStyle(
                  color: GroupDetailPage.textDarkColor,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 3),
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 132),
                child: Text(
                  expense.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: TextStyle(
                    color: expense.noteColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DetailLoadingState extends StatelessWidget {
  const _DetailLoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 72),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _DetailEmptyState extends StatelessWidget {
  const _DetailEmptyState({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF6B7280),
          fontSize: 12,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _DetailErrorState extends StatelessWidget {
  const _DetailErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 72),
      child: Column(
        children: <Widget>[
          Text(
            'Gagal memuat detail grup: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6B7280),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
