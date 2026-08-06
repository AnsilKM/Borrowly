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
  static const String neighborhoodNameKey = 'neighborhood_name';
  static const String savedAddressesKey = 'saved_addresses';

  // Location persistence
  static const String lastLatKey = 'last_lat';
  static const String lastLngKey = 'last_lng';
  static const String lastLocalityNameKey = 'last_locality_name';
  static const String locationSourceKey = 'location_source'; // 'gps' | 'manual'
  static const String recentLocalitySearchesKey = 'recent_locality_searches';

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

  // ── Location Persistence ─────────────────────────────────────────────────

  /// Returns the last known lat/lng/locality, or null if not yet set.
  ({double lat, double lng, String localityName, String source})? getLastLocation() {
    try {
      final lat = _settingsBox?.get(lastLatKey) as double?;
      final lng = _settingsBox?.get(lastLngKey) as double?;
      final name = _settingsBox?.get(lastLocalityNameKey, defaultValue: '') as String? ?? '';
      final source = _settingsBox?.get(locationSourceKey, defaultValue: 'gps') as String? ?? 'gps';
      if (lat != null && lng != null) {
        return (lat: lat, lng: lng, localityName: name, source: source);
      }
    } catch (e) {
      BorrowlyLogger.warning('Read last location notice: $e');
    }
    return null;
  }

  /// Persists the active location center to Hive.
  Future<void> setLastLocation({
    required double lat,
    required double lng,
    required String localityName,
    String source = 'gps',
  }) async {
    if (_settingsBox == null) await init();
    try {
      await _settingsBox?.put(lastLatKey, lat);
      await _settingsBox?.put(lastLngKey, lng);
      await _settingsBox?.put(lastLocalityNameKey, localityName);
      await _settingsBox?.put(locationSourceKey, source);
      BorrowlyLogger.info('Location persisted: $localityName ($lat, $lng) [$source]');
    } catch (e) {
      BorrowlyLogger.warning('Set last location error: $e');
    }
  }

  /// Clears any saved location so GPS will be re-requested on next launch.
  Future<void> clearLastLocation() async {
    if (_settingsBox == null) await init();
    await _settingsBox?.delete(lastLatKey);
    await _settingsBox?.delete(lastLngKey);
    await _settingsBox?.delete(lastLocalityNameKey);
    await _settingsBox?.delete(locationSourceKey);
  }

  /// Returns the stored recent locality searches list.
  List<String> getRecentLocalitySearches() {
    try {
      final list = _settingsBox?.get(recentLocalitySearchesKey) as List<dynamic>?;
      if (list != null) {
        return list.map((e) => e.toString()).toList();
      }
    } catch (e) {
      BorrowlyLogger.warning('Read recent searches notice: $e');
    }
    return [];
  }

  /// Persists recent locality searches list to Hive.
  Future<void> saveRecentLocalitySearches(List<String> searches) async {
    if (_settingsBox == null) await init();
    try {
      await _settingsBox?.put(recentLocalitySearchesKey, searches);
    } catch (e) {
      BorrowlyLogger.warning('Save recent searches error: $e');
    }
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
      BorrowlyLogger.warning('Read cached items error: $e');
    }
    return [];
  }

  static const String deletedItemIdsKey = 'deleted_item_ids';
  static const String availabilityOverridesKey = 'availability_overrides';
  static const String editedItemIdsKey = 'edited_item_ids';

  Set<String> getDeletedItemIds() {
    try {
      final list = _itemsCacheBox?.get(deletedItemIdsKey) as List<dynamic>?;
      if (list != null) {
        return list.map((e) => e.toString()).toSet();
      }
    } catch (e) {
      BorrowlyLogger.warning('Read deleted item ids error: $e');
    }
    return {};
  }

  Set<String> getEditedItemIds() {
    try {
      final list = _itemsCacheBox?.get(editedItemIdsKey) as List<dynamic>?;
      if (list != null) {
        return list.map((e) => e.toString()).toSet();
      }
    } catch (e) {
      BorrowlyLogger.warning('Read edited item ids notice: $e');
    }
    return {};
  }

  Future<void> addEditedItemId(String itemId) async {
    if (_itemsCacheBox == null) await init();
    try {
      final set = getEditedItemIds()..add(itemId);
      await _itemsCacheBox?.put(editedItemIdsKey, set.toList());
    } catch (e) {
      BorrowlyLogger.warning('Save edited item id notice: $e');
    }
  }

  Future<void> deleteCachedItem(String itemId) async {
    if (_itemsCacheBox == null) await init();
    try {
      final deletedSet = getDeletedItemIds()..add(itemId);
      await _itemsCacheBox?.put(deletedItemIdsKey, deletedSet.toList());

      final current = getCachedNearbyItems();
      final updated = current.where((item) => item['id'] != itemId).toList();
      await cacheNearbyItems(updated);
    } catch (e) {
      BorrowlyLogger.warning('deleteCachedItem notice: $e');
    }
  }

  Map<String, bool> getAvailabilityOverrides() {
    try {
      final raw = _itemsCacheBox?.get(availabilityOverridesKey) as String?;
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        return decoded.map((k, v) => MapEntry(k, v as bool));
      }
    } catch (e) {
      BorrowlyLogger.warning('Read availability overrides notice: $e');
    }
    return {};
  }

  Future<void> setAvailabilityOverride(String itemId, bool isAvailable) async {
    if (_itemsCacheBox == null) await init();
    try {
      final overrides = getAvailabilityOverrides();
      overrides[itemId] = isAvailable;
      await _itemsCacheBox?.put(availabilityOverridesKey, jsonEncode(overrides));
    } catch (e) {
      BorrowlyLogger.warning('Save availability override notice: $e');
    }
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
