import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../data/datasources/group_remote_data_source.dart';
import '../../data/models/group_user_model.dart';
import '../../data/repositories/group_repository_impl.dart';
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
  final ImagePicker _imagePicker = ImagePicker();
  final GroupRepositoryImpl _groupRepository = GroupRepositoryImpl(
    remoteDataSource: GroupRemoteDataSourceImpl(),
  );
  late final List<_CategoryOption> _categories;
  final List<GroupUserModel> _selectedMembers = <GroupUserModel>[];
  List<GroupUserModel> _memberSuggestions = const <GroupUserModel>[];
  Uint8List? _photoBytes;
  String? _photoName;
  String? _photoContentType;
  int _selectedCategoryIndex = 1;
  bool _isSubmitting = false;
  bool _isPickingPhoto = false;
  bool _isSearchingMembers = false;
  int _memberSearchVersion = 0;

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

  Future<void> _pickGroupPhoto() async {
    if (_isPickingPhoto || _isSubmitting) {
      return;
    }

    setState(() => _isPickingPhoto = true);

    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        imageQuality: 82,
      );

      if (image == null) {
        return;
      }

      final Uint8List bytes = await image.readAsBytes();
      if (!mounted) {
        return;
      }

      setState(() {
        _photoBytes = bytes;
        _photoName = image.name;
        _photoContentType = image.mimeType ?? _contentTypeFor(image.name);
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Gagal memilih foto: $error')));
    } finally {
      if (mounted) {
        setState(() => _isPickingPhoto = false);
      }
    }
  }

  Future<void> _searchMembers(String query) async {
    final int version = ++_memberSearchVersion;
    final String trimmedQuery = query.trim();

    if (trimmedQuery.length < 2) {
      setState(() {
        _memberSuggestions = const <GroupUserModel>[];
        _isSearchingMembers = false;
      });
      return;
    }

    setState(() => _isSearchingMembers = true);
    await Future<void>.delayed(const Duration(milliseconds: 300));

    if (!mounted || version != _memberSearchVersion) {
      return;
    }

    try {
      final List<GroupUserModel> users = await _groupRepository.searchUsers(
        trimmedQuery,
      );

      if (!mounted || version != _memberSearchVersion) {
        return;
      }

      final Set<String> selectedIds = _selectedMembers
          .map((GroupUserModel user) => user.id)
          .toSet();
      setState(() {
        _memberSuggestions = users
            .where((GroupUserModel user) => !selectedIds.contains(user.id))
            .toList();
        _isSearchingMembers = false;
      });
    } catch (error) {
      if (!mounted || version != _memberSearchVersion) {
        return;
      }

      setState(() => _isSearchingMembers = false);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          SnackBar(content: Text('Gagal mencari anggota: $error')),
        );
    }
  }

  void _addSelectedMember(GroupUserModel user) {
    final bool alreadySelected = _selectedMembers.any(
      (GroupUserModel selectedUser) => selectedUser.id == user.id,
    );
    if (alreadySelected) {
      return;
    }

    setState(() {
      _selectedMembers.add(user);
      _memberSuggestions = _memberSuggestions
          .where((GroupUserModel suggestion) => suggestion.id != user.id)
          .toList();
    });
  }

  void _removeSelectedMember(GroupUserModel user) {
    setState(() {
      _selectedMembers.removeWhere(
        (GroupUserModel selectedUser) => selectedUser.id == user.id,
      );
    });
  }

  String _contentTypeFor(String fileName) {
    final String lowerName = fileName.toLowerCase();
    if (lowerName.endsWith('.png')) {
      return 'image/png';
    }
    if (lowerName.endsWith('.webp')) {
      return 'image/webp';
    }
    return 'image/jpeg';
  }

  Future<void> _createGroup() async {
    if (_isSubmitting) {
      return;
    }

    final String groupName = _groupNameController.text.trim();
    if (groupName.isEmpty) {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Nama grup wajib diisi.')));
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      String? photoUrl;
      final Uint8List? photoBytes = _photoBytes;
      if (photoBytes != null) {
        photoUrl = await _groupRepository.uploadGroupPhoto(
          bytes: photoBytes,
          fileName: _photoName ?? 'group_photo.jpg',
          contentType: _photoContentType ?? 'image/jpeg',
        );
      }

      await _groupRepository.createGroup(
        name: groupName,
        photoUrl: photoUrl,
        memberUserIds: _selectedMembers
            .map((GroupUserModel user) => user.id)
            .toList(),
      );

      if (!mounted) {
        return;
      }

      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text('Gagal membuat grup: $error')));
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

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
                  _GroupPhotoSection(
                    primaryRed: _primaryRed,
                    mutedTextColor: _mutedTextColor,
                    imageBytes: _photoBytes,
                    isLoading:
                        _isPickingPhoto ||
                        (_isSubmitting && _photoBytes != null),
                    onTap: _pickGroupPhoto,
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
                  _MemberHeader(memberCount: _selectedMembers.length + 1),
                  const SizedBox(height: 12),
                  _SearchField(
                    controller: _searchController,
                    fieldColor: _fieldColor,
                    onChanged: _searchMembers,
                  ),
                  const SizedBox(height: 18),
                  if (_selectedMembers.isNotEmpty) ...<Widget>[
                    const _SectionLabel(label: 'Anggota Dipilih'),
                    const SizedBox(height: 8),
                    _SelectedMemberList(
                      members: _selectedMembers,
                      onRemove: _removeSelectedMember,
                    ),
                    const SizedBox(height: 18),
                  ],
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
                  _MemberSuggestionList(
                    members: _memberSuggestions,
                    isLoading: _isSearchingMembers,
                    hasQuery: _searchController.text.trim().length >= 2,
                    primaryRed: _primaryRed,
                    onAdd: _addSelectedMember,
                  ),
                ],
              ),
            ),
            _CreateGroupButton(
              primaryRed: _primaryRed,
              isLoading: _isSubmitting,
              onPressed: _createGroup,
            ),
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

class _GroupPhotoSection extends StatelessWidget {
  const _GroupPhotoSection({
    required this.primaryRed,
    required this.mutedTextColor,
    required this.onTap,
    this.imageBytes,
    this.isLoading = false,
  });

  final Color primaryRed;
  final Color mutedTextColor;
  final Uint8List? imageBytes;
  final bool isLoading;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: isLoading ? null : onTap,
      borderRadius: BorderRadius.circular(42),
      child: Column(
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
                    image: imageBytes == null
                        ? null
                        : DecorationImage(
                            image: MemoryImage(imageBytes!),
                            fit: BoxFit.cover,
                          ),
                  ),
                  child: imageBytes == null
                      ? const Icon(
                          Icons.groups_outlined,
                          color: Color(0xFFBE9F99),
                          size: 30,
                        )
                      : null,
                ),
                if (isLoading)
                  const SizedBox(
                    width: 66,
                    height: 66,
                    child: CircularProgressIndicator(strokeWidth: 2),
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
            imageBytes == null ? 'Unggah grup foto' : 'Ganti grup foto',
            style: TextStyle(
              color: mutedTextColor,
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
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
  const _MemberHeader({required this.memberCount});

  final int memberCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        const Expanded(
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
          '$memberCount of 50',
          style: const TextStyle(
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
  const _SearchField({
    required this.controller,
    required this.fieldColor,
    required this.onChanged,
  });

  final TextEditingController controller;
  final Color fieldColor;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
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

class _SelectedMemberList extends StatelessWidget {
  const _SelectedMemberList({required this.members, required this.onRemove});

  final List<GroupUserModel> members;
  final ValueChanged<GroupUserModel> onRemove;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: <Widget>[
        for (final GroupUserModel member in members)
          InputChip(
            avatar: _UserAvatar(user: member, radius: 12),
            label: Text(member.label),
            onDeleted: () => onRemove(member),
            deleteIconColor: const Color(0xFF6F625F),
            backgroundColor: Colors.white,
            side: const BorderSide(color: _CreateGroupPageState._borderColor),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
      ],
    );
  }
}

class _MemberSuggestionList extends StatelessWidget {
  const _MemberSuggestionList({
    required this.members,
    required this.isLoading,
    required this.hasQuery,
    required this.primaryRed,
    required this.onAdd,
  });

  final List<GroupUserModel> members;
  final bool isLoading;
  final bool hasQuery;
  final Color primaryRed;
  final ValueChanged<GroupUserModel> onAdd;

  @override
  Widget build(BuildContext context) {
    Widget child;
    if (isLoading) {
      child = const Padding(
        padding: EdgeInsets.symmetric(vertical: 18),
        child: Center(child: CircularProgressIndicator(strokeWidth: 2)),
      );
    } else if (!hasQuery) {
      child = const _MemberSearchMessage(
        message: 'Ketik minimal 2 karakter untuk mencari teman.',
      );
    } else if (members.isEmpty) {
      child = const _MemberSearchMessage(message: 'Tidak ada pengguna cocok.');
    } else {
      child = Column(
        children: <Widget>[
          for (int index = 0; index < members.length; index++)
            MemberSuggestionTile(
              member: members[index],
              primaryRed: primaryRed,
              showDivider: index != members.length - 1,
              onAdd: onAdd,
            ),
        ],
      );
    }

    return Container(
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
      child: child,
    );
  }
}

class _MemberSearchMessage extends StatelessWidget {
  const _MemberSearchMessage({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
      child: Text(
        message,
        textAlign: TextAlign.center,
        style: const TextStyle(
          color: Color(0xFF9A8581),
          fontSize: 12,
          fontWeight: FontWeight.w600,
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
    required this.onAdd,
  });

  final GroupUserModel member;
  final Color primaryRed;
  final bool showDivider;
  final ValueChanged<GroupUserModel> onAdd;

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
          _UserAvatar(user: member, radius: 17),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  member.label,
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
                  member.email ?? member.id,
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
              onPressed: () => onAdd(member),
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

class _UserAvatar extends StatelessWidget {
  const _UserAvatar({required this.user, required this.radius});

  final GroupUserModel user;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: radius,
      backgroundColor: const Color(0xFFECEFFC),
      backgroundImage: user.avatarUrl == null
          ? null
          : NetworkImage(user.avatarUrl!),
      child: user.avatarUrl == null
          ? Text(
              user.initial,
              style: const TextStyle(
                color: Color(0xFF583D38),
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            )
          : null,
    );
  }
}

class _CreateGroupButton extends StatelessWidget {
  const _CreateGroupButton({
    required this.primaryRed,
    required this.isLoading,
    required this.onPressed,
  });

  final Color primaryRed;
  final bool isLoading;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBF7F4),
      padding: const EdgeInsets.fromLTRB(28, 12, 28, 22),
      child: SizedBox(
        width: double.infinity,
        height: 46,
        child: FilledButton.icon(
          onPressed: isLoading ? null : onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: primaryRed,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(24),
            ),
          ),
          icon: isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.group_add_outlined, size: 18),
          label: Text(
            isLoading ? 'Membuat...' : 'Buat Grup',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
          ),
        ),
      ),
    );
  }
}
