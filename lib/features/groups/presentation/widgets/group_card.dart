import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';
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
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppRadius.sm),
        border: Border.all(color: const Color(0xFFE7E0DC)),
        boxShadow: <BoxShadow>[
          const BoxShadow(
            color: Color(0x0D000000),
            blurRadius: 8,
            offset: Offset(0, 4),
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
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.titleSmall?.copyWith(
                        color: const Color(0xFF111827),
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: textTheme.bodySmall?.copyWith(
                        color: const Color(0xFF6F625F),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              _AmountStatus(
                amount: amount,
                statusLabel: statusLabel,
                statusStyle: statusStyle,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
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
        borderRadius: BorderRadius.circular(AppRadius.sm),
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
        return const Color(0xFF6B4D49);
    }
  }

  Color _statusBackgroundColor() {
    switch (statusStyle) {
      case GroupCardStatusStyle.red:
        return const Color(0x1EDC2626);
      case GroupCardStatusStyle.blue:
        return const Color(0x1E2563EB);
      case GroupCardStatusStyle.gray:
        return const Color(0x1E6B4D49);
    }
  }

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme.of(context).textTheme;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: <Widget>[
        Text(
          formatRupiah(amount),
          textAlign: TextAlign.right,
          style: textTheme.titleSmall?.copyWith(
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: _statusBackgroundColor(),
            borderRadius: BorderRadius.circular(AppRadius.pill),
          ),
          child: Text(
            statusLabel,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.labelMedium?.copyWith(
              color: _statusColor(),
              fontWeight: FontWeight.w700,
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
    final TextTheme textTheme = Theme.of(context).textTheme;
    final List<Widget> chips = <Widget>[];

    for (var i = 0; i < initials.length; i++) {
      chips.add(
        Padding(
          padding: const EdgeInsets.only(right: AppSpacing.xs),
          child: _AvatarChip(label: initials[i], textTheme: textTheme),
        ),
      );
    }

    if (extraCount > 0) {
      chips.add(_AvatarChip(label: '+$extraCount', textTheme: textTheme));
    }

    return Row(children: chips);
  }
}

class _AvatarChip extends StatelessWidget {
  const _AvatarChip({required this.label, required this.textTheme});

  final String label;
  final TextTheme textTheme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 32,
      height: 32,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: Color(0xFFF3F2F1),
        shape: BoxShape.circle,
      ),
      child: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: textTheme.labelMedium?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
