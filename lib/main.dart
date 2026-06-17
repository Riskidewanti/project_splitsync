import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/ocr/presentation/pages/scan_page.dart';
import 'features/groups/presentation/pages/group_home_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mkdacnbbvjgekosdhevw.supabase.co',
    publishableKey: 'sb_publishable_dpm-U61n41ih8DM8vGyNhQ_fMSyt5WL',
  );

  debugPrint('Supabase Connected!');
  debugPrint('${Supabase.instance.client.auth.currentUser}');
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(home: const GroupHomePage());
  }
}
