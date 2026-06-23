import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'features/expenses/presentation/pages/add_expense_page.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Supabase.initialize(
      url: 'https://mkdacnbbvjgekosdhevw.supabase.co',
      anonKey: 'sb_publishable_dpm-U61n41ih8DM8vGyNhQ_fMSyt5WL',
    );
    debugPrint('Supabase initialized successfully');
  } catch (e) {
    debugPrint('Error initializing Supabase: $e');
  }

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
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFD70F1F)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.white,
      ),
      home: AddExpensePage(
        groupId: '',
        groupName: 'Keluarga Cemara',
        userId: '',
        members: <Member>[
          Member(id: '1', name: 'John', avatarUrl: ''),
          Member(id: '2', name: 'Jane', avatarUrl: ''),
          Member(id: '3', name: 'Bob', avatarUrl: ''),
        ],
      ),
    );
  }
}
