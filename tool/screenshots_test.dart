// Renders README screenshots into docs/screenshots/.
// Run (FLUTTER_ROOT supplies the Material icon font):
//   flutter test tool/screenshots_test.dart --update-goldens --dart-define=FLUTTER_ROOT=C:/flutter
// Uses sample data in a fresh database. The headless renderer can't draw
// flag emoji, so country flags appear as placeholder glyphs.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_explorer/app.dart';
import 'package:travel_explorer/application/providers.dart';
import 'package:travel_explorer/core/router/app_router.dart';
import 'package:travel_explorer/data/repositories/bundled_catalog_repository.dart';
import 'package:travel_explorer/data/repositories/local_database.dart';
import 'package:travel_explorer/data/services/integration_points.dart';
import 'package:travel_explorer/data/services/photo_storage.dart';
import 'package:travel_explorer/domain/entities/user_activity.dart';

Future<void> _font(String family, List<String> paths) async {
  final loader = FontLoader(family);
  for (final p in paths) {
    loader.addFont(Future.value(ByteData.sublistView(File(p).readAsBytesSync())));
  }
  await loader.load();
}

const _shots = [
  ('home', '/home', 0.0),
  ('explore', '/explore', 0.0),
  ('best_time', '/destination/munnar', 900.0),
  ('my_travels', '/travels?tab=timeline', 0.0),
  ('profile', '/profile', 0.0),
];

void main() {
  testWidgets('screenshots', (tester) async {
    const sdk = '${String.fromEnvironment('FLUTTER_ROOT')}/bin/cache/artifacts/material_fonts';
    await tester.runAsync(() async {
      await _font('Jakarta', ['assets/fonts/PlusJakartaSans.ttf']);
      await _font('Fraunces', ['assets/fonts/Fraunces.ttf']);
      await _font('MaterialIcons', ['$sdk/materialicons-regular.otf']);
      await _font('Roboto', ['$sdk/roboto-regular.ttf']);
    });
    debugDisableShadows = false;

    final dir = Directory.systemTemp.createTempSync('te_shots');
    late LocalDatabase db;
    await tester.runAsync(() async => db = await LocalDatabase.openForTest(dir.path));
    tester.view.physicalSize = const Size(393 * 2, 852 * 2);
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final c = ProviderContainer(
      overrides: [
        localDatabaseProvider.overrideWithValue(db),
        photoStorageProvider.overrideWithValue(PhotoStorage(dir)),
        catalogRepositoryProvider.overrideWithValue(const BundledCatalogRepository(simulatedLatency: Duration.zero)),
        remoteImagesEnabledProvider.overrideWithValue(false),
        mapTileConfigProvider.overrideWithValue(MapTileConfig.none),
      ],
    );
    addTearDown(c.dispose);
    await tester.runAsync(() async {
      await c.read(catalogDataProvider.future);
      await c.read(settingsProvider.notifier).selectCountry('in');
      await c
          .read(profileProvider.notifier)
          .save(const UserProfile(displayName: 'Abin', bio: 'Mountains over beaches, always.'));
      final v = c.read(visitsProvider.notifier);
      for (final (id, d, r) in [
        ('munnar.echo-point', DateTime(2026, 8, 15), 5),
        ('munnar.mattupetty-dam', DateTime(2026, 8, 15), 4),
        ('munnar.lakkam-falls', DateTime(2026, 8, 16), 5),
        ('wayanad.edakkal-caves', DateTime(2026, 7, 2), 4),
        ('kochi.kashi-art-cafe', DateTime(2026, 6, 10), 5),
        ('goa.palolem', DateTime(2025, 12, 28), 4),
      ]) {
        await v.markVisited(SubjectType.place, id, on: d, rating: r);
      }
      final b = c.read(bucketProvider.notifier);
      for (final (t, id) in [
        (SubjectType.destination, 'ladakh'),
        (SubjectType.place, 'munnar.top-station'),
        (SubjectType.destination, 'manali'),
      ]) {
        await b.toggle(t, id);
      }
      final now = DateTime.now();
      await c
          .read(tripsProvider.notifier)
          .put(
            Trip(
              id: 'trip.demo',
              title: 'Munnar Weekend',
              destinationId: 'munnar',
              startDate: now.add(const Duration(days: 12)),
              createdAt: now,
              days: const [
                TripDay(
                  id: 'd1',
                  activities: [
                    TripActivity(id: 'a1', title: 'Mattupetty Dam', placeId: 'munnar.mattupetty-dam', done: true),
                    TripActivity(id: 'a2', title: 'Kundala Lake', placeId: 'munnar.kundala-lake'),
                  ],
                ),
                TripDay(
                  id: 'd2',
                  activities: [TripActivity(id: 'a3', title: 'Top Station', placeId: 'munnar.top-station')],
                ),
              ],
            ),
          );
    });

    await tester.pumpWidget(UncontrolledProviderScope(container: c, child: const TravelExplorerApp()));
    final router = c.read(routerProvider);
    for (final (name, route, scroll) in _shots) {
      router.go(route);
      for (var i = 0; i < 5; i++) {
        await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
        await tester.pump(const Duration(milliseconds: 400));
      }
      if (scroll > 0) {
        await tester.drag(find.byType(Scrollable).first, Offset(0, -scroll));
        await tester.pump(const Duration(milliseconds: 800));
      }
      await expectLater(find.byType(MaterialApp), matchesGoldenFile('../docs/screenshots/$name.png'));
    }
    await tester.pumpWidget(const SizedBox());
    debugDisableShadows = true;
  });
}
