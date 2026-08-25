// test/admin_logic_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:compound_coffee/providers.dart';
import 'package:compound_coffee/models.dart';

void main() {
  group('AppProvider Admin Logic Tests', () {
    late AppProvider provider;

    setUp(() {
      provider = AppProvider();
    });

    test('Initial products should not be empty (from MockDataService)', () {
      expect(provider.drinks.isNotEmpty || provider.snacks.isNotEmpty, true);
    });

    test('addProduct should increase the total product count', () {
      final initialCount = provider.drinks.length + provider.snacks.length;
      final newProduct = Product(
        id: 'test_id',
        name: 'Test Coffee',
        description: 'Testing description',
        basePrice: 50.0,
        category: 'drink',
        imageUrl: '',
      );

      provider.addProduct(newProduct);

      final newCount = provider.drinks.length + provider.snacks.length;
      expect(newCount, initialCount + 1);
      expect(provider.drinks.any((p) => p.id == 'test_id'), true);
    });

    test('updateProduct should modify existing product', () {
      final newProduct = Product(
        id: 'test_update',
        name: 'Original',
        description: 'Desc',
        basePrice: 10.0,
        category: 'drink',
        imageUrl: '',
      );
      provider.addProduct(newProduct);

      final updatedProduct = Product(
        id: 'test_update',
        name: 'Updated Name',
        description: 'New Desc',
        basePrice: 20.0,
        category: 'drink',
        imageUrl: 'new_url',
      );

      provider.updateProduct(updatedProduct);

      final p = provider.drinks.firstWhere((p) => p.id == 'test_update');
      expect(p.name, 'Updated Name');
      expect(p.basePrice, 20.0);
    });

    test('deleteProduct should remove the product', () {
      final newProduct = Product(
        id: 'test_delete',
        name: 'To Delete',
        description: 'Desc',
        basePrice: 10.0,
        category: 'drink',
        imageUrl: '',
      );
      provider.addProduct(newProduct);
      expect(provider.drinks.any((p) => p.id == 'test_delete'), true);

      provider.deleteProduct('test_delete');
      expect(provider.drinks.any((p) => p.id == 'test_delete'), false);
    });
  });
}
