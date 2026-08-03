import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import '../widgets/borrowly_toast.dart';
import 'borrowly_logger.dart';

class PermissionService {
  /// Request Photos & Storage Permission before opening image picker
  static Future<bool> requestPhotosPermission(BuildContext context) async {
    BorrowlyLogger.event('Requesting Photos / Storage Permission');

    PermissionStatus status;
    if (await Permission.photos.isGranted) {
      return true;
    }

    status = await Permission.photos.request();
    if (status.isDenied) {
      status = await Permission.storage.request();
    }

    if (status.isGranted || status.isLimited) {
      BorrowlyLogger.info('Photos permission granted.');
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        BorrowlyToast.show(
          context,
          'Photo permission is required. Please enable it in Settings.',
          icon: Icons.photo_library_outlined,
        );
      }
      openAppSettings();
      return false;
    }

    return false;
  }

  /// Request Camera Permission before capturing photo
  static Future<bool> requestCameraPermission(BuildContext context) async {
    BorrowlyLogger.event('Requesting Camera Permission');

    if (await Permission.camera.isGranted) {
      return true;
    }

    final status = await Permission.camera.request();
    if (status.isGranted) {
      BorrowlyLogger.info('Camera permission granted.');
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        BorrowlyToast.show(
          context,
          'Camera permission is required to take photos of items.',
          icon: Icons.camera_alt_outlined,
        );
      }
      openAppSettings();
      return false;
    }

    return false;
  }

  /// Request Location Permission for hyper-local PostGIS radius search
  static Future<bool> requestLocationPermission(BuildContext context) async {
    BorrowlyLogger.event('Requesting Location Permission');

    if (await Permission.locationWhenInUse.isGranted) {
      return true;
    }

    final status = await Permission.locationWhenInUse.request();
    if (status.isGranted) {
      BorrowlyLogger.info('Location permission granted.');
      return true;
    }

    if (status.isPermanentlyDenied) {
      if (context.mounted) {
        BorrowlyToast.show(
          context,
          'Location permission is required for 5 km radius search.',
          icon: Icons.location_on_outlined,
        );
      }
      openAppSettings();
      return false;
    }

    return false;
  }
}
