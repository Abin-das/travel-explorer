import 'package:flutter/material.dart' show ThemeMode;

import 'common.dart';

/// What a visit / bookmark points at in the shared catalog.
enum SubjectType { place, destination }

/// A record that the user has been somewhere. Belongs to the user, never to
/// the catalog. One visit per subject; editing replaces it.
class Visit implements Identifiable {
  const Visit({
    required this.id,
    required this.subjectType,
    required this.subjectId,
    required this.visitedOn,
    required this.createdAt,
    this.rating,
  });

  @override
  final String id;
  final SubjectType subjectType;
  final String subjectId;
  final DateTime visitedOn;
  final DateTime createdAt;

  /// Personal 1–5 rating. Never shown as a public score.
  final int? rating;

  Visit copyWith({DateTime? visitedOn, int? rating, bool clearRating = false}) => Visit(
    id: id,
    subjectType: subjectType,
    subjectId: subjectId,
    visitedOn: visitedOn ?? this.visitedOn,
    createdAt: createdAt,
    rating: clearRating ? null : (rating ?? this.rating),
  );

  @override
  Json toJson() => {
    'id': id,
    'subjectType': subjectType.name,
    'subjectId': subjectId,
    'visitedOn': dateToJson(visitedOn),
    'createdAt': dateToJson(createdAt),
    'rating': rating,
  };

  factory Visit.fromJson(Json j) => Visit(
    id: j['id'] as String,
    subjectType: enumByName(SubjectType.values, j['subjectType'], SubjectType.place),
    subjectId: j['subjectId'] as String,
    visitedOn: parseDate(j['visitedOn']) ?? DateTime.now(),
    createdAt: parseDate(j['createdAt']) ?? DateTime.now(),
    rating: (j['rating'] as num?)?.toInt(),
  );
}

/// A personal note about a place (planning note, or a review after a visit).
class PlaceNote implements Identifiable {
  const PlaceNote({required this.placeId, required this.text, required this.updatedAt});

  final String placeId;
  final String text;
  final DateTime updatedAt;

  @override
  String get id => placeId;

  @override
  Json toJson() => {'placeId': placeId, 'text': text, 'updatedAt': dateToJson(updatedAt)};

  factory PlaceNote.fromJson(Json j) => PlaceNote(
    placeId: j['placeId'] as String,
    text: j['text'] as String? ?? '',
    updatedAt: parseDate(j['updatedAt']) ?? DateTime.now(),
  );
}

/// A photo stored on this device. [path] is relative to the app's photo
/// directory so it survives app-container moves on iOS. [remoteUrl] is the
/// hook for future cloud uploads.
class TravelPhoto {
  const TravelPhoto({required this.id, required this.path, required this.addedAt, this.remoteUrl});

  final String id;
  final String path;
  final DateTime addedAt;
  final String? remoteUrl;

  Json toJson() => {'id': id, 'path': path, 'addedAt': dateToJson(addedAt), 'remoteUrl': remoteUrl};

  factory TravelPhoto.fromJson(Json j) => TravelPhoto(
    id: j['id'] as String,
    path: j['path'] as String,
    addedAt: parseDate(j['addedAt']) ?? DateTime.now(),
    remoteUrl: j['remoteUrl'] as String?,
  );
}

/// A journal entry attached to a particular visit.
class TravelMemory implements Identifiable {
  const TravelMemory({
    required this.id,
    required this.visitId,
    required this.placeId,
    required this.title,
    required this.date,
    required this.note,
    required this.photos,
    required this.createdAt,
    this.rating,
  });

  @override
  final String id;
  final String visitId;
  final String placeId;
  final String title;
  final DateTime date;
  final String note;
  final int? rating;
  final List<TravelPhoto> photos;
  final DateTime createdAt;

  TravelMemory copyWith({String? title, DateTime? date, String? note, int? rating, List<TravelPhoto>? photos}) =>
      TravelMemory(
        id: id,
        visitId: visitId,
        placeId: placeId,
        title: title ?? this.title,
        date: date ?? this.date,
        note: note ?? this.note,
        rating: rating ?? this.rating,
        photos: photos ?? this.photos,
        createdAt: createdAt,
      );

  @override
  Json toJson() => {
    'id': id,
    'visitId': visitId,
    'placeId': placeId,
    'title': title,
    'date': dateToJson(date),
    'note': note,
    'rating': rating,
    'photos': photos.map((p) => p.toJson()).toList(),
    'createdAt': dateToJson(createdAt),
  };

  factory TravelMemory.fromJson(Json j) => TravelMemory(
    id: j['id'] as String,
    visitId: j['visitId'] as String? ?? '',
    placeId: j['placeId'] as String,
    title: j['title'] as String? ?? '',
    date: parseDate(j['date']) ?? DateTime.now(),
    note: j['note'] as String? ?? '',
    rating: (j['rating'] as num?)?.toInt(),
    photos: (j['photos'] as List? ?? const [])
        .map((e) => TravelPhoto.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
    createdAt: parseDate(j['createdAt']) ?? DateTime.now(),
  );
}

/// "I want to go here" — a bookmark, independent of visits.
class BucketItem implements Identifiable {
  const BucketItem({required this.id, required this.subjectType, required this.subjectId, required this.addedAt});

  @override
  final String id;
  final SubjectType subjectType;
  final String subjectId;
  final DateTime addedAt;

  @override
  Json toJson() => {'id': id, 'subjectType': subjectType.name, 'subjectId': subjectId, 'addedAt': dateToJson(addedAt)};

  factory BucketItem.fromJson(Json j) => BucketItem(
    id: j['id'] as String,
    subjectType: enumByName(SubjectType.values, j['subjectType'], SubjectType.place),
    subjectId: j['subjectId'] as String,
    addedAt: parseDate(j['addedAt']) ?? DateTime.now(),
  );
}

/// An entry on "Foods I want to try". Either references a catalog dish or is
/// a custom dish typed by the user.
class DishWish implements Identifiable {
  const DishWish({required this.id, required this.addedAt, this.dishId, this.customName, this.triedOn});

  @override
  final String id;
  final String? dishId;
  final String? customName;
  final DateTime addedAt;
  final DateTime? triedOn;

  bool get tried => triedOn != null;

  DishWish withTried(DateTime? when) =>
      DishWish(id: id, dishId: dishId, customName: customName, addedAt: addedAt, triedOn: when);

  @override
  Json toJson() => {
    'id': id,
    'dishId': dishId,
    'customName': customName,
    'addedAt': dateToJson(addedAt),
    'triedOn': dateToJson(triedOn),
  };

  factory DishWish.fromJson(Json j) => DishWish(
    id: j['id'] as String,
    dishId: j['dishId'] as String?,
    customName: j['customName'] as String?,
    addedAt: parseDate(j['addedAt']) ?? DateTime.now(),
    triedOn: parseDate(j['triedOn']),
  );
}

class TripActivity {
  const TripActivity({required this.id, required this.title, this.placeId, this.done = false});

  final String id;
  final String title;

  /// Null for free-form activities ("Shopping", "Return journey").
  final String? placeId;

  /// Completion of the *plan item*. Deliberately does not create a [Visit].
  final bool done;

  TripActivity copyWith({bool? done, String? title}) =>
      TripActivity(id: id, title: title ?? this.title, placeId: placeId, done: done ?? this.done);

  Json toJson() => {'id': id, 'title': title, 'placeId': placeId, 'done': done};

  factory TripActivity.fromJson(Json j) => TripActivity(
    id: j['id'] as String,
    title: j['title'] as String? ?? '',
    placeId: j['placeId'] as String?,
    done: j['done'] as bool? ?? false,
  );
}

class TripDay {
  const TripDay({required this.id, required this.activities});

  final String id;
  final List<TripActivity> activities;

  TripDay copyWith({List<TripActivity>? activities}) => TripDay(id: id, activities: activities ?? this.activities);

  Json toJson() => {'id': id, 'activities': activities.map((a) => a.toJson()).toList()};

  factory TripDay.fromJson(Json j) => TripDay(
    id: j['id'] as String,
    activities: (j['activities'] as List? ?? const [])
        .map((e) => TripActivity.fromJson((e as Map).cast<String, dynamic>()))
        .toList(),
  );
}

class Trip implements Identifiable {
  const Trip({
    required this.id,
    required this.title,
    required this.destinationId,
    required this.startDate,
    required this.days,
    required this.createdAt,
  });

  @override
  final String id;
  final String title;
  final String destinationId;
  final DateTime startDate;
  final List<TripDay> days;
  final DateTime createdAt;

  DateTime get endDate => startDate.add(Duration(days: (days.length - 1).clamp(0, 365)));
  int get totalActivities => days.fold(0, (s, d) => s + d.activities.length);
  int get completedActivities => days.fold(0, (s, d) => s + d.activities.where((a) => a.done).length);

  Trip copyWith({String? title, String? destinationId, DateTime? startDate, List<TripDay>? days}) => Trip(
    id: id,
    title: title ?? this.title,
    destinationId: destinationId ?? this.destinationId,
    startDate: startDate ?? this.startDate,
    days: days ?? this.days,
    createdAt: createdAt,
  );

  @override
  Json toJson() => {
    'id': id,
    'title': title,
    'destinationId': destinationId,
    'startDate': dateToJson(startDate),
    'days': days.map((d) => d.toJson()).toList(),
    'createdAt': dateToJson(createdAt),
  };

  factory Trip.fromJson(Json j) => Trip(
    id: j['id'] as String,
    title: j['title'] as String? ?? 'Trip',
    destinationId: j['destinationId'] as String,
    startDate: parseDate(j['startDate']) ?? DateTime.now(),
    days: (j['days'] as List? ?? const []).map((e) => TripDay.fromJson((e as Map).cast<String, dynamic>())).toList(),
    createdAt: parseDate(j['createdAt']) ?? DateTime.now(),
  );
}

class UserProfile {
  const UserProfile({this.displayName = 'Explorer', this.avatarPath, this.bio = ''});

  final String displayName;
  final String? avatarPath;
  final String bio;

  UserProfile copyWith({String? displayName, String? avatarPath, bool clearAvatar = false, String? bio}) => UserProfile(
    displayName: displayName ?? this.displayName,
    avatarPath: clearAvatar ? null : (avatarPath ?? this.avatarPath),
    bio: bio ?? this.bio,
  );

  Json toJson() => {'displayName': displayName, 'avatarPath': avatarPath, 'bio': bio};

  factory UserProfile.fromJson(Json j) => UserProfile(
    displayName: j['displayName'] as String? ?? 'Explorer',
    avatarPath: j['avatarPath'] as String?,
    bio: j['bio'] as String? ?? '',
  );
}

class AppSettings {
  const AppSettings({
    this.countryId,
    this.themeMode = ThemeMode.system,
    this.tripReminders = true,
    this.seasonTips = true,
    this.showStatsOnProfile = true,
    this.recentDestinationIds = const [],
  });

  /// Null until the user completes country selection.
  final String? countryId;
  final ThemeMode themeMode;
  final bool tripReminders;
  final bool seasonTips;
  final bool showStatsOnProfile;
  final List<String> recentDestinationIds;

  AppSettings copyWith({
    String? countryId,
    ThemeMode? themeMode,
    bool? tripReminders,
    bool? seasonTips,
    bool? showStatsOnProfile,
    List<String>? recentDestinationIds,
  }) => AppSettings(
    countryId: countryId ?? this.countryId,
    themeMode: themeMode ?? this.themeMode,
    tripReminders: tripReminders ?? this.tripReminders,
    seasonTips: seasonTips ?? this.seasonTips,
    showStatsOnProfile: showStatsOnProfile ?? this.showStatsOnProfile,
    recentDestinationIds: recentDestinationIds ?? this.recentDestinationIds,
  );

  Json toJson() => {
    'countryId': countryId,
    'themeMode': themeMode.name,
    'tripReminders': tripReminders,
    'seasonTips': seasonTips,
    'showStatsOnProfile': showStatsOnProfile,
    'recentDestinationIds': recentDestinationIds,
  };

  factory AppSettings.fromJson(Json j) => AppSettings(
    countryId: j['countryId'] as String?,
    themeMode: enumByName(ThemeMode.values, j['themeMode'], ThemeMode.system),
    tripReminders: j['tripReminders'] as bool? ?? true,
    seasonTips: j['seasonTips'] as bool? ?? true,
    showStatsOnProfile: j['showStatsOnProfile'] as bool? ?? true,
    recentDestinationIds: stringList(j['recentDestinationIds']),
  );
}

/// Achievements are computed from saved activity, never stored.
class Achievement {
  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.progress,
    required this.target,
  });

  final String id;
  final String title;
  final String description;
  final int progress;
  final int target;

  bool get unlocked => progress >= target;
  double get ratio => target == 0 ? 1 : (progress / target).clamp(0, 1).toDouble();
}

/// The user's own links for a place: a map link and social videos (e.g.
/// Instagram reels). Works for catalog places and user-added ones alike.
class PlaceLinks implements Identifiable {
  const PlaceLinks({required this.placeId, this.mapUrl, this.reelUrls = const [], required this.updatedAt});

  final String placeId;
  final String? mapUrl;
  final List<String> reelUrls;
  final DateTime updatedAt;

  @override
  String get id => placeId;

  bool get isEmpty => (mapUrl == null || mapUrl!.isEmpty) && reelUrls.isEmpty;

  PlaceLinks copyWith({String? mapUrl, bool clearMap = false, List<String>? reelUrls}) => PlaceLinks(
    placeId: placeId,
    mapUrl: clearMap ? null : (mapUrl ?? this.mapUrl),
    reelUrls: reelUrls ?? this.reelUrls,
    updatedAt: DateTime.now(),
  );

  @override
  Json toJson() => {'placeId': placeId, 'mapUrl': mapUrl, 'reelUrls': reelUrls, 'updatedAt': dateToJson(updatedAt)};

  factory PlaceLinks.fromJson(Json j) => PlaceLinks(
    placeId: j['placeId'] as String,
    mapUrl: j['mapUrl'] as String?,
    reelUrls: stringList(j['reelUrls']),
    updatedAt: parseDate(j['updatedAt']) ?? DateTime.now(),
  );
}
