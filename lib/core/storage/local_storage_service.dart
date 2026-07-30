import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ThemeModeNotifier(storage);
});

class LocalStorageService {
  static const String settingsBoxName = 'borrowly_settings';
  static const String themeKey = 'theme_mode';

  Box? _settingsBox;
  bool _isInitializing = false;

  Future<void> init() async {
    if (_settingsBox != null || _isInitializing) return;
    _isInitializing = true;
    try {
      await Hive.initFlutter();
      _settingsBox = await Hive.openBox(settingsBoxName);
    } catch (_) {
    } finally {
      _isInitializing = false;
    }
  }

  String getThemeMode() {
    return _settingsBox?.get(themeKey, defaultValue: 'light') ?? 'light';
  }

  Future<void> setThemeMode(String mode) async {
    if (_settingsBox == null) await init();
    await _settingsBox?.put(themeKey, mode);
  }
}

class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final LocalStorageService _storage;

  ThemeModeNotifier(this._storage) : super(ThemeMode.light);

  Future<void> setThemeMode(ThemeMode mode) async {
    state = ThemeMode.light;
    await _storage.setThemeMode('light');
  }

  Future<void> toggleTheme(bool isDark) async {
    await setThemeMode(ThemeMode.light);
  }
}
