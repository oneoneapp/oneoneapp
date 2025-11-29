import 'package:get_it/get_it.dart';
import 'package:one_one/providers/home_provider.dart';
import 'package:one_one/providers/walkie_talkie_provider.dart';
import 'package:one_one/services/api_service.dart';
import 'package:one_one/services/auth_service.dart';
import 'package:one_one/services/fcm_service.dart';
export 'package:one_one/services/api_service.dart';
export 'package:one_one/services/auth_service.dart';

final GetIt loc = GetIt.instance;

Future<void> setupLocator() async {
  loc.registerSingleton<ApiService>(ApiService());
  loc<ApiService>().init();
  loc.registerSingleton<FcmService>(FcmService());
  await loc<FcmService>().initialise();
  loc.registerSingleton<AuthService>(AuthService(apiService: loc(), fcmService: loc()));
  loc<AuthService>().init();
  loc.registerSingleton(WalkieTalkieProvider());
  loc.registerSingleton(HomeProvider(walkieTalkieProvider: loc()));
}