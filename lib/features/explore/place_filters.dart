import 'package:flutter/material.dart';

import '../../application/catalog.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/common.dart';
import '../../domain/entities/place.dart';

enum PlaceFilter {
  popular('Popular', Icons.local_fire_department_rounded),
  hiddenGems('Hidden Gems', Icons.diamond_rounded),
  nature('Nature', Icons.park_rounded),
  adventure('Adventure', Icons.hiking_rounded),
  historical('Historical', Icons.account_balance_rounded),
  religious('Religious', Icons.temple_hindu_rounded),
  familyFriendly('Family Friendly', Icons.family_restroom_rounded),
  freeEntry('Free Entry', Icons.money_off_rounded),
  paidEntry('Paid Entry', Icons.confirmation_number_rounded),
  visited('Already Visited', Icons.check_circle_rounded),
  notVisited('Not Yet Visited', Icons.radio_button_unchecked_rounded);

  const PlaceFilter(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum PlaceSort {
  popularity('Popularity'),
  name('Name (A–Z)'),
  distance('Distance from centre');

  const PlaceSort(this.label);
  final String label;
}

const _kindGroup = {PlaceFilter.popular, PlaceFilter.hiddenGems};
const _themeGroup = {PlaceFilter.nature, PlaceFilter.adventure, PlaceFilter.historical, PlaceFilter.religious};
const _entryGroup = {PlaceFilter.freeEntry, PlaceFilter.paidEntry};
const _statusGroup = {PlaceFilter.visited, PlaceFilter.notVisited};

/// Immutable filter + sort state. Filters in the same group are OR-ed,
/// different groups are AND-ed.
class PlaceQuery {
  const PlaceQuery({this.filters = const {}, this.sort = PlaceSort.popularity});

  final Set<PlaceFilter> filters;
  final PlaceSort sort;

  bool get isDefault => filters.isEmpty && sort == PlaceSort.popularity;

  PlaceQuery toggle(PlaceFilter f) =>
      PlaceQuery(filters: filters.contains(f) ? ({...filters}..remove(f)) : {...filters, f}, sort: sort);
  PlaceQuery withSort(PlaceSort s) => PlaceQuery(filters: filters, sort: s);

  bool _matches(PlaceFilter f, Place p, Set<String> visited) => switch (f) {
    PlaceFilter.popular => p.kind == PlaceKind.attraction && p.popularity >= 75,
    PlaceFilter.hiddenGems => p.kind == PlaceKind.hiddenGem,
    PlaceFilter.nature => p.categories.any((c) => c.isNature),
    PlaceFilter.adventure => p.categories.contains(PlaceCategory.adventure),
    PlaceFilter.historical => p.categories.contains(PlaceCategory.historical),
    PlaceFilter.religious => p.categories.contains(PlaceCategory.temples),
    PlaceFilter.familyFriendly => p.familyFriendly,
    PlaceFilter.freeEntry => p.entry == EntryType.free,
    PlaceFilter.paidEntry => p.entry == EntryType.paid,
    PlaceFilter.visited => visited.contains(p.id),
    PlaceFilter.notVisited => !visited.contains(p.id),
  };

  bool _group(Set<PlaceFilter> group, Place p, Set<String> visited) {
    final active = filters.intersection(group);
    return active.isEmpty || active.any((f) => _matches(f, p, visited));
  }

  List<Place> apply(List<Place> input, {required Set<String> visitedIds, required Catalog catalog}) {
    final out = input.where((p) {
      if (filters.contains(PlaceFilter.familyFriendly) && !p.familyFriendly) return false;
      return _group(_kindGroup, p, visitedIds) &&
          _group(_themeGroup, p, visitedIds) &&
          _group(_entryGroup, p, visitedIds) &&
          _group(_statusGroup, p, visitedIds);
    }).toList();
    switch (sort) {
      case PlaceSort.popularity:
        out.sort((a, b) => b.popularity.compareTo(a.popularity));
      case PlaceSort.name:
        out.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      case PlaceSort.distance:
        double d(Place p) => catalog.distanceFromCentre(p) ?? double.infinity;
        out.sort((a, b) => d(a).compareTo(d(b)));
    }
    return out;
  }
}

/// Bottom sheet for choosing filters and sort. Returns the new query.
Future<PlaceQuery?> showFilterSheet(
  BuildContext context,
  PlaceQuery current, {
  bool allowDistance = true,
  Set<PlaceFilter>? available,
}) {
  return showModalBottomSheet<PlaceQuery>(
    context: context,
    isScrollControlled: true,
    builder: (ctx) => _FilterSheet(current: current, allowDistance: allowDistance, available: available),
  );
}

class _FilterSheet extends StatefulWidget {
  const _FilterSheet({required this.current, required this.allowDistance, this.available});
  final PlaceQuery current;
  final bool allowDistance;
  final Set<PlaceFilter>? available;

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late PlaceQuery q = widget.current;

  @override
  Widget build(BuildContext context) {
    final filters = PlaceFilter.values.where((f) => widget.available?.contains(f) ?? true);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text('Filter & sort', style: context.text.titleLarge),
                const Spacer(),
                TextButton(onPressed: () => setState(() => q = const PlaceQuery()), child: const Text('Reset')),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            Text('Show', style: context.text.titleSmall),
            const SizedBox(height: AppSpace.sm),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final f in filters)
                  AppChip(
                    label: f.label,
                    icon: f.icon,
                    selected: q.filters.contains(f),
                    onTap: () => setState(() => q = q.toggle(f)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            Text('Sort by', style: context.text.titleSmall),
            RadioGroup<PlaceSort>(
              groupValue: q.sort,
              onChanged: (v) => setState(() => q = q.withSort(v!)),
              child: Column(
                children: [
                  for (final s in PlaceSort.values)
                    if (s != PlaceSort.distance || widget.allowDistance)
                      RadioListTile<PlaceSort>(
                        value: s,
                        contentPadding: EdgeInsets.zero,
                        title: Text(s.label),
                        subtitle: s == PlaceSort.distance
                            ? const Text('Straight-line distance from the destination centre')
                            : null,
                      ),
                ],
              ),
            ),
            const SizedBox(height: AppSpace.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton(onPressed: () => Navigator.pop(context, q), child: const Text('Apply')),
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontal quick-filter chips with a "more" button that opens the sheet.
class FilterBar extends StatelessWidget {
  const FilterBar({
    super.key,
    required this.query,
    required this.onChanged,
    this.quick = const [PlaceFilter.popular, PlaceFilter.hiddenGems, PlaceFilter.nature, PlaceFilter.notVisited],
    this.allowDistance = true,
  });

  final PlaceQuery query;
  final ValueChanged<PlaceQuery> onChanged;
  final List<PlaceFilter> quick;
  final bool allowDistance;

  @override
  Widget build(BuildContext context) {
    final extra = query.filters.difference(quick.toSet()).length + (query.sort == PlaceSort.popularity ? 0 : 1);
    return SizedBox(
      height: scaledHeight(context, 44, textShare: 0.7),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: AppSpace.screen,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: Badge(
              isLabelVisible: extra > 0,
              label: Text('$extra'),
              child: AppChip(
                label: 'Filters',
                icon: Icons.tune_rounded,
                selected: extra > 0,
                onTap: () async {
                  final r = await showFilterSheet(context, query, allowDistance: allowDistance);
                  if (r != null) onChanged(r);
                },
              ),
            ),
          ),
          for (final f in quick)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: AppChip(
                label: f.label,
                selected: query.filters.contains(f),
                onTap: () => onChanged(query.toggle(f)),
              ),
            ),
        ],
      ),
    );
  }
}

String sortLabel(PlaceSort s) => s.label;
String categoriesLabel(Place p) => p.categories.map((c) => c.label).join(' · ');
