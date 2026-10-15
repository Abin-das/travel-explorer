/// Shared primitives used by both catalog and user-activity entities.
library;

typedef Json = Map<String, dynamic>;

/// Anything persisted in an [EntityStore] needs a stable id and a JSON form.
abstract interface class Identifiable {
  String get id;
  Json toJson();
}

/// A plain geographic coordinate (kept free of any map SDK types).
class GeoPoint {
  const GeoPoint(this.lat, this.lng);

  final double lat;
  final double lng;

  Json toJson() => {'lat': lat, 'lng': lng};
  factory GeoPoint.fromJson(Json j) => GeoPoint((j['lat'] as num).toDouble(), (j['lng'] as num).toDouble());

  @override
  bool operator ==(Object other) => other is GeoPoint && other.lat == lat && other.lng == lng;
  @override
  int get hashCode => Object.hash(lat, lng);
}

/// Where a piece of catalog data came from. Shown in the UI so that sample
/// content is never mistaken for verified, live information.
enum DataSource {
  /// Bundled, curated sample content shipped with the app.
  curatedSample,

  /// Created by this user on this device.
  userSubmitted,

  /// Reserved for a future backend.
  remote,
}

DateTime? parseDate(Object? v) => v is String ? DateTime.tryParse(v) : null;
String? dateToJson(DateTime? d) => d?.toIso8601String();

T enumByName<T extends Enum>(List<T> values, Object? name, T fallback) {
  for (final v in values) {
    if (v.name == name) return v;
  }
  return fallback;
}

List<String> stringList(Object? v) => v is List ? v.map((e) => e.toString()).toList() : const [];
