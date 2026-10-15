import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:hive_ce/hive.dart';

import '../../domain/entities/common.dart';
import '../../domain/repositories/repositories.dart';

/// Stores each entity as a JSON string keyed by id. Using plain JSON avoids
/// code generation and keeps the format identical to what a REST API returns.
class HiveEntityStore<T extends Identifiable> implements EntityStore<T> {
  HiveEntityStore(this._box, this._fromJson);

  final Box<String> _box;
  final T Function(Json json) _fromJson;

  @override
  List<T> readAll() {
    final out = <T>[];
    for (final raw in _box.values) {
      try {
        out.add(_fromJson((jsonDecode(raw) as Map).cast<String, dynamic>()));
      } catch (e) {
        // A corrupt record should never take the whole list down.
        debugPrint('Skipping unreadable record in ${_box.name}: $e');
      }
    }
    return out;
  }

  @override
  Future<void> upsert(T item) => _box.put(item.id, jsonEncode(item.toJson()));

  @override
  Future<void> upsertAll(Iterable<T> items) => _box.putAll({for (final i in items) i.id: jsonEncode(i.toJson())});

  @override
  Future<void> remove(String id) => _box.delete(id);

  @override
  Future<void> clear() => _box.clear();
}

class HiveValueStore<T> implements ValueStore<T> {
  HiveValueStore(this._box, this._key, this._fromJson, this._toJson, this._fallback);

  final Box<String> _box;
  final String _key;
  final T Function(Json json) _fromJson;
  final Json Function(T value) _toJson;
  final T _fallback;

  @override
  T read() {
    final raw = _box.get(_key);
    if (raw == null) return _fallback;
    try {
      return _fromJson((jsonDecode(raw) as Map).cast<String, dynamic>());
    } catch (_) {
      return _fallback;
    }
  }

  @override
  Future<void> write(T value) => _box.put(_key, jsonEncode(_toJson(value)));

  @override
  Future<void> clear() => _box.delete(_key);
}
