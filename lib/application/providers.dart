import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../data/repositories/bundled_catalog_repository.dart';
import '../data/repositories/local_database.dart';
import '../data/services/integration_points.dart';
import '../data/services/photo_storage.dart';
import '../domain/entities/common.dart';
import '../domain/entities/place.dart';
import '../domain/entities/user_activity.dart';
import '../domain/repositories/repositories.dart';
import 'catalog.dart';

const uuid = Uuid();

// ---------------------------------------------------------------------------
// Infrastructure (overridden in main.dart once storage is opened)
// ---------------------------------------------------------------------------

final localDatabaseProvider = Provider<LocalDatabase>((ref) => throw UnimplementedError('Override in main'));
final photoStorageProvider = Provider<PhotoStorage>((ref) => throw UnimplementedError('Override in main'));
final catalogRepositoryProvider = Provider<CatalogRepository>((ref) => const BundledCatalogRepository());
final weatherServiceProvider = Provider<WeatherService>((ref) => const CuratedSeasonWeather());
final mapTileConfigProvider = Provider<MapTileConfig>((ref) => MapTileConfig.openStreetMap);

/// When false, network photos are replaced by local artwork (tests, a future
/// data-saver setting).
final remoteImagesEnabledProvider = Provider<bool>((ref) => true);

// ---------------------------------------------------------------------------
// Catalog
// ---------------------------------------------------------------------------

final catalogDataProvider = FutureProvider<CatalogData>((ref) => ref.watch(catalogRepositoryProvider).load());

/// The merged catalog (bundled + user-submitted places).
final catalogProvider = Provider<AsyncValue<Catalog>>((ref) {
  final custom = ref.watch(customPlacesProvider);
  return ref.watch(catalogDataProvider).whenData((d) => Catalog(d, custom));
});

// ---------------------------------------------------------------------------
// Generic persisted list
// ---------------------------------------------------------------------------

abstract class EntityListNotifier<T extends Identifiable> extends Notifier<List<T>> {
  EntityStore<T> get store;

  @override
  List<T> build() => store.readAll();

  Future<void> put(T item) async {
    final next = [...state];
    final i = next.indexWhere((e) => e.id == item.id);
    if (i < 0) {
      next.add(item);
    } else {
      next[i] = item;
    }
    state = next;
    await store.upsert(item);
  }

  Future<void> removeId(String id) async {
    state = state.where((e) => e.id != id).toList();
    await store.remove(id);
  }
}

// ---------------------------------------------------------------------------
// Settings & profile
// ---------------------------------------------------------------------------

class SettingsNotifier extends Notifier<AppSettings> {
  ValueStore<AppSettings> get _store => ref.read(localDatabaseProvider).settings;

  @override
  AppSettings build() => _store.read();

  Future<void> _save(AppSettings s) async {
    state = s;
    await _store.write(s);
  }

  Future<void> selectCountry(String id) => _save(state.copyWith(countryId: id));
  Future<void> setThemeMode(ThemeMode m) => _save(state.copyWith(themeMode: m));
  Future<void> setTripReminders(bool v) => _save(state.copyWith(tripReminders: v));
  Future<void> setSeasonTips(bool v) => _save(state.copyWith(seasonTips: v));
  Future<void> setShowStats(bool v) => _save(state.copyWith(showStatsOnProfile: v));

  Future<void> recordRecent(String destinationId) {
    final list = [destinationId, ...state.recentDestinationIds.where((e) => e != destinationId)].take(10).toList();
    return _save(state.copyWith(recentDestinationIds: list));
  }
}

final settingsProvider = NotifierProvider<SettingsNotifier, AppSettings>(SettingsNotifier.new);

/// The active country; India until the user chooses otherwise.
final selectedCountryIdProvider = Provider<String>((ref) => ref.watch(settingsProvider).countryId ?? 'in');

class ProfileNotifier extends Notifier<UserProfile> {
  ValueStore<UserProfile> get _store => ref.read(localDatabaseProvider).profile;

  @override
  UserProfile build() => _store.read();

  Future<void> save(UserProfile p) async {
    final old = state.avatarPath;
    state = p;
    await _store.write(p);
    if (old != null && old != p.avatarPath) await ref.read(photoStorageProvider).delete(old);
  }
}

final profileProvider = NotifierProvider<ProfileNotifier, UserProfile>(ProfileNotifier.new);

// ---------------------------------------------------------------------------
// Visits
// ---------------------------------------------------------------------------

class VisitsNotifier extends EntityListNotifier<Visit> {
  @override
  EntityStore<Visit> get store => ref.read(localDatabaseProvider).visits;

  Visit? forSubject(String subjectId) => state.where((v) => v.subjectId == subjectId).firstOrNull;

  Future<Visit> markVisited(SubjectType type, String subjectId, {DateTime? on, int? rating}) async {
    final existing = forSubject(subjectId);
    final visit =
        existing?.copyWith(visitedOn: on, rating: rating) ??
        Visit(
          id: uuid.v4(),
          subjectType: type,
          subjectId: subjectId,
          visitedOn: on ?? DateTime.now(),
          createdAt: DateTime.now(),
          rating: rating,
        );
    await put(visit);
    return visit;
  }

  /// Removes the visit and the memories (and photo files) attached to it.
  Future<void> unmark(String subjectId) async {
    final v = forSubject(subjectId);
    if (v == null) return;
    await ref.read(memoriesProvider.notifier).deleteForVisit(v.id);
    await removeId(v.id);
  }
}

final visitsProvider = NotifierProvider<VisitsNotifier, List<Visit>>(VisitsNotifier.new);

final visitForProvider = Provider.family<Visit?, String>(
  (ref, subjectId) => ref.watch(visitsProvider).where((v) => v.subjectId == subjectId).firstOrNull,
);

// ---------------------------------------------------------------------------
// Notes
// ---------------------------------------------------------------------------

class NotesNotifier extends EntityListNotifier<PlaceNote> {
  @override
  EntityStore<PlaceNote> get store => ref.read(localDatabaseProvider).notes;

  Future<void> setNote(String placeId, String text) {
    if (text.trim().isEmpty) return removeId(placeId);
    return put(PlaceNote(placeId: placeId, text: text.trim(), updatedAt: DateTime.now()));
  }
}

final notesProvider = NotifierProvider<NotesNotifier, List<PlaceNote>>(NotesNotifier.new);
final noteForProvider = Provider.family<PlaceNote?, String>(
  (ref, id) => ref.watch(notesProvider).where((n) => n.placeId == id).firstOrNull,
);

// ---------------------------------------------------------------------------
// Memories & photos
// ---------------------------------------------------------------------------

class MemoriesNotifier extends EntityListNotifier<TravelMemory> {
  @override
  EntityStore<TravelMemory> get store => ref.read(localDatabaseProvider).memories;

  /// Saves a memory, ensuring the place is marked visited (a memory always
  /// belongs to a visit). Photo files removed from the memory are deleted.
  Future<TravelMemory> save({
    String? id,
    required String placeId,
    required String title,
    required DateTime date,
    required String note,
    int? rating,
    required List<TravelPhoto> photos,
  }) async {
    final visits = ref.read(visitsProvider.notifier);
    final visit = visits.forSubject(placeId) ?? await visits.markVisited(SubjectType.place, placeId, on: date);
    final existing = id == null ? null : state.where((m) => m.id == id).firstOrNull;
    if (existing != null) {
      final keep = photos.map((p) => p.id).toSet();
      for (final p in existing.photos.where((p) => !keep.contains(p.id))) {
        await ref.read(photoStorageProvider).delete(p.path);
      }
    }
    final memory = TravelMemory(
      id: existing?.id ?? uuid.v4(),
      visitId: visit.id,
      placeId: placeId,
      title: title.trim().isEmpty ? 'Untitled memory' : title.trim(),
      date: date,
      note: note.trim(),
      rating: rating,
      photos: photos,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    await put(memory);
    return memory;
  }

  Future<void> delete(String id) async {
    final m = state.where((e) => e.id == id).firstOrNull;
    if (m == null) return;
    for (final p in m.photos) {
      await ref.read(photoStorageProvider).delete(p.path);
    }
    await removeId(id);
  }

  Future<void> deleteForVisit(String visitId) async {
    for (final m in state.where((m) => m.visitId == visitId).toList()) {
      await delete(m.id);
    }
  }
}

final memoriesProvider = NotifierProvider<MemoriesNotifier, List<TravelMemory>>(MemoriesNotifier.new);

final memoriesForPlaceProvider = Provider.family<List<TravelMemory>, String>(
  (ref, placeId) =>
      ref.watch(memoriesProvider).where((m) => m.placeId == placeId).toList()..sort((a, b) => b.date.compareTo(a.date)),
);

final allPhotosProvider = Provider<List<(TravelPhoto, TravelMemory)>>(
  (ref) => [
    for (final m in ref.watch(memoriesProvider))
      for (final p in m.photos) (p, m),
  ]..sort((a, b) => b.$2.date.compareTo(a.$2.date)),
);

/// The most recent user photo of a place, used as its cover image.
final coverPhotoForProvider = Provider.family<TravelPhoto?, String>((ref, placeId) {
  final mems = ref.watch(memoriesForPlaceProvider(placeId));
  for (final m in mems) {
    if (m.photos.isNotEmpty) return m.photos.first;
  }
  return null;
});

// ---------------------------------------------------------------------------
// Bucket list & dishes
// ---------------------------------------------------------------------------

class BucketNotifier extends EntityListNotifier<BucketItem> {
  @override
  EntityStore<BucketItem> get store => ref.read(localDatabaseProvider).bucket;

  bool contains(String subjectId) => state.any((b) => b.subjectId == subjectId);

  /// Returns true if the item is now on the list.
  Future<bool> toggle(SubjectType type, String subjectId) async {
    final existing = state.where((b) => b.subjectId == subjectId).firstOrNull;
    if (existing != null) {
      await removeId(existing.id);
      return false;
    }
    await put(BucketItem(id: uuid.v4(), subjectType: type, subjectId: subjectId, addedAt: DateTime.now()));
    return true;
  }
}

final bucketProvider = NotifierProvider<BucketNotifier, List<BucketItem>>(BucketNotifier.new);
final isBucketedProvider = Provider.family<bool, String>(
  (ref, id) => ref.watch(bucketProvider).any((b) => b.subjectId == id),
);

class DishWishNotifier extends EntityListNotifier<DishWish> {
  @override
  EntityStore<DishWish> get store => ref.read(localDatabaseProvider).dishWishes;

  bool hasDish(String dishId) => state.any((d) => d.dishId == dishId);

  Future<void> addDish(String dishId) async {
    if (hasDish(dishId)) return;
    await put(DishWish(id: uuid.v4(), dishId: dishId, addedAt: DateTime.now()));
  }

  Future<void> addCustom(String name) => put(DishWish(id: uuid.v4(), customName: name.trim(), addedAt: DateTime.now()));

  Future<void> toggleTried(DishWish d) => put(d.withTried(d.tried ? null : DateTime.now()));
}

final dishWishesProvider = NotifierProvider<DishWishNotifier, List<DishWish>>(DishWishNotifier.new);

// ---------------------------------------------------------------------------
// Trips
// ---------------------------------------------------------------------------

class TripsNotifier extends EntityListNotifier<Trip> {
  @override
  EntityStore<Trip> get store => ref.read(localDatabaseProvider).trips;

  Future<Trip> create({
    required String title,
    required String destinationId,
    required DateTime start,
    required int days,
  }) async {
    final trip = Trip(
      id: uuid.v4(),
      title: title.trim().isEmpty ? 'My trip' : title.trim(),
      destinationId: destinationId,
      startDate: start,
      days: [for (var i = 0; i < days; i++) TripDay(id: uuid.v4(), activities: const [])],
      createdAt: DateTime.now(),
    );
    await put(trip);
    return trip;
  }

  Future<void> delete(String id) => removeId(id);
}

final tripsProvider = NotifierProvider<TripsNotifier, List<Trip>>(TripsNotifier.new);
final tripProvider = Provider.family<Trip?, String>(
  (ref, id) => ref.watch(tripsProvider).where((t) => t.id == id).firstOrNull,
);

// ---------------------------------------------------------------------------
// User-submitted places
// ---------------------------------------------------------------------------

class CustomPlacesNotifier extends EntityListNotifier<Place> {
  @override
  EntityStore<Place> get store => ref.read(localDatabaseProvider).customPlaces;

  Future<void> save(Place p) => put(p);

  Future<void> delete(String id) async {
    await ref.read(visitsProvider.notifier).unmark(id);
    final b = ref.read(bucketProvider).where((e) => e.subjectId == id).firstOrNull;
    if (b != null) await ref.read(bucketProvider.notifier).removeId(b.id);
    await ref.read(notesProvider.notifier).removeId(id);
    await ref.read(linksProvider.notifier).removeId(id);
    await removeId(id);
  }
}

final customPlacesProvider = NotifierProvider<CustomPlacesNotifier, List<Place>>(CustomPlacesNotifier.new);

// ---------------------------------------------------------------------------
// Personal links (map link, reels)
// ---------------------------------------------------------------------------

class LinksNotifier extends EntityListNotifier<PlaceLinks> {
  @override
  EntityStore<PlaceLinks> get store => ref.read(localDatabaseProvider).links;

  Future<void> save(PlaceLinks links) => links.isEmpty ? removeId(links.placeId) : put(links);
}

final linksProvider = NotifierProvider<LinksNotifier, List<PlaceLinks>>(LinksNotifier.new);
final linksForProvider = Provider.family<PlaceLinks?, String>(
  (ref, id) => ref.watch(linksProvider).where((l) => l.placeId == id).firstOrNull,
);

// ---------------------------------------------------------------------------
// Data reset
// ---------------------------------------------------------------------------

/// Clears all personal data. Keeps the selected country and theme.
Future<void> clearUserData(WidgetRef ref) async {
  final settings = ref.read(settingsProvider);
  await ref.read(localDatabaseProvider).clearAll();
  await ref.read(photoStorageProvider).deleteAll();
  await ref
      .read(localDatabaseProvider)
      .settings
      .write(AppSettings(countryId: settings.countryId, themeMode: settings.themeMode));
  for (final p in [
    settingsProvider,
    profileProvider,
    visitsProvider,
    notesProvider,
    memoriesProvider,
    bucketProvider,
    dishWishesProvider,
    tripsProvider,
    customPlacesProvider,
    linksProvider,
  ]) {
    ref.invalidate(p);
  }
}
