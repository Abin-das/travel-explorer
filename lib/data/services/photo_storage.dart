import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/user_activity.dart';

/// Copies picked images into the app's private documents directory so they
/// survive the gallery originals being moved or deleted, and stores only a
/// path relative to that directory.
///
/// Future cloud upload: upload the file, then set [TravelPhoto.remoteUrl].
class PhotoStorage {
  PhotoStorage(this._root);

  final Directory _root;
  static const _uuid = Uuid();

  static Future<PhotoStorage> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'photos'));
    if (!dir.existsSync()) await dir.create(recursive: true);
    return PhotoStorage(dir);
  }

  final ImagePicker _picker = ImagePicker();

  /// Returns null if a photo file has gone missing.
  File? resolve(String relativePath) {
    final f = File(p.join(_root.path, relativePath));
    return f.existsSync() ? f : null;
  }

  Future<List<TravelPhoto>> pickFromGallery({int? limit}) async {
    final picked = await _picker.pickMultiImage(imageQuality: 85, maxWidth: 2400, limit: limit);
    return _import(picked);
  }

  Future<List<TravelPhoto>> pickFromCamera() async {
    final shot = await _picker.pickImage(source: ImageSource.camera, imageQuality: 85, maxWidth: 2400);
    return shot == null ? const [] : _import([shot]);
  }

  Future<String?> pickSingleRelative() async {
    final picked = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (picked == null) return null;
    final photos = await _import([picked]);
    return photos.isEmpty ? null : photos.first.path;
  }

  Future<List<TravelPhoto>> _import(List<XFile> files) async {
    final out = <TravelPhoto>[];
    for (final f in files) {
      final id = _uuid.v4();
      final ext = p.extension(f.path).isEmpty ? '.jpg' : p.extension(f.path);
      final name = '$id$ext';
      await f.saveTo(p.join(_root.path, name));
      out.add(TravelPhoto(id: id, path: name, addedAt: DateTime.now()));
    }
    return out;
  }

  Future<void> delete(String relativePath) async {
    final f = File(p.join(_root.path, relativePath));
    if (f.existsSync()) await f.delete();
  }

  Future<void> deleteAll() async {
    if (_root.existsSync()) {
      await for (final e in _root.list()) {
        await e.delete(recursive: true);
      }
    }
  }
}
