import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:latlong2/latlong.dart';

import '../../application/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../domain/entities/common.dart';

LatLng toLatLng(GeoPoint p) => LatLng(p.lat, p.lng);

/// Marker styles from the spec.
enum MarkerStyle {
  visited(AppColors.visited, Icons.check_rounded, 'Visited'),
  attraction(AppColors.attraction, Icons.place_rounded, 'Attraction'),
  hiddenGem(AppColors.hiddenGem, Icons.diamond_rounded, 'Hidden Gem'),
  food(AppColors.foodSpot, Icons.restaurant_rounded, 'Food Spot'),
  bucket(AppColors.bucket, Icons.bookmark_rounded, 'Bucket List'),
  pin(AppColors.danger, Icons.push_pin_rounded, 'Pin');

  const MarkerStyle(this.color, this.icon, this.label);
  final Color color;
  final IconData icon;
  final String label;
}

class MapPin {
  const MapPin({required this.id, required this.point, required this.style, this.label});
  final String id;
  final GeoPoint point;
  final MarkerStyle style;
  final String? label;
}

/// Map wrapper. Tiles come from [mapTileConfigProvider] (OpenStreetMap by
/// default — no API key). Markers keep working when tiles cannot load.
class TravelMap extends ConsumerWidget {
  const TravelMap({
    super.key,
    required this.pins,
    required this.center,
    this.zoom = 11,
    this.onPinTap,
    this.onTap,
    this.controller,
    this.interactive = true,
    this.selectedId,
  });

  final List<MapPin> pins;
  final GeoPoint center;
  final double zoom;
  final ValueChanged<MapPin>? onPinTap;
  final ValueChanged<GeoPoint>? onTap;
  final MapController? controller;
  final bool interactive;
  final String? selectedId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tiles = ref.watch(mapTileConfigProvider);
    final dark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: dark ? const Color(0xFF1B2A2E) : const Color(0xFFE4EEEA),
      child: FlutterMap(
        mapController: controller,
        options: MapOptions(
          initialCenter: toLatLng(center),
          initialZoom: zoom,
          minZoom: 2,
          maxZoom: tiles.maxZoom,
          backgroundColor: Colors.transparent,
          interactionOptions: InteractionOptions(
            flags: interactive ? InteractiveFlag.all & ~InteractiveFlag.rotate : InteractiveFlag.none,
          ),
          onTap: onTap == null ? null : (_, ll) => onTap!(GeoPoint(ll.latitude, ll.longitude)),
        ),
        children: [
          if (tiles.urlTemplate != null)
            TileLayer(
              urlTemplate: tiles.urlTemplate,
              subdomains: tiles.subdomains,
              userAgentPackageName: 'com.travelexplorer.travel_explorer',
              maxZoom: tiles.maxZoom,
              maxNativeZoom: tiles.maxZoom.toInt(),
              // 256-px tiles look soft on high-density screens; retina mode loads
              // the next zoom level at half size so detail matches the display.
              retinaMode: RetinaMode.isHighDensity(context),
              // Keep a ring of tiles around the viewport so panning doesn't flash
              // low-resolution placeholders.
              keepBuffer: 3,
              panBuffer: 1,
              tileBuilder: dark
                  ? (context, tile, _) => ColorFiltered(
                      colorFilter: const ColorFilter.matrix([
                        -0.6, 0, 0, 0, 200, //
                        0, -0.6, 0, 0, 210,
                        0, 0, -0.6, 0, 210,
                        0, 0, 0, 1, 0,
                      ]),
                      child: tile,
                    )
                  : null,
            ),
          MarkerLayer(
            markers: [
              for (final p in pins)
                Marker(
                  point: toLatLng(p.point),
                  width: p.id == selectedId ? 52 : 40,
                  height: p.id == selectedId ? 52 : 40,
                  alignment: Alignment.topCenter,
                  child: GestureDetector(
                    onTap: onPinTap == null ? null : () => onPinTap!(p),
                    child: _PinIcon(style: p.style, selected: p.id == selectedId, label: p.label),
                  ),
                ),
            ],
          ),
          if (tiles.attribution.isNotEmpty)
            RichAttributionWidget(
              showFlutterMapAttribution: false,
              attributions: [TextSourceAttribution(tiles.attribution)],
            ),
        ],
      ),
    );
  }
}

class _PinIcon extends StatelessWidget {
  const _PinIcon({required this.style, required this.selected, this.label});
  final MarkerStyle style;
  final bool selected;
  final String? label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label == null ? style.label : '$label, ${style.label}',
      button: true,
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Icon(
            Icons.location_on,
            color: style.color,
            size: selected ? 52 : 40,
            shadows: const [Shadow(color: Colors.black38, blurRadius: 6, offset: Offset(0, 2))],
          ),
          Positioned(
            top: selected ? 10 : 8,
            child: Icon(style.icon, color: Colors.white, size: selected ? 18 : 14),
          ),
        ],
      ),
    );
  }
}

class MapLegend extends StatelessWidget {
  const MapLegend({super.key});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 4,
      children: [
        for (final s in MarkerStyle.values.where((s) => s != MarkerStyle.pin))
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(color: s.color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 4),
              Text(s.label, style: Theme.of(context).textTheme.labelSmall),
            ],
          ),
      ],
    );
  }
}
