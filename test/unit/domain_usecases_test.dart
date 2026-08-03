import 'package:flutter_test/flutter_test.dart';
import 'package:borrowly/features/item/data/repositories/supabase_item_repository.dart';
import 'package:borrowly/features/item/domain/usecases/get_nearby_items_usecase.dart';
import 'package:borrowly/features/item/domain/usecases/search_items_usecase.dart';

void main() {
  group('Borrowly Clean Architecture UseCases & Result Tests', () {
    late SupabaseItemRepository itemRepository;
    late GetNearbyItemsUseCase getNearbyItemsUseCase;
    late SearchItemsUseCase searchItemsUseCase;

    setUp(() {
      itemRepository = SupabaseItemRepository();
      getNearbyItemsUseCase = GetNearbyItemsUseCase(itemRepository);
      searchItemsUseCase = SearchItemsUseCase(itemRepository);
    });

    test('GetNearbyItemsUseCase executes with clean params', () async {
      final result = await getNearbyItemsUseCase(
        const GetNearbyItemsParams(maxDistanceKm: 5.0),
      );

      expect(result.isSuccess, isTrue);
    });

    test('SearchItemsUseCase executes search query', () async {
      final result = await searchItemsUseCase(
        const SearchItemsParams(
          query: 'Drill',
          maxDistanceKm: 5.0,
        ),
      );

      expect(result.isSuccess, isTrue);
    });
  });
}
