import 'dart:io';
import 'package:flutter/material.dart';

/// Helper utility that returns the appropriate [ImageProvider] for user avatar displays.
/// Defaults to the Borrowly app icon asset ('assets/icons/app_icon.png') when no custom photo is set.
ImageProvider getAvatarImageProvider(String? avatarUrl) {
  if (avatarUrl == null || avatarUrl.isEmpty || avatarUrl.startsWith('assets/')) {
    return const AssetImage('assets/icons/app_icon.png');
  }
  if (avatarUrl.startsWith('http://') || avatarUrl.startsWith('https://')) {
    return NetworkImage(avatarUrl);
  }
  try {
    final file = File(avatarUrl);
    if (file.existsSync() && file.lengthSync() > 0) {
      return FileImage(file);
    }
  } catch (_) {}
  return const AssetImage('assets/icons/app_icon.png');
}
