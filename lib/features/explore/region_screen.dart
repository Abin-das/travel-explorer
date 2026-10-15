import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../core/widgets/scene_art.dart';
import '../../domain/entities/geography.dart';
import '../../domain/entities/place.dart';

/// State / region page: Country → Region → list of destinations (cities).
class RegionScreen extends ConsumerWidget {
  const RegionScreen({super.key, required this.regionId});
  final String regionId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) {
          final region = cat.region(regionId);
          if (region == null) {
            return const EmptyState(
              icon: Icons.map_rounded,
              title: 'Region not found',
              message: 'It may have been removed.',
            );
          }
          final dests = cat.destinationsIn(regionId: regionId);
          final gems = cat.placesIn(regionId: regionId, kind: PlaceKind.hiddenGem);
          final food = cat.placesIn(regionId: regionId, kind: PlaceKind.foodSpot);
          final dishes = cat.dishesIn(regionId: regionId);
          final country = cat.country(region.countryId);
          return CustomScrollView(
            slivers: [
              SliverAppBar(
                expandedHeight: 240,
                pinned: true,
                stretch: true,
                flexibleSpace: FlexibleSpaceBar(
                  title: Text(region.name),
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      SceneArt(theme: dests.isEmpty ? SceneTheme.mountains : dests.first.theme, seed: region.id),
                      const BottomScrim(strength: 0.6),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 0),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${region.kind} · ${country?.name ?? ''} ${country?.flag ?? ''}',
                        style: context.text.bodySmall,
                      ),
                      const SizedBox(height: 4),
                      Text(region.tagline, style: context.text.bodyLarge),
                    ],
                  ),
                ),
              ),
              SliverToBoxAdapter(child: SectionHeader('Destinations', subtitle: plural(dests.length, 'destination'))),
              if (dests.isEmpty)
                SliverToBoxAdapter(
                  child: EmptyState(
                    compact: true,
                    icon: Icons.add_location_alt_rounded,
                    title: 'No curated destinations yet',
                    message: 'Add places you know in ${region.name}.',
                    actionLabel: 'Add a place',
                    onAction: () => context.push(Routes.addPlace),
                  ),
                )
              else
                SliverPadding(
                  padding: AppSpace.screen,
                  sliver: SliverList.separated(
                    itemCount: dests.length,
                    separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
                    itemBuilder: (_, i) => FadeSlideIn(
                      index: i,
                      child: DestinationTile(destination: dests[i]),
                    ),
                  ),
                ),
              if (gems.isNotEmpty) ...[
                SliverToBoxAdapter(child: SectionHeader('Hidden gems in ${region.name}')),
                SliverToBoxAdapter(
                  child: HorizontalList(
                    height: 262,
                    itemCount: gems.length,
                    itemBuilder: (_, i) => PlaceCard(place: gems[i]),
                  ),
                ),
              ],
              if (food.isNotEmpty) ...[
                SliverToBoxAdapter(child: SectionHeader('Food spots', subtitle: '${food.length} to try')),
                SliverToBoxAdapter(
                  child: HorizontalList(
                    height: 290,
                    itemCount: food.length,
                    itemBuilder: (_, i) => FoodSpotCard(place: food[i], width: 230),
                  ),
                ),
              ],
              if (dishes.isNotEmpty) ...[
                const SliverToBoxAdapter(child: SectionHeader('Dishes to try')),
                SliverPadding(
                  padding: AppSpace.screen,
                  sliver: SliverToBoxAdapter(child: DishChips(dishes: dishes)),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: AppSpace.xxxl)),
            ],
          );
        },
      ),
    );
  }
}

/// Chips for regional dishes that add/remove them from "Foods I want to try".
class DishChips extends ConsumerWidget {
  const DishChips({super.key, required this.dishes});
  final List<LocalDish> dishes;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishes = ref.watch(dishWishesProvider);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final d in dishes)
          Builder(
            builder: (context) {
              final wish = wishes.where((w) => w.dishId == d.id).firstOrNull;
              return Tooltip(
                message: d.description,
                child: AppChip(
                  label: d.name,
                  icon: wish == null
                      ? Icons.add_rounded
                      : (wish.tried ? Icons.check_circle_rounded : Icons.bookmark_added_rounded),
                  selected: wish != null,
                  onTap: () async {
                    if (wish == null) {
                      await ref.read(dishWishesProvider.notifier).addDish(d.id);
                      if (context.mounted) showSnack(context, '${d.name} added to Foods I want to try');
                    } else {
                      if (context.mounted) context.push(Routes.bucket);
                    }
                  },
                ),
              );
            },
          ),
      ],
    );
  }
}
