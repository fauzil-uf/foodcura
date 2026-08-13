import 'package:flutter_test/flutter_test.dart';
import 'package:foodcura/main.dart';

void main() {
  testWidgets('OnboardingScreen renders correctly', (WidgetTester tester) async {
    await tester.pumpWidget(const FoodCuraApp());

    expect(find.text('FOOD MANAGEMENT'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
  });
}

