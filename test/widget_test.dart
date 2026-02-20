
import 'package:flutter_test/flutter_test.dart';

import 'package:myapp/main.dart';

void main() {
  testWidgets('smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that our app has a title.
    expect(find.text('Comics'), findsOneWidget);
    expect(find.text('Movies'), findsOneWidget);
  });
}
