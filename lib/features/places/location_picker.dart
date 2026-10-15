import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_theme.dart';
import '../../domain/entities/common.dart';
import '../map/travel_map.dart';

/// Full-screen map where the user taps to drop a pin. Returns the point.
class LocationPickerScreen extends StatefulWidget {
  const LocationPickerScreen({super.key, required this.initial, this.hasInitialPin = false});
  final GeoPoint initial;
  final bool hasInitialPin;

  static Future<GeoPoint?> open(BuildContext context, GeoPoint initial, {bool hasPin = false}) =>
      Navigator.of(context, rootNavigator: true).push<GeoPoint>(
        MaterialPageRoute(
          fullscreenDialog: true,
          builder: (_) => LocationPickerScreen(initial: initial, hasInitialPin: hasPin),
        ),
      );

  @override
  State<LocationPickerScreen> createState() => _LocationPickerScreenState();
}

class _LocationPickerScreenState extends State<LocationPickerScreen> {
  late GeoPoint? _pin = widget.hasInitialPin ? widget.initial : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Drop a pin')),
      body: Stack(
        children: [
          TravelMap(
            center: widget.initial,
            zoom: widget.hasInitialPin ? 13 : 9,
            onTap: (p) => setState(() => _pin = p),
            pins: [if (_pin != null) MapPin(id: 'pin', point: _pin!, style: MarkerStyle.pin)],
            selectedId: 'pin',
          ),
          Positioned(
            left: AppSpace.lg,
            right: AppSpace.lg,
            top: AppSpace.lg,
            child: Material(
              elevation: 2,
              borderRadius: AppRadius.mdAll,
              color: context.palette.card,
              child: Padding(
                padding: const EdgeInsets.all(AppSpace.md),
                child: Text(
                  _pin == null
                      ? 'Tap the map where the place is. Map tiles need an internet connection.'
                      : 'Pinned at ${_pin!.lat.toStringAsFixed(5)}, ${_pin!.lng.toStringAsFixed(5)}',
                  style: context.text.bodyMedium,
                ),
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.all(AppSpace.lg),
        child: FilledButton.icon(
          onPressed: _pin == null ? null : () => Navigator.pop(context, _pin),
          icon: const Icon(Icons.check_rounded),
          label: const Text('Use this location'),
        ),
      ),
    );
  }
}
