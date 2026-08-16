import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kepr/constants/app_styles.dart';
import 'package:kepr/widgets/app_card.dart';

/// Reproduces the Inspect tab's sliver structure to prove that every area in
/// the list is reachable — the list must scroll, not silently stop early.
void main() {
  Widget harness(int areaCount) {
    return MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Expanded(
              child: CustomScrollView(
                slivers: [
                  const SliverAppBar(pinned: true, title: Text('Inspection')),
                  const SliverToBoxAdapter(child: SizedBox(height: 300)),
                  SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        if (index == areaCount) {
                          return const SizedBox(
                            height: 56,
                            child: Center(child: Text('Add area')),
                          );
                        }
                        return Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(
                              maxWidth: AppSizes.contentMaxWidth,
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(AppSpacing.lg),
                              child: AppCard(
                                child: Text('Area $index'),
                              ),
                            ),
                          ),
                        );
                      },
                      childCount: areaCount + 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }

  testWidgets('every area is reachable by scrolling', (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(harness(9));
    await tester.pumpAndSettle();

    // The first area must be present without scrolling.
    expect(find.text('Area 0'), findsOneWidget);

    // The last area and the add tile must be reachable.
    await tester.scrollUntilVisible(find.text('Area 8'), 200);
    expect(find.text('Area 8'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Add area'), 200);
    expect(find.text('Add area'), findsOneWidget);

    expect(tester.takeException(), isNull);
  });
}
