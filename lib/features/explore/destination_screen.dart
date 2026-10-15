import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/catalog.dart';
import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../core/utils/links.dart';
import '../../domain/entities/geography.dart';
import '../../domain/entities/media.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/user_activity.dart';
import '../map/travel_map.dart';
import 'place_filters.dart';
import 'region_screen.dart';
import 'season_widgets.dart';

class DestinationScreen extends ConsumerStatefulWidget {
  const DestinationScreen({super.key, required this.destinationId});
  final String destinationId;

  @override
  ConsumerState<DestinationScreen> createState() => _DestinationScreenState();
}

class _DestinationScreenState extends ConsumerState<DestinationScreen> {
  PlaceQuery _query = const PlaceQuery();

  @override
  void initState() {
    super.initState();
    // Feeds "Continue Exploring" on the home screen.
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => ref.read(settingsProvider.notifier).recordRecent(widget.destinationId),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) {
          final d = cat.destination(widget.destinationId);
          if (d == null) {
            return const EmptyState(icon: Icons.place_rounded, title: 'Destination not found', message: '');
          }
          return _body(context, cat, d);
        },
      ),
    );
  }

  Widget _body(BuildContext context, Catalog cat, Destination d) {
    final all = cat.placesAt(d.id);
    final sights = all.where((p) => !p.isFood).toList();
    final gems = all.where((p) => p.isHiddenGem).toList();
    final food = all.where((p) => p.isFood).toList();
    final visitedIds = ref.watch(visitsProvider).map((v) => v.subjectId).toSet();
    final filtered = _query.apply(sights, visitedIds: visitedIds, catalog: cat);
    final visitedHere = sights.where((p) => visitedIds.contains(p.id)).length;
    final destVisit = ref.watch(visitForProvider(d.id));
    final dishes = cat.dishesIn(regionId: d.regionId);

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 340,
          pinned: true,
          stretch: true,
          actions: [
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: BookmarkButton(type: SubjectType.destination, id: d.id),
            ),
          ],
          flexibleSpace: FlexibleSpaceBar(
            stretchModes: const [StretchMode.zoomBackground],
            background: Stack(
              fit: StackFit.expand,
              children: [
                DestinationCover(destination: d, heroTag: destinationHeroTag(d.id), thumbnail: false),
                const BottomScrim(strength: 0.8),
                if (d.photo != null)
                  Positioned(
                    top: MediaQuery.paddingOf(context).top + 56,
                    right: 12,
                    child: PhotoCredit(photo: d.photo!),
                  ),
                Positioned(
                  left: AppSpace.gutter,
                  right: AppSpace.gutter,
                  bottom: AppSpace.xl,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.name, style: context.text.displaySmall?.copyWith(color: Colors.white)),
                      const SizedBox(height: 4),
                      InkWell(
                        onTap: () => context.push(Routes.region(d.regionId)),
                        child: Row(
                          children: [
                            const Icon(Icons.place_rounded, size: 16, color: Colors.white70),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                [
                                  if (d.district != null && d.district != d.name) '${d.district} district',
                                  cat.destinationLocation(d),
                                ].join(' · '),
                                style: context.text.bodyMedium?.copyWith(color: Colors.white70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 0),
          sliver: SliverList.list(
            children: [
              Text(d.tagline, style: context.text.titleMedium?.copyWith(color: context.colors.primary)),
              const SizedBox(height: AppSpace.sm),
              Text(d.intro, style: context.text.bodyLarge),
              if (d.about != null) ...[const SizedBox(height: AppSpace.lg), _WikiCard(about: d.about!)],
              const SizedBox(height: AppSpace.lg),
              _QuickFacts(destination: d),
              const SizedBox(height: AppSpace.lg),
              _ProgressRow(
                visited: visitedHere,
                total: sights.length,
                destVisited: destVisit != null,
                destinationId: d.id,
              ),
              const SizedBox(height: AppSpace.md),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('${Routes.newTrip}?destination=${d.id}'),
                      icon: const Icon(Icons.event_note_rounded),
                      label: const Text('Plan a trip'),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => context.push('${Routes.addPlace}?destination=${d.id}'),
                      icon: const Icon(Icons.add_location_alt_rounded),
                      label: const Text('Add place'),
                    ),
                  ),
                ],
              ),
              const DetailHeading('Best Time to Visit'),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.xs,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Pill(
                    label: d.season.recommendedSeason,
                    icon: Icons.wb_sunny_rounded,
                    color: AppColors.warmOrange,
                    solid: true,
                  ),
                  Text(monthRange(d.season.bestMonths), style: context.text.titleMedium),
                ],
              ),
              const SizedBox(height: AppSpace.sm),
              Text(d.season.summary, style: context.text.bodyMedium),
              const SizedBox(height: AppSpace.md),
              MonthStrip(guide: d.season),
            ],
          ),
        ),
        if (d.season.cards.isNotEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpace.lg),
              child: HorizontalList(
                height: 218,
                itemCount: d.season.cards.length,
                itemBuilder: (_, i) => SeasonCardView(card: d.season.cards[i]),
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, 0),
          sliver: SliverList.list(
            children: [
              InfoRow(icon: Icons.thermostat_rounded, label: 'Typical climate', value: d.climate),
              const SizedBox(height: AppSpace.sm),
              const CuratedSeasonNote(),
            ],
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHeader('Attractions', subtitle: '${filtered.length} of ${sights.length} shown'),
        ),
        SliverToBoxAdapter(
          child: FilterBar(query: _query, onChanged: (q) => setState(() => _query = q)),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpace.md)),
        if (filtered.isEmpty)
          SliverToBoxAdapter(
            child: EmptyState(
              compact: true,
              icon: Icons.filter_alt_off_rounded,
              title: 'Nothing matches these filters',
              message: 'Try removing a filter.',
              actionLabel: 'Clear filters',
              onAction: () => setState(() => _query = const PlaceQuery()),
            ),
          )
        else
          SliverPadding(
            padding: AppSpace.screen,
            sliver: SliverList.separated(
              itemCount: filtered.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
              itemBuilder: (_, i) => FadeSlideIn(
                index: i,
                child: PlaceTile(
                  place: filtered[i],
                  distanceKm: _query.sort == PlaceSort.distance ? cat.distanceFromCentre(filtered[i]) : null,
                ),
              ),
            ),
          ),
        if (gems.isNotEmpty) ...[
          SliverToBoxAdapter(
            child: SectionHeader(
              'Hidden Gems',
              subtitle: 'Lesser-known spots around ${d.name}',
              action: 'See all',
              onAction: () => context.push(Routes.gemsIn(destinationId: d.id)),
            ),
          ),
          SliverToBoxAdapter(
            child: HorizontalList(
              height: 262,
              itemCount: gems.length,
              itemBuilder: (_, i) => PlaceCard(place: gems[i]),
            ),
          ),
        ],
        SliverToBoxAdapter(
          child: SectionHeader(
            'Local Food Spots',
            subtitle: food.isEmpty ? 'None listed yet' : null,
            action: food.isEmpty ? 'Add one' : 'Food explorer',
            onAction: () => food.isEmpty
                ? context.push('${Routes.addPlace}?destination=${d.id}&kind=foodSpot')
                : context.push(Routes.foodIn(destinationId: d.id)),
          ),
        ),
        if (food.isNotEmpty)
          SliverToBoxAdapter(
            child: HorizontalList(
              height: 290,
              itemCount: food.length,
              itemBuilder: (_, i) => FoodSpotCard(place: food[i], width: 230),
            ),
          ),
        if (dishes.isNotEmpty)
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 0),
            sliver: SliverList.list(
              children: [
                Text('Regional dishes — tap to add to Foods I want to try', style: context.text.bodySmall),
                const SizedBox(height: AppSpace.sm),
                DishChips(dishes: dishes),
              ],
            ),
          ),
        if (d.activities.isNotEmpty)
          SliverPadding(
            padding: AppSpace.screen,
            sliver: SliverList.list(
              children: [
                const DetailHeading('Activities'),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [for (final a in d.activities) Pill(label: a, icon: Icons.local_activity_rounded)],
                ),
              ],
            ),
          ),
        SliverPadding(
          padding: AppSpace.screen,
          sliver: SliverList.list(
            children: [
              const DetailHeading('Map'),
              SizedBox(
                height: 240,
                child: ClipRRect(
                  borderRadius: AppRadius.lgAll,
                  child: _DestinationMap(destination: d, places: all),
                ),
              ),
              const SizedBox(height: AppSpace.sm),
              const MapLegend(),
              const SizedBox(height: AppSpace.lg),
              const SampleDataNote(),
              const SizedBox(height: AppSpace.xxxl),
            ],
          ),
        ),
      ],
    );
  }
}

class _QuickFacts extends StatelessWidget {
  const _QuickFacts({required this.destination});
  final Destination destination;

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.calendar_month_rounded, 'Best time', monthRange(destination.season.bestMonths)),
      (Icons.schedule_rounded, 'Trip length', destination.recommendedDuration),
      (Icons.wb_sunny_rounded, 'Season', destination.season.recommendedSeason),
    ];
    return Row(
      children: [
        for (final (icon, label, value) in items)
          Expanded(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.all(AppSpace.md),
              decoration: BoxDecoration(color: context.palette.card, borderRadius: AppRadius.mdAll),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 20, color: context.colors.primary),
                  const SizedBox(height: 6),
                  Text(label, style: context.text.labelSmall?.copyWith(color: context.palette.muted)),
                  Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: context.text.titleSmall),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ProgressRow extends ConsumerWidget {
  const _ProgressRow({
    required this.visited,
    required this.total,
    required this.destVisited,
    required this.destinationId,
  });
  final int visited;
  final int total;
  final bool destVisited;
  final String destinationId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SurfaceCard(
      onTap: visited > 0 ? () => context.push(Routes.visitedIn(destinationId)) : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  visited == 0
                      ? 'You haven\'t visited any places here yet'
                      : 'You\'ve visited $visited of $total places',
                  style: context.text.titleSmall,
                ),
              ),
              if (visited > 0) const Icon(Icons.chevron_right_rounded),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          AnimatedProgressBar(value: total == 0 ? 0 : visited / total, color: AppColors.visited),
          const SizedBox(height: AppSpace.sm),
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    destVisited ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                    size: 18,
                    color: destVisited ? AppColors.visited : context.palette.muted,
                  ),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      destVisited ? 'Destination marked as visited' : 'Been here? Mark the destination as visited',
                      style: context.text.bodySmall,
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () async {
                  final n = ref.read(visitsProvider.notifier);
                  if (destVisited) {
                    await n.unmark(destinationId);
                  } else {
                    await n.markVisited(SubjectType.destination, destinationId);
                    if (context.mounted) showSnack(context, 'Destination marked as visited');
                  }
                },
                child: Text(destVisited ? 'Undo' : 'Mark visited'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _DestinationMap extends ConsumerWidget {
  const _DestinationMap({required this.destination, required this.places});
  final Destination destination;
  final List<Place> places;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visited = ref.watch(visitsProvider).map((v) => v.subjectId).toSet();
    final bucket = ref.watch(bucketProvider).map((b) => b.subjectId).toSet();
    return TravelMap(
      center: destination.center,
      zoom: 10,
      pins: [
        for (final p in places) MapPin(id: p.id, point: p.location, style: styleFor(p, visited, bucket), label: p.name),
      ],
      onPinTap: (pin) => context.push(Routes.place(pin.id)),
    );
  }
}

MarkerStyle styleFor(Place p, Set<String> visited, Set<String> bucket) {
  if (visited.contains(p.id)) return MarkerStyle.visited;
  if (bucket.contains(p.id)) return MarkerStyle.bucket;
  return switch (p.kind) {
    PlaceKind.attraction => MarkerStyle.attraction,
    PlaceKind.hiddenGem => MarkerStyle.hiddenGem,
    PlaceKind.foodSpot => MarkerStyle.food,
  };
}

/// Sourced background and history for a destination.
class _WikiCard extends StatelessWidget {
  const _WikiCard({required this.about});
  final SourcedText about;

  @override
  Widget build(BuildContext context) {
    return SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.history_edu_rounded, color: context.colors.tertiary),
              const SizedBox(width: AppSpace.sm),
              Expanded(child: Text('Background & history', style: context.text.titleMedium)),
            ],
          ),
          const SizedBox(height: AppSpace.sm),
          Text(about.text, style: context.text.bodyMedium),
          if (about.history.isNotEmpty) ...[
            const SizedBox(height: AppSpace.sm),
            Text(about.history, style: context.text.bodyMedium),
          ],
          const SizedBox(height: AppSpace.sm),
          InkWell(
            onTap: () => openExternal(context, about.sourceUrl),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Icon(Icons.menu_book_rounded, size: 14, color: context.palette.muted),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Source: ${about.sourceName} — "${about.sourceTitle}" (${about.license})',
                      style: context.text.labelSmall?.copyWith(color: context.palette.muted),
                    ),
                  ),
                  Icon(Icons.open_in_new_rounded, size: 14, color: context.palette.muted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
