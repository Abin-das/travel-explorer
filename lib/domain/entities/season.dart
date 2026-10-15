/// Curated seasonal guidance. This is static reference information, NOT a
/// weather forecast — see `WeatherService` for the live-data integration point.
enum SeasonFit { best, good, fair, avoid }

class SeasonCard {
  const SeasonCard({
    required this.name,
    required this.months,
    required this.weather,
    required this.bestFor,
    required this.fit,
    this.activities = const [],
  });

  final String name;
  final String months;
  final String weather;
  final String bestFor;
  final SeasonFit fit;
  final List<String> activities;
}

class SeasonGuide {
  const SeasonGuide({
    required this.bestMonths,
    required this.recommendedSeason,
    required this.summary,
    this.peakMonths = const [],
    this.rainyMonths = const [],
    this.offMonths = const [],
    this.cards = const [],
  });

  /// 1 = January … 12 = December.
  final List<int> bestMonths;
  final String recommendedSeason;
  final String summary;
  final List<int> peakMonths;
  final List<int> rainyMonths;
  final List<int> offMonths;
  final List<SeasonCard> cards;

  bool isGoodMonth(int month) => bestMonths.contains(month);
}
