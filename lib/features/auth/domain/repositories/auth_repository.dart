import '../entities/user_entity.dart';

abstract class AuthRepository {
  /// Fetch currently authenticated user or guest profile
  Future<UserEntity?> getCurrentUser();

  /// Sign in using Google OAuth
  Future<UserEntity> signInWithGoogle();

  /// Continue browsing as Guest (Non-logged in mode)
  Future<UserEntity> continueAsGuest();

  /// Update user profile details (Name, Phone, Distance Radius)
  Future<UserEntity> updateProfile(UserEntity profile);

  /// Sign out current session
  Future<void> signOut();

  /// Stream auth state changes
  Stream<UserEntity?> get authStateChanges;
}
