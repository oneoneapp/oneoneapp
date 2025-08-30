import 'package:get_it/get_it.dart';
import 'package:one_one/services/api_service.dart';
export 'package:one_one/services/api_service.dart';

final GetIt loc = GetIt.instance;

void setupLocator() {
  loc.registerSingleton(() => ApiService());
  loc<ApiService>().init();
}