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
}
