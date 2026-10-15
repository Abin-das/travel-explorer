import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_explorer/app.dart';
import 'package:travel_explorer/application/providers.dart';
import 'package:travel_explorer/data/repositories/bundled_catalog_repository.dart';
import 'package:travel_explorer/data/repositories/local_database.dart';
import 'package:travel_explorer/core/widgets/common.dart';
import 'package:travel_explorer/data/services/photo_storage.dart';

/// Lets real file I/O (Hive) finish, then advances animations.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 3; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
    await tester.pump(const Duration(milliseconds: 400));
  }
}

void main() {
  testWidgets('onboarding → explore → destination → place → mark visited', (tester) async {
    final dir = Directory.systemTemp.createTempSync('te_widget');
    addTearDown(() => dir.deleteSync(recursive: true));
    late LocalDatabase db;
    await tester.runAsync(() async => db = await LocalDatabase.openForTest(dir.path));
    tester.view.physicalSize = const Size(1080, 2340);
    tester.view.devicePixelRatio = 2.75;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          localDatabaseProvider.overrideWithValue(db),
          photoStorageProvider.overrideWithValue(PhotoStorage(dir)),
          catalogRepositoryProvider.overrideWithValue(const BundledCatalogRepository(simulatedLatency: Duration.zero)),
          remoteImagesEnabledProvider.overrideWithValue(false),
        ],
        child: const TravelExplorerApp(),
      ),
    );
    await settle(tester);

    // First run: country selection with India preselected.
    expect(find.text('India'), findsOneWidget);
    await tester.tap(find.text('Start exploring'));
    await settle(tester);

    expect(find.textContaining('Explorer!'), findsOneWidget);
    expect(find.text('Popular Destinations'), findsOneWidget);
    expect(find.text('Munnar'), findsWidgets);

    // Search for Munnar and open it.
    await tester.tap(find.byType(AppSearchField));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Munnar');
    await settle(tester);
    await tester.tap(find.text('Munnar').first);
    await settle(tester);
    expect(find.textContaining('Rolling tea gardens'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Best Time to Visit'), 300, scrollable: find.byType(Scrollable).first);
    expect(find.text('Best Time to Visit'), findsOneWidget);

    await tester.scrollUntilVisible(find.text('Echo Point'), 300, scrollable: find.byType(Scrollable).first);
    await tester.tap(find.text('Echo Point'));
    await settle(tester);

    await tester.tap(find.text('Mark as Visited'));
    await settle(tester);
    await tester.tap(find.widgetWithText(FilledButton, 'Mark as visited'));
    await settle(tester);
    // The sticky action bar now shows the visit, and the status card appears.
    expect(find.textContaining('Visited ·'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Status: Visited ✓'), 200, scrollable: find.byType(Scrollable).first);
    expect(find.text('Status: Visited ✓'), findsOneWidget);
    expect(find.textContaining('Visited on:'), findsOneWidget);

    // Drain the celebration overlay and snackbar timers.
    await tester.pump(const Duration(seconds: 5));
  }, timeout: const Timeout(Duration(seconds: 90)));
}
