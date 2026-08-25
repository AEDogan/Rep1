// test/database_sync_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:compound_coffee/models.dart';
import 'package:compound_coffee/providers.dart';

void main() {
  group('Veritabanı Modelleri & Canlı Senkronizasyon Testleri', () {
    test('1. DeliveryLocation JSON serileştirme ve ayrıştırma doğru çalışıyor', () {
      final json = {
        'id': 'loc_1',
        'company_id': 'comp_1',
        'name': 'Masam / Açık Ofis',
        'icon': '🏢',
        'is_room': false,
        'is_active': true,
      };

      final loc = DeliveryLocation.fromJson(json);
      expect(loc.id, 'loc_1');
      expect(loc.companyId, 'comp_1');
      expect(loc.name, 'Masam / Açık Ofis');
      expect(loc.icon, '🏢');
      expect(loc.isRoom, false);
      expect(loc.isActive, true);

      final outJson = loc.toJson();
      expect(outJson['name'], 'Masam / Açık Ofis');
    });

    test('2. Product ve iç içe ModifierGroup JSON dönüşümü doğru çalışıyor', () {
      final json = {
        'id': 'prod_latte',
        'company_id': 'comp_maslak',
        'name': 'Caffe Latte',
        'description': 'İpeksi sütlü kahve',
        'base_price': 75.0,
        'category': 'drink',
        'image_url': 'https://example.com/latte.jpg',
        'is_infinite_stock': true,
        'stock_quantity': 100,
        'is_available': true,
        'modifier_groups': [
          {
            'id': 'mod_milk',
            'name': 'Süt Tercihi',
            'is_required': true,
            'is_multi_select': false,
            'product_modifiers': [
              {'id': 'opt_1', 'name': 'Yulaf Sütü', 'price': 15.0, 'is_available': true},
              {'id': 'opt_2', 'name': 'Badem Sütü', 'price': 18.0, 'is_available': true},
            ]
          }
        ]
      };

      final product = Product.fromJson(json);
      expect(product.name, 'Caffe Latte');
      expect(product.basePrice, 75.0);
      expect(product.category, 'drink');
      expect(product.modifierGroups.length, 1);
      expect(product.modifierGroups[0].name, 'Süt Tercihi');
      expect(product.modifierGroups[0].options.length, 2);
      expect(product.modifierGroups[0].options[0].name, 'Yulaf Sütü');
      expect(product.modifierGroups[0].options[0].price, 15.0);
      expect(product.isOutOfStock, false);
    });

    test('3. Stok bittiğinde veya ürün kapatıldığında isOutOfStock doğru tetikleniyor', () {
      final availableProduct = Product(
        id: 'p1',
        name: 'Filtre Kahve',
        description: 'Taze filtre kahve',
        basePrice: 55,
        imageUrl: '',
        category: 'drink',
        isInfiniteStock: false,
        stockQuantity: 5,
        isAvailable: true,
      );
      expect(availableProduct.isOutOfStock, false);

      final outOfStockProduct = Product(
        id: 'p2',
        name: 'Kruvasan',
        description: 'Taze kruvasan',
        basePrice: 70,
        imageUrl: '',
        category: 'snack',
        isInfiniteStock: false,
        stockQuantity: 0,
        isAvailable: true,
      );
      expect(outOfStockProduct.isOutOfStock, true);

      final disabledProduct = Product(
        id: 'p3',
        name: 'San Sebastian',
        description: 'Cheesecake',
        basePrice: 110,
        imageUrl: '',
        category: 'snack',
        isInfiniteStock: true,
        stockQuantity: 50,
        isAvailable: false,
      );
      expect(disabledProduct.isOutOfStock, true);
    });

    test('4. AppProvider ürün listesini, içecek/atıştırmalık kategorilerini ve stok açıp kapamayı yönetiyor', () async {
      final provider = AppProvider();
      
      // Başlangıç verisi yüklensin
      await Future.delayed(const Duration(milliseconds: 50));
      
      expect(provider.products.isNotEmpty, true);
      expect(provider.drinks.every((p) => p.category == 'drink'), true);
      expect(provider.snacks.every((p) => p.category == 'snack'), true);

      // İlk ürünün stok durumunu değiştir
      final firstProduct = provider.products.first;
      await provider.toggleProductAvailability(firstProduct.id, false);

      final updatedProduct = provider.products.firstWhere((p) => p.id == firstProduct.id);
      expect(updatedProduct.isAvailable, false);
      expect(updatedProduct.isOutOfStock, true);
    });
  });
}
