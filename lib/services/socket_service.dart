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
        'http://192.168.1.244:5050',
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