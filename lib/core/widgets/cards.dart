import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/catalog.dart';
import '../../application/providers.dart';
import '../../domain/entities/geography.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/user_activity.dart';
import '../router/routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_theme.dart';
import '../utils/labels.dart';
import 'common.dart';
import 'media.dart';

/// Heart-style bookmark that adds/removes a bucket-list item.
class BookmarkButton extends ConsumerWidget {
  const BookmarkButton({super.key, required this.type, required this.id, this.onImage = true, this.size = 20});

  final SubjectType type;
  final String id;
  final bool onImage;
  final double size;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final saved = ref.watch(isBucketedProvider(id));
    final icon = AnimatedSwitcher(
      duration: AppDurations.fast,
      transitionBuilder: (c, a) => ScaleTransition(scale: a, child: c),
      child: Icon(
        saved ? Icons.bookmark_rounded : Icons.bookmark_border_rounded,
        key: ValueKey(saved),
        size: size,
        color: saved ? AppColors.bucket : (onImage ? Colors.white : context.colors.onSurface),
      ),
    );
    return Semantics(
      button: true,
      label: saved ? 'Remove from bucket list' : 'Add to bucket list',
      child: Material(
        color: onImage ? Colors.black.withValues(alpha: 0.32) : Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: () async {
            final added = await ref.read(bucketProvider.notifier).toggle(type, id);
            if (context.mounted) showSnack(context, added ? 'Added to your bucket list' : 'Removed from bucket list');
          },
          child: Padding(padding: const EdgeInsets.all(8), child: icon),
        ),
      ),
    );
  }
}

class VisitedBadge extends StatelessWidget {
  const VisitedBadge({super.key, this.compact = false});
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Pill(
      label: compact ? 'Visited' : 'Visited ✓',
      icon: Icons.check_circle_rounded,
      color: AppColors.visited,
      solid: true,
    );
  }
}

/// Large image card for a destination (Popular Destinations carousel).
class DestinationCard extends ConsumerWidget {
  const DestinationCard({super.key, required this.destination, this.width = 260, this.height = 320, this.hero = false});

  final Destination destination;
  final double width;
  final double height;

  /// Only one carousel per screen should animate into the destination page,
  /// otherwise tabs kept alive by the shell would register duplicate tags.
  final bool hero;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final count = catalog?.sightCount(destination.id) ?? 0;
    final loc = catalog?.destinationLocation(destination) ?? '';
    return SizedBox(
      width: width,
      height: height,
      child: Semantics(
        button: true,
        label: '${destination.name}, $loc',
        child: GestureDetector(
          onTap: () => context.push(Routes.destination(destination.id)),
          child: ClipRRect(
            borderRadius: AppRadius.lgAll,
            child: Stack(
              fit: StackFit.expand,
              children: [
                DestinationCover(destination: destination, heroTag: hero ? destinationHeroTag(destination.id) : null),
                const BottomScrim(),
                Positioned(
                  top: 10,
                  right: 10,
                  child: BookmarkButton(type: SubjectType.destination, id: destination.id),
                ),
                Positioned(
                  top: 14,
                  left: 14,
                  child: Pill(
                    label: destination.season.recommendedSeason,
                    icon: Icons.wb_sunny_rounded,
                    color: Colors.black.withValues(alpha: 0.35),
                    solid: true,
                  ),
                ),
                Positioned(
                  left: 16,
                  right: 16,
                  bottom: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        destination.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.headlineMedium?.copyWith(color: Colors.white),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.place_rounded, size: 14, color: Colors.white70),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              loc,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: context.text.bodySmall?.copyWith(color: Colors.white70),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpace.sm),
                      Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          _GlassTag(icon: Icons.photo_camera_rounded, label: plural(count, 'attraction')),
                          _GlassTag(
                            icon: Icons.calendar_month_rounded,
                            label: monthRange(destination.season.bestMonths),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _GlassTag extends StatelessWidget {
  const _GlassTag({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(100),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.white),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelSmall?.copyWith(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// Vertical card with image on top — used for attractions and hidden gems in
/// carousels. Needs a bounded height (the image fills what the text leaves).
class PlaceCard extends ConsumerWidget {
  const PlaceCard({super.key, required this.place, this.width = 220});

  final Place place;
  final double width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final visited = ref.watch(visitForProvider(place.id)) != null;
    return SizedBox(
      width: width,
      child: SurfaceCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push(Routes.place(place.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlaceCover(place: place),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: BookmarkButton(type: SubjectType.place, id: place.id, size: 18),
                    ),
                    Positioned(
                      left: 8,
                      top: 10,
                      child: visited
                          ? const VisitedBadge(compact: true)
                          : Pill(label: place.kind.label, icon: place.kind.icon, color: place.kind.color, solid: true),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.md, AppSpace.md, AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                  const SizedBox(height: 2),
                  Text(
                    catalog?.placeLocation(place) ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  if (place.bestTime != null) ...[
                    const SizedBox(height: AppSpace.sm),
                    Row(
                      children: [
                        Icon(Icons.wb_sunny_outlined, size: 14, color: context.colors.tertiary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            place.bestTime!,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: context.text.labelSmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal list tile for places — used in lists, search and history.
class PlaceTile extends ConsumerWidget {
  const PlaceTile({super.key, required this.place, this.trailing, this.subtitle, this.onTap, this.distanceKm});

  final Place place;
  final Widget? trailing;
  final String? subtitle;
  final VoidCallback? onTap;
  final double? distanceKm;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final visited = ref.watch(visitForProvider(place.id)) != null;
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpace.sm),
      onTap: onTap ?? () => context.push(Routes.place(place.id)),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: PlaceCover(place: place),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 6,
                  runSpacing: 4,
                  children: [
                    Pill(label: place.kind.label, color: place.kind.color),
                    if (visited) const Pill(label: 'Visited', icon: Icons.check_rounded, color: AppColors.visited),
                    if (place.isUserSubmitted)
                      const Pill(label: 'Added by you', icon: Icons.person_rounded, color: AppColors.oceanBlue),
                  ],
                ),
                const SizedBox(height: 6),
                Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                const SizedBox(height: 2),
                Text(
                  subtitle ??
                      [
                        catalog?.placeLocation(place) ?? '',
                        if (distanceKm != null)
                          '${distanceKm!.toStringAsFixed(distanceKm! < 10 ? 1 : 0)} km from centre',
                      ].where((s) => s.isNotEmpty).join(' · '),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.bodySmall,
                ),
              ],
            ),
          ),
          trailing ?? BookmarkButton(type: SubjectType.place, id: place.id, onImage: false),
        ],
      ),
    );
  }
}

/// Food spot card showing dishes and price range. Needs a bounded height.
class FoodSpotCard extends ConsumerWidget {
  const FoodSpotCard({super.key, required this.place, this.width});

  final Place place;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final catalog = ref.watch(catalogProvider).value;
    final visited = ref.watch(visitForProvider(place.id)) != null;
    return SizedBox(
      width: width,
      child: SurfaceCard(
        padding: EdgeInsets.zero,
        onTap: () => context.push(Routes.place(place.id)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppRadius.lg)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    PlaceCover(place: place),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: BookmarkButton(type: SubjectType.place, id: place.id, size: 18),
                    ),
                    if (visited) const Positioned(left: 8, top: 10, child: VisitedBadge(compact: true)),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AppSpace.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.titleMedium),
                  Text(
                    catalog?.placeLocation(place) ?? '',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Row(
                    children: [
                      if (place.foodCategories.isNotEmpty)
                        Flexible(
                          child: Pill(
                            label: place.foodCategories.first.label,
                            icon: place.foodCategories.first.icon,
                            color: AppColors.foodSpot,
                          ),
                        ),
                      if (place.priceRange != null) ...[
                        const SizedBox(width: 6),
                        Pill(label: place.priceRange!.split(' ').first, color: AppColors.slate),
                      ],
                    ],
                  ),
                  const SizedBox(height: AppSpace.sm),
                  Text(
                    place.famousDishes.isEmpty
                        ? place.description
                        : 'Famous for: ${place.famousDishes.take(3).join(', ')}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Compact destination row (region pages, bucket list).
class DestinationTile extends ConsumerWidget {
  const DestinationTile({super.key, required this.destination, this.trailing, this.onTap});

  final Destination destination;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final Catalog? catalog = ref.watch(catalogProvider).value;
    return SurfaceCard(
      padding: const EdgeInsets.all(AppSpace.sm),
      onTap: onTap ?? () => context.push(Routes.destination(destination.id)),
      child: Row(
        children: [
          SizedBox(
            width: 84,
            height: 84,
            child: ClipRRect(
              borderRadius: AppRadius.mdAll,
              child: DestinationCover(destination: destination),
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(destination.name, style: context.text.titleMedium),
                Text(catalog?.destinationLocation(destination) ?? '', style: context.text.bodySmall),
                const SizedBox(height: 6),
                Text(
                  '${plural(catalog?.sightCount(destination.id) ?? 0, 'attraction')} · Best ${monthRange(destination.season.bestMonths)}',
                  style: context.text.labelSmall?.copyWith(color: context.colors.primary),
                ),
              ],
            ),
          ),
          trailing ?? BookmarkButton(type: SubjectType.destination, id: destination.id, onImage: false),
        ],
      ),
    );
  }
}

String destinationHeroTag(String id) => 'dest-$id';

/// Horizontal scroller with consistent padding.
class HorizontalList extends StatelessWidget {
  const HorizontalList({
    super.key,
    required this.height,
    required this.itemCount,
    required this.itemBuilder,
    this.textShare = 0.45,
  });

  /// Height at the default font size; grows with the user's text scale.
  final double height;
  final double textShare;
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: scaledHeight(context, height, textShare: textShare),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter, vertical: 4),
        itemCount: itemCount,
        clipBehavior: Clip.none,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.md),
        itemBuilder: (c, i) => FadeSlideIn(index: i, child: itemBuilder(c, i)),
      ),
    );
  }
}
