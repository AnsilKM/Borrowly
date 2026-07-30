import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/repositories/supabase_borrow_repository.dart';
import '../../domain/entities/borrow_request_entity.dart';
import '../../domain/repositories/borrow_repository.dart';
import '../../domain/usecases/create_borrow_request_usecase.dart';
import '../../domain/usecases/get_borrow_requests_usecase.dart';
import '../../domain/usecases/update_borrow_status_usecase.dart';

final borrowRepositoryProvider = Provider<BorrowRepository>((ref) {
  return SupabaseBorrowRepository();
});

final createBorrowRequestUseCaseProvider = Provider<CreateBorrowRequestUseCase>((ref) {
  return CreateBorrowRequestUseCase(ref.watch(borrowRepositoryProvider));
});

final getBorrowRequestsUseCaseProvider = Provider<GetBorrowRequestsUseCase>((ref) {
  return GetBorrowRequestsUseCase(ref.watch(borrowRepositoryProvider));
});

final updateBorrowStatusUseCaseProvider = Provider<UpdateBorrowStatusUseCase>((ref) {
  return UpdateBorrowStatusUseCase(ref.watch(borrowRepositoryProvider));
});

final userBorrowRequestsProvider = FutureProvider.family<List<BorrowRequestEntity>, bool>((ref, isOwner) async {
  final usecase = ref.watch(getBorrowRequestsUseCaseProvider);
  final result = await usecase(GetBorrowRequestsParams(userId: 'guest_user_id', isOwner: isOwner));
  return result.fold(
    onSuccess: (list) => list,
    onError: (failure) => throw Exception(failure.message),
  );
});

class BorrowState {
  final bool isLoading;
  final String? errorMessage;
  final bool isSuccess;

  const BorrowState({
    this.isLoading = false,
    this.errorMessage,
    this.isSuccess = false,
  });

  BorrowState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool? isSuccess,
  }) {
    return BorrowState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
      isSuccess: isSuccess ?? this.isSuccess,
    );
  }
}

class BorrowController extends StateNotifier<BorrowState> {
  final CreateBorrowRequestUseCase _createBorrowRequestUseCase;
  final UpdateBorrowStatusUseCase _updateBorrowStatusUseCase;

  BorrowController({
    required CreateBorrowRequestUseCase createBorrowRequestUseCase,
    required UpdateBorrowStatusUseCase updateBorrowStatusUseCase,
  })  : _createBorrowRequestUseCase = createBorrowRequestUseCase,
        _updateBorrowStatusUseCase = updateBorrowStatusUseCase,
        super(const BorrowState());

  Future<bool> submitRequest(BorrowRequestEntity request) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _createBorrowRequestUseCase(request);

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        return true;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }

  Future<bool> updateStatus(String requestId, BorrowRequestStatus status) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    final result = await _updateBorrowStatusUseCase(UpdateBorrowStatusParams(
      requestId: requestId,
      newStatus: status,
    ));

    return result.fold(
      onSuccess: (_) {
        state = state.copyWith(isLoading: false, isSuccess: true);
        return true;
      },
      onError: (failure) {
        state = state.copyWith(isLoading: false, errorMessage: failure.message);
        return false;
      },
    );
  }
}

final borrowControllerProvider = StateNotifierProvider<BorrowController, BorrowState>((ref) {
  return BorrowController(
    createBorrowRequestUseCase: ref.watch(createBorrowRequestUseCaseProvider),
    updateBorrowStatusUseCase: ref.watch(updateBorrowStatusUseCaseProvider),
  );
});
