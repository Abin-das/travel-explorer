import 'dart:math' as math;

import 'package:collection/collection.dart';

import '../domain/entities/common.dart';
import '../domain/entities/geography.dart';
import '../domain/entities/place.dart';
import '../domain/repositories/repositories.dart';

/// Indexed, read-only view over catalog data plus the user's own submissions.
class Catalog {
  Catalog(CatalogData data, List<Place> userPlaces)
    : countries = data.countries,
      regions = data.regions,
      destinations = data.destinations,
      dishes = data.dishes,
      places = [...data.places, ...userPlaces] {
    _countries = {for (final c in countries) c.id: c};
    _regions = {for (final r in regions) r.id: r};
    _destinations = {for (final d in destinations) d.id: d};
    _places = {for (final p in places) p.id: p};
    _dishes = {for (final d in dishes) d.id: d};
    _byDestination = groupBy(places.where((p) => p.destinationId != null), (Place p) => p.destinationId!);
  }

  final List<Country> countries;
  final List<Region> regions;
  final List<Destination> destinations;
  final List<Place> places;
  final List<LocalDish> dishes;

  late final Map<String, Country> _countries;
  late final Map<String, Region> _regions;
  late final Map<String, Destination> _destinations;
  late final Map<String, Place> _places;
  late final Map<String, LocalDish> _dishes;
  late final Map<String, List<Place>> _byDestination;

  Country? country(String? id) => _countries[id];
  Region? region(String? id) => _regions[id];
  Destination? destination(String? id) => _destinations[id];
  Place? place(String? id) => _places[id];
  LocalDish? dish(String? id) => _dishes[id];

  bool hasCuratedData(String countryId) => destinations.any((d) => d.countryId == countryId);

  List<Region> regionsOf(String countryId) => regions.where((r) => r.countryId == countryId).toList();

  List<Destination> destinationsIn({String? countryId, String? regionId}) => destinations
      .where((d) => (countryId == null || d.countryId == countryId) && (regionId == null || d.regionId == regionId))
      .sortedBy<num>((d) => -d.popularity);

  List<Place> placesAt(String destinationId, {PlaceKind? kind}) =>
      (_byDestination[destinationId] ?? const []).where((p) => kind == null || p.kind == kind).toList();

  List<Place> placesIn({String? countryId, String? regionId, PlaceKind? kind}) => places
      .where(
        (p) =>
            (countryId == null || p.countryId == countryId) &&
            (regionId == null || p.regionId == regionId) &&
            (kind == null || p.kind == kind),
      )
      .toList();

  int sightCount(String destinationId) => placesAt(destinationId).where((p) => !p.isFood).length;

  List<LocalDish> dishesIn({String? countryId, String? regionId}) => dishes
      .where((d) => (countryId == null || d.countryId == countryId) && (regionId == null || d.regionId == regionId))
      .toList();

  String regionName(Place p) => region(p.regionId)?.name ?? p.regionName ?? '';
  String cityName(Place p) => destination(p.destinationId)?.name ?? p.cityName ?? '';

  /// "Munnar, Kerala"
  String placeLocation(Place p) => [cityName(p), regionName(p)].where((s) => s.isNotEmpty).join(', ');

  /// "Kerala, India"
  String destinationLocation(Destination d) =>
      [region(d.regionId)?.name, country(d.countryId)?.name].whereType<String>().join(', ');

  /// Distance in km from the destination centre, when the place belongs to a
  /// catalog destination with known coordinates.
  double? distanceFromCentre(Place p) {
    final d = destination(p.destinationId);
    if (d == null) return null;
    return haversineKm(d.center, p.location);
  }

  List<SearchHit> search(String query, {String? countryId}) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return const [];
    bool m(String? s) => s != null && s.toLowerCase().contains(q);
    final hits = <SearchHit>[];
    for (final r in regions) {
      if ((countryId == null || r.countryId == countryId) && m(r.name)) {
        hits.add(SearchHit.region(r, country(r.countryId)?.name ?? ''));
      }
    }
    for (final d in destinations) {
      if ((countryId == null || d.countryId == countryId) && (m(d.name) || m(d.district) || m(d.tagline))) {
        hits.add(SearchHit.destination(d, destinationLocation(d)));
      }
    }
    for (final p in places) {
      if (countryId != null && p.countryId != countryId) continue;
      if (m(p.name) || m(p.locality) || p.famousDishes.any(m) || m(cityName(p))) {
        hits.add(SearchHit.place(p, placeLocation(p)));
      }
    }
    for (final d in dishes) {
      if ((countryId == null || d.countryId == countryId) && m(d.name)) {
        hits.add(SearchHit.dish(d, region(d.regionId)?.name ?? ''));
      }
    }
    int rank(SearchHit h) => h.title.toLowerCase().startsWith(q) ? 0 : 1;
    return hits.sortedBy<num>(rank);
  }
}

enum SearchHitType { region, destination, place, dish }

class SearchHit {
  const SearchHit._(this.type, this.id, this.title, this.subtitle, {this.place});
  factory SearchHit.region(Region r, String c) => SearchHit._(SearchHitType.region, r.id, r.name, '${r.kind} · $c');
  factory SearchHit.destination(Destination d, String loc) => SearchHit._(SearchHitType.destination, d.id, d.name, loc);
  factory SearchHit.place(Place p, String loc) => SearchHit._(SearchHitType.place, p.id, p.name, loc, place: p);
  factory SearchHit.dish(LocalDish d, String r) => SearchHit._(SearchHitType.dish, d.id, d.name, 'Dish · $r');

  final SearchHitType type;
  final String id;
  final String title;
  final String subtitle;
  final Place? place;
}

double haversineKm(GeoPoint a, GeoPoint b) {
  const r = 6371.0;
  double rad(double d) => d * math.pi / 180;
  final dLat = rad(b.lat - a.lat);
  final dLng = rad(b.lng - a.lng);
  final h =
      math.sin(dLat / 2) * math.sin(dLat / 2) +
      math.cos(rad(a.lat)) * math.cos(rad(b.lat)) * math.sin(dLng / 2) * math.sin(dLng / 2);
  return 2 * r * math.asin(math.sqrt(h));
}
