import 'package:flutter/material.dart';

import '../authentication/auth_service.dart';
import '../widgets/responsive.dart';
import 'welcome_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Logout'),
        content: const Text('Keluar dari akun SplitSync sekarang?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC8152B),
            ),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) return;
    await AuthService.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        child: Column(
          children: [
            Container(
              height: responsive.space(112),
              padding: responsive.horizontal(30),
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
                children: const [
                  Text(
                    'SplitSync',
                    style: TextStyle(
                      color: Color(0xFFC8152B),
                      fontSize: 30,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Spacer(),
                  Icon(
                    Icons.notifications_none_rounded,
                    color: Color(0xFF4B3333),
                    size: 30,
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: responsive
                    .horizontal(30)
                    .copyWith(
                      top: responsive.space(28),
                      bottom: responsive.space(24),
                    ),
                child: ResponsivePage(
                  maxWidth: 560,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 26),
                        decoration: BoxDecoration(
                          color: const Color(0xFFA4161D),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          children: [
                            const Text(
                              'Total Saldo Bersih',
                              style: TextStyle(
                                color: Color(0xFFDFA5A8),
                                fontSize: 17,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            const FittedBox(
                              child: Text(
                                'Rp 2.000.000',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 46,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
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
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final itemWidth = constraints.maxWidth >= 350
                              ? (constraints.maxWidth - 30) / 4
                              : (constraints.maxWidth - 10) / 2;
                          return Wrap(
                            spacing: 10,
                            runSpacing: 10,
                            children: [
                              _QuickAction(
                                icon: Icons.receipt_long_outlined,
                                label: 'Tambah\nPengeluaran',
                                iconBg: Color(0xFFFFD9DC),
                                iconColor: Color(0xFF9A0010),
                                width: itemWidth,
                              ),
                              _QuickAction(
                                icon: Icons.payments_outlined,
                                label: 'Lunasi\nTagihan',
                                width: itemWidth,
                              ),
                              _QuickAction(
                                icon: Icons.request_quote_outlined,
                                label: 'Minta\nPembayaran',
                                width: itemWidth,
                              ),
                              _QuickAction(
                                icon: Icons.view_agenda_outlined,
                                label: 'Split\nBill',
                                width: itemWidth,
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 26),
                      Row(
                        children: const [
                          Text(
                            'Grup Teratas',
                            style: TextStyle(
                              color: Color(0xFF111B2C),
                              fontSize: 26,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Spacer(),
                          Text(
                            'Lihat Semua',
                            style: TextStyle(
                              color: Color(0xFF9A0010),
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 22),
                      LayoutBuilder(
                        builder: (context, constraints) {
                          final isTight = constraints.maxWidth < 360;
                          final cards = const [
                            _GroupCard(
                              icon: Icons.home_work_outlined,
                              title: "Roomies '24",
                              subtitle: 'Rp 300.000 Belum\ndibayar',
                              chips: ['JC', 'AS', '+2'],
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
                              children: [
                                cards[0],
                                const SizedBox(height: 14),
                                cards[1],
                              ],
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
                      ),
                      const SizedBox(height: 26),
                      Container(
                        padding: const EdgeInsets.fromLTRB(24, 26, 24, 24),
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
                          children: const [
                            Row(
                              children: [
                                Text(
                                  'Aktivitas Terbaru',
                                  style: TextStyle(
                                    color: Color(0xFF111B2C),
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                Spacer(),
                                Text(
                                  'Lihat semua',
                                  style: TextStyle(
                                    color: Color(0xFF9A0010),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 26),
                            _ActivityRow(
                              icon: Icons.restaurant,
                              bg: Color(0xFFD7E7FF),
                              title: "Dinner at Luigi's",
                              subtitle: 'Anda membayar •\n2 jam yang lalu',
                              amount: r'$120.00',
                              status: 'Anda menalangi\nRp60.000',
                            ),
                            _ActivityRow(
                              icon: Icons.flight,
                              bg: Color(0xFFFFB5B7),
                              title: 'Flights to NYC',
                              subtitle: 'Sarah paid • Yesterday',
                              amount: r'$450.00',
                              status: r'Owe $225.00',
                            ),
                            _ActivityRow(
                              icon: Icons.local_taxi,
                              bg: Color(0xFFD7E7FF),
                              title: 'Uber home',
                              subtitle: 'You paid • Mon',
                              amount: r'$24.50',
                              status: r'Lent $12.25',
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _BottomNav(onLogout: () => _logout(context)),
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
          const SizedBox(height: 8),
          FittedBox(
            child: Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
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
    return SizedBox(
      width: width,
      child: Container(
        height: 116,
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 15),
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
              radius: 23,
              backgroundColor: iconBg,
              child: Icon(icon, color: iconColor, size: 27),
            ),
            const SizedBox(height: 9),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 2,
              style: const TextStyle(
                color: Color(0xFF0D213A),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                height: 1.18,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GroupCard extends StatelessWidget {
  const _GroupCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.chips,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final List<String> chips;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 182,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE4E4E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: const Color(0xFFF3E7E7),
            child: Icon(icon, color: const Color(0xFF9A0010), size: 30),
          ),
          const Spacer(),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF111B2C),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: Color(0xFF5E5656),
              fontSize: 15,
              fontWeight: FontWeight.w700,
              height: 1.2,
            ),
          ),
          const SizedBox(height: 12),
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
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Row(
        children: [
          CircleAvatar(
            radius: 27,
            backgroundColor: bg,
            child: Icon(icon, color: const Color(0xFF0D213A), size: 27),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Color(0xFF111B2C),
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: Color(0xFF5E5656),
                    fontSize: 14,
                    height: 1.2,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                amount,
                style: const TextStyle(
                  color: Color(0xFF111B2C),
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                status,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  color: Color(0xFFB51B2E),
                  fontSize: 14,
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
  const _BottomNav({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 92,
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
      decoration: const BoxDecoration(color: Colors.white),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const _NavItem(
            icon: Icons.home_rounded,
            label: 'Beranda',
            selected: true,
          ),
          const _NavItem(icon: Icons.groups_2_outlined, label: 'Grup'),
          Container(
            width: 70,
            height: 70,
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
            child: const Icon(Icons.add, color: Colors.white, size: 42),
          ),
          const _NavItem(icon: Icons.analytics_outlined, label: 'Laporan'),
          _NavItem(
            icon: Icons.person_outline_rounded,
            label: 'Profil',
            onTap: onLogout,
          ),
        ],
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
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 27),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ],
    );

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: onTap,
      child: Container(
        width: 78,
        height: 64,
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFFFFDADB),
                borderRadius: BorderRadius.circular(18),
              )
            : null,
        child: IconTheme(
          data: IconThemeData(
            color: selected ? const Color(0xFFC8152B) : const Color(0xFF5A5A5A),
          ),
          child: DefaultTextStyle.merge(
            style: TextStyle(
              color: selected
                  ? const Color(0xFFC8152B)
                  : const Color(0xFF5A5A5A),
            ),
            child: Center(child: content),
          ),
        ),
      ),
    );
  }
}
