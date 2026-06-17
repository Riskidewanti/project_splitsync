import 'package:flutter/material.dart';

import '../widgets/group_card.dart';

class GroupHomePage extends StatelessWidget {
  const GroupHomePage({super.key});

  static const List<_MockGroup> _groups = <_MockGroup>[
    _MockGroup(
      title: 'Euro Trip 2024',
      subtitle: 'Terakhir dilihat 2 jam',
      amount: 45000,
      statusLabel: 'Anda menerima',
      statusStyle: GroupCardStatusStyle.red,
      icon: Icons.flight_takeoff,
      memberInitials: <String>['A', 'B', 'C'],
      extraMemberCount: 2,
    ),
    _MockGroup(
      title: 'Apartment 4B',
      subtitle: 'Terakhir dilihat kemarin',
      amount: 0,
      statusLabel: 'Transaksi Selesai',
      statusStyle: GroupCardStatusStyle.gray,
      icon: Icons.apartment,
      memberInitials: <String>['D', 'E'],
    ),
    _MockGroup(
      title: 'Friday Dinner',
      subtitle: 'Terakhir dilihat 3 hari',
      amount: 20000,
      statusLabel: 'Anda Menerima',
      statusStyle: GroupCardStatusStyle.blue,
      icon: Icons.restaurant,
      memberInitials: <String>['F', 'G', 'H'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F4),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: <Widget>[
            const _GroupHomeHeader(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(22, 32, 22, 116),
                children: <Widget>[
                  const _GroupSectionHeader(),
                  const SizedBox(height: 20),
                  for (int index = 0; index < _groups.length; index++) ...<Widget>[
                    GroupCard(
                      title: _groups[index].title,
                      subtitle: _groups[index].subtitle,
                      amount: _groups[index].amount,
                      statusLabel: _groups[index].statusLabel,
                      statusStyle: _groups[index].statusStyle,
                      icon: _groups[index].icon,
                      memberInitials: _groups[index].memberInitials,
                      extraMemberCount: _groups[index].extraMemberCount,
                    ),
                    if (index != _groups.length - 1) const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _SplitSyncBottomNavigation(),
      floatingActionButton: const _CenterCreateButton(),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
    );
  }
}

class _MockGroup {
  const _MockGroup({
    required this.title,
    required this.subtitle,
    required this.amount,
    required this.statusLabel,
    required this.statusStyle,
    required this.icon,
    required this.memberInitials,
    this.extraMemberCount = 0,
  });

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
  const _GroupHomeHeader();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 102,
      padding: const EdgeInsets.fromLTRB(30, 26, 28, 0),
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
              padding: EdgeInsets.only(top: 34),
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
            padding: const EdgeInsets.only(top: 29),
            child: IconButton(
              constraints: const BoxConstraints.tightFor(width: 34, height: 34),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () {},
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
  const _GroupSectionHeader();

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
          height: 34,
          child: FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC70F1B),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 18),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
            onPressed: () {},
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
  const _SplitSyncBottomNavigation();

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
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _BottomNavigationItem(icon: Icons.home, label: 'Beranda'),
          _BottomNavigationItem(
            icon: Icons.groups_outlined,
            label: 'Grup',
            isActive: true,
          ),
          SizedBox(width: 54),
          _BottomNavigationItem(icon: Icons.bar_chart, label: 'Laporan'),
          _BottomNavigationItem(icon: Icons.person_outline, label: 'Profil'),
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
  });

  final IconData icon;
  final String label;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    final Color color = isActive
        ? const Color(0xFFC70F1B)
        : const Color(0xFF6D6D6D);

    return Container(
      width: 54,
      height: 50,
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFFFFD7D7) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 2),
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
    );
  }
}

class _CenterCreateButton extends StatelessWidget {
  const _CenterCreateButton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22),
      child: SizedBox(
        width: 52,
        height: 52,
        child: FloatingActionButton(
          elevation: 4,
          backgroundColor: const Color(0xFFC70F1B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          onPressed: () {},
          child: const Icon(Icons.add, size: 34),
        ),
      ),
    );
  }
}
