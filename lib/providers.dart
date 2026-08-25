// providers.dart
import 'dart:async';
import 'package:flutter/material.dart';
import 'models.dart';
import 'mock_service.dart';
import 'socket_service.dart';

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
  final List<DeliveryLocation> _locations = [
    DeliveryLocation(name: "Ofisim", icon: "🏢"),
    DeliveryLocation(name: "Proje Laboratuvarı", icon: "🧪"),
    DeliveryLocation(name: "A1 Toplantı Odası", icon: "🤝", isRoom: true),
    DeliveryLocation(name: "B3 Toplantı Odası", icon: "🤝", isRoom: true),
  ];
  
  int _loyaltyStamps = 6; // Örnek başlangıç değeri
  int _freeProducts = 0;
  
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

  // Socket Service
  final SocketService _socketService = SocketService();
  final List<Order> _incomingOrders = []; // KDS için aktif siparişler listesi

  AppProvider() {
    _selectedLocation = _locations[0];
    _loadProducts();
    _initSocketListeners();
  }

  void _initSocketListeners() {
    // Mutfak Paneli: Yeni sipariş dinle
    _socketService.onNewOrder.listen((data) {
      // Gelen datayı Order objesine çevir
      final items = (data['items'] as List).cast<CartItem>();
      
      final newOrder = Order(
        id: data['orderId'],
        customerName: data['customerName'] ?? 'Misafir',
        locationName: data['locationName'] ?? 'Bilinmiyor',
        items: items,
        totalPrice: data['totalPrice'] ?? 0.0,
        paymentMethod: data['paymentMethod'] ?? 'Nakit',
        timestamp: DateTime.now(),
        status: OrderStatus.received,
      );

      _incomingOrders.insert(0, newOrder); // En yeniyi başa ekle
      notifyListeners();
    });

    // Müşteri Paneli: Ürün stok durumu dinle
    _socketService.onProductUpdate.listen((data) {
      final productId = data['id'];
      final isAvailable = data['isAvailable'];
      
      final index = _products.indexWhere((p) => p.id == productId);
      if (index != -1) {
        // Stok durumunu güncelle (isInfiniteStock false yapıp stock 0 veya 999)
        final p = _products[index];
        _products[index] = Product(
          id: p.id,
          name: p.name,
          description: p.description,
          basePrice: p.basePrice,
          imageUrl: p.imageUrl,
          category: p.category,
          modifierGroups: p.modifierGroups,
          isInfiniteStock: isAvailable, // True ise açık, False ise kapalı (basit mantık)
          stockQuantity: isAvailable ? 100 : 0, 
        );
        notifyListeners();
      }
    });
  }

  List<Order> get incomingOrders => _incomingOrders;

  Future<void> _loadProducts() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _products = MockDataService.getProducts();
    _isLoading = false;
    notifyListeners();
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
    if (!product.isInfiniteStock && product.stockQuantity < quantity) return;
    
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

  void checkout() {
    if (_cart.isEmpty) return;
    
    // Sipariş tamamlandığında:
    _lastOrderedProduct = _cart.first.product;
    final orderItems = List<CartItem>.from(_cart);
    final orderTotal = totalAmount;
    
    // Loyalty güncelleme
    _loyaltyStamps++;
    if (_loyaltyStamps >= 10) {
      _loyaltyStamps = 0;
      _freeProducts++;
    }
    
    // Socket'e bildir
    _socketService.emit('new_order', {
      'orderId': DateTime.now().millisecondsSinceEpoch.toString().substring(8), // Kısa ID
      'items': orderItems,
      'status': 'received',
      'paymentMethod': _selectedPaymentMethod == PaymentMethod.googlePay ? "Google Pay" : "Kapıda Ödeme",
      'customerName': _currentUser?.name ?? "Misafir",
      'locationName': _selectedLocation.name,
      'totalPrice': orderTotal,
    });

    _cart.clear();

    // Takip başlat
    _startOrderTracking();
    notifyListeners();
  }

  void _startOrderTracking() {
    _activeOrderStatus = OrderStatus.received;
    _orderStatusMessage = "Siparişinizi aldık, sıraya ekledik! ☕";
    
    int step = 0;
    _trackingTimer?.cancel();
    _trackingTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      step++;
      switch (step) {
        case 1:
          _activeOrderStatus = OrderStatus.preparing;
          _orderStatusMessage = "Kahveniz ustalıkla hazırlanıyor... ✨";
          break;
        case 2:
          _activeOrderStatus = OrderStatus.onTheWay;
          _orderStatusMessage = "Kurye Mert yola çıktı! 🛵 (Şu an asansör bekliyor...)";
          break;
        case 3:
          _activeOrderStatus = OrderStatus.delivered;
          _orderStatusMessage = "Afiyet olsun! Kapıdayız. 🚪😋";
          timer.cancel();
          break;
      }
      notifyListeners();
    });
  }

  // --- User Profile & Payment ---
  void updateUserProfile({required String name, required String email, String? photoUrl}) {
    _currentUser = UserProfile(name: name, email: email, photoUrl: photoUrl);
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

  // --- ÜRÜN YÖNETİMİ (ADMİN) ---
  void addProduct(Product product) {
    _products.add(product);
    notifyListeners();
  }

  void updateProduct(Product updatedProduct) {
    final index = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (index != -1) {
      _products[index] = updatedProduct;
      notifyListeners();
    }
  }
  
  // KDS: Sipariş Statü Güncelleme (Manuel)
  void updateOrderStatus(String orderId, OrderStatus newStatus) {
    final index = _incomingOrders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _incomingOrders[index].status = newStatus;
      
      // Eğer 'delivered' ise listeden kaldırılabilir veya 'Tamamlananlar' listesine alınabilir.
      // Şimdilik listede tutalım ama rengi değişsin. veya en sona atalım.
      
      notifyListeners();
      
      // Müşteriye bildirim gönderme (Socket emit)
      // _socketService.emit('status_update', { 'orderId': orderId, 'status': newStatus.toString() });
    }
  }

  // KDS: Ürün Aç/Kapa
  void toggleProductAvailability(String productId, bool isAvailable) {
    _socketService.emit('toggle_product', {
      'id': productId,
      'isAvailable': isAvailable,
    });
    // Kendi local state'imizi de güncelleyelim (Socket dinleyicisi de yapacak ama olsun)
  }

  void deleteProduct(String productId) {
    _products.removeWhere((p) => p.id == productId);
    notifyListeners();
  }

  bool isModifierConflict(Product product, List<ProductModifier> selectedModifiers, ModifierGroup currentGroup) {
    bool hasNoMilkModifier = selectedModifiers.any((m) => m.name.contains('Sade') || m.name.contains('Siyah'));
    if (currentGroup.name.contains('Süt') && hasNoMilkModifier) return true;
    return false;
  }
}
