import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kepr/constants/severity.dart';
import 'package:kepr/screens/start_inspection_flow.dart';
import 'package:kepr/services/inspection_session.dart';
import 'package:kepr/services/supabase_repository.dart';
import 'package:kepr/widgets/bottom_nav.dart';
import 'package:kepr/widgets/severity_pill.dart';

/// The narrowest phone the app is expected to support.
const smallPhone = Size(360, 640);

Future<void> setViewport(
    WidgetTester tester, Size size, double textScale) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  tester.platformDispatcher.textScaleFactorTestValue = textScale;
  addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
}

void main() {
  const inspector = InspectorLogin(
    userId: 'i-1',
    displayName: 'Test Inspector',
    phone: '9876543210',
    authToken: 'token',
  );

  tearDown(InspectionSession.clear);

  testWidgets('start flow has no overflow at 360px', (tester) async {
    await setViewport(tester, smallPhone, 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: StartInspectionFlow(
          inspector: inspector,
          onStarted: () {},
          onSessionExpired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Flat Property'), findsOneWidget);
  });

  testWidgets('start flow survives 200% text scale', (tester) async {
    await setViewport(tester, smallPhone, 2.0);

    await tester.pumpWidget(
      MaterialApp(
        home: StartInspectionFlow(
          inspector: inspector,
          onStarted: () {},
          onSessionExpired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });

  testWidgets('plan step survives 200% text scale', (tester) async {
    await setViewport(tester, smallPhone, 2.0);

    await tester.pumpWidget(
      MaterialApp(
        home: StartInspectionFlow(
          inspector: inspector,
          onStarted: () {},
          onSessionExpired: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    // At 200% scale the third option sits below the fold, so scroll to it
    // rather than assuming it is on screen.
    await tester.scrollUntilVisible(find.text('Society'), 120);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Society'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Which plan applies?'), findsOneWidget);
  });

  group('bottom navigation', () {
    testWidgets('exposes all four destinations', (tester) async {
      await setViewport(tester, smallPhone, 1.0);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNav(
              activeTab: AppTab.home,
              onTabChange: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Inspect'), findsOneWidget);
      expect(find.text('Reports'), findsOneWidget);
      expect(find.text('Me'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('reports each tap and survives 200% text scale',
        (tester) async {
      await setViewport(tester, smallPhone, 2.0);
      final tapped = <AppTab>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: BottomNav(
              activeTab: AppTab.home,
              onTabChange: tapped.add,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Reports'));
      await tester.pumpAndSettle();

      expect(tapped, [AppTab.reports]);
      expect(tester.takeException(), isNull);
    });
  });

  testWidgets('severity choices render every level without overflow',
      (tester) async {
    await setViewport(tester, smallPhone, 1.0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Column(
            children: [
              for (final severity in Severity.values)
                SeverityChoice(
                  severity: severity,
                  selected: severity == Severity.critical,
                  onTap: () {},
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('No issue'), findsOneWidget);
    expect(find.text('Critical'), findsOneWidget);
  });
}
