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
      socket = IO.io('https://api.oneoneapp.in', <String, dynamic>{
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