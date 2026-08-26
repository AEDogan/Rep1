// models.dart

enum OrderStatus {
  received,
  preparing,
  onTheWay,
  delivered,
  cancelled;

  String toDbString() {
    switch (this) {
      case OrderStatus.received:
        return 'received';
      case OrderStatus.preparing:
        return 'preparing';
      case OrderStatus.onTheWay:
        return 'on_the_way';
      case OrderStatus.delivered:
        return 'delivered';
      case OrderStatus.cancelled:
        return 'cancelled';
    }
  }

  static OrderStatus fromDbString(String? str) {
    switch (str?.toLowerCase()) {
      case 'preparing':
        return OrderStatus.preparing;
      case 'on_the_way':
      case 'ontheway':
        return OrderStatus.onTheWay;
      case 'delivered':
        return OrderStatus.delivered;
      case 'cancelled':
        return OrderStatus.cancelled;
      case 'received':
      default:
        return OrderStatus.received;
    }
  }

  String get label {
    switch (this) {
      case OrderStatus.received:
        return 'Sipariş Alındı';
      case OrderStatus.preparing:
        return 'Hazırlanıyor';
      case OrderStatus.onTheWay:
        return 'Kuryede / Yolda';
      case OrderStatus.delivered:
        return 'Teslim Edildi';
      case OrderStatus.cancelled:
        return 'İptal Edildi';
    }
  }
}

enum PaymentMethod { googlePay, payAtDoor }

class Order {
  final String id;
  final String? companyId;
  final String? userId;
  final String customerName;
  final String? deliveryLocationId;
  final String locationName;
  final List<CartItem> items;
  final double totalPrice;
  final String paymentMethod;
  final DateTime timestamp;
  OrderStatus status;

  Order({
    required this.id,
    this.companyId,
    this.userId,
    required this.customerName,
    this.deliveryLocationId,
    required this.locationName,
    required this.items,
    required double totalPrice,
    required this.paymentMethod,
    required this.timestamp,
    this.status = OrderStatus.received,
  }) : totalPrice = totalPrice < 0 ? 0.0 : totalPrice;

  factory Order.fromJson(Map<String, dynamic> json) {
    final rawItems = json['order_items'] as List<dynamic>? ??
        json['items'] as List<dynamic>? ??
        [];

    final rawTotal = (json['total_price'] as num?)?.toDouble() ?? 0.0;

    return Order(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String?,
      userId: json['user_id'] as String?,
      customerName: json['customer_name'] as String? ?? 'Misafir',
      deliveryLocationId: json['delivery_location_id'] as String?,
      locationName: json['location_name'] as String? ?? 'Bilinmiyor',
      totalPrice: rawTotal < 0 ? 0.0 : rawTotal,
      paymentMethod: json['payment_method'] as String? ?? 'Google Pay',
      timestamp: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String) ?? DateTime.now()
          : DateTime.now(),
      status: OrderStatus.fromDbString(json['status'] as String?),
      items: rawItems
          .map((item) => CartItem.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      if (companyId != null) 'company_id': companyId,
      if (userId != null) 'user_id': userId,
      'customer_name': customerName,
      if (deliveryLocationId != null) 'delivery_location_id': deliveryLocationId,
      'location_name': locationName,
      'total_price': totalPrice,
      'payment_method': paymentMethod,
      'status': status.toDbString(),
      'created_at': timestamp.toIso8601String(),
      'items': items.map((i) => i.toJson()).toList(),
    };
  }
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
    required double price,
    this.isAvailable = true,
  }) : price = price < 0 ? 0.0 : price;

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
  final String? dependentOnVariantId;
  final List<ProductModifier> options;

  ModifierGroup({
    required this.id,
    required this.name,
    this.isRequired = false,
    this.isMultiSelect = false,
    this.dependentOnVariantId,
    required this.options,
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
  final String category;
  final bool isInfiniteStock;
  final int stockQuantity;
  final bool isAvailable;
  final List<ModifierGroup> modifierGroups;

  Product({
    required this.id,
    this.companyId,
    required this.name,
    required this.description,
    required double basePrice,
    required this.imageUrl,
    required this.category,
    this.isInfiniteStock = true,
    this.stockQuantity = 0,
    this.isAvailable = true,
    this.modifierGroups = const [],
  }) : basePrice = basePrice < 0 ? 0.0 : basePrice;

  bool get isOutOfStock => !isAvailable || (!isInfiniteStock && stockQuantity <= 0);

  factory Product.fromJson(Map<String, dynamic> json) {
    final rawGroups = json['modifier_groups'] as List<dynamic>? ?? [];
    final rawPrice = (json['base_price'] as num?)?.toDouble() ?? 0.0;
    return Product(
      id: json['id'] as String? ?? '',
      companyId: json['company_id'] as String?,
      name: json['name'] as String? ?? '',
      description: json['description'] as String? ?? '',
      basePrice: rawPrice < 0 ? 0.0 : rawPrice,
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
  final String? giftNote;

  CartItem({
    required this.id,
    required this.product,
    required this.selectedModifiers,
    int quantity = 1,
    this.note = '',
    this.addedBy = 'Sen',
    this.giftNote,
  }) : quantity = quantity < 1 ? 1 : (quantity > 100 ? 100 : quantity);

  double get totalPrice {
    double modsPrice = selectedModifiers.fold(0.0, (sum, item) => sum + (item.price > 0 ? item.price : 0.0));
    double unitPrice = product.basePrice > 0 ? product.basePrice : 0.0;
    return (unitPrice + modsPrice) * quantity;
  }

  factory CartItem.fromJson(Map<String, dynamic> json) {
    Product parsedProduct;
    if (json['product'] != null && json['product'] is Map<String, dynamic>) {
      parsedProduct = Product.fromJson(json['product'] as Map<String, dynamic>);
    } else {
      final rawUnit = (json['unit_price'] as num?)?.toDouble() ?? 0.0;
      parsedProduct = Product(
        id: json['product_id'] as String? ?? 'p_custom',
        name: json['product_name'] as String? ?? 'Kahve',
        description: '',
        basePrice: rawUnit < 0 ? 0.0 : rawUnit,
        imageUrl: '',
        category: 'drink',
      );
    }

    final rawMods = json['selected_modifiers'] as List<dynamic>? ?? [];
    final modifiers = rawMods
        .map((m) => ProductModifier.fromJson(m as Map<String, dynamic>))
        .toList();

    final rawQuantity = (json['quantity'] as num?)?.toInt() ?? 1;

    return CartItem(
      id: json['id'] as String? ?? '',
      product: parsedProduct,
      selectedModifiers: modifiers,
      quantity: rawQuantity < 1 ? 1 : (rawQuantity > 100 ? 100 : rawQuantity),
      note: json['item_note'] as String? ?? json['note'] as String? ?? '',
      addedBy: json['added_by'] as String? ?? 'Sen',
      giftNote: json['gift_note'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'product_id': product.id,
      'product_name': product.name,
      'quantity': quantity,
      'unit_price': product.basePrice,
      'total_price': totalPrice,
      'selected_modifiers': selectedModifiers.map((m) => m.toJson()).toList(),
      'item_note': note,
      'gift_note': giftNote,
      'added_by': addedBy,
      'product': product.toJson(),
    };
  }
}
