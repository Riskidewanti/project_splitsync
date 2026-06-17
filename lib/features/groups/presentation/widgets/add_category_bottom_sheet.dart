import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CategoryDraft {
  const CategoryDraft({
    required this.name,
    required this.icon,
    required this.monthlyBudget,
  });

  final String name;
  final IconData icon;
  final double monthlyBudget;
}

class AddCategoryBottomSheet extends StatefulWidget {
  const AddCategoryBottomSheet({super.key});

  @override
  State<AddCategoryBottomSheet> createState() => _AddCategoryBottomSheetState();
}

class _AddCategoryBottomSheetState extends State<AddCategoryBottomSheet> {
  static const Color _backgroundColor = Color(0xFFFBF7F4);
  static const Color _primaryRed = Color(0xFFC70F1B);
  static const Color _darkRed = Color(0xFF76000A);
  static const Color _textColor = Color(0xFF3F3633);
  static const Color _mutedTextColor = Color(0xFF6F625F);
  static const Color _fieldColor = Color(0xFFFAF6F0);
  static const Color _unselectedIconColor = Color(0xFFF4EFEA);

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _budgetController = TextEditingController();
  int _selectedIconIndex = 0;

  static const List<_IconOption> _iconOptions = <_IconOption>[
    _IconOption(label: 'Kebutuhan', icon: Icons.flash_on_outlined),
    _IconOption(label: 'Coffee', icon: Icons.local_cafe_outlined),
    _IconOption(label: 'Hadiah', icon: Icons.card_giftcard_outlined),
    _IconOption(label: 'Kesehatan', icon: Icons.local_hospital_outlined),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _budgetController.dispose();
    super.dispose();
  }

  void _confirm() {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      return;
    }

    final double budget = double.tryParse(_budgetController.text.trim()) ?? 0;
    final _IconOption selectedIcon = _iconOptions[_selectedIconIndex];

    Navigator.of(context).pop(
      CategoryDraft(name: name, icon: selectedIcon.icon, monthlyBudget: budget),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double keyboardInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      top: false,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: EdgeInsets.only(bottom: keyboardInset),
        child: DecoratedBox(
          decoration: const BoxDecoration(
            color: _backgroundColor,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(24, 16, 20, 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Center(child: _DragHandle()),
                const SizedBox(height: 17),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    const Expanded(
                      child: Text(
                        'Tambah Kategori Baru',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: _darkRed,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close, size: 23),
                      color: const Color(0xFF4B4441),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints.tightFor(
                        width: 36,
                        height: 36,
                      ),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 23),
                _LabeledInput(
                  label: 'Nama Kategori',
                  child: TextField(
                    controller: _nameController,
                    textInputAction: TextInputAction.next,
                    decoration: _inputDecoration(
                      hintText: 'e.g., Subscription Services',
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const _SheetLabel(label: 'Pilih Ikon'),
                const SizedBox(height: 12),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _iconOptions.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    mainAxisExtent: 72,
                    crossAxisSpacing: 15,
                  ),
                  itemBuilder: (BuildContext context, int index) {
                    final _IconOption option = _iconOptions[index];
                    return _IconChoice(
                      option: option,
                      isSelected: index == _selectedIconIndex,
                      onTap: () => setState(() => _selectedIconIndex = index),
                    );
                  },
                ),
                const SizedBox(height: 27),
                _LabeledInput(
                  label: 'Batas Pengeluaran Bulanan',
                  child: TextField(
                    controller: _budgetController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    inputFormatters: <TextInputFormatter>[
                      FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
                    ],
                    decoration: _inputDecoration(
                      hintText: '0',
                      prefixIcon: const Padding(
                        padding: EdgeInsets.only(left: 15, right: 8),
                        child: Text(
                          'Rp',
                          style: TextStyle(
                            color: Color(0xFF5B5552),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 39),
                SizedBox(
                  width: double.infinity,
                  height: 53,
                  child: FilledButton(
                    onPressed: _confirm,
                    style: FilledButton.styleFrom(
                      backgroundColor: _primaryRed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(28),
                      ),
                      elevation: 12,
                      shadowColor: _primaryRed.withValues(alpha: 0.23),
                    ),
                    child: const Text(
                      'Tambah Kategori',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 13),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      foregroundColor: _mutedTextColor,
                      textStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    child: const Text('Batalkan'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hintText,
    Widget? prefixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: const TextStyle(
        color: Color(0xFF8D93A1),
        fontSize: 14,
        fontWeight: FontWeight.w400,
      ),
      prefixIcon: prefixIcon,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      filled: true,
      fillColor: _fieldColor,
      contentPadding: const EdgeInsets.symmetric(horizontal: 13, vertical: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
    );
  }
}

Future<CategoryDraft?> showAddCategoryBottomSheet(BuildContext context) {
  return showModalBottomSheet<CategoryDraft>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.18),
    builder: (BuildContext context) => const AddCategoryBottomSheet(),
  );
}

class _IconOption {
  const _IconOption({required this.label, required this.icon});

  final String label;
  final IconData icon;
}

class _DragHandle extends StatelessWidget {
  const _DragHandle();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFD6A6A0),
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _LabeledInput extends StatelessWidget {
  const _LabeledInput({required this.label, required this.child});

  final String label;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SheetLabel(label: label),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _SheetLabel extends StatelessWidget {
  const _SheetLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: _AddCategoryBottomSheetState._textColor,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _IconChoice extends StatelessWidget {
  const _IconChoice({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  final _IconOption option;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isSelected
                  ? _AddCategoryBottomSheetState._primaryRed
                  : _AddCategoryBottomSheetState._unselectedIconColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              option.icon,
              color: isSelected ? Colors.white : const Color(0xFF55504D),
              size: 21,
            ),
          ),
          const SizedBox(height: 7),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              option.label,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF514946),
                fontSize: 10,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
