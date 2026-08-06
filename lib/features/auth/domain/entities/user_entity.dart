import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String fullName;
  final String? avatarUrl;
  final String? phone;
  final int searchRadiusKm; // 1, 2, 3, or 5 km
  final bool isGuest;
  final bool isNewUser;
  final DateTime createdAt;

  const UserEntity({
    required this.id,
    required this.email,
    required this.fullName,
    this.avatarUrl,
    this.phone,
    this.searchRadiusKm = 5,
    this.isGuest = false,
    this.isNewUser = false,
    required this.createdAt,
  });

  String get displayAvatarUrl {
    if (avatarUrl != null && avatarUrl!.isNotEmpty && !avatarUrl!.contains('ui-avatars.com')) {
      return avatarUrl!;
    }
    return 'assets/icons/app_icon.png';
  }

  factory UserEntity.guest() {
    return UserEntity(
      id: 'guest_user_id',
      email: 'guest@borrowly.app',
      fullName: 'Guest User',
      isGuest: true,
      isNewUser: false,
      searchRadiusKm: 5,
      createdAt: DateTime.now(),
    );
  }

  UserEntity copyWith({
    String? id,
    String? email,
    String? fullName,
    String? avatarUrl,
    String? phone,
    int? searchRadiusKm,
    bool? isGuest,
    bool? isNewUser,
    DateTime? createdAt,
  }) {
    return UserEntity(
      id: id ?? this.id,
      email: email ?? this.email,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      phone: phone ?? this.phone,
      searchRadiusKm: searchRadiusKm ?? this.searchRadiusKm,
      isGuest: isGuest ?? this.isGuest,
      isNewUser: isNewUser ?? this.isNewUser,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'phone': phone,
      'search_radius_km': searchRadiusKm,
      'is_guest': isGuest,
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory UserEntity.fromJson(Map<String, dynamic> json) {
    return UserEntity(
      id: json['id'] as String? ?? '',
      email: json['email'] as String? ?? '',
      fullName: json['full_name'] as String? ?? 'Borrowly User',
      avatarUrl: json['avatar_url'] as String?,
      phone: json['phone'] as String?,
      searchRadiusKm: json['search_radius_km'] as int? ?? 5,
      isGuest: json['is_guest'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        email,
        fullName,
        avatarUrl,
        phone,
        searchRadiusKm,
        isGuest,
        createdAt,
      ];
}
