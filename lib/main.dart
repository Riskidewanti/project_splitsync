import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'authentication/auth_service.dart';
import 'screens/splash_screen.dart';
import 'features/ocr/presentation/pages/scan_page.dart';
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mkdacnbbvjgekosdhevw.supabase.co',
    publishableKey: 'sb_publishable_dpm-U61n41ih8DM8vGyNhQ_fMSyt5WL',
  );

  await AuthService.initialize();

  debugPrint('Supabase Connected!');
  debugPrint('${Supabase.instance.client.auth.currentUser}');

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
      ),
      home: const SplashScreen(),
    );
  }
}