import 'package:flutter/material.dart';

import '../../data/datasources/group_remote_data_source.dart';
import '../../data/models/group_member_model.dart';
import '../../data/models/group_model.dart';
import '../../data/repositories/group_repository_impl.dart';
import '../../../../core/theme/app_theme.dart';
import 'create_group_page.dart';
import 'group_detail_page.dart';
import '../../../notifications/presentation/pages/notifications_page.dart';
import '../widgets/group_card.dart';
import '../../../../screens/profile_setting/profile_settings_page.dart';

class GroupHomePage extends StatefulWidget {
  const GroupHomePage({super.key});

  @override
  State<GroupHomePage> createState() => _GroupHomePageState();
}

class _GroupHomePageState extends State<GroupHomePage> {
  final GroupRepositoryImpl _groupRepository = GroupRepositoryImpl(
    remoteDataSource: GroupRemoteDataSourceImpl(),
  );

  List<_GroupCardData> _groups = const <_GroupCardData>[];
  Object? _error;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadGroups();
  }

  Future<void> _loadGroups() async {
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }

    try {
      final List<GroupModel> groups = await _groupRepository.getGroups();
      final List<_GroupCardData> cards = await Future.wait(
        groups.map(_buildGroupCardData),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _groups = cards;
        _error = null;
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

  Future<void> _refreshGroups() async {
    try {
      final List<GroupModel> groups = await _groupRepository.getGroups();
      final List<_GroupCardData> cards = await Future.wait(
        groups.map(_buildGroupCardData),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _groups = cards;
        _error = null;
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

  Future<_GroupCardData> _buildGroupCardData(GroupModel group) async {
    final List<GroupMemberModel> members = await _groupRepository
        .getGroupMembers(group.id);
    final List<String> initials = members
        .take(3)
        .map((GroupMemberModel member) => _memberInitial(member))
        .toList();

    return _GroupCardData(
      id: group.id,
      title: group.name,
      subtitle: _subtitleFor(group),
      amount: 0,
      statusLabel: 'Belum ada saldo',
      statusStyle: GroupCardStatusStyle.gray,
      icon: _iconForGroup(group.name),
      memberInitials: initials.isEmpty ? const <String>['?'] : initials,
      extraMemberCount: members.length > 3 ? members.length - 3 : 0,
    );
  }

  Future<void> _openNotifications() async {
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const NotificationsPage()),
    );
  }

  Future<void> _openCreateGroup() async {
    final Object? created = await Navigator.of(context).push(
      MaterialPageRoute<bool>(builder: (_) => const CreateGroupPage()),
    );

    if (created == true) {
      await _refreshGroups();
    }
  }

  String _subtitleFor(GroupModel group) {
    final DateTime createdAt = group.createdAt.toLocal();
    return 'Dibuat ${createdAt.day}/${createdAt.month}/${createdAt.year}';
  }

  String _memberInitial(GroupMemberModel member) {
    final String source =
        member.displayName ?? member.email ?? member.userId.substring(0, 1);
    return source.trim().isEmpty ? '?' : source.trim().characters.first.toUpperCase();
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
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            _GroupHomeHeader(onNotificationsPressed: _openNotifications),
            Expanded(
              child: RefreshIndicator(
                onRefresh: _refreshGroups,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(24, 32, 24, 120),
                  children: <Widget>[
                    _GroupSectionHeader(onCreateGroup: _openCreateGroup),
                    const SizedBox(height: AppSpacing.md),
                    if (_isLoading)
                      const _LoadingState()
                    else if (_error != null)
                      _ErrorState(error: _error!, onRetry: _loadGroups)
                    else if (_groups.isEmpty)
                      const _EmptyState()
                    else
                      for (
                        int index = 0;
                        index < _groups.length;
                        index++
                      ) ...<Widget>[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(8),
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => GroupDetailPage(
                                    groupId: _groups[index].id,
                                  ),
                                ),
                              );
                            },
                            child: GroupCard(
                              title: _groups[index].title,
                              subtitle: _groups[index].subtitle,
                              amount: _groups[index].amount,
                              statusLabel: _groups[index].statusLabel,
                              statusStyle: _groups[index].statusStyle,
                              icon: _groups[index].icon,
                              memberInitials: _groups[index].memberInitials,
                              extraMemberCount: _groups[index].extraMemberCount,
                            ),
                          ),
                        ),
                        if (index != _groups.length - 1)
                          const SizedBox(height: AppSpacing.xs),
                      ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _SplitSyncBottomNavigation(
        onCreateGroup: _openCreateGroup,
      ),
    );
  }
}
class _GroupCardData {
  const _GroupCardData({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.statusLabel,
    required this.statusStyle,
    required this.icon,
    required this.memberInitials,
    this.extraMemberCount = 0,
  });

  final String id;
  final String title;
  final String subtitle;
  final num amount;
  final String statusLabel;
  final GroupCardStatusStyle statusStyle;
  final IconData icon;
  final List<String> memberInitials;
  final int extraMemberCount;
}

class _GroupHomeHeader extends StatelessWidget {
  const _GroupHomeHeader({required this.onNotificationsPressed});

  final VoidCallback onNotificationsPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 96,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Expanded(
            child: Padding(
              padding: EdgeInsets.only(top: 24),
              child: Text(
                'SplitSync',
                style: TextStyle(
                  color: Color(0xFFC70F1B),
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.only(top: 16),
            child: IconButton(
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: onNotificationsPressed,
              icon: const Icon(
                Icons.notifications_none,
                color: Color(0xFF6B4D49),
                size: 22,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupSectionHeader extends StatelessWidget {
  const _GroupSectionHeader({required this.onCreateGroup});

  final VoidCallback onCreateGroup;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
          child: Text(
            'Grup Aktif',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        SizedBox(
          height: 48,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC70F1B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
            ),
            onPressed: onCreateGroup,
            child: const Text(
              '+ Buat Grup',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }
}


class _SplitSyncBottomNavigation extends StatelessWidget {
  const _SplitSyncBottomNavigation({required this.onCreateGroup});

  final VoidCallback onCreateGroup;

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
        children: <Widget>[
          _BottomNavigationItem(
            icon: Icons.home,
            label: 'Beranda',
            onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
          ),
          const _BottomNavigationItem(
            icon: Icons.groups_outlined,
            label: 'Grup',
            isActive: true,
          ),
          _CenterCreateButton(onCreateGroup: onCreateGroup),
          _BottomNavigationItem(
            icon: Icons.bar_chart,
            label: 'Laporan',
            onTap: () => Navigator.of(context).pushReplacementNamed('/reports'),
          ),
          _BottomNavigationItem(
            icon: Icons.person_outline,
            label: 'Profil',
            onTap: () => Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
            ),
          ),
        ],
      ),
    );
  }
}

class _BottomNavigationItem extends StatelessWidget {
  const _BottomNavigationItem({
    required this.icon,
    required this.label,
    this.isActive = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isActive;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final Color color = isActive
        ? const Color(0xFFC70F1B)
        : const Color(0xFF6D6D6D);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFFFD7D7) : Colors.transparent,
            borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CenterCreateButton extends StatelessWidget {
  const _CenterCreateButton({required this.onCreateGroup});

  final VoidCallback onCreateGroup;

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
            onPressed: onCreateGroup,
            child: const Icon(Icons.add, size: 34),
          ),
        ),
      ),
    );
  }
}
class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 44),
      child: Center(child: CircularProgressIndicator()),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 44),
      child: Center(
        child: Text(
          'Belum ada grup aktif.',
          style: TextStyle(
            color: Color(0xFF6F625F),
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.error, required this.onRetry});

  final Object error;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: <Widget>[
          Text(
            'Gagal memuat grup: $error',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF6F625F),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(onPressed: onRetry, child: const Text('Coba lagi')),
        ],
      ),
    );
  }
}
