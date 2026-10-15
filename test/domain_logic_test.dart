import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_explorer/application/catalog.dart';
import 'package:travel_explorer/application/insights.dart';
import 'package:travel_explorer/application/providers.dart';
import 'package:travel_explorer/core/utils/labels.dart';
import 'package:travel_explorer/data/repositories/bundled_catalog_repository.dart';
import 'package:travel_explorer/data/repositories/local_database.dart';
import 'package:travel_explorer/data/services/photo_storage.dart';
import 'package:travel_explorer/domain/entities/common.dart';
import 'package:travel_explorer/domain/entities/place.dart';
import 'package:travel_explorer/domain/entities/user_activity.dart';
import 'package:travel_explorer/features/explore/place_filters.dart';

Future<ProviderContainer> makeContainer(Directory dir, {LocalDatabase? db}) async {
  final database = db ?? await LocalDatabase.openForTest(dir.path);
  final container = ProviderContainer(
    overrides: [
      localDatabaseProvider.overrideWithValue(database),
      photoStorageProvider.overrideWithValue(PhotoStorage(dir)),
      catalogRepositoryProvider.overrideWithValue(const BundledCatalogRepository(simulatedLatency: Duration.zero)),
    ],
  );
  await container.read(catalogDataProvider.future);
  return container;
}

void main() {
  late Directory dir;
  setUp(() => dir = Directory.systemTemp.createTempSync('te_test'));
  tearDown(() => dir.deleteSync(recursive: true));

  group('catalog data', () {
    test('ids are unique and every place belongs to a known destination', () async {
      final data = await const BundledCatalogRepository(simulatedLatency: Duration.zero).load();
      final ids = data.places.map((p) => p.id).toList();
      expect(ids.toSet().length, ids.length);
      final destIds = data.destinations.map((d) => d.id).toSet();
      final regionIds = data.regions.map((r) => r.id).toSet();
      for (final p in data.places) {
        expect(destIds, contains(p.destinationId), reason: p.id);
        expect(regionIds, contains(p.regionId), reason: p.id);
        expect(p.source, DataSource.curatedSample);
      }
      for (final d in data.destinations) {
        expect(regionIds, contains(d.regionId));
      }
    });

    test('Varkala Beach sits under Thiruvananthapuram with its municipality', () async {
      final data = await const BundledCatalogRepository(simulatedLatency: Duration.zero).load();
      final v = data.places.firstWhere((p) => p.name == 'Varkala Beach');
      expect(v.destinationId, 'thiruvananthapuram');
      expect(v.locality, contains('Varkala municipality'));
    });

    test('search finds destinations, places and dishes', () async {
      final data = await const BundledCatalogRepository(simulatedLatency: Duration.zero).load();
      final cat = Catalog(data, const []);
      expect(cat.search('munnar').first.title, 'Munnar');
      expect(cat.search('echo').any((h) => h.title == 'Echo Point'), isTrue);
      expect(cat.search('biryani').any((h) => h.type == SearchHitType.dish), isTrue);
      expect(cat.search('kyoto', countryId: 'in'), isEmpty);
    });
  });

  group('labels', () {
    test('monthRange handles wrap-around and contiguous ranges', () {
      expect(monthRange([9, 10, 11, 12, 1, 2, 3]), 'Sep – Mar');
      expect(monthRange([5, 6, 7, 8, 9]), 'May – Sep');
      expect(monthRange(List.generate(12, (i) => i + 1)), 'Year-round');
      expect(monthRange([4, 11]), 'Apr, Nov');
    });
  });

  group('filters', () {
    test('groups OR within, AND across; sort by distance', () async {
      final data = await const BundledCatalogRepository(simulatedLatency: Duration.zero).load();
      final cat = Catalog(data, const []);
      final munnar = cat.placesAt('munnar').where((p) => !p.isFood).toList();
      final gems = const PlaceQuery(filters: {PlaceFilter.hiddenGems}).apply(munnar, visitedIds: {}, catalog: cat);
      expect(gems.every((p) => p.kind == PlaceKind.hiddenGem), isTrue);
      final visited = const PlaceQuery(filters: {PlaceFilter.visited})
          .apply(munnar, visitedIds: {'munnar.echo-point'}, catalog: cat);
      expect(visited.map((p) => p.id), ['munnar.echo-point']);
      final both = const PlaceQuery(filters: {PlaceFilter.visited, PlaceFilter.notVisited})
          .apply(munnar, visitedIds: {'munnar.echo-point'}, catalog: cat);
      expect(both.length, munnar.length);
      final byDist = const PlaceQuery(sort: PlaceSort.distance).apply(munnar, visitedIds: {}, catalog: cat);
      final d = byDist.map((p) => cat.distanceFromCentre(p)!).toList();
      expect(d, [...d]..sort());
    });
  });

  group('user activity', () {
    test('visits update stats, bucket remaining and achievements', () async {
      final c = await makeContainer(dir);
      await c.read(bucketProvider.notifier).toggle(SubjectType.place, 'munnar.echo-point');
      expect(c.read(travelStatsProvider).bucketRemaining, 1);

      await c
          .read(visitsProvider.notifier)
          .markVisited(SubjectType.place, 'munnar.echo-point', on: DateTime(2026, 8, 15));
      await c.read(visitsProvider.notifier).markVisited(SubjectType.place, 'wayanad.edakkal-caves');
      final s = c.read(travelStatsProvider);
      expect(s.placesVisited, 2);
      expect(s.cities, 2);
      expect(s.regions, 1);
      expect(s.byRegion['Kerala'], 2);
      expect(s.bucketRemaining, 0);
      expect(c.read(achievementsProvider).firstWhere((a) => a.id == 'first').unlocked, isTrue);
      expect(c.read(travelHistoryProvider).single.regions.single.cities.length, 2);
    });

    test('a memory implies a visit, and removing the visit removes the memory', () async {
      final c = await makeContainer(dir);
      await c
          .read(memoriesProvider.notifier)
          .save(
            placeId: 'munnar.top-station',
            title: 'Clouds',
            date: DateTime(2026, 8, 16),
            note: 'Wow',
            photos: const [],
          );
      expect(c.read(visitForProvider('munnar.top-station')), isNotNull);
      await c.read(visitsProvider.notifier).unmark('munnar.top-station');
      expect(c.read(memoriesProvider), isEmpty);
    });

    test('trip activities never create visits', () async {
      final c = await makeContainer(dir);
      final t = await c
          .read(tripsProvider.notifier)
          .create(title: 'Munnar', destinationId: 'munnar', start: DateTime.now(), days: 2);
      final day = t.days.first.copyWith(
        activities: [TripActivity(id: 'a', title: 'Echo Point', placeId: 'munnar.echo-point', done: true)],
      );
      await c.read(tripsProvider.notifier).put(t.copyWith(days: [day, t.days.last]));
      expect(c.read(visitsProvider), isEmpty);
      expect(c.read(tripProvider(t.id))!.completedActivities, 1);
    });

    test('data persists across a restart', () async {
      final db = await LocalDatabase.openForTest(dir.path);
      final c1 = await makeContainer(dir, db: db);
      await c1.read(settingsProvider.notifier).selectCountry('in');
      await c1.read(visitsProvider.notifier).markVisited(SubjectType.place, 'goa.palolem');
      await c1
          .read(customPlacesProvider.notifier)
          .save(
            Place(
              id: 'user.1',
              kind: PlaceKind.hiddenGem,
              countryId: 'in',
              regionId: 'in-kl',
              destinationId: 'munnar',
              name: 'Secret Ridge',
              description: 'A quiet ridge',
              location: const GeoPoint(10.1, 77.1),
              source: DataSource.userSubmitted,
            ),
          );
      c1.dispose();

      final c2 = await makeContainer(dir, db: db);
      expect(c2.read(settingsProvider).countryId, 'in');
      expect(c2.read(visitForProvider('goa.palolem')), isNotNull);
      expect(c2.read(catalogProvider).value!.place('user.1')!.name, 'Secret Ridge');
      expect(c2.read(catalogProvider).value!.placesAt('munnar').any((p) => p.id == 'user.1'), isTrue);
    });
  });
}
