import 'package:flutter_test/flutter_test.dart';
import 'package:myapp/main.dart';

void main() {
  testWidgets('GeoTracker app smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const GeoTrackerApp());
    expect(find.byType(GeoTrackerApp), findsOneWidget);
  });
}