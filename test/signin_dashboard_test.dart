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

  testWidgets('dashboard starts the property then plan flow', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SignInScreen()),
    );

    expect(find.textContaining('Test Inspector'), findsOneWidget);
    expect(find.text("Here's your inspection activity"), findsOneWidget);
    expect(find.text('Weekly inspections'), findsOneWidget);
    expect(find.text('Total'), findsOneWidget);
    expect(find.text('Today'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Start new inspection'), findsOneWidget);
    expect(find.byTooltip('Navigation'), findsOneWidget);
    expect(find.text('Flat Property'), findsNothing);

    await tester.tap(find.text('Total'));
    await tester.pumpAndSettle();
    expect(find.text('All inspections'), findsOneWidget);
    expect(find.text('No inspections in this period'), findsOneWidget);
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Navigation'));
    await tester.pumpAndSettle();
    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Start inspection'), findsOneWidget);
    expect(find.text('Profile'), findsWidgets);
    await tester.tap(find.text('Dashboard'));
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.text('Start new inspection'));
    await tester.tap(find.text('Start new inspection'));
    await tester.pumpAndSettle();

    expect(find.text('Flat Property'), findsOneWidget);
    expect(find.text('Society'), findsOneWidget);
    expect(find.text('Individual Home'), findsOneWidget);
    final flatTop = tester.getTopLeft(find.text('Flat Property')).dy;
    final societyTop = tester.getTopLeft(find.text('Society')).dy;
    final individualTop = tester.getTopLeft(find.text('Individual Home')).dy;
    expect(flatTop, lessThan(societyTop));
    expect(societyTop, lessThan(individualTop));
    expect(find.text('50 basic checks'), findsNothing);

    await tester.tap(find.text('Society'));
    await tester.pumpAndSettle();

    expect(find.text('50 basic checks'), findsOneWidget);
    expect(find.text('Complete checklist'), findsOneWidget);
    expect(find.text('Create custom checks'), findsOneWidget);
    expect(find.text('Step 2 of 3'), findsOneWidget);
  });

  testWidgets('continues from selected property and plan to correct fields',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: SignInScreen()),
    );

    await tester.ensureVisible(find.text('Start new inspection'));
    await tester.tap(find.text('Start new inspection'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Individual Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paid'));
    await tester.pumpAndSettle();

    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Individual home details'), findsOneWidget);
    expect(find.text('Property name'), findsOneWidget);
    expect(find.text('Property owner name'), findsOneWidget);
    expect(find.text('Property owner mobile'), findsOneWidget);
    expect(find.text('Start Individual Inspection'), findsOneWidget);

    await tester.tap(find.text('Start Individual Inspection'));
    await tester.pumpAndSettle();

    expect(find.text('Cannot start inspection'), findsOneWidget);
    expect(find.text('Enter the property or house name.'), findsOneWidget);
  });
}
