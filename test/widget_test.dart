import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:compound_coffee/providers.dart';
import 'package:compound_coffee/services/auth_service.dart';
import 'package:compound_coffee/login_screen.dart';

void main() {
  testWidgets('App launch and login flow smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AppProvider()),
          ChangeNotifierProvider(create: (_) => AuthService()),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    // Verify brand header
    expect(find.text('COMPOUND COFFEE'), findsOneWidget);
    expect(find.text('Şirketinize Özel Hızlı Kahve Deneyimi'), findsOneWidget);

    // Verify Google and tabs
    expect(find.text('Google ile Giriş Yap'), findsOneWidget);
    expect(find.text('Giriş Yap'), findsWidgets);
    expect(find.text('Yeni Kayıt'), findsOneWidget);

    // Tap on Yeni Kayıt tab
    await tester.tap(find.text('Yeni Kayıt'));
    await tester.pumpAndSettle();

    // Verify Registration form is displayed
    expect(find.text('Ad Soyad'), findsOneWidget);
    expect(find.text('Hesap Oluştur'), findsOneWidget);
  });
}
