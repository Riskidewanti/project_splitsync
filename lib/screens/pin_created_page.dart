import 'package:flutter/material.dart';

import '../widgets/responsive.dart';
import 'home_page.dart';

class PinCreatedPage extends StatelessWidget {
  const PinCreatedPage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFFFFFCF7),
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 430,
          scrollable: true,
          padding: responsive.horizontal(42),
          child: Column(
            children: [
              SizedBox(height: responsive.space(74)),
              SizedBox(
                width: responsive.space(230),
                height: responsive.space(230),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 210,
                      height: 210,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFFFFE3E4)),
                      ),
                    ),
                    Container(
                      width: 138,
                      height: 138,
                      decoration: const BoxDecoration(
                        color: Color(0xFFA4161D),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Color(0x22000000),
                            blurRadius: 30,
                            offset: Offset(0, 20),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.lock_open_rounded,
                        color: Color(0xFFFF8D8F),
                        size: 70,
                      ),
                    ),
                    const Positioned(
                      left: 22,
                      bottom: 44,
                      child: CircleAvatar(
                        radius: 13,
                        backgroundColor: Color(0xFFE8BDC0),
                        child: Icon(Icons.check, color: Colors.white, size: 16),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: responsive.space(38)),
              Text(
                'PIN Berhasil\nDibuat',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF111B2C),
                  fontSize: responsive.font(43),
                  height: 1.18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: responsive.space(24)),
              Text(
                'Akun SplitSync Anda kini lebih\naman. Gunakan PIN ini untuk\ntransaksi dan pengaturan\nsensitif.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF6A625F),
                  fontSize: responsive.font(20),
                  height: 1.48,
                ),
              ),
              SizedBox(height: responsive.space(64)),
              SizedBox(
                width: double.infinity,
                height: responsive.space(62),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(builder: (_) => const HomePage()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFA4161D),
                    foregroundColor: const Color(0xFFEBC8C8),
                    elevation: 20,
                    shadowColor: const Color(0x33A4161D),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(28),
                    ),
                  ),
                  child: Text(
                    'KEMBALI KE BERANDA',
                    style: TextStyle(
                      fontSize: responsive.font(17),
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1,
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.space(34)),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(radius: 5, backgroundColor: Color(0xFFA4161D)),
                  SizedBox(width: 10),
                  Text(
                    'Enkripsi End-to-End Aktif',
                    style: TextStyle(color: Color(0xFF6A625F), fontSize: 15),
                  ),
                ],
              ),
              SizedBox(height: responsive.space(48)),
            ],
          ),
        ),
      ),
    );
  }
}
