import '../entities/borrow_request_entity.dart';

abstract class BorrowRepository {
  /// Submit a new borrow request
  Future<BorrowRequestEntity> createBorrowRequest(BorrowRequestEntity request);

  /// Fetch requests for user (as borrower or owner)
  Future<List<BorrowRequestEntity>> getBorrowRequests({
    required String userId,
    bool isOwner = false,
  });

  /// Update status (Accept, Reject, Complete, Cancel)
  Future<BorrowRequestEntity> updateRequestStatus({
    required String requestId,
    required BorrowRequestStatus newStatus,
  });
}
