import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:splitsync/main.dart';

void main() {
  testWidgets('SplitSync starts on splash screen', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(const SplitSyncApp());

    expect(find.text('SplitSync'), findsOneWidget);
    expect(find.text('Pengeluaran, lebih seimbang.'), findsOneWidget);
  });
}
