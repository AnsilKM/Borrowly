import 'package:equatable/equatable.dart';
import 'item_category.dart';

class ItemEntity extends Equatable {
  final String id;
  final String title;
  final String description;
  final ItemCategory category;
  final double dailyPrice;
  final bool isFree;
  final double depositAmount;
  final List<String> images;
  final String ownerId;
  final String ownerName;
  final String? ownerAvatar;
  final double distanceKm;
  final bool isAvailable;
  final String locationName;
  final double ratingScore;
  final int reviewCount;
  final String ownerResponseRate;
  final DateTime createdAt;

  const ItemEntity({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    this.dailyPrice = 0.0,
    this.isFree = false,
    this.depositAmount = 0.0,
    required this.images,
    required this.ownerId,
    required this.ownerName,
    this.ownerAvatar,
    required this.distanceKm,
    this.isAvailable = true,
    required this.locationName,
    this.ratingScore = 4.9,
    this.reviewCount = 12,
    this.ownerResponseRate = '< 30 mins',
    required this.createdAt,
  });

  String get formattedPrice => isFree ? 'FREE' : '₹${dailyPrice.toStringAsFixed(0)}/day';

  String get formattedDistance => '${distanceKm.toStringAsFixed(1)} km away';

  ItemEntity copyWith({
    String? id,
    String? title,
    String? description,
    ItemCategory? category,
    double? dailyPrice,
    bool? isFree,
    double? depositAmount,
    List<String>? images,
    String? ownerId,
    String? ownerName,
    String? ownerAvatar,
    double? distanceKm,
    bool? isAvailable,
    String? locationName,
    double? ratingScore,
    int? reviewCount,
    String? ownerResponseRate,
    DateTime? createdAt,
  }) {
    return ItemEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      category: category ?? this.category,
      dailyPrice: dailyPrice ?? this.dailyPrice,
      isFree: isFree ?? this.isFree,
      depositAmount: depositAmount ?? this.depositAmount,
      images: images ?? this.images,
      ownerId: ownerId ?? this.ownerId,
      ownerName: ownerName ?? this.ownerName,
      ownerAvatar: ownerAvatar ?? this.ownerAvatar,
      distanceKm: distanceKm ?? this.distanceKm,
      isAvailable: isAvailable ?? this.isAvailable,
      locationName: locationName ?? this.locationName,
      ratingScore: ratingScore ?? this.ratingScore,
      reviewCount: reviewCount ?? this.reviewCount,
      ownerResponseRate: ownerResponseRate ?? this.ownerResponseRate,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        description,
        category,
        dailyPrice,
        isFree,
        depositAmount,
        images,
        ownerId,
        ownerName,
        ownerAvatar,
        distanceKm,
        isAvailable,
        locationName,
        ratingScore,
        reviewCount,
        ownerResponseRate,
        createdAt,
      ];
}
