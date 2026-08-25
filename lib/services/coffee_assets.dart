// services/coffee_assets.dart

class CoffeePreset {
  final String id;
  final String name;
  final String description;
  final String category; // 'drink' or 'snack'
  final double defaultPrice;
  final String imageUrl;

  const CoffeePreset({
    required this.id,
    required this.name,
    required this.description,
    required this.category,
    required this.defaultPrice,
    required this.imageUrl,
  });
}

class CoffeeAssets {
  /// 15 Çeşit Markasız, Şeffaf Cam Bardakta Katmanları Görünen Yüksek Kaliteli Jenerik Görsel Kataloğu
  static const List<CoffeePreset> presets = [
    // 1. Espresso
    CoffeePreset(
      id: 'preset_espresso',
      name: 'Espresso',
      description: 'Şeffaf cam fincanda tek shot yoğun gövdeli ve altın sarısı kremalı klasik espresso.',
      category: 'drink',
      defaultPrice: 60.0,
      imageUrl: 'https://images.unsplash.com/photo-1510591509098-f4fdc6d0ff04?w=600&auto=format&fit=crop&q=80',
    ),
    // 2. Double Espresso
    CoffeePreset(
      id: 'preset_doppio',
      name: 'Double Espresso (Doppio)',
      description: 'Çift shot konsantre espresso, zengin crema dokusuyla şeffaf shot bardağında.',
      category: 'drink',
      defaultPrice: 75.0,
      imageUrl: 'https://images.unsplash.com/photo-1579992357154-faf4bde95b3d?w=600&auto=format&fit=crop&q=80',
    ),
    // 3. Americano
    CoffeePreset(
      id: 'preset_americano',
      name: 'Americano',
      description: 'Sıcak su ile inceltilmiş çift shot espresso, berrak amber tonunda cam kupa.',
      category: 'drink',
      defaultPrice: 65.0,
      imageUrl: 'https://images.unsplash.com/photo-1551030173-122aabc4489c?w=600&auto=format&fit=crop&q=80',
    ),
    // 4. Caffe Latte
    CoffeePreset(
      id: 'preset_latte',
      name: 'Caffe Latte',
      description: 'Espresso, buharda ısıtılmış süt ve kadifemsi mikro köpük katmanlı şeffaf cam bardak.',
      category: 'drink',
      defaultPrice: 75.0,
      imageUrl: 'https://images.unsplash.com/photo-1534778101976-62847782c213?w=600&auto=format&fit=crop&q=80',
    ),
    // 5. Cappuccino
    CoffeePreset(
      id: 'preset_cappuccino',
      name: 'Cappuccino',
      description: 'Eşit oranda espresso, sıcak süt ve yoğun kalın süt köpüğü katmanlı cam bardak.',
      category: 'drink',
      defaultPrice: 75.0,
      imageUrl: 'https://images.unsplash.com/photo-1572442388796-11668a67e53d?w=600&auto=format&fit=crop&q=80',
    ),
    // 6. Flat White
    CoffeePreset(
      id: 'preset_flat_white',
      name: 'Flat White',
      description: 'Çift shot ristretto espresso ve ince pürüzsüz mikro köpüklü süt uyumu.',
      category: 'drink',
      defaultPrice: 80.0,
      imageUrl: 'https://images.unsplash.com/photo-1577968897966-3d4325b36b61?w=600&auto=format&fit=crop&q=80',
    ),
    // 7. Cortado
    CoffeePreset(
      id: 'preset_cortado',
      name: 'Cortado',
      description: 'Espresso ve sıcak sütün 1:1 mükemmel dengesi, küçük şeffaf cortado bardağında.',
      category: 'drink',
      defaultPrice: 70.0,
      imageUrl: 'https://images.unsplash.com/photo-1514432324607-a09d9b4aefdd?w=600&auto=format&fit=crop&q=80',
    ),
    // 8. Caramel Macchiato
    CoffeePreset(
      id: 'preset_caramel_macchiato',
      name: 'Caramel Macchiato',
      description: 'Vanilya şurubu, süt, espresso ve üzerinde karamel sos katmanlı şeffaf cam servis.',
      category: 'drink',
      defaultPrice: 85.0,
      imageUrl: 'https://images.unsplash.com/photo-1485808191679-5f86510681a2?w=600&auto=format&fit=crop&q=80',
    ),
    // 9. Caffe Mocha
    CoffeePreset(
      id: 'preset_mocha',
      name: 'Caffe Mocha',
      description: 'Hakiki bitter çikolata sosu, espresso ve süt katmanı, krema süslemesiyle cam kupada.',
      category: 'drink',
      defaultPrice: 85.0,
      imageUrl: 'https://images.unsplash.com/photo-1578314675249-a6910f80cc4e?w=600&auto=format&fit=crop&q=80',
    ),
    // 10. Filtre Kahve
    CoffeePreset(
      id: 'preset_filter_coffee',
      name: 'Filtre Kahve',
      description: 'Günün taze çekirdeklerinden berrak damıtma filtre kahve cam chemex sunumu.',
      category: 'drink',
      defaultPrice: 55.0,
      imageUrl: 'https://images.unsplash.com/photo-1495474472287-4d71bcdd2085?w=600&auto=format&fit=crop&q=80',
    ),
    // 11. Cold Brew
    CoffeePreset(
      id: 'preset_cold_brew',
      name: 'Cold Brew',
      description: '18 saat soğuk damıtılmış, kristal buz küpleriyle ferahlatıcı berrak cam bardak.',
      category: 'drink',
      defaultPrice: 80.0,
      imageUrl: 'https://images.unsplash.com/photo-1517701550927-30cf4ba1dba5?w=600&auto=format&fit=crop&q=80',
    ),
    // 12. Iced Latte
    CoffeePreset(
      id: 'preset_iced_latte',
      name: 'Iced Caffe Latte',
      description: 'Buz üzerinde süt ve dökülen espressonun büyüleyici katman dansı.',
      category: 'drink',
      defaultPrice: 80.0,
      imageUrl: 'https://images.unsplash.com/photo-1461023058943-07fcbe16d735?w=600&auto=format&fit=crop&q=80',
    ),
    // 13. Iced Mocha / Frappe
    CoffeePreset(
      id: 'preset_iced_mocha',
      name: 'Iced Mocha',
      description: 'Çikolatalı buzlu soğuk kahve, çikolata damlaları ve süt katmanıyla.',
      category: 'drink',
      defaultPrice: 85.0,
      imageUrl: 'https://images.unsplash.com/photo-1553909489-cd47e0907980?w=600&auto=format&fit=crop&q=80',
    ),
    // 14. Sıcak Çikolata
    CoffeePreset(
      id: 'preset_hot_chocolate',
      name: 'Sıcak Çikolata',
      description: 'Koyu kıvamlı Belçika çikolatası ve buharlanmış sütle hazırlanan cam kupa lezzeti.',
      category: 'drink',
      defaultPrice: 75.0,
      imageUrl: 'https://images.unsplash.com/photo-1542990253-0d0f5be5f0ed?w=600&auto=format&fit=crop&q=80',
    ),
    // 15. Tereyağlı Kruvasan
    CoffeePreset(
      id: 'preset_croissant',
      name: 'Tereyağlı Kruvasan',
      description: 'Kat kat çıtır Fransız tereyağlı kruvasan, kahvenin en tatlı eşlikçisi.',
      category: 'snack',
      defaultPrice: 70.0,
      imageUrl: 'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600&auto=format&fit=crop&q=80',
    ),
    // 16. San Sebastian Cheesecake
    CoffeePreset(
      id: 'preset_cheesecake',
      name: 'San Sebastian Cheesecake',
      description: 'Akışkan iç dokusu ve karamelize yanık üst katmanıyla meşhur cheesecake dilimi.',
      category: 'snack',
      defaultPrice: 110.0,
      imageUrl: 'https://images.unsplash.com/photo-1533134242443-d4fd215305ad?w=600&auto=format&fit=crop&q=80',
    ),
  ];
}
