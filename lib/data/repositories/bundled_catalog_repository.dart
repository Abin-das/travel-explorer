import '../../domain/repositories/repositories.dart';
import '../mock/dishes.dart';
import '../mock/geo_data.dart';
import '../mock/places_kerala.dart';
import '../mock/places_north.dart';
import '../mock/places_south.dart';
import '../mock/wiki_media.dart';

/// Serves the curated sample catalog bundled with the app.
///
/// To connect a backend, implement [CatalogRepository] with REST/Supabase calls
/// and override `catalogRepositoryProvider` — nothing in the UI changes.
class BundledCatalogRepository implements CatalogRepository {
  const BundledCatalogRepository({this.simulatedLatency = const Duration(milliseconds: 450)});

  final Duration simulatedLatency;

  @override
  Future<CatalogData> load() async {
    // A short delay keeps loading/skeleton states honest during development.
    await Future<void>.delayed(simulatedLatency);
    return CatalogData(
      countries: countries,
      regions: regions,
      destinations: [for (final d in destinations) d.withMedia(wikiMedia[d.id]?.photo, wikiMedia[d.id]?.about)],
      places: [
        for (final p in [...keralaPlaces, ...southPlaces, ...northAndWorldPlaces])
          p.withMedia(wikiMedia[p.id]?.photo, wikiMedia[p.id]?.about),
      ],
      dishes: dishes,
    );
  }
}
