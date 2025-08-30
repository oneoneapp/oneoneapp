import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:one_one/firebase_options.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  print("Handling a background message: ${message.messageId}");
  await connectToServer(message);
}

Future<void> connectToServer(RemoteMessage message) async {
  try {
    print("Message: ${message.notification?.title}");

    if (message.notification?.body == null) {
      print('No notification payload found.');
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

    print('Connected to server');
  } catch (e) {
    print('Error connecting to server: $e');
  }
}
