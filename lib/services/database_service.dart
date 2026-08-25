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

  /// Realtime aboneliğini temizle
  void dispose() {
    _productsChannel?.unsubscribe();
  }
}
