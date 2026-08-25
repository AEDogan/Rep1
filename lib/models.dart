// models.dart

enum OrderStatus { received, preparing, onTheWay, delivered }

enum PaymentMethod { googlePay, payAtDoor }

class Order {
  final String id;
  final String customerName;
  final String locationName;
  final List<CartItem> items;
  final double totalPrice;
  final String paymentMethod;
  final DateTime timestamp;
  OrderStatus status;

  Order({
    required this.id,
    required this.customerName,
    required this.locationName,
    required this.items,
    required this.totalPrice,
    required this.paymentMethod,
    required this.timestamp,
    this.status = OrderStatus.received,
  });
}

enum UserRole { customer, kitchen, admin }

class Company {
  final String id;
  final String name;
  final String companyCode;
  final List<String> allowedDomains;
  final String? logoUrl;

  Company({
    required this.id,
    required this.name,
    required this.companyCode,
    this.allowedDomains = const [],
    this.logoUrl,
  });

  factory Company.fromJson(Map<String, dynamic> json) {
    return Company(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      companyCode: json['company_code'] as String? ?? '',
      allowedDomains: (json['allowed_domains'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      logoUrl: json['logo_url'] as String?,
    );
  }
}

class UserProfile {
  final String? id;
  final String name;
  final String email;
  final String? photoUrl;
  final String? companyId;
  final String? companyName;
  final UserRole role;
  final int loyaltyStamps;
  final int freeCoffeesAvailable;

  UserProfile({
    this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.companyId,
    this.companyName,
    this.role = UserRole.customer,
    this.loyaltyStamps = 0,
    this.freeCoffeesAvailable = 0,
  });

  UserProfile copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    String? companyId,
    String? companyName,
    UserRole? role,
    int? loyaltyStamps,
    int? freeCoffeesAvailable,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      companyId: companyId ?? this.companyId,
      companyName: companyName ?? this.companyName,
      role: role ?? this.role,
      loyaltyStamps: loyaltyStamps ?? this.loyaltyStamps,
      freeCoffeesAvailable: freeCoffeesAvailable ?? this.freeCoffeesAvailable,
    );
  }

  factory UserProfile.fromJson(Map<String, dynamic> json, {String? companyName}) {
    UserRole parsedRole = UserRole.customer;
    final roleStr = json['role'] as String?;
    if (roleStr == 'kitchen' || roleStr == 'operator') {
      parsedRole = UserRole.kitchen;
    } else if (roleStr == 'admin') {
      parsedRole = UserRole.admin;
    }

    return UserProfile(
      id: json['id'] as String?,
      name: json['full_name'] as String? ?? 'Kullanıcı',
      email: json['email'] as String? ?? '',
      photoUrl: json['avatar_url'] as String?,
      companyId: json['company_id'] as String?,
      companyName: companyName,
      role: parsedRole,
      loyaltyStamps: (json['loyalty_stamps'] as num?)?.toInt() ?? 0,
      freeCoffeesAvailable: (json['free_coffees_available'] as num?)?.toInt() ?? 0,
    );
  }
}

class DeliveryLocation {
  final String name;
  final String icon;
  final bool isRoom;

  DeliveryLocation({required this.name, required this.icon, this.isRoom = false});
}

class Product {
  final String id;
  final String name;
  final String description;
  final double basePrice;
  final String imageUrl;
  final String category; // 'drink' or 'snack'
  final bool isInfiniteStock;
  final int stockQuantity;
  final List<ModifierGroup> modifierGroups;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.imageUrl,
    required this.category,
    this.isInfiniteStock = true,
    this.stockQuantity = 0,
    this.modifierGroups = const [],
  });

  bool get isOutOfStock => !isInfiniteStock && stockQuantity <= 0;
}

class ModifierGroup {
  final String id;
  final String name;
  final bool isRequired;
  final bool isMultiSelect;
  final List<ProductModifier> options;
  // Çakışma Mantığı: Eğer bu grup belirli bir seçime bağlıysa buraya eklenir
  final String? dependentOnVariantId; 

  ModifierGroup({
    required this.id,
    required this.name,
    required this.options,
    this.isRequired = false,
    this.isMultiSelect = false,
    this.dependentOnVariantId,
  });
}

class ProductModifier {
  final String id;
  final String name;
  final double price; // 0 ise Ücretsiz

  ProductModifier({required this.id, required this.name, required this.price});

  String get priceLabel => price <= 0 ? "Ücretsiz" : "+${price.toStringAsFixed(0)} TL";
}

class CartItem {
  final String id;
  final Product product;
  final List<ProductModifier> selectedModifiers;
  final int quantity;
  final String note;
  final String addedBy;
  final String? giftNote; // "X kişisine benden"

  CartItem({
    required this.id,
    required this.product,
    required this.selectedModifiers,
    this.quantity = 1,
    this.note = '',
    this.addedBy = 'Sen',
    this.giftNote,
  });

  double get totalPrice {
    double modsPrice = selectedModifiers.fold(0, (sum, item) => sum + item.price);
    return (product.basePrice + modsPrice) * quantity;
  }
}
