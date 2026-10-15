import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../domain/entities/geography.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/season.dart';
import '../theme/app_colors.dart';

extension PlaceCategoryX on PlaceCategory {
  String get label => switch (this) {
    PlaceCategory.mountains => 'Mountains',
    PlaceCategory.beaches => 'Beaches',
    PlaceCategory.waterfalls => 'Waterfalls',
    PlaceCategory.forests => 'Forests',
    PlaceCategory.historical => 'Historical',
    PlaceCategory.temples => 'Temples',
    PlaceCategory.adventure => 'Adventure',
    PlaceCategory.wildlife => 'Wildlife',
    PlaceCategory.hillStations => 'Hill Stations',
    PlaceCategory.lakes => 'Lakes',
    PlaceCategory.viewpoints => 'Viewpoints',
    PlaceCategory.culture => 'Culture',
    PlaceCategory.food => 'Food',
  };

  IconData get icon => switch (this) {
    PlaceCategory.mountains => Icons.terrain_rounded,
    PlaceCategory.beaches => Icons.beach_access_rounded,
    PlaceCategory.waterfalls => Icons.water_rounded,
    PlaceCategory.forests => Icons.forest_rounded,
    PlaceCategory.historical => Icons.account_balance_rounded,
    PlaceCategory.temples => Icons.temple_hindu_rounded,
    PlaceCategory.adventure => Icons.hiking_rounded,
    PlaceCategory.wildlife => Icons.pets_rounded,
    PlaceCategory.hillStations => Icons.landscape_rounded,
    PlaceCategory.lakes => Icons.kayaking_rounded,
    PlaceCategory.viewpoints => Icons.visibility_rounded,
    PlaceCategory.culture => Icons.museum_rounded,
    PlaceCategory.food => Icons.restaurant_rounded,
  };

  bool get isNature => const {
    PlaceCategory.mountains,
    PlaceCategory.beaches,
    PlaceCategory.waterfalls,
    PlaceCategory.forests,
    PlaceCategory.wildlife,
    PlaceCategory.hillStations,
    PlaceCategory.lakes,
    PlaceCategory.viewpoints,
  }.contains(this);
}

/// Categories offered in "Explore by category" (Hidden Gems is a kind, handled separately).
const exploreCategories = [
  PlaceCategory.mountains,
  PlaceCategory.beaches,
  PlaceCategory.waterfalls,
  PlaceCategory.forests,
  PlaceCategory.historical,
  PlaceCategory.temples,
  PlaceCategory.adventure,
  PlaceCategory.wildlife,
  PlaceCategory.hillStations,
  PlaceCategory.lakes,
];

extension FoodCategoryX on FoodCategory {
  String get label => switch (this) {
    FoodCategory.localCuisine => 'Local Cuisine',
    FoodCategory.streetFood => 'Street Food',
    FoodCategory.restaurant => 'Restaurants',
    FoodCategory.cafe => 'Cafés',
    FoodCategory.traditional => 'Traditional',
    FoodCategory.desserts => 'Desserts',
    FoodCategory.breakfast => 'Breakfast',
    FoodCategory.budget => 'Budget-Friendly',
    FoodCategory.mustTry => 'Must-Try',
  };

  IconData get icon => switch (this) {
    FoodCategory.localCuisine => Icons.rice_bowl_rounded,
    FoodCategory.streetFood => Icons.storefront_rounded,
    FoodCategory.restaurant => Icons.restaurant_rounded,
    FoodCategory.cafe => Icons.local_cafe_rounded,
    FoodCategory.traditional => Icons.soup_kitchen_rounded,
    FoodCategory.desserts => Icons.icecream_rounded,
    FoodCategory.breakfast => Icons.free_breakfast_rounded,
    FoodCategory.budget => Icons.savings_rounded,
    FoodCategory.mustTry => Icons.star_rounded,
  };
}

extension PlaceKindX on PlaceKind {
  String get label => switch (this) {
    PlaceKind.attraction => 'Tourist Attraction',
    PlaceKind.hiddenGem => 'Hidden Gem',
    PlaceKind.foodSpot => 'Food Spot',
  };

  Color get color => switch (this) {
    PlaceKind.attraction => AppColors.attraction,
    PlaceKind.hiddenGem => AppColors.hiddenGem,
    PlaceKind.foodSpot => AppColors.foodSpot,
  };

  IconData get icon => switch (this) {
    PlaceKind.attraction => Icons.place_rounded,
    PlaceKind.hiddenGem => Icons.diamond_rounded,
    PlaceKind.foodSpot => Icons.restaurant_rounded,
  };
}

extension EntryTypeX on EntryType {
  String get label => switch (this) {
    EntryType.free => 'Free entry',
    EntryType.paid => 'Ticketed entry',
    EntryType.unknown => 'Entry: check locally',
  };
}

extension SeasonFitX on SeasonFit {
  Color get color => switch (this) {
    SeasonFit.best => AppColors.visited,
    SeasonFit.good => AppColors.oceanBlue,
    SeasonFit.fair => AppColors.bucket,
    SeasonFit.avoid => AppColors.danger,
  };
  String get label => switch (this) {
    SeasonFit.best => 'Best',
    SeasonFit.good => 'Good',
    SeasonFit.fair => 'Fair',
    SeasonFit.avoid => 'Avoid',
  };
}

SceneTheme sceneForPlace(Place p) {
  if (p.isFood) return SceneTheme.food;
  final c = p.categories.toSet();
  if (c.contains(PlaceCategory.waterfalls)) return SceneTheme.waterfall;
  if (c.contains(PlaceCategory.beaches)) return SceneTheme.beach;
  if (c.contains(PlaceCategory.temples)) return SceneTheme.temple;
  if (c.contains(PlaceCategory.lakes)) return SceneTheme.lake;
  if (c.contains(PlaceCategory.historical)) return SceneTheme.heritage;
  if (c.contains(PlaceCategory.wildlife)) return SceneTheme.wildlife;
  if (c.contains(PlaceCategory.forests)) return SceneTheme.forest;
  if (c.contains(PlaceCategory.culture)) return SceneTheme.city;
  return SceneTheme.mountains;
}

SceneTheme sceneForCategory(PlaceCategory c) => switch (c) {
  PlaceCategory.mountains || PlaceCategory.hillStations || PlaceCategory.viewpoints => SceneTheme.mountains,
  PlaceCategory.beaches => SceneTheme.beach,
  PlaceCategory.waterfalls => SceneTheme.waterfall,
  PlaceCategory.forests || PlaceCategory.adventure => SceneTheme.forest,
  PlaceCategory.historical => SceneTheme.heritage,
  PlaceCategory.temples => SceneTheme.temple,
  PlaceCategory.wildlife => SceneTheme.wildlife,
  PlaceCategory.lakes => SceneTheme.lake,
  PlaceCategory.culture => SceneTheme.city,
  PlaceCategory.food => SceneTheme.food,
};

const _monthShort = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
String monthShort(int m) => _monthShort[(m - 1) % 12];

/// [1,2,3,10,11,12] → "Oct – Mar"
String monthRange(List<int> months) {
  if (months.isEmpty) return '—';
  final set = months.toSet();
  // Find a start month whose predecessor is not in the set.
  final start = months.firstWhere((m) => !set.contains(m == 1 ? 12 : m - 1), orElse: () => months.first);
  var end = start;
  while (set.contains(end % 12 + 1) && end % 12 + 1 != start) {
    end = end % 12 + 1;
  }
  if (set.length == 12) return 'Year-round';
  final contiguous = set.length == ((end - start + 12) % 12) + 1;
  if (!contiguous) return (months.toList()..sort()).map(monthShort).join(', ');
  return start == end ? monthShort(start) : '${monthShort(start)} – ${monthShort(end)}';
}

String formatDate(DateTime d) => DateFormat('d MMMM yyyy').format(d);
String formatShortDate(DateTime d) => DateFormat('d MMM yyyy').format(d);
String formatMonthYear(DateTime d) => DateFormat('MMMM yyyy').format(d);
String formatDayMonth(DateTime d) => DateFormat('EEE, d MMM').format(d);

String greetingFor(DateTime now) {
  final h = now.hour;
  if (h < 5) return 'Good Evening';
  if (h < 12) return 'Good Morning';
  if (h < 17) return 'Good Afternoon';
  return 'Good Evening';
}

String plural(int n, String one, [String? many]) => '$n ${n == 1 ? one : (many ?? '${one}s')}';
