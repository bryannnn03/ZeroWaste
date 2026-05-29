import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:zerowaste/main.dart';
import 'package:zerowaste/supabase_client.dart';

class MockSupabaseClient extends Mock implements SupabaseClient {}
class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  testWidgets('App starts on login route smoke test', (WidgetTester tester) async {
    // Set up mock client for initial routing setup
    final mockClient = MockSupabaseClient();
    final mockAuth = MockGoTrueClient();
    when(() => mockClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);

    supabase = mockClient;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const ZeroWasteApp());
    await tester.pumpAndSettle();

    // Verify that our initial route is login screen and renders the title.
    expect(find.text('ZeroWaste'), findsOneWidget);
    expect(find.text('Login'), findsOneWidget);
    expect(find.text('Register'), findsOneWidget);
  });
}
