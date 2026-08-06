import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import '../utils/borrowly_logger.dart';

/// Value object representing a resolved location center.
class LocationFix {
  final double lat;
  final double lng;
  final String localityName; // "Kakkanad", "Edappally", etc.
  final String source; // 'gps' | 'manual' | 'cached'

  const LocationFix({
    required this.lat,
    required this.lng,
    required this.localityName,
    this.source = 'gps',
  });

  @override
  String toString() => 'LocationFix($localityName, $lat, $lng, [$source])';
}

/// Low-level wrapper around `geolocator` and `geocoding`.
class LocationService {

  /// Check current permission status WITHOUT prompting.
  Future<LocationPermission> checkPermission() => Geolocator.checkPermission();

  /// Ask the OS for permission. Returns final permission state.
  Future<LocationPermission> requestPermission() =>
      Geolocator.requestPermission();

  /// Returns `true` if permission is granted (whileInUse or always).
  bool isGranted(LocationPermission permission) =>
      permission == LocationPermission.whileInUse ||
      permission == LocationPermission.always;

  /// Returns `true` if permission is permanently denied.
  bool isPermanentlyDenied(LocationPermission permission) =>
      permission == LocationPermission.deniedForever;

  /// Opens the app's OS settings page so the user can grant location.
  Future<bool> openSettings() => Geolocator.openAppSettings();

  /// Gets a single GPS fix.
  Future<Position?> getCurrentPosition() async {
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: AndroidSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: const Duration(seconds: 12),
        ),
      );
    } catch (e) {
      BorrowlyLogger.warning('GPS fix error: $e');
      return null;
    }
  }

  /// Reverse geocodes [lat]/[lng] → locality display name.
  Future<String> reverseGeocode(double lat, double lng) async {
    try {
      final placemarks = await placemarkFromCoordinates(lat, lng);
      if (placemarks.isNotEmpty) {
        final p = placemarks.first;
        final name = p.subLocality?.isNotEmpty == true
            ? p.subLocality!
            : p.locality?.isNotEmpty == true
                ? p.locality!
                : p.name ?? 'Unknown Area';
        return name;
      }
    } catch (e) {
      BorrowlyLogger.warning('Reverse geocode error: $e');
    }
    return 'Unknown Area';
  }

  /// Full flow with permission request: permission → fix → geocode.
  /// Returns `null` if any step fails.
  Future<LocationFix?> resolveCurrentLocation() async {
    final perm = await requestPermission();
    if (!isGranted(perm)) {
      BorrowlyLogger.info('Location permission denied.');
      return null;
    }
    return resolveWithGrantedPermission();
  }

  /// Assumes permission is already granted. Gets fix + geocodes.
  Future<LocationFix?> resolveWithGrantedPermission() async {
    final position = await getCurrentPosition();
    if (position == null) return null;

    final name = await reverseGeocode(position.latitude, position.longitude);
    BorrowlyLogger.info('GPS resolved: $name (${position.latitude}, ${position.longitude})');

    return LocationFix(
      lat: position.latitude,
      lng: position.longitude,
      localityName: name,
      source: 'gps',
    );
  }
}
