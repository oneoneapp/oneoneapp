import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:one_one/core/config/logging.dart';
import 'package:one_one/firebase_options.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';

class FcmService {
  String? _fcmToken;

  FcmService() {
    _setupFCM();
  }

  Future<void> _setupFCM() async {
    try {
      await FirebaseMessaging.instance.requestPermission();
      final token = await FirebaseMessaging.instance.getToken();
      _fcmToken = token;
      logger.debug("FCM Token: $_fcmToken");

      FirebaseMessaging.onMessage.listen((message) async {
        logger.info("Foreground message: ${message.data}");
        await connectToServer(message);
      });

      FirebaseMessaging.onMessageOpenedApp.listen((message) async {
        logger.info("Message opened from background");
        await connectToServer(message);
      });
      FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
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
  
  @pragma('vm:entry-point')
  static Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    logger.info("Handling a background message: ${message.messageId}");
    await connectToServer(message);
  }

  @pragma('vm:entry-point')
  static Future<void> connectToServer(RemoteMessage message) async {
    try {
      logger.info("Message: ${message.notification?.title}");

      if (message.notification?.body == null) {
        logger.info('No notification payload found.');
        return;
      }

      if (message.notification?.title == "c") {
        await WalkieTalkieProvider().startCall(message.notification!.body!); 
      } else if(message.notification?.title == "r") {
        // await WalkieTalkieProvider().autoAcceptCall();
      }
      else{
        WalkieTalkieProvider().setupSocketListeners();
      }

      logger.info('Connected to server');
    } catch (e) {
      logger.info('Error connecting to server: $e');
    }
  }
}