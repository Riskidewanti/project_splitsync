import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'add_friends_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://mkdacnbbvjgekosdhevw.supabase.co',
    publishableKey: 'sb_publishable_dpm-U61n41ih8DM8vGyNhQ_fMSyt5WL',
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'SplitSync',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFFFBF8),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFC8152B),
          primary: const Color(0xFFC8152B),
        ),
      ),
      home: const AddFriendsPage(),
    );
  }
}
