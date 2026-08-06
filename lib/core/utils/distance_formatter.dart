/// Utility class for formatting distances into hyper-local proximity badges
/// with walking and driving estimates.
class DistanceFormatter {
  /// Formats [distanceKm] into a user-friendly micro-proximity string.
  ///
  /// Examples:
  /// - `0.3` -> `📍 300m · 4 min walk`
  /// - `0.8` -> `📍 800m · 10 min walk`
  /// - `1.4` -> `📍 1.4 km · 3 min drive`
  /// - `3.5` -> `📍 3.5 km away`
  static String formatProximity(double distanceKm) {
    if (distanceKm <= 0.0) {
      return '📍 Nearby';
    }

    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      // Average walking speed ~ 5 km/h -> 1 km takes 12 mins -> 100m takes ~1.2 mins
      final walkMins = (distanceKm * 12).round().clamp(1, 15);
      return '📍 ${meters}m · $walkMins min walk';
    }

    if (distanceKm <= 2.5) {
      // Average city drive speed ~ 25 km/h -> 1 km takes ~2.4 mins
      final driveMins = (distanceKm * 2.4).round().clamp(2, 10);
      return '📍 ${distanceKm.toStringAsFixed(1)} km · $driveMins min drive';
    }

    return '📍 ${distanceKm.toStringAsFixed(1)} km away';
  }

  /// Compact badge display (e.g. for small cards): `300m walk` or `1.4 km`
  static String formatShort(double distanceKm) {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '${meters}m walk';
    }
    return '${distanceKm.toStringAsFixed(1)} km';
  }
}
