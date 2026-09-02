import 'package:dio/dio.dart';
import 'package:get/get.dart';
import '../../core/constants/api.dart';
import '../../core/utils/app_log.dart';
import '../local/hive_service.dart';

class ApiClient extends GetxService {
  late final Dio dio;
  bool signedOut = false;

  Future<ApiClient> init() async {
    dio = Dio(
      BaseOptions(
        baseUrl: _origin(),
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) {
          final origin = _origin();
          if (origin.isEmpty) {
            AppLog.error('API_BASE_URL missing before ${options.method} ${options.path}', tag: 'API');
            return handler.reject(
              DioException(
                requestOptions: options,
                type: DioExceptionType.unknown,
                error: 'API_BASE_URL is missing. Set it in assets/env.',
                message: 'API_BASE_URL is missing. Set it in assets/env.',
              ),
            );
          }
          options.baseUrl = origin;
          final token = Get.find<HiveService>().accessToken;
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          AppLog.info('${options.method} ${options.uri}', tag: 'API');
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLog.info(
            '${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
            tag: 'API',
          );
          handler.next(response);
        },
        onError: (error, handler) async {
          printDioError(error);
          _logDio(error);
          if (!signedOut && error.response?.statusCode == 401) {
            final refreshed = await _refresh();
            if (refreshed) {
              try {
                final retry = await dio.fetch(error.requestOptions);
                return handler.resolve(retry);
              } catch (e, stack) {
                AppLog.error('Retry after refresh failed', error: e, stack: stack, tag: 'API');
              }
            }
          }
          handler.next(error);
        },
      ),
    );
    return this;
  }

  static void printDioError(DioException error) {
    print('========== DIO ERROR ==========');
    print('URL: ${error.requestOptions.method} ${error.requestOptions.uri}');
    print('Type: ${error.type}');
    print('Status: ${error.response?.statusCode}');
    print('Message: ${error.message}');
    print('Response: ${error.response?.data}');
    print('Error: ${error.error}');
    print('===============================');
  }

  void _logDio(DioException error) {
    AppLog.error(
      '${error.requestOptions.method} ${error.requestOptions.uri} '
      'type=${error.type.name} status=${error.response?.statusCode} '
      'message=${error.message} body=${error.response?.data}',
      error: error,
      tag: 'API',
    );
  }

  String _origin() {
    final base = ApiConfig.resolved();
    if (base == null || base.isEmpty) return '';
    return '$base${ApiConfig.prefix}';
  }

  void applyBaseUrl(String baseUrl) {
    dio.options.baseUrl = '${ApiConfig.adjustForPlatform(baseUrl)}${ApiConfig.prefix}';
    AppLog.info('API base set to ${dio.options.baseUrl}', tag: 'API');
  }

  Future<bool> _refresh() async {
    final hive = Get.find<HiveService>();
    final refresh = hive.refreshToken;
    if (refresh == null) return false;
    try {
      final res = await Dio(BaseOptions(baseUrl: _origin())).post(
        '/auth/refresh',
        data: {'refreshToken': refresh},
      );
      final tokens = res.data['data']['tokens'] as Map<String, dynamic>;
      await hive.saveTokens(
        access: tokens['accessToken'] as String,
        refresh: tokens['refreshToken'] as String,
      );
      AppLog.info('Access token refreshed', tag: 'API');
      return true;
    } catch (e, stack) {
      AppLog.error('Token refresh failed', error: e, stack: stack, tag: 'API');
      return false;
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await dio.get(path, queryParameters: query);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      printDioError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    try {
      final res = await dio.post(path, data: data);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      printDioError(e);
      rethrow;
    }
  }
}
