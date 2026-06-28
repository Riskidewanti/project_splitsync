import 'package:flutter/material.dart';

class SplitMember {
  const SplitMember({
    required this.name,
    required this.avatarText,
    required this.amount,
  });

  final String name;
  final String avatarText;
  final double amount;
}

class SplitCalculationPage extends StatelessWidget {
  const SplitCalculationPage({
    super.key,
    required this.totalAmount,
    required this.members,
    this.description = 'Pengeluaran',
    this.category = 'expense',
    this.groupName = 'Grup',
    this.expenseDate,
  });

  final double totalAmount;
  final List<SplitMember> members;
  final String description;
  final String category;
  final String groupName;
  final DateTime? expenseDate;

  static const Color _primary = Color(0xFF8D000B);
  static const Color _ink = Color(0xFF102033);
  static const Color _surface = Color(0xFFFFFAF7);
  static const Color _muted = Color(0xFF756B6B);
  static const Color _border = Color(0xFFE9EEF7);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: _ink,
        elevation: 2,
        shadowColor: Colors.black.withValues(alpha: 0.10),
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, size: 24),
        ),
        title: const Text(
          'Tambah Pengeluaran',
          style: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(14, 14, 14, 22),
              children: <Widget>[
                const _SuccessHeader(),
                const SizedBox(height: 18),
                _ExpenseSummaryCard(
                  category: _categoryLabel(category),
                  amount: totalAmount,
                  date: _formatDate(expenseDate ?? DateTime.now()),
                  description: description,
                ),
                const SizedBox(height: 14),
                _SplitHeader(participantCount: members.length),
                const SizedBox(height: 10),
                for (final SplitMember member in members) ...<Widget>[
                  _SplitPersonCard(member: member),
                  const SizedBox(height: 12),
                ],
                const SizedBox(height: 20),
                _PrimaryActionButton(groupName: groupName),
                const SizedBox(height: 14),
                const Row(
                  children: <Widget>[
                    Expanded(
                      child: _SecondaryActionButton(
                        icon: Icons.add,
                        label: 'Tambahkan lainnya',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _SecondaryActionButton(
                        icon: Icons.receipt_long,
                        label: 'Lihat Semua',
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  static String _categoryLabel(String value) {
    switch (value) {
      case 'food':
        return 'Food';
      case 'transport':
        return 'Transport';
      case 'travel':
        return 'Travel';
      case 'shopping':
        return 'Belanja';
      default:
        return value.isEmpty ? 'Expense' : value;
    }
  }

  static String _formatDate(DateTime value) {
    const List<String> months = <String>[
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${months[value.month - 1]} ${value.day}, ${value.year}';
  }
}

class _SuccessHeader extends StatelessWidget {
  const _SuccessHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        CircleAvatar(
          radius: 31,
          backgroundColor: SplitCalculationPage._primary,
          child: Icon(Icons.check, color: Colors.white, size: 34),
        ),
        SizedBox(height: 9),
        Text(
          'Pengeluaran Berhasil Disimpan',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SplitCalculationPage._ink,
            fontSize: 13,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 3),
        Text(
          'Berhasil ditambahkan ke grup',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: SplitCalculationPage._muted,
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }
}

class _ExpenseSummaryCard extends StatelessWidget {
  const _ExpenseSummaryCard({
    required this.category,
    required this.amount,
    required this.date,
    required this.description,
  });

  final String category;
  final double amount;
  final String date;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 19),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SplitCalculationPage._border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _CategoryPill(label: category),
              const Spacer(),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  Text(
                    _formatCurrency(amount),
                    style: const TextStyle(
                      color: SplitCalculationPage._primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    date,
                    style: const TextStyle(
                      color: SplitCalculationPage._muted,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 11),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: SplitCalculationPage._ink,
                fontSize: 13,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPill extends StatelessWidget {
  const _CategoryPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: const Color(0xFFE9E9FB),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Icon(
            Icons.restaurant,
            color: SplitCalculationPage._primary,
            size: 13,
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: const TextStyle(
              color: SplitCalculationPage._primary,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitHeader extends StatelessWidget {
  const _SplitHeader({required this.participantCount});

  final int participantCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Text(
          'RINCIAN PEMBAGIAN',
          style: TextStyle(
            color: Color(0xFF928989),
            fontSize: 13,
            letterSpacing: 0.2,
          ),
        ),
        const Spacer(),
        Text(
          '$participantCount Orang',
          style: const TextStyle(color: Color(0xFF5F5353), fontSize: 13),
        ),
      ],
    );
  }
}

class _SplitPersonCard extends StatelessWidget {
  const _SplitPersonCard({required this.member});

  final SplitMember member;

  @override
  Widget build(BuildContext context) {
    final bool isCurrentUser = member.name.toLowerCase() == 'you';
    final String displayName = isCurrentUser ? 'Alex M.' : member.name;
    final String subtitle = isCurrentUser
        ? 'Kamu membayar ini'
        : 'Berutang kepada Anda';

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: SplitCalculationPage._border),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: isCurrentUser
                ? SplitCalculationPage._primary
                : const Color(0xFF21424A),
            child: Text(
              member.avatarText,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SplitCalculationPage._ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: SplitCalculationPage._muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _formatCurrency(member.amount),
            style: TextStyle(
              color: isCurrentUser
                  ? SplitCalculationPage._ink
                  : SplitCalculationPage._primary,
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  const _PrimaryActionButton({required this.groupName});

  final String groupName;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 44,
      child: FilledButton.icon(
        style: FilledButton.styleFrom(
          backgroundColor: SplitCalculationPage._primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
        ),
        onPressed: () => Navigator.of(
          context,
        ).popUntil((Route<dynamic> route) => route.isFirst),
        icon: const Icon(Icons.groups, size: 18),
        label: Text(
          'Kembali ke ${groupName.isEmpty ? 'Grup' : 'Grup'}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ),
    );
  }
}

class _SecondaryActionButton extends StatelessWidget {
  const _SecondaryActionButton({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 38,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          foregroundColor: SplitCalculationPage._primary,
          side: const BorderSide(color: Color(0xFFE6B5B5)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(19),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10),
        ),
        onPressed: () {},
        icon: Icon(icon, size: 16),
        label: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }
}

String _formatCurrency(double value) {
 
  final String whole = value.toStringAsFixed(0);
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < whole.length; i++) {
    final int reverseIndex = whole.length - i;
    buffer.write(whole[i]);

    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write('.');
    }
  }

  return 'Rp ${buffer.toString()}';
}
