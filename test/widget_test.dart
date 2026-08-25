import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:compound_coffee/main.dart';

void main() {
  testWidgets('App launch and role selection smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    // Verify Welcome screen and role buttons are present
    expect(find.text('HOŞ GELDİNİZ'), findsOneWidget);
    expect(find.text('MÜŞTERİ GİRİŞİ'), findsOneWidget);
    expect(find.text('İŞLETMECİ / MUTFAK'), findsOneWidget);
    expect(find.text('YÖNETİCİ PANELİ'), findsOneWidget);

    // Tap on Müşteri Girişi
    await tester.tap(find.text('MÜŞTERİ GİRİŞİ'));
    await tester.pumpAndSettle();

    // Verify Customer login form is displayed
    expect(find.text('Müşteri Girişi'), findsOneWidget);
    expect(find.text('Numaranla Başla'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('Kod Gönder'), findsOneWidget);
  });
}

