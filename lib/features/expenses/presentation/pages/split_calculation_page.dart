import 'package:flutter/material.dart';

import '../../../ocr/presentation/pages/edit_items_page.dart';
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
    required this.merchantName,
    required this.expenseDate,
    required this.items,
    required this.subtotal,
    required this.tax,
    required this.serviceFee,
    required this.totalAmount,
    required this.members,
  });

  final String merchantName;
  final DateTime? expenseDate;
  final List<ReceiptItem> items;
  final double subtotal;
  final double tax;
  final double serviceFee;
  final double totalAmount;
  final List<SplitMember> members;

  @override
  State<SplitCalculationPage> createState() => _SplitCalculationPageState();
}

class _SplitCalculationPageState extends State<SplitCalculationPage> {
  int _selectedSegment = 0;
  late List<TextEditingController> _percentageControllers;
  late List<TextEditingController> _customAmountControllers;

  @override
  void initState() {
    super.initState();
    _percentageControllers = _buildPercentageControllers();
    _customAmountControllers = _buildCustomAmountControllers();
  }

  @override
  void didUpdateWidget(covariant SplitCalculationPage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.members.length != widget.members.length ||
        oldWidget.totalAmount != widget.totalAmount) {
      _disposeControllers(_percentageControllers);
      _disposeControllers(_customAmountControllers);
      _percentageControllers = _buildPercentageControllers();
      _customAmountControllers = _buildCustomAmountControllers();
    }
  }

  @override
  void dispose() {
    _disposeControllers(_percentageControllers);
    _disposeControllers(_customAmountControllers);
    super.dispose();
  }

  List<TextEditingController> _buildPercentageControllers() {
    if (widget.members.isEmpty) {
      return <TextEditingController>[];
    }

    final double basePercentage = 100 / widget.members.length;
    double assignedPercentage = 0;

    return List<TextEditingController>.generate(widget.members.length, (
      int index,
    ) {
      final double percentage = index == widget.members.length - 1
          ? 100 - assignedPercentage
          : basePercentage;
      assignedPercentage += percentage;

      return TextEditingController(text: _formatInputNumber(percentage))
        ..addListener(_recalculate);
    });
  }

  List<TextEditingController> _buildCustomAmountControllers() {
    return widget.members.map((SplitMember member) {
      return TextEditingController(text: _formatInputNumber(member.amount))
        ..addListener(_recalculate);
    }).toList();
  }

  void _disposeControllers(List<TextEditingController> controllers) {
    for (final TextEditingController controller in controllers) {
      controller.dispose();
    }
  }

  void _recalculate() {
    if (mounted) {
      setState(() {});
    }
  }

  List<double> get _splitAmounts {
    if (widget.members.isEmpty) {
      return <double>[];
    }

    if (_selectedSegment == 1) {
      return _percentageControllers.map((TextEditingController controller) {
        final double percentage = _parseNumber(controller.text);
        return widget.totalAmount * percentage / 100;
      }).toList();
    }

    if (_selectedSegment == 2) {
      return _customAmountControllers.map((TextEditingController controller) {
        return _parseNumber(controller.text);
      }).toList();
    }

    final double equalAmount = widget.totalAmount / widget.members.length;
    return List<double>.filled(widget.members.length, equalAmount);
  }

  String? get _validationMessage {
    if (_selectedSegment == 1) {
      final double totalPercentage = _percentageControllers.fold<double>(
        0,
        (double total, TextEditingController controller) =>
            total + _parseNumber(controller.text),
      );

      if ((totalPercentage - 100).abs() > 0.01) {
        return 'Total persentase harus 100%.';
      }
    }

    if (_selectedSegment == 2) {
      final double assignedTotal = _customAmountControllers.fold<double>(
        0,
        (double total, TextEditingController controller) =>
            total + _parseNumber(controller.text),
      );

      if ((assignedTotal - widget.totalAmount).abs() > 0.01) {
        return 'Total kustom harus ${_formatCurrency(widget.totalAmount)}.';
      }
    }

    return null;
  }

  String get _selectedSplitMethod {
    return switch (_selectedSegment) {
      1 => 'percentage',
      2 => 'custom',
      _ => 'equal',
    };
  }

  double get _currentUserSplitAmount {
    if (_splitAmounts.isEmpty) {
      return widget.totalAmount;
    }

    final int currentUserIndex = widget.members.indexWhere(
      (SplitMember member) => member.name.toLowerCase() == 'you',
    );
    final int index = currentUserIndex == -1 ? 0 : currentUserIndex;

    return _splitAmounts[index];
  }

  double? get _currentUserPercentage {
    if (_selectedSegment == 1 && _percentageControllers.isNotEmpty) {
      final int currentUserIndex = widget.members.indexWhere(
        (SplitMember member) => member.name.toLowerCase() == 'you',
      );
      final int index = currentUserIndex == -1 ? 0 : currentUserIndex;

      return _parseNumber(_percentageControllers[index].text);
    }

    if (_selectedSegment == 0 && widget.members.isNotEmpty) {
      return 100 / widget.members.length;
    }

    return null;
  }

  void _submit() {
    final String? validationMessage = _validationMessage;
    if (validationMessage != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(validationMessage)));
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return ConfirmExpensePage(
            merchantName: widget.merchantName,
            expenseDate: widget.expenseDate,
            items: widget.items,
            subtotal: widget.subtotal,
            tax: widget.tax,
            serviceFee: widget.serviceFee,
            totalAmount: widget.totalAmount,
            itemCount: widget.items.length,
            participantCount: widget.members.length,
            splitMethod: _selectedSplitMethod,
            currentUserSplitAmount: _currentUserSplitAmount,
            currentUserPercentage: _currentUserPercentage,
            note: null,
            tags: <String>['dinner', 'supplies'],
          );
        },
      ),
    );
  }

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
                    amounts: _splitAmounts,
                    percentageControllers: _percentageControllers,
                    customAmountControllers: _customAmountControllers,
                  ),
                  if (_validationMessage != null) ...<Widget>[
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _validationMessage!,
                        style: const TextStyle(
                          color: Color(0xFFD71920),
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
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
                      onPressed: _submit,
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
  const _MemberListCard({
    required this.members,
    required this.selectedSegment,
    required this.amounts,
    required this.percentageControllers,
    required this.customAmountControllers,
  });

  final List<SplitMember> members;
  final int selectedSegment;
  final List<double> amounts;
  final List<TextEditingController> percentageControllers;
  final List<TextEditingController> customAmountControllers;

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
                amount: amounts[index],
                percentageController: percentageControllers[index],
                customAmountController: customAmountControllers[index],
              ),
              if (index != members.length - 1)
                const Divider(height: 1, color: Color(0xFFE8EAEE)),
            ],
        ],
      ),
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.member,
    required this.selectedSegment,
    required this.amount,
    required this.percentageController,
    required this.customAmountController,
  });

  final SplitMember member;
  final int selectedSegment;
  final double amount;
  final TextEditingController percentageController;
  final TextEditingController customAmountController;

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
            _PercentageBox(controller: percentageController),
            const SizedBox(width: 16),
          ],
          if (selectedSegment == 2) ...<Widget>[
            const SizedBox(width: 10),
            _AmountBox(controller: customAmountController),
            const SizedBox(width: 16),
          ] else
            Text(
              _formatCurrency(amount),
              style: TextStyle(
                color: member.name.toLowerCase() == 'you'
                    ? const Color(0xFFD71920)
                    : const Color(0xFF111827),
                fontSize: 13,
                fontWeight: FontWeight.w800,
              ),
            ),
          if (selectedSegment == 2) ...<Widget>[
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
  const _PercentageBox({required this.controller});

  final TextEditingController controller;

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
          SizedBox(
            width: 34,
            child: TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              textAlign: TextAlign.center,
              decoration: const InputDecoration(
                border: InputBorder.none,
                isCollapsed: true,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                color: Color(0xFF475067),
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 3),
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

class _AmountBox extends StatelessWidget {
  const _AmountBox({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 92,
      height: 30,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFF0F2F7),
        borderRadius: BorderRadius.circular(6),
      ),
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        textAlign: TextAlign.center,
        decoration: const InputDecoration(
          prefixText: r'$ ',
          prefixStyle: TextStyle(
            color: Color(0xFF8A92A3),
            fontSize: 12,
            fontWeight: FontWeight.w800,
          ),
          border: InputBorder.none,
          isCollapsed: true,
          contentPadding: EdgeInsets.zero,
        ),
        style: const TextStyle(
          color: Color(0xFF111827),
          fontSize: 12,
          fontWeight: FontWeight.w800,
        ),
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

String _formatInputNumber(double value) {
  final String fixed = value.toStringAsFixed(2);
  if (fixed.endsWith('.00')) {
    return fixed.substring(0, fixed.length - 3);
  }

  return fixed;
}

double _parseNumber(String value) {
  final String normalized = value
      .replaceAll(',', '')
      .replaceAll(r'$', '')
      .trim();
  return double.tryParse(normalized) ?? 0;
}
