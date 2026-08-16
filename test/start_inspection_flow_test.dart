import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kepr/screens/start_inspection_flow.dart';
import 'package:kepr/services/inspection_session.dart';
import 'package:kepr/services/supabase_repository.dart';

void main() {
  const inspector = InspectorLogin(
    userId: 'inspector-test',
    displayName: 'Test Inspector',
    phone: '9876543210',
    authToken: 'test-token',
  );

  Widget wrap() => MaterialApp(
        home: StartInspectionFlow(
          inspector: inspector,
          onStarted: () {},
          onSessionExpired: () {},
        ),
      );

  tearDown(InspectionSession.clear);

  testWidgets('step 1 asks what is being inspected, not the plan',
      (tester) async {
    await tester.pumpWidget(wrap());

    expect(find.text('Step 1 of 3'), findsOneWidget);
    expect(find.text('What are you inspecting?'), findsOneWidget);
    expect(find.text('Flat Property'), findsOneWidget);
    expect(find.text('Society'), findsOneWidget);
    expect(find.text('Individual Home'), findsOneWidget);

    // The plan step must not be visible yet.
    expect(find.text('Free'), findsNothing);
    expect(find.text('Ad-hoc'), findsNothing);
  });

  testWidgets('choosing a mode advances to the plan step', (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Society'));
    await tester.pumpAndSettle();

    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Which plan applies?'), findsOneWidget);
    expect(find.text('Free'), findsOneWidget);
    expect(find.text('Ad-hoc'), findsOneWidget);
    expect(find.text('Paid'), findsOneWidget);
  });

  testWidgets('ad-hoc plan states its custom-check requirement up front',
      (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Individual Home'));
    await tester.pumpAndSettle();

    expect(
      find.textContaining('at least one custom check required'),
      findsOneWidget,
    );
  });

  testWidgets('individual mode collects owner details on step 3',
      (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Individual Home'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paid'));
    await tester.pumpAndSettle();

    expect(find.text('Step 3 of 3'), findsOneWidget);
    expect(find.text('Individual home details'), findsOneWidget);
    expect(find.text('Property name'), findsOneWidget);
    expect(find.text('Property owner name'), findsOneWidget);
    expect(find.text('Property owner mobile'), findsOneWidget);
    expect(find.text('Start inspection'), findsOneWidget);
  });

  testWidgets('flat mode uses tappable pickers, not inline dropdowns',
      (tester) async {
    await tester.pumpWidget(wrap());

    await tester.tap(find.text('Flat Property'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paid'));
    await tester.pumpAndSettle();

    expect(find.text('Which flat?'), findsOneWidget);
    expect(find.text('Choose a society'), findsOneWidget);
    // Downstream pickers are disabled until their parent is chosen, so the
    // page cannot shift under the user's thumb.
    expect(find.text('Select a society first'), findsOneWidget);
    expect(find.text('Select a block first'), findsOneWidget);
  });

  testWidgets('back from step 1 leaves the flow', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => StartInspectionFlow(
                    inspector: inspector,
                    onStarted: () {},
                    onSessionExpired: () {},
                  ),
                ),
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('What are you inspecting?'), findsOneWidget);

    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();
    expect(find.text('open'), findsOneWidget);
  });
}
