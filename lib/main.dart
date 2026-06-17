import 'package:flutter/material.dart';

import 'authentication/auth_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AuthService.initialize();
  runApp(const SplitSyncApp());
}

class SplitSyncApp extends StatelessWidget {
  const SplitSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFCF7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8152B),
          primary: const Color(0xFFC8152B),
          secondary: const Color(0xFF001A35),
          surface: Colors.white,
        ),
        fontFamily: 'Arial',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            color: Color(0xFF001A35),
            fontWeight: FontWeight.w800,
          ),
          headlineMedium: TextStyle(
            color: Color(0xFF001A35),
            fontWeight: FontWeight.w800,
          ),
          titleLarge: TextStyle(
            color: Color(0xFF001A35),
            fontWeight: FontWeight.w800,
          ),
          bodyMedium: TextStyle(color: Color(0xFF585858)),
        ),
      ),
      home: const SplashScreen(),
    );
  }
}
