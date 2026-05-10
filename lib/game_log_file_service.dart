import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';

/// Result of a load operation: the JSON string and whatever filename hint
/// was supplied by the picker (may be null on some platforms).
class LoadedGameFile {
  final String jsonString;
  final String? filename;

  LoadedGameFile(this.jsonString, this.filename);
}

/// Thin wrapper around [FilePicker] for loading and saving game-log JSON.
/// Exists so widget/integration tests can swap in a fake implementation
/// without touching the platform channel.
class GameLogFileService {
  static GameLogFileService _defaultInstance = GameLogFileService();

  static GameLogFileService get instance => _defaultInstance;

  static void setDefaultInstance(GameLogFileService instance) {
    _defaultInstance = instance;
  }

  static GameLogFileService resetDefaultInstance() {
    _defaultInstance = GameLogFileService();
    return _defaultInstance;
  }

  /// Returns the JSON string from the picked file, or null if the user
  /// cancelled. Throws if a file was selected but couldn't be read.
  Future<LoadedGameFile?> pickAndReadJson() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.isEmpty) {
      return null;
    }

    final file = result.files.single;
    String jsonString;
    if (file.bytes != null) {
      jsonString = utf8.decode(file.bytes!);
    } else if (file.path != null) {
      jsonString = await File(file.path!).readAsString();
    } else {
      throw Exception('Unable to read file: neither bytes nor path available');
    }
    return LoadedGameFile(jsonString, file.name);
  }

  /// Returns the saved file path (null on web or if user cancelled).
  Future<String?> saveJson({
    required String filename,
    required String jsonData,
  }) async {
    return FilePicker.platform.saveFile(
      dialogTitle: 'Please select an output file:',
      fileName: filename,
      type: FileType.custom,
      allowedExtensions: ['json'],
      bytes: utf8.encode(jsonData),
    );
  }
}
