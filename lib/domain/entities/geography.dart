import 'common.dart';
import 'media.dart';
import 'season.dart';

/// Top of the hierarchy: Country → Region → Destination (city/town) → Place.
class Country {
  const Country({
    required this.id,
    required this.name,
    required this.flag,
    required this.tagline,
    this.regionLabel = 'State',
    this.center = const GeoPoint(20, 0),
  });

  final String id;
  final String name;
  final String flag;
  final String tagline;

  /// What a first-level subdivision is called ("State", "Prefecture", …).
  final String regionLabel;
  final GeoPoint center;
}

/// A state, province, union territory or prefecture.
class Region {
  const Region({
    required this.id,
    required this.countryId,
    required this.name,
    required this.tagline,
    this.kind = 'State',
    this.highlights = const [],
  });

  final String id;
  final String countryId;
  final String name;
  final String tagline;
  final String kind;
  final List<String> highlights;
}

/// The city / town / area level that travellers think of as "a destination",
/// e.g. Munnar or Wayanad. This is the "City" level of the hierarchy.
class Destination {
  const Destination({
    required this.id,
    required this.countryId,
    required this.regionId,
    required this.name,
    required this.tagline,
    required this.intro,
    required this.center,
    required this.theme,
    required this.season,
    required this.recommendedDuration,
    required this.climate,
    this.district,
    this.activities = const [],
    this.popularity = 50,
    this.trending = false,
    this.imageUrl,
    this.photo,
    this.about,
  });

  final String id;
  final String countryId;
  final String regionId;
  final String name;
  final String? district;
  final String tagline;
  final String intro;
  final GeoPoint center;

  /// Dominant landscape, used for the cover illustration.
  final SceneTheme theme;
  final SeasonGuide season;
  final String recommendedDuration;
  final String climate;
  final List<String> activities;

  /// Curated 0–100 estimate used for ordering only. Not a rating.
  final int popularity;
  final bool trending;
  final String? imageUrl;
  final RemotePhoto? photo;
  final SourcedText? about;

  Destination withMedia(RemotePhoto? photo, SourcedText? about) => Destination(
    id: id,
    countryId: countryId,
    regionId: regionId,
    name: name,
    tagline: tagline,
    intro: intro,
    center: center,
    theme: theme,
    season: season,
    recommendedDuration: recommendedDuration,
    climate: climate,
    district: district,
    activities: activities,
    popularity: popularity,
    trending: trending,
    imageUrl: imageUrl,
    photo: photo,
    about: about,
  );
}

/// The illustration style used when no photo is available.
enum SceneTheme { mountains, beach, waterfall, forest, heritage, temple, lake, desert, snow, city, food, wildlife }
