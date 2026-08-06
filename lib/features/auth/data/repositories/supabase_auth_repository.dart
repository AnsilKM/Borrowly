import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/network/supabase_service.dart';
import '../../../../core/network/supabase_storage_service.dart';
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
              final user = await _resolveOrCreateUserProfile(
                client,
                res.user!,
                googleDisplayName: googleUser.displayName,
                googlePhotoUrl: googleUser.photoUrl,
              );
              BorrowlyLogger.event('Auth: Google Sign-In Success', parameters: {
                'userId': user.id,
                'email': user.email,
                'isNewUser': user.isNewUser,
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
          final user = await _resolveOrCreateUserProfile(client, u);
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

    String uploadedAvatarUrl = profile.avatarUrl ?? '';
    if (uploadedAvatarUrl.isNotEmpty &&
        !uploadedAvatarUrl.startsWith('http://') &&
        !uploadedAvatarUrl.startsWith('https://') &&
        !uploadedAvatarUrl.startsWith('assets/')) {
      uploadedAvatarUrl = await SupabaseStorageService.uploadAvatarImage(uploadedAvatarUrl);
    } else if (uploadedAvatarUrl.isEmpty) {
      uploadedAvatarUrl = profile.displayAvatarUrl;
    }

    final finalProfile = profile.copyWith(avatarUrl: uploadedAvatarUrl);

    final client = SupabaseService.client;
    if (client != null && client.auth.currentUser != null) {
      try {
        await client.auth.updateUser(
          UserAttributes(
            data: {
              'full_name': finalProfile.fullName,
              'phone': finalProfile.phone,
              'avatar_url': finalProfile.avatarUrl,
              'search_radius_km': finalProfile.searchRadiusKm,
            },
          ),
        );

        // Also upsert user into public.users database table
        await client.from('users').upsert({
          'id': client.auth.currentUser!.id,
          'full_name': finalProfile.fullName,
          'email': finalProfile.email,
          'phone': finalProfile.phone,
          'avatar_url': finalProfile.avatarUrl,
          'search_radius_km': finalProfile.searchRadiusKm,
        });

        // Global propagation: update owner_name and owner_avatar across all items owned by user
        try {
          await client.from('items').update({
            'owner_name': finalProfile.fullName,
            'owner_avatar': finalProfile.avatarUrl,
          }).eq('owner_id', client.auth.currentUser!.id);
          BorrowlyLogger.info('Propagated updated user name "${finalProfile.fullName}" and avatar to user listings in Supabase.');
        } catch (e) {
          BorrowlyLogger.warning('Global item owner update notice: $e');
        }

        BorrowlyLogger.info('Profile and phone number updated in Supabase.');
      } catch (e, stack) {
        BorrowlyLogger.error('Supabase profile update notice', e, stack);
      }
    }

    final finalUser = finalProfile;

    // Update local Hive cache for items owned by current user
    try {
      final cached = _localStorageService.getCachedNearbyItems();
      final updated = cached.map((itemMap) {
        if (itemMap['owner_id'] == finalUser.id) {
          final m = Map<String, dynamic>.from(itemMap);
          m['owner_name'] = finalUser.fullName;
          m['owner_avatar'] = finalUser.avatarUrl;
          return m;
        }
        return itemMap;
      }).toList();
      _localStorageService.cacheNearbyItems(updated);
    } catch (_) {}

    await _saveUserLocal(finalUser);
    _authStateController.add(finalUser);
    return finalUser;
  }

  @override
  Future<UserEntity> signInWithEmail({required String email, required String password}) async {
    BorrowlyLogger.event('Auth: Email Sign-In Initiated', parameters: {'email': email});
    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      final res = await client.auth.signInWithPassword(
        email: email,
        password: password,
      );

      if (res.user != null) {
        final u = res.user!;
        final user = UserEntity(
          id: u.id,
          email: u.email ?? email,
          fullName: u.userMetadata?['full_name'] ?? u.email?.split('@').first ?? 'Borrowly User',
          avatarUrl: u.userMetadata?['avatar_url'],
          searchRadiusKm: (u.userMetadata?['search_radius_km'] as num?)?.toInt() ?? 5,
          isGuest: false,
          createdAt: DateTime.now(),
        );
        await _saveUserLocal(user);
        _authStateController.add(user);
        BorrowlyLogger.event('Auth: Email Sign-In Success', parameters: {'userId': user.id, 'email': user.email});
        return user;
      }
    }
    throw Exception('Failed to sign in with email/password. Please check credentials.');
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

  Future<UserEntity> _resolveOrCreateUserProfile(
    SupabaseClient client,
    User authUser, {
    String? googleDisplayName,
    String? googlePhotoUrl,
  }) async {
    Map<String, dynamic>? dbUserRow;
    try {
      final res = await client.from('users').select().eq('id', authUser.id).maybeSingle();
      if (res != null) {
        dbUserRow = Map<String, dynamic>.from(res as Map);
      }
    } catch (e) {
      BorrowlyLogger.warning('Database check user notice: $e');
    }

    final bool isNew = dbUserRow == null;

    if (isNew) {
      BorrowlyLogger.info('NEW USER DETECTED: First-time Google login for ${authUser.email}');
      final initialName = googleDisplayName ?? authUser.userMetadata?['full_name'] ?? authUser.email?.split('@').first ?? 'Borrowly User';
      final initialAvatar = googlePhotoUrl ?? authUser.userMetadata?['avatar_url'];

      try {
        await client.from('users').insert({
          'id': authUser.id,
          'email': authUser.email ?? '',
          'full_name': initialName,
          'avatar_url': initialAvatar,
          'search_radius_km': 5,
        });
      } catch (e) {
        BorrowlyLogger.warning('Insert initial user row notice: $e');
      }

      final newUser = UserEntity(
        id: authUser.id,
        email: authUser.email ?? '',
        fullName: initialName,
        avatarUrl: initialAvatar,
        searchRadiusKm: 5,
        isGuest: false,
        isNewUser: true,
        createdAt: DateTime.now(),
      );
      await _saveUserLocal(newUser);
      _authStateController.add(newUser);
      return newUser;
    } else {
      BorrowlyLogger.info('EXISTING USER DETECTED: Continuing session for ${dbUserRow['full_name']} (${authUser.email})');
      final existingUser = UserEntity(
        id: authUser.id,
        email: authUser.email ?? dbUserRow['email'] as String? ?? '',
        fullName: dbUserRow['full_name'] as String? ?? authUser.userMetadata?['full_name'] ?? 'Borrowly User',
        avatarUrl: dbUserRow['avatar_url'] as String? ?? authUser.userMetadata?['avatar_url'],
        phone: dbUserRow['phone'] as String? ?? authUser.phone,
        searchRadiusKm: (dbUserRow['search_radius_km'] as num?)?.toInt() ?? 5,
        isGuest: false,
        isNewUser: false,
        createdAt: DateTime.tryParse(dbUserRow['created_at'] as String? ?? '') ?? DateTime.now(),
      );
      await _saveUserLocal(existingUser);
      _authStateController.add(existingUser);
      return existingUser;
    }
  }
}
