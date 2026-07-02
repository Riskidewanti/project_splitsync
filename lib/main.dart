import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_friends_page.dart';
import 'authentication/auth_service.dart';
import 'core/services/fcm_service.dart';
import 'core/services/local_notification_service.dart';
import 'core/theme/app_theme.dart';
import 'features/notifications/presentation/pages/notifications_page.dart';
import 'features/ocr/presentation/pages/scan_page.dart';
import 'features/groups/presentation/pages/group_home_page.dart';
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

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('Firebase initialized');
  } catch (e, stackTrace) {
    debugPrint('Firebase initialization failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await Supabase.initialize(
      url: 'https://mkdacnbbvjgekosdhevw.supabase.co',
      publishableKey: 'sb_publishable_dpm-U61n41ih8DM8vGyNhQ_fMSyt5WL',
    );
    debugPrint('Supabase initialized');
  } catch (e, stackTrace) {
    debugPrint('Supabase initialization failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await AuthService.initialize();
    debugPrint('Auth initialized');
  } catch (e, stackTrace) {
    debugPrint('Auth initialization failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await FcmService.instance.initialize();
    debugPrint(kIsWeb ? 'FCM initialized (skipped on Web)' : 'FCM initialized');
  } catch (e, stackTrace) {
    debugPrint('FCM initialization failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  try {
    await LocalNotificationService.instance.initialize();
    debugPrint('Local notifications initialized');
  } catch (e, stackTrace) {
    debugPrint('Local notifications initialization failed: $e');
    debugPrintStack(stackTrace: stackTrace);
  }

  debugPrint('Starting app');
  runApp(const SplitSyncApp());
}

class SplitSyncApp extends StatelessWidget {
  const SplitSyncApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitSync',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
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
        '/groups': (_) => const GroupHomePage(),
        '/reports': (_) => const ReportsPage(),
        '/notifications': (_) => const NotificationsPage(),
        '/settlements': (_) => const SettlementDebtListPage(),
        '/friends/add': (_) => const AddFriendsPage(),
        '/friends': (_) => const FriendsListPage(),
      },
    );
  }
}
