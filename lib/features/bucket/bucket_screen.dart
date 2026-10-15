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
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../domain/entities/user_activity.dart';
import '../trips/trip_widgets.dart';

class BucketScreen extends ConsumerWidget {
  const BucketScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: Text('My Bucket List', style: context.text.headlineMedium),
          bottom: const TabBar(
            isScrollable: true,
            tabs: [
              Tab(text: 'Saved Places'),
              Tab(text: 'Food'),
              Tab(text: 'Trip Planner'),
            ],
          ),
        ),
        body: AsyncView(
          value: ref.watch(catalogProvider),
          builder: (cat) => TabBarView(
            children: [
              _SavedPlaces(catalog: cat),
              _FoodTab(catalog: cat),
              const TripList(),
            ],
          ),
        ),
      ),
    );
  }
}

/// A bucket item resolved to display data.
class _Resolved {
  _Resolved(this.item, this.title, this.subtitle, this.countryId, this.regionId, this.cover, this.route, this.isFood);
  final BucketItem item;
  final String title;
  final String subtitle;
  final String countryId;
  final String? regionId;
  final Widget cover;
  final String route;
  final bool isFood;
}

List<_Resolved> _resolve(Catalog cat, List<BucketItem> items) {
  final out = <_Resolved>[];
  for (final b in items) {
    if (b.subjectType == SubjectType.destination) {
      final d = cat.destination(b.subjectId);
      if (d == null) continue;
      out.add(
        _Resolved(
          b,
          d.name,
          cat.destinationLocation(d),
          d.countryId,
          d.regionId,
          DestinationCover(destination: d),
          Routes.destination(d.id),
          false,
        ),
      );
    } else {
      final p = cat.place(b.subjectId);
      if (p == null) continue;
      out.add(
        _Resolved(
          b,
          p.name,
          '${p.kind.label} · ${cat.placeLocation(p)}',
          p.countryId,
          p.regionId,
          PlaceCover(place: p),
          Routes.place(p.id),
          p.isFood,
        ),
      );
    }
  }
  out.sort((a, b) => b.item.addedAt.compareTo(a.item.addedAt));
  return out;
}

class _SavedPlaces extends ConsumerStatefulWidget {
  const _SavedPlaces({required this.catalog});
  final Catalog catalog;

  @override
  ConsumerState<_SavedPlaces> createState() => _SavedPlacesState();
}

class _SavedPlacesState extends ConsumerState<_SavedPlaces> {
  String? _countryId;
  String? _regionId;
  bool _hideVisited = false;

  @override
  Widget build(BuildContext context) {
    final cat = widget.catalog;
    final visited = ref.watch(visitsProvider).map((v) => v.subjectId).toSet();
    final all = _resolve(cat, ref.watch(bucketProvider)).where((r) => !r.isFood).toList();
    final countries = all.map((r) => r.countryId).toSet().map(cat.country).nonNulls.toList();
    final regions = all
        .where((r) => _countryId == null || r.countryId == _countryId)
        .map((r) => r.regionId)
        .whereType<String>()
        .toSet()
        .map(cat.region)
        .nonNulls
        .toList();
    final list = all
        .where(
          (r) =>
              (_countryId == null || r.countryId == _countryId) &&
              (_regionId == null || r.regionId == _regionId) &&
              (!_hideVisited || !visited.contains(r.item.subjectId)),
        )
        .toList();
    final done = all.where((r) => visited.contains(r.item.subjectId)).length;

    if (all.isEmpty) {
      return EmptyState(
        icon: Icons.bookmark_add_rounded,
        title: 'Your bucket list is empty',
        message: 'Tap the bookmark on any destination or attraction to save it here.',
        actionLabel: 'Find places',
        onAction: () => context.go(Routes.explore),
      );
    }
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, AppSpace.lg, AppSpace.gutter, 100),
      children: [
        SurfaceCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('$done of ${all.length} ticked off', style: context.text.titleMedium),
              const SizedBox(height: AppSpace.sm),
              AnimatedProgressBar(value: all.isEmpty ? 0 : done / all.length, color: AppColors.visited),
            ],
          ),
        ),
        const SizedBox(height: AppSpace.md),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            if (countries.length > 1)
              for (final c in countries)
                AppChip(
                  label: '${c.flag} ${c.name}',
                  selected: _countryId == c.id,
                  onTap: () => setState(() {
                    _countryId = _countryId == c.id ? null : c.id;
                    _regionId = null;
                  }),
                ),
            for (final r in regions)
              AppChip(
                label: r.name,
                selected: _regionId == r.id,
                onTap: () => setState(() => _regionId = _regionId == r.id ? null : r.id),
              ),
            AppChip(
              label: 'Hide visited',
              icon: Icons.visibility_off_rounded,
              selected: _hideVisited,
              onTap: () => setState(() => _hideVisited = !_hideVisited),
            ),
          ],
        ),
        const SizedBox(height: AppSpace.md),
        if (list.isEmpty)
          const EmptyState(compact: true, icon: Icons.filter_alt_off_rounded, title: 'Nothing matches', message: ''),
        for (final r in list)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _BucketRow(resolved: r, visited: visited.contains(r.item.subjectId)),
          ),
      ],
    );
  }
}

class _BucketRow extends ConsumerWidget {
  const _BucketRow({required this.resolved, required this.visited});
  final _Resolved resolved;
  final bool visited;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final r = resolved;
    return Dismissible(
      key: ValueKey(r.item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: AppSpace.xl),
        decoration: BoxDecoration(color: AppColors.danger, borderRadius: AppRadius.lgAll),
        child: const Icon(Icons.delete_rounded, color: Colors.white),
      ),
      onDismissed: (_) async {
        final item = r.item;
        await ref.read(bucketProvider.notifier).removeId(item.id);
        if (context.mounted) {
          showSnack(
            context,
            'Removed ${r.title}',
            actionLabel: 'Undo',
            onAction: () => ref.read(bucketProvider.notifier).put(item),
          );
        }
      },
      child: SurfaceCard(
        padding: const EdgeInsets.all(AppSpace.sm),
        onTap: () => context.push(r.route),
        child: Row(
          children: [
            IconButton(
              tooltip: visited ? 'Visited' : 'Mark as visited',
              icon: AnimatedSwitcher(
                duration: AppDurations.fast,
                child: Icon(
                  visited ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded,
                  key: ValueKey(visited),
                  color: visited ? AppColors.visited : null,
                  size: 28,
                ),
              ),
              onPressed: () async {
                if (visited) {
                  context.push(r.route);
                  return;
                }
                await ref.read(visitsProvider.notifier).markVisited(r.item.subjectType, r.item.subjectId);
                if (context.mounted) {
                  showSnack(
                    context,
                    '${r.title} marked as visited',
                    actionLabel: 'Undo',
                    onAction: () => ref.read(visitsProvider.notifier).unmark(r.item.subjectId),
                  );
                }
              },
            ),
            SizedBox(
              width: 56,
              height: 56,
              child: ClipRRect(borderRadius: AppRadius.smAll, child: r.cover),
            ),
            const SizedBox(width: AppSpace.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    r.title,
                    style: context.text.titleMedium?.copyWith(
                      decoration: visited ? TextDecoration.lineThrough : null,
                      color: visited ? context.palette.muted : null,
                    ),
                  ),
                  Text(r.subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.text.bodySmall),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}

class _FoodTab extends ConsumerWidget {
  const _FoodTab({required this.catalog});
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visited = ref.watch(visitsProvider).map((v) => v.subjectId).toSet();
    final spots = _resolve(catalog, ref.watch(bucketProvider)).where((r) => r.isFood).toList();
    final wishes = [...ref.watch(dishWishesProvider)]
      ..sort((a, b) => a.tried == b.tried ? b.addedAt.compareTo(a.addedAt) : (a.tried ? 1 : -1));
    return ListView(
      padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, 100),
      children: [
        SectionHeader(
          'Foods I Want to Try',
          subtitle: '${wishes.where((w) => w.tried).length} of ${wishes.length} tried',
          action: 'Add dish',
          onAction: () => _addDish(context, ref),
          padding: const EdgeInsets.only(top: AppSpace.lg, bottom: AppSpace.sm),
        ),
        if (wishes.isEmpty)
          Text('Add dishes from any state or destination page, or type your own.', style: context.text.bodySmall),
        for (final w in wishes)
          Dismissible(
            key: ValueKey(w.id),
            onDismissed: (_) => ref.read(dishWishesProvider.notifier).removeId(w.id),
            child: CheckboxListTile(
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: w.tried,
              onChanged: (_) => ref.read(dishWishesProvider.notifier).toggleTried(w),
              title: Text(
                catalog.dish(w.dishId)?.name ?? w.customName ?? 'Dish',
                style: TextStyle(decoration: w.tried ? TextDecoration.lineThrough : null),
              ),
              subtitle: Text(
                w.tried
                    ? 'Tried on ${formatShortDate(w.triedOn!)}'
                    : (catalog.region(catalog.dish(w.dishId)?.regionId)?.name ?? 'Added by you'),
              ),
            ),
          ),
        SectionHeader(
          'Saved Food Spots',
          subtitle: plural(spots.length, 'spot'),
          action: 'Food explorer',
          onAction: () => context.push(Routes.food),
          padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.sm),
        ),
        if (spots.isEmpty) Text('Bookmark a food spot to save it here.', style: context.text.bodySmall),
        for (final r in spots)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpace.sm),
            child: _BucketRow(resolved: r, visited: visited.contains(r.item.subjectId)),
          ),
      ],
    );
  }

  Future<void> _addDish(BuildContext context, WidgetRef ref) async {
    final c = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add a dish'),
        content: TextField(
          controller: c,
          autofocus: true,
          textCapitalization: TextCapitalization.words,
          decoration: const InputDecoration(hintText: 'e.g. Kozhikode Halwa'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, c.text), child: const Text('Add')),
        ],
      ),
    );
    c.dispose();
    if (name == null || name.trim().isEmpty) return;
    final match = catalog.dishes.where((d) => d.name.toLowerCase() == name.trim().toLowerCase()).firstOrNull;
    if (match != null) {
      await ref.read(dishWishesProvider.notifier).addDish(match.id);
    } else {
      await ref.read(dishWishesProvider.notifier).addCustom(name);
    }
  }
}
