import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/catalog.dart';
import '../../application/providers.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/place.dart';
import 'place_filters.dart';

/// Reusable list of places with region chips, quick filters and sorting.
class PlaceBrowser extends ConsumerStatefulWidget {
  const PlaceBrowser({
    super.key,
    required this.catalog,
    required this.places,
    this.header,
    this.quickFilters = const [PlaceFilter.familyFriendly, PlaceFilter.freeEntry, PlaceFilter.notVisited],
    this.emptyTitle = 'Nothing here yet',
    this.emptyMessage = 'Try another filter.',
    this.initialRegionId,
  });

  final Catalog catalog;
  final List<Place> places;
  final Widget? header;
  final List<PlaceFilter> quickFilters;
  final String emptyTitle;
  final String emptyMessage;
  final String? initialRegionId;

  @override
  ConsumerState<PlaceBrowser> createState() => _PlaceBrowserState();
}

class _PlaceBrowserState extends ConsumerState<PlaceBrowser> {
  PlaceQuery _query = const PlaceQuery();
  late String? _regionId = widget.initialRegionId;

  @override
  Widget build(BuildContext context) {
    final visited = ref.watch(visitsProvider).map((v) => v.subjectId).toSet();
    final regionIds = widget.places.map((p) => p.regionId).whereType<String>().toSet();
    final regions = widget.catalog.regions.where((r) => regionIds.contains(r.id)).toList();
    final base = _regionId == null ? widget.places : widget.places.where((p) => p.regionId == _regionId).toList();
    final list = _query.apply(base, visitedIds: visited, catalog: widget.catalog);

    return CustomScrollView(
      slivers: [
        if (widget.header != null) SliverToBoxAdapter(child: widget.header),
        if (regions.length > 1)
          SliverToBoxAdapter(
            child: SizedBox(
              height: scaledHeight(context, 44, textShare: 0.7),
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppSpace.gutter),
                children: [
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: AppChip(
                      label: 'All',
                      selected: _regionId == null,
                      onTap: () => setState(() => _regionId = null),
                    ),
                  ),
                  for (final r in regions)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: AppChip(
                        label: r.name,
                        selected: _regionId == r.id,
                        onTap: () => setState(() => _regionId = _regionId == r.id ? null : r.id),
                      ),
                    ),
                ],
              ),
            ),
          ),
        const SliverToBoxAdapter(child: SizedBox(height: AppSpace.sm)),
        SliverToBoxAdapter(
          child: FilterBar(query: _query, quick: widget.quickFilters, onChanged: (q) => setState(() => _query = q)),
        ),
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, AppSpace.sm),
            child: Text(
              '${list.length} places · sorted by ${_query.sort.label.toLowerCase()}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ),
        ),
        if (list.isEmpty)
          SliverFillRemaining(
            hasScrollBody: false,
            child: EmptyState(
              icon: Icons.travel_explore_rounded,
              title: widget.emptyTitle,
              message: widget.emptyMessage,
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.xxxl),
            sliver: SliverList.separated(
              itemCount: list.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpace.md),
              itemBuilder: (_, i) => FadeSlideIn(
                index: i,
                child: PlaceTile(
                  place: list[i],
                  distanceKm: _query.sort == PlaceSort.distance ? widget.catalog.distanceFromCentre(list[i]) : null,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
