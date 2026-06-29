import 'package:flutter/material.dart';

import '../../widgets/responsive.dart';

class NotificationSettingsPage extends StatefulWidget {
  const NotificationSettingsPage({super.key});

  @override
  State<NotificationSettingsPage> createState() =>
      _NotificationSettingsPageState();
}

class _NotificationSettingsPageState extends State<NotificationSettingsPage> {
  bool _transactionPush = true;
  bool _transactionEmail = true;
  bool _groupPush = true;
  bool _groupEmail = false;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _NotificationAppBar(responsive: responsive),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  responsive.clamp(46, 24, 52),
                  responsive.space(34),
                  responsive.clamp(46, 24, 52),
                  responsive.space(28),
                ),
                child: ResponsivePage(
                  maxWidth: 430,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pengaturan Notifikasi',
                        style: TextStyle(
                          color: const Color(0xFF171717),
                          fontSize: responsive.font(24),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: responsive.space(22)),
                      Text(
                        'Atur cara Anda menerima notifikasi dan\npembaruan.',
                        style: TextStyle(
                          color: const Color(0xFF5C4545),
                          fontSize: responsive.font(23),
                          fontWeight: FontWeight.w500,
                          height: 1.42,
                        ),
                      ),
                      SizedBox(height: responsive.space(58)),
                      _NotificationCard(
                        icon: Icons.payments_outlined,
                        title: 'Peringatan Transaksi',
                        children: [
                          _NotificationOption(
                            title: 'Notifikasi Push',
                            subtitle:
                                'Terima notifikasi secara\nlangsung di perangkat Anda.',
                            enabled: _transactionPush,
                            onChanged: (value) =>
                                setState(() => _transactionPush = value),
                          ),
                          SizedBox(height: responsive.space(32)),
                          _NotificationOption(
                            title: 'Notifikasi Email',
                            subtitle:
                                'Kuitansi dan ringkasan\ntransaksi yang detail',
                            enabled: _transactionEmail,
                            onChanged: (value) =>
                                setState(() => _transactionEmail = value),
                          ),
                        ],
                      ),
                      SizedBox(height: responsive.space(50)),
                      _NotificationCard(
                        icon: Icons.groups_2_outlined,
                        title: 'Group Activity',
                        children: [
                          _NotificationOption(
                            title: 'Push Notifications',
                            subtitle: 'New bills added to groups.',
                            enabled: _groupPush,
                            onChanged: (value) =>
                                setState(() => _groupPush = value),
                          ),
                          SizedBox(height: responsive.space(32)),
                          _NotificationOption(
                            title: 'Email Notifications',
                            subtitle: 'Weekly group summaries.',
                            enabled: _groupEmail,
                            onChanged: (value) =>
                                setState(() => _groupEmail = value),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const _NotificationBottomNav(),
    );
  }
}

class _NotificationAppBar extends StatelessWidget {
  const _NotificationAppBar({required this.responsive});

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
          SizedBox(width: responsive.space(46)),
          Expanded(
            child: Text(
              'Pengaturan Notifikasi',
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

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final IconData icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        responsive.clamp(26, 20, 28),
        responsive.clamp(28, 22, 30),
        responsive.clamp(26, 20, 28),
        responsive.clamp(32, 26, 34),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        border: Border.all(color: const Color(0xFFE0E0E0)),
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
          Row(
            children: [
              CircleAvatar(
                radius: responsive.clamp(24, 20, 25),
                backgroundColor: const Color(0xFFFFD5DB),
                child: Icon(
                  icon,
                  color: const Color(0xFFC8152B),
                  size: responsive.clamp(27, 23, 29),
                ),
              ),
              SizedBox(width: responsive.space(20)),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: const Color(0xFF202020),
                    fontSize: responsive.font(24),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: responsive.space(28)),
          const Divider(height: 1, color: Color(0xFFE8E8E8)),
          SizedBox(height: responsive.space(28)),
          ...children,
        ],
      ),
    );
  }
}

class _NotificationOption extends StatelessWidget {
  const _NotificationOption({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF202020),
                  fontSize: responsive.font(22),
                  fontWeight: FontWeight.w800,
                ),
              ),
              SizedBox(height: responsive.space(8)),
              Text(
                subtitle,
                style: TextStyle(
                  color: const Color(0xFF5C4545),
                  fontSize: responsive.font(21),
                  fontWeight: FontWeight.w500,
                  height: 1.38,
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: responsive.space(14)),
        _SplitSyncSwitch(value: enabled, onChanged: onChanged),
      ],
    );
  }
}

class _SplitSyncSwitch extends StatelessWidget {
  const _SplitSyncSwitch({required this.value, required this.onChanged});

  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final width = responsive.clamp(70, 58, 72);
    final height = responsive.clamp(38, 32, 40);
    final knob = responsive.clamp(42, 34, 44);
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: SizedBox(
        width: width + (value ? responsive.space(8) : 0),
        height: knob,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Align(
              alignment: value ? Alignment.centerLeft : Alignment.center,
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(
                  color: value
                      ? const Color(0xFFC8152B)
                      : const Color(0xFFE7E8EA),
                  borderRadius: BorderRadius.circular(24),
                  border: value
                      ? null
                      : Border.all(color: const Color(0xFF7B8492), width: 4),
                ),
              ),
            ),
            AnimatedAlign(
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOut,
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: knob,
                height: knob,
                decoration: const BoxDecoration(
                  color: Color(0xFF2F6BEA),
                  shape: BoxShape.circle,
                ),
                child: value
                    ? Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: responsive.clamp(27, 22, 29),
                      )
                    : null,
              ),
            ),
            if (!value)
              Align(
                alignment: Alignment.centerLeft,
                child: Container(
                  width: knob,
                  height: knob,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFFD9DDE2),
                      width: 2,
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

class _NotificationBottomNav extends StatelessWidget {
  const _NotificationBottomNav();

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
            _BottomItem(
              icon: Icons.home_rounded,
              label: 'Home',
              onTap: () => Navigator.of(context).pushReplacementNamed('/home'),
            ),
            _BottomItem(
              icon: Icons.groups_2_outlined,
              label: 'Groups',
              onTap: () => Navigator.of(context).pushReplacementNamed('/groups'),
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
            _BottomItem(
              icon: Icons.analytics_outlined,
              label: 'Reports',
              onTap: () => Navigator.of(context).pushReplacementNamed('/reports'),
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
