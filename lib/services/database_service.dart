// services/database_service.dart
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models.dart';
import 'supabase_config.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  SupabaseClient? get _client {
    try {
      if (SupabaseConfig.isConfigured) {
        return Supabase.instance.client;
      }
    } catch (_) {}
    return null;
  }

  RealtimeChannel? _productsChannel;

  /// Firmanın tüm ürünlerini ve bağlı opsiyon gruplarını çeker
  Future<List<Product>> fetchProducts(String companyId) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client
          .from('products')
          .select('''
            *,
            modifier_groups (
              *,
              product_modifiers (*)
            )
          ''')
          .eq('company_id', companyId)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Product.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("DatabaseService.fetchProducts hatası: $e");
      return [];
    }
  }

  /// Firmanın teslimat noktalarını çeker
  Future<List<DeliveryLocation>> fetchDeliveryLocations(String companyId) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client
          .from('delivery_locations')
          .select('*')
          .eq('company_id', companyId)
          .eq('is_active', true)
          .order('created_at', ascending: true);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => DeliveryLocation.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("DatabaseService.fetchDeliveryLocations hatası: $e");
      return [];
    }
  }

  /// Yeni ürün ekler (Admin)
  Future<bool> addProduct(Product product, String companyId) async {
    final client = _client;
    if (client == null) return false;

    try {
      // 1. Ürünü ekle
      final productData = await client
          .from('products')
          .insert({
            'company_id': companyId,
            'name': product.name,
            'description': product.description,
            'base_price': product.basePrice,
            'category': product.category,
            'image_url': product.imageUrl,
            'is_infinite_stock': product.isInfiniteStock,
            'stock_quantity': product.stockQuantity,
            'is_available': product.isAvailable,
          })
          .select('id')
          .single();

      final String createdProductId = productData['id'] as String;

      // 2. Opsiyon gruplarını ekle
      for (var group in product.modifierGroups) {
        final groupData = await client
            .from('modifier_groups')
            .insert({
              'product_id': createdProductId,
              'name': group.name,
              'is_required': group.isRequired,
              'is_multi_select': group.isMultiSelect,
              'dependent_on_variant_id': group.dependentOnVariantId,
            })
            .select('id')
            .single();

        final String createdGroupId = groupData['id'] as String;

        // 3. Opsiyonları ekle
        for (var opt in group.options) {
          await client.from('product_modifiers').insert({
            'group_id': createdGroupId,
            'name': opt.name,
            'price': opt.price,
            'is_available': opt.isAvailable,
          });
        }
      }

      return true;
    } catch (e) {
      debugPrint("DatabaseService.addProduct hatası: $e");
      return false;
    }
  }

  /// Ürün güncelle (Admin)
  Future<bool> updateProduct(Product product) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from('products').update({
        'name': product.name,
        'description': product.description,
        'base_price': product.basePrice,
        'category': product.category,
        'image_url': product.imageUrl,
        'is_infinite_stock': product.isInfiniteStock,
        'stock_quantity': product.stockQuantity,
        'is_available': product.isAvailable,
      }).eq('id', product.id);

      return true;
    } catch (e) {
      debugPrint("DatabaseService.updateProduct hatası: $e");
      return false;
    }
  }

  /// Stok / Erişilebilirlik Aç-Kapa (KDS / Mutfak / Admin)
  Future<bool> toggleProductAvailability(String productId, bool isAvailable) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from('products').update({
        'is_available': isAvailable,
      }).eq('id', productId);

      return true;
    } catch (e) {
      debugPrint("DatabaseService.toggleProductAvailability hatası: $e");
      return false;
    }
  }

  /// Ürün sil (Admin)
  Future<bool> deleteProduct(String productId) async {
    final client = _client;
    if (client == null) return false;

    try {
      await client.from('products').delete().eq('id', productId);
      return true;
    } catch (e) {
      debugPrint("DatabaseService.deleteProduct hatası: $e");
      return false;
    }
  }

  /// Supabase Realtime: Menü / Stok değişikliklerini canlı dinleme
  void subscribeToProducts({
    required String companyId,
    required Function() onUpdate,
  }) {
    final client = _client;
    if (client == null) return;

    try {
      _productsChannel?.unsubscribe();
      _productsChannel = client
          .channel('public:products:company_$companyId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'products',
            callback: (payload) {
              debugPrint("Realtime Product Update tetiklendi: ${payload.eventType}");
              onUpdate();
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint("Realtime subscribeToProducts hatası: $e");
    }
  }

  RealtimeChannel? _ordersChannel;

  /// Yeni Sipariş Oluştur ve Ürünlerini Kaydet (Müşteri)
  Future<Order?> createOrder({
    required Order order,
    required String companyId,
    String? userId,
    String? deliveryLocationId,
  }) async {
    final client = _client;
    if (client == null) {
      // Demo / Offline fallback: Local order return
      return order;
    }

    try {
      // 1. Siparişi ana tabloya ekle
      final orderData = await client
          .from('orders')
          .insert({
            'company_id': companyId,
            'user_id': userId,
            'customer_name': order.customerName,
            'delivery_location_id': deliveryLocationId,
            'location_name': order.locationName,
            'total_price': order.totalPrice,
            'payment_method': order.paymentMethod,
            'status': order.status.toDbString(),
          })
          .select('id, created_at')
          .single();

      final String createdOrderId = orderData['id'] as String;
      final DateTime createdAt = DateTime.tryParse(orderData['created_at'] as String? ?? '') ?? DateTime.now();

      // 2. Siparişteki her bir ürünü ve opsiyonlarını kaydet
      for (var item in order.items) {
        await client.from('order_items').insert({
          'order_id': createdOrderId,
          'product_id': item.product.id.length > 30 ? item.product.id : null,
          'product_name': item.product.name,
          'quantity': item.quantity,
          'unit_price': item.product.basePrice,
          'total_price': item.totalPrice,
          'selected_modifiers': item.selectedModifiers.map((m) => m.toJson()).toList(),
          'item_note': item.note,
          'gift_note': item.giftNote,
        });
      }

      return Order(
        id: createdOrderId,
        companyId: companyId,
        userId: userId,
        customerName: order.customerName,
        deliveryLocationId: deliveryLocationId,
        locationName: order.locationName,
        items: order.items,
        totalPrice: order.totalPrice,
        paymentMethod: order.paymentMethod,
        timestamp: createdAt,
        status: order.status,
      );
    } catch (e) {
      debugPrint("DatabaseService.createOrder hatası: $e");
      return order;
    }
  }

  /// Firmanın Aktif / Bekleyen Siparişlerini Çeker (KDS / Mutfak)
  Future<List<Order>> fetchActiveOrders(String companyId) async {
    final client = _client;
    if (client == null) return [];

    try {
      final response = await client
          .from('orders')
          .select('''
            *,
            order_items (*)
          ''')
          .eq('company_id', companyId)
          .neq('status', 'delivered')
          .neq('status', 'cancelled')
          .order('created_at', ascending: false);

      final List<dynamic> data = response as List<dynamic>;
      return data.map((json) => Order.fromJson(json as Map<String, dynamic>)).toList();
    } catch (e) {
      debugPrint("DatabaseService.fetchActiveOrders hatası: $e");
      return [];
    }
  }

  /// Sipariş Durumunu Günceller (KDS / Barista: Hazırlanıyor -> Yolda -> Teslim)
  Future<bool> updateOrderStatus(String orderId, OrderStatus status) async {
    final client = _client;
    if (client == null) return true;

    try {
      await client.from('orders').update({
        'status': status.toDbString(),
      }).eq('id', orderId);

      return true;
    } catch (e) {
      debugPrint("DatabaseService.updateOrderStatus hatası: $e");
      return false;
    }
  }

  /// Supabase Realtime: Canlı Siparişleri ve Durum Güncellemelerini Dinle (KDS & Müşteri)
  void subscribeToOrders({
    required String companyId,
    required Function(Order newOrder) onNewOrder,
    required Function(String orderId, OrderStatus status) onStatusUpdate,
  }) {
    final client = _client;
    if (client == null) return;

    try {
      _ordersChannel?.unsubscribe();
      _ordersChannel = client
          .channel('public:orders:company_$companyId')
          .onPostgresChanges(
            event: PostgresChangeEvent.all,
            schema: 'public',
            table: 'orders',
            callback: (payload) async {
              debugPrint("Realtime Order Event: ${payload.eventType}");
              
              if (payload.eventType == PostgresChangeEvent.insert) {
                final record = payload.newRecord;
                final orderId = record['id'] as String?;
                if (orderId != null) {
                  // Siparişin ürünleriyle birlikte detayını çek
                  try {
                    final response = await client
                        .from('orders')
                        .select('*, order_items(*)')
                        .eq('id', orderId)
                        .single();
                    final order = Order.fromJson(response);
                    onNewOrder(order);
                  } catch (_) {}
                }
              } else if (payload.eventType == PostgresChangeEvent.update) {
                final record = payload.newRecord;
                final orderId = record['id'] as String?;
                final statusStr = record['status'] as String?;
                if (orderId != null && statusStr != null) {
                  onStatusUpdate(orderId, OrderStatus.fromDbString(statusStr));
                }
              }
            },
          )
          .subscribe();
    } catch (e) {
      debugPrint("Realtime subscribeToOrders hatası: $e");
    }
  }

  /// Realtime aboneliklerini temizle
  void dispose() {
    _productsChannel?.unsubscribe();
    _ordersChannel?.unsubscribe();
  }
}
