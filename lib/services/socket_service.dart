import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:flutter/foundation.dart';

class SocketHandler {
  static final SocketHandler _instance = SocketHandler._internal();
  IO.Socket? socket;
  
  factory SocketHandler() {
    return _instance;
  }

  SocketHandler._internal();

  void initSocket() {
    if (socket == null) {
      socket = IO.io('http://192.168.1.118:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': true,
        'forceNew': true,
        'reconnection': true,
        'reconnectionAttempts': 10000, // Increased reconnection attempts
      });
      socket!.connect();
    }
  }
}