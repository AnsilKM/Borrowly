import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import '../../core/storage/local_storage_service.dart';
import '../../core/utils/borrowly_logger.dart';
import 'location_service.dart';

export 'location_service.dart' show LocationFix;

/// The shared LocationService instance.
final locationServiceProvider = Provider<LocationService>((ref) => LocationService());

/// Enum for the location prompt state displayed in UI.
enum LocationStatus {
  /// Still waiting for permission / GPS fix
  loading,
  /// GPS fix resolved successfully
  resolved,
  /// Permission denied — show "Set Location" prompt
  denied,
  /// Permission permanently denied — must go to Settings
  permanentlyDenied,
  /// Service disabled on device
  disabled,
}

/// State object combining the fix + status.
class LocationState {
  final LocationFix? fix;
  final LocationStatus status;

  const LocationState({this.fix, this.status = LocationStatus.loading});

  LocationState copyWith({LocationFix? fix, LocationStatus? status}) {
    return LocationState(
      fix: fix ?? this.fix,
      status: status ?? this.status,
    );
  }

  bool get hasLocation => fix != null;

  /// True when the user has permanently denied and we should direct them to Settings.
  bool get isPermanentlyDenied => status == LocationStatus.permanentlyDenied;

  /// True when permission was denied this session (can re-request).
  bool get isDenied => status == LocationStatus.denied;
}

/// Manages the active location center for the home feed.
///
/// On build:
///   1. Instantly restores last-used location from Hive cache (< 5ms).
///   2. If the cached source was 'manual', stays with it (don't override user choice).
///   3. If cached source was 'gps' or nothing cached, attempts a fresh GPS fix.
///
/// Exposes [setManualLocation] and [refreshGps] for UI.
class LocationNotifier extends AsyncNotifier<LocationState> {
  @override
  Future<LocationState> build() async {
    final storage = ref.read(localStorageServiceProvider);
    final service = ref.read(locationServiceProvider);

    // ── Step 1: Load cached location instantly ───────────────────────────────
    final cached = storage.getLastLocation();
    if (cached != null) {
      final cachedFix = LocationFix(
        lat: cached.lat,
        lng: cached.lng,
        localityName: cached.localityName,
        source: 'cached',
      );
      BorrowlyLogger.info('Location restored from cache: ${cached.localityName}');

      // If user manually chose a location, respect it.
      if (cached.source == 'manual') {
        return LocationState(fix: cachedFix, status: LocationStatus.resolved);
      }

      // Was GPS before — fire off GPS refresh in background, return cache immediately.
      _backgroundGpsRefresh(service, storage);
      return LocationState(fix: cachedFix, status: LocationStatus.resolved);
    }

    // ── Step 2: No cache — check permission first ─────────────────────────────
    return await _resolveWithPermissionCheck(service, storage);
  }

  /// Checks permission and resolves location. Returns appropriate status if denied.
  Future<LocationState> _resolveWithPermissionCheck(
      LocationService service, LocalStorageService storage) async {

    // Check current permission without prompting yet
    final permission = await service.checkPermission();

    if (permission == LocationPermission.deniedForever) {
      BorrowlyLogger.info('Location permanently denied.');
      return const LocationState(fix: null, status: LocationStatus.permanentlyDenied);
    }

    if (permission == LocationPermission.denied) {
      // First time — ask for permission
      final requested = await service.requestPermission();
      if (!service.isGranted(requested)) {
        return LocationState(
          fix: null,
          status: requested == LocationPermission.deniedForever
              ? LocationStatus.permanentlyDenied
              : LocationStatus.denied,
        );
      }
    }

    // Permission granted — get fix
    final fix = await service.resolveWithGrantedPermission();
    if (fix != null) {
      await storage.setLastLocation(
        lat: fix.lat,
        lng: fix.lng,
        localityName: fix.localityName,
        source: 'gps',
      );
      return LocationState(fix: fix, status: LocationStatus.resolved);
    }

    return const LocationState(fix: null, status: LocationStatus.denied);
  }

  /// Fires a background GPS refresh without blocking the UI.
  void _backgroundGpsRefresh(LocationService service, LocalStorageService storage) {
    Future.microtask(() async {
      final freshFix = await service.resolveCurrentLocation();
      if (freshFix != null) {
        await storage.setLastLocation(
          lat: freshFix.lat,
          lng: freshFix.lng,
          localityName: freshFix.localityName,
          source: 'gps',
        );
        state = AsyncData(LocationState(fix: freshFix, status: LocationStatus.resolved));
        BorrowlyLogger.info('Background GPS refresh: ${freshFix.localityName}');
      }
    });
  }

  /// Force refresh from GPS — called by "Use Current Location" button.
  Future<void> refreshGps() async {
    state = const AsyncLoading();
    final service = ref.read(locationServiceProvider);
    final storage = ref.read(localStorageServiceProvider);

    final permission = await service.checkPermission();
    if (permission == LocationPermission.deniedForever) {
      state = const AsyncData(LocationState(
        fix: null,
        status: LocationStatus.permanentlyDenied,
      ));
      return;
    }

    final fix = await service.resolveCurrentLocation();
    if (fix != null) {
      await storage.setLastLocation(
        lat: fix.lat,
        lng: fix.lng,
        localityName: fix.localityName,
        source: 'gps',
      );
      state = AsyncData(LocationState(fix: fix, status: LocationStatus.resolved));
    } else {
      state = const AsyncData(LocationState(fix: null, status: LocationStatus.denied));
    }
  }

  /// Manually set a locality chosen from the search/history picker.
  Future<void> setManualLocation({
    required double lat,
    required double lng,
    required String localityName,
  }) async {
    final fix = LocationFix(lat: lat, lng: lng, localityName: localityName, source: 'manual');
    final storage = ref.read(localStorageServiceProvider);
    await storage.setLastLocation(
      lat: lat,
      lng: lng,
      localityName: localityName,
      source: 'manual',
    );
    state = AsyncData(LocationState(fix: fix, status: LocationStatus.resolved));
    BorrowlyLogger.info('Manual location set: $localityName ($lat, $lng)');
  }
}

/// The global active location provider. All components that need lat/lng watch this.
final activeLocationProvider =
    AsyncNotifierProvider<LocationNotifier, LocationState>(LocationNotifier.new);
