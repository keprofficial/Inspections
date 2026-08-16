import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kepr/screens/signin_screen.dart';
import 'package:kepr/services/inspection_session.dart';

void main() {
  setUp(() {
    InspectionSession.clear();
    InspectionSession.inspectorId = 'inspector-test';
    InspectionSession.inspectorName = 'Test Inspector';
    InspectionSession.mobileNumber = '9876543210';
    InspectionSession.authToken = 'test-token';
    InspectionSession.lastLoginAt = DateTime.now();
  });

  tearDown(InspectionSession.clear);

  testWidgets('shows property choices before plan choices', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SignInScreen()),
    );

    expect(find.textContaining('Test Inspector'), findsOneWidget);
    expect(find.text('Flat Property'), findsOneWidget);
    expect(find.text('Society'), findsOneWidget);
    expect(find.text('Individual Home'), findsOneWidget);
    expect(find.text('50 basic checks'), findsNothing);

    await tester.tap(find.text('Society'));
    await tester.pumpAndSettle();

    expect(find.text('50 basic checks'), findsOneWidget);
    expect(find.text('Complete checklist'), findsOneWidget);
    expect(find.text('Create custom checks'), findsOneWidget);
    expect(find.text('Continue to property details'), findsNothing);
  });

  testWidgets('continues from selected property and plan to correct fields',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SignInScreen()),
    );

    await tester.tap(find.text('Individual Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paid'));
    await tester.pumpAndSettle();

    final continueFinder = find.text('Continue to property details');
    await tester.ensureVisible(continueFinder);
    await tester.tap(continueFinder);
    await tester.pumpAndSettle();

    expect(find.text('Individual home details'), findsOneWidget);
    expect(find.text('Property name'), findsOneWidget);
    expect(find.text('Property owner name'), findsOneWidget);
    expect(find.text('Property owner mobile'), findsOneWidget);
    expect(find.text('Start Individual Inspection'), findsOneWidget);
  });
}
