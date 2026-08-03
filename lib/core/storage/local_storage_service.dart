import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/borrowly_logger.dart';

final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return ThemeModeNotifier(storage);
});

class LocalStorageService {
  static const String settingsBoxName = 'borrowly_settings';
  static const String itemsCacheBoxName = 'borrowly_items_cache';
  static const String userCacheBoxName = 'borrowly_user_cache';

  static const String themeKey = 'theme_mode';
  static const String cachedNearbyItemsKey = 'cached_nearby_items';
  static const String cachedUserKey = 'cached_user_profile';

  Box? _settingsBox;
  Box? _itemsCacheBox;
  Box? _userCacheBox;
  bool _isInitializing = false;

  Future<void> init() async {
    if (_settingsBox != null || _isInitializing) return;
    _isInitializing = true;
    try {
      await Hive.initFlutter();
      _settingsBox = await Hive.openBox(settingsBoxName);
      _itemsCacheBox = await Hive.openBox(itemsCacheBoxName);
      _userCacheBox = await Hive.openBox(userCacheBoxName);
      BorrowlyLogger.info('Hive Local Storage initialized successfully.');
    } catch (e) {
      BorrowlyLogger.warning('Hive init notice: $e');
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

  /// Fast Hive local cache for user profile (< 5ms startup response)
  Future<void> cacheUserProfile(Map<String, dynamic> userMap) async {
    if (_userCacheBox == null) await init();
    try {
      final jsonString = jsonEncode(userMap);
      await _userCacheBox?.put(cachedUserKey, jsonString);
      BorrowlyLogger.info('User profile cached locally in Hive.');
    } catch (e) {
      BorrowlyLogger.warning('Cache user profile error: $e');
    }
  }

  Map<String, dynamic>? getCachedUserProfile() {
    try {
      final raw = _userCacheBox?.get(cachedUserKey) as String?;
      if (raw != null && raw.isNotEmpty) {
        return Map<String, dynamic>.from(jsonDecode(raw) as Map);
      }
    } catch (e) {
      BorrowlyLogger.warning('Read cached user profile notice: $e');
    }
    return null;
  }

  Future<void> clearCachedUserProfile() async {
    if (_userCacheBox == null) await init();
    await _userCacheBox?.delete(cachedUserKey);
    BorrowlyLogger.info('User profile cache cleared from Hive.');
  }

  /// Fast Hive local cache for nearby items (< 5ms startup response)
  Future<void> cacheNearbyItems(List<Map<String, dynamic>> rawItemRows) async {
    if (_itemsCacheBox == null) await init();
    try {
      final jsonString = jsonEncode(rawItemRows);
      await _itemsCacheBox?.put(cachedNearbyItemsKey, jsonString);
      BorrowlyLogger.info('Cached ${rawItemRows.length} items to Hive local storage.');
    } catch (e) {
      BorrowlyLogger.warning('Cache nearby items error: $e');
    }
  }

  List<Map<String, dynamic>> getCachedNearbyItems() {
    try {
      final raw = _itemsCacheBox?.get(cachedNearbyItemsKey) as String?;
      if (raw != null && raw.isNotEmpty) {
        final decoded = jsonDecode(raw) as List<dynamic>;
        return decoded.map((e) => Map<String, dynamic>.from(e as Map)).toList();
      }
    } catch (e) {
      BorrowlyLogger.warning('Read cached items notice: $e');
    }
    return [];
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
