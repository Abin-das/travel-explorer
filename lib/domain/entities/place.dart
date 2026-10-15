import 'common.dart';
import 'media.dart';

/// What kind of place this is. Hidden gems and food spots share one model
/// with attractions so they can live in the same lists, maps and trips.
enum PlaceKind { attraction, hiddenGem, foodSpot }

/// Landscape / interest tags used for "Explore by category" and filters.
enum PlaceCategory {
  mountains,
  beaches,
  waterfalls,
  forests,
  historical,
  temples,
  adventure,
  wildlife,
  hillStations,
  lakes,
  viewpoints,
  culture,
  food,
}

enum FoodCategory { localCuisine, streetFood, restaurant, cafe, traditional, desserts, breakfast, budget, mustTry }

enum EntryType { free, paid, unknown }

/// Moderation state for user-submitted places. Nothing user-submitted is ever
/// shown to other users until a backend approves it.
enum SubmissionStatus { localOnly, pendingReview, approved, rejected }

class Submission {
  const Submission({required this.status, required this.createdAt, required this.updatedAt, this.authorId});

  final SubmissionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? authorId;

  Json toJson() => {
    'status': status.name,
    'createdAt': dateToJson(createdAt),
    'updatedAt': dateToJson(updatedAt),
    'authorId': authorId,
  };

  factory Submission.fromJson(Json j) => Submission(
    status: enumByName(SubmissionStatus.values, j['status'], SubmissionStatus.localOnly),
    createdAt: parseDate(j['createdAt']) ?? DateTime.now(),
    updatedAt: parseDate(j['updatedAt']) ?? DateTime.now(),
    authorId: j['authorId'] as String?,
  );
}

/// Shared destination data: an attraction, hidden gem or food spot.
/// Personal activity (visits, notes, photos) lives in separate entities.
class Place implements Identifiable {
  const Place({
    required this.id,
    required this.kind,
    required this.countryId,
    required this.name,
    required this.description,
    required this.location,
    this.regionId,
    this.regionName,
    this.destinationId,
    this.cityName,
    this.locality,
    this.categories = const [],
    this.foodCategories = const [],
    this.popularity = 50,
    this.bestTime,
    this.visitDuration,
    this.visitingHours,
    this.entry = EntryType.unknown,
    this.entryNote,
    this.tips = const [],
    this.thingsToDo = const [],
    this.accessibility,
    this.familyFriendly = false,
    this.famousDishes = const [],
    this.priceRange,
    this.address,
    this.imageUrls = const [],
    this.source = DataSource.curatedSample,
    this.submission,
    this.photo,
    this.about,
  });

  @override
  final String id;
  final PlaceKind kind;
  final String countryId;
  final String? regionId;

  /// Free-text region, used by user submissions outside the catalog.
  final String? regionName;
  final String? destinationId;

  /// Free-text city, used by user submissions outside the catalog.
  final String? cityName;

  /// Precise administrative location, e.g. "Varkala, Thiruvananthapuram district".
  final String? locality;
  final String name;
  final String description;
  final GeoPoint location;
  final List<PlaceCategory> categories;
  final List<FoodCategory> foodCategories;

  /// Curated 0–100 estimate used for ordering only. Not a user rating.
  final int popularity;
  final String? bestTime;
  final String? visitDuration;

  /// Indicative only — always shown with a "verify locally" hint.
  final String? visitingHours;
  final EntryType entry;
  final String? entryNote;
  final List<String> tips;
  final List<String> thingsToDo;
  final String? accessibility;
  final bool familyFriendly;
  final List<String> famousDishes;
  final String? priceRange;
  final String? address;
  final List<String> imageUrls;
  final DataSource source;
  final Submission? submission;

  /// Freely licensed photo with attribution (catalog content).
  final RemotePhoto? photo;

  /// Sourced description and history (catalog content).
  final SourcedText? about;

  bool get isFood => kind == PlaceKind.foodSpot;
  bool get isHiddenGem => kind == PlaceKind.hiddenGem;
  bool get isUserSubmitted => source == DataSource.userSubmitted;

  Place copyWith({Submission? submission}) => Place.fromJson({...toJson(), 'submission': submission?.toJson()});

  /// Attaches catalog media. Media is not part of [toJson] (user places use
  /// [imageUrls]; catalog media ships with the app or comes from the backend).
  Place withMedia(RemotePhoto? photo, SourcedText? about) {
    final p = Place.fromJson(toJson());
    return Place(
      id: p.id,
      kind: p.kind,
      countryId: p.countryId,
      regionId: p.regionId,
      regionName: p.regionName,
      destinationId: p.destinationId,
      cityName: p.cityName,
      locality: p.locality,
      name: p.name,
      description: p.description,
      location: p.location,
      categories: p.categories,
      foodCategories: p.foodCategories,
      popularity: p.popularity,
      bestTime: p.bestTime,
      visitDuration: p.visitDuration,
      visitingHours: p.visitingHours,
      entry: p.entry,
      entryNote: p.entryNote,
      tips: p.tips,
      thingsToDo: p.thingsToDo,
      accessibility: p.accessibility,
      familyFriendly: p.familyFriendly,
      famousDishes: p.famousDishes,
      priceRange: p.priceRange,
      address: p.address,
      imageUrls: p.imageUrls,
      source: source,
      submission: p.submission,
      photo: photo,
      about: about,
    );
  }

  @override
  Json toJson() => {
    'id': id,
    'kind': kind.name,
    'countryId': countryId,
    'regionId': regionId,
    'regionName': regionName,
    'destinationId': destinationId,
    'cityName': cityName,
    'locality': locality,
    'name': name,
    'description': description,
    'location': location.toJson(),
    'categories': categories.map((e) => e.name).toList(),
    'foodCategories': foodCategories.map((e) => e.name).toList(),
    'popularity': popularity,
    'bestTime': bestTime,
    'visitDuration': visitDuration,
    'visitingHours': visitingHours,
    'entry': entry.name,
    'entryNote': entryNote,
    'tips': tips,
    'thingsToDo': thingsToDo,
    'accessibility': accessibility,
    'familyFriendly': familyFriendly,
    'famousDishes': famousDishes,
    'priceRange': priceRange,
    'address': address,
    'imageUrls': imageUrls,
    'source': source.name,
    'submission': submission?.toJson(),
  };

  factory Place.fromJson(Json j) => Place(
    id: j['id'] as String,
    kind: enumByName(PlaceKind.values, j['kind'], PlaceKind.attraction),
    countryId: j['countryId'] as String,
    regionId: j['regionId'] as String?,
    regionName: j['regionName'] as String?,
    destinationId: j['destinationId'] as String?,
    cityName: j['cityName'] as String?,
    locality: j['locality'] as String?,
    name: j['name'] as String,
    description: j['description'] as String? ?? '',
    location: GeoPoint.fromJson((j['location'] as Map).cast<String, dynamic>()),
    categories: stringList(j['categories'])
        .map((e) => enumByName(PlaceCategory.values, e, PlaceCategory.viewpoints))
        .toList(),
    foodCategories: stringList(j['foodCategories'])
        .map((e) => enumByName(FoodCategory.values, e, FoodCategory.localCuisine))
        .toList(),
    popularity: (j['popularity'] as num?)?.toInt() ?? 0,
    bestTime: j['bestTime'] as String?,
    visitDuration: j['visitDuration'] as String?,
    visitingHours: j['visitingHours'] as String?,
    entry: enumByName(EntryType.values, j['entry'], EntryType.unknown),
    entryNote: j['entryNote'] as String?,
    tips: stringList(j['tips']),
    thingsToDo: stringList(j['thingsToDo']),
    accessibility: j['accessibility'] as String?,
    familyFriendly: j['familyFriendly'] as bool? ?? false,
    famousDishes: stringList(j['famousDishes']),
    priceRange: j['priceRange'] as String?,
    address: j['address'] as String?,
    imageUrls: stringList(j['imageUrls']),
    source: enumByName(DataSource.values, j['source'], DataSource.userSubmitted),
    submission: j['submission'] is Map ? Submission.fromJson((j['submission'] as Map).cast<String, dynamic>()) : null,
  );
}

/// A regional dish that can go on the "Foods I want to try" list.
class LocalDish {
  const LocalDish({
    required this.id,
    required this.name,
    required this.countryId,
    required this.regionId,
    required this.description,
    this.vegetarian,
  });

  final String id;
  final String name;
  final String countryId;
  final String regionId;
  final String description;
  final bool? vegetarian;
}
