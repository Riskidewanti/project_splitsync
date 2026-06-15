import 'package:flutter/material.dart';

import 'confirm_expense_page.dart';

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

class SplitCalculationPage extends StatefulWidget {
  const SplitCalculationPage({
    super.key,
    required this.totalAmount,
    required this.members,
  });

  final double totalAmount;
  final List<SplitMember> members;

  @override
  State<SplitCalculationPage> createState() => _SplitCalculationPageState();
}

class _SplitCalculationPageState extends State<SplitCalculationPage> {
  int _selectedSegment = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF7F4),
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1F2933),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          onPressed: () => Navigator.maybePop(context),
          icon: const Icon(Icons.arrow_back, size: 20),
        ),
        title: const Text(
          'SplitSync',
          style: TextStyle(
            color: Color(0xFFD70F1F),
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Column(
                children: <Widget>[
                  const Text(
                    'Total Bill',
                    style: TextStyle(
                      color: Color(0xFF7A818C),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatCurrency(widget.totalAmount),
                    style: const TextStyle(
                      color: Color(0xFF1F2933),
                      fontSize: 38,
                      fontWeight: FontWeight.w800,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 26),
                  _SplitSegmentedControl(
                    selectedIndex: _selectedSegment,
                    onChanged: (int value) {
                      setState(() {
                        _selectedSegment = value;
                      });
                    },
                  ),
                  const SizedBox(height: 22),
                  _MemberListCard(
                    members: widget.members,
                    selectedSegment: _selectedSegment,
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFFD71920),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: () {},
                      icon: Container(
                        width: 28,
                        height: 28,
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFEEF0),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.add, size: 16),
                      ),
                      label: const Text(
                        'TAMBAH TEMAN',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                  ),
                  const Spacer(),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFC70F1B),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute<void>(
                            builder: (BuildContext context) {
                              return const ConfirmExpensePage(
                                merchantName: 'Whole Foods Market',
                                totalAmount: 142.50,
                                itemCount: 4,
                                note: null,
                                tags: <String>['dinner', 'supplies'],
                              );
                            },
                          ),
                        );
                      },
                      child: const Text(
                        'KIRIM',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SplitSegmentedControl extends StatelessWidget {
  const _SplitSegmentedControl({
    required this.selectedIndex,
    required this.onChanged,
  });

  final int selectedIndex;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    const List<String> labels = <String>['Pembagian', 'Persentase', 'Kustom'];

    return Container(
      width: double.infinity,
      height: 38,
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3E5EA),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: <Widget>[
          for (int index = 0; index < labels.length; index++)
            Expanded(
              child: _SegmentButton(
                label: labels[index],
                isSelected: selectedIndex == index,
                onTap: () => onChanged(index),
              ),
            ),
        ],
      ),
    );
  }
}

class _SegmentButton extends StatelessWidget {
  const _SegmentButton({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          boxShadow: isSelected
              ? <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected
                ? const Color(0xFFD71920)
                : const Color(0xFF707783),
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _MemberListCard extends StatelessWidget {
  const _MemberListCard({required this.members, required this.selectedSegment});

  final List<SplitMember> members;
  final int selectedSegment;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8EAEE)),
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: <Widget>[
          if (members.isEmpty)
            const Padding(
              padding: EdgeInsets.all(18),
              child: Text(
                'Belum ada teman',
                style: TextStyle(
                  color: Color(0xFF6B7280),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            )
          else
            for (int index = 0; index < members.length; index++) ...<Widget>[
              _MemberRow(
                member: members[index],
                selectedSegment: selectedSegment,
                percentage: _displayPercentageFor(index),
              ),
              if (index != members.length - 1)
                const Divider(height: 1, color: Color(0xFFE8EAEE)),
            ],
        ],
      ),
    );
  }

  int _displayPercentageFor(int index) {
    if (index == 0) {
      return 50;
    }

    return 30;
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.selectedSegment,
    required this.percentage,
  });

  final SplitMember member;
  final int selectedSegment;
  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      child: Row(
        children: <Widget>[
          CircleAvatar(
            radius: 20,
            backgroundColor: const Color(0xFFFFE7E8),
            child: Text(
              member.avatarText,
              style: const TextStyle(
                color: Color(0xFFD71920),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              member.name,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          if (selectedSegment == 1) ...<Widget>[
            const SizedBox(width: 10),
            _PercentageBox(percentage: percentage),
            const SizedBox(width: 16),
          ],
          Text(
            _formatCurrency(member.amount),
            style: TextStyle(
              color: member.name.toLowerCase() == 'you'
                  ? const Color(0xFFD71920)
                  : const Color(0xFF111827),
              fontSize: 13,
              fontWeight: FontWeight.w800,
            ),
          ),
          if (selectedSegment == 2) ...<Widget>[
            const SizedBox(width: 16),
            IconButton(
              constraints: const BoxConstraints.tightFor(width: 32, height: 32),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              onPressed: () {},
              icon: const Icon(
                Icons.edit_outlined,
                size: 17,
                color: Color(0xFF4B5563),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _PercentageBox extends StatelessWidget {
  const _PercentageBox({required this.percentage});

  final int percentage;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 66,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '$percentage',
            style: const TextStyle(
              color: Color(0xFF475067),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(width: 7),
          const Text(
            '%',
            style: TextStyle(
              color: Color(0xFF8A92A3),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

String _formatCurrency(double value) {
  final String fixed = value.toStringAsFixed(2);
  final List<String> parts = fixed.split('.');
  final String whole = parts.first;
  final StringBuffer buffer = StringBuffer();

  for (int i = 0; i < whole.length; i++) {
    final int reverseIndex = whole.length - i;
    buffer.write(whole[i]);
    if (reverseIndex > 1 && reverseIndex % 3 == 1) {
      buffer.write(',');
    }
  }

  return '\$${buffer.toString()}.${parts.last}';
}
