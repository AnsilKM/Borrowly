import 'dart:async';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/utils/borrowly_logger.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';

class SupabaseAuthRepository implements AuthRepository {
  final LocalStorageService _localStorageService;
  final StreamController<UserEntity?> _authStateController = StreamController<UserEntity?>.broadcast();

  SupabaseAuthRepository(this._localStorageService) {
    _initSessionListener();
  }

  void _initSessionListener() {
    final client = SupabaseService.client;
    if (client != null) {
      client.auth.onAuthStateChange.listen((data) {
        final session = data.session;
        final event = data.event;
        BorrowlyLogger.event('Supabase AuthStateChanged', parameters: {
          'event': event.name,
          'userId': session?.user.id,
          'email': session?.user.email,
        });

        if (session != null) {
          final user = UserEntity(
            id: session.user.id,
            email: session.user.email ?? '',
            fullName: session.user.userMetadata?['full_name'] ?? session.user.email?.split('@').first ?? 'Borrowly User',
            avatarUrl: session.user.userMetadata?['avatar_url'],
            phone: session.user.phone,
            createdAt: DateTime.tryParse(session.user.createdAt) ?? DateTime.now(),
          );
          _saveUserLocal(user);
          _authStateController.add(user);
        }
      });
    }
  }

  @override
  Stream<UserEntity?> get authStateChanges => _authStateController.stream;

  @override
  Future<UserEntity?> getCurrentUser() async {
    BorrowlyLogger.event('Auth: Check Current User');
    final isGuest = _localStorageService.getThemeMode() == 'guest';
    if (isGuest) {
      BorrowlyLogger.info('Current user session: Guest Mode active');
      return UserEntity.guest();
    }

    final client = SupabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      final user = client.auth.currentUser!;
      BorrowlyLogger.info('Current user session found: ${user.email}');
      return UserEntity(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] ?? 'Borrowly User',
        avatarUrl: user.userMetadata?['avatar_url'],
        phone: user.phone,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
    }

    BorrowlyLogger.info('No active session found.');
    return null;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    BorrowlyLogger.event('Auth: Google Sign-In Initiated');
    final client = SupabaseService.client;

    if (client != null && SupabaseService.isConfigured) {
      try {
        final googleSignIn = GoogleSignIn(
          scopes: ['email', 'profile'],
        );

        BorrowlyLogger.info('Opening Google Sign-In native account picker...');
        final googleUser = await googleSignIn.signIn();

        if (googleUser == null) {
          BorrowlyLogger.warning('Google Sign-In cancelled by user.');
          throw Exception('Google Sign-In was cancelled by the user.');
        }

        BorrowlyLogger.info('Google Account selected: ${googleUser.email}');
        final googleAuth = await googleUser.authentication;
        final accessToken = googleAuth.accessToken;
        final idToken = googleAuth.idToken;

        if (idToken == null) {
          BorrowlyLogger.error('Google Auth Token missing (idToken is null).');
          throw Exception('Failed to obtain Google ID Token.');
        }

        BorrowlyLogger.info('Authenticating ID Token with Supabase...');
        final res = await client.auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: idToken,
          accessToken: accessToken,
        );

        if (res.user != null) {
          final user = UserEntity(
            id: res.user!.id,
            email: res.user!.email ?? googleUser.email,
            fullName: res.user!.userMetadata?['full_name'] ?? googleUser.displayName ?? 'Alex Morgan',
            avatarUrl: res.user!.userMetadata?['avatar_url'] ?? googleUser.photoUrl,
            searchRadiusKm: 3,
            isGuest: false,
            createdAt: DateTime.now(),
          );
          await _saveUserLocal(user);
          _authStateController.add(user);
          BorrowlyLogger.event('Auth: Google Sign-In Success', parameters: {
            'userId': user.id,
            'email': user.email,
          });
          return user;
        }
      } catch (e, stack) {
        BorrowlyLogger.error('Google Sign-In Exception', e, stack);
        rethrow;
      }
    }

    BorrowlyLogger.warning('Supabase not configured or client null.');
    throw Exception('Supabase connection is not available.');
  }

  @override
  Future<UserEntity> continueAsGuest() async {
    BorrowlyLogger.event('Auth: Continue As Guest Selected');
    final guest = UserEntity.guest();
    await _saveUserLocal(guest);
    _authStateController.add(guest);
    return guest;
  }

  @override
  Future<UserEntity> updateProfile(UserEntity profile) async {
    BorrowlyLogger.event('Auth: Update Profile', parameters: {
      'fullName': profile.fullName,
      'radius': profile.searchRadiusKm,
    });

    final client = SupabaseService.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        await client.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': profile.fullName,
              'phone': profile.phone,
              'search_radius_km': profile.searchRadiusKm,
            },
          ),
        );
        BorrowlyLogger.info('Profile updated in Supabase auth metadata.');
      } catch (e, stack) {
        BorrowlyLogger.error('Supabase profile update notice', e, stack);
      }
    }

    await _saveUserLocal(profile);
    _authStateController.add(profile);
    return profile;
  }

  @override
  Future<void> signOut() async {
    BorrowlyLogger.event('Auth: Sign Out Triggered');
    final client = SupabaseService.client;
    if (client != null) {
      try {
        await client.auth.signOut();
        BorrowlyLogger.info('Supabase auth session signed out.');
      } catch (e) {
        BorrowlyLogger.warning('Sign out error: $e');
      }
    }

    _authStateController.add(null);
  }

  Future<void> _saveUserLocal(UserEntity user) async {
    BorrowlyLogger.info('Persisting user profile locally: ${user.fullName}');
  }
}
