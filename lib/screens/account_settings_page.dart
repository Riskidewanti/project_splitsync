import 'package:flutter/material.dart';

import '../authentication/auth_service.dart';
import '../widgets/responsive.dart';

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late final Future<ProfileDetails> _profileFuture;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.fetchCurrentProfile();
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
              return _AccountErrorState(
                message: snapshot.error.toString(),
                onBack: () => Navigator.of(context).pop(),
              );
            }

            return _AccountSettingsBody(profile: snapshot.requireData);
          },
        ),
      ),
      bottomNavigationBar: const _AccountBottomNav(),
    );
  }
}

class _AccountSettingsBody extends StatelessWidget {
  const _AccountSettingsBody({required this.profile});

  final ProfileDetails profile;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Column(
      children: [
        _AccountAppBar(responsive: responsive),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              responsive.clamp(42, 26, 44),
              responsive.space(34),
              responsive.clamp(42, 26, 44),
              responsive.space(34),
            ),
            child: ResponsivePage(
              maxWidth: 430,
              child: Column(
                children: [
                  _AccountHeader(profile: profile),
                  SizedBox(height: responsive.space(50)),
                  _InfoCard(profile: profile),
                  SizedBox(height: responsive.space(52)),
                  const _PreferenceCard(),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountAppBar extends StatelessWidget {
  const _AccountAppBar({required this.responsive});

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
          SizedBox(width: responsive.space(56)),
          Expanded(
            child: Text(
              'Pengaturan Akun',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF111B2C),
                fontSize: responsive.font(26),
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({required this.profile});

  final ProfileDetails profile;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final name = profile.userName.isEmpty
        ? 'Pengguna SplitSync'
        : profile.userName;
    return Column(
      children: [
        _AccountAvatar(profile: profile),
        SizedBox(height: responsive.space(26)),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF111111),
            fontSize: responsive.font(27),
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: responsive.space(4)),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF5F5A5A),
            fontSize: responsive.font(18),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({required this.profile});

  final ProfileDetails profile;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final initials = profile.userName.isNotEmpty
        ? profile.userName.trim().substring(0, 1).toUpperCase()
        : 'S';

    return Container(
      width: responsive.clamp(104, 90, 112),
      height: responsive.clamp(104, 90, 112),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF151F2A),
        boxShadow: const [
          BoxShadow(
            color: Color(0x12000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
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
                  color: Colors.white,
                  fontSize: responsive.font(36),
                  fontWeight: FontWeight.w900,
                ),
              ),
            )
          : null,
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.profile});

  final ProfileDetails profile;

  @override
  Widget build(BuildContext context) {
    final name = profile.userName.isEmpty
        ? 'Pengguna SplitSync'
        : profile.userName;
    final phone = profile.phone.isEmpty ? 'Belum ditambahkan' : profile.phone;
    return _SectionCard(
      title: 'INFO PRIBADI',
      children: [
        _EditableInfoRow(label: 'Nama', value: name),
        const _ThinDivider(),
        _EditableInfoRow(label: 'Email', value: profile.email),
        const _ThinDivider(),
        _EditableInfoRow(label: 'Nomor Hp', value: phone),
      ],
    );
  }
}

class _PreferenceCard extends StatelessWidget {
  const _PreferenceCard();

  @override
  Widget build(BuildContext context) {
    return _SectionCard(
      title: 'PREFERENSI',
      children: const [
        _ThemePreferenceRow(),
        _ThinDivider(),
        _ChevronInfoRow(title: 'Bahasa', subtitle: 'English (US)'),
        _ThinDivider(),
        _ChevronInfoRow(title: 'Mata Uang', subtitle: 'Rupiah\n(Rp)'),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        responsive.clamp(28, 22, 30),
        responsive.clamp(28, 24, 30),
        responsive.clamp(28, 22, 30),
        responsive.clamp(24, 20, 26),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFECECEC)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 16,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFFC8152B),
              fontSize: responsive.font(16),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: responsive.space(34)),
          ...children,
        ],
      ),
    );
  }
}

class _EditableInfoRow extends StatelessWidget {
  const _EditableInfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.space(6)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: const Color(0xFF5D5353),
                    fontSize: responsive.font(13),
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: responsive.space(8)),
                Text(
                  value,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF181818),
                    fontSize: responsive.font(18),
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.space(16)),
          Icon(
            Icons.edit_rounded,
            color: const Color(0xFF5F5F5F),
            size: responsive.clamp(23, 20, 25),
          ),
        ],
      ),
    );
  }
}

class _ThemePreferenceRow extends StatelessWidget {
  const _ThemePreferenceRow();

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.space(6)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Tampilan Aplikasi',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF181818),
                    fontSize: responsive.font(18),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: responsive.space(7)),
                Text(
                  'System Default',
                  style: TextStyle(
                    color: const Color(0xFF5D5353),
                    fontSize: responsive.font(13),
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: responsive.space(14)),
          Container(
            width: responsive.clamp(112, 102, 118),
            height: responsive.clamp(42, 38, 44),
            padding: EdgeInsets.all(responsive.space(5)),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0),
              borderRadius: BorderRadius.circular(22),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _ModeIcon(
                  icon: Icons.brightness_6_rounded,
                  selected: true,
                  size: responsive.clamp(31, 28, 33),
                ),
                _ModeIcon(
                  icon: Icons.wb_sunny_outlined,
                  size: responsive.clamp(31, 28, 33),
                ),
                _ModeIcon(
                  icon: Icons.nightlight_round,
                  size: responsive.clamp(31, 28, 33),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ModeIcon extends StatelessWidget {
  const _ModeIcon({
    required this.icon,
    required this.size,
    this.selected = false,
  });

  final IconData icon;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: selected ? Colors.white : Colors.transparent,
        shape: BoxShape.circle,
        boxShadow: selected
            ? const [
                BoxShadow(
                  color: Color(0x11000000),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: Icon(icon, color: const Color(0xFF2C2C2C), size: size * 0.62),
    );
  }
}

class _ChevronInfoRow extends StatelessWidget {
  const _ChevronInfoRow({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.space(6)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: const Color(0xFF181818),
                    fontSize: responsive.font(18),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: responsive.space(7)),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF4F4B4B),
                    fontSize: responsive.font(13),
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: const Color(0xFF555555),
            size: responsive.clamp(27, 24, 30),
          ),
        ],
      ),
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.space(16)),
      child: const Divider(height: 1, color: Color(0xFFEDEDED)),
    );
  }
}

class _AccountBottomNav extends StatelessWidget {
  const _AccountBottomNav();

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return SafeArea(
      top: false,
      child: Container(
        height: responsive.clamp(96, 86, 100),
        padding: EdgeInsets.symmetric(
          horizontal: responsive.clamp(28, 14, 30),
          vertical: responsive.space(8),
        ),
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
            _AccountBottomItem(
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () =>
                  Navigator.of(context).popUntil((route) => route.isFirst),
            ),
            const _AccountBottomItem(
              icon: Icons.groups_2_outlined,
              label: 'Groups',
            ),
            Container(
              width: responsive.clamp(72, 62, 76),
              height: responsive.clamp(72, 62, 76),
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
              child: Icon(
                Icons.add,
                color: Colors.white,
                size: responsive.clamp(44, 36, 46),
              ),
            ),
            const _AccountBottomItem(
              icon: Icons.analytics_outlined,
              label: 'Reports',
            ),
            const _AccountBottomItem(
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

class _AccountBottomItem extends StatelessWidget {
  const _AccountBottomItem({
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
    final responsive = Responsive.of(context);
    final color = selected ? const Color(0xFFC8152B) : const Color(0xFF5A5A5A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        width: responsive.clamp(76, 54, 78),
        height: responsive.clamp(64, 56, 68),
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFFFFDADB),
                borderRadius: BorderRadius.circular(18),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: responsive.clamp(28, 23, 30)),
            SizedBox(height: responsive.space(3)),
            FittedBox(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: responsive.font(13),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountErrorState extends StatelessWidget {
  const _AccountErrorState({required this.message, required this.onBack});

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
            'Pengaturan akun belum bisa dimuat',
            textAlign: TextAlign.center,
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
