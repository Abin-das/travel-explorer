import '../entities/common.dart';
import '../entities/geography.dart';
import '../entities/place.dart';

/// Read-only shared travel content. The bundled implementation is
/// `BundledCatalogRepository`; a REST/Supabase implementation can replace it
/// without touching the UI.
abstract interface class CatalogRepository {
  Future<CatalogData> load();
}

class CatalogData {
  const CatalogData({
    required this.countries,
    required this.regions,
    required this.destinations,
    required this.places,
    required this.dishes,
  });

  final List<Country> countries;
  final List<Region> regions;
  final List<Destination> destinations;
  final List<Place> places;
  final List<LocalDish> dishes;
}

/// Generic local persistence for a collection of user-owned entities.
abstract interface class EntityStore<T extends Identifiable> {
  List<T> readAll();
  Future<void> upsert(T item);
  Future<void> upsertAll(Iterable<T> items);
  Future<void> remove(String id);
  Future<void> clear();
}

/// Single-object persistence (settings, profile).
abstract interface class ValueStore<T> {
  T read();
  Future<void> write(T value);
  Future<void> clear();
}
