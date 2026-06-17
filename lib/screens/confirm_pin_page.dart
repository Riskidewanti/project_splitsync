import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'create_pin_page.dart';
import 'pin_created_page.dart';

class ConfirmPinPage extends StatefulWidget {
  const ConfirmPinPage({super.key, required this.pin});

  final String pin;

  @override
  State<ConfirmPinPage> createState() => _ConfirmPinPageState();
}

class _ConfirmPinPageState extends State<ConfirmPinPage> {
  var _confirmation = '';

  Future<void> _tap(String value) async {
    if (_confirmation.length >= 6) return;
    setState(() => _confirmation += value);
    if (_confirmation.length == 6) {
      await Future<void>.delayed(const Duration(milliseconds: 160));
      if (!mounted) return;
      if (_confirmation == widget.pin) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('splitsync_pin', widget.pin);
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const PinCreatedPage()),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('PIN tidak cocok. Coba ulangi lagi.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: const Color(0xFF8C0010),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        );
        setState(() => _confirmation = '');
      }
    }
  }

  void _delete() {
    if (_confirmation.isEmpty) return;
    setState(() {
      _confirmation = _confirmation.substring(0, _confirmation.length - 1);
    });
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryScaffold(
      title: 'Konfirmasi PIN',
      icon: Icons.lock,
      heading: 'Ulangi PIN',
      subtitle: 'Masukkan kembali 6 digit PIN yang\nbaru saja Anda buat.',
      pinLength: _confirmation.length,
      onDigit: _tap,
      onDelete: _delete,
    );
  }
}
