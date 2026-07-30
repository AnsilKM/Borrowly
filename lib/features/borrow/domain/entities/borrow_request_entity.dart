import 'package:equatable/equatable.dart';

enum BorrowRequestStatus {
  pending('Pending Owner Approval'),
  accepted('Approved — Physical Pickup Ready'),
  rejected('Declined by Owner'),
  completed('Item Returned & Completed'),
  cancelled('Cancelled');

  final String label;
  const BorrowRequestStatus(this.label);
}

class BorrowRequestEntity extends Equatable {
  final String id;
  final String itemId;
  final String itemTitle;
  final String itemImage;
  final String borrowerId;
  final String borrowerName;
  final String? borrowerAvatar;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatar;
  final DateTime startDate;
  final DateTime endDate;
  final double totalPrice;
  final double depositAmount;
  final BorrowRequestStatus status;
  final String handoverLocation;
  final DateTime createdAt;

  const BorrowRequestEntity({
    required this.id,
    required this.itemId,
    required this.itemTitle,
    required this.itemImage,
    required this.borrowerId,
    required this.borrowerName,
    this.borrowerAvatar,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatar,
    required this.startDate,
    required this.endDate,
    required this.totalPrice,
    required this.depositAmount,
    required this.status,
    required this.handoverLocation,
    required this.createdAt,
  });

  int get rentalDays => endDate.difference(startDate).inDays + 1;

  BorrowRequestEntity copyWith({
    String? id,
    String? itemId,
    String? itemTitle,
    String? itemImage,
    String? borrowerId,
    String? borrowerName,
    String? borrowerAvatar,
    String? ownerId,
    String? ownerName,
    String? ownerAvatar,
    DateTime? startDate,
    DateTime? endDate,
    double? totalPrice,
    double? depositAmount,
    BorrowRequestStatus? status,
    String? handoverLocation,
    DateTime? createdAt,
  }) {
    return BorrowRequestEntity(
      id: id ?? this.id,
      itemId: itemId ?? this.itemId,
      itemTitle: itemTitle ?? this.itemTitle,
      itemImage: itemImage ?? this.itemImage,
      borrowerId: borrowerId ?? this.borrowerId,
      borrowerName: borrowerName ?? this.borrowerName,
      borrowerAvatar: borrowerAvatar ?? this.borrowerAvatar,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      totalPrice: totalPrice ?? this.totalPrice,
      depositAmount: depositAmount ?? this.depositAmount,
      status: status ?? this.status,
      handoverLocation: handoverLocation ?? this.handoverLocation,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        itemId,
        itemTitle,
        itemImage,
        borrowerId,
        borrowerName,
        borrowerAvatar,
        ownerId,
        ownerName,
        ownerAvatar,
        startDate,
        endDate,
        totalPrice,
        depositAmount,
        status,
        handoverLocation,
        createdAt,
      ];
}
