import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../authentication/auth_service.dart';
import '../../widgets/responsive.dart';
import '../authentication/create_pin_page.dart';

enum _EditableField { name, email, phone }

class _ProfileEditValues {
  const _ProfileEditValues({
    required this.userName,
    required this.email,
    required this.phone,
  });

  final String userName;
  final String email;
  final String phone;
}

class AccountSettingsPage extends StatefulWidget {
  const AccountSettingsPage({super.key});

  @override
  State<AccountSettingsPage> createState() => _AccountSettingsPageState();
}

class _AccountSettingsPageState extends State<AccountSettingsPage> {
  late Future<ProfileDetails> _profileFuture;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = AuthService.fetchCurrentProfile();
  }

  Future<void> _editProfile(
    ProfileDetails profile,
    _EditableField field,
  ) async {
    final updated = await showDialog<_ProfileEditValues>(
      context: context,
      builder: (context) => _EditProfileDialog(profile: profile, field: field),
    );
    if (updated == null) return;

    try {
      final saved = await AuthService.updateCurrentProfile(
        userName: updated.userName,
        email: updated.email,
        phone: updated.phone,
      );
      if (!mounted) return;
      setState(() {
        _profileFuture = Future.value(saved);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil berhasil disimpan.'),
          backgroundColor: Color(0xFFC8152B),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFF9A0010),
        ),
      );
    }
  }

  Future<void> _changeProfilePhoto() async {
    if (_uploadingPhoto) return;
    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        imageQuality: 85,
      );
      if (picked == null) return;

      setState(() {
        _uploadingPhoto = true;
      });
      final saved = await AuthService.updateCurrentProfilePhoto(
        bytes: await picked.readAsBytes(),
        fileName: picked.name,
      );
      if (!mounted) return;
      setState(() {
        _profileFuture = Future.value(saved);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Foto profil berhasil disimpan.'),
          backgroundColor: Color(0xFFC8152B),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: const Color(0xFF9A0010),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _uploadingPhoto = false;
        });
      }
    }
  }

  void _changePin() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const CreatePinPage()));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        bottom: false,
        child: FutureBuilder<ProfileDetails>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFC8152B)),
              );
            }

            if (snapshot.hasError) {
              return _AccountErrorState(
                message: snapshot.error.toString(),
                onBack: () => Navigator.of(context).pop(),
              );
            }

            return _AccountSettingsBody(
              profile: snapshot.requireData,
              onEdit: _editProfile,
              onChangePhoto: _changeProfilePhoto,
              onChangePin: _changePin,
              uploadingPhoto: _uploadingPhoto,
            );
          },
        ),
      ),
      bottomNavigationBar: const _AccountBottomNav(),
    );
  }
}

class _AccountSettingsBody extends StatelessWidget {
  const _AccountSettingsBody({
    required this.profile,
    required this.onEdit,
    required this.onChangePhoto,
    required this.onChangePin,
    required this.uploadingPhoto,
  });

  final ProfileDetails profile;
  final Future<void> Function(ProfileDetails profile, _EditableField field)
  onEdit;
  final VoidCallback onChangePhoto;
  final VoidCallback onChangePin;
  final bool uploadingPhoto;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Column(
      children: [
        _AccountAppBar(responsive: responsive),
        Expanded(
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
              responsive.clamp(42, 26, 44),
              responsive.space(34),
              responsive.clamp(42, 26, 44),
              responsive.space(34),
            ),
            child: ResponsivePage(
              maxWidth: 430,
              child: Column(
                children: [
                  _AccountHeader(
                    profile: profile,
                    onChangePhoto: onChangePhoto,
                    uploadingPhoto: uploadingPhoto,
                  ),
                  SizedBox(height: responsive.space(50)),
                  _InfoCard(
                    profile: profile,
                    onEdit: onEdit,
                    onChangePin: onChangePin,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _AccountAppBar extends StatelessWidget {
  const _AccountAppBar({required this.responsive});

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
          SizedBox(width: responsive.space(56)),
          Expanded(
            child: Text(
              'Pengaturan Akun',
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

class _AccountHeader extends StatelessWidget {
  const _AccountHeader({
    required this.profile,
    required this.onChangePhoto,
    required this.uploadingPhoto,
  });

  final ProfileDetails profile;
  final VoidCallback onChangePhoto;
  final bool uploadingPhoto;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final name = profile.userName.isEmpty
        ? 'Pengguna SplitSync'
        : profile.userName;
    return Column(
      children: [
        _AccountAvatar(
          profile: profile,
          onTap: onChangePhoto,
          uploading: uploadingPhoto,
        ),
        SizedBox(height: responsive.space(26)),
        Text(
          name,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF111111),
            fontSize: responsive.font(27),
            fontWeight: FontWeight.w900,
          ),
        ),
        SizedBox(height: responsive.space(4)),
        Text(
          profile.email,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: const Color(0xFF5F5A5A),
            fontSize: responsive.font(18),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _AccountAvatar extends StatelessWidget {
  const _AccountAvatar({
    required this.profile,
    required this.onTap,
    required this.uploading,
  });

  final ProfileDetails profile;
  final VoidCallback onTap;
  final bool uploading;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final initials = profile.userName.isNotEmpty
        ? profile.userName.trim().substring(0, 1).toUpperCase()
        : 'S';

    final size = responsive.clamp(104, 90, 112);
    return InkWell(
      onTap: uploading ? null : onTap,
      customBorder: const CircleBorder(),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF151F2A),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 16,
                  offset: Offset(0, 8),
                ),
              ],
              image: profile.avatarUrl.isEmpty
                  ? null
                  : DecorationImage(
                      image: NetworkImage(profile.avatarUrl),
                      fit: BoxFit.cover,
                    ),
            ),
            child: uploading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 3,
                    ),
                  )
                : profile.avatarUrl.isEmpty
                ? Center(
                    child: Text(
                      initials,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: responsive.font(36),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  )
                : null,
          ),
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              width: responsive.clamp(34, 30, 36),
              height: responsive.clamp(34, 30, 36),
              decoration: BoxDecoration(
                color: const Color(0xFFC8152B),
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 3),
              ),
              child: Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: responsive.clamp(18, 16, 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.profile,
    required this.onEdit,
    required this.onChangePin,
  });

  final ProfileDetails profile;
  final Future<void> Function(ProfileDetails profile, _EditableField field)
  onEdit;
  final VoidCallback onChangePin;

  @override
  Widget build(BuildContext context) {
    final name = profile.userName.isEmpty
        ? 'Pengguna SplitSync'
        : profile.userName;
    final phone = profile.phone.isEmpty ? 'Belum ditambahkan' : profile.phone;
    return _SectionCard(
      title: 'INFO PRIBADI',
      children: [
        _EditableInfoRow(
          label: 'Nama',
          value: name,
          onTap: () {
            onEdit(profile, _EditableField.name);
          },
        ),
        const _ThinDivider(),
        _EditableInfoRow(
          label: 'Email',
          value: profile.email,
          onTap: () {
            onEdit(profile, _EditableField.email);
          },
        ),
        const _ThinDivider(),
        _EditableInfoRow(
          label: 'Nomor Hp',
          value: phone,
          onTap: () {
            onEdit(profile, _EditableField.phone);
          },
        ),
        const _ThinDivider(),
        _ActionInfoRow(
          label: 'PIN Keamanan',
          value: profile.pinCreated ? 'Ganti PIN' : 'Buat PIN',
          icon: Icons.lock_reset_rounded,
          onTap: onChangePin,
        ),
      ],
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({required this.title, required this.children});

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        responsive.clamp(28, 22, 30),
        responsive.clamp(28, 24, 30),
        responsive.clamp(28, 22, 30),
        responsive.clamp(24, 20, 26),
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFECECEC)),
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
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFFC8152B),
              fontSize: responsive.font(16),
              fontWeight: FontWeight.w800,
              letterSpacing: 0,
            ),
          ),
          SizedBox(height: responsive.space(34)),
          ...children,
        ],
      ),
    );
  }
}

class _EditableInfoRow extends StatelessWidget {
  const _EditableInfoRow({
    required this.label,
    required this.value,
    required this.onTap,
  });

  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: responsive.space(6)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFF5D5353),
                      fontSize: responsive.font(13),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: responsive.space(8)),
                  Text(
                    value,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF181818),
                      fontSize: responsive.font(18),
                      fontWeight: FontWeight.w500,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: responsive.space(16)),
            Icon(
              Icons.edit_rounded,
              color: const Color(0xFF5F5F5F),
              size: responsive.clamp(23, 20, 25),
            ),
          ],
        ),
      ),
    );
  }
}

class _ActionInfoRow extends StatelessWidget {
  const _ActionInfoRow({
    required this.label,
    required this.value,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: responsive.space(6)),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: const Color(0xFF5D5353),
                      fontSize: responsive.font(13),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: responsive.space(8)),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFF181818),
                      fontSize: responsive.font(18),
                      fontWeight: FontWeight.w600,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: responsive.space(16)),
            Container(
              width: responsive.clamp(36, 32, 38),
              height: responsive.clamp(36, 32, 38),
              decoration: const BoxDecoration(
                color: Color(0xFFFFD8DB),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: const Color(0xFFC8152B),
                size: responsive.clamp(21, 19, 23),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditProfileDialog extends StatefulWidget {
  const _EditProfileDialog({required this.profile, required this.field});

  final ProfileDetails profile;
  final _EditableField field;

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.profile.userName);
    _emailController = TextEditingController(text: widget.profile.email);
    _phoneController = TextEditingController(text: widget.profile.phone);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  String get _title {
    switch (widget.field) {
      case _EditableField.name:
        return 'Edit Nama';
      case _EditableField.email:
        return 'Edit Email';
      case _EditableField.phone:
        return 'Edit Nomor Hp';
    }
  }

  TextEditingController get _activeController {
    switch (widget.field) {
      case _EditableField.name:
        return _nameController;
      case _EditableField.email:
        return _emailController;
      case _EditableField.phone:
        return _phoneController;
    }
  }

  TextInputType get _keyboardType {
    switch (widget.field) {
      case _EditableField.name:
        return TextInputType.name;
      case _EditableField.email:
        return TextInputType.emailAddress;
      case _EditableField.phone:
        return TextInputType.phone;
    }
  }

  String get _label {
    switch (widget.field) {
      case _EditableField.name:
        return 'Nama';
      case _EditableField.email:
        return 'Email';
      case _EditableField.phone:
        return 'Nomor Hp';
    }
  }

  void _save() {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nama dan email wajib diisi.'),
          backgroundColor: Color(0xFF9A0010),
        ),
      );
      return;
    }

    Navigator.of(context).pop(
      _ProfileEditValues(
        userName: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: Text(
        _title,
        style: const TextStyle(
          color: Color(0xFF111B2C),
          fontWeight: FontWeight.w900,
        ),
      ),
      content: TextField(
        controller: _activeController,
        autofocus: true,
        keyboardType: _keyboardType,
        textInputAction: TextInputAction.done,
        onSubmitted: (_) => _save(),
        decoration: InputDecoration(
          labelText: _label,
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFC8152B)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Batal'),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFFC8152B),
          ),
          child: const Text('Simpan'),
        ),
      ],
    );
  }
}

class _ThinDivider extends StatelessWidget {
  const _ThinDivider();

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: responsive.space(16)),
      child: const Divider(height: 1, color: Color(0xFFEDEDED)),
    );
  }
}

class _AccountBottomNav extends StatelessWidget {
  const _AccountBottomNav();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        height: 72,
        padding: const EdgeInsets.fromLTRB(18, 8, 18, 10),
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
            _AccountBottomItem(
              icon: Icons.home_rounded,
              label: 'Beranda',
              onTap: () => Navigator.of(context).pushReplacementNamed('/beranda'),
            ),
            _AccountBottomItem(
              icon: Icons.groups_2_outlined,
              label: 'Grup',
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed('/grup'),
            ),
            Container(
              width: 52,
              height: 52,
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
              child: const Icon(Icons.add, color: Colors.white, size: 34),
            ),
            _AccountBottomItem(
              icon: Icons.analytics_outlined,
              label: 'Laporan',
              onTap: () =>
                  Navigator.of(context).pushReplacementNamed('/laporan'),
            ),
            const _AccountBottomItem(
              icon: Icons.person_outline_rounded,
              label: 'Profil',
              selected: true,
            ),
          ],
        ),
      ),
    );
  }
}

class _AccountBottomItem extends StatelessWidget {
  const _AccountBottomItem({
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
    final color = selected ? const Color(0xFFC8152B) : const Color(0xFF5A5A5A);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 54,
        height: 50,
        decoration: selected
            ? BoxDecoration(
                color: const Color(0xFFFFDADB),
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 2),
            FittedBox(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
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

class _AccountErrorState extends StatelessWidget {
  const _AccountErrorState({required this.message, required this.onBack});

  final String message;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Padding(
      padding: responsive.horizontal(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: Color(0xFFC8152B),
            size: 48,
          ),
          SizedBox(height: responsive.space(16)),
          Text(
            'Pengaturan akun belum bisa dimuat',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF111B2C),
              fontSize: responsive.font(22),
              fontWeight: FontWeight.w900,
            ),
          ),
          SizedBox(height: responsive.space(8)),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: const Color(0xFF6A625F),
              fontSize: responsive.font(14),
            ),
          ),
          SizedBox(height: responsive.space(20)),
          FilledButton(
            onPressed: onBack,
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFC8152B),
            ),
            child: const Text('Kembali'),
          ),
        ],
      ),
    );
  }
}
