import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_friends_page.dart';
import 'authentication/auth_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/local_notification_service.dart';
import 'features/ocr/presentation/pages/scan_page.dart';
import 'features/settlements/presentation/pages/settlement_debt_list_page.dart';
import 'firebase_options.dart';
import 'friends_list_page.dart';
import 'reports/reports_page.dart';
import 'screens/authentication/add_pin_option_page.dart';
import 'screens/authentication/auth_page.dart';
import 'screens/authentication/create_pin_page.dart';
import 'screens/authentication/pin_created_page.dart';
import 'screens/authentication/splash_screen.dart';
import 'screens/authentication/welcome_page.dart';
import 'screens/home/home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: 'https://mkdacnbbvjgekosdhevw.supabase.co',
    publishableKey: 'sb_publishable_dpm-U61n41ih8DM8vGyNhQ_fMSyt5WL',
  );

  await AuthService.initialize();
  await LocalNotificationService.instance.initialize();
  await FcmService.instance.initialize();

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
      routes: {
        '/splash': (_) => const SplashScreen(),
        '/welcome': (_) => const WelcomePage(),
        '/auth': (_) => const AuthPage(),
        '/add-pin': (_) => const AddPinOptionPage(),
        '/create-pin': (_) => const CreatePinPage(),
        '/pin-created': (_) => const PinCreatedPage(),
        '/home': (_) => const HomePage(),
        '/scan': (_) => const ScanPage(),
        '/reports': (_) => const ReportsPage(),
        '/settlements': (_) => const SettlementDebtListPage(),
        '/friends/add': (_) => const AddFriendsPage(),
        '/friends': (_) => const FriendsListPage(),
      },
    );
  }
}