import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/services/socket_service.dart';

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(WalkieTalkieTaskHandler());
}

class WalkieTalkieTaskHandler extends TaskHandler {
  SocketHandler socketHandler = SocketHandler();

  @pragma('vm:entry-point')
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    logger.info('Foreground service started');
    socketHandler.initSocket();
  }

  @pragma('vm:entry-point')
  @override
  void onRepeatEvent(DateTime timestamp) {
    // Check socket connection every interval
    if (socketHandler.socket?.disconnected == true) {
      logger.info('Socket disconnected, attempting to reconnect...');
      socketHandler.socket?.connect();
    } else {
      logger.info('Socket connection check: Connected');
    }
  }

  @pragma('vm:entry-point')
  @override
  Future<void> onDestroy(DateTime timestamp, bool isForeground) async {
    // Even when service is destroyed, try to maintain socket
    socketHandler.initSocket();
  }
}