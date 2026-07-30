import 'package:equatable/equatable.dart';

class ReviewEntity extends Equatable {
  final String id;
  final String authorName;
  final String? authorAvatar;
  final double rating;
  final String comment;
  final String itemTitle;
  final DateTime createdAt;

  const ReviewEntity({
    required this.id,
    required this.authorName,
    this.authorAvatar,
    required this.rating,
    required this.comment,
    required this.itemTitle,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [id, authorName, authorAvatar, rating, comment, itemTitle, createdAt];
}
