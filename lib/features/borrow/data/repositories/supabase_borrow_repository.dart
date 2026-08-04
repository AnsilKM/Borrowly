import '../../../../core/network/supabase_service.dart';
import '../../../../core/utils/borrowly_logger.dart';
import '../../domain/entities/borrow_request_entity.dart';
import '../../domain/repositories/borrow_repository.dart';

class SupabaseBorrowRepository implements BorrowRepository {
  static final Map<String, BorrowRequestStatus> _localStatusOverrides = {};

  BorrowRequestEntity _mapRowToEntity(Map<String, dynamic> row) {
    final rowId = row['id'] as String? ?? '';
    final statusStr = (row['status'] as String? ?? 'pending').toLowerCase();
    BorrowRequestStatus status;
    if (statusStr == 'accepted' || statusStr == 'approved') {
      status = BorrowRequestStatus.accepted;
    } else if (statusStr == 'rejected' || statusStr == 'declined') {
      status = BorrowRequestStatus.rejected;
    } else if (statusStr == 'completed') {
      status = BorrowRequestStatus.completed;
    } else if (statusStr == 'cancelled' || statusStr == 'canceled') {
      status = BorrowRequestStatus.cancelled;
    } else {
      status = BorrowRequestStatus.pending;
    }

    if (_localStatusOverrides.containsKey(rowId)) {
      status = _localStatusOverrides[rowId]!;
    }

    return BorrowRequestEntity(
      id: rowId,
      itemId: row['item_id'] as String? ?? '',
      itemTitle: row['item_title'] as String? ?? 'Borrow Request',
      itemImage: row['item_image'] as String? ?? 'https://images.unsplash.com/photo-1504148455328-c376907d081c?w=600',
      borrowerId: row['borrower_id'] as String? ?? 'guest_user_id',
      borrowerName: row['borrower_name'] as String? ?? 'Alex Morgan',
      borrowerAvatar: row['borrower_avatar'] as String?,
      ownerId: row['owner_id'] as String? ?? 'user_1',
      ownerName: row['owner_name'] as String? ?? 'Marcus Vance',
      ownerAvatar: row['owner_avatar'] as String?,
      startDate: DateTime.tryParse(row['start_date'] as String? ?? '') ?? DateTime.now(),
      endDate: DateTime.tryParse(row['end_date'] as String? ?? '') ?? DateTime.now().add(const Duration(days: 2)),
      totalPrice: (row['total_price'] as num?)?.toDouble() ?? 0.0,
      depositAmount: (row['deposit_amount'] as num?)?.toDouble() ?? 0.0,
      status: status,
      handoverLocation: row['handover_location'] as String? ?? 'Neighborhood Pickup',
      createdAt: DateTime.tryParse(row['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  Future<BorrowRequestEntity> createBorrowRequest(BorrowRequestEntity request) async {
    BorrowlyLogger.event('Borrow: Create Borrow Request', parameters: {
      'itemId': request.itemId,
      'itemTitle': request.itemTitle,
      'totalPrice': request.totalPrice,
    });

    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final row = {
          'item_id': request.itemId,
          'item_title': request.itemTitle,
          'item_image': request.itemImage,
          'borrower_id': request.borrowerId,
          'borrower_name': request.borrowerName,
          'owner_id': request.ownerId,
          'owner_name': request.ownerName,
          'start_date': request.startDate.toIso8601String(),
          'end_date': request.endDate.toIso8601String(),
          'total_price': request.totalPrice,
          'deposit_amount': request.depositAmount,
          'status': request.status.name,
          'handover_location': request.handoverLocation,
          'payment_type': 'physical_cash',
        };

        final response = await client.from('borrow_requests').insert(row).select().single();
        final created = _mapRowToEntity(response);
        BorrowlyLogger.info('Borrow request created in Supabase: ${created.id}');
        return created;
      } catch (e, stack) {
        BorrowlyLogger.error('createBorrowRequest error', e, stack);
        rethrow;
      }
    }

    throw Exception('Supabase service is not available');
  }

  @override
  Future<List<BorrowRequestEntity>> getBorrowRequests({
    required String userId,
    bool isOwner = false,
  }) async {
    BorrowlyLogger.event('Borrow: Fetch Requests', parameters: {'userId': userId, 'isOwner': isOwner});
    if (userId == 'guest_user_id' || userId.isEmpty) {
      return [];
    }

    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        final column = isOwner ? 'owner_id' : 'borrower_id';
        final response = await client
            .from('borrow_requests')
            .select()
            .eq(column, userId)
            .order('created_at', ascending: false);

        final rows = response as List<dynamic>;
        return rows.map((r) => _mapRowToEntity(r as Map<String, dynamic>)).toList();
      } catch (e) {
        BorrowlyLogger.warning('getBorrowRequests error: $e');
      }
    }

    return [];
  }

  @override
  Future<BorrowRequestEntity> updateRequestStatus({
    required String requestId,
    required BorrowRequestStatus newStatus,
  }) async {
    _localStatusOverrides[requestId] = newStatus;
    BorrowlyLogger.event('Borrow: Update Status', parameters: {
      'requestId': requestId,
      'newStatus': newStatus.name,
    });

    final client = SupabaseService.client;
    if (client != null && SupabaseService.isConfigured) {
      try {
        BorrowlyLogger.info('Updating Supabase borrow_requests eq(id, $requestId) -> status: ${newStatus.name}');
        final List<dynamic> rows = await client
            .from('borrow_requests')
            .update({'status': newStatus.name})
            .eq('id', requestId)
            .select();

        BorrowlyLogger.info('Supabase updateRequestStatus returned ${rows.length} updated rows.');

        if (rows.isNotEmpty) {
          return _mapRowToEntity(rows.first as Map<String, dynamic>);
        } else {
          BorrowlyLogger.warning('Supabase update returned 0 rows. (Row ID $requestId may not exist or RLS policy blocked update).');
        }
      } catch (e, stack) {
        BorrowlyLogger.error('updateRequestStatus error', e, stack);
      }
    }

    // Return local fallback entity if remote row wasn't updated or Supabase unavailable
    return BorrowRequestEntity(
      id: requestId,
      itemId: 'local_item_id',
      itemTitle: 'Item',
      itemImage: '',
      borrowerId: 'borrower_id',
      borrowerName: 'Borrower',
      ownerId: 'owner_id',
      ownerName: 'Owner',
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 2)),
      totalPrice: 0,
      depositAmount: 0,
      status: newStatus,
      handoverLocation: 'Handover Location',
      createdAt: DateTime.now(),
    );
  }
}
