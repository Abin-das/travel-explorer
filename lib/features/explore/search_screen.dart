import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/catalog.dart';
import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';

class SearchScreen extends ConsumerStatefulWidget {
  const SearchScreen({super.key});

  @override
  ConsumerState<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends ConsumerState<SearchScreen> {
  final _c = TextEditingController();
  bool _allCountries = false;

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalog = ref.watch(catalogProvider);
    final countryId = ref.watch(selectedCountryIdProvider);
    return Scaffold(
      appBar: AppBar(
        titleSpacing: 0,
        title: Padding(
          padding: const EdgeInsets.only(right: AppSpace.lg),
          child: Hero(
            tag: 'search-bar',
            child: Material(
              type: MaterialType.transparency,
              child: AppSearchField(controller: _c, autofocus: true, onChanged: (_) => setState(() {})),
            ),
          ),
        ),
        toolbarHeight: 72,
      ),
      body: AsyncView(
        value: catalog,
        builder: (cat) {
          final hits = cat.search(_c.text, countryId: _allCountries ? null : countryId);
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.sm),
                child: Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    AppChip(
                      label: cat.country(countryId)?.name ?? 'This country',
                      selected: !_allCountries,
                      onTap: () => setState(() => _allCountries = false),
                    ),
                    AppChip(
                      label: 'All countries',
                      selected: _allCountries,
                      onTap: () => setState(() => _allCountries = true),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: _c.text.trim().isEmpty
                    ? _Suggestions(onPick: (s) => setState(() => _c.text = s))
                    : hits.isEmpty
                    ? const EmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No results',
                        message: 'Try another name, or add the place yourself from the Explore tab.',
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.sm, AppSpace.gutter, AppSpace.xl),
                        itemCount: hits.length,
                        separatorBuilder: (_, _) => const SizedBox(height: AppSpace.sm),
                        itemBuilder: (_, i) => _HitTile(hit: hits[i], catalog: cat),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _HitTile extends StatelessWidget {
  const _HitTile({required this.hit, required this.catalog});
  final SearchHit hit;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    if (hit.type == SearchHitType.place) return PlaceTile(place: hit.place!);
    if (hit.type == SearchHitType.destination) return DestinationTile(destination: catalog.destination(hit.id)!);
    final (icon, route) = switch (hit.type) {
      SearchHitType.region => (Icons.location_city_rounded, Routes.region(hit.id)),
      _ => (Icons.ramen_dining_rounded, Routes.food),
    };
    return SurfaceCard(
      padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg, vertical: AppSpace.md),
      onTap: () => context.push(route),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: context.colors.primaryContainer,
            child: Icon(icon, color: context.colors.primary),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(hit.title, style: context.text.titleMedium),
                Text(hit.subtitle, style: context.text.bodySmall),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded),
        ],
      ),
    );
  }
}

class _Suggestions extends StatelessWidget {
  const _Suggestions({required this.onPick});
  final ValueChanged<String> onPick;

  @override
  Widget build(BuildContext context) {
    const ideas = ['Munnar', 'Waterfall', 'Biryani', 'Beach', 'Fort', 'Kerala', 'Lake', 'Temple', 'Coffee'];
    return ListView(
      padding: const EdgeInsets.all(AppSpace.gutter),
      children: [
        Text('Try searching for', style: context.text.titleSmall),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final s in ideas) AppChip(label: s, icon: Icons.north_west_rounded, onTap: () => onPick(s))],
        ),
      ],
    );
  }
}
