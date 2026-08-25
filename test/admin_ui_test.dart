// test/admin_ui_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:compound_coffee/admin_screens.dart';
import 'package:compound_coffee/providers.dart';

void main() {
  testWidgets('AdminLoginScreen UI Test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      ChangeNotifierProvider(
        create: (_) => AppProvider(),
        child: const MaterialApp(
          home: AdminLoginScreen(),
        ),
      ),
    );

    // Verify that the login components are present
    expect(find.text('Admin Girişi'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Kullanıcı Adı'), findsOneWidget);
    expect(find.text('Şifre'), findsOneWidget);
    expect(find.byType(ElevatedButton), findsOneWidget);
    expect(find.text('Giriş Yap'), findsOneWidget);

    // Test failed login
    await tester.enterText(find.byType(TextField).at(0), 'wrong');
    await tester.enterText(find.byType(TextField).at(1), 'wrong');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pump();

    expect(find.text('Geçersiz kullanıcı adı veya şifre'), findsOneWidget);

    // Test success login path (should navigate away)
    await tester.enterText(find.byType(TextField).at(0), 'admin');
    await tester.enterText(find.byType(TextField).at(1), 'password123');
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    // Verify navigation to Dashboard
    expect(find.text('Admin Paneli'), findsOneWidget);
    expect(find.byType(ListView), findsOneWidget);
  });
}
