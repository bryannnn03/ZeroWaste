class UserProfile {
  final String name;
  final String email;
  final int itemsTracked;
  final int wasteReduced;
  bool expiryNotifications;

  UserProfile({
    required this.name,
    required this.email,
    required this.itemsTracked,
    required this.wasteReduced,
    required this.expiryNotifications,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'email': email,
        'itemsTracked': itemsTracked,
        'wasteReduced': wasteReduced,
        'expiryNotifications': expiryNotifications,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      name: json['name'] as String? ?? '',
      email: json['email'] as String? ?? '',
      itemsTracked: (json['itemsTracked'] as num?)?.toInt() ?? 0,
      wasteReduced: (json['wasteReduced'] as num?)?.toInt() ?? 0,
      expiryNotifications: json['expiryNotifications'] as bool? ?? true,
    );
  }
}
