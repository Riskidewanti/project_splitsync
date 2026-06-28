import 'package:flutter/material.dart';

import '../widgets/responsive.dart';
import 'confirm_pin_page.dart';

class CreatePinPage extends StatefulWidget {
  const CreatePinPage({super.key});

  @override
  State<CreatePinPage> createState() => _CreatePinPageState();
}

class _CreatePinPageState extends State<CreatePinPage> {
  var _pin = '';

  void _tap(String value) {
    if (_pin.length >= 6) return;
    setState(() => _pin += value);
    if (_pin.length == 6) {
      Future<void>.delayed(const Duration(milliseconds: 180), () {
        if (!mounted) return;
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => ConfirmPinPage(pin: _pin)));
      });
    }
  }

  void _delete() {
    if (_pin.isEmpty) return;
    setState(() => _pin = _pin.substring(0, _pin.length - 1));
  }

  @override
  Widget build(BuildContext context) {
    return PinEntryScaffold(
      title: 'Buat PIN Baru',
      icon: Icons.lock_person_outlined,
      heading: 'Buat PIN Baru',
      subtitle: 'Masukkan 6 digit angka untuk PIN\nbaru Anda.',
      pinLength: _pin.length,
      filledDots: false,
      boxedKeyboard: true,
      onDigit: _tap,
      onDelete: _delete,
    );
  }
}

class PinEntryScaffold extends StatelessWidget {
  const PinEntryScaffold({
    super.key,
    required this.title,
    required this.icon,
    required this.heading,
    required this.subtitle,
    required this.pinLength,
    required this.onDigit,
    required this.onDelete,
    this.filledDots = true,
    this.boxedKeyboard = false,
  });

  final String title;
  final IconData icon;
  final String heading;
  final String subtitle;
  final int pinLength;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;
  final bool filledDots;
  final bool boxedKeyboard;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Scaffold(
      backgroundColor: boxedKeyboard ? const Color(0xFFFFFCF7) : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        toolbarHeight: responsive.space(88),
        leadingWidth: 62,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(
            Icons.arrow_back,
            color: Color(0xFF8C0010),
            size: 30,
          ),
        ),
        title: Text(
          title,
          style: const TextStyle(
            color: Color(0xFF7B0010),
            fontSize: 24,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (boxedKeyboard)
            Padding(
              padding: const EdgeInsets.only(right: 22),
              child: CircleAvatar(
                radius: 27,
                backgroundColor: const Color(0xFFE7E5E1),
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(
                    Icons.help_outline,
                    color: Color(0xFF555555),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: ResponsivePage(
          maxWidth: 430,
          padding: EdgeInsets.only(bottom: responsive.space(24)),
          child: Column(
            children: [
              SizedBox(
                height: boxedKeyboard
                    ? responsive.space(92)
                    : responsive.space(48),
              ),
              CircleAvatar(
                radius: responsive.space(boxedKeyboard ? 42 : 48),
                backgroundColor: boxedKeyboard
                    ? const Color(0xFFF5E5E2)
                    : const Color(0xFFFFD6D6),
                child: Icon(
                  icon,
                  color: const Color(0xFF8C0010),
                  size: responsive.space(37),
                ),
              ),
              SizedBox(height: responsive.space(36)),
              Text(
                heading,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF111B2C),
                  fontSize: responsive.font(31),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: responsive.space(18)),
              Text(
                subtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5D5757),
                  fontSize: responsive.font(20),
                  height: 1.35,
                ),
              ),
              SizedBox(height: responsive.space(44)),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  6,
                  (index) => Container(
                    width: responsive.space(filledDots ? 20 : 18),
                    height: responsive.space(filledDots ? 20 : 18),
                    margin: EdgeInsets.symmetric(
                      horizontal: responsive.space(10),
                    ),
                    decoration: BoxDecoration(
                      color: index < pinLength
                          ? const Color(0xFF8C0010)
                          : (filledDots
                                ? const Color(0xFFE8E5E0)
                                : Colors.white),
                      border: filledDots
                          ? null
                          : Border.all(
                              color: const Color(0xFFDDB7B9),
                              width: 2,
                            ),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.space(boxedKeyboard ? 110 : 150)),
              _PinKeyboard(
                boxed: boxedKeyboard,
                onDigit: onDigit,
                onDelete: onDelete,
              ),
              SizedBox(
                height: boxedKeyboard
                    ? responsive.space(30)
                    : responsive.space(42),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PinKeyboard extends StatelessWidget {
  const _PinKeyboard({
    required this.boxed,
    required this.onDigit,
    required this.onDelete,
  });

  final bool boxed;
  final ValueChanged<String> onDigit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', 'delete'],
    ];

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: responsive.space(boxed ? 54 : 36),
      ),
      decoration: boxed
          ? null
          : const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(
                  color: Color(0x08000000),
                  blurRadius: 28,
                  offset: Offset(0, -10),
                ),
              ],
            ),
      child: Column(
        children: rows.map((row) {
          return Padding(
            padding: EdgeInsets.only(bottom: responsive.space(boxed ? 12 : 28)),
            child: Row(
              children: row.map((item) {
                if (item.isEmpty) return const Expanded(child: SizedBox());
                final isDelete = item == 'delete';
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: responsive.space(boxed ? 4 : 12),
                    ),
                    child: SizedBox(
                      height: responsive.space(boxed ? 72 : 60),
                      child: TextButton(
                        onPressed: isDelete ? onDelete : () => onDigit(item),
                        style: TextButton.styleFrom(
                          backgroundColor: boxed
                              ? Colors.white
                              : Colors.transparent,
                          foregroundColor: isDelete
                              ? const Color(0xFF8C0010)
                              : const Color(0xFF111B2C),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          elevation: boxed ? 4 : 0,
                          shadowColor: const Color(0x11000000),
                          textStyle: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        child: isDelete
                            ? const Icon(Icons.backspace_outlined, size: 28)
                            : Text(item),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          );
        }).toList(),
      ),
    );
  }
}
