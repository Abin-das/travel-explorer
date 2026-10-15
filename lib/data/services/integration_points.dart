import '../../domain/entities/geography.dart';
import '../../domain/entities/season.dart';

/// Weather integration seam. The app currently ships [CuratedSeasonWeather],
/// which only returns the static, curated season guide. A live provider
/// (e.g. Open-Meteo) can implement [WeatherService] later.
abstract interface class WeatherService {
  bool get isLive;
  Future<SeasonGuide> seasonFor(Destination destination);
}

class CuratedSeasonWeather implements WeatherService {
  const CuratedSeasonWeather();

  @override
  bool get isLive => false;

  @override
  Future<SeasonGuide> seasonFor(Destination destination) async => destination.season;
}

/// Map tile source abstraction. OpenStreetMap needs no API key; Google Maps or
/// a commercial tile provider can be configured here later.
class MapTileConfig {
  const MapTileConfig({
    required this.urlTemplate,
    required this.attribution,
    this.subdomains = const [],
    this.maxZoom = 18,
  });

  /// Null disables the base map (markers still render) — used offline/in tests.
  final String? urlTemplate;
  final String attribution;
  final List<String> subdomains;
  final double maxZoom;

  static const none = MapTileConfig(urlTemplate: null, attribution: '');

  static const openStreetMap = MapTileConfig(
    urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
    attribution: '© OpenStreetMap contributors',
    maxZoom: 19,
  );
}
