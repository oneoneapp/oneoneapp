import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/firebase_options.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';
export 'package:flutter_foreground_task/flutter_foreground_task.dart';

class ForegroundService {
  static void initService() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'foreground_service',
        channelName: 'Foreground Service',
        channelDescription: 'Handles background operations',
        channelImportance: NotificationChannelImportance.HIGH,
        priority: NotificationPriority.HIGH,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(2),
        allowWakeLock: true,
      ),
    );
  }

  static void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  static Future<void> requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    // iOS: If you need notification, ask for permission.
    final NotificationPermission notificationPermission =
        await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      // To restart the service on device reboot or unexpected problem, you need to allow below permission.
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        // This function requires `android.permission.REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` permission.
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
      }
    }
  }

  static Future<ServiceRequestResult> startService(String name) async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.stopService();
    }
    return FlutterForegroundTask.startService(
      serviceTypes: [
        ForegroundServiceTypes.mediaPlayback,
        ForegroundServiceTypes.microphone,
      ],
      serviceId: 256,
      notificationTitle: '$name wants to talk',
      notificationText: '',
      notificationButtons: [
        NotificationButton(id: 'stop', text: 'stop'),
      ],
      notificationInitialRoute: '/',
      callback: startCallback,
    );
  }

  static void sendData(Map<String, dynamic> data) {
    FlutterForegroundTask.sendDataToTask(data);
  }

  static Future<ServiceRequestResult> stopService() async {
    return FlutterForegroundTask.stopService();
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(WalkieTalkieTaskHandler());
}

class WalkieTalkieTaskHandler extends TaskHandler {
  late WalkieTalkieProvider walkieTalkieProvider;
  String? callerSocketId;

  @pragma('vm:entry-point')
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    logger.info('Foreground service starting');
    WidgetsFlutterBinding.ensureInitialized();
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    walkieTalkieProvider = WalkieTalkieProvider();
    await walkieTalkieProvider.initialize();
    logger.info('WalkieTalkieProvider initialized in foreground service');
  }

  @override
  void onReceiveData(Object data) {
    logger.debug('onReceiveData: $data');
    if (data is Map<String, dynamic>) {
      if (data["type"] == 'call') {
        callerSocketId = data['sender'];
        logger.debug('Incoming call from $callerSocketId');
        // walkieTalkieProvider.startCall(sender, audio: false);
      }
    }
  }

  @pragma('vm:entry-point')
  @override
  void onRepeatEvent(DateTime timestamp) {
    if (callerSocketId != null) {
      if (walkieTalkieProvider.isCallActive) {
        return;
      } else {
        if (walkieTalkieProvider.isConnected && walkieTalkieProvider.uniqueCode != '') {
          logger.info('Starting call with $callerSocketId from foreground service');
          walkieTalkieProvider.startCall(callerSocketId!);
        } else {
          logger.info('Socket not connected yet, cannot start call');
        }
      }
    } else {
      logger.info('No active call');
    }
  }

  @override
  void onNotificationButtonPressed(String id) {
    logger.info('Notification btn with id: ($id) pressed');
    if (id == 'stop') {
      FlutterForegroundTask.stopService();
    }
  }

  @pragma('vm:entry-point')
  @override
  Future<void> onDestroy(DateTime timestamp, bool isForeground) async {
    walkieTalkieProvider.dispose();
    logger.info('Foreground service destroyed');
  }
}