import 'package:flutter/material.dart';

import '../authentication/auth_service.dart';
import '../widgets/responsive.dart';
import 'home_page.dart';
import 'welcome_page.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scale;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..forward();
    _scale = CurvedAnimation(parent: _controller, curve: Curves.easeOutBack);
    _fade = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _continue();
  }

  Future<void> _continue() async {
    await Future<void>.delayed(const Duration(milliseconds: 2300));
    final profile = await AuthService.currentSession();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) =>
            profile == null ? const WelcomePage() : const HomePage(),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final responsive = Responsive.of(context);
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: ResponsivePage(
          maxWidth: 430,
          scrollable: true,
          padding: responsive.horizontal(24),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).vertical,
            child: Column(
              children: [
                const Spacer(flex: 4),
                ScaleTransition(
                  scale: _scale,
                  child: FadeTransition(
                    opacity: _fade,
                    child: Container(
                      width: responsive.clamp(78, 62, 86),
                      height: responsive.clamp(78, 62, 86),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: const Color(0xFFE1E1E1)),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x17000000),
                            blurRadius: 12,
                            offset: Offset(0, 6),
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Text(
                          'S',
                          style: TextStyle(
                            color: Color(0xFFFF4450),
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: responsive.space(26)),
                Text(
                  'SplitSync',
                  style: TextStyle(
                    color: const Color(0xFF001A35),
                    fontSize: responsive.font(42),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0,
                  ),
                ),
                const Spacer(flex: 5),
                Text(
                  'Pengeluaran, lebih seimbang.',
                  style: TextStyle(
                    color: const Color(0xFF6B6B6B),
                    fontSize: responsive.font(18),
                    letterSpacing: 0,
                  ),
                ),
                SizedBox(height: responsive.space(42)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
