import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerowaste/supabase_client.dart';
import 'package:zerowaste/models/food_item.dart';
import 'package:zerowaste/models/meal_suggestion.dart';
import 'package:zerowaste/screens/login_screen.dart';
import 'package:zerowaste/screens/register_screen.dart';
import 'package:zerowaste/screens/inventory_screen.dart';
import 'package:zerowaste/screens/scan_screen.dart';
import 'package:zerowaste/screens/receipt_review_screen.dart';
import 'package:zerowaste/screens/meals_screen.dart';
import 'package:zerowaste/screens/urgency_dashboard_screen.dart';
import 'package:zerowaste/screens/home_screen.dart';
import 'package:zerowaste/screens/profile_screen.dart';
import 'package:zerowaste/screens/edit_profile_screen.dart';
import 'package:zerowaste/screens/change_password_screen.dart';
import 'package:zerowaste/screens/main_shell.dart';
import 'package:zerowaste/screens/notifications_screen.dart';
import 'package:zerowaste/services/receipt_ocr_service.dart';
import 'package:lucide_icons/lucide_icons.dart';

// ── Mocks & Fakes ────────────────────────────────────────────────────────────
class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}
class MockUser extends Mock implements User {}
class MockSession extends Mock implements Session {}
class MockRealtimeClient extends Mock implements RealtimeClient {}
class MockRealtimeChannel extends Mock implements RealtimeChannel {}
class MockUserResponse extends Mock implements UserResponse {}

class FakeSupabaseQueryBuilder extends Fake implements SupabaseQueryBuilder {
  final dynamic value;
  FakeSupabaseQueryBuilder(this.value);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> select([String columns = '*']) {
    return FakePostgrestFilterBuilder(value);
  }

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> update(Map values) {
    return FakePostgrestFilterBuilder(value);
  }
}

class FakePostgrestFilterBuilder extends Fake implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {
  final dynamic value;
  FakePostgrestFilterBuilder(this.value);

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> eq(String column, Object? value) => this;

  @override
  PostgrestFilterBuilder<List<Map<String, dynamic>>> neq(String column, Object? value) => this;

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool? ascending,
    bool? nullsFirst,
    String? foreignTable,
  }) {
    return FakePostgrestTransformBuilder(value);
  }

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue(value as List<Map<String, dynamic>>));
  }
}

class FakePostgrestTransformBuilder extends Fake implements PostgrestTransformBuilder<List<Map<String, dynamic>>> {
  final dynamic value;
  FakePostgrestTransformBuilder(this.value);

  @override
  PostgrestTransformBuilder<List<Map<String, dynamic>>> order(
    String column, {
    bool? ascending,
    bool? nullsFirst,
    String? foreignTable,
  }) => this;

  @override
  Future<R> then<R>(
    FutureOr<R> Function(List<Map<String, dynamic>>) onValue, {
    Function? onError,
  }) {
    return Future.value(onValue(value as List<Map<String, dynamic>>));
  }
}

void main() {
  late MockSupabaseClient mockClient;
  late MockGoTrueClient mockAuth;
  late MockUser mockUser;
  late MockSession mockSession;

  setUpAll(() {
    registerFallbackValue(UserAttributes());
    registerFallbackValue(PostgresChangeEvent.all);
  });

  setUp(() {
    mockClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();
    mockUser = MockUser();
    mockSession = MockSession();

    // Stub default Auth behaviors
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockAuth.currentSession).thenReturn(mockSession);
    when(() => mockUser.id).thenReturn('fake-user-id');
    when(() => mockUser.email).thenReturn('test@example.com');
    when(() => mockUser.userMetadata).thenReturn({'full_name': 'Test User', 'expiry_notifications': true});

    // Stub real-time channel behaviors
    final mockChannel = MockRealtimeChannel();
    when(() => mockClient.channel(any())).thenReturn(mockChannel);
    when(() => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          callback: any(named: 'callback'),
        )).thenReturn(mockChannel);
    when(() => mockChannel.subscribe()).thenReturn(mockChannel);
    when(() => mockChannel.unsubscribe()).thenAnswer((_) async => 'ok');

    // Set the global supabase variable to our mock
    supabase = mockClient;
  });

  group('LoginScreen', () {
    testWidgets('shows warning on empty email/password login click', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));
      await tester.tap(find.text('Login'));
      await tester.pump();
      expect(find.text('Please enter your email and password.'), findsOneWidget);
    });

    testWidgets('shows error SnackBar on invalid credentials', (tester) async {
      when(() => mockAuth.signInWithPassword(
            email: 'wrong@example.com',
            password: 'pwd',
          )).thenThrow(const AuthException('Invalid login credentials'));

      await tester.pumpWidget(const MaterialApp(home: LoginScreen()));

      // Enter email and password
      await tester.enterText(find.byType(TextField).at(0), 'wrong@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'pwd');
      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.text('Invalid login credentials'), findsOneWidget);
    });

    testWidgets('handles successful login and loading state', (tester) async {
      final completer = Completer<AuthResponse>();
      when(() => mockAuth.signInWithPassword(
            email: 'correct@example.com',
            password: 'password123',
          )).thenAnswer((_) => completer.future);

      await tester.pumpWidget(MaterialApp(
        routes: {
          '/main': (context) => const Scaffold(body: Text('Main Shell Mock')),
        },
        home: const LoginScreen(),
      ));

      await tester.enterText(find.byType(TextField).at(0), 'correct@example.com');
      await tester.enterText(find.byType(TextField).at(1), 'password123');

      await tester.tap(find.text('Login'));
      await tester.pump(); // Start loading
      
      // Verify loading state indicator
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      completer.complete(AuthResponse(session: mockSession, user: mockUser));
      await tester.pumpAndSettle(); // Navigate
      expect(find.text('Main Shell Mock'), findsOneWidget);
    });
  });

  group('RegisterScreen', () {
    testWidgets('requires matching confirm password and minimum length', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      await tester.enterText(find.byType(TextField).at(0), 'John Doe');
      await tester.enterText(find.byType(TextField).at(1), 'john@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'pwd123');
      await tester.enterText(find.byType(TextField).at(3), 'pwd321');

      final btn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pump();
      expect(find.text('Passwords do not match.'), findsOneWidget);
    });

    testWidgets('displays error on duplicate email registration', (tester) async {
      when(() => mockAuth.signUp(
            email: 'duplicate@example.com',
            password: 'password123',
            data: {'full_name': 'John'},
          )).thenThrow(const AuthException('User already exists'));

      await tester.pumpWidget(const MaterialApp(home: RegisterScreen()));

      await tester.enterText(find.byType(TextField).at(0), 'John');
      await tester.enterText(find.byType(TextField).at(1), 'duplicate@example.com');
      await tester.enterText(find.byType(TextField).at(2), 'password123');
      await tester.enterText(find.byType(TextField).at(3), 'password123');

      final btn = find.widgetWithText(ElevatedButton, 'Create Account');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pump();

      expect(find.text('User already exists'), findsOneWidget);
    });
  });

  group('InventoryScreen', () {
    testWidgets('loads inventory and performs category filter search', (tester) async {
      final mockData = [
        {
          'id': 'item-1',
          'name': 'Gardenia Bread',
          'category': 'Bakery',
          'quantity': 1,
          'unit': 'loaf',
          'expiry_date': '2026-06-30'
        },
        {
          'id': 'item-2',
          'name': 'Fresh Milk',
          'category': 'Dairy',
          'quantity': 2,
          'unit': 'bottle',
          'expiry_date': '2026-07-15'
        }
      ];

      when(() => mockClient.from('inventory')).thenAnswer((_) => FakeSupabaseQueryBuilder(mockData));

      await tester.pumpWidget(const MaterialApp(home: InventoryScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Gardenia Bread'), findsOneWidget);
      expect(find.text('Fresh Milk'), findsOneWidget);

      // Search field test
      await tester.enterText(find.byType(TextField), 'Milk');
      await tester.pump();

      expect(find.text('Gardenia Bread'), findsNothing);
      expect(find.text('Fresh Milk'), findsOneWidget);
    });
  });

  group('ScanScreen', () {
    testWidgets('renders empty preview guidelines', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: ScanScreen()));
      expect(find.text('Capture or upload a receipt'), findsOneWidget);
      expect(find.text('Capture Receipt'), findsOneWidget);
    });
  });

  group('ReceiptReviewScreen', () {
    testWidgets('allows item deletion and insertion', (tester) async {
      final List<ExtractedItem> reviewItems = [
        ExtractedItem(name: 'Item A', quantity: 2, unit: 'pcs', category: 'Produce', expiryDate: DateTime.now())
      ];

      await tester.pumpWidget(MaterialApp(home: ReceiptReviewScreen(items: reviewItems)));
      expect(find.text('Item A'), findsOneWidget);

      // Tap delete
      await tester.tap(find.byIcon(LucideIcons.trash2));
      await tester.pumpAndSettle();

      expect(find.text('No items left'), findsOneWidget);
    });
  });

  group('MealsScreen', () {
    testWidgets('renders empty state when no recipes suggest', (tester) async {
      when(() => mockClient.from('meal_recommendations')).thenAnswer((_) => FakeSupabaseQueryBuilder(<Map<String, dynamic>>[]));

      await tester.pumpWidget(const MaterialApp(home: MealsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('No AI Recipes Yet'), findsOneWidget);
    });
  });

  group('UrgencyDashboardScreen', () {
    testWidgets('renders urgency list in order', (tester) async {
      final mockData = [
        {
          'id': 'item-u',
          'name': 'Urgent Egg',
          'category': 'Produce',
          'quantity': 10,
          'unit': 'pcs',
          'expiry_date': DateTime.now().toIso8601String()
        }
      ];

      when(() => mockClient.from('inventory')).thenAnswer((_) => FakeSupabaseQueryBuilder(mockData));

      await tester.pumpWidget(const MaterialApp(home: UrgencyDashboardScreen()));
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Urgent Egg'), findsOneWidget);
      expect(find.text('Critical Priority'), findsOneWidget);
    });
  });

  group('HomeScreen', () {
    testWidgets('renders expiring items list', (tester) async {
      when(() => mockClient.from('inventory')).thenAnswer((_) => FakeSupabaseQueryBuilder(<Map<String, dynamic>>[]));

      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Back!'), findsOneWidget);
      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('Scan Receipt'), findsOneWidget);
    });
  });

  group('ProfileScreen', () {
    testWidgets('displays user stats and notifications configuration', (tester) async {
      when(() => mockClient.from('inventory')).thenAnswer((_) => FakeSupabaseQueryBuilder(<Map<String, dynamic>>[]));

      await tester.pumpWidget(const MaterialApp(home: ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Test User'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Expiry Notifications'), findsOneWidget);
    });
  });

  group('EditProfileScreen', () {
    testWidgets('validates edit profile fields and triggers Supabase update', (tester) async {
      final mockUserResponse = MockUserResponse();
      when(() => mockUserResponse.user).thenReturn(mockUser);
      when(() => mockAuth.updateUser(any())).thenAnswer((_) async => mockUserResponse);

      await tester.pumpWidget(const MaterialApp(home: EditProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Save Changes'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'Updated User');
      await tester.pumpAndSettle();

      final btn = find.text('Save Changes');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pump();

      verify(() => mockAuth.updateUser(any())).called(1);
    });
  });

  group('ChangePasswordScreen', () {
    testWidgets('validates matching values and updates user credentials', (tester) async {
      when(() => mockAuth.signInWithPassword(
            email: 'test@example.com',
            password: 'oldPassword',
          )).thenAnswer((_) async => AuthResponse(session: mockSession, user: mockUser));

      final mockUserResponse = MockUserResponse();
      when(() => mockUserResponse.user).thenReturn(mockUser);
      when(() => mockAuth.updateUser(any())).thenAnswer((_) async => mockUserResponse);

      await tester.pumpWidget(const MaterialApp(home: ChangePasswordScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextFormField).at(0), 'oldPassword');
      await tester.enterText(find.byType(TextFormField).at(1), 'newPassword123!');
      await tester.enterText(find.byType(TextFormField).at(2), 'newPassword123!');

      final btn = find.text('Update Password');
      await tester.ensureVisible(btn);
      await tester.tap(btn);
      await tester.pump();

      verify(() => mockAuth.signInWithPassword(email: 'test@example.com', password: 'oldPassword')).called(1);
      verify(() => mockAuth.updateUser(any())).called(1);
    });
  });

  group('NotificationsScreen', () {
    testWidgets('marks notifications as read', (tester) async {
      final mockNotifs = [
        {
          'id': 'notif-1',
          'title': 'Egg is expiring',
          'message': 'Use it',
          'type': 'urgent',
          'read': false,
          'created_at': DateTime.now().toIso8601String()
        }
      ];

      when(() => mockClient.from('notifications')).thenAnswer((_) => FakeSupabaseQueryBuilder(mockNotifs));

      await tester.pumpWidget(const MaterialApp(home: NotificationsScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Egg is expiring'), findsOneWidget);
      await tester.tap(find.text('Mark all read'));
      await tester.pump();
    });
  });

  group('MainShell', () {
    testWidgets('allows tab navigation switching', (tester) async {
      when(() => mockClient.from('notifications')).thenAnswer((_) => FakeSupabaseQueryBuilder(<Map<String, dynamic>>[]));
      when(() => mockClient.from('inventory')).thenAnswer((_) => FakeSupabaseQueryBuilder(<Map<String, dynamic>>[]));

      await tester.pumpWidget(const MaterialApp(home: MainShell()));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap Inventory tab
      await tester.tap(find.text('Inventory'));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.byType(InventoryScreen), findsOneWidget);

      // Tap Alerts tab
      await tester.tap(find.text('Alerts'));
      await tester.pump(const Duration(seconds: 3));
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });
  });
}
