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
}
