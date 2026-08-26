// test/order_and_kds_sync_test.dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:compound_coffee/models.dart';
import 'package:compound_coffee/providers.dart';
import 'package:compound_coffee/mock_service.dart';
import 'package:compound_coffee/services/auth_service.dart';
import 'package:compound_coffee/operator_screens.dart';

Widget createTestApp(Widget child) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => AppProvider()),
      ChangeNotifierProvider(create: (_) => AuthService()),
    ],
    child: MaterialApp(
      home: child,
    ),
  );
}

void main() {
  group('Canlı Sipariş & Mutfak KDS Senkronizasyon Testleri', () {
    test('1. OrderStatus veritabanı eşleştirmesi doğru çalışıyor', () {
      expect(OrderStatus.received.toDbString(), 'received');
      expect(OrderStatus.preparing.toDbString(), 'preparing');
      expect(OrderStatus.onTheWay.toDbString(), 'on_the_way');
      expect(OrderStatus.delivered.toDbString(), 'delivered');
      expect(OrderStatus.cancelled.toDbString(), 'cancelled');

      expect(OrderStatus.fromDbString('received'), OrderStatus.received);
      expect(OrderStatus.fromDbString('preparing'), OrderStatus.preparing);
      expect(OrderStatus.fromDbString('on_the_way'), OrderStatus.onTheWay);
      expect(OrderStatus.fromDbString('delivered'), OrderStatus.delivered);
      expect(OrderStatus.fromDbString('cancelled'), OrderStatus.cancelled);
      expect(OrderStatus.fromDbString(null), OrderStatus.received);
    });

    test('2. Order ve CartItem JSON dönüşümleri doğru çalışıyor', () {
      final json = {
        'id': 'ord_12345',
        'company_id': 'comp_maslak',
        'customer_name': 'Ahmet Yılmaz',
        'location_name': 'Masam / Açık Ofis',
        'total_price': 150.0,
        'payment_method': 'Google Pay',
        'status': 'preparing',
        'created_at': '2026-08-26T12:00:00.000Z',
        'order_items': [
          {
            'id': 'item_1',
            'product_name': 'Caffe Latte',
            'unit_price': 75.0,
            'quantity': 2,
            'selected_modifiers': [
              {'id': 'm1', 'name': 'Yulaf Sütü', 'price': 15.0}
            ],
            'item_note': 'Çok sıcak olsun',
          }
        ]
      };

      final order = Order.fromJson(json);
      expect(order.id, 'ord_12345');
      expect(order.companyId, 'comp_maslak');
      expect(order.customerName, 'Ahmet Yılmaz');
      expect(order.locationName, 'Masam / Açık Ofis');
      expect(order.totalPrice, 150.0);
      expect(order.status, OrderStatus.preparing);
      expect(order.items.length, 1);
      expect(order.items.first.product.name, 'Caffe Latte');
      expect(order.items.first.quantity, 2);
      expect(order.items.first.note, 'Çok sıcak olsun');
      expect(order.items.first.selectedModifiers.first.name, 'Yulaf Sütü');

      final outJson = order.toJson();
      expect(outJson['status'], 'preparing');
      expect(outJson['total_price'], 150.0);
    });

    test('3. AppProvider checkout işlemi sepeti temizliyor, sipariş oluşturuyor ve takibi başlatıyor', () async {
      final provider = AppProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final product = provider.products.first;
      provider.addToCart(product, [], 1);
      expect(provider.cart.length, 1);

      await provider.checkout();

      expect(provider.cart.isEmpty, true);
      expect(provider.activeOrderStatus, OrderStatus.received);
      expect(provider.orderStatusMessage.contains("Siparişinizi aldık"), true);
      expect(provider.incomingOrders.isNotEmpty, true);

      await Future.delayed(const Duration(milliseconds: 350));
      provider.dispose();
    });

    test('4. Barista KDS üzerinden sipariş durumunu değiştirdiğinde takip mesajı güncelleniyor', () async {
      final provider = AppProvider();
      await Future.delayed(const Duration(milliseconds: 50));

      final product = provider.products.first;
      provider.addToCart(product, [], 1);
      await provider.checkout();

      final activeOrder = provider.incomingOrders.first;

      // Barista: "BAŞLA" (Hazırlanıyor)
      await provider.updateOrderStatus(activeOrder.id, OrderStatus.preparing);
      expect(provider.activeOrderStatus, OrderStatus.preparing);
      expect(provider.orderStatusMessage.contains("hazırlanıyor"), true);

      // Barista: "YOLA ÇIKAR" (Kuryede / Yolda)
      await provider.updateOrderStatus(activeOrder.id, OrderStatus.onTheWay);
      expect(provider.activeOrderStatus, OrderStatus.onTheWay);
      expect(provider.orderStatusMessage.contains("yola çıktı"), true);

      // Barista: "TESLİM EDİLDİ"
      await provider.updateOrderStatus(activeOrder.id, OrderStatus.delivered);
      expect(provider.activeOrderStatus, OrderStatus.delivered);
      expect(provider.orderStatusMessage.contains("Afiyet olsun"), true);

      await Future.delayed(const Duration(milliseconds: 350));
      provider.dispose();
    });

    testWidgets('5. OrderKdsView KDS sipariş kartını ve durum butonunu çiziyor', (WidgetTester tester) async {
      final provider = AppProvider();

      final testOrder = Order(
        id: 'ord_test_kds',
        customerName: 'Ahmet Yılmaz',
        locationName: 'Masam / Ofisim',
        items: [
          CartItem(
            id: 'i1',
            product: MockDataService.getProducts().first,
            selectedModifiers: [],
            quantity: 1,
          ),
        ],
        totalPrice: 80,
        paymentMethod: 'Google Pay',
        timestamp: DateTime.now(),
        status: OrderStatus.received,
      );

      provider.incomingOrders.insert(0, testOrder);

      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<AppProvider>.value(
            value: provider,
            child: const Scaffold(body: OrderKdsView()),
          ),
        ),
      );
      await tester.pump();

      expect(find.text("#ord_test_kds"), findsOneWidget);
      expect(find.text("BAŞLA"), findsOneWidget);

      // Barista "BAŞLA" butonuna basar
      await tester.tap(find.text("BAŞLA"));
      await tester.pump();

      // Buton "YOLA ÇIKAR" haline döner
      expect(find.text("YOLA ÇIKAR"), findsOneWidget);

      // Unmount ve temizlik
      await tester.pumpWidget(const SizedBox());
      await tester.pump(const Duration(milliseconds: 350));
      provider.dispose();
    });
  });
}
