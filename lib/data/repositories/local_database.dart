import 'package:hive_ce_flutter/hive_flutter.dart';

import '../../domain/entities/place.dart';
import '../../domain/entities/user_activity.dart';
import 'hive_stores.dart';

/// Opens every local box once at startup and exposes typed stores.
class LocalDatabase {
  LocalDatabase._(this._boxes);

  static const _names = ['visits', 'memories', 'notes', 'bucket', 'dishes', 'trips', 'custom_places', 'links', 'prefs'];

  final Map<String, Box<String>> _boxes;

  static Future<LocalDatabase> open() async {
    await Hive.initFlutter('travel_explorer');
    final boxes = <String, Box<String>>{};
    for (final n in _names) {
      boxes[n] = await Hive.openBox<String>(n);
    }
    return LocalDatabase._(boxes);
  }

  /// In-memory database for tests.
  static Future<LocalDatabase> openForTest(String path) async {
    Hive.init(path);
    final boxes = <String, Box<String>>{};
    for (final n in _names) {
      boxes[n] = await Hive.openBox<String>('${n}_${DateTime.now().microsecondsSinceEpoch}');
    }
    return LocalDatabase._(boxes);
  }

  late final visits = HiveEntityStore<Visit>(_boxes['visits']!, Visit.fromJson);
  late final memories = HiveEntityStore<TravelMemory>(_boxes['memories']!, TravelMemory.fromJson);
  late final notes = HiveEntityStore<PlaceNote>(_boxes['notes']!, PlaceNote.fromJson);
  late final bucket = HiveEntityStore<BucketItem>(_boxes['bucket']!, BucketItem.fromJson);
  late final dishWishes = HiveEntityStore<DishWish>(_boxes['dishes']!, DishWish.fromJson);
  late final trips = HiveEntityStore<Trip>(_boxes['trips']!, Trip.fromJson);
  late final links = HiveEntityStore<PlaceLinks>(_boxes['links']!, PlaceLinks.fromJson);
  late final customPlaces = HiveEntityStore<Place>(_boxes['custom_places']!, Place.fromJson);

  late final settings = HiveValueStore<AppSettings>(
    _boxes['prefs']!,
    'settings',
    AppSettings.fromJson,
    (v) => v.toJson(),
    const AppSettings(),
  );
  late final profile = HiveValueStore<UserProfile>(
    _boxes['prefs']!,
    'profile',
    UserProfile.fromJson,
    (v) => v.toJson(),
    const UserProfile(),
  );

  /// Wipes every piece of user data (catalog content is bundled, so it stays).
  Future<void> clearAll() async {
    for (final b in _boxes.values) {
      await b.clear();
    }
  }
}
