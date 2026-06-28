import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';

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
  final num amount;
  final String statusLabel;
  final GroupCardStatusStyle statusStyle;
  final IconData icon;
  final List<String> memberInitials;
  final int extraMemberCount;

  @override
Widget build(BuildContext context) {
  return Container(
    width: double.infinity,
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
      mainAxisSize: MainAxisSize.min,
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

        const SizedBox(height: 16),

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
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2F1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(icon, size: 20, color: const Color(0xFF6B4D49)),
    );
  }
}

class _AmountStatus extends StatelessWidget {
  const _AmountStatus({
    required this.amount,
    required this.statusLabel,
    required this.statusStyle,
  });

  final num amount;
  final String statusLabel;
  final GroupCardStatusStyle statusStyle;

  Color _statusColor() {
    switch (statusStyle) {
      case GroupCardStatusStyle.red:
        return const Color(0xFFDC2626);
      case GroupCardStatusStyle.blue:
        return const Color(0xFF2563EB);
      case GroupCardStatusStyle.gray:
      default:
        return const Color(0xFF6B4D49);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          formatRupiah(amount),
          style: const TextStyle(
            color: Color(0xFF111827),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusColor().withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            statusLabel,
            style: TextStyle(
              color: _statusColor(),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _MemberAvatarRow extends StatelessWidget {
  const _MemberAvatarRow({required this.initials, required this.extraCount});
  final List<String> initials;
  final int extraCount;

  @override
  Widget build(BuildContext context) {
    final List<Widget> chips = [];
    for (var i = 0; i < initials.length; i++) {
      chips.add(Container(
        margin: const EdgeInsets.only(right: 6),
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFF3F2F1),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text(
          initials[i],
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
        ),
      ));
    }
    if (extraCount > 0) {
      chips.add(Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: const Color(0xFFECECEC),
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Text('+$extraCount', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
      ));
    }

    return Row(children: chips);
  }
}
