import 'package:dio/dio.dart';
import 'package:talker_dio_logger/talker_dio_logger_interceptor.dart';
import 'package:talker_dio_logger/talker_dio_logger_settings.dart';

class ApiService {
  late String baseUrl;
  final String baseUrlRemote = "https://api.oneoneapp.in/";
  final String baseUrlLocal = "http://192.168.1.242:5050/";
  final Dio dio = Dio();

  void init() {
    baseUrl = baseUrlRemote;
    dio.options.baseUrl = baseUrl;
    dio.options.headers['Content-Type'] = 'application/json';
    dio.options.validateStatus = (status) {
      return status != null && status >= 200 && status < 600;
    };
    dio.interceptors.add(
      TalkerDioLogger(
        settings: const TalkerDioLoggerSettings(
          printRequestHeaders: true,
          printResponseHeaders: true,
          printResponseMessage: true,
        ),
      ),
    );
  }

  Future<Response> get(
    String url,
    {
      Map<String, dynamic>? headers
    }
  ) async {
    return await dio.get(
      url,
      options: Options(
        headers: headers
      ),
    );
  }

  Future<Response> post(
    String url,
    {
      Map? body,
      Map<String, dynamic>? headers
    }
  ) async {
    return await dio.post(
      url,
      data: body,
      options: Options(
        headers: headers
      ),
    );
  }
}