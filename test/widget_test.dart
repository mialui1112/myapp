import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';
import 'package:myapp/services/download_service.dart';
import 'package:myapp/services/firestore_service.dart';
import 'package:myapp/services/otruyen_api_service.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets('Counter increments smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          Provider<OTruyenApiService>(create: (_) => OTruyenApiService()),
          Provider<FirestoreService>(create: (_) => FirestoreService()),
          ChangeNotifierProvider<DownloadService>(create: (_) => DownloadService()),
        ],
        child: const MyApp(),
      ),
    );

    // Verify that our counter starts at 0.
    expect(find.text('0'), findsOneWidget);
    expect(find.text('1'), findsNothing);

    // Tap the '+' icon and trigger a frame.
    await tester.tap(find.byIcon(Icons.add));
    await tester.pump();

    // Verify that our counter has incremented.
    expect(find.text('0'), findsNothing);
    expect(find.text('1'), findsOneWidget);
  });
}
