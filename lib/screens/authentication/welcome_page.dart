import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../widgets/responsive.dart';
import 'auth_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    final screen = MediaQuery.sizeOf(context);
    final isShort = screen.height < 760;
    final horizontalPadding = responsive.isNarrow ? 24.0 : 38.0;
    final availableWidth = math.min(screen.width, 430) - horizontalPadding * 2;
    final imageSide = math
        .min(availableWidth, isShort ? screen.height * 0.34 : 360)
        .clamp(230.0, 360.0)
        .toDouble();

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 430,
          scrollable: true,
          padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
          child: Column(
            children: [
              SizedBox(height: responsive.space(isShort ? 34 : 58)),
              Text(
                'SplitSync',
                style: TextStyle(
                  color: const Color(0xFFC8152B),
                  fontSize: responsive.font(28),
                  fontWeight: FontWeight.w900,
                ),
              ),
              SizedBox(height: responsive.space(isShort ? 36 : 56)),
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: SizedBox.square(
                  dimension: imageSide,
                  child: Image.asset(
                    'lib/Assets/welcome.jpg',
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              SizedBox(height: responsive.space(isShort ? 42 : 86)),
              Text(
                'Bagikan tagihan,\nbukan stres.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF001A35),
                  fontSize: responsive.font(44),
                  fontWeight: FontWeight.w900,
                  height: 1.12,
                ),
              ),
              SizedBox(height: responsive.space(isShort ? 20 : 28)),
              Text(
                'Cara paling cerdas untuk mengelola\npengeluaran bersama dan membagi\ntagihan dengan teman.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: const Color(0xFF5E5656),
                  fontSize: responsive.font(19),
                  height: 1.5,
                ),
              ),
              SizedBox(height: responsive.space(isShort ? 36 : 58)),
              SizedBox(
                width: double.infinity,
                height: responsive.space(64),
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(
                      context,
                    ).push(MaterialPageRoute(builder: (_) => const AuthPage()));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF4048),
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shadowColor: const Color(0x33FF4048),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                  ),
                  child: Text(
                    'Mulai Sekarang',
                    style: TextStyle(
                      fontSize: responsive.font(22),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              SizedBox(height: responsive.space(40)),
            ],
          ),
        ),
      ),
    );
  }
}
