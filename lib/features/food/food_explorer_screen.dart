import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/place.dart';
import '../explore/region_screen.dart' show DishChips;

class FoodExplorerScreen extends ConsumerStatefulWidget {
  const FoodExplorerScreen({super.key, this.destinationId});
  final String? destinationId;

  @override
  ConsumerState<FoodExplorerScreen> createState() => _FoodExplorerScreenState();
}

class _FoodExplorerScreenState extends ConsumerState<FoodExplorerScreen> {
  FoodCategory? _cat;
  String? _regionId;
  bool _onlyNotVisited = false;

  @override
  Widget build(BuildContext context) {
    final countryId = ref.watch(selectedCountryIdProvider);
    final visited = ref.watch(visitsProvider).map((v) => v.subjectId).toSet();
    return Scaffold(
      appBar: AppBar(title: const Text('Food Explorer')),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'add-food',
        backgroundColor: AppColors.foodSpot,
        foregroundColor: Colors.white,
        onPressed: () => context.push(
          '${Routes.addPlace}?kind=foodSpot${widget.destinationId == null ? '' : '&destination=${widget.destinationId}'}',
        ),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Add food spot'),
      ),
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) {
          final dest = cat.destination(widget.destinationId);
          var spots = dest != null
              ? cat.placesAt(dest.id, kind: PlaceKind.foodSpot)
              : cat.placesIn(countryId: countryId, kind: PlaceKind.foodSpot);
          final regionIds = spots.map((p) => p.regionId).whereType<String>().toSet();
          final regions = cat.regions.where((r) => regionIds.contains(r.id)).toList();
          if (_regionId != null) spots = spots.where((p) => p.regionId == _regionId).toList();
          if (_cat != null) spots = spots.where((p) => p.foodCategories.contains(_cat)).toList();
          if (_onlyNotVisited) spots = spots.where((p) => !visited.contains(p.id)).toList();
          spots.sort((a, b) => b.popularity.compareTo(a.popularity));
          final dishes = dest != null
              ? cat.dishesIn(regionId: dest.regionId)
              : cat.dishesIn(countryId: countryId, regionId: _regionId);

          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.md),
                  child: Text(
                    dest == null
                        ? 'Famous local food spots and dishes across ${cat.country(countryId)?.name ?? 'the country'}.'
                        : 'Food spots in and around ${dest.name}.',
                    style: context.text.bodyMedium?.copyWith(color: context.palette.muted),
                  ),
                ),
              ),
              SliverToBoxAdapter(
                child: SizedBox(
                  height: scaledHeight(context, 44, textShare: 0.7),
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    padding: AppSpace.screen,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: AppChip(label: 'All', selected: _cat == null, onTap: () => setState(() => _cat = null)),
                      ),
                      for (final c in FoodCategory.values)
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: AppChip(
                            label: c.label,
                            icon: c.icon,
                            selected: _cat == c,
                            onTap: () => setState(() => _cat = _cat == c ? null : c),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              if (dest == null && regions.length > 1)
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.only(top: AppSpace.sm),
                    child: SizedBox(
                      height: scaledHeight(context, 44, textShare: 0.7),
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        padding: AppSpace.screen,
                        children: [
                          for (final r in regions)
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: AppChip(
                                label: r.name,
                                icon: Icons.location_city_rounded,
                                selected: _regionId == r.id,
                                onTap: () => setState(() => _regionId = _regionId == r.id ? null : r.id),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                  child: SwitchListTile(
                    value: _onlyNotVisited,
                    onChanged: (v) => setState(() => _onlyNotVisited = v),
                    title: const Text('Only spots I haven\'t visited'),
                  ),
                ),
              ),
              if (dishes.isNotEmpty) ...[
                const SliverToBoxAdapter(
                  child: SectionHeader('Must-try dishes', subtitle: 'Tap to add to Foods I want to try'),
                ),
                SliverPadding(
                  padding: AppSpace.screen,
                  sliver: SliverToBoxAdapter(child: DishChips(dishes: dishes)),
                ),
              ],
              SliverToBoxAdapter(child: SectionHeader('Food spots', subtitle: plural(spots.length, 'spot'))),
              if (spots.isEmpty)
                const SliverToBoxAdapter(
                  child: EmptyState(
                    compact: true,
                    icon: Icons.no_food_rounded,
                    title: 'No food spots match',
                    message: 'Clear a filter, or add a spot you love.',
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, 100),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: 420,
                      mainAxisExtent: 286,
                      mainAxisSpacing: AppSpace.md,
                      crossAxisSpacing: AppSpace.md,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (_, i) => FadeSlideIn(
                        index: i,
                        child: FoodSpotCard(place: spots[i]),
                      ),
                      childCount: spots.length,
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
