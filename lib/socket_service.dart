// socket_service.dart
import 'dart:async';

// Basit bir Socket.io simülasyonu
// Gerçek dünyada burası 'socket_io_client' paketini kullanır.
class SocketService {
  // Singleton pattern
  static final SocketService _instance = SocketService._internal();
  factory SocketService() => _instance;
  SocketService._internal();

  // Olayları dinlemek için StreamController'lar
  final _orderStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _productStreamController = StreamController<Map<String, dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onNewOrder => _orderStreamController.stream;
  Stream<Map<String, dynamic>> get onProductUpdate => _productStreamController.stream;

  // "Sunucuya" veri gönderme (Emit)
  void emit(String event, dynamic data) {
    print("SOCKET EMIT: $event -> $data");
    
    // Gecikme simülasyonu (Network latency)
    Future.delayed(const Duration(milliseconds: 300), () {
      if (!_orderStreamController.isClosed && event == 'new_order') {
        // Tüm dinleyicilere (Mutfak Paneli) haber ver
        _orderStreamController.add(data as Map<String, dynamic>);
      } else if (!_productStreamController.isClosed && event == 'toggle_product') {
        // Tüm dinleyicilere (Müşteri Uygulaması) haber ver
        _productStreamController.add(data as Map<String, dynamic>);
      }
    });
  }

  void dispose() {
    _orderStreamController.close();
    _productStreamController.close();
  }
}
