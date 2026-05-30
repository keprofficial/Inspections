import 'package:flutter_test/flutter_test.dart';
import 'package:kepr/main.dart';

void main() {
  testWidgets('Kepr app starts on the login screen', (tester) async {
    await tester.pumpWidget(const KeprApp());

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });
}
