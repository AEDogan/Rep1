// test/auth_flow_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:compound_coffee/providers.dart';
import 'package:compound_coffee/services/auth_service.dart';
import 'package:compound_coffee/splash_screen.dart';
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
        '/splash': (_) => const SplashScreen(),
      },
    ),
  );
}

void main() {
  group('Açılış ve Giriş Ekranı Fonksiyon Testleri', () {
    testWidgets('1. SplashScreen açılış logosu ve animasyonu başarıyla yükleniyor', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const SplashScreen()));

      // Başlık ve logo kontrolü
      expect(find.text("COMPOUND COFFEE"), findsOneWidget);
      expect(find.text("Kurumsal & Hızlı Kahve Deneyimi"), findsOneWidget);
      expect(find.byIcon(Icons.coffee_rounded), findsOneWidget);

      // Animasyon süresini ilerlet
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 1200));
      await tester.pump(const Duration(seconds: 1));
    });

    testWidgets('2. LoginScreen tüm ana bileşenleri doğru şekilde çiziyor', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      // Logo ve başlık
      expect(find.text("COMPOUND COFFEE"), findsOneWidget);
      expect(find.text("Şirketinize Özel Hızlı Kahve Deneyimi"), findsOneWidget);

      // Sağ üst köşe işletme butonu
      expect(find.text("İşletme Girişi"), findsOneWidget);

      // Sekmeler
      expect(find.text("Giriş Yap"), findsWidgets); // Sekme ve buton
      expect(find.text("Yeni Kayıt"), findsOneWidget);

      // Google Butonu
      expect(find.text("Google ile Giriş Yap"), findsOneWidget);

      // Şifremi Unuttum bağlantısı
      expect(find.text("Şifremi Unuttum?"), findsOneWidget);
    });

    testWidgets('3. "İşletme Girişi" tıklandığında Mutfak ve Admin seçenekleri açılıyor', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      // İşletme Girişi butonuna tıkla
      await tester.tap(find.text("İşletme Girişi"));
      await tester.pumpAndSettle();

      // Dialog içeriğini kontrol et
      expect(find.text("İşletme & Personel"), findsOneWidget);
      expect(find.text("Mutfak / KDS Ekranı"), findsOneWidget);
      expect(find.text("Yönetici (Admin) Paneli"), findsOneWidget);
    });

    testWidgets('4. "Yeni Kayıt" sekmesine geçildiğinde Ad Soyad ve Firma Kodu alanları açılıyor', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      // İlk başta "Ad Soyad" olmamalı
      expect(find.text("Ad Soyad"), findsNothing);

      // "Yeni Kayıt" sekmesine tıkla
      await tester.tap(find.text("Yeni Kayıt"));
      await tester.pumpAndSettle();

      // Artık Ad Soyad ve Firma Kodu görünmeli
      expect(find.text("Ad Soyad"), findsOneWidget);
      expect(find.text("Firma Kodu (İsteğe bağlı)"), findsOneWidget);
      expect(find.text("Google ile Kayıt Ol"), findsOneWidget);
      expect(find.text("Hesap Oluştur"), findsOneWidget);
    });

    testWidgets('5. "Şifremi Unuttum?" tıklandığında e-posta sıfırlama modalı açılıyor', (WidgetTester tester) async {
      await tester.pumpWidget(createTestApp(const LoginScreen()));

      // Şifremi unuttum butonuna tıkla
      await tester.tap(find.text("Şifremi Unuttum?"));
      await tester.pumpAndSettle();

      // Modal içeriğini kontrol et
      expect(find.text("Şifremi Unuttum"), findsOneWidget);
      expect(find.text("Sıfırlama Bağlantısı Gönder"), findsOneWidget);
    });
  });
}
