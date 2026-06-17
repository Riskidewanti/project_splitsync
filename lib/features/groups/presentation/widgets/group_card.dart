import 'package:flutter/material.dart';

enum GroupCardStatusStyle { red, gray, blue }

class GroupCard extends StatelessWidget {
  const GroupCard({
    super.key,
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
  final String amount;
  final String statusLabel;
  final GroupCardStatusStyle statusStyle;
  final IconData icon;
  final List<String> memberInitials;
  final int extraMemberCount;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 108),
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE7E0DC)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _GroupIconTile(icon: icon),
              const SizedBox(width: 8),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF111827),
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Color(0xFF6F625F),
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _AmountStatus(
                amount: amount,
                statusLabel: statusLabel,
                statusStyle: statusStyle,
              ),
            ],
          ),
          const Spacer(),
          Row(
            children: <Widget>[
              Expanded(
                child: _MemberAvatarRow(
                  initials: memberInitials,
                  extraCount: extraMemberCount,
                ),
              ),
              const Icon(
                Icons.chevron_right,
                color: Color(0xFF6B4D49),
                size: 24,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GroupIconTile extends StatelessWidget {
  const _GroupIconTile({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFDDEBFF),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Icon(icon, color: const Color(0xFF53606F), size: 20),
    );
  }
}

class _AmountStatus extends StatelessWidget {
  const _AmountStatus({
    required this.amount,
    required this.statusLabel,
    required this.statusStyle,
  });

  final String amount;
  final String statusLabel;
  final GroupCardStatusStyle statusStyle;

  @override
  Widget build(BuildContext context) {
    final _StatusColors colors = _statusColors(statusStyle);

    return SizedBox(
      width: 94,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[
          Text(
            amount,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              color: statusStyle == GroupCardStatusStyle.red
                  ? const Color(0xFFC70F1B)
                  : const Color(0xFF4C3E3B),
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 5),
          Container(
            constraints: const BoxConstraints(maxWidth: 94),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: colors.background,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              statusLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: colors.foreground,
                fontSize: 9,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  _StatusColors _statusColors(GroupCardStatusStyle style) {
    return switch (style) {
      GroupCardStatusStyle.red => const _StatusColors(
        background: Color(0xFFFFECEE),
        foreground: Color(0xFFC70F1B),
      ),
      GroupCardStatusStyle.gray => const _StatusColors(
        background: Color(0xFFE7E3E0),
        foreground: Color(0xFF6D625F),
      ),
      GroupCardStatusStyle.blue => const _StatusColors(
        background: Color(0xFFDCEAFF),
        foreground: Color(0xFF4D6F9F),
      ),
    };
  }
}

class _StatusColors {
  const _StatusColors({required this.background, required this.foreground});

  final Color background;
  final Color foreground;
}

class _MemberAvatarRow extends StatelessWidget {
  const _MemberAvatarRow({required this.initials, required this.extraCount});

  final List<String> initials;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 24,
      child: Stack(
        clipBehavior: Clip.none,
        children: <Widget>[
          for (int index = 0; index < initials.length; index++)
            Positioned(
              left: index * 16,
              child: _MemberAvatar(
                label: initials[index],
                backgroundColor: _avatarColor(index),
              ),
            ),
          if (extraCount > 0)
            Positioned(
              left: initials.length * 16,
              child: _MemberAvatar(
                label: '+$extraCount',
                backgroundColor: const Color(0xFFE8EEFF),
                foregroundColor: const Color(0xFF516078),
              ),
            ),
        ],
      ),
    );
  }

  Color _avatarColor(int index) {
    const List<Color> colors = <Color>[
      Color(0xFFDFE7E5),
      Color(0xFFEAD8CC),
      Color(0xFFD8E1EF),
      Color(0xFFE5D8E9),
    ];

    return colors[index % colors.length];
  }
}

class _MemberAvatar extends StatelessWidget {
  const _MemberAvatar({
    required this.label,
    required this.backgroundColor,
    this.foregroundColor = const Color(0xFF2E2A28),
  });

  final String label;
  final Color backgroundColor;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: backgroundColor,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 1.4),
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.clip,
        style: TextStyle(
          color: foregroundColor,
          fontSize: label.startsWith('+') ? 9 : 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
