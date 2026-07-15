import 'package:flutter/material.dart';

import '../widgets/responsive.dart';
import 'profile_setting/profile_settings_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

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
                      const _BalanceCard(),
                      SizedBox(height: responsive.space(22)),
                      const _QuickActions(),
                      SizedBox(height: responsive.space(26)),
                      _SectionTitle(
                        title: 'Grup Teratas',
                        action: 'Lihat Semua',
                        titleSize: responsive.font(26),
                      ),
                      SizedBox(height: responsive.space(22)),
                      const _TopGroups(),
                      SizedBox(height: responsive.space(26)),
                      const _ActivityPanel(),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _BottomNav(),
    );
  }
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
  const _BalanceCard();

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
      child: Column(
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
          FittedBox(
            child: Text(
              'Rp 2.000.000',
              style: TextStyle(
                color: Colors.white,
                fontSize: responsive.font(46),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          SizedBox(height: responsive.space(24)),
          Row(
            children: const [
              Expanded(
                child: _BalanceMiniCard(
                  color: Color(0xFF8C0010),
                  title: 'Hutang ke Anda',
                  value: 'Rp 700.000',
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _BalanceMiniCard(
                  color: Color(0xFF26384B),
                  title: 'Hutang Kamu',
                  value: 'Rp 100.000',
                ),
              ),
            ],
          ),
        ],
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
  const _QuickActions();

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
            ),
            _QuickAction(
              width: itemWidth,
              icon: Icons.payments_outlined,
              label: 'Lunasi\nTagihan',
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
  });

  final IconData icon;
  final String label;
  final double width;
  final Color iconBg;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return SizedBox(
      width: width,
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
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.action,
    required this.titleSize,
  });

  final String title;
  final String action;
  final double titleSize;

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
        Text(
          action,
          style: TextStyle(
            color: const Color(0xFF9A0010),
            fontSize: responsive.font(16),
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _TopGroups extends StatelessWidget {
  const _TopGroups();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isTight = constraints.maxWidth < 360;
        const cards = [
          _GroupCard(
            icon: Icons.home_work_outlined,
            title: "Roomies '24",
            subtitle: 'Rp 300.000 Belum\ndibayar',
            chips: ['JC', 'AS', '+2'],
            highlightSubtitle: true,
          ),
          _GroupCard(
            icon: Icons.flight_takeoff_rounded,
            title: 'Japan Trip',
            subtitle: 'Semua Tagihan\nSelesai',
            chips: ['M', 'TH'],
          ),
        ];
        if (isTight) {
          return Column(
            children: [cards[0], const SizedBox(height: 14), cards[1]],
          );
        }
        return Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 20),
            Expanded(child: cards[1]),
          ],
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chips,
    this.highlightSubtitle = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> chips;
  final bool highlightSubtitle;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      height: responsive.clamp(202, 188, 208),
      padding: EdgeInsets.all(responsive.clamp(20, 16, 20)),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: responsive.clamp(28, 24, 29),
            backgroundColor: const Color(0xFFF3E7E7),
            child: Icon(
              icon,
              color: const Color(0xFF9A0010),
              size: responsive.clamp(30, 25, 31),
            ),
          ),
          SizedBox(height: responsive.space(18)),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF111B2C),
              fontSize: responsive.font(16),
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: highlightSubtitle
                  ? const Color(0xFF8C0010)
                  : const Color(0xFF5E5656),
              fontSize: responsive.font(15),
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          SizedBox(height: responsive.space(10)),
          Row(
            children: chips
                .map(
                  (chip) => Container(
                    margin: const EdgeInsets.only(right: 4),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 5,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F3F9),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      chip,
                      style: const TextStyle(
                        color: Color(0xFF0D213A),
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _ActivityPanel extends StatelessWidget {
  const _ActivityPanel();

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
      child: Column(
        children: [
          _SectionTitle(
            title: 'Aktivitas Terbaru',
            action: 'Lihat semua',
            titleSize: responsive.font(24),
          ),
          SizedBox(height: responsive.space(26)),
          const _ActivityRow(
            icon: Icons.restaurant,
            bg: Color(0xFFD7E7FF),
            title: "Dinner at Luigi's",
            subtitle: 'Anda membayar •\n2 jam yang lalu',
            amount: r'$120.00',
            status: 'Anda menalangi\nRp60.000',
          ),
          const _ActivityRow(
            icon: Icons.flight,
            bg: Color(0xFFFFB5B7),
            title: 'Flights to NYC',
            subtitle: 'Sarah paid • Yesterday',
            amount: r'$450.00',
            status: r'Owe $225.00',
          ),
          const _ActivityRow(
            icon: Icons.local_taxi,
            bg: Color(0xFFD7E7FF),
            title: 'Uber home',
            subtitle: 'You paid • Mon',
            amount: r'$24.50',
            status: r'Lent $12.25',
          ),
        ],
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
  const _BottomNav();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        decoration: const BoxDecoration(color: Colors.white),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const _NavItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              selected: true,
            ),
            _NavItem(
              icon: Icons.groups_2_outlined,
              label: 'Grup',
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed('/groups'),
            ),
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: const Color(0xFFC8152B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x33C8152B),
                    blurRadius: 16,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 34),
            ),
            _NavItem(
              icon: Icons.analytics_outlined,
              label: 'Laporan',
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed('/reports'),
            ),
            _NavItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const ProfileSettingsPage()),
              ),
            ),
          ],
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
