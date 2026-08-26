// providers.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';
import 'mock_service.dart';
import 'socket_service.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';

enum GroupRole { leader, friend }
enum MemberStatus { choosing, ready }

class GroupMember {
  final String id;
  final String name;
  MemberStatus status;
  final List<CartItem> items;

  GroupMember({
    required this.id,
    required this.name,
    this.status = MemberStatus.choosing,
    this.items = const [],
  });
}

class AppProvider with ChangeNotifier {
  List<Product> _products = [];
  bool _isLoading = true;
  final List<CartItem> _cart = [];
  
  // User Profile
  UserProfile? _currentUser;
  UserProfile? get currentUser => _currentUser;

  // Payment
  PaymentMethod _selectedPaymentMethod = PaymentMethod.googlePay;
  PaymentMethod get selectedPaymentMethod => _selectedPaymentMethod;
  
  // Sosyal ve Teslimat Durumları
  late DeliveryLocation _selectedLocation;
  List<DeliveryLocation> _locations = [
    DeliveryLocation(name: "Masam / Ofisim", icon: "🏢"),
    DeliveryLocation(name: "Proje Laboratuvarı", icon: "🧪"),
    DeliveryLocation(name: "A1 Toplantı Odası", icon: "🤝", isRoom: true),
    DeliveryLocation(name: "B3 Yönetim Odası", icon: "🤝", isRoom: true),
  ];
  
  int _loyaltyStamps = 6;
  int _freeProducts = 0;
  
  String? _activeOrderId;
  OrderStatus? _activeOrderStatus;
  String _orderStatusMessage = '';
  Timer? _trackingTimer;
  
  Product? _lastOrderedProduct;
  
  // Grup Siparişi Durumları
  bool _isGroupOrderActive = false;
  bool _isPaying = false; 
  GroupRole _userRole = GroupRole.leader;
  String _groupId = '';
  int _groupTimeRemaining = 300; 
  Timer? _groupTimer;
  
  final List<GroupMember> _groupMembers = [];

  // Services
  final SocketService _socketService = SocketService();
  final DatabaseService _databaseService = DatabaseService();
  List<Order> _incomingOrders = []; // KDS için aktif siparişler listesi
  StreamSubscription? _orderSub;
  StreamSubscription? _productSub;
  bool _isDisposed = false;

  AppProvider() {
    _selectedLocation = _locations[0];
    _loadInitialData();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    // Mutfak Paneli: Yeni sipariş dinle (Local socket)
    _orderSub = _socketService.onNewOrder.listen((data) {
      if (_isDisposed) return;
      final items = (data['items'] as List).cast<CartItem>();
      
      final newOrder = Order(
        id: data['orderId'],
        customerName: data['customerName'] ?? 'Misafir',
        locationName: data['locationName'] ?? 'Bilinmiyor',
        items: items,
        totalPrice: (data['totalPrice'] as num?)?.toDouble() ?? 0.0,
        paymentMethod: data['paymentMethod'] ?? 'Nakit',
        timestamp: DateTime.now(),
        status: OrderStatus.received,
      );

      final exists = _incomingOrders.any((o) => o.id == newOrder.id);
      if (!exists) {
        _incomingOrders.insert(0, newOrder);
        notifyListeners();
      }
    });

    // Müşteri Paneli: Ürün stok durumu dinle
    _productSub = _socketService.onProductUpdate.listen((data) {
      if (_isDisposed) return;
      final productId = data['id'];
      final isAvailable = data['isAvailable'] as bool? ?? true;
      
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        final p = _products[index];
        _products[index] = Product(
          id: p.id,
          companyId: p.companyId,
          name: p.name,
          description: p.description,
          basePrice: p.basePrice,
          imageUrl: p.imageUrl,
          category: p.category,
          modifierGroups: p.modifierGroups,
          isInfiniteStock: p.isInfiniteStock,
          stockQuantity: isAvailable ? (p.stockQuantity > 0 ? p.stockQuantity : 100) : 0,
          isAvailable: isAvailable,
        );
        notifyListeners();
      }
    });
  }

  List<Order> get incomingOrders => _incomingOrders;

  Future<void> _loadInitialData() async {
    _isLoading = true;
    notifyListeners();

    final companyId = AuthService().currentUser?.companyId ??
        AuthService().currentCompany?.id ??
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11'; // Varsayılan örnek firma Maslak Hub

    await loadCompanyData(companyId);
  }

  /// Şirketin ürünlerini, teslimat noktalarını ve aktif siparişlerini Supabase'den çeker
  Future<void> loadCompanyData(String companyId) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Canlı veritabanından ürünleri çek
      final fetchedProducts = await _databaseService.fetchProducts(companyId);
      if (fetchedProducts.isNotEmpty) {
        _products = fetchedProducts;
      } else {
        _products = MockDataService.getProducts();
      }

      // 2. Teslimat noktalarını çek
      final fetchedLocations = await _databaseService.fetchDeliveryLocations(companyId);
      if (fetchedLocations.isNotEmpty) {
        _locations = fetchedLocations;
        _selectedLocation = _locations.first;
      }

      // 3. Mutfak için aktif siparişleri çek
      final activeOrders = await _databaseService.fetchActiveOrders(companyId);
      if (activeOrders.isNotEmpty) {
        _incomingOrders = activeOrders;
      }

      // 4. Realtime Ürün/Stok dinleyici başlat
      _databaseService.subscribeToProducts(
        companyId: companyId,
        onUpdate: () async {
          final updated = await _databaseService.fetchProducts(companyId);
          if (updated.isNotEmpty) {
            _products = updated;
            notifyListeners();
          }
        },
      );

      // 5. Realtime Sipariş & KDS dinleyici başlat
      _databaseService.subscribeToOrders(
        companyId: companyId,
        onNewOrder: (newOrder) {
          final exists = _incomingOrders.any((o) => o.id == newOrder.id);
          if (!exists) {
            _incomingOrders.insert(0, newOrder);
            notifyListeners();
          }
        },
        onStatusUpdate: (orderId, newStatus) {
          // KDS listesinde güncelle
          final index = _incomingOrders.indexWhere((o) => o.id == orderId);
          if (index != -1) {
            _incomingOrders[index].status = newStatus;
          }

          // Eğer müşterinin aktif siparişi bu ise, takip ekranını anında ilerlet
          if (_activeOrderId == orderId) {
            _activeOrderStatus = newStatus;
            _orderStatusMessage = _getStatusMessage(newStatus);
          }
          notifyListeners();
        },
      );
    } catch (e) {
      debugPrint("loadCompanyData hatası: $e");
      _products = MockDataService.getProducts();
    }

    _isLoading = false;
    notifyListeners();
  }

  String _getStatusMessage(OrderStatus status) {
    switch (status) {
      case OrderStatus.received:
        return "Siparişinizi aldık, sıraya ekledik! ☕";
      case OrderStatus.preparing:
        return "Kahveniz ustalıkla hazırlanıyor... ✨";
      case OrderStatus.onTheWay:
        return "Kurye Mert yola çıktı! 🛵 (Şu an asansör bekliyor...)";
      case OrderStatus.delivered:
        return "Afiyet olsun! Kapıdayız. 🚪😋";
      case OrderStatus.cancelled:
        return "Siparişiniz iptal edildi.";
    }
  }

  // Getters
  List<Product> get products => _products;
  List<Product> get drinks => _products.where((p) => p.category == 'drink').toList();
  List<Product> get snacks => _products.where((p) => p.category == 'snack').toList();
  List<CartItem> get cart => _cart;
  bool get isLoading => _isLoading;
  
  // Location Getters
  DeliveryLocation get selectedLocation => _selectedLocation;
  List<DeliveryLocation> get locations => _locations;
  
  // Loyalty Getters
  int get loyaltyStamps => _loyaltyStamps;
  int get freeProducts => _freeProducts;
  
  // Tracking Getters
  OrderStatus? get activeOrderStatus => _activeOrderStatus;
  String get orderStatusMessage => _orderStatusMessage;
  
  // Quick Reorder
  Product? get lastOrderedProduct => _lastOrderedProduct;

  // Grup Siparişi Getters
  bool get isGroupOrderActive => _isGroupOrderActive;
  bool get isPaying => _isPaying;
  GroupRole get userRole => _userRole;
  String get groupId => _groupId;
  List<GroupMember> get groupMembers => _groupMembers;
  
  String get formattedTime {
    final minutes = (_groupTimeRemaining / 60).floor();
    final seconds = _groupTimeRemaining % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  double get totalAmount {
    double total = _cart.fold(0, (sum, item) => sum + item.totalPrice);
    for (var member in _groupMembers) {
      total += member.items.fold(0, (sum, item) => sum + item.totalPrice);
    }
    return total;
  }

  // Setters & Actions
  void setLocation(DeliveryLocation loc) {
    _selectedLocation = loc;
    notifyListeners();
  }

  void addToCart(Product product, List<ProductModifier> modifiers, int quantity, {String? giftNote}) {
    if (product.isOutOfStock) return;
    
    _cart.add(CartItem(
      id: DateTime.now().toString(),
      product: product,
      selectedModifiers: modifiers,
      quantity: quantity,
      addedBy: 'Sen',
      giftNote: giftNote,
    ));
    notifyListeners();
  }

  Future<void> checkout() async {
    if (_cart.isEmpty) return;
    
    _lastOrderedProduct = _cart.first.product;
    final orderItems = List<CartItem>.from(_cart);
    final orderTotal = totalAmount;
    final companyId = _currentUser?.companyId ??
        AuthService().currentCompany?.id ??
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';
    final userId = _currentUser?.id ?? AuthService().currentUser?.id;

    final tempOrderId = 'ord_${DateTime.now().millisecondsSinceEpoch}';

    final order = Order(
      id: tempOrderId,
      companyId: companyId,
      userId: userId,
      customerName: _currentUser?.name ?? "Misafir",
      deliveryLocationId: _selectedLocation.id,
      locationName: _selectedLocation.name,
      items: orderItems,
      totalPrice: orderTotal,
      paymentMethod: _selectedPaymentMethod == PaymentMethod.googlePay ? "Google Pay" : "Kapıda Ödeme",
      timestamp: DateTime.now(),
      status: OrderStatus.received,
    );

    // Sadakat damgası
    _loyaltyStamps++;
    if (_loyaltyStamps >= 10) {
      _loyaltyStamps = 0;
      _freeProducts++;
    }

    _cart.clear();
    _activeOrderId = tempOrderId;
    _activeOrderStatus = OrderStatus.received;
    _orderStatusMessage = _getStatusMessage(OrderStatus.received);
    notifyListeners();

    // Veritabanına kaydet
    final createdOrder = await _databaseService.createOrder(
      order: order,
      companyId: companyId,
      userId: userId,
      deliveryLocationId: _selectedLocation.id,
    );

    if (createdOrder != null) {
      _activeOrderId = createdOrder.id;
      final exists = _incomingOrders.any((o) => o.id == createdOrder.id);
      if (!exists) {
        _incomingOrders.insert(0, createdOrder);
      }
    }

    // Socket yayını
    _socketService.emit('new_order', {
      'orderId': createdOrder?.id ?? tempOrderId,
      'items': orderItems,
      'status': 'received',
      'paymentMethod': _selectedPaymentMethod == PaymentMethod.googlePay ? "Google Pay" : "Kapıda Ödeme",
      'customerName': _currentUser?.name ?? "Misafir",
      'locationName': _selectedLocation.name,
      'totalPrice': orderTotal,
    });

    _startOrderTracking();
    notifyListeners();
  }

  void _startOrderTracking() {
    // Baristadan bağımsız demo fallback simülasyonu (eğer mutfaktan basılmazsa)
    int step = 0;
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 12), (timer) {
      step++;
      switch (step) {
        case 1:
          if (_activeOrderStatus == OrderStatus.received) {
            _activeOrderStatus = OrderStatus.preparing;
            _orderStatusMessage = _getStatusMessage(OrderStatus.preparing);
          }
          break;
        case 2:
          if (_activeOrderStatus == OrderStatus.preparing) {
            _activeOrderStatus = OrderStatus.onTheWay;
            _orderStatusMessage = _getStatusMessage(OrderStatus.onTheWay);
          }
          break;
        case 3:
          if (_activeOrderStatus == OrderStatus.onTheWay) {
            _activeOrderStatus = OrderStatus.delivered;
            _orderStatusMessage = _getStatusMessage(OrderStatus.delivered);
            timer.cancel();
          }
          break;
      }
      notifyListeners();
    });
  }

  // --- User Profile & Payment ---
  void updateUserProfile({required String name, required String email, String? photoUrl, String? companyId}) {
    _currentUser = UserProfile(name: name, email: email, photoUrl: photoUrl, companyId: companyId);
    if (companyId != null) {
      loadCompanyData(companyId);
    }
    notifyListeners();
  }

  void setPaymentMethod(PaymentMethod method) {
    _selectedPaymentMethod = method;
    notifyListeners();
  }

  // --- GRUP SİPARİŞİ MANTIĞI ---
  void startGroupOrder() {
    _isGroupOrderActive = true;
    _isPaying = false;
    _userRole = GroupRole.leader;
    _groupId = 'group_${DateTime.now().millisecondsSinceEpoch}';
    _groupTimeRemaining = 300;
    _groupMembers.clear();
    _groupMembers.add(GroupMember(id: 'm1', name: 'Ahmet'));
    _groupMembers.add(GroupMember(id: 'm2', name: 'Ayşe'));
    _startGroupTimer();
    notifyListeners();
  }

  void joinGroupOrder(String id) {
    _isGroupOrderActive = true;
    _isPaying = false;
    _userRole = GroupRole.friend;
    _groupId = id;
    _groupTimeRemaining = 280;
    _startGroupTimer();
    notifyListeners();
  }

  void _startGroupTimer() {
    _groupTimer?.cancel();
    _groupTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_groupTimeRemaining > 0) {
        _groupTimeRemaining--;
        if (_groupTimeRemaining == 295) _simulateMemberUpdate('m1', MemberStatus.ready, 'Çay');
        if (_groupTimeRemaining == 290) _simulateMemberUpdate('m2', MemberStatus.choosing, 'Kurabiye');
        notifyListeners();
      } else {
        cancelGroupOrder();
      }
    });
  }

  void _simulateMemberUpdate(String memberId, MemberStatus status, String productName) {
    final index = _groupMembers.indexWhere((m) => m.id == memberId);
    if (index != -1) {
      final member = _groupMembers[index];
      member.status = status;
      if (member.items.isEmpty) {
        final product = _products.firstWhere((p) => p.name.contains(productName), orElse: () => _products.first);
        member.items.add(CartItem(
          id: '${memberId}_item',
          product: product,
          selectedModifiers: [],
          addedBy: member.name,
        ));
      }
      notifyListeners();
    }
  }

  void lockGroupForPayment() {
    _isPaying = true;
    notifyListeners();
  }

  void cancelGroupOrder() {
    _isGroupOrderActive = false;
    _isPaying = false;
    _groupTimer?.cancel();
    _groupMembers.clear();
    notifyListeners();
  }

  // --- ÜRÜN YÖNETİMİ (ADMİN & KDS) ---
  Future<void> addProduct(Product product, {String? companyId}) async {
    _products.add(product);
    notifyListeners();

    final targetCompanyId = companyId ??
        _currentUser?.companyId ??
        AuthService().currentCompany?.id ??
        'a0eebc99-9c0b-4ef8-bb6d-6bb9bd380a11';

    await _databaseService.addProduct(product, targetCompanyId);
  }

  Future<void> updateProduct(Product updatedProduct) async {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
    await _databaseService.updateProduct(updatedProduct);
  }
  
  // KDS: Sipariş Statü Güncelleme (Canlı Mutfak Barista)
  Future<void> updateOrderStatus(String orderId, OrderStatus newStatus) async {
    final index = _incomingOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _incomingOrders[index].status = newStatus;
    }

    if (_activeOrderId == orderId) {
      _activeOrderStatus = newStatus;
      _orderStatusMessage = _getStatusMessage(newStatus);
    }
    notifyListeners();

    _socketService.emit('status_update', {
      'orderId': orderId,
      'status': newStatus.toString(),
    });

    await _databaseService.updateOrderStatus(orderId, newStatus);
  }

  // KDS / Mutfak: Ürün Aç/Kapa (Canlı Stok)
  Future<void> toggleProductAvailability(String productId, bool isAvailable) async {
    final index = _products.indexWhere((p) => p.id == productId);
    if (index != -1) {
      final p = _products[index];
      _products[index] = Product(
        id: p.id,
        companyId: p.companyId,
        name: p.name,
        description: p.description,
        basePrice: p.basePrice,
        imageUrl: p.imageUrl,
        category: p.category,
        modifierGroups: p.modifierGroups,
        isInfiniteStock: p.isInfiniteStock,
        stockQuantity: isAvailable ? 100 : 0,
        isAvailable: isAvailable,
      );
      notifyListeners();
    }

    _socketService.emit('toggle_product', {
      'id': productId,
      'isAvailable': isAvailable,
    });

    await _databaseService.toggleProductAvailability(productId, isAvailable);
  }

  Future<void> deleteProduct(String productId) async {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
    await _databaseService.deleteProduct(productId);
  }

  bool isModifierConflict(Product product, List<ProductModifier> selectedModifiers, ModifierGroup currentGroup) {
    bool hasNoMilkModifier = selectedModifiers.any((m) => m.name.contains('Sade') || m.name.contains('Siyah'));
    if (currentGroup.name.contains('Süt') && hasNoMilkModifier) return true;
    return false;
  }

  @override
  void notifyListeners() {
    if (!_isDisposed) {
      super.notifyListeners();
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _trackingTimer?.cancel();
    _groupTimer?.cancel();
    _orderSub?.cancel();
    _productSub?.cancel();
    _databaseService.dispose();
    super.dispose();
  }
}
