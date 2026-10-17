import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../application/catalog.dart';
import '../../application/providers.dart';
import '../../core/router/routes.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/directions.dart';
import '../../core/utils/labels.dart';
import '../../core/widgets/cards.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/media.dart';
import '../../domain/entities/common.dart';
import '../../domain/entities/geography.dart';
import '../../domain/entities/place.dart';
import '../../domain/entities/user_activity.dart';
import '../travels/memory_widgets.dart';
import 'travel_map.dart';

/// Pin ids for destinations are prefixed so they don't collide with places.
const _destPrefix = 'dest:';

/// Map tab: only the user's own places — where they've been (shown with
/// their memory photos) and what's on their bucket list.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  static const _layerStyles = [MarkerStyle.visited, MarkerStyle.bucket];

  final _controller = MapController();
  final Set<MarkerStyle> _layers = {..._layerStyles};
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final countryId = ref.watch(selectedCountryIdProvider);
    final visits = ref.watch(visitsProvider);
    final bucket = ref.watch(bucketProvider);
    final memories = ref.watch(memoriesProvider);
    return Scaffold(
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) {
          final country = cat.country(countryId);

          // Latest memory photo per place, used as its marker.
          final covers = <String, String>{};
          for (final m in [...memories]..sort((a, b) => b.date.compareTo(a.date))) {
            if (m.photos.isNotEmpty) covers.putIfAbsent(m.placeId, () => m.photos.first.path);
          }

          final visitedIds = {for (final v in visits) v.subjectId};
          final all = <MapPin>[
            for (final v in visits) ?_pinFor(cat, v.subjectType, v.subjectId, MarkerStyle.visited, covers),
            for (final b in bucket.where((b) => !visitedIds.contains(b.subjectId)))
              ?_pinFor(cat, b.subjectType, b.subjectId, MarkerStyle.bucket, covers),
          ];
          final pins = all.where((p) => _layers.contains(p.style)).toList();

          return Stack(
            children: [
              TravelMap(
                key: ValueKey(countryId),
                controller: _controller,
                center: country?.center ?? const GeoPoint(20, 0),
                zoom: countryId == 'in' ? 4.6 : 5,
                pins: pins,
                selectedId: _selected,
                onPinTap: (pin) => _openSheet(cat, pin),
              ),
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpace.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: context.palette.card,
                        elevation: 3,
                        borderRadius: AppRadius.mdAll,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(AppSpace.md, AppSpace.sm, AppSpace.sm, AppSpace.sm),
                          child: Row(
                            children: [
                              Text('${country?.flag ?? ''}  ', style: const TextStyle(fontSize: 20)),
                              Expanded(
                                child: Text(
                                  pins.length == 1 ? '1 of your places' : '${pins.length} of your places',
                                  style: context.text.titleSmall,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Jump to one of your places',
                                icon: const Icon(Icons.my_location_rounded),
                                onPressed: () => _jump(cat, countryId, all),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpace.sm),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            for (final s in _layerStyles)
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  selected: _layers.contains(s),
                                  showCheckmark: false,
                                  avatar: Icon(s.icon, size: 16, color: _layers.contains(s) ? Colors.white : s.color),
                                  label: Text(
                                    '${s == MarkerStyle.visited ? 'Places I went' : s.label} · '
                                    '${all.where((p) => p.style == s).length}',
                                  ),
                                  labelStyle: context.text.labelMedium?.copyWith(
                                    color: _layers.contains(s) ? Colors.white : context.colors.onSurface,
                                  ),
                                  selectedColor: s.color,
                                  backgroundColor: context.palette.card,
                                  elevation: 2,
                                  onSelected: (v) => setState(() => v ? _layers.add(s) : _layers.remove(s)),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (pins.isEmpty)
                Center(
                  child: Card(
                    margin: const EdgeInsets.all(AppSpace.gutter),
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpace.lg),
                      child: Text(
                        all.isEmpty
                            ? 'Mark places as visited or add them to your bucket list to see them here.'
                            : 'No places for the selected layers',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  MapPin? _pinFor(Catalog cat, SubjectType type, String id, MarkerStyle style, Map<String, String> covers) {
    switch (type) {
      case SubjectType.place:
        final p = cat.place(id);
        if (p == null) return null;
        return MapPin(
          id: p.id,
          point: p.location,
          style: style,
          label: p.name,
          photoPath: style == MarkerStyle.visited ? covers[p.id] : null,
        );
      case SubjectType.destination:
        final d = cat.destination(id);
        if (d == null) return null;
        return MapPin(id: '$_destPrefix${d.id}', point: d.center, style: style, label: d.name);
    }
  }

  void _jump(Catalog cat, String countryId, List<MapPin> pins) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        builder: (ctx, sc) => ListView(
          controller: sc,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.sm),
              child: Text('Jump to', style: ctx.text.titleLarge),
            ),
            ListTile(
              leading: const Icon(Icons.public_rounded),
              title: const Text('Whole country'),
              onTap: () {
                Navigator.pop(ctx);
                final c = cat.country(countryId);
                if (c != null) _controller.move(toLatLng(c.center), 4.6);
              },
            ),
            for (final p in pins)
              ListTile(
                leading: Icon(p.style.icon, color: p.style.color),
                title: Text(p.label ?? ''),
                subtitle: Text(p.style == MarkerStyle.visited ? 'Visited' : 'Bucket list'),
                onTap: () {
                  Navigator.pop(ctx);
                  _controller.move(toLatLng(p.point), 12);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(Catalog cat, MapPin pin) async {
    final Widget sheet;
    if (pin.id.startsWith(_destPrefix)) {
      final d = cat.destination(pin.id.substring(_destPrefix.length));
      if (d == null) return;
      sheet = _DestinationSheet(destination: d, catalog: cat);
    } else {
      final p = cat.place(pin.id);
      if (p == null) return;
      sheet = _PlaceSheet(place: p, catalog: cat, onSeeAllMemories: () => _openMemories(p));
    }
    setState(() => _selected = pin.id);
    await showModalBottomSheet<void>(context: context, isScrollControlled: true, builder: (_) => sheet);
    if (mounted) setState(() => _selected = null);
  }

  void _openMemories(Place place) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _MemoriesSheet(place: place),
    );
  }
}

class _PlaceSheet extends ConsumerWidget {
  const _PlaceSheet({required this.place, required this.catalog, required this.onSeeAllMemories});
  final Place place;
  final Catalog catalog;
  final VoidCallback onSeeAllMemories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(visitForProvider(place.id));
    final memories = ref.watch(memoriesForPlaceProvider(place.id));
    final photos = [for (final m in memories) ...m.photos];
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (photos.isNotEmpty) ...[_PhotoStrip(photos: photos), const SizedBox(height: AppSpace.md)],
            Row(
              children: [
                if (photos.isEmpty) ...[
                  SizedBox(
                    width: 96,
                    height: 96,
                    child: ClipRRect(
                      borderRadius: AppRadius.mdAll,
                      child: PlaceCover(place: place),
                    ),
                  ),
                  const SizedBox(width: AppSpace.md),
                ],
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: [
                          Pill(label: place.kind.label, icon: place.kind.icon, color: place.kind.color),
                          visit != null
                              ? Pill(
                                  label: 'Visited ${formatShortDate(visit.visitedOn)}',
                                  icon: Icons.check_rounded,
                                  color: AppColors.visited,
                                )
                              : const Pill(label: 'Bucket list', icon: Icons.bookmark_rounded, color: AppColors.bucket),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(place.name, style: context.text.titleLarge),
                      Text(catalog.placeLocation(place), style: context.text.bodySmall),
                    ],
                  ),
                ),
                BookmarkButton(type: SubjectType.place, id: place.id, onImage: false),
              ],
            ),
            if (visit != null) ...[
              const SizedBox(height: AppSpace.sm),
              memories.isEmpty
                  ? TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        context.push(Routes.newMemory(place.id));
                      },
                      icon: const Icon(Icons.add_photo_alternate_rounded),
                      label: const Text('Add a memory'),
                    )
                  : TextButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        onSeeAllMemories();
                      },
                      icon: const Icon(Icons.photo_library_rounded),
                      label: Text(
                        'See all ${memories.length == 1 ? '1 memory' : '${memories.length} memories'}'
                        ' · ${photos.length} photo${photos.length == 1 ? '' : 's'}',
                      ),
                    ),
            ],
            const SizedBox(height: AppSpace.md),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openDirections(context, place.location),
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text('Directions'),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(Routes.place(place.id));
                    },
                    child: const Text('View details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The top few memory photos of a place; tapping one opens the full gallery.
class _PhotoStrip extends StatelessWidget {
  const _PhotoStrip({required this.photos});
  final List<TravelPhoto> photos;

  static const _max = 6;

  @override
  Widget build(BuildContext context) {
    final shown = photos.take(_max).toList();
    final extra = photos.length - shown.length;
    return SizedBox(
      height: 120,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: shown.length,
        separatorBuilder: (_, _) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (context, i) => GestureDetector(
          onTap: () => PhotoViewer.open(context, photos, i),
          child: ClipRRect(
            borderRadius: AppRadius.mdAll,
            child: SizedBox(
              width: i == 0 ? 160 : 120,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  LocalPhoto(path: shown[i].path, cacheWidth: 400),
                  if (extra > 0 && i == shown.length - 1)
                    ColoredBox(
                      color: Colors.black54,
                      child: Center(
                        child: Text('+$extra', style: context.text.titleLarge?.copyWith(color: Colors.white)),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Every memory recorded at a place.
class _MemoriesSheet extends ConsumerWidget {
  const _MemoriesSheet({required this.place});
  final Place place;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final memories = ref.watch(memoriesForPlaceProvider(place.id));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.95,
      builder: (ctx, sc) => CustomScrollView(
        controller: sc,
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.md),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Memories', style: ctx.text.titleLarge),
                  Text(place.name, style: ctx.text.bodySmall),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.xl),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 260,
                mainAxisExtent: 250,
                mainAxisSpacing: AppSpace.md,
                crossAxisSpacing: AppSpace.md,
              ),
              itemCount: memories.length,
              itemBuilder: (_, i) => MemoryCard(
                memory: memories[i],
                onTap: () {
                  Navigator.pop(ctx);
                  context.push(Routes.memory(memories[i].id));
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DestinationSheet extends StatelessWidget {
  const _DestinationSheet({required this.destination, required this.catalog});
  final Destination destination;
  final Catalog catalog;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(AppSpace.gutter, 0, AppSpace.gutter, AppSpace.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 96,
                  height: 96,
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
                      const Pill(label: 'Destination', icon: Icons.location_city_rounded, color: AppColors.slate),
                      const SizedBox(height: 6),
                      Text(destination.name, style: context.text.titleLarge),
                      Text(catalog.destinationLocation(destination), style: context.text.bodySmall),
                    ],
                  ),
                ),
                BookmarkButton(type: SubjectType.destination, id: destination.id, onImage: false),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => openDirections(context, destination.center),
                    icon: const Icon(Icons.directions_rounded),
                    label: const Text('Directions'),
                  ),
                ),
                const SizedBox(width: AppSpace.md),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      Navigator.pop(context);
                      context.push(Routes.destination(destination.id));
                    },
                    child: const Text('View details'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
