import 'package:flutter_test/flutter_test.dart';
import 'package:kepr/main.dart';

void main() {
  testWidgets('Kepr app starts on the login screen', (tester) async {
    await tester.pumpWidget(const KeprApp());

    expect(find.text('Inspector sign in'), findsOneWidget);
    expect(find.text('Mobile number'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);

    // Login is a single-purpose screen: no property or plan pickers.
    expect(find.text('Society'), findsNothing);
    expect(find.text('Flat Property'), findsNothing);
    expect(find.text('Free'), findsNothing);
  });
}
