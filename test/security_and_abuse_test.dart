// test/security_and_abuse_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:compound_coffee/models.dart';
import 'package:compound_coffee/providers.dart';
import 'package:compound_coffee/mock_service.dart';

void main() {
  group('🛡️ Güvenlik & Kötüye Kullanım (Anti-Abuse) Test Paketi', () {
    test('1. Fiyat & Miktar Manipülasyon Koruması (Negative & Overflow Guard)', () {
      final dummyProduct = Product(
        id: 'p_secure',
        name: 'Güvenli Espresso',
        description: 'Test',
        basePrice: -50.0, // Negatif fiyat saldırısı
        imageUrl: '',
        category: 'drink',
      );

      // Negatif ürün fiyatı otomatik 0.0'a çekilmeli
      expect(dummyProduct.basePrice, 0.0);

      final dummyMod = ProductModifier(
        id: 'm_hack',
        name: 'Negatif Süt',
        price: -30.0, // Negatif modifikasyon fiyatı
      );
      expect(dummyMod.price, 0.0);

      // Negatif adet ve aşırı yüksek adet saldırıları
      final itemNegative = CartItem(
        id: 'c1',
        product: dummyProduct,
        selectedModifiers: [dummyMod],
        quantity: -10,
      );
      expect(itemNegative.quantity, 1); // Minimum 1 olmalı
      expect(itemNegative.totalPrice, 0.0); // Negatif tutar oluşamaz

      final itemZero = CartItem(
        id: 'c2',
        product: dummyProduct,
        selectedModifiers: [],
        quantity: 0,
      );
      expect(itemZero.quantity, 1);

      final itemOverflow = CartItem(
        id: 'c3',
        product: dummyProduct,
        selectedModifiers: [],
        quantity: 999999,
      );
      expect(itemOverflow.quantity, 100); // Maksimum 100 ile sınırlandırılmalı
    });

    test('2. Race Condition / Spam Click Çift Sipariş Koruması (Double-Spend Lock)', () async {
      final provider = AppProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final product = MockDataService.getProducts().first;
      provider.addToCart(product, [], 1);
      expect(provider.cart.length, 1);

      final initialStamps = provider.loyaltyStamps;

      // Kullanıcı "ÖDE" butonuna aynı anda 10 defa art arda basarsa
      final List<Future<void>> spamCheckouts = List.generate(10, (_) => provider.checkout());
      await Future.wait(spamCheckouts);

      // Yalnızca 1 sipariş üretilmeli ve sadakat damgası sadece 1 artmalı
      expect(provider.cart.isEmpty, true);
      expect(provider.loyaltyStamps, initialStamps + 1);

      await Future.delayed(const Duration(milliseconds: 350));
      provider.dispose();
    });

    test('3. Stok Bypass ve Kapalı Ürün Sipariş Etme Engeli', () async {
      final provider = AppProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      // Tükenmiş veya satışı kapatılmış ürün
      final outOfStockProduct = Product(
        id: 'p_out',
        name: 'Tükenmiş Kahve',
        description: '',
        basePrice: 80.0,
        imageUrl: '',
        category: 'drink',
        isAvailable: false,
      );

      // Sepete eklemeyi denerse reddedilmeli
      provider.addToCart(outOfStockProduct, [], 1);
      expect(provider.cart.isEmpty, true);

      // Eğer sepetteki ürün checkout anında tükendiyse checkout reddedilmeli
      final validProduct = MockDataService.getProducts().first;
      provider.addToCart(validProduct, [], 1);
      expect(provider.cart.length, 1);

      // Ürünü sepetteyken tükendi yapalım
      provider.toggleProductAvailability(validProduct.id, false);

      await provider.checkout();

      // Tükenen ürün elendiği için sipariş geçilmemeli
      expect(provider.cart.isEmpty, true);

      await Future.delayed(const Duration(milliseconds: 350));
      provider.dispose();
    });

    test('4. SQL Injection & XSS Payload Dayanıklılık ve Sanitizasyon Testi', () {
      const sqlPayload = "'; DROP TABLE orders; --";
      const xssPayload = "<script>alert('pwned')</script>";
      const nullBytePayload = "Ahmet\x00Yılmaz";

      final sanitizedNull = AppProvider.sanitizeInput(nullBytePayload);
      expect(sanitizedNull.contains('\x00'), false);
      expect(sanitizedNull, 'AhmetYılmaz');

      final orderJson = {
        'id': 'ord_hack_1',
        'customer_name': sqlPayload,
        'location_name': xssPayload,
        'total_price': 100.0,
        'payment_method': 'Google Pay',
        'status': 'received',
        'order_items': [
          {
            'id': 'i1',
            'product_name': xssPayload,
            'unit_price': 100.0,
            'quantity': 1,
            'item_note': sqlPayload,
            'gift_note': xssPayload,
          }
        ]
      };

      // Model parse ederken çökmemeli ve güvenle serileştirmeli
      final order = Order.fromJson(orderJson);
      expect(order.customerName, sqlPayload);
      expect(order.locationName, xssPayload);
      expect(order.items.first.note, sqlPayload);

      final outJson = order.toJson();
      expect(outJson['customer_name'], sqlPayload);
    });

    test('5. Bozuk ve Aşırı Uzun Payload Dayanıklılığı (Crash / DoS Resistance)', () {
      // Tamamen boş ve eksik JSON
      final emptyOrder = Order.fromJson({});
      expect(emptyOrder.id, '');
      expect(emptyOrder.customerName, 'Misafir');
      expect(emptyOrder.totalPrice, 0.0);
      expect(emptyOrder.items.isEmpty, true);

      // Negatif tutarlı ve hatalı tipli JSON
      final corruptOrder = Order.fromJson({
        'total_price': -999.0,
        'status': 'UNKNOWN_STATUS_ATTACK',
        'created_at': 'NOT_A_DATE',
        'order_items': null,
      });
      expect(corruptOrder.status, OrderStatus.received);
      expect(corruptOrder.items.isEmpty, true);

      // 50.000 karakterlik devasa metin (Tampon taşma simülasyonu)
      final massiveText = 'A' * 50000;
      final sanitizedMassive = AppProvider.sanitizeInput(massiveText, maxLength: 200);
      expect(sanitizedMassive.length, 200);
    });
  });
}
