import '../../domain/entities/common.dart';
import '../../domain/entities/geography.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/season.dart';

/// Helpers that keep the sample catalog files compact. Every place built here
/// is tagged [DataSource.curatedSample].
Place place(
  Destination d,
  PlaceKind kind,
  String slug,
  String name,
  double lat,
  double lng, {
  required String desc,
  List<PlaceCategory> cats = const [],
  List<FoodCategory> food = const [],
  int pop = 50,
  String? best,
  String? duration,
  String? hours,
  EntryType entry = EntryType.unknown,
  String? entryNote,
  List<String> tips = const [],
  List<String> todo = const [],
  String? access,
  bool family = false,
  List<String> dishes = const [],
  String? price,
  String? locality,
  String? address,
}) {
  return Place(
    id: '${d.id}.$slug',
    kind: kind,
    countryId: d.countryId,
    regionId: d.regionId,
    destinationId: d.id,
    name: name,
    description: desc,
    location: GeoPoint(lat, lng),
    categories: cats,
    foodCategories: food,
    popularity: pop,
    bestTime: best,
    visitDuration: duration,
    visitingHours: hours,
    entry: entry,
    entryNote: entryNote,
    tips: tips,
    thingsToDo: todo,
    accessibility: access,
    familyFriendly: family,
    famousDishes: dishes,
    priceRange: price,
    locality: locality,
    address: address,
  );
}

const _fee = 'Fees change often — check at the venue or official site.';

Place sight(
  Destination d,
  String slug,
  String name,
  double lat,
  double lng, {
  required String desc,
  List<PlaceCategory> cats = const [],
  int pop = 60,
  String? best,
  String? duration,
  String? hours,
  EntryType entry = EntryType.unknown,
  List<String> tips = const [],
  List<String> todo = const [],
  String? access,
  bool family = true,
  String? locality,
}) => place(
  d,
  PlaceKind.attraction,
  slug,
  name,
  lat,
  lng,
  desc: desc,
  cats: cats,
  pop: pop,
  best: best,
  duration: duration,
  hours: hours,
  entry: entry,
  entryNote: entry == EntryType.paid ? _fee : null,
  tips: tips,
  todo: todo,
  access: access,
  family: family,
  locality: locality,
);

Place gem(
  Destination d,
  String slug,
  String name,
  double lat,
  double lng, {
  required String desc,
  List<PlaceCategory> cats = const [],
  String? best,
  String? duration,
  EntryType entry = EntryType.unknown,
  List<String> tips = const [],
  List<String> todo = const [],
  required String access,
  bool family = false,
  String? locality,
}) => place(
  d,
  PlaceKind.hiddenGem,
  slug,
  name,
  lat,
  lng,
  desc: desc,
  cats: cats,
  pop: 25,
  best: best,
  duration: duration,
  entry: entry,
  entryNote: entry == EntryType.paid ? _fee : null,
  tips: tips,
  todo: todo,
  access: access,
  family: family,
  locality: locality,
);

Place eat(
  Destination d,
  String slug,
  String name,
  double lat,
  double lng, {
  required String desc,
  required List<FoodCategory> food,
  required List<String> dishes,
  String? price,
  String? best,
  String? address,
  int pop = 55,
  List<String> tips = const [],
}) => place(
  d,
  PlaceKind.foodSpot,
  slug,
  name,
  lat,
  lng,
  desc: desc,
  cats: const [PlaceCategory.food],
  food: food,
  dishes: dishes,
  price: price,
  best: best,
  address: address,
  pop: pop,
  family: true,
  tips: tips,
);

List<int> months(int from, int to) {
  final out = <int>[];
  var m = from;
  while (true) {
    out.add(m);
    if (m == to) break;
    m = m % 12 + 1;
  }
  return out;
}

// ---------------------------------------------------------------------------
// Season presets (curated, general guidance — not forecasts)
// ---------------------------------------------------------------------------

SeasonGuide hillStationSouth({String? summary}) => SeasonGuide(
  bestMonths: months(9, 3),
  recommendedSeason: 'Winter',
  summary: summary ?? 'Cool, clear days from September to March make it ideal for sightseeing and treks.',
  peakMonths: months(12, 1) + [5],
  rainyMonths: months(6, 8),
  offMonths: months(6, 8),
  cards: const [
    SeasonCard(
      name: 'Winter',
      months: 'Oct – Feb',
      weather: 'Cool and crisp; misty mornings, chilly nights.',
      bestFor: 'Best for sightseeing',
      fit: SeasonFit.best,
      activities: ['Viewpoints', 'Tea estate walks', 'Treks'],
    ),
    SeasonCard(
      name: 'Summer',
      months: 'Mar – May',
      weather: 'Pleasant days, a welcome escape from the plains.',
      bestFor: 'Best for outdoor activities',
      fit: SeasonFit.good,
      activities: ['Boating', 'Camping', 'Family trips'],
    ),
    SeasonCard(
      name: 'Monsoon',
      months: 'Jun – Sep',
      weather: 'Heavy rain, fog and occasional landslides.',
      bestFor: 'Best for green landscapes',
      fit: SeasonFit.fair,
      activities: ['Waterfalls', 'Monsoon photography'],
    ),
  ],
);

SeasonGuide tropicalCoast({String? summary}) => SeasonGuide(
  bestMonths: months(10, 3),
  recommendedSeason: 'Winter',
  summary: summary ?? 'October to March brings calmer seas, lower humidity and the best beach weather.',
  peakMonths: months(12, 1),
  rainyMonths: months(6, 9),
  offMonths: months(5, 8),
  cards: const [
    SeasonCard(
      name: 'Winter',
      months: 'Nov – Feb',
      weather: 'Warm days, lighter humidity, calm seas.',
      bestFor: 'Best for beaches & sightseeing',
      fit: SeasonFit.best,
      activities: ['Beaches', 'Backwaters', 'Heritage walks'],
    ),
    SeasonCard(
      name: 'Summer',
      months: 'Mar – May',
      weather: 'Hot and humid; afternoons can be draining.',
      bestFor: 'Best for early-morning outings',
      fit: SeasonFit.fair,
      activities: ['Sunrise walks', 'Indoor museums'],
    ),
    SeasonCard(
      name: 'Monsoon',
      months: 'Jun – Sep',
      weather: 'Heavy rain and rough seas; swimming often unsafe.',
      bestFor: 'Best for Ayurveda & green landscapes',
      fit: SeasonFit.fair,
      activities: ['Ayurveda', 'Monsoon drives'],
    ),
  ],
);

SeasonGuide eastCoast() => SeasonGuide(
  bestMonths: months(11, 2),
  recommendedSeason: 'Winter',
  summary: 'November to February is pleasant; the north-east monsoon brings rain from October to December.',
  peakMonths: months(12, 1),
  rainyMonths: months(10, 12),
  offMonths: months(4, 6),
  cards: const [
    SeasonCard(
      name: 'Winter',
      months: 'Dec – Feb',
      weather: 'Warm and breezy, comfortable for walking.',
      bestFor: 'Best for sightseeing',
      fit: SeasonFit.best,
      activities: ['Temple visits', 'Beach walks', 'Heritage sites'],
    ),
    SeasonCard(
      name: 'Summer',
      months: 'Mar – Jun',
      weather: 'Very hot and humid.',
      bestFor: 'Visit early mornings only',
      fit: SeasonFit.avoid,
      activities: ['Sunrise visits'],
    ),
    SeasonCard(
      name: 'NE Monsoon',
      months: 'Oct – Dec',
      weather: 'Spells of heavy rain and possible cyclones.',
      bestFor: 'Best for quieter trips',
      fit: SeasonFit.fair,
      activities: ['Museums', 'Local food'],
    ),
  ],
);

SeasonGuide plainsHeritage({String? summary, String monsoon = 'Lush and dramatic, with occasional downpours.'}) =>
    SeasonGuide(
      bestMonths: months(10, 3),
      recommendedSeason: 'Winter',
      summary: summary ?? 'October to March offers mild days — perfect for forts, palaces and markets.',
      peakMonths: months(12, 1),
      rainyMonths: months(7, 9),
      offMonths: months(4, 6),
      cards: [
        const SeasonCard(
          name: 'Winter',
          months: 'Oct – Mar',
          weather: 'Sunny, mild days and cool nights.',
          bestFor: 'Best for sightseeing',
          fit: SeasonFit.best,
          activities: ['Forts & palaces', 'Markets', 'Festivals'],
        ),
        const SeasonCard(
          name: 'Summer',
          months: 'Apr – Jun',
          weather: 'Very hot; midday sightseeing is tiring.',
          bestFor: 'Lower prices, fewer crowds',
          fit: SeasonFit.avoid,
          activities: ['Early mornings', 'Museums'],
        ),
        SeasonCard(
          name: 'Monsoon',
          months: 'Jul – Sep',
          weather: monsoon,
          bestFor: 'Best for green landscapes',
          fit: SeasonFit.good,
          activities: const ['Lakes', 'Photography'],
        ),
      ],
    );

SeasonGuide himalaya({required List<int> best, required String summary, String recommended = 'Summer'}) => SeasonGuide(
  bestMonths: best,
  recommendedSeason: recommended,
  summary: summary,
  peakMonths: months(5, 6),
  rainyMonths: months(7, 8),
  offMonths: months(1, 2),
  cards: const [
    SeasonCard(
      name: 'Summer',
      months: 'Apr – Jun',
      weather: 'Pleasant days, cool evenings, open passes.',
      bestFor: 'Best for outdoor activities',
      fit: SeasonFit.best,
      activities: ['Treks', 'Paragliding', 'Road trips'],
    ),
    SeasonCard(
      name: 'Monsoon',
      months: 'Jul – Aug',
      weather: 'Rain and landslide risk on mountain roads.',
      bestFor: 'Only for flexible travellers',
      fit: SeasonFit.fair,
      activities: ['Cafés', 'Short walks'],
    ),
    SeasonCard(
      name: 'Autumn',
      months: 'Sep – Nov',
      weather: 'Clear skies and sharp mountain views.',
      bestFor: 'Best for photography',
      fit: SeasonFit.best,
      activities: ['Viewpoints', 'Camping'],
    ),
    SeasonCard(
      name: 'Winter',
      months: 'Dec – Feb',
      weather: 'Freezing; snowfall can close roads.',
      bestFor: 'Best for snow',
      fit: SeasonFit.good,
      activities: ['Snow play', 'Skiing'],
    ),
  ],
);
