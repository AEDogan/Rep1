// test/coffee_presets_and_onboarding_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:compound_coffee/models.dart';
import 'package:compound_coffee/providers.dart';
import 'package:compound_coffee/services/auth_service.dart';
import 'package:compound_coffee/services/coffee_assets.dart';
import 'package:compound_coffee/admin_screens.dart';
import 'package:compound_coffee/login_screen.dart';

Widget createTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppProvider()),
      ChangeNotifierProvider(create: (_) => AuthService()),
    ],
    child: MaterialApp(
      home: child,
      routes: {
        '/login': (_) => const LoginScreen(),
      },
    ),
  );
}

void main() {
  group('Jenerik Görsel Kataloğu & İşletme Kayıt Testleri', () {
    test('1. CoffeeAssets kataloğu 15+ şeffaf bardak jenerik görseli ve geçerli bilgileri içeriyor', () {
      expect(CoffeeAssets.presets.length, greaterThanOrEqualTo(15));

      for (var preset in CoffeeAssets.presets) {
        expect(preset.id.isNotEmpty, true);
        expect(preset.name.isNotEmpty, true);
        expect(preset.description.isNotEmpty, true);
        expect(preset.imageUrl.startsWith('http'), true);
        expect(preset.defaultPrice, greaterThan(0));
        expect(['drink', 'snack'].contains(preset.category), true);
      }

      // Popüler kahve tipleri mevcut mu?
      final names = CoffeeAssets.presets.map((p) => p.name).toList();
      expect(names.contains('Espresso'), true);
      expect(names.contains('Americano'), true);
      expect(names.contains('Caffe Latte'), true);
      expect(names.contains('Cappuccino'), true);
      expect(names.contains('Cold Brew'), true);
      expect(names.contains('Flat White'), true);
    });

    test('2. AuthService yeni işletme ve yönetici hesabını başarıyla oluşturuyor', () async {
      final auth = AuthService();
      final success = await auth.registerNewCompanyWithAdmin(
        companyName: 'Kolektif House Test',
        companyCode: 'TST-99',
        adminEmail: 'yonetici@kolektif.com',
        adminPassword: 'password123',
        adminName: 'Test Yönetici',
        allowedDomains: ['@kolektif.com'],
      );

      expect(success, true);
      expect(auth.currentUser?.role, UserRole.admin);
      expect(auth.currentCompany?.companyCode, 'TST-99');
      expect(auth.currentCompany?.name, 'Kolektif House Test');
    });

    testWidgets('3. LoginScreen İşletme Diyaloğunda "Yeni İşletme / Şube Kaydı" seçeneği görünüyor', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      // Sağ üstteki "İşletme Girişi" butonuna bas
      await tester.tap(find.text("İşletme Girişi"));
      await tester.pumpAndSettle();

      // Modalda 3 seçenek de var mı?
      expect(find.text("Mutfak / KDS Ekranı"), findsOneWidget);
      expect(find.text("Yönetici (Admin) Paneli"), findsOneWidget);
      expect(find.text("Yeni İşletme / Şube Kaydı"), findsOneWidget);
    });

    testWidgets('4. ProductEditorScreen formunda "Jenerik Görsellerden Seç" butonu bulunuyor', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const ProductEditorScreen()));

      expect(find.text("Jenerik Görsellerden Seç (15 Çeşit)"), findsOneWidget);
    });
  });
}
