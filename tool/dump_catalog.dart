// Dumps catalog places/destinations (id, name, context, coordinates) as JSON.
// Used by tool/fetch_wiki_media.py to look up freely licensed photos.
// Run: dart run tool/dump_catalog.dart > build/catalog.json
// ignore_for_file: avoid_print -- CLI tool that writes JSON to stdout.
import 'dart:convert';

import 'package:travel_explorer/data/mock/geo_data.dart';
import 'package:travel_explorer/data/mock/places_kerala.dart';
import 'package:travel_explorer/data/mock/places_north.dart';
import 'package:travel_explorer/data/mock/places_south.dart';

void main() {
  final regionName = {for (final r in regions) r.id: r.name};
  final destName = {for (final d in destinations) d.id: d.name};
  final out = [
    for (final d in destinations)
      {
        'id': d.id,
        'type': 'destination',
        'name': d.name,
        'context': regionName[d.regionId],
        'lat': d.center.lat,
        'lng': d.center.lng,
      },
    for (final p in [...keralaPlaces, ...southPlaces, ...northAndWorldPlaces])
      {
        'id': p.id,
        'type': p.kind.name,
        'name': p.name,
        'context': destName[p.destinationId],
        'lat': p.location.lat,
        'lng': p.location.lng,
      },
  ];
  print(const JsonEncoder.withIndent(' ').convert(out));
}
