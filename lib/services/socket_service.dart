import 'package:one_one/core/config/locator.dart';
import 'package:socket_io_client/socket_io_client.dart';

class SocketHandler {
  static final SocketHandler _instance = SocketHandler._internal();
  Socket? socket;
  
  factory SocketHandler() {
    return _instance;
  }

  SocketHandler._internal();

  void initSocket() {
    if (socket == null) {
      socket = io(
        loc<ApiService>().baseUrl,
        {
          'transports': ['websocket'],
          'autoConnect': true,
          'forceNew': true,
          'reconnection': true,
          'reconnectionAttempts': 10000,
        }
      );
      socket!.connect();
    }
  }
}