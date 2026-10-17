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
import '../../domain/entities/place.dart';
import 'place_browser.dart';
import 'place_filters.dart';

/// Which slice of the catalog the Explore tab lists.
enum _Scope {
  all('All', Icons.apps_rounded, null),
  attractions('Attractions', Icons.place_rounded, AppColors.attraction),
  gems('Hidden gems', Icons.diamond_rounded, AppColors.hiddenGem),
  food('Food spots', Icons.restaurant_rounded, AppColors.foodSpot),
  saved('Saved', Icons.favorite_rounded, AppColors.danger);

  const _Scope(this.label, this.icon, this.color);
  final String label;
  final IconData icon;
  final Color? color;
}

/// Explore tab: search every place in the country, narrow by type, filter,
/// sort and save favourites (the heart adds a place to the bucket list).
class ExploreScreen extends ConsumerStatefulWidget {
  const ExploreScreen({super.key});

  @override
  ConsumerState<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends ConsumerState<ExploreScreen> {
  final _search = TextEditingController();
  _Scope _scope = _Scope.all;

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countryId = ref.watch(selectedCountryIdProvider);
    final saved = {for (final b in ref.watch(bucketProvider)) b.subjectId};
    return Scaffold(
      appBar: AppBar(
        title: Text('Explore', style: context.text.headlineMedium),
        actions: [
          IconButton(
            tooltip: 'Bucket list',
            icon: Badge(
              isLabelVisible: saved.isNotEmpty,
              label: Text('${saved.length}'),
              child: const Icon(Icons.bookmarks_rounded),
            ),
            onPressed: () => context.push(Routes.bucket),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'explore-add-place',
        onPressed: () => context.push(Routes.addPlace),
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('Add place'),
      ),
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) {
          final q = _search.text.trim().toLowerCase();
          final places = cat.placesIn(countryId: countryId).where((p) {
            final inScope = switch (_scope) {
              _Scope.all => true,
              _Scope.attractions => p.kind == PlaceKind.attraction,
              _Scope.gems => p.kind == PlaceKind.hiddenGem,
              _Scope.food => p.kind == PlaceKind.foodSpot,
              _Scope.saved => saved.contains(p.id),
            };
            return inScope && (q.isEmpty || _matches(cat, p, q));
          }).toList();
          final destinations = q.isEmpty
              ? const <Widget>[]
              : [
                  for (final d in cat.destinationsIn(countryId: countryId))
                    if (d.name.toLowerCase().contains(q) || cat.destinationLocation(d).toLowerCase().contains(q))
                      DestinationTile(destination: d),
                ];

          return PlaceBrowser(
            catalog: cat,
            places: places,
            quickFilters: const [PlaceFilter.notVisited, PlaceFilter.familyFriendly, PlaceFilter.freeEntry],
            emptyTitle: _scope == _Scope.saved && q.isEmpty ? 'No saved places yet' : 'No places found',
            emptyMessage: _scope == _Scope.saved && q.isEmpty
                ? 'Tap the bookmark on any place to save it as a favourite.'
                : 'Try another name, type or filter.',
            header: _Header(
              controller: _search,
              scope: _scope,
              savedCount: saved.length,
              countryLabel: '${cat.country(countryId)?.flag ?? ''} ${cat.country(countryId)?.name ?? ''}'.trim(),
              destinations: destinations,
              onSearch: () => setState(() {}),
              onScope: (s) => setState(() => _scope = s),
            ),
          );
        },
      ),
    );
  }

  bool _matches(Catalog cat, Place p, String q) =>
      p.name.toLowerCase().contains(q) ||
      cat.placeLocation(p).toLowerCase().contains(q) ||
      p.categories.any((c) => c.label.toLowerCase().contains(q));
}

class _Header extends StatelessWidget {
  const _Header({
    required this.controller,
    required this.scope,
    required this.savedCount,
    required this.countryLabel,
    required this.destinations,
    required this.onSearch,
    required this.onScope,
  });

  final TextEditingController controller;
  final _Scope scope;
  final int savedCount;
  final String countryLabel;
  final List<Widget> destinations;
  final VoidCallback onSearch;
  final ValueChanged<_Scope> onScope;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.xs, AppSpace.gutter, AppSpace.md),
          child: AppSearchField(
            controller: controller,
            hint: 'Search places in $countryLabel',
            onChanged: (_) => onSearch(),
          ),
        ),
        SizedBox(
          height: scaledHeight(context, 44, textShare: 0.7),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: AppSpace.screen,
            itemCount: _Scope.values.length,
            separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
            itemBuilder: (context, i) {
              final s = _Scope.values[i];
              final selected = s == scope;
              final color = s.color ?? context.colors.primary;
              return FilterChip(
                selected: selected,
                showCheckmark: false,
                avatar: Icon(s.icon, size: 16, color: selected ? Colors.white : color),
                label: Text(s == _Scope.saved && savedCount > 0 ? '${s.label} · $savedCount' : s.label),
                labelStyle: context.text.labelMedium?.copyWith(
                  color: selected ? Colors.white : context.colors.onSurface,
                ),
                selectedColor: color,
                onSelected: (_) => onScope(s),
              );
            },
          ),
        ),
        if (scope == _Scope.all && controller.text.trim().isEmpty) const _Guides(),
        if (destinations.isNotEmpty) ...[
          const SectionHeader('Destinations'),
          Padding(
            padding: AppSpace.screen,
            child: Column(
              children: [
                for (final (i, d) in destinations.take(5).indexed) ...[
                  if (i > 0) const SizedBox(height: AppSpace.sm),
                  d,
                ],
              ],
            ),
          ),
          const SectionHeader('Places'),
        ] else
          const SizedBox(height: AppSpace.sm),
      ],
    );
  }
}

/// Shortcuts to the curated guide pages.
class _Guides extends StatelessWidget {
  const _Guides();

  @override
  Widget build(BuildContext context) {
    final items = [
      (Icons.diamond_rounded, 'Hidden gems', AppColors.hiddenGem, Routes.gems),
      (Icons.restaurant_rounded, 'Food explorer', AppColors.foodSpot, Routes.food),
      (Icons.wb_sunny_rounded, 'Best time to visit', AppColors.bucket, Routes.seasons),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.md, AppSpace.gutter, 0),
      child: Row(
        children: [
          for (final (i, (icon, label, color, route)) in items.indexed) ...[
            if (i > 0) const SizedBox(width: AppSpace.sm),
            Expanded(
              child: SurfaceCard(
                padding: const EdgeInsets.all(AppSpace.md),
                onTap: () => context.push(route),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: color),
                    const SizedBox(height: AppSpace.xs),
                    Text(label, maxLines: 2, style: context.text.labelMedium),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
