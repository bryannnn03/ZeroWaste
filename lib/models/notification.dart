enum NotificationType { urgent, warning, info }

class AppNotification {
  final String id;
  final String title;
  final String message;
  final String timeAgo;
  final NotificationType type;
  final String? linkText;
  bool read;

  AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.timeAgo,
    required this.type,
    this.linkText,
    required this.read,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'message': message,
        'timeAgo': timeAgo,
        'type': type.name,
        'linkText': linkText,
        'read': read,
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    final typeStr = json['type'] as String? ?? 'info';
    final typeVal = NotificationType.values.firstWhere(
      (e) => e.name == typeStr.toLowerCase(),
      orElse: () => NotificationType.info,
    );
    return AppNotification(
      id: json['id']?.toString() ?? '',
      title: json['title'] as String? ?? '',
      message: json['message'] as String? ?? '',
      timeAgo: json['timeAgo'] as String? ?? '',
      type: typeVal,
      linkText: json['linkText'] as String?,
      read: json['read'] as bool? ?? false,
    );
  }
}
