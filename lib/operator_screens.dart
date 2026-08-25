// operator_screens.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models.dart';
import 'providers.dart';

class OperatorDashboardScreen extends StatefulWidget {
  const OperatorDashboardScreen({super.key});

  @override
  State<OperatorDashboardScreen> createState() => _OperatorDashboardScreenState();
}

class _OperatorDashboardScreenState extends State<OperatorDashboardScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final activeCount = provider.incomingOrders.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('MERKEZİ MUTFAK YÖNETİMİ', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
        backgroundColor: Colors.blueGrey[900],
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.orange,
          unselectedLabelColor: Colors.white60,
          indicatorColor: Colors.orange,
          tabs: const [
            Tab(icon: Icon(Icons.dvr), text: 'KDS (Siparişler)'),
            Tab(icon: Icon(Icons.inventory), text: 'Menü & Stok'),
          ],
        ),
        actions: [
          IconButton(icon: const Icon(Icons.notifications_active, color: Colors.orange), onPressed: () {}),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(20)),
                child: Text("AÇIK: $activeCount Sipariş", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ),
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          OrderKdsView(),
          StockManagerView(),
        ],
      ),
    );
  }
}

// --- KDS GÖRÜNÜMÜ (GRID) ---
class OrderKdsView extends StatelessWidget {
  const OrderKdsView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final orders = provider.incomingOrders;

    if (orders.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline, size: 80, color: Colors.green[200]),
            const SizedBox(height: 16),
            Text("Tüm siparişler tamamlandı!", style: TextStyle(fontSize: 20, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          ],
        ),
      );
    }

    // Ekran genişliğine göre kolon sayısını ayarla
    final width = MediaQuery.of(context).size.width;
    final crossAxisCount = width > 1200 ? 4 : (width > 800 ? 3 : (width > 600 ? 2 : 1));

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: 0.75, // Kartın boy/en oranı
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: orders.length,
      itemBuilder: (context, index) {
        final order = orders[index];
        return _OrderCard(order: order);
      },
    );
  }
}

class _OrderCard extends StatelessWidget {
  final Order order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context, listen: false);
    final isNew = order.status == OrderStatus.received;
    final isPreparing = order.status == OrderStatus.preparing;
    
    // Zaman farkı hesapla
    final diff = DateTime.now().difference(order.timestamp).inMinutes;
    final timeStr = diff == 0 ? "Şimdi" : "$diff dk önce";

    Color statusColor;
    if (isNew) statusColor = Colors.blue;
    else if (isPreparing) statusColor = Colors.orange;
    else statusColor = Colors.green;

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor, width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("#${order.id}", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(4)),
                  child: Text(timeStr, style: const TextStyle(color: Colors.black54, fontSize: 12, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
            const Divider(),
            
            // User & Location
            Text(order.customerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.blue),
                const SizedBox(width: 4),
                Expanded(child: Text(order.locationName, style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.w600, fontSize: 13), overflow: TextOverflow.ellipsis)),
              ],
            ),
            const SizedBox(height: 12),
            
            // Items List
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: order.items.map((item) {
                    final mods = item.selectedModifiers.map((m) => m.name).join(', ');
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        "${item.quantity}x ${item.product.name} ${mods.isNotEmpty ? '($mods)' : ''}",
                        style: const TextStyle(fontSize: 14, height: 1.3),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
            
            const Divider(),
            
            // Payment & Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(order.paymentMethod, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.green)),
                Text("${order.totalPrice.toStringAsFixed(0)} TL", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (isNew) {
                         provider.updateOrderStatus(order.id, OrderStatus.preparing);
                      } else if (isPreparing) {
                         provider.updateOrderStatus(order.id, OrderStatus.onTheWay);
                      } else {
                         // Zaten yolda veya teslim edildi, belki arşivle fonksiyonu?
                         provider.updateOrderStatus(order.id, OrderStatus.delivered);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: statusColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      isNew ? "BAŞLA" : (isPreparing ? "YOLA ÇIKAR" : "TESLİM EDİLDİ"),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// --- STOK YÖNETİMİ ---
class StockManagerView extends StatelessWidget {
  const StockManagerView({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<AppProvider>(context);
    final products = provider.products;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        return Card(
          child: SwitchListTile(
            title: Text(product.name, style: TextStyle(fontWeight: FontWeight.bold, decoration: product.isInfiniteStock ? null : TextDecoration.lineThrough, color: product.isInfiniteStock ? Colors.black : Colors.grey)),
            subtitle: Text(product.isInfiniteStock ? "Satışta" : "KAPALI (Müşteride Görünmez)"),
            value: product.isInfiniteStock,
            activeColor: Colors.green,
            inactiveThumbColor: Colors.red,
            secondary: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: product.imageUrl.startsWith('assets/')
                  ? Image.asset(product.imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.coffee))
                  : Image.network(product.imageUrl, width: 40, height: 40, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.coffee)),
            ),
            onChanged: (val) {
              provider.toggleProductAvailability(product.id, val);
            },
          ),
        );
      },
    );
  }
}
