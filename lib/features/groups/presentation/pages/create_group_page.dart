import 'package:flutter/material.dart';

import '../widgets/add_category_bottom_sheet.dart';

class CreateGroupPage extends StatefulWidget {
  const CreateGroupPage({super.key});

  @override
  State<CreateGroupPage> createState() => _CreateGroupPageState();
}

class _CreateGroupPageState extends State<CreateGroupPage> {
  static const Color _backgroundColor = Color(0xFFFBF7F4);
  static const Color _primaryRed = Color(0xFFC70F1B);
  static const Color _textColor = Color(0xFF111827);
  static const Color _mutedTextColor = Color(0xFF6F625F);
  static const Color _borderColor = Color(0xFFE7E0DC);
  static const Color _fieldColor = Color(0xFFEDEFFC);

  final TextEditingController _groupNameController = TextEditingController();
  final TextEditingController _searchController = TextEditingController();
  late final List<_CategoryOption> _categories;
  int _selectedCategoryIndex = 1;

  @override
  void initState() {
    super.initState();
    _categories = <_CategoryOption>[
      const _CategoryOption(label: 'Home', icon: Icons.home_outlined),
      const _CategoryOption(label: 'Travel', icon: Icons.flight),
      const _CategoryOption(label: 'Food', icon: Icons.restaurant),
      const _CategoryOption(
        label: 'Custom',
        icon: Icons.add,
        isCustomAction: true,
      ),
    ];
  }

  Future<void> _handleCategoryTap(int index) async {
    final _CategoryOption category = _categories[index];
    if (!category.isCustomAction) {
      setState(() => _selectedCategoryIndex = index);
      return;
    }

    final CategoryDraft? draft = await showAddCategoryBottomSheet(context);
    if (!mounted || draft == null) {
      return;
    }

    final int insertIndex = _categories.length - 1;
    setState(() {
      _categories.insert(
        insertIndex,
        _CategoryOption(label: draft.name, icon: draft.icon),
      );
      _selectedCategoryIndex = insertIndex;
    });
  }

  static const List<MockMember> _members = <MockMember>[
    MockMember(
      name: 'Alex Morgan',
      email: 'alex.m@splitsync.com',
      initials: 'AM',
      avatarColor: Color(0xFF233348),
    ),
    MockMember(
      name: 'Sam Rodriguez',
      email: 'sam.r22@gmail.com',
      initials: 'SR',
      avatarColor: Color(0xFFF1E4D4),
    ),
    MockMember(
      name: 'Jordan Kelly',
      email: 'jkelly.pro@outlook.com',
      initials: 'JK',
      avatarColor: Color(0xFFD8EEE4),
    ),
  ];

  @override
  void dispose() {
    _groupNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.12),
        leading: IconButton(
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back, color: Color(0xFF0F1D2E)),
        ),
        centerTitle: true,
        title: const Text(
          'Detail Grup',
          style: TextStyle(
            color: _textColor,
            fontSize: 16,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: <Widget>[
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 22),
                children: <Widget>[
                  const SizedBox(height: 6),
                  const _GroupPhotoSection(
                    primaryRed: _primaryRed,
                    mutedTextColor: _mutedTextColor,
                  ),
                  const SizedBox(height: 24),
                  _LabeledTextField(
                    label: 'Nama Grup',
                    hintText: 'e.g., Euro Trip 2024',
                    controller: _groupNameController,
                    fieldColor: _fieldColor,
                  ),
                  const SizedBox(height: 26),
                  const _SectionLabel(label: 'Pilih Kategori'),
                  const SizedBox(height: 12),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: <Widget>[
                        for (
                          int index = 0;
                          index < _categories.length;
                          index++
                        ) ...<Widget>[
                          CategoryChip(
                            label: _categories[index].label,
                            icon: _categories[index].icon,
                            isSelected: _selectedCategoryIndex == index,
                            primaryRed: _primaryRed,
                            borderColor: _borderColor,
                            onTap: () => _handleCategoryTap(index),
                          ),
                          if (index != _categories.length - 1)
                            const SizedBox(width: 14),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 30),
                  const _MemberHeader(),
                  const SizedBox(height: 12),
                  _SearchField(
                    controller: _searchController,
                    fieldColor: _fieldColor,
                  ),
                  const SizedBox(height: 18),
                  const Padding(
                    padding: EdgeInsets.only(left: 42),
                    child: Text(
                      'REKOMENDASI',
                      style: TextStyle(
                        color: _mutedTextColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: <BoxShadow>[
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.04),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Column(
                      children: <Widget>[
                        for (int index = 0; index < _members.length; index++)
                          MemberSuggestionTile(
                            member: _members[index],
                            primaryRed: _primaryRed,
                            showDivider: index != _members.length - 1,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const _CreateGroupButton(primaryRed: _primaryRed),
          ],
        ),
      ),
    );
  }
}

class _CategoryOption {
  const _CategoryOption({
    required this.label,
    required this.icon,
    this.isCustomAction = false,
  });

  final String label;
  final IconData icon;
  final bool isCustomAction;
}

class MockMember {
  const MockMember({
    required this.name,
    required this.email,
    required this.initials,
    required this.avatarColor,
  });

  final String name;
  final String email;
  final String initials;
  final Color avatarColor;
}

class _GroupPhotoSection extends StatelessWidget {
  const _GroupPhotoSection({
    required this.primaryRed,
    required this.mutedTextColor,
  });

  final Color primaryRed;
  final Color mutedTextColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        SizedBox(
          width: 82,
          height: 72,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                width: 66,
                height: 66,
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F3F1),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFE6C7C1),
                    width: 1.3,
                  ),
                ),
                child: const Icon(
                  Icons.groups_outlined,
                  color: Color(0xFFBE9F99),
                  size: 30,
                ),
              ),
              Positioned(
                right: 6,
                bottom: 8,
                child: Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    color: primaryRed,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                  child: const Icon(
                    Icons.camera_alt,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        Text(
          'Unggah grup foto',
          style: TextStyle(
            color: mutedTextColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF4B3D3A),
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _LabeledTextField extends StatelessWidget {
  const _LabeledTextField({
    required this.label,
    required this.hintText,
    required this.controller,
    required this.fieldColor,
  });

  final String label;
  final String hintText;
  final TextEditingController controller;
  final Color fieldColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        _SectionLabel(label: label),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hintText,
            hintStyle: const TextStyle(
              color: Color(0xFF9B7775),
              fontSize: 13,
              fontWeight: FontWeight.w400,
            ),
            filled: true,
            fillColor: fieldColor,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide.none,
            ),
          ),
        ),
      ],
    );
  }
}

class CategoryChip extends StatelessWidget {
  const CategoryChip({
    super.key,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.primaryRed,
    required this.borderColor,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool isSelected;
  final Color primaryRed;
  final Color borderColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color foregroundColor = isSelected
        ? Colors.white
        : const Color(0xFF172033);
    final Color iconColor = isSelected ? Colors.white : primaryRed;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 68,
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? primaryRed : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? primaryRed : borderColor),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0x33FFFFFF)
                    : const Color(0xFFECEFFC),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 19),
            ),
            const SizedBox(height: 5),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                maxLines: 1,
                style: TextStyle(
                  color: foregroundColor,
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

class _MemberHeader extends StatelessWidget {
  const _MemberHeader();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'Tambah Anggota',
            style: TextStyle(
              color: Color(0xFF111827),
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Text(
          '1 of 50',
          style: TextStyle(
            color: Color(0xFFC70F1B),
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.fieldColor});

  final TextEditingController controller;
  final Color fieldColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        hintText: 'Cari teman dari nama atau email',
        hintStyle: const TextStyle(
          color: Color(0xFF8C8897),
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: const Icon(
          Icons.search,
          color: Color(0xFF8F5D5A),
          size: 20,
        ),
        filled: true,
        fillColor: fieldColor,
        contentPadding: const EdgeInsets.symmetric(vertical: 12),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}

class MemberSuggestionTile extends StatelessWidget {
  const MemberSuggestionTile({
    super.key,
    required this.member,
    required this.primaryRed,
    required this.showDivider,
  });

  final MockMember member;
  final Color primaryRed;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        border: showDivider
            ? const Border(bottom: BorderSide(color: Color(0xFFF2EEEB)))
            : null,
      ),
      child: Row(
        children: <Widget>[
          _MockAvatar(member: member),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  member.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF111827),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF9A8581),
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            height: 30,
            child: FilledButton(
              onPressed: () {},
              style: FilledButton.styleFrom(
                backgroundColor: primaryRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 17),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
              ),
              child: const Text(
                'Tambah',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MockAvatar extends StatelessWidget {
  const _MockAvatar({required this.member});

  final MockMember member;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 34,
      height: 34,
      decoration: BoxDecoration(
        color: member.avatarColor,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        member.initials,
        style: TextStyle(
          color:
              ThemeData.estimateBrightnessForColor(member.avatarColor) ==
                  Brightness.dark
              ? Colors.white
              : const Color(0xFF583D38),
          fontSize: 11,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _CreateGroupButton extends StatelessWidget {
  const _CreateGroupButton({required this.primaryRed});

  final Color primaryRed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBF7F4),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 22),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: FilledButton.icon(
          onPressed: () {},
          style: FilledButton.styleFrom(
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          icon: const Icon(Icons.group_add_outlined, size: 18),
          label: const Text(
            'Buat Grup',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
