import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

/// Holds the user's tag names and persists them to a local JSON file.
///
/// Tags are referenced by value in [recorded sessions]; deleting a tag
/// removes it from this list only, so past sessions keep their copy.
class TagsProvider extends ChangeNotifier {
  final List<String> _tags = [];

  /// Unmodifiable view of all tags, in creation order.
  List<String> get tags => List.unmodifiable(_tags);

  bool _loaded = false;

  /// Adds [name] (trimmed) unless it is empty or already exists,
  /// ignoring case. Returns true when the tag was added.
  bool addTag(String name) {
    final trimmed = name.trim();
    if (trimmed.isEmpty) return false;
    final exists = _tags.any((t) => t.toLowerCase() == trimmed.toLowerCase());
    if (exists) return false;
    _tags.add(trimmed);
    notifyListeners();
    unawaited(save());
    return true;
  }

  /// Removes [name] (case-insensitive match). Returns true when a tag
  /// was removed.
  bool removeTag(String name) {
    final index = _tags.indexWhere(
      (t) => t.toLowerCase() == name.trim().toLowerCase(),
    );
    if (index < 0) return false;
    _tags.removeAt(index);
    notifyListeners();
    unawaited(save());
    return true;
  }

  Future<File> get _file async {
    final directory = await getApplicationDocumentsDirectory();
    return File('${directory.path}/tags.json');
  }

  /// Loads tags from disk. Safe to call multiple times; only the first
  /// call has an effect. Falls back to an empty list on any error or when
  /// no save file exists yet.
  Future<void> loadTags() async {
    if (_loaded) return;
    _loaded = true;
    try {
      final file = await _file;
      if (!await file.exists()) return;
      final content = await file.readAsString();
      final list = jsonDecode(content) as List<dynamic>;
      _tags
        ..clear()
        ..addAll(list.cast<String>());
      notifyListeners();
    } catch (e) {
      // Start with an empty list rather than crashing.
    }
  }

  /// Writes the current tag list to disk.
  Future<void> save() async {
    try {
      final file = await _file;
      await file.writeAsString(jsonEncode(_tags));
    } catch (e) {
      // Persistence failures are non-fatal for this step.
    }
  }
}
