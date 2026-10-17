import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:travel_explorer/app.dart';
import 'package:travel_explorer/application/providers.dart';
import 'package:travel_explorer/core/router/app_router.dart';
import 'package:travel_explorer/data/repositories/bundled_catalog_repository.dart';
import 'package:travel_explorer/data/repositories/local_database.dart';
import 'package:travel_explorer/data/services/integration_points.dart';
import 'package:travel_explorer/data/services/photo_storage.dart';
import 'package:travel_explorer/domain/entities/common.dart';
import 'package:travel_explorer/domain/entities/place.dart';
import 'package:travel_explorer/domain/entities/user_activity.dart';

/// Opens every screen and tab at several device sizes and font scales,
/// scrolls each to the bottom, and fails on any layout overflow.
///
/// Run: flutter test test/responsive_audit_test.dart
class _Device {
  const _Device(this.name, this.size, this.textScale);
  final String name;
  final Size size;
  final double textScale;
}

const _devices = [
  _Device('small phone 320x568', Size(320, 568), 1.0),
  _Device('small phone, large text', Size(320, 568), 1.3),
  _Device('phone 393x852', Size(393, 852), 1.0),
  _Device('phone, largest text', Size(393, 852), 2.0),
  _Device('tablet 800x1280', Size(800, 1280), 1.0),
];

/// (route, tabs to visit on that route)
const _routes = <(String, List<String>)>[
  ('/home', []),
  ('/explore', []),
  ('/search', []),
  ('/countries', []),
  ('/region/in-kl', []),
  ('/destination/munnar', []),
  ('/place/munnar.echo-point', []),
  ('/place/kochi.kashi-art-cafe', []),
  ('/place/user.audit', []),
  ('/category/mountains', []),
  ('/gems', []),
  ('/food', []),
  ('/seasons', []),
  ('/add-place', []),
  ('/add-place?kind=foodSpot&destination=munnar', []),
  ('/my-places', []),
  ('/memory/new?place=munnar.top-station', []),
  ('/memory/mem.audit', []),
  ('/visited/munnar', []),
  ('/trip/new', []),
  ('/trip/trip.audit', []),
  ('/analytics', []),
  ('/achievements', []),
  ('/settings', []),
  ('/notifications', []),
  ('/map', []),
  ('/travels', ['Overview', 'History', 'Timeline', 'Journal']),
  ('/bucket', ['Saved Places', 'Food', 'Trip Planner']),
  ('/profile', []),
];

Future<void> _seed(ProviderContainer c, Directory photos) async {
  await c.read(settingsProvider.notifier).selectCountry('in');
  await c
      .read(profileProvider.notifier)
      .save(const UserProfile(displayName: 'Anjali Ramachandran-Krishnan', bio: 'Mountains over beaches, always.'));
  final v = c.read(visitsProvider.notifier);
  for (final (id, d) in [
    ('munnar.echo-point', DateTime(2026, 8, 15)),
    ('munnar.mattupetty-dam', DateTime(2026, 8, 15)),
    ('munnar.lakkam-falls', DateTime(2026, 8, 16)),
    ('wayanad.edakkal-caves', DateTime(2026, 7, 2)),
    ('kochi.kashi-art-cafe', DateTime(2026, 6, 10)),
    ('goa.palolem', DateTime(2025, 12, 28)),
  ]) {
    await v.markVisited(SubjectType.place, id, on: d, rating: 4);
  }
  await c
      .read(notesProvider.notifier)
      .setNote('munnar.echo-point', 'Beautiful mountain views and an amazing experience.');
  File('assets/branding/icon.png').copySync('${photos.path}/audit.png');
  final visit = c.read(visitForProvider('munnar.echo-point'))!;
  await c
      .read(memoriesProvider.notifier)
      .put(
        TravelMemory(
          id: 'mem.audit',
          visitId: visit.id,
          placeId: 'munnar.echo-point',
          title: 'Misty morning at Echo Point with the whole family',
          date: DateTime(2026, 8, 15),
          note: 'We shouted across the lake and the hills shouted back. Carrots from the stall were the best.',
          rating: 5,
          photos: [
            for (var i = 0; i < 4; i++) TravelPhoto(id: 'p$i', path: 'audit.png', addedAt: DateTime(2026, 8, 15)),
            TravelPhoto(id: 'missing', path: 'deleted.png', addedAt: DateTime(2026, 8, 15)),
          ],
          createdAt: DateTime(2026, 8, 15),
        ),
      );
  final b = c.read(bucketProvider.notifier);
  for (final (t, id) in [
    (SubjectType.destination, 'manali'),
    (SubjectType.destination, 'ladakh'),
    (SubjectType.place, 'munnar.top-station'),
    (SubjectType.place, 'goa.palolem'),
    (SubjectType.place, 'kochi.fort-kochi-seafood'),
    (SubjectType.destination, 'kyoto'),
  ]) {
    await b.toggle(t, id);
  }
  final dw = c.read(dishWishesProvider.notifier);
  await dw.addDish('kerala-sadya');
  await dw.addDish('malabar-biryani');
  await dw.addCustom('A very long custom dish name that keeps going and going');
  await dw.toggleTried(c.read(dishWishesProvider).first);
  final now = DateTime.now();
  await c
      .read(tripsProvider.notifier)
      .put(
        Trip(
          id: 'trip.audit',
          title: 'Munnar Weekend Trip with Friends and Family',
          destinationId: 'munnar',
          startDate: now.add(const Duration(days: 3)),
          createdAt: now,
          days: [
            TripDay(
              id: 'd1',
              activities: const [
                TripActivity(id: 'a1', title: 'Mattupetty Dam', placeId: 'munnar.mattupetty-dam', done: true),
                TripActivity(id: 'a2', title: 'Echo Point', placeId: 'munnar.echo-point'),
                TripActivity(id: 'a3', title: 'Kundala Lake', placeId: 'munnar.kundala-lake'),
              ],
            ),
            TripDay(
              id: 'd2',
              activities: const [
                TripActivity(id: 'a4', title: 'Top Station', placeId: 'munnar.top-station'),
                TripActivity(id: 'a5', title: 'Local food exploration around the town bazaar and estate stalls'),
              ],
            ),
            const TripDay(id: 'd3', activities: []),
          ],
        ),
      );
  await c
      .read(customPlacesProvider.notifier)
      .save(
        Place(
          id: 'user.audit',
          kind: PlaceKind.hiddenGem,
          countryId: 'in',
          regionName: 'Kerala',
          cityName: 'Vagamon',
          name: 'Pine Forest Meadow Viewpoint Above The Clouds',
          description: 'A quiet meadow beyond the pine forest.',
          location: const GeoPoint(9.68, 76.9),
          categories: const [PlaceCategory.forests, PlaceCategory.viewpoints],
          tips: const ['Go early'],
          source: DataSource.userSubmitted,
          submission: Submission(status: SubmissionStatus.localOnly, createdAt: now, updatedAt: now),
        ),
      );
}

String _describe(FlutterErrorDetails d) {
  final text = d.toString();
  final first = d.exceptionAsString().split('\n').first;
  final loc = RegExp(r'lib/[\w/]+\.dart:\d+').firstMatch(text)?.group(0);
  if (loc != null) return '$first  @ $loc';
  // Raised inside a framework widget: show the nearest ancestors instead.
  final creator = RegExp(r'creator: ([^\n]+(?:\n {4}[^\n]+)?)').firstMatch(text)?.group(1) ?? '';
  return '$first  @ ${creator.replaceAll(RegExp(r'\s+'), ' ')}';
}

Future<void> _pump(WidgetTester tester, [int times = 3]) async {
  for (var i = 0; i < times; i++) {
    await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 20)));
    await tester.pump(const Duration(milliseconds: 350));
  }
}

/// Scrolls every vertical scrollable on screen to the end, so lazily built
/// content below the fold gets laid out too.
Future<void> _scrollAll(WidgetTester tester) async {
  for (var pass = 0; pass < 40; pass++) {
    final scrollables = find.byWidgetPredicate((w) => w is Scrollable && (w.axisDirection == AxisDirection.down));
    var moved = false;
    for (final e in scrollables.evaluate().toList()) {
      final state = (e as StatefulElement).state as ScrollableState;
      final pos = state.position;
      if (!pos.hasContentDimensions || pos.pixels >= pos.maxScrollExtent - 1) continue;
      pos.jumpTo((pos.pixels + pos.viewportDimension * 0.8).clamp(0, pos.maxScrollExtent));
      moved = true;
    }
    if (!moved) break;
    await tester.pump(const Duration(milliseconds: 120));
  }
  await tester.pump(const Duration(milliseconds: 400));
}

void main() {
  for (final device in _devices) {
    testWidgets('no layout overflow — ${device.name} (text ×${device.textScale})', (tester) async {
      final dir = Directory.systemTemp.createTempSync('te_audit');
      addTearDown(() => dir.deleteSync(recursive: true));
      late LocalDatabase db;
      await tester.runAsync(() async => db = await LocalDatabase.openForTest(dir.path));

      tester.view.physicalSize = device.size * 3;
      tester.view.devicePixelRatio = 3;
      tester.platformDispatcher.textScaleFactorTestValue = device.textScale;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      final container = ProviderContainer(
        overrides: [
          localDatabaseProvider.overrideWithValue(db),
          photoStorageProvider.overrideWithValue(PhotoStorage(dir)),
          catalogRepositoryProvider.overrideWithValue(const BundledCatalogRepository(simulatedLatency: Duration.zero)),
          remoteImagesEnabledProvider.overrideWithValue(false),
          // No network in tests; this audit checks layout, not tile downloads.
          mapTileConfigProvider.overrideWithValue(MapTileConfig.none),
        ],
      );
      addTearDown(container.dispose);
      await tester.runAsync(() async {
        await container.read(catalogDataProvider.future);
        await _seed(container, dir);
      });

      final problems = <String>{};
      final original = FlutterError.onError;
      FlutterError.onError = (d) {
        final s = d.exceptionAsString();
        // Map tiles can't load in tests (no network); that's expected.
        if (s.contains('HTTP') ||
            s.contains('NetworkImage') ||
            s.contains('tile') ||
            s.contains('MissingPluginException')) {
          return;
        }
        problems.add('${_current ?? ''}: ${_describe(d)}');
      };

      await tester.pumpWidget(UncontrolledProviderScope(container: container, child: const TravelExplorerApp()));
      await _pump(tester);

      final router = container.read(routerProvider);
      for (final (route, tabs) in _routes) {
        _current = route;
        router.go(route);
        await _pump(tester);
        await _scrollAll(tester);
        for (final tab in tabs) {
          _current = '$route [$tab]';
          final f = find.widgetWithText(Tab, tab);
          if (f.evaluate().isEmpty) {
            problems.add('$_current: tab not found');
            continue;
          }
          await tester.tap(f.first, warnIfMissed: false);
          await _pump(tester, 2);
          await _scrollAll(tester);
        }
      }
      _current = null;
      // Let snackbars / timers finish.
      await tester.pump(const Duration(seconds: 5));
      // Let in-flight image decodes finish before restoring the error handler.
      await tester.pumpWidget(const SizedBox());
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 500)));
      await tester.pump();
      FlutterError.onError = original;

      if (problems.isNotEmpty) {
        File('build/responsive_audit.txt').writeAsStringSync(
          '## ${device.name} ×${device.textScale}\n${problems.join('\n')}\n\n',
          mode: FileMode.append,
        );
      }
      expect(problems, isEmpty, reason: '\n${problems.join('\n')}');
    }, timeout: const Timeout(Duration(minutes: 4)));
  }
}

String? _current;
