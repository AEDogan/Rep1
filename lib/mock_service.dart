// mock_service.dart
import 'models.dart';

class MockDataService {
  static List<Product> getProducts() {
    return [
      // 1. Espresso
      Product(
        id: 'p_espresso',
        name: 'Espresso',
        description: 'Yoğun ve zengin aromalı klasik espresso.',
        basePrice: 80,
        category: 'drink',
        imageUrl: 'assets/images/espresso.png',
        modifierGroups: [
          ModifierGroup(
            id: 'extra',
            name: 'Ekstralar',
            isMultiSelect: true,
            options: [
              ProductModifier(id: 'ex1', name: '+1 Shot Espresso', price: 30),
            ],
          ),
        ],
      ),
      // 2. Americano
      Product(
        id: 'p_americano',
        name: 'Americano',
        description: 'Sıcak su ile yumuşatılmış espresso lezzeti.',
        basePrice: 100,
        category: 'drink',
        imageUrl: 'assets/images/americano.png',
        modifierGroups: [
          ModifierGroup(
            id: 'size',
            name: 'Boyut Seçimi',
            isRequired: true,
            options: [
              ProductModifier(id: 's', name: 'Küçük', price: 0),
              ProductModifier(id: 'm', name: 'Orta', price: 15),
              ProductModifier(id: 'l', name: 'Büyük', price: 25),
            ],
          ),
        ],
      ),
      // 3. Latte
      Product(
        id: 'p_latte',
        name: 'Latte',
        description: 'Yumuşak içimli, bol sütlü espresso.',
        basePrice: 120,
        category: 'drink',
        imageUrl: 'assets/images/latte.png',
        modifierGroups: [
          ModifierGroup(
            id: 'size',
            name: 'Boyut Seçimi',
            isRequired: true,
            options: [
              ProductModifier(id: 's', name: 'Küçük', price: 0),
              ProductModifier(id: 'm', name: 'Orta', price: 20),
              ProductModifier(id: 'l', name: 'Büyük', price: 30),
            ],
          ),
          ModifierGroup(
            id: 'milk',
            name: 'Süt Tercihi',
            options: [
              ProductModifier(id: 'm1', name: 'Normal Süt', price: 0),
              ProductModifier(id: 'm2', name: 'Laktozsuz', price: 15),
              ProductModifier(id: 'm3', name: 'Yulaf Sütü', price: 20),
            ],
          ),
        ],
      ),
      // 4. Cappuccino
      Product(
        id: 'p_cappuccino',
        name: 'Cappuccino',
        description: 'Belirgin süt köpüğü ve dengeli espresso.',
        basePrice: 115,
        category: 'drink',
        imageUrl: 'assets/images/cappuccino.png',
        modifierGroups: [
          ModifierGroup(
            id: 'size',
            name: 'Boyut Seçimi',
            isRequired: true,
            options: [
              ProductModifier(id: 's', name: 'Küçük', price: 0),
              ProductModifier(id: 'm', name: 'Orta', price: 15),
            ],
          ),
        ],
      ),
      // 5. Macchiato
      Product(
        id: 'p_macchiato',
        name: 'Macchiato',
        description: 'Bir dokunuş süt köpüğü ile espresso.',
        basePrice: 90,
        category: 'drink',
        imageUrl: 'https://images.unsplash.com/photo-1485121268090-6c9d74960309?q=80&w=1080&auto=format&fit=crop',
      ),
      // 6. Flat White
      Product(
        id: 'p_flatwhite',
        name: 'Flat White',
        description: 'İnce bir süt tabakası ile yoğun espresso.',
        basePrice: 110,
        category: 'drink',
        imageUrl: 'assets/images/latte.png',
      ),
      // 7. Cortado
      Product(
        id: 'p_cortado',
        name: 'Cortado',
        description: 'Eşit miktarda espresso ve sıcak süt.',
        basePrice: 95,
        category: 'drink',
        imageUrl: 'https://images.unsplash.com/photo-1512568400610-62da28bc8a13?q=80&w=1080&auto=format&fit=crop',
      ),
      // ... Diğer atıştırmalıklar aynı kalabilir ...
      Product(
        id: 'p2',
        name: 'Demleme Çay',
        description: 'Taze demlenmiş Rize çayı.',
        basePrice: 40,
        category: 'drink',
        imageUrl: 'https://images.unsplash.com/photo-1544787210-282aa56e49fc?q=80&w=1080&auto=format&fit=crop',
        modifierGroups: [
          ModifierGroup(
            id: 'type',
            name: 'Bardak Tipi',
            isRequired: true,
            options: [
              ProductModifier(id: 't1', name: 'İnce Belli', price: 0),
              ProductModifier(id: 't2', name: 'Fincan', price: 0),
            ],
          ),
        ],
      ),
      Product(
        id: 's1',
        name: 'Yulaflı Kurabiye',
        description: 'Ev yapımı, bol çikolatalı.',
        basePrice: 45,
        category: 'snack',
        isInfiniteStock: false,
        stockQuantity: 5,
        imageUrl: 'https://images.unsplash.com/photo-1499636136210-6f4ee915583e?q=80&w=1080&auto=format&fit=crop',
      ),
      Product(
        id: 's2',
        name: 'Islak Brownie',
        description: 'Belçika çikolatalı.',
        basePrice: 60,
        category: 'snack',
        isInfiniteStock: false,
        stockQuantity: 0,
        imageUrl: 'https://images.unsplash.com/photo-1624353365286-3f8d62daad51?q=80&w=1080&auto=format&fit=crop',
      ),
    ];
  }
}
