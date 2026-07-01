import 'package:flutter/material.dart';

import '../../authentication/auth_service.dart';
import '../../widgets/responsive.dart';
import '../authentication/welcome_page.dart';
import 'account_settings_page.dart';
import 'notification_settings_page.dart';

class ProfileSettingsPage extends StatefulWidget {
  const ProfileSettingsPage({super.key});

  @override
  State<ProfileSettingsPage> createState() => _ProfileSettingsPageState();
}

class _ProfileSettingsPageState extends State<ProfileSettingsPage> {
  late final Future<ProfileDetails> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.fetchCurrentProfile();
  }

  Future<void> _logout() async {
    await AuthService.logout();
    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomePage()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<ProfileDetails>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFC8152B)),
              );
            }

            if (snapshot.hasError) {
              return _ErrorState(
                message: snapshot.error.toString(),
                onBack: () => Navigator.of(context).pop(),
              );
            }

            return _ProfileBody(
              profile: snapshot.requireData,
              onLogout: _logout,
            );
          },
        ),
      ),
      bottomNavigationBar: const _ProfileBottomNav(),
    );
  }
}

class _ProfileBody extends StatelessWidget {
  const _ProfileBody({required this.profile, required this.onLogout});

  final ProfileDetails profile;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Column(
      children: [
        _ProfileAppBar(responsive: responsive),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              responsive.clamp(38, 24, 42),
              responsive.space(24),
              responsive.clamp(38, 24, 42),
              responsive.space(28),
            ),
            child: ResponsivePage(
              maxWidth: 430,
              child: Column(
                children: [
                  _IdentityCard(profile: profile),
                  SizedBox(height: responsive.space(26)),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          value: profile.groupCount.toString(),
                          label: 'Grup yang Diikuti',
                          accent: true,
                        ),
                      ),
                      SizedBox(width: responsive.space(18)),
                      Expanded(
                        child: _StatCard(
                          value: _formatNumber(profile.totalSharedExpense),
                          label: 'Total Pengeluaran\nBersama',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: responsive.space(28)),
                  _SettingsCard(onLogout: onLogout),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  static String _formatNumber(num value) {
    final raw = value.round().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < raw.length; i++) {
      final remaining = raw.length - i - 1;
      buffer.write(raw[i]);
      if (remaining > 0 && remaining % 3 == 0) buffer.write('.');
    }
    return buffer.toString();
  }
}

class _ProfileAppBar extends StatelessWidget {
  const _ProfileAppBar({required this.responsive});

  final Responsive responsive;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: responsive.clamp(116, 96, 118),
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: responsive.clamp(28, 22, 34)),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(
              Icons.arrow_back_rounded,
              size: responsive.clamp(32, 28, 34),
              color: const Color(0xFF111B2C),
            ),
          ),
          SizedBox(width: responsive.space(62)),
          Expanded(
            child: Text(
              'Pengaturan Profil',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF111B2C),
                fontSize: responsive.font(27),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _IdentityCard extends StatelessWidget {
  const _IdentityCard({required this.profile});

  final ProfileDetails profile;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        responsive.clamp(24, 20, 28),
        responsive.clamp(38, 32, 42),
        responsive.clamp(24, 20, 28),
        responsive.clamp(34, 28, 38),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          _Avatar(profile: profile),
          SizedBox(height: responsive.space(28)),
          Text(
            profile.userName.isEmpty ? 'Pengguna SplitSync' : profile.userName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF111111),
              fontSize: responsive.font(36),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: responsive.space(8)),
          Text(
            profile.email,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF6A6666),
              fontSize: responsive.font(21),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.profile});

  final ProfileDetails profile;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final initials = profile.userName.isNotEmpty
        ? profile.userName.trim().substring(0, 1).toUpperCase()
        : 'S';
    return Container(
      width: responsive.clamp(116, 96, 124),
      height: responsive.clamp(116, 96, 124),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFFFFDDE0),
        image: profile.avatarUrl.isEmpty
            ? null
            : DecorationImage(
                image: NetworkImage(profile.avatarUrl),
                fit: BoxFit.cover,
              ),
      ),
      child: profile.avatarUrl.isEmpty
          ? Center(
              child: Text(
                initials,
                style: TextStyle(
                  color: const Color(0xFFC8152B),
                  fontSize: responsive.font(42),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : null,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.value,
    required this.label,
    this.accent = false,
  });

  final String value;
  final String label;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      height: responsive.clamp(160, 138, 166),
      padding: EdgeInsets.symmetric(
        horizontal: responsive.clamp(14, 10, 16),
        vertical: responsive.clamp(22, 18, 24),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FittedBox(
            child: Text(
              value,
              style: TextStyle(
                color: accent
                    ? const Color(0xFFC8152B)
                    : const Color(0xFF111111),
                fontSize: responsive.font(54),
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
          SizedBox(height: responsive.space(13)),
          Text(
            label,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: const Color(0xFF5A5656),
              fontSize: responsive.font(17),
              fontWeight: FontWeight.w600,
              height: 1.18,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({required this.onLogout});

  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 14,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          const _SettingsTile(
            icon: Icons.person_outline_rounded,
            title: 'Pengaturan Akun',
            subtitle: 'Info pribadi, Password',
            destination: AccountSettingsPage(),
          ),
          const Divider(height: 1, color: Color(0xFFEDEDED)),
          const _SettingsTile(
            icon: Icons.notifications_none_rounded,
            title: 'Pengaturan Notifikasi',
            subtitle: 'Email, push, SMS',
            destination: NotificationSettingsPage(),
          ),
          const Divider(height: 1, color: Color(0xFFEDEDED)),
          const _SettingsTile(
            icon: Icons.credit_card_rounded,
            title: 'Metode Pembayaran',
            subtitle: 'Kartu, Bank Akun',
          ),
          const Divider(height: 1, color: Color(0xFFEDEDED)),
          _SettingsTile(
            icon: Icons.logout_rounded,
            title: 'Log Out',
            subtitle: '',
            danger: true,
            showChevron: false,
            onTap: onLogout,
          ),
        ],
      ),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.danger = false,
    this.showChevron = true,
    this.onTap,
    this.destination,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool danger;
  final bool showChevron;
  final VoidCallback? onTap;
  final Widget? destination;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final color = danger ? const Color(0xFFC8152B) : const Color(0xFF161616);
    return InkWell(
      onTap:
          onTap ??
          (destination == null
              ? null
              : () => Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => destination!))),
      borderRadius: BorderRadius.circular(28),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: responsive.clamp(24, 18, 26),
          vertical: responsive.clamp(20, 16, 22),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: responsive.clamp(26, 22, 28),
              backgroundColor: danger
                  ? const Color(0xFFFFDADB)
                  : const Color(0xFFECECEC),
              child: Icon(
                icon,
                color: color,
                size: responsive.clamp(27, 23, 29),
              ),
            ),
            SizedBox(width: responsive.space(20)),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: color,
                      fontSize: responsive.font(21),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (subtitle.isNotEmpty) ...[
                    SizedBox(height: responsive.space(3)),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: const Color(0xFF5F5A5A),
                        fontSize: responsive.font(16),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (showChevron)
              Icon(
                Icons.chevron_right_rounded,
                color: const Color(0xFF5A5656),
                size: responsive.clamp(30, 26, 32),
              ),
          ],
        ),
      ),
    );
  }
}

class _ProfileBottomNav extends StatelessWidget {
  const _ProfileBottomNav();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0F000000),
              blurRadius: 10,
              offset: Offset(0, -3),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _BottomItem(
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
            ),
            _BottomItem(
              icon: Icons.groups_2_outlined,
              label: 'Groups',
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
                    blurRadius: 14,
                    offset: Offset(0, 8),
                  ),
                ],
              ),
              child: const Icon(Icons.add, color: Colors.white, size: 34),
            ),
            _BottomItem(
              icon: Icons.analytics_outlined,
              label: 'Reports',
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed('/reports'),
            ),
            const _BottomItem(
              icon: Icons.person_outline_rounded,
              label: 'Profile',
              selected: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _BottomItem extends StatelessWidget {
  const _BottomItem({
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
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
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
            Icon(icon, color: color, size: 20),
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

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Padding(
      padding: responsive.horizontal(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFC8152B),
            size: 48,
          ),
          SizedBox(height: responsive.space(16)),
          Text(
            'Profil belum bisa dimuat',
            style: TextStyle(
              color: const Color(0xFF111B2C),
              fontSize: responsive.font(22),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: responsive.space(8)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF6A625F),
              fontSize: responsive.font(14),
            ),
          ),
          SizedBox(height: responsive.space(20)),
          FilledButton(
            onPressed: onBack,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC8152B),
            ),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}
