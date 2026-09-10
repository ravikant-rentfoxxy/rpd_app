import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart' hide FormData, MultipartFile;
import '../../core/constants/api.dart';
import '../../core/routes/app_routes.dart';
import '../../core/utils/app_log.dart';
import '../local/hive_service.dart';

class ApiClient extends GetxService {
  late final Dio dio;
  bool signedOut = false;
  Future<bool>? _refreshing;
  Future<void> Function()? onSessionExpired;

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
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          }
          if (!signedOut) {
            final token = Get.find<HiveService>().accessToken;
            if (token != null) {
              options.headers['Authorization'] = 'Bearer $token';
            }
          }
          AppLog.info('${options.method} ${options.uri}', tag: 'API');
          handler.next(options);
        },
        onResponse: (response, handler) {
          AppLog.info(
            '${response.statusCode} ${response.requestOptions.method} ${response.requestOptions.uri}',
            tag: 'API',
          );
          AppLog.info("Response: ${response.data}", tag: 'API');
          handler.next(response);
        },
        onError: (error, handler) async {
          final dropped = error.type == DioExceptionType.connectionError || error.type == DioExceptionType.connectionTimeout;
          if (dropped && error.requestOptions.extra['retriedConnection'] != true) {
            error.requestOptions.extra['retriedConnection'] = true;
            try {
              final retry = await dio.fetch(error.requestOptions);
              return handler.resolve(retry);
            } catch (_) {}
          }
          final path = error.requestOptions.path;
          final isAuthCall = path.contains('/auth/refresh') || path.contains('/auth/otp');
          final isAuthFailure = _isUnauthorized(error) && !isAuthCall;
          if (signedOut && isAuthFailure) {
            return handler.next(error);
          }
          if (!signedOut && isAuthFailure) {
            final refreshed = await _refresh();
            if (refreshed) {
              try {
                final retry = await dio.fetch(error.requestOptions);
                return handler.resolve(retry);
              } catch (e, stack) {
                AppLog.error('Retry after refresh failed', error: e, stack: stack, tag: 'API');
              }
            }
            return handler.next(error);
          }
          printDioError(error);
          _logDio(error);
          handler.next(error);
        },
      ),
    );
    return this;
  }

  static void printDioError(DioException error) {
    if (kDebugMode) {
      print('========== DIO ERROR ==========');
      print('URL: ${error.requestOptions.method} ${error.requestOptions.uri}');
      print('Type: ${error.type}');
      print('Status: ${error.response?.statusCode}');
      print('Message: ${error.message}');
      print('Response: ${error.response?.data}');
      print('Error: ${error.error}');
      print('===============================');
    }
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

  bool _isUnauthorized(DioException error) {
    if (error.response?.statusCode != 401) return false;
    final code = (error.response?.data as Map?)?['error'] is Map
        ? ((error.response?.data as Map)['error'] as Map)['code']?.toString()
        : null;
    return code != 'forbidden';
  }

  Future<bool> _refresh() async {
    if (signedOut) return false;
    if (_refreshing != null) return _refreshing!;
    _refreshing = _doRefresh();
    try {
      return await _refreshing!;
    } finally {
      _refreshing = null;
    }
  }

  Future<bool> _doRefresh() async {
    final hive = Get.find<HiveService>();
    final refresh = hive.refreshToken;
    if (refresh == null) {
      await expireSession();
      return false;
    }
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
    } catch (_) {
      AppLog.warn('Session expired, signing out', tag: 'API');
      await expireSession();
      return false;
    }
  }

  Future<void> expireSession() async {
    if (signedOut) return;
    signedOut = true;
    final hook = onSessionExpired;
    if (hook != null) {
      await hook();
      return;
    }
    await Get.find<HiveService>().clearSession();
    if (Get.currentRoute != Routes.mobile) {
      Get.offAllNamed(Routes.mobile);
    }
  }

  Future<Map<String, dynamic>> get(String path, {Map<String, dynamic>? query}) async {
    try {
      final res = await dio.get(path, queryParameters: query);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      if (!_isUnauthorized(e)) printDioError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> post(String path, {Object? data}) async {
    try {
      final res = await dio.post(path, data: data);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      if (!_isUnauthorized(e)) printDioError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> patch(String path, {Object? data}) async {
    try {
      final res = await dio.patch(path, data: data);
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      if (!_isUnauthorized(e)) printDioError(e);
      rethrow;
    }
  }

  Future<Map<String, dynamic>> postMultipart(String path, FormData data) async {
    try {
      final res = await dio.post(
        path,
        data: data,
        options: Options(
          sendTimeout: const Duration(minutes: 3),
          receiveTimeout: const Duration(minutes: 3),
        ),
      );
      return Map<String, dynamic>.from(res.data as Map);
    } on DioException catch (e) {
      if (!_isUnauthorized(e)) printDioError(e);
      rethrow;
    }
  }
}
