import '../../domain/entities/borrow_request_entity.dart';
import '../../domain/repositories/borrow_repository.dart';

class MockBorrowRepository implements BorrowRepository {
  final List<BorrowRequestEntity> _requests = [
    BorrowRequestEntity(
      id: 'req_1',
      itemId: 'item_1',
      itemTitle: 'DeWalt 20V Cordless Hammer Drill',
      itemImage: 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600',
      borrowerId: 'guest_user_id',
      borrowerName: 'Alex Morgan',
      ownerId: 'user_1',
      ownerName: 'Marcus Vance',
      ownerAvatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
      startDate: DateTime.now().add(const Duration(days: 1)),
      endDate: DateTime.now().add(const Duration(days: 3)),
      totalPrice: 16.0,
      depositAmount: 50.0,
      status: BorrowRequestStatus.pending,
      handoverLocation: 'Oakwood Drive (0.8 km)',
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
    BorrowRequestEntity(
      id: 'req_2',
      itemId: 'item_2',
      itemTitle: 'Coleman 4-Person Camping Tent',
      itemImage: 'https://images.unsplash.com/photo-1504280390367-361c6d9f38f4?w=600',
      borrowerId: 'guest_user_id',
      borrowerName: 'Alex Morgan',
      ownerId: 'user_2',
      ownerName: 'Sarah Jenkins',
      ownerAvatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
      startDate: DateTime.now().subtract(const Duration(days: 2)),
      endDate: DateTime.now().subtract(const Duration(days: 1)),
      totalPrice: 0.0,
      depositAmount: 20.0,
      status: BorrowRequestStatus.completed,
      handoverLocation: 'Pine Street (1.2 km)',
      createdAt: DateTime.now().subtract(const Duration(days: 4)),
    ),
  ];

  @override
  Future<BorrowRequestEntity> createBorrowRequest(BorrowRequestEntity request) async {
    await Future.delayed(const Duration(milliseconds: 300));
    _requests.insert(0, request);
    return request;
  }

  @override
  Future<List<BorrowRequestEntity>> getBorrowRequests({
    required String userId,
    bool isOwner = false,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    if (isOwner) {
      return _requests.where((r) => r.ownerId == userId || userId == 'guest_user_id').toList();
    }
    return _requests.where((r) => r.borrowerId == userId || userId == 'guest_user_id').toList();
  }

  @override
  Future<BorrowRequestEntity> updateRequestStatus({
    required String requestId,
    required BorrowRequestStatus newStatus,
  }) async {
    await Future.delayed(const Duration(milliseconds: 200));
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      final updated = _requests[index].copyWith(status: newStatus);
      _requests[index] = updated;
      return updated;
    }
    throw Exception('Request not found');
  }
}
