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
  final String? id;
  final String? companyId;
  final String name;
  final String icon;
  final bool isRoom;
  final bool isActive;

  DeliveryLocation({
    this.id,
    this.companyId,
    required this.name,
    required this.icon,
    this.isRoom = false,
    this.isActive = true,
  });

  factory DeliveryLocation.fromJson(Map<String, dynamic> json) {
    return DeliveryLocation(
      id: json['id'] as String?,
      companyId: json['company_id'] as String?,
      name: json['name'] as String? ?? 'Nokta',
      icon: json['icon'] as String? ?? '🏢',
      isRoom: json['is_room'] as bool? ?? false,
      isActive: json['is_active'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (companyId != null) 'company_id': companyId,
      'name': name,
      'icon': icon,
      'is_room': isRoom,
      'is_active': isActive,
    };
  }
}

class ProductModifier {
  final String id;
  final String name;
  final double price; // 0 ise Ücretsiz
  final bool isAvailable;

  ProductModifier({
    required this.id,
    required this.name,
    required this.price,
    this.isAvailable = true,
  });

  String get priceLabel => price <= 0 ? "Ücretsiz" : "+${price.toStringAsFixed(0)} TL";

  factory ProductModifier.fromJson(Map<String, dynamic> json) {
    return ProductModifier(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      isAvailable: json['is_available'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'is_available': isAvailable,
    };
  }
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

  factory ModifierGroup.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['product_modifiers'] as List<dynamic>? ??
        json['options'] as List<dynamic>? ??
        [];
    return ModifierGroup(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      isRequired: json['is_required'] as bool? ?? false,
      isMultiSelect: json['is_multi_select'] as bool? ?? false,
      dependentOnVariantId: json['dependent_on_variant_id'] as String?,
      options: rawOptions
          .map((o) => ProductModifier.fromJson(o as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'is_required': isRequired,
      'is_multi_select': isMultiSelect,
      'dependent_on_variant_id': dependentOnVariantId,
      'options': options.map((o) => o.toJson()).toList(),
    };
  }
}

class Product {
  final String id;
  final String? companyId;
  final String name;
  final String description;
  final double basePrice;
  final String imageUrl;
  final String category; // 'drink' or 'snack'
  final bool isInfiniteStock;
  final int stockQuantity;
  final bool isAvailable;
  final List<ModifierGroup> modifierGroups;

  Product({
    required this.id,
    this.companyId,
    required this.name,
    required this.description,
    required this.basePrice,
    required this.imageUrl,
    required this.category,
    this.isInfiniteStock = true,
    this.stockQuantity = 0,
    this.isAvailable = true,
    this.modifierGroups = const [],
  });

  bool get isOutOfStock => !isAvailable || (!isInfiniteStock && stockQuantity <= 0);

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['modifier_groups'] as List<dynamic>? ?? [];
    return Product(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      basePrice: (json['base_price'] as num?)?.toDouble() ?? 0.0,
      imageUrl: json['image_url'] as String? ?? '',
      category: json['category'] as String? ?? 'drink',
      isInfiniteStock: json['is_infinite_stock'] as bool? ?? true,
      stockQuantity: (json['stock_quantity'] as num?)?.toInt() ?? 0,
      isAvailable: json['is_available'] as bool? ?? true,
      modifierGroups: rawGroups
          .map((g) => ModifierGroup.fromJson(g as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (companyId != null) 'company_id': companyId,
      'name': name,
      'description': description,
      'base_price': basePrice,
      'image_url': imageUrl,
      'category': category,
      'is_infinite_stock': isInfiniteStock,
      'stock_quantity': stockQuantity,
      'is_available': isAvailable,
    };
  }
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
