import 'package:flutter_test/flutter_test.dart';
import 'package:borrowly/features/item/data/repositories/mock_item_repository.dart';
import 'package:borrowly/features/item/domain/repositories/item_repository.dart';
import 'package:borrowly/features/item/domain/usecases/get_nearby_items_usecase.dart';
import 'package:borrowly/features/item/domain/usecases/search_items_usecase.dart';

void main() {
  group('Borrowly Clean Architecture UseCases & Result Tests', () {
    late MockItemRepository itemRepository;
    late GetNearbyItemsUseCase getNearbyItemsUseCase;
    late SearchItemsUseCase searchItemsUseCase;

    setUp(() {
      itemRepository = MockItemRepository();
      getNearbyItemsUseCase = GetNearbyItemsUseCase(itemRepository);
      searchItemsUseCase = SearchItemsUseCase(itemRepository);
    });

    test('GetNearbyItemsUseCase returns items within 5 km radius', () async {
      final result = await getNearbyItemsUseCase(
        const GetNearbyItemsParams(maxDistanceKm: 5.0),
      );

      expect(result.isSuccess, isTrue);
      final items = result.data!;
      expect(items.isNotEmpty, isTrue);
      expect(items.every((i) => i.distanceKm <= 5.0), isTrue);
    });

    test('SearchItemsUseCase filters items by query string', () async {
      final result = await searchItemsUseCase(
        const SearchItemsParams(
          query: 'Drill',
          maxDistanceKm: 5.0,
        ),
      );

      expect(result.isSuccess, isTrue);
      final items = result.data!;
      expect(items.isNotEmpty, isTrue);
      expect(items.first.title.contains('Drill'), isTrue);
    });

    test('SearchItemsUseCase filters FREE items correctly', () async {
      final result = await searchItemsUseCase(
        const SearchItemsParams(
          query: '',
          maxDistanceKm: 5.0,
          pricingFilter: ItemPricingFilter.freeOnly,
        ),
      );

      expect(result.isSuccess, isTrue);
      final items = result.data!;
      expect(items.every((i) => i.isFree), isTrue);
    });
  });
}
