import 'app_role.dart';

class UserProfile {
  final String id;
  final AppRole role;
  final String phone;
  final String name;
  final String? colonyId;
  final String? colonyName;
  final String? address; // Flat / Block / House number
  final String? avatarUrl;
  final bool mustChangePassword;
  final bool suspended;
  final String? shopStatus; // pending, approved, rejected, suspended (for shop owners)
  final String? shopId;
  final String? shopName;

  const UserProfile({
    required this.id,
    required this.role,
    required this.phone,
    required this.name,
    this.colonyId,
    this.colonyName,
    this.address,
    this.avatarUrl,
    this.mustChangePassword = false,
    this.suspended = false,
    this.shopStatus,
    this.shopId,
    this.shopName,
  });

  bool get isOnboarded {
    if (role == AppRole.admin) return true;
    if (role == AppRole.customer) {
      return colonyId != null && address != null && name.trim().isNotEmpty;
    }
    if (role == AppRole.shopOwner) {
      return shopId != null || shopStatus != null;
    }
    return false;
  }

  factory UserProfile.fromJson(Map<String, dynamic> json, {Map<String, dynamic>? shopJson}) {
    return UserProfile(
      id: json['id'] as String,
      role: AppRole.fromDbString(json['role'] as String?),
      phone: json['phone'] as String? ?? '',
      name: json['name'] as String? ?? '',
      colonyId: json['colony_id'] as String?,
      colonyName: json['colonies'] != null ? json['colonies']['name'] as String? : null,
      address: json['address'] as String?,
      avatarUrl: json['avatar_url'] as String?,
      mustChangePassword: json['must_change_password'] as bool? ?? false,
      suspended: json['suspended'] as bool? ?? false,
      shopStatus: shopJson != null ? shopJson['status'] as String? : null,
      shopId: shopJson != null ? shopJson['id'] as String? : null,
      shopName: shopJson != null ? shopJson['name'] as String? : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'role': role.toDbString(),
      'phone': phone,
      'name': name,
      'colony_id': colonyId,
      'address': address,
      'avatar_url': avatarUrl,
      'must_change_password': mustChangePassword,
      'suspended': suspended,
    };
  }

  UserProfile copyWith({
    String? id,
    AppRole? role,
    String? phone,
    String? name,
    String? colonyId,
    String? colonyName,
    String? address,
    String? avatarUrl,
    bool? mustChangePassword,
    bool? suspended,
    String? shopStatus,
    String? shopId,
    String? shopName,
  }) {
    return UserProfile(
      id: id ?? this.id,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      name: name ?? this.name,
      colonyId: colonyId ?? this.colonyId,
      colonyName: colonyName ?? this.colonyName,
      address: address ?? this.address,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      mustChangePassword: mustChangePassword ?? this.mustChangePassword,
      suspended: suspended ?? this.suspended,
      shopStatus: shopStatus ?? this.shopStatus,
      shopId: shopId ?? this.shopId,
      shopName: shopName ?? this.shopName,
    );
  }
}
