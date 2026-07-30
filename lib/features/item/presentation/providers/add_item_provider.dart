import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/item_category.dart';
import '../../domain/entities/item_entity.dart';
import '../../domain/usecases/add_item_usecase.dart';
import 'home_items_provider.dart';

class AddItemFormState {
  final List<String> imagePaths;
  final String title;
  final String description;
  final ItemCategory category;
  final bool isFree;
  final double dailyPrice;
  final double depositAmount;
  final bool isLoading;
  final bool isSuccess;
  final String? errorMessage;

  const AddItemFormState({
    this.imagePaths = const [],
    this.title = '',
    this.description = '',
    this.category = ItemCategory.tools,
    this.isFree = false,
    this.dailyPrice = 5.0,
    this.depositAmount = 0.0,
    this.isLoading = false,
    this.isSuccess = false,
    this.errorMessage,
  });

  AddItemFormState copyWith({
    List<String>? imagePaths,
    String? title,
    String? description,
    ItemCategory? category,
    bool? isFree,
    double? dailyPrice,
    double? depositAmount,
    bool? isLoading,
    bool? isSuccess,
    String? errorMessage,
  }) {
    return AddItemFormState(
      imagePaths: imagePaths ?? this.imagePaths,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      isFree: isFree ?? this.isFree,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      isLoading: isLoading ?? this.isLoading,
      isSuccess: isSuccess ?? this.isSuccess,
      errorMessage: errorMessage,
    );
  }
}

final addItemUseCaseProvider = Provider<AddItemUseCase>((ref) {
  return AddItemUseCase(ref.watch(itemRepositoryProvider));
});

class AddItemNotifier extends StateNotifier<AddItemFormState> {
  final AddItemUseCase _addItemUseCase;

  AddItemNotifier(this._addItemUseCase) : super(const AddItemFormState());

  void addImagePath(String path) {
    state = state.copyWith(imagePaths: [...state.imagePaths, path]);
  }

  void removeImagePath(int index) {
    final list = [...state.imagePaths];
    if (index >= 0 && index < list.length) {
      list.removeAt(index);
      state = state.copyWith(imagePaths: list);
    }
  }

  void setTitle(String title) => state = state.copyWith(title: title);
  void setDescription(String desc) => state = state.copyWith(description: desc);
  void setCategory(ItemCategory cat) => state = state.copyWith(category: cat);
  void setIsFree(bool isFree) => state = state.copyWith(isFree: isFree);
  void setDailyPrice(double price) => state = state.copyWith(dailyPrice: price);
  void setDepositAmount(double deposit) => state = state.copyWith(depositAmount: deposit);

  Future<bool> submitListing({
    required String ownerId,
    required String ownerName,
    String? ownerAvatar,
    required double searchRadiusKm,
  }) async {
    if (state.title.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter an item title');
      return false;
    }
    if (state.description.trim().isEmpty) {
      state = state.copyWith(errorMessage: 'Please enter a description');
      return false;
    }

    state = state.copyWith(isLoading: true, errorMessage: null);

    final defaultImage = state.imagePaths.isNotEmpty
        ? state.imagePaths.first
        : 'https://images.unsplash.com/photo-1581578731548-c64695cc6952?w=600';

    final newItem = ItemEntity(
      id: 'item_${DateTime.now().millisecondsSinceEpoch}',
      title: state.title.trim(),
      description: state.description.trim(),
      category: state.category,
      dailyPrice: state.isFree ? 0.0 : state.dailyPrice,
      isFree: state.isFree,
      depositAmount: state.depositAmount,
      images: [defaultImage],
      ownerId: ownerId,
      ownerName: ownerName,
      ownerAvatar: ownerAvatar,
      distanceKm: 0.5,
      isAvailable: true,
      locationName: 'My Neighborhood (0.5 km)',
      createdAt: DateTime.now(),
    );

    final result = await _addItemUseCase(newItem);

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

final addItemProvider = StateNotifierProvider<AddItemNotifier, AddItemFormState>((ref) {
  return AddItemNotifier(ref.watch(addItemUseCaseProvider));
});
