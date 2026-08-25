// screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'providers.dart';

Widget buildProductImage(
  String imageUrl, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
  BorderRadius? borderRadius,
}) {
  Widget imgWidget;
  if (imageUrl.startsWith('http')) {
    imgWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.orange.shade50,
        child: const Icon(Icons.coffee_rounded, color: Colors.orange),
      ),
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Container(
          width: width,
          height: height,
          color: Colors.grey.shade100,
          child: const Center(
            child: SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.orange),
            ),
          ),
        );
      },
    );
  } else if (imageUrl.isNotEmpty) {
    imgWidget = Image.asset(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (_, __, ___) => Container(
        width: width,
        height: height,
        color: Colors.orange.shade50,
        child: const Icon(Icons.coffee_rounded, color: Colors.orange),
      ),
    );
  } else {
    imgWidget = Container(
      width: width,
      height: height,
      color: Colors.orange.shade50,
      child: const Icon(Icons.coffee_rounded, color: Colors.orange),
    );
  }

  if (borderRadius != null) {
    return ClipRRect(borderRadius: borderRadius, child: imgWidget);
  }
  return imgWidget;
}

// --- ANA EKRAN (DASHBOARD) ---
class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: provider.userRole == GroupRole.friend && provider.isGroupOrderActive
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(color: Colors.green.shade50, borderRadius: BorderRadius.circular(8)),
                  child: const Text("Mert'in Grubuna Katıldın 👥", style: TextStyle(color: Colors.green, fontSize: 13, fontWeight: FontWeight.bold)),
                )
              : GestureDetector(
                  onTap: () => _showLocationPicker(context, provider),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("📍 ${provider.selectedLocation.name}", style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.bold)),
                          const Icon(Icons.keyboard_arrow_down, color: Colors.orange, size: 20),
                        ],
                      ),
                      const Text("Seçili Teslimat Noktası", style: TextStyle(color: Colors.grey, fontSize: 11)),
                    ],
                  ),
                ),
          actions: [
            IconButton(
              icon: const Icon(Icons.card_membership, color: Colors.orange),
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoyaltyScreen())),
            ),
            if (provider.isGroupOrderActive && provider.userRole == GroupRole.leader)
              IconButton(icon: const Icon(Icons.share, color: Colors.blue), onPressed: () => _showShareDialog(context, provider.groupId)),
          ],
          bottom: TabBar(
            labelColor: Colors.orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.orange,
            tabs: [
              Tab(text: "İÇECEKLER"),
              Tab(text: "ATIŞTIRMALIKLAR"),
            ],
          ),
        ),
        body: Stack(
          children: [
            Column(
              children: [
                // Grup Durum Şeridi (Yeni Tasarım)
                if (provider.isGroupOrderActive)
                  PersistentGroupStatusBar(),

                // Ürün Listesi
                Expanded(
                  child: ListView(
                    children: [
                      // Sadakat Kartı Önizleme
                      _buildLoyaltyMiniCard(context, provider),

                      // Hızlı Tekrarla (Önceki Sipariş)
                      if (provider.lastOrderedProduct != null)
                        _buildQuickReorder(context, provider.lastOrderedProduct!),

                      // Grup Siparişi Banner
                      if (!provider.isGroupOrderActive)
                        _buildGroupOrderBanner(context, provider),

                      const SizedBox(height: 16),

                      SizedBox(
                        height: 500, // Grid için yükseklik
                        child: TabBarView(
                          children: [
                            ProductGrid(products: provider.drinks),
                            ProductGrid(products: provider.snacks),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            // Alt Sabit Butonlar (SİPARİŞ TAKİP + SEPET)
            Positioned(
              bottom: 16,
              left: 16,
              right: 16,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (provider.activeOrderStatus != null)
                    _buildTrackingBanner(context, provider),
                  const SizedBox(height: 8),
                  if (provider.cart.isNotEmpty || (provider.isGroupOrderActive && provider.totalAmount > 0))
                    _buildUnifiedCartFAB(context, provider),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLocationPicker(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Nereye Gelsin?", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            ...provider.locations.map((loc) => ListTile(
                  leading: Text(loc.icon, style: const TextStyle(fontSize: 24)),
                  title: Text(loc.name),
                  trailing: provider.selectedLocation == loc ? const Icon(Icons.check_circle, color: Colors.orange) : null,
                  onTap: () {
                    provider.setLocation(loc);
                    Navigator.pop(context);
                  },
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildLoyaltyMiniCard(BuildContext context, AppProvider provider) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoyaltyScreen())),
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF2C3E50), Color(0xFF000000)]),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Loyalty Card", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text("${provider.loyaltyStamps}/10 Damga", style: const TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
            const Icon(Icons.stars, color: Colors.orange, size: 30),
          ],
        ),
      ),
    );
  }

// Helper functions for safe image handling across network and assets
Widget buildProductImage(String imageUrl, {double? width, double? height, BoxFit fit = BoxFit.cover, BorderRadius? borderRadius}) {
  Widget imgWidget;
  if (imageUrl.isEmpty) {
    imgWidget = Container(
      width: width,
      height: height,
      color: Colors.grey[200],
      child: const Icon(Icons.coffee, color: Colors.grey),
    );
  } else if (imageUrl.startsWith('assets/')) {
    imgWidget = Image.asset(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.coffee, color: Colors.grey),
      ),
    );
  } else {
    imgWidget = Image.network(
      imageUrl,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => Container(
        width: width,
        height: height,
        color: Colors.grey[200],
        child: const Icon(Icons.coffee, color: Colors.grey),
      ),
    );
  }

  if (borderRadius != null) {
    return ClipRRect(borderRadius: borderRadius, child: imgWidget);
  }
  return imgWidget;
}

ImageProvider getProductImageProvider(String imageUrl) {
  if (imageUrl.startsWith('assets/')) {
    return AssetImage(imageUrl);
  } else if (imageUrl.startsWith('http')) {
    return NetworkImage(imageUrl);
  }
  return const AssetImage('assets/images/espresso.png');
}

  Widget _buildQuickReorder(BuildContext context, Product product) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: Colors.orange.shade50, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.orange.shade200)),
      child: Row(
        children: [
          buildProductImage(product.imageUrl, width: 50, height: 50, fit: BoxFit.cover, borderRadius: BorderRadius.circular(8)),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Hızlı Tekrarla", style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold)),
                Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => _showProductDetail(context, product),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white, elevation: 0),
            child: const Text("EKLE"),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupOrderBanner(BuildContext context, AppProvider provider) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          const Icon(Icons.groups, color: Colors.white, size: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("The Office Hero", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                const Text("Arkadaşlarınızla ortak sipariş verin!", style: TextStyle(color: Colors.white70, fontSize: 12)),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () => provider.startGroupOrder(),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: Colors.blue.shade600, elevation: 0),
            child: const Text("BAŞLAT"),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, String groupId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Arkadaşlarını Davet Et"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Bu linki kopyalayıp arkadaşlarına gönder:"),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(4)),
              child: Text("https://compound.coffee/join/$groupId", style: const TextStyle(fontSize: 12, color: Colors.blue)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("KAPAT")),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Arkadaş olarak katılımı simüle et
              Provider.of<AppProvider>(context, listen: false).joinGroupOrder(groupId);
            },
            child: const Text("KENDİMİ ARKADAŞ YAP (Simüle)"),
          ),
        ],
      ),
    );
  }

  Widget _buildUnifiedCartFAB(BuildContext context, AppProvider provider) {
    return SizedBox(
      height: 56,
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 8,
        ),
        onPressed: () => _showCartSheet(context, provider),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Icon(Icons.shopping_bag_outlined),
            Text("${provider.totalAmount.toStringAsFixed(0)} TL ÖDE", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Icon(Icons.arrow_forward_ios, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackingBanner(BuildContext context, AppProvider provider) {
    return GestureDetector(
      onTap: () => showModalBottomSheet(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (context) => const OrderTrackingSheet(),
      ),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: Colors.blue.shade600, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.blue.withValues(alpha: 0.3), blurRadius: 10)]),
        child: Row(
          children: [
            const Icon(Icons.moped, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(provider.orderStatusMessage, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13))),
            const Text("İZLE >", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  void _showCartSheet(BuildContext context, AppProvider provider) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            const SizedBox(height: 12),
            Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
            const Padding(padding: EdgeInsets.all(24), child: Text("Sipariş Özeti", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold))),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                children: [
                  if (provider.cart.isNotEmpty) ...[
                    const Text("SENİN SEÇİMLERİN", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...provider.cart.map((item) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text("${item.quantity}x ${item.product.name}"),
                          subtitle: Text(item.giftNote != null ? "🎁 Ismarlama: ${item.giftNote}" : "Kendim için"),
                          trailing: Text("${item.totalPrice.toStringAsFixed(0)} TL"),
                        )),
                    const SizedBox(height: 16),
                  ],
                  if (provider.isGroupOrderActive) ...[
                    const Text("GRUP ÜYELERİ", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold, fontSize: 12)),
                    const SizedBox(height: 8),
                    ...provider.groupMembers.map((m) => Column(
                          children: m.items.map((i) => ListTile(
                                contentPadding: EdgeInsets.zero,
                                leading: CircleAvatar(radius: 12, child: Text(m.name[0])),
                                title: Text("${m.name}: ${i.product.name}"),
                                trailing: Text("${i.totalPrice.toStringAsFixed(0)} TL"),
                              )).toList(),
                        )),
                  ],
                  const Divider(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Teslimat Noktası", style: TextStyle(color: Colors.grey)),
                      Text(provider.selectedLocation.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),

              const Divider(),

              // Ödeme Seçenekleri
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("ÖDEME YÖNTEMİ", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          RadioListTile<PaymentMethod>(
                            title: const Row(children: [Icon(Icons.payment, color: Colors.blue), SizedBox(width: 8), Text("Google Pay", style: TextStyle(fontWeight: FontWeight.bold))]),
                            subtitle: const Text("Hızlı ve Dijital"),
                            value: PaymentMethod.googlePay,
                            groupValue: provider.selectedPaymentMethod,
                            onChanged: (val) => provider.setPaymentMethod(val!),
                            activeColor: Colors.blue,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          ),
                          const Divider(height: 1),
                          RadioListTile<PaymentMethod>(
                            title: const Row(children: [Icon(Icons.delivery_dining, color: Colors.orange), SizedBox(width: 8), Text("Teslimatta Öde", style: TextStyle(fontWeight: FontWeight.bold))]),
                            subtitle: const Text("Nakit veya Kart ile kapıda"),
                            value: PaymentMethod.payAtDoor,
                            groupValue: provider.selectedPaymentMethod,
                            onChanged: (val) => provider.setPaymentMethod(val!),
                            activeColor: Colors.orange,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.all(24).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16, top: 0),
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                    onPressed: () {
                      provider.checkout();
                      Navigator.pop(context);
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => const OrderTrackingSheet(),
                      );
                    },
                    child: Text("SİPARİŞİ ONAYLA - ${provider.totalAmount.toStringAsFixed(0)} ₺", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showProductDetail(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(product: product),
    );
  }
}

class PersistentGroupStatusBar extends StatelessWidget {
  const PersistentGroupStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final count = provider.groupMembers.where((m) => m.status == MemberStatus.choosing).length;

    return Container(
      width: double.infinity,
      color: const Color(0xFFE91E63),
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              const Icon(Icons.groups, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                "$count Kişi Ekliyor...",
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.timer, color: Colors.white, size: 16),
              const SizedBox(width: 4),
              Text(provider.formattedTime, style: const TextStyle(color: Colors.white)),
              const SizedBox(width: 8),
              TextButton(
                onPressed: () => showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) => GroupTrackingSheet(),
                ),
                child: const Text(
                  "GÖR >",
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }
}

// --- ÜRÜN IZGARASI ---
class ProductGrid extends StatelessWidget {
  final List<Product> products;
  const ProductGrid({super.key, required this.products});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    if (provider.isLoading) {
      return GridView.builder(
        padding: const EdgeInsets.all(16).copyWith(bottom: 100),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.75,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: 6,
        itemBuilder: (context, index) => const ShimmerCard(),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16).copyWith(bottom: 100), // Alt bar için boşluk
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return ProductCard(product: product);
      },
    );
  }
}

class ShimmerCard extends StatefulWidget {
  const ShimmerCard({super.key});

  @override
  State<ShimmerCard> createState() => _ShimmerCardState();
}

class _ShimmerCardState extends State<ShimmerCard> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.grey[200]!, Colors.grey[100]!, Colors.grey[200]!],
                      stops: [_controller.value - 0.3, _controller.value, _controller.value + 0.3],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(height: 12, width: 80, color: Colors.grey[200]),
                    const SizedBox(height: 8),
                    Container(height: 12, width: 40, color: Colors.grey[200]),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }
}

// --- ÜRÜN KARTI ---
class ProductCard extends StatelessWidget {
  final Product product;
  const ProductCard({super.key, required this.product});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: product.isOutOfStock 
          ? null 
          : () => _showProductDetail(context, product),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Görsel ve Stok Durumu
            Expanded(
              child: Stack(
                children: [
                  Positioned.fill(
                    child: buildProductImage(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                  ),
                  if (product.isOutOfStock)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.8),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: const Center(child: Text("TÜKENDİ", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16), maxLines: 1),
                  SizedBox(height: 4),
                  Text("${product.basePrice} TL", style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductDetail(BuildContext context, Product product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => ProductDetailSheet(product: product),
    );
  }
}

// --- ÜRÜN DETAY (BOTTOM SHEET) - Karmaşık Mantık Burada ---
class ProductDetailSheet extends StatefulWidget {
  final Product product;
  const ProductDetailSheet({super.key, required this.product});

  @override
  State<ProductDetailSheet> createState() => _ProductDetailSheetState();
}

class _ProductDetailSheetState extends State<ProductDetailSheet> {
  final Map<String, List<ProductModifier>> _selections = {};
  int _quantity = 1;

  bool _isGiftMode = false;
  final TextEditingController _giftNoteController = TextEditingController();

  Widget _buildGiftModeToggle() {
    return Column(
      children: [
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text("Başkasını Ismarla 🎁", style: TextStyle(fontWeight: FontWeight.bold)),
          subtitle: const Text("Arkadaşına sürpriz yap!"),
          value: _isGiftMode,
          activeColor: Colors.orange,
          onChanged: (val) => setState(() => _isGiftMode = val),
        ),
        if (_isGiftMode)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: TextField(
              controller: _giftNoteController,
              decoration: InputDecoration(
                hintText: "Örn: Mert için benden!",
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                prefixIcon: const Icon(Icons.note_add_outlined),
                fillColor: Colors.grey.shade50,
                filled: true,
              ),
            ),
          ),
      ],
    );
  }

  @override
  void initState() {
    super.initState();
    for (var group in widget.product.modifierGroups) {
      if (group.isRequired && group.options.isNotEmpty) {
        _selections[group.id] = [group.options.first];
      } else {
        _selections[group.id] = [];
      }
    }
  }

  double get _currentPrice {
    double totalMods = 0;
    for (var mods in _selections.values) {
      for (var mod in mods) {
        totalMods += mod.price;
      }
    }
    return (widget.product.basePrice + totalMods) * _quantity;
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Üst Kapatma Çizgisi ve Kontrol Barı
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(icon: const Icon(Icons.arrow_back_ios, size: 20), onPressed: () => Navigator.pop(context)),
                const Text("Ürün Detayı", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                // Büyük Ürün Görseli
                const SizedBox(height: 16),
                Center(
                  child: buildProductImage(
                    widget.product.imageUrl,
                    height: 200,
                    width: 200,
                    fit: BoxFit.cover,
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(child: Text(widget.product.name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold))),
                    Text("${widget.product.basePrice.toStringAsFixed(0)} TL", style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                Text(widget.product.description, style: const TextStyle(color: Colors.grey)),
                
                const Divider(height: 32),

                // Başkasını Ismarla (Gift Mode)
                _buildGiftModeToggle(),
                
                const Divider(height: 48),

                // Opsiyonlar (Modifier Groups)
                ...widget.product.modifierGroups.map((group) {
                  // Seçili modlara göre çakışma kontrolü
                  List<ProductModifier> allSelected = [];
                  for (var list in _selections.values) {
                    allSelected.addAll(list);
                  }
                  final isDisabled = provider.isModifierConflict(widget.product, allSelected, group);

                  return Opacity(
                    opacity: isDisabled ? 0.3 : 1.0,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(group.name.toUpperCase(), style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey[700], fontSize: 13)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: group.options.map((option) {
                            final isSelected = _selections[group.id]?.contains(option) ?? false;
                            return ChoiceChip(
                              label: Text("${option.name} ${option.price > 0 ? '(+${option.price.toStringAsFixed(0)})' : ''}"),
                              selected: isSelected,
                              selectedColor: Colors.orange.withValues(alpha: 0.1),
                              labelStyle: TextStyle(
                                color: isSelected ? Colors.deepOrange : Colors.black87,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                                side: BorderSide(color: isSelected ? Colors.orange : Colors.grey.shade300),
                              ),
                              onSelected: isDisabled ? null : (selected) {
                                setState(() {
                                  if (group.isMultiSelect) {
                                    if (selected) {
                                      _selections[group.id]!.add(option);
                                    } else {
                                      _selections[group.id]!.remove(option);
                                    }
                                  } else {
                                    _selections[group.id] = [option];
                                  }
                                });
                              },
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                      ],
                    ),
                  );
                }),

                // Adet Seçici
                const Text("ADET", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey, fontSize: 13)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          IconButton(icon: const Icon(Icons.remove), onPressed: () => setState(() { if (_quantity > 1) _quantity--; })),
                          Text("$_quantity", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          IconButton(icon: const Icon(Icons.add), onPressed: () => setState(() { if (_quantity < 10) _quantity++; })),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 120), // Alt buton için boşluk
              ],
            ),
          ),

          // Alt Dinamik Buton
          Container(
            padding: EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            decoration: const BoxDecoration(
              color: Colors.white,
              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 15, offset: Offset(0, -5))],
            ),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange, 
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () {
                  List<ProductModifier> finalMods = [];
                  for (var list in _selections.values) {
                    finalMods.addAll(list);
                  }
                  provider.addToCart(
                    widget.product, 
                    finalMods, 
                    _quantity,
                    giftNote: _isGiftMode ? _giftNoteController.text : null,
                  );
                  Navigator.pop(context);
                },
                child: Text(
                  "SEPETE EKLE - ${_currentPrice.toStringAsFixed(0)} TL", 
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// --- SADAKAT EKRANI (LOYALTY) ---
class LoyaltyScreen extends StatelessWidget {
  const LoyaltyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.transparent, elevation: 0, iconTheme: const IconThemeData(color: Colors.white)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Icon(Icons.stars, color: Colors.orange, size: 80),
            const SizedBox(height: 16),
            const Text("Compound Loyalty", style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            const Text("10 Damgada Bir Ürün Bedava!", style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 40),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: List.generate(10, (index) {
                final isStamped = index < provider.loyaltyStamps;
                return Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: isStamped ? Colors.orange : Colors.grey.shade900,
                    shape: BoxShape.circle,
                    border: Border.all(color: isStamped ? Colors.orange : Colors.white24, width: 2),
                  ),
                  child: Icon(
                    isStamped ? Icons.check : Icons.coffee_outlined,
                    color: isStamped ? Colors.white : Colors.white24,
                  ),
                );
              }),
            ),
            const Spacer(),
            if (provider.freeProducts > 0)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(color: Colors.green, borderRadius: BorderRadius.circular(16)),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard, color: Colors.white),
                    const SizedBox(width: 12),
                    Text("${provider.freeProducts} Bedava Ürünün Var!", style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

// --- SİPARİŞ TAKİP EKRANI (LIVE TRACKING) ---
class OrderTrackingSheet extends StatelessWidget {
  const OrderTrackingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final status = provider.activeOrderStatus;

    if (status == null) return const Center(child: Text("Aktif sipariş bulunamadı."));

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          Text(provider.orderStatusMessage, textAlign: TextAlign.center, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildStatusIcon(Icons.receipt_long, "Alındı", status.index >= 0),
              _buildStatusLine(status.index >= 1),
              _buildStatusIcon(Icons.soup_kitchen, "Mutfakta", status.index >= 1),
              _buildStatusLine(status.index >= 2),
              _buildStatusIcon(Icons.moped, "Yolda", status.index >= 2),
              _buildStatusLine(status.index >= 3),
              _buildStatusIcon(Icons.door_front_door, "Kapıda", status.index >= 3),
            ],
          ),
          const SizedBox(height: 40),
          if (status == OrderStatus.onTheWay)
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(strokeWidth: 2),
                SizedBox(width: 12),
                Text("Mert asansör bekliyor...", style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic)),
              ],
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: TextButton(onPressed: () => Navigator.pop(context), child: const Text("KAPAT")),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIcon(IconData icon, String label, bool active) {
    return Column(
      children: [
        Icon(icon, color: active ? Colors.orange : Colors.grey.shade300, size: 30),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: active ? Colors.black : Colors.grey.shade400, fontWeight: active ? FontWeight.bold : FontWeight.normal)),
      ],
    );
  }

  Widget _buildStatusLine(bool active) {
    return Expanded(child: Container(height: 2, color: active ? Colors.orange : Colors.grey.shade200));
  }
}
class GroupTrackingSheet extends StatelessWidget {
  const GroupTrackingSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final bool isWarning = (provider.totalAmount > 0 && provider.formattedTime.startsWith('00:'));

    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text("Grup Sepeti", style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          if (provider.isGroupOrderActive)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: isWarning ? Colors.red.shade50 : Colors.blue.shade50,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.timer, color: isWarning ? Colors.red : Colors.blue, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    "Kapanmasına: ${provider.formattedTime}",
                    style: TextStyle(color: isWarning ? Colors.red : Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text("SENİN SEÇİMLERİN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                ...provider.cart.where((i) => i.addedBy == 'Sen').map((item) => ListTile(
                      title: Text(item.product.name),
                      subtitle: Text(item.selectedModifiers.map((e) => e.name).join(', ')),
                      trailing: Text("${item.totalPrice.toStringAsFixed(0)} TL"),
                    )),
                const Divider(height: 32),
                const Text("ARKADAŞLARIN", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                ...provider.groupMembers.map((member) => Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(member.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: member.status == MemberStatus.ready ? Colors.green.shade50 : Colors.orange.shade50,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    member.status == MemberStatus.ready ? "Hazır" : "Seçiyor...",
                                    style: TextStyle(
                                      color: member.status == MemberStatus.ready ? Colors.green : Colors.orange,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (member.items.isEmpty)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: Text("Henüz ekleme yapmadı.", style: TextStyle(color: Colors.grey, fontSize: 13)),
                              ),
                            ...member.items.map((item) => Padding(
                                  padding: const EdgeInsets.only(top: 4),
                                  child: Text("• ${item.product.name} (${item.totalPrice.toStringAsFixed(0)} TL)", style: const TextStyle(fontSize: 14)),
                                )),
                          ],
                        ),
                      ),
                    )),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.all(16).copyWith(bottom: MediaQuery.of(context).padding.bottom + 16),
            decoration: const BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)]),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.lock_outline),
                label: Text("GRUBU KAPAT VE ÖDE (${provider.totalAmount.toStringAsFixed(0)} TL)"),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.black, foregroundColor: Colors.white),
                onPressed: () {
                  provider.lockGroupForPayment();
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Ödeme işlemi başlatıldı! 🚀")));
                },
              ),
            ),
          )
        ],
      ),
    );
  }
}
