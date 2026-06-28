import 'package:flutter/material.dart';

import '../../authentication/auth_service.dart';
import '../../widgets/responsive.dart';
import 'add_pin_option_page.dart';
import '../home/home_page.dart';

class AuthPage extends StatefulWidget {
  const AuthPage({super.key});

  @override
  State<AuthPage> createState() => _AuthPageState();
}

class _AuthPageState extends State<AuthPage> {
  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _registerEmail = TextEditingController();
  final _registerUsername = TextEditingController();
  final _registerPassword = TextEditingController();
  var _isLogin = true;
  var _loading = false;

  @override
  void dispose() {
    _loginEmail.dispose();
    _loginPassword.dispose();
    _registerEmail.dispose();
    _registerUsername.dispose();
    _registerPassword.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final profile = _isLogin
          ? await AuthService.login(
              email: _loginEmail.text,
              password: _loginPassword.text,
            )
          : await AuthService.register(
              email: _registerEmail.text,
              username: _registerUsername.text,
              password: _registerPassword.text,
            );

      if (_isLogin) {
        _showNotice('Login berhasil. Selamat datang kembali.');
      } else {
        _showNotice('Akun berhasil dibuat.');
      }
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              profile.pinCreated ? const HomePage() : const AddPinOptionPage(),
        ),
      );
    } catch (error) {
      _showNotice(
        _isLogin ? 'Login gagal. ${_message(error)}' : _message(error),
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(Object error) {
    final text = error.toString().replaceFirst('AuthException(message: ', '');
    return text.replaceAll(RegExp(r'[,)]$'), '').trim();
  }

  void _showNotice(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: isError
            ? const Color(0xFF8E0010)
            : const Color(0xFFC8152B),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 430,
          scrollable: true,
          alignment: Alignment.center,
          padding: responsive
              .horizontal(32)
              .copyWith(
                top: responsive.space(24),
                bottom: responsive.space(24),
              ),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              responsive.clamp(30, 20, 30),
              responsive.clamp(34, 24, 34),
              responsive.clamp(30, 20, 30),
              responsive.clamp(34, 24, 34),
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE0E0E0)),
              boxShadow: const [
                BoxShadow(
                  color: Color(0x12000000),
                  blurRadius: 12,
                  offset: Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: responsive.clamp(48, 42, 52),
                  height: responsive.clamp(36, 32, 40),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F5FF),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.view_agenda_rounded,
                    color: const Color(0xFFC8152B),
                    size: responsive.clamp(30, 25, 32),
                  ),
                ),
                SizedBox(height: responsive.space(20)),
                Text(
                  'SplitSync',
                  style: TextStyle(
                    color: const Color(0xFF001A35),
                    fontSize: responsive.font(40),
                    fontWeight: FontWeight.w900,
                  ),
                ),
                SizedBox(height: responsive.space(12)),
                Text(
                  _isLogin
                      ? 'Kelola pengeluaran dengan mudah.'
                      : 'Manage expenses effortlessly.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: const Color(0xFF696969),
                    fontSize: responsive.font(18),
                  ),
                ),
                SizedBox(
                  height: responsive.space(
                    responsive.isCompactHeight ? 28 : 42,
                  ),
                ),
                Row(
                  children: [
                    _TabButton(
                      label: 'Log In',
                      selected: _isLogin,
                      onTap: () => setState(() => _isLogin = true),
                    ),
                    _TabButton(
                      label: 'Buat Akun',
                      selected: !_isLogin,
                      onTap: () => setState(() => _isLogin = false),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 220),
                  child: _isLogin ? _loginForm() : _registerForm(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    final responsive = Responsive.of(context);
    return Column(
      key: const ValueKey('login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: responsive.space(28)),
        const _FieldLabel('Email'),
        _InputField(
          controller: _loginEmail,
          hint: 'name@company.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: responsive.space(20)),
        Row(
          children: [
            const _FieldLabel('Password'),
            const Spacer(),
            Flexible(
              child: Text(
                'Lupa Password?',
                textAlign: TextAlign.right,
                style: TextStyle(
                  color: const Color(0xFFB51B2E),
                  fontWeight: FontWeight.w800,
                  fontSize: responsive.font(14),
                ),
              ),
            ),
          ],
        ),
        _InputField(
          controller: _loginPassword,
          hint: '********',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
        SizedBox(
          height: responsive.space(responsive.isCompactHeight ? 40 : 74),
        ),
        _SubmitButton(
          label: 'Log in',
          icon: Icons.arrow_forward_rounded,
          loading: _loading,
          onTap: _submit,
        ),
      ],
    );
  }

  Widget _registerForm() {
    final responsive = Responsive.of(context);
    return Column(
      key: const ValueKey('register'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: responsive.space(26)),
        const _FieldLabel('Email'),
        _InputField(
          controller: _registerEmail,
          hint: 'name@company.com',
          icon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        SizedBox(height: responsive.space(18)),
        const _FieldLabel('Nama Pengguna'),
        _InputField(controller: _registerUsername, hint: 'Username'),
        SizedBox(height: responsive.space(18)),
        const _FieldLabel('Password'),
        _InputField(
          controller: _registerPassword,
          hint: '********',
          icon: Icons.lock_outline_rounded,
          obscureText: true,
        ),
        SizedBox(
          height: responsive.space(responsive.isCompactHeight ? 34 : 52),
        ),
        _SubmitButton(label: 'Buat Akun', loading: _loading, onTap: _submit),
      ],
    );
  }
}

class _TabButton extends StatelessWidget {
  const _TabButton({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            FittedBox(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? const Color(0xFFB51B2E) : Colors.black54,
                  fontSize: responsive.font(20),
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            SizedBox(height: responsive.space(16)),
            Container(
              height: selected ? 3 : 1,
              color: selected ? const Color(0xFFB51B2E) : Colors.black12,
            ),
          ],
        ),
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Padding(
      padding: EdgeInsets.only(bottom: responsive.space(10)),
      child: Text(
        text,
        style: TextStyle(
          color: const Color(0xFF001A35),
          fontSize: responsive.font(14),
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  const _InputField({
    required this.controller,
    required this.hint,
    this.icon,
    this.obscureText = false,
    this.keyboardType,
  });

  final TextEditingController controller;
  final String hint;
  final IconData? icon;
  final bool obscureText;
  final TextInputType? keyboardType;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return SizedBox(
      height: responsive.clamp(58, 52, 60),
      child: TextField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: TextStyle(fontSize: responsive.font(16)),
        decoration: InputDecoration(
          prefixIcon: icon == null
              ? null
              : Icon(icon, color: const Color(0xFF666666)),
          hintText: hint,
          hintStyle: TextStyle(
            color: const Color(0xFFC9C9C9),
            fontSize: responsive.font(18),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: responsive.space(14),
            vertical: responsive.space(14),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: Color(0xFFC8152B)),
          ),
        ),
      ),
    );
  }
}

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({
    required this.label,
    required this.loading,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool loading;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return SizedBox(
      width: double.infinity,
      height: responsive.clamp(58, 52, 60),
      child: ElevatedButton(
        onPressed: loading ? null : onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFC8152B),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
        ),
        child: loading
            ? SizedBox(
                width: responsive.clamp(22, 20, 24),
                height: responsive.clamp(22, 20, 24),
                child: const CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: FittedBox(
                      child: Text(
                        label,
                        style: TextStyle(
                          fontSize: responsive.font(20),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  if (icon != null) ...[
                    SizedBox(width: responsive.space(16)),
                    Icon(icon, size: responsive.clamp(26, 22, 28)),
                  ],
                ],
              ),
      ),
    );
  }
}
