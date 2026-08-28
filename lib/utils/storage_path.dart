import 'dart:io';

import 'package:path_provider/path_provider.dart';

/// Resolves the directory where app data is persisted.
///
/// On Windows desktop the data lives in a `storage` folder created next to
/// the executable, which avoids anti-virus/Defender heuristics that flag
/// apps writing application state into the user's Documents directory.
/// On every other platform a `storage` folder under the platform's
/// application-support directory is used instead.
class StoragePath {
  StoragePath._();

  /// Returns (creating if needed) the persistent `storage` directory.
  static Future<Directory> directory() async {
    final Directory base;
    if (Platform.isWindows) {
      final exe = File(Platform.resolvedExecutable);
      base = exe.parent;
    } else {
      base = await getApplicationSupportDirectory();
    }
    final storage = Directory('${base.path}${Platform.pathSeparator}storage');
    await storage.create(recursive: true);
    return storage;
  }
}
