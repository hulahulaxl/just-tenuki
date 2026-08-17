import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/board_settings.dart';

class SettingsService {
  static const String _boxName = 'settingsBox';
  static const String _boardSettingsKey = 'boardSettings';
  static const String _showTreePaneKey = 'showTreePane';
  static const String _showAnalysisPaneKey = 'showAnalysisPane';
  static const String _showCommentsPaneKey = 'showCommentsPane';
  static const String _showSettingsPaneKey = 'showSettingsPane';
  static const String _showMarkPaneKey = 'showMarkPane';

  static late Box _box;

  static Future<void> init() async {
    await Hive.initFlutter();
    _box = await Hive.openBox(_boxName);
  }

  // --- Board Settings ---
  static BoardSettings loadBoardSettings() {
    final Map<dynamic, dynamic>? data = _box.get(_boardSettingsKey);
    if (data != null) {
      try {
        return BoardSettings.fromJson(data);
      } catch (e) {
        debugPrint('Error parsing BoardSettings from Hive: $e');
      }
    }
    return const BoardSettings.defaults();
  }

  static Future<void> saveBoardSettings(BoardSettings settings) async {
    await _box.put(_boardSettingsKey, settings.toJson());
  }

  // --- UI Layout State ---
  static bool get showTreePane => _box.get(_showTreePaneKey, defaultValue: false);
  static Future<void> setShowTreePane(bool value) => _box.put(_showTreePaneKey, value);

  static bool get showAnalysisPane => _box.get(_showAnalysisPaneKey, defaultValue: false);
  static Future<void> setShowAnalysisPane(bool value) => _box.put(_showAnalysisPaneKey, value);

  static bool get showCommentsPane => _box.get(_showCommentsPaneKey, defaultValue: false);
  static Future<void> setShowCommentsPane(bool value) => _box.put(_showCommentsPaneKey, value);

  static bool get showSettingsPane => _box.get(_showSettingsPaneKey, defaultValue: false);
  static Future<void> setShowSettingsPane(bool value) => _box.put(_showSettingsPaneKey, value);

  static bool get showMarkPane => _box.get(_showMarkPaneKey, defaultValue: false);
  static Future<void> setShowMarkPane(bool value) => _box.put(_showMarkPaneKey, value);
}
