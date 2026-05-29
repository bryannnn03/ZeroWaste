import 'package:flutter_test/flutter_test.dart';
import 'package:zerowaste/models/notification.dart';

void main() {
  group('NotificationType enum', () {
    test('has three values: urgent, warning, info', () {
      expect(NotificationType.values, hasLength(3));
      expect(NotificationType.values, containsAll([
        NotificationType.urgent,
        NotificationType.warning,
        NotificationType.info,
      ]));
    });
  });

  group('AppNotification', () {
    group('constructor', () {
      test('stores all required fields correctly', () {
        final n = AppNotification(
          id: 'notif-1',
          title: 'Chicken expiring TODAY!',
          message: 'Use them now or they will go to waste.',
          timeAgo: '2h ago',
          type: NotificationType.urgent,
          read: false,
        );

        expect(n.id, 'notif-1');
        expect(n.title, 'Chicken expiring TODAY!');
        expect(n.message, 'Use them now or they will go to waste.');
        expect(n.timeAgo, '2h ago');
        expect(n.type, NotificationType.urgent);
        expect(n.read, isFalse);
        expect(n.linkText, isNull);
      });

      test('linkText is optional and defaults to null', () {
        final n = AppNotification(
          id: 'n2',
          title: 'Milk expiring soon',
          message: 'Plan a meal.',
          timeAgo: '1d ago',
          type: NotificationType.warning,
          read: false,
        );
        expect(n.linkText, isNull);
      });

      test('accepts an explicit linkText', () {
        final n = AppNotification(
          id: 'n3',
          title: 'Items nearing expiry',
          message: 'Check inventory.',
          timeAgo: '3d ago',
          type: NotificationType.info,
          read: true,
          linkText: 'View Inventory',
        );
        expect(n.linkText, 'View Inventory');
      });
    });

    group('read field mutability', () {
      test('read field can be mutated from false to true', () {
        final n = AppNotification(
          id: 'n4',
          title: 'Alert',
          message: 'Message',
          timeAgo: 'now',
          type: NotificationType.info,
          read: false,
        );
        expect(n.read, isFalse);
        n.read = true;
        expect(n.read, isTrue);
      });

      test('read field can be mutated from true to false', () {
        final n = AppNotification(
          id: 'n5',
          title: 'Alert',
          message: 'Message',
          timeAgo: 'now',
          type: NotificationType.info,
          read: true,
        );
        expect(n.read, isTrue);
        n.read = false;
        expect(n.read, isFalse);
      });
    });

    group('notification types', () {
      test('urgent type is stored correctly', () {
        final n = AppNotification(
          id: 'n6',
          title: 'Urgent!',
          message: 'Act now.',
          timeAgo: 'just now',
          type: NotificationType.urgent,
          read: false,
        );
        expect(n.type, NotificationType.urgent);
      });

      test('warning type is stored correctly', () {
        final n = AppNotification(
          id: 'n7',
          title: 'Warning',
          message: 'Plan soon.',
          timeAgo: '1h ago',
          type: NotificationType.warning,
          read: false,
        );
        expect(n.type, NotificationType.warning);
      });

      test('info type is stored correctly', () {
        final n = AppNotification(
          id: 'n8',
          title: 'Info',
          message: 'Items nearing expiry.',
          timeAgo: '2d ago',
          type: NotificationType.info,
          read: true,
        );
        expect(n.type, NotificationType.info);
      });
    });

    group('list operations', () {
      test('can filter unread notifications from a list', () {
        final notifications = [
          AppNotification(id: 'a', title: 'A', message: '', timeAgo: '', type: NotificationType.info, read: true),
          AppNotification(id: 'b', title: 'B', message: '', timeAgo: '', type: NotificationType.urgent, read: false),
          AppNotification(id: 'c', title: 'C', message: '', timeAgo: '', type: NotificationType.warning, read: false),
        ];
        final unread = notifications.where((n) => !n.read).toList();
        expect(unread, hasLength(2));
        expect(unread.map((n) => n.id), containsAll(['b', 'c']));
      });

      test('can mark all notifications as read', () {
        final notifications = [
          AppNotification(id: 'x', title: 'X', message: '', timeAgo: '', type: NotificationType.info, read: false),
          AppNotification(id: 'y', title: 'Y', message: '', timeAgo: '', type: NotificationType.urgent, read: false),
        ];
        for (final n in notifications) {
          n.read = true;
        }
        expect(notifications.every((n) => n.read), isTrue);
      });
    });

    group('serialization and null safety', () {
      test('toJson returns expected map', () {
        final notif = AppNotification(
          id: 'notif-123',
          title: 'Expiring Item',
          message: 'Detail message',
          timeAgo: '1h ago',
          type: NotificationType.urgent,
          linkText: 'Resolve',
          read: true,
        );
        final json = notif.toJson();
        expect(json['id'], 'notif-123');
        expect(json['title'], 'Expiring Item');
        expect(json['message'], 'Detail message');
        expect(json['timeAgo'], '1h ago');
        expect(json['type'], 'urgent');
        expect(json['linkText'], 'Resolve');
        expect(json['read'], isTrue);
      });

      test('fromJson parses standard structure correctly', () {
        final raw = {
          'id': 'notif-abc',
          'title': 'New Item',
          'message': 'Parsed correctly',
          'timeAgo': 'now',
          'type': 'warning',
          'linkText': null,
          'read': false,
        };
        final notif = AppNotification.fromJson(raw);
        expect(notif.id, 'notif-abc');
        expect(notif.title, 'New Item');
        expect(notif.message, 'Parsed correctly');
        expect(notif.timeAgo, 'now');
        expect(notif.type, NotificationType.warning);
        expect(notif.linkText, isNull);
        expect(notif.read, isFalse);
      });

      test('fromJson handles null / missing fields safely', () {
        final notif = AppNotification.fromJson({});
        expect(notif.id, '');
        expect(notif.title, '');
        expect(notif.message, '');
        expect(notif.timeAgo, '');
        expect(notif.type, NotificationType.info);
        expect(notif.linkText, isNull);
        expect(notif.read, isFalse);
      });
    });
  });
}
