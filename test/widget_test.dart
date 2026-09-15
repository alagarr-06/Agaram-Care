import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:agaram_care/app/app.dart';

void main() {
  testWidgets('Agaram Care app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: AgaramCareApp()));
    expect(find.text('Agaram Care'), findsOneWidget);

    // Let the splash screen timer complete
    await tester.pumpAndSettle(const Duration(milliseconds: 1500));
  });
}
