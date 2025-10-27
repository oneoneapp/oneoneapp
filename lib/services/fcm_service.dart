import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/services/foreground_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.info("Handling a background message: ${message.messageId}");
  logger.debug(message.data.toString());
  ForegroundService.initService();
  final ServiceRequestResult result = await ForegroundService.startService(message.data["name"]);
  if (result is ServiceRequestSuccess) {
    logger.info("Foreground service started successfully from background message");
    ForegroundService.sendData(message.data);
  } else {
    logger.error("Failed to start foreground service from background message: $result");
  }
}

class FcmService {
  String? _fcmToken;

  Future<void> initialise() async {
    try {
      await FirebaseMessaging.instance.requestPermission();

      FirebaseMessaging.onMessage.listen((message) async {
        logger.info("Foreground message: ${message.data}");
        logger.debug(message);
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        logger.info("Message opened from background");
        logger.debug(message);
      });
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      final token = await FirebaseMessaging.instance.getToken();
      _fcmToken = token;
      logger.debug("FCM Token: $_fcmToken");
    } catch (e) {
      logger.error("Error setting up FCM: $e");
    }
  }

  Future<String?> getFcmToken() async {
    try {
      _fcmToken ??= await FirebaseMessaging.instance.getToken();
      return _fcmToken;
    } catch (e) {
      logger.error("Error retrieving FCM token: $e");
      return null;
    }
  }
}