import 'package:dio/dio.dart';

/// Execute a network action and retry once when retryable failures occur.
Future<T> withOneRetry<T>(
  Future<T> Function() action, {
  CancelToken? cancelToken,
}) async {
  try {
    final result = await action();
    if (result is Response && _retryStatus(result.statusCode)) {
      _throwForRetryableStatus(result);
    }
    return result;
  } on DioException catch (error) {
    if (!_shouldRetry(error, cancelToken)) rethrow;
  }

  final result = await action();
  return result;
}

bool _shouldRetry(DioException error, CancelToken? cancelToken) {
  if (CancelToken.isCancel(error) || cancelToken?.isCancelled == true) {
    return false;
  }
  return switch (error.type) {
    DioExceptionType.connectionTimeout ||
    DioExceptionType.sendTimeout ||
    DioExceptionType.receiveTimeout ||
    DioExceptionType.connectionError =>
      true,
    DioExceptionType.badResponse => _retryStatus(error.response?.statusCode),
    _ => false,
  };
}

bool _retryStatus(int? statusCode) {
  if (statusCode == null) return false;
  return statusCode == 408 || statusCode == 429 || statusCode >= 500;
}

Never _throwForRetryableStatus(Response<dynamic> response) {
  throw DioException.badResponse(
    statusCode: response.statusCode ?? 500,
    requestOptions: response.requestOptions,
    response: response,
  );
}
