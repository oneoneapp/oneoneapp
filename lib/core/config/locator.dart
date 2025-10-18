import 'package:get_it/get_it.dart';
import 'package:one_one/services/api_service.dart';
import 'package:one_one/services/auth_service.dart';
import 'package:one_one/services/fcm_service.dart';
export 'package:one_one/services/api_service.dart';
export 'package:one_one/services/auth_service.dart';

final GetIt loc = GetIt.instance;

void setupLocator() {
  loc.registerSingleton<ApiService>(ApiService());
  loc<ApiService>().init();
  loc.registerSingleton<FcmService>(FcmService());
  loc.registerSingleton<AuthService>(AuthService(apiService: loc(), fcmService: loc()));
  loc<AuthService>().init();
}