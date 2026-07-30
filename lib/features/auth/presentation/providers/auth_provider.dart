import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/storage/local_storage_service.dart';
import '../../../../core/usecases/usecase.dart';
import '../../data/repositories/supabase_auth_repository.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/continue_as_guest_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/sign_in_with_google_usecase.dart';
import '../../domain/usecases/update_profile_usecase.dart';
import '../widgets/login_prompt_bottom_sheet.dart';

enum AuthStatus { initial, authenticated, guest, unauthenticated, loading, error }

class AuthState {
  final AuthStatus status;
  final UserEntity? user;
  final String? errorMessage;

  const AuthState({
    this.status = AuthStatus.initial,
    this.user,
    this.errorMessage,
  });

  bool get isAuthenticated => status == AuthStatus.authenticated && user != null && !user!.isGuest;
  bool get isGuest => status == AuthStatus.guest || (user != null && user!.isGuest);

  AuthState copyWith({
    AuthStatus? status,
    UserEntity? user,
    String? errorMessage,
  }) {
    return AuthState(
      status: status ?? this.status,
      user: user ?? this.user,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final storage = ref.watch(localStorageServiceProvider);
  return SupabaseAuthRepository(storage);
});

// Auth Domain UseCase Providers
final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>((ref) {
  return GetCurrentUserUseCase(ref.watch(authRepositoryProvider));
});

final signInWithGoogleUseCaseProvider = Provider<SignInWithGoogleUseCase>((ref) {
  return SignInWithGoogleUseCase(ref.watch(authRepositoryProvider));
});

final continueAsGuestUseCaseProvider = Provider<ContinueAsGuestUseCase>((ref) {
  return ContinueAsGuestUseCase(ref.watch(authRepositoryProvider));
});

final updateProfileUseCaseProvider = Provider<UpdateProfileUseCase>((ref) {
  return UpdateProfileUseCase(ref.watch(authRepositoryProvider));
});

final authProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  return AuthController(
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
    signInWithGoogleUseCase: ref.watch(signInWithGoogleUseCaseProvider),
    continueAsGuestUseCase: ref.watch(continueAsGuestUseCaseProvider),
    updateProfileUseCase: ref.watch(updateProfileUseCaseProvider),
    authRepository: ref.watch(authRepositoryProvider),
  );
});

class AuthController extends StateNotifier<AuthState> {
  final GetCurrentUserUseCase _getCurrentUserUseCase;
  final SignInWithGoogleUseCase _signInWithGoogleUseCase;
  final ContinueAsGuestUseCase _continueAsGuestUseCase;
  final UpdateProfileUseCase _updateProfileUseCase;
  final AuthRepository _authRepository;

  AuthController({
    required GetCurrentUserUseCase getCurrentUserUseCase,
    required SignInWithGoogleUseCase signInWithGoogleUseCase,
    required ContinueAsGuestUseCase continueAsGuestUseCase,
    required UpdateProfileUseCase updateProfileUseCase,
    required AuthRepository authRepository,
  })  : _getCurrentUserUseCase = getCurrentUserUseCase,
        _signInWithGoogleUseCase = signInWithGoogleUseCase,
        _continueAsGuestUseCase = continueAsGuestUseCase,
        _updateProfileUseCase = updateProfileUseCase,
        _authRepository = authRepository,
        super(const AuthState()) {
    checkInitialSession();
  }

  Future<void> checkInitialSession() async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _getCurrentUserUseCase(const NoParams());

    result.fold(
      onSuccess: (user) async {
        if (user != null) {
          state = AuthState(
            status: user.isGuest ? AuthStatus.guest : AuthStatus.authenticated,
            user: user,
          );
        } else {
          final guestResult = await _continueAsGuestUseCase(const NoParams());
          guestResult.fold(
            onSuccess: (guest) => state = AuthState(status: AuthStatus.guest, user: guest),
            onError: (f) => state = AuthState(status: AuthStatus.error, errorMessage: f.message),
          );
        }
      },
      onError: (failure) => state = AuthState(status: AuthStatus.error, errorMessage: failure.message),
    );
  }

  Future<void> signInWithGoogle() async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _signInWithGoogleUseCase(const NoParams());
    result.fold(
      onSuccess: (user) => state = AuthState(status: AuthStatus.authenticated, user: user),
      onError: (failure) => state = AuthState(status: AuthStatus.error, errorMessage: failure.message),
    );
  }

  Future<void> continueAsGuest() async {
    state = state.copyWith(status: AuthStatus.loading);
    final result = await _continueAsGuestUseCase(const NoParams());
    result.fold(
      onSuccess: (guest) => state = AuthState(status: AuthStatus.guest, user: guest),
      onError: (failure) => state = AuthState(status: AuthStatus.error, errorMessage: failure.message),
    );
  }

  Future<void> updateProfile({
    required String fullName,
    required String phone,
    required int searchRadiusKm,
  }) async {
    if (state.user == null) return;
    state = state.copyWith(status: AuthStatus.loading);

    final updated = state.user!.copyWith(
      fullName: fullName,
      phone: phone,
      searchRadiusKm: searchRadiusKm,
      isGuest: false,
    );

    final result = await _updateProfileUseCase(updated);
    result.fold(
      onSuccess: (saved) => state = AuthState(status: AuthStatus.authenticated, user: saved),
      onError: (failure) => state = AuthState(status: AuthStatus.error, errorMessage: failure.message),
    );
  }

  Future<void> signOut() async {
    state = state.copyWith(status: AuthStatus.loading);
    await _authRepository.signOut();
    final guestResult = await _continueAsGuestUseCase(const NoParams());
    guestResult.fold(
      onSuccess: (guest) => state = AuthState(status: AuthStatus.guest, user: guest),
      onError: (failure) => state = AuthState(status: AuthStatus.error, errorMessage: failure.message),
    );
  }

  void executeProtectedAction(BuildContext context, {required String actionTitle, required VoidCallback onAuthenticated}) {
    if (state.isAuthenticated) {
      onAuthenticated();
    } else {
      LoginPromptBottomSheet.show(context, actionTitle: actionTitle);
    }
  }
}
