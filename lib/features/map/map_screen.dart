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
import '../../domain/entities/place.dart';
import '../../domain/entities/user_activity.dart';
import '../explore/destination_screen.dart' show styleFor;
import 'travel_map.dart';

/// Map tab: every place in the selected country, colour-coded.
class MapScreen extends ConsumerStatefulWidget {
  const MapScreen({super.key});

  @override
  ConsumerState<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends ConsumerState<MapScreen> {
  final _controller = MapController();
  final Set<MarkerStyle> _layers = {
    MarkerStyle.attraction,
    MarkerStyle.hiddenGem,
    MarkerStyle.food,
    MarkerStyle.visited,
    MarkerStyle.bucket,
  };
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final countryId = ref.watch(selectedCountryIdProvider);
    final visited = ref.watch(visitsProvider).map((v) => v.subjectId).toSet();
    final bucket = ref.watch(bucketProvider).map((b) => b.subjectId).toSet();
    return Scaffold(
      body: AsyncView(
        value: ref.watch(catalogProvider),
        builder: (cat) {
          final country = cat.country(countryId);
          final pins = <MapPin>[];
          for (final p in cat.placesIn(countryId: countryId)) {
            final style = styleFor(p, visited, bucket);
            if (_layers.contains(style)) pins.add(MapPin(id: p.id, point: p.location, style: style, label: p.name));
          }
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
                              Expanded(child: Text('${pins.length} places on the map', style: context.text.titleSmall)),
                              IconButton(
                                tooltip: 'Jump to a destination',
                                icon: const Icon(Icons.my_location_rounded),
                                onPressed: () => _jump(cat, countryId),
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
                            for (final s in MarkerStyle.values.where((s) => s != MarkerStyle.pin))
                              Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: FilterChip(
                                  selected: _layers.contains(s),
                                  showCheckmark: false,
                                  avatar: Icon(s.icon, size: 16, color: _layers.contains(s) ? Colors.white : s.color),
                                  label: Text(s.label),
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
                const Center(
                  child: Card(
                    child: Padding(
                      padding: EdgeInsets.all(AppSpace.lg),
                      child: Text('No places for the selected layers'),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _jump(Catalog cat, String countryId) {
    final dests = cat.destinationsIn(countryId: countryId);
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
            for (final d in dests)
              ListTile(
                leading: const Icon(Icons.place_rounded),
                title: Text(d.name),
                subtitle: Text(cat.destinationLocation(d)),
                onTap: () {
                  Navigator.pop(ctx);
                  _controller.move(toLatLng(d.center), 10.5);
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _openSheet(Catalog cat, MapPin pin) async {
    final p = cat.place(pin.id);
    if (p == null) return;
    setState(() => _selected = p.id);
    await showModalBottomSheet<void>(
      context: context,
      builder: (ctx) => _PlaceSheet(place: p, catalog: cat),
    );
    if (mounted) setState(() => _selected = null);
  }
}

class _PlaceSheet extends ConsumerWidget {
  const _PlaceSheet({required this.place, required this.catalog});
  final Place place;
  final Catalog catalog;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final visit = ref.watch(visitForProvider(place.id));
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
                          Pill(label: place.kind.label, icon: place.kind.icon, color: place.kind.color),
                          visit != null
                              ? const Pill(label: 'Visited', icon: Icons.check_rounded, color: AppColors.visited)
                              : const Pill(label: 'Not visited yet', color: AppColors.slate),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(place.name, style: context.text.titleLarge),
                      Text(catalog.placeLocation(place), style: context.text.bodySmall),
                      if (place.categories.isNotEmpty)
                        Text(
                          place.categories.map((c) => c.label).join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: context.text.labelSmall,
                        ),
                    ],
                  ),
                ),
                BookmarkButton(type: SubjectType.place, id: place.id, onImage: false),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
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
