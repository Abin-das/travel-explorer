import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../domain/entities/geography.dart';
import '../domain/entities/place.dart';
import '../domain/entities/user_activity.dart';
import 'providers.dart';

/// A visited place resolved against the catalog.
class VisitedPlace {
  const VisitedPlace(this.visit, this.place);
  final Visit visit;
  final Place place;
}

final visitedPlacesProvider = Provider<List<VisitedPlace>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const [];
  return [
    for (final v in ref.watch(visitsProvider))
      if (v.subjectType == SubjectType.place && catalog.place(v.subjectId) != null)
        VisitedPlace(v, catalog.place(v.subjectId)!),
  ]..sort((a, b) => b.visit.visitedOn.compareTo(a.visit.visitedOn));
});

class TravelStats {
  const TravelStats({
    required this.countries,
    required this.regions,
    required this.cities,
    required this.attractions,
    required this.hiddenGems,
    required this.foodSpots,
    required this.photos,
    required this.memories,
    required this.bucketTotal,
    required this.bucketRemaining,
    required this.dishesTried,
    required this.byRegion,
    required this.byCategory,
    required this.monthly,
    required this.tripsPlanned,
  });

  final int countries;
  final int regions;
  final int cities;
  final int attractions;
  final int hiddenGems;
  final int foodSpots;
  final int photos;
  final int memories;
  final int bucketTotal;
  final int bucketRemaining;
  final int dishesTried;
  final int tripsPlanned;

  /// Region name → places visited.
  final Map<String, int> byRegion;
  final Map<PlaceCategory, int> byCategory;

  /// First-of-month → places visited, last 12 months (oldest first).
  final Map<DateTime, int> monthly;

  int get placesVisited => attractions + hiddenGems + foodSpots;
}

final travelStatsProvider = Provider<TravelStats>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  final visited = ref.watch(visitedPlacesProvider);
  final visits = ref.watch(visitsProvider);
  final memories = ref.watch(memoriesProvider);
  final bucket = ref.watch(bucketProvider);
  final dishes = ref.watch(dishWishesProvider);
  final trips = ref.watch(tripsProvider);

  final visitedIds = visits.map((v) => v.subjectId).toSet();
  final destVisits = visits.where((v) => v.subjectType == SubjectType.destination).map((v) => v.subjectId);
  final destDests = destVisits.map((id) => catalog?.destination(id)).whereType<Destination>();

  final countries = {...visited.map((v) => v.place.countryId), ...destDests.map((d) => d.countryId)};
  final regions = {
    ...visited.map((v) => v.place.regionId ?? 'custom:${v.place.regionName}'),
    ...destDests.map((d) => d.regionId),
  };
  final cities = {...visited.map((v) => v.place.destinationId ?? 'custom:${v.place.cityName}'), ...destVisits};

  final byRegion = <String, int>{};
  final byCategory = <PlaceCategory, int>{};
  for (final v in visited) {
    final name = catalog?.regionName(v.place) ?? '';
    if (name.isNotEmpty) byRegion[name] = (byRegion[name] ?? 0) + 1;
    for (final c in v.place.categories) {
      byCategory[c] = (byCategory[c] ?? 0) + 1;
    }
  }

  final now = DateTime.now();
  final monthly = <DateTime, int>{for (var i = 11; i >= 0; i--) DateTime(now.year, now.month - i): 0};
  for (final v in visited) {
    final key = DateTime(v.visit.visitedOn.year, v.visit.visitedOn.month);
    if (monthly.containsKey(key)) monthly[key] = monthly[key]! + 1;
  }

  return TravelStats(
    countries: countries.length,
    regions: regions.length,
    cities: cities.length,
    attractions: visited.where((v) => v.place.kind == PlaceKind.attraction).length,
    hiddenGems: visited.where((v) => v.place.kind == PlaceKind.hiddenGem).length,
    foodSpots: visited.where((v) => v.place.kind == PlaceKind.foodSpot).length,
    photos: memories.fold(0, (s, m) => s + m.photos.length),
    memories: memories.length,
    bucketTotal: bucket.length,
    bucketRemaining: bucket.where((b) => !visitedIds.contains(b.subjectId)).length,
    dishesTried: dishes.where((d) => d.tried).length,
    byRegion: Map.fromEntries(byRegion.entries.sortedBy<num>((e) => -e.value)),
    byCategory: byCategory,
    monthly: monthly,
    tripsPlanned: trips.length,
  );
});

// ---------------------------------------------------------------------------
// History grouping: Country → Region → City → visited places
// ---------------------------------------------------------------------------

class CityHistory {
  const CityHistory({required this.key, required this.name, required this.destinationId, required this.places});
  final String key;
  final String name;
  final String? destinationId;
  final List<VisitedPlace> places;
}

class RegionHistory {
  const RegionHistory(this.name, this.cities);
  final String name;
  final List<CityHistory> cities;
  int get count => cities.fold(0, (s, c) => s + c.places.length);
}

class CountryHistory {
  const CountryHistory(this.country, this.regions);
  final Country? country;
  final List<RegionHistory> regions;
  int get count => regions.fold(0, (s, r) => s + r.count);
}

final travelHistoryProvider = Provider<List<CountryHistory>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const [];
  final visited = ref.watch(visitedPlacesProvider);
  final byCountry = groupBy(visited, (VisitedPlace v) => v.place.countryId);
  return [
    for (final ce in byCountry.entries)
      CountryHistory(
        catalog.country(ce.key),
        [
          for (final re in groupBy(ce.value, (VisitedPlace v) => catalog.regionName(v.place)).entries)
            RegionHistory(
              re.key.isEmpty ? 'Other' : re.key,
              [
                for (final de in groupBy(
                  re.value,
                  (VisitedPlace v) => v.place.destinationId ?? 'custom:${v.place.cityName}',
                ).entries)
                  CityHistory(
                    key: de.key,
                    name: catalog.cityName(de.value.first.place).isEmpty
                        ? 'Other'
                        : catalog.cityName(de.value.first.place),
                    destinationId: de.value.first.place.destinationId,
                    places: de.value,
                  ),
              ]..sort((a, b) => b.places.length.compareTo(a.places.length)),
            ),
        ]..sort((a, b) => b.count.compareTo(a.count)),
      ),
  ]..sort((a, b) => b.count.compareTo(a.count));
});

/// Visits grouped by month (newest first) for the timeline.
final timelineProvider = Provider<List<MapEntry<DateTime, List<VisitedPlace>>>>((ref) {
  final visited = ref.watch(visitedPlacesProvider);
  final grouped = groupBy(visited, (VisitedPlace v) => DateTime(v.visit.visitedOn.year, v.visit.visitedOn.month));
  return grouped.entries.toList()..sort((a, b) => b.key.compareTo(a.key));
});

// ---------------------------------------------------------------------------
// Achievements (computed, never stored)
// ---------------------------------------------------------------------------

final achievementsProvider = Provider<List<Achievement>>((ref) {
  final s = ref.watch(travelStatsProvider);
  int cat(List<PlaceCategory> cs) => cs.fold(0, (t, c) => t + (s.byCategory[c] ?? 0));
  Achievement a(String id, String t, String d, int p, int target) =>
      Achievement(id: id, title: t, description: d, progress: p, target: target);
  return [
    a('first', 'First Adventure', 'Mark your first place as visited', s.placesVisited, 1),
    a('ten', '10 Places Explored', 'Visit 10 places', s.placesVisited, 10),
    a('fifty', '50 Places Explored', 'Visit 50 places', s.placesVisited, 50),
    a('gems', 'Hidden Gem Hunter', 'Discover 5 hidden gems', s.hiddenGems, 5),
    a('food', 'Food Explorer', 'Visit 5 food spots or try 5 dishes', s.foodSpots + s.dishesTried, 5),
    a(
      'mountain',
      'Mountain Explorer',
      'Visit 5 mountain or hill-station places',
      cat([PlaceCategory.mountains, PlaceCategory.hillStations]),
      5,
    ),
    a('beach', 'Beach Lover', 'Visit 3 beaches', cat([PlaceCategory.beaches]), 3),
    a('waterfall', 'Waterfall Chaser', 'Visit 3 waterfalls', cat([PlaceCategory.waterfalls]), 3),
    a('heritage', 'History Buff', 'Visit 5 historical places', cat([PlaceCategory.historical]), 5),
    a('states', 'State Explorer', 'Visit places in 3 different states or regions', s.regions, 3),
    a('memories', 'Storyteller', 'Save 5 travel memories', s.memories, 5),
    a('photos', 'Shutterbug', 'Add 25 travel photos', s.photos, 25),
    a('planner', 'Trip Planner', 'Plan your first trip', s.tripsPlanned, 1),
    a('globe', 'Globetrotter', 'Visit places in 2 countries', s.countries, 2),
  ];
});

// ---------------------------------------------------------------------------
// Local, on-device notifications (generated from the user's own data)
// ---------------------------------------------------------------------------

class LocalNotice {
  const LocalNotice({required this.icon, required this.title, required this.body, this.route});
  final IconData icon;
  final String title;
  final String body;
  final String? route;
}

final noticesProvider = Provider<List<LocalNotice>>((ref) {
  final settings = ref.watch(settingsProvider);
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const [];
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final out = <LocalNotice>[];

  if (settings.tripReminders) {
    for (final t in ref.watch(tripsProvider)) {
      final days = DateTime(t.startDate.year, t.startDate.month, t.startDate.day).difference(today).inDays;
      if (days >= 0 && days <= 14) {
        out.add(
          LocalNotice(
            icon: Icons.luggage_rounded,
            title: days == 0 ? '${t.title} starts today' : '${t.title} in $days day${days == 1 ? '' : 's'}',
            body: '${t.completedActivities}/${t.totalActivities} planned activities ticked off.',
            route: '/trip/${t.id}',
          ),
        );
      }
    }
  }
  if (settings.seasonTips) {
    final bucketDest = ref
        .watch(bucketProvider)
        .map(
          (b) => b.subjectType == SubjectType.destination
              ? catalog.destination(b.subjectId)
              : catalog.destination(catalog.place(b.subjectId)?.destinationId),
        )
        .whereType<Destination>()
        .toSet();
    for (final d in bucketDest.where((d) => d.season.isGoodMonth(now.month))) {
      out.add(
        LocalNotice(
          icon: Icons.wb_sunny_rounded,
          title: 'Good season for ${d.name}',
          body: '${d.season.recommendedSeason} — ${d.season.summary}',
          route: '/destination/${d.id}',
        ),
      );
    }
  }
  return out;
});

/// Featured destinations for the selected country.
final countryDestinationsProvider = Provider<List<Destination>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const [];
  return catalog.destinationsIn(countryId: ref.watch(selectedCountryIdProvider));
});

/// Hidden gems in the selected country, preferring ones near recent destinations.
final featuredGemsProvider = Provider<List<Place>>((ref) {
  final catalog = ref.watch(catalogProvider).value;
  if (catalog == null) return const [];
  final countryId = ref.watch(selectedCountryIdProvider);
  final recent = ref.watch(settingsProvider).recentDestinationIds;
  final gems = catalog.placesIn(countryId: countryId, kind: PlaceKind.hiddenGem);
  int rank(Place p) {
    final i = recent.indexOf(p.destinationId ?? '');
    return i < 0 ? 100 : i;
  }

  return gems.sortedBy<num>(rank);
});

// ---------------------------------------------------------------------------
// Explorer level (home progress card)
// ---------------------------------------------------------------------------

class ExplorerLevel {
  const ExplorerLevel({
    required this.level,
    required this.title,
    required this.placesVisited,
    required this.floor,
    this.nextTarget,
    this.nextTitle,
  });

  final int level;
  final String title;
  final int placesVisited;

  /// Places needed for the current level.
  final int floor;

  /// Places needed for the next level; null at the top level.
  final int? nextTarget;
  final String? nextTitle;

  int get remaining => nextTarget == null ? 0 : nextTarget! - placesVisited;

  /// Progress from this level's floor to the next level, 0–1.
  double get progress =>
      nextTarget == null ? 1 : ((placesVisited - floor) / (nextTarget! - floor)).clamp(0, 1).toDouble();
}

const _levels = [
  (0, 'New Explorer'),
  (1, 'Wanderer'),
  (5, 'Adventurer'),
  (10, 'Trailblazer'),
  (25, 'Voyager'),
  (50, 'Globetrotter'),
];

final explorerLevelProvider = Provider<ExplorerLevel>((ref) {
  final visited = ref.watch(travelStatsProvider).placesVisited;
  var i = 0;
  while (i + 1 < _levels.length && visited >= _levels[i + 1].$1) {
    i++;
  }
  final next = i + 1 < _levels.length ? _levels[i + 1] : null;
  return ExplorerLevel(
    level: i + 1,
    title: _levels[i].$2,
    placesVisited: visited,
    floor: _levels[i].$1,
    nextTarget: next?.$1,
    nextTitle: next?.$2,
  );
});
