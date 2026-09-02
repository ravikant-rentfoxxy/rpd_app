import 'package:dio/dio.dart';
import '../constants/api.dart';

String apiErrorMessage(Object error) {
  final base = ApiConfig.resolved();
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final message = (data['error'] as Map)['message'];
      if (message is String && message.isNotEmpty) return message;
    }
    final fromError = error.error?.toString();
    if (fromError != null && fromError.contains('API_BASE_URL')) return fromError;
    if (error.message != null && error.message!.contains('API_BASE_URL')) {
      return error.message!;
    }
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.unknown) {
      return 'Could not reach ${base ?? 'the API'}. Set API_BASE_URL in assets/env and restart the app.';
    }
    return error.message ?? 'Request failed';
  }
  return error.toString();
}
