import 'dart:async';
import 'package:flutter/foundation.dart';
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

    // Fast Hive Local Profile Cache (< 5ms response time)
    final cached = _localStorageService.getCachedUserProfile();
    if (cached != null) {
      BorrowlyLogger.info('Loaded cached user profile from Hive: ${cached['full_name']}');
      return UserEntity(
        id: cached['id'] as String? ?? 'guest',
        email: cached['email'] as String? ?? '',
        fullName: cached['full_name'] as String? ?? 'Borrowly User',
        avatarUrl: cached['avatar_url'] as String?,
        phone: cached['phone'] as String?,
        searchRadiusKm: cached['search_radius_km'] as int? ?? 5,
        isGuest: cached['is_guest'] as bool? ?? false,
        createdAt: DateTime.tryParse(cached['created_at'] as String? ?? '') ?? DateTime.now(),
      );
    }

    final client = SupabaseService.client;
    if (client != null && client.auth.currentSession != null) {
      final user = client.auth.currentUser!;
      BorrowlyLogger.info('Current user session found: ${user.email}');
      final entity = UserEntity(
        id: user.id,
        email: user.email ?? '',
        fullName: user.userMetadata?['full_name'] ?? 'Borrowly User',
        avatarUrl: user.userMetadata?['avatar_url'],
        phone: user.userMetadata?['phone'] as String? ?? user.phone,
        searchRadiusKm: (user.userMetadata?['search_radius_km'] as num?)?.toInt() ?? 5,
        createdAt: DateTime.tryParse(user.createdAt) ?? DateTime.now(),
      );
      _saveUserLocal(entity);
      return entity;
    }

    BorrowlyLogger.info('No active session found.');
    return null;
  }

  @override
  Future<UserEntity> signInWithGoogle() async {
    BorrowlyLogger.event('Auth: Google Sign-In Initiated');
    final client = SupabaseService.client;

    if (client != null && SupabaseService.isConfigured) {
      // 1. Try Native Google Sign-In SDK
      try {
        final googleSignIn = GoogleSignIn(
          serverClientId: '76981842422-qqe0i49gbhcl1944mddlqur2n7tnombs.apps.googleusercontent.com',
          scopes: ['email', 'profile'],
        );

        BorrowlyLogger.info('Opening Google Sign-In native account picker...');
        final googleUser = await googleSignIn.signIn();

        if (googleUser != null) {
          BorrowlyLogger.info('Google Account selected: ${googleUser.email}');
          final googleAuth = await googleUser.authentication;
          final accessToken = googleAuth.accessToken;
          final idToken = googleAuth.idToken;

          if (idToken != null) {
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
          }
        } else {
          BorrowlyLogger.warning('Google Sign-In cancelled by user.');
          throw Exception('Google Sign-In was cancelled by the user.');
        }
      } catch (e) {
        BorrowlyLogger.warning('Native GoogleSignIn notice ($e). Triggering Supabase OAuth Web Flow...');
      }

      // 2. Direct Supabase Web OAuth Flow Fallback (Fixes Android ApiException 10)
      try {
        final bool success = await client.auth.signInWithOAuth(
          OAuthProvider.google,
          redirectTo: kIsWeb ? null : 'io.supabase.borrowly://login-callback',
        );

        if (success && client.auth.currentUser != null) {
          final u = client.auth.currentUser!;
          final user = UserEntity(
            id: u.id,
            email: u.email ?? '',
            fullName: u.userMetadata?['full_name'] ?? 'Borrowly User',
            avatarUrl: u.userMetadata?['avatar_url'],
            searchRadiusKm: 3,
            isGuest: false,
            createdAt: DateTime.now(),
          );
          await _saveUserLocal(user);
          _authStateController.add(user);
          return user;
        }
      } catch (e, stack) {
        BorrowlyLogger.error('Supabase OAuth Error', e, stack);
        rethrow;
      }
    }

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
      'phone': profile.phone,
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

        // Also upsert user into public.users database table
        await client.from('users').upsert({
          'id': client.auth.currentUser!.id,
          'full_name': profile.fullName,
          'email': profile.email,
          'phone': profile.phone,
          'avatar_url': profile.avatarUrl,
          'search_radius_km': profile.searchRadiusKm,
        });

        BorrowlyLogger.info('Profile and phone number updated in Supabase.');
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
    await _localStorageService.clearCachedUserProfile();
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
    BorrowlyLogger.info('Persisting user profile locally in Hive: ${user.fullName}');
    await _localStorageService.cacheUserProfile({
      'id': user.id,
      'email': user.email,
      'full_name': user.fullName,
      'avatar_url': user.avatarUrl,
      'phone': user.phone,
      'search_radius_km': user.searchRadiusKm,
      'is_guest': user.isGuest,
      'created_at': user.createdAt.toIso8601String(),
    });
  }
}
