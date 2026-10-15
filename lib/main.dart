import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'application/providers.dart';
import 'data/repositories/local_database.dart';
import 'data/services/photo_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  final db = await LocalDatabase.open();
  final photos = await PhotoStorage.open();

  runApp(
    ProviderScope(
      overrides: [localDatabaseProvider.overrideWithValue(db), photoStorageProvider.overrideWithValue(photos)],
      child: const TravelExplorerApp(),
    ),
  );
}
