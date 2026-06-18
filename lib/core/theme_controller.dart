import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fitlog_theme.dart';

class ThemeController extends ChangeNotifier {
  ThemeController();

  static const String _themeKey = 'theme_key';

  FitLogThemeKey _theme = FitLogThemeKey.green;
  bool _initialized = false;

  FitLogThemeKey get theme => _theme;
  bool get initialized => _initialized;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _theme = FitLogThemeKey.fromStorageValue(prefs.getString(_themeKey));
    _initialized = true;
    notifyListeners();
  }

  Future<void> setTheme(FitLogThemeKey theme) async {
    if (_theme == theme) {
      return;
    }
    _theme = theme;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, theme.storageValue);
  }
}
