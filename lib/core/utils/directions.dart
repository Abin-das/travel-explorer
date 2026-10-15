import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/common.dart';
import '../widgets/common.dart';

/// Opens the device's navigation app (Google Maps / Apple Maps / browser).
Future<void> openDirections(BuildContext context, GeoPoint to, {String? label}) async {
  final uri = Uri.parse('https://www.google.com/maps/dir/?api=1&destination=${to.lat},${to.lng}');
  try {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showSnack(context, 'No app available to open directions');
  } catch (_) {
    if (context.mounted) showSnack(context, 'Could not open directions');
  }
}
