import 'package:edhtracker/game_log_file_service.dart';

/// In-memory test double for [GameLogFileService]. Set [nextLoad] to control
/// what `pickAndReadJson` returns, and inspect [savedFiles] after a save.
class FakeGameLogFileService extends GameLogFileService {
  LoadedGameFile? nextLoad;
  Object? loadError;
  final List<({String filename, String jsonData})> savedFiles = [];
  String? saveResult = '/fake/path/saved.json';

  @override
  Future<LoadedGameFile?> pickAndReadJson() async {
    if (loadError != null) {
      throw loadError!;
    }
    return nextLoad;
  }

  @override
  Future<String?> saveJson({
    required String filename,
    required String jsonData,
  }) async {
    savedFiles.add((filename: filename, jsonData: jsonData));
    return saveResult;
  }
}
