import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/common.dart';
import '../widgets/common.dart';

/// Normalises user input into an http(s) URL, or null if it isn't a web link.
String? normaliseUrl(String input) {
  var s = input.trim();
  if (s.isEmpty) return null;
  if (!s.contains('://')) s = 'https://$s';
  final uri = Uri.tryParse(s);
  if (uri == null || !(uri.scheme == 'https' || uri.scheme == 'http') || !uri.host.contains('.')) return null;
  return uri.toString();
}

bool isMapLink(String url) {
  final h = Uri.tryParse(url)?.host ?? '';
  return h.contains('google.') || h.contains('goo.gl') || h.contains('maps.apple') || h.contains('openstreetmap');
}

bool isInstagramLink(String url) {
  final u = Uri.tryParse(url);
  return u != null && (u.host == 'instagram.com' || u.host.endsWith('.instagram.com') || u.host == 'instagr.am');
}

/// Extracts coordinates from full Google Maps URLs ("@lat,lng" or "q=lat,lng").
/// Short links (maps.app.goo.gl) can't be resolved offline and return null.
GeoPoint? coordinatesFromMapLink(String url) {
  final m = RegExp(r'(?:@|[?&](?:q|ll|query|destination)=)(-?\d{1,2}\.\d+),\s*(-?\d{1,3}\.\d+)').firstMatch(url);
  if (m == null) return null;
  final lat = double.parse(m.group(1)!), lng = double.parse(m.group(2)!);
  if (lat.abs() > 90 || lng.abs() > 180) return null;
  return GeoPoint(lat, lng);
}

Future<void> openExternal(BuildContext context, String url) async {
  try {
    final ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) showSnack(context, 'No app available to open this link');
  } catch (_) {
    if (context.mounted) showSnack(context, 'Could not open the link');
  }
}
