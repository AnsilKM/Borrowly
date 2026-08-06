import 'dart:io';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_service.dart';
import '../utils/borrowly_logger.dart';

class SupabaseStorageService {
  static const String bucketName = 'item-images';

  /// Uploads a local image file to Supabase Storage and returns its public HTTPS CDN URL.
  /// Falls back gracefully if offline, unconfigured, or bucket missing.
  static Future<String> uploadItemImage(String localPath) async {
    // If it's already a web URL, return as-is
    if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
      return localPath;
    }

    final client = SupabaseService.client;
    if (client == null || !SupabaseService.isConfigured) {
      BorrowlyLogger.warning('Supabase client unconfigured, skipping image upload for: $localPath');
      return localPath;
    }

    final file = File(localPath);
    if (!await file.exists()) {
      BorrowlyLogger.warning('Local image file does not exist at path: $localPath');
      return localPath;
    }

    try {
      final bytes = await file.readAsBytes();
      final fileExt = localPath.contains('.') ? localPath.split('.').last.toLowerCase() : 'jpg';
      final fileName = '${DateTime.now().millisecondsSinceEpoch}_${localPath.hashCode}.$fileExt';
      final storagePath = 'items/$fileName';

      BorrowlyLogger.info('Uploading item photo to Supabase Storage bucket "$bucketName": $storagePath');

      // Upload file bytes to Supabase Storage bucket
      await client.storage.from(bucketName).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      // Fetch public CDN URL
      final publicUrl = client.storage.from(bucketName).getPublicUrl(storagePath);
      BorrowlyLogger.info('Successfully uploaded item image! Public CDN URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      BorrowlyLogger.warning('Supabase Storage image upload error (bucket "$bucketName" notice): $e');
      return localPath;
    }
  }

  /// Uploads a user profile avatar image to Supabase Storage and returns its public HTTPS CDN URL.
  static Future<String> uploadAvatarImage(String localPath) async {
    if (localPath.startsWith('http://') || localPath.startsWith('https://')) {
      return localPath;
    }

    final client = SupabaseService.client;
    if (client == null || !SupabaseService.isConfigured) {
      BorrowlyLogger.warning('Supabase client unconfigured, skipping avatar upload for: $localPath');
      return localPath;
    }

    final file = File(localPath);
    if (!await file.exists()) {
      BorrowlyLogger.warning('Local avatar image file does not exist at path: $localPath');
      return localPath;
    }

    try {
      final bytes = await file.readAsBytes();
      final fileExt = localPath.contains('.') ? localPath.split('.').last.toLowerCase() : 'jpg';
      final fileName = 'avatar_${DateTime.now().millisecondsSinceEpoch}_${localPath.hashCode}.$fileExt';
      final storagePath = 'avatars/$fileName';

      BorrowlyLogger.info('Uploading user avatar photo to Supabase Storage bucket "$bucketName": $storagePath');

      await client.storage.from(bucketName).uploadBinary(
        storagePath,
        bytes,
        fileOptions: FileOptions(
          contentType: 'image/$fileExt',
          upsert: true,
        ),
      );

      final publicUrl = client.storage.from(bucketName).getPublicUrl(storagePath);
      BorrowlyLogger.info('Successfully uploaded user avatar! Public CDN URL: $publicUrl');
      return publicUrl;
    } catch (e) {
      BorrowlyLogger.warning('Supabase Storage avatar upload notice: $e');
      return localPath;
    }
  }

  /// Uploads multiple local item images concurrently.
  static Future<List<String>> uploadItemImages(List<String> localPaths) async {
    if (localPaths.isEmpty) return const [];
    final results = await Future.wait(
      localPaths.map((path) => uploadItemImage(path)),
    );
    return results;
  }
}
