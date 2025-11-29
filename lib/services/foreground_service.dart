import 'dart:async';
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
        eventAction: ForegroundTaskEventAction.repeat(10000),
        allowWakeLock: true,
      ),
    );
  }

  static void initCommunicationPort() {
    FlutterForegroundTask.initCommunicationPort();
  }

  static Future<void> requestPermissions() async {
    // Android 13+, you need to allow notification permission to display foreground service notification.
    final NotificationPermission notificationPermission = await FlutterForegroundTask.checkNotificationPermission();
    if (notificationPermission != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // Android 12+, there are restrictions on starting a foreground service.
      if (!(await FlutterForegroundTask.isIgnoringBatteryOptimizations)) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        await FlutterForegroundTask.openIgnoreBatteryOptimizationSettings();
      }
    }
  }

  static Future<ServiceRequestResult> startService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.stopService();
    }
    return FlutterForegroundTask.startService(
      serviceTypes: [
        ForegroundServiceTypes.mediaPlayback,
        ForegroundServiceTypes.microphone,
      ],
      serviceId: 256,
      notificationTitle: 'One One',
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

  static Future<ServiceRequestResult?> stopService() async {
    if (await FlutterForegroundTask.isRunningService) {
      return FlutterForegroundTask.stopService();
    } else {
      return null;
    }
  }
}

@pragma('vm:entry-point')
void startCallback() {
  FlutterForegroundTask.setTaskHandler(WalkieTalkieTaskHandler());
}

class WalkieTalkieTaskHandler extends TaskHandler {
  late WalkieTalkieProvider walkieTalkieProvider;
  late Timer? selfDestructTimer;
  static const Duration selfDestructDuration = Duration(minutes: 1);

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
    selfDestructTimer = Timer(selfDestructDuration, () async {
      logger.info('Self-destruct timer triggered. Stopping foreground service. initial');
      await FlutterForegroundTask.stopService();
    });
    walkieTalkieProvider.userSpeakingStream.listen((event) {
      if (event.speaking) {
        selfDestructTimer?.cancel();
        selfDestructTimer = null;
        logger.info('User started speaking. Self-destruct timer cancelled.');
      } else if (!event.speaking) {
        selfDestructTimer?.cancel();
        selfDestructTimer = Timer(selfDestructDuration, () async {
          logger.info('Self-destruct timer triggered after user stopped speaking. Stopping foreground service.');
          await FlutterForegroundTask.stopService();
        });
        logger.info('User stopped speaking. Self-destruct timer started.');
      }
    });
  }

  @override
  void onReceiveData(Object data) {
    logger.debug('onReceiveData: $data');
  }

  @pragma('vm:entry-point')
  @override
  void onRepeatEvent(DateTime timestamp) {}

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
    selfDestructTimer?.cancel();
    walkieTalkieProvider.dispose();
    logger.info('Foreground service destroyed');
  }
}