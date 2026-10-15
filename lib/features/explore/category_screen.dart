import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/place.dart';
import 'place_browser.dart';
import 'place_filters.dart';

class CategoryScreen extends ConsumerWidget {
  const CategoryScreen({super.key, required this.category});
  final PlaceCategory category;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryId = ref.watch(selectedCountryIdProvider);
    return Scaffold(
      appBar: AppBar(title: Row(children: [Icon(category.icon), const SizedBox(width: 8), Text(category.label)])),
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) => PlaceBrowser(
          catalog: cat,
          places: cat.placesIn(countryId: countryId).where((p) => p.categories.contains(category)).toList(),
          quickFilters: const [
            PlaceFilter.popular,
            PlaceFilter.hiddenGems,
            PlaceFilter.familyFriendly,
            PlaceFilter.notVisited,
          ],
          emptyTitle: 'No ${category.label.toLowerCase()} yet',
          emptyMessage: 'There are no ${category.label.toLowerCase()} in the guide for this country. You can add one.',
        ),
      ),
    );
  }
}
