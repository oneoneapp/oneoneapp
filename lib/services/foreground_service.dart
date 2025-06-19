import 'dart:isolate';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:one_one/services/socket_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(WalkieTalkieTaskHandler());
}

class WalkieTalkieTaskHandler extends TaskHandler {
  SocketHandler socketHandler = SocketHandler();

  @pragma('vm:entry-point')
  @override
  Future<void> onStart(DateTime timestamp, SendPort? sendPort) async {
    print('Foreground service started');
    socketHandler.initSocket();
  }

  @pragma('vm:entry-point')
  @override
  Future<void> onEvent(DateTime timestamp, SendPort? sendPort) async {
    // Check socket connection every interval
    if (socketHandler.socket?.disconnected == true) {
      print('Socket disconnected, attempting to reconnect...');
      socketHandler.socket?.connect();
    } else {
      print('Socket connection check: Connected');
    }
  }

  @pragma('vm:entry-point')
  @override
  Future<void> onDestroy(DateTime timestamp, SendPort? sendPort) async {
    // Even when service is destroyed, try to maintain socket
    socketHandler.initSocket();
  }
}