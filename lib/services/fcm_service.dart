import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:one_one/core/config/locator.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/providers/home_provider.dart';
import 'package:one_one/services/foreground_service.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  logger.info("Handling a background message: ${message.messageId}");
  logger.debug(message.data.toString());
  if (message.data["type"] == "call") {
    logger.info("Background message for walkie talkie call received");
    ForegroundService.initService();
    final ServiceRequestResult result = await ForegroundService.startService();
    if (result is ServiceRequestSuccess) {
      logger.info("Foreground service started successfully from background message");
    } else {
      logger.error("Failed to start foreground service from background message: $result");
    }
    return;
  } else if (message.data["type"] == "FRIEND_REQUEST") {
    logger.info("Background message for friend request received. Updating friend requests from notification");
    loc<HomeProvider>().updateFriendRequestsFromNotification(message.data);
    return;
  } else if (message.data["type"] == "FRIEND_REQUEST_ACCEPTED") {
    logger.info("Background message for frnd request accepted. Updating frnds list from notification");
    loc<HomeProvider>().updateFriendsFromNotification(message.data);
  }
}

class FcmService {
  String? _fcmToken;

  Future<void> initialise() async {
    try {
      await FirebaseMessaging.instance.requestPermission();

      FirebaseMessaging.onMessage.listen((message) async {
        logger.info("Foreground message recieved");
        logger.debug("Message payload: ${message.data}");
        if (message.data["type"] == "FRIEND_REQUEST") {
          logger.info("Recieved frnd request. Updating frnd requests from notification");
          loc<HomeProvider>().updateFriendRequestsFromNotification(message.data);
        } else if (message.data["type"] == "FRIEND_REQUEST_ACCEPTED") {
          logger.info("Frnd request accepted. Updating frnds list from notification");
          loc<HomeProvider>().updateFriendsFromNotification(message.data);
        }
      });
      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        logger.info("Message opened from background");
        logger.debug("Message payload: ${message.data}");
      });
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

      FirebaseMessaging.instance.onTokenRefresh.listen((newToken) {
        logger.info('FCM Token Refreshed: $newToken');
        _fcmToken = newToken;
        loc<ApiService>().post(
          "user/fcm-token",
          body: {
            "fcmToken": newToken
          },
        );
      });

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