import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../config/raha_adsense_config.dart';
import '../errors/raha_adsense_exception.dart';
import '../models/models.dart';
import 'retry_policy.dart';

Dio buildRahaDio(RahaAdsenseConfig config) {
  final dio = Dio(
    BaseOptions(
      baseUrl: config.endpoints.apiOrigin.toString().replaceAll(
            RegExp(r'/+$'),
            '',
          ),
      connectTimeout: config.requestTimeout,
      sendTimeout: config.requestTimeout,
      receiveTimeout: config.requestTimeout,
      contentType: Headers.jsonContentType,
      responseType: ResponseType.plain,
      validateStatus: (_) => true,
      headers: const {'Accept': 'application/json'},
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onResponse: (response, handler) {
        if (kDebugMode &&
            config.enableDebugLogs &&
            !response.requestOptions.path.contains('/tracking/')) {
          debugPrint(
            '[Raha Adsense] ${response.requestOptions.method} '
            '${response.requestOptions.path.split('?').first}: '
            'HTTP ${response.statusCode}',
          );
        }
        handler.next(response);
      },
      onError: (error, handler) {
        final path = error.requestOptions.path;
        if (kDebugMode &&
            config.enableDebugLogs &&
            !path.contains('/tracking/')) {
          final status = error.response?.statusCode;
          final outcome = status == null
              ? _describeDioError(error)
              : 'HTTP $status';
          debugPrint(
            '[Raha Adsense] ${error.requestOptions.method} '
            '${error.requestOptions.uri.replace(query: '').toString()} '
            'failed: $outcome',
          );
        }
        handler.next(error);
      },
    ),
  );

  return dio;
}

final class RahaAdsenseApi {
  RahaAdsenseApi({required Dio dio}) : _dio = dio;

  final Dio _dio;

  Future<RahaInventoryResponse> fetchInventory({
    CancelToken? cancelToken,
  }) async {
    final response = await _guardNetwork(
      () => _dio.get<String>(
        '/api/v1/ad-requests/public/inventory',
        cancelToken: cancelToken,
      ),
    );
    _requireStatus(response, 200);
    final json = _decodeObject(
      response.data,
      maxBytes: 512 * 1024,
      label: 'inventory',
    );
    return RahaInventoryResponse.fromJson(json);
  }

  Future<RahaAdDecisionDto?> requestAd({
    required String placementId,
    required Map<String, Object?> signals,
    CancelToken? cancelToken,
  }) async {
    final body = validateAndNormalizePublisherSignals(signals);
    final encoded = jsonEncode(body);
    if (utf8.encode(encoded).length > 16 * 1024) {
      throw const RahaAdsException.invalidRequest(
        'Signals exceed the 16 KiB request limit.',
      );
    }

    final response = await _guardNetwork(
      () => withOneRetry<Response<String>>(
        () => _dio.post<String>(
          '/api/v1/ad-requests/request/${Uri.encodeComponent(placementId)}',
          data: encoded,
          cancelToken: cancelToken,
        ),
        cancelToken: cancelToken,
      ),
    );

    if (response.statusCode == 204) return null;
    _requireStatus(response, 200);

    final raw = response.data?.trim();
    if (raw == null || raw == 'null' || raw.isEmpty) return null;
    final json = _decodeObject(raw, maxBytes: 256 * 1024, label: 'ad decision');
    try {
      return RahaAdDecisionDto.fromJson(json);
    } on FormatException catch (error) {
      throw RahaAdsException(
        RahaAdsErrorCode.invalidResponse,
        'Invalid Raha ad decision response.',
        cause: error,
      );
    }
  }

  Future<RahaTrackingResult> trackImpression(
    Uri uri, {
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return _track(
      uri,
      eventId: eventId,
      expectedType: 'impression',
      cancelToken: cancelToken,
    );
  }

  Future<RahaTrackingResult> trackClick(
    Uri uri, {
    required String eventId,
    CancelToken? cancelToken,
  }) async {
    return _track(
      uri,
      eventId: eventId,
      expectedType: 'click',
      cancelToken: cancelToken,
    );
  }

  Future<RahaTrackingResult> _track(
    Uri uri, {
    required String eventId,
    required String expectedType,
    CancelToken? cancelToken,
  }) async {
    final trackedUri = _appendEventId(uri, eventId);
    final response = await _guardNetwork(
      () => withOneRetry<Response<String>>(
        () => _dio.getUri<String>(trackedUri, cancelToken: cancelToken),
        cancelToken: cancelToken,
      ),
    );
    if (response.statusCode == 204) {
      return RahaTrackingResult.normalized(
        json: const <String, Object?>{},
        eventId: eventId,
        type: expectedType,
      );
    }
    _requireStatus(response, 200);

    final raw = response.data?.trim();
    if (raw == null || raw.isEmpty) {
      return RahaTrackingResult.normalized(
        json: const <String, Object?>{},
        eventId: eventId,
        type: expectedType,
      );
    }

    try {
      return RahaTrackingResult.normalized(
        json: _decodeObject(raw, maxBytes: 64 * 1024, label: 'tracking'),
        eventId: eventId,
        type: expectedType,
      );
    } on RahaAdsException catch (error) {
      _logMalformedTracking(response, expectedType);
      throw error;
    } on FormatException catch (error) {
      _logMalformedTracking(response, expectedType);
      throw RahaAdsException(
        RahaAdsErrorCode.malformedResponse,
        'Malformed tracking response.',
        statusCode: response.statusCode,
        cause: error,
      );
    }
  }

  void dispose() => _dio.close(force: true);
}

Map<String, Object?> validateAndNormalizePublisherSignals(
  Map<String, Object?> signals,
) {
  const keyPattern = r'^[a-z][a-z0-9_]*$';
  final keyRegex = RegExp(keyPattern);
  if (signals.length > 32) {
    throw const RahaAdsException.invalidRequest(
      'At most 32 publisher signals are allowed.',
    );
  }

  final normalized = <String, Object?>{};
  for (final entry in signals.entries) {
    final key = entry.key.toLowerCase();
    if (!keyRegex.hasMatch(key)) {
      throw RahaAdsException.invalidRequest(
        'Signal keys must match $keyPattern.',
      );
    }
    if (normalized.containsKey(key)) {
      throw RahaAdsException.invalidRequest(
        'Duplicate signal key after lowercase normalization: $key.',
      );
    }
    normalized[key] = _validateSignalValue(entry.value);
  }
  return normalized;
}

Object? _validateSignalValue(Object? value) {
  if (value == null || value is String || value is bool) return value;
  if (value is num && value.isFinite) return value;
  if (value is List) {
    if (value.length > 32) {
      throw const RahaAdsException.invalidRequest(
        'Signal lists may contain at most 32 values.',
      );
    }
    return value.map(_validateSignalScalar).toList(growable: false);
  }
  throw const RahaAdsException.invalidRequest(
    'Signal values must be strings, finite numbers, booleans, null, or lists.',
  );
}

Object? _validateSignalScalar(Object? value) {
  if (value == null || value is String || value is bool) return value;
  if (value is num && value.isFinite) return value;
  throw const RahaAdsException.invalidRequest(
    'Signal list values must be scalar JSON values.',
  );
}

Map<String, Object?> _decodeObject(
  String? raw, {
  required int maxBytes,
  required String label,
}) {
  if (raw == null || utf8.encode(raw).length > maxBytes) {
    throw RahaAdsException(
      RahaAdsErrorCode.malformedResponse,
      'Malformed $label response.',
    );
  }
  final decoded = jsonDecode(raw);
  if (decoded is Map<String, Object?>) return decoded;
  if (decoded is Map) return decoded.cast<String, Object?>();
  throw RahaAdsException(
    RahaAdsErrorCode.malformedResponse,
    'Expected $label response to be a JSON object.',
  );
}

void _requireStatus(Response<dynamic> response, int statusCode) {
  if (response.statusCode == statusCode) return;
  final code = switch (response.statusCode) {
    401 || 403 => RahaAdsErrorCode.unauthorized,
    408 => RahaAdsErrorCode.timeout,
    429 => RahaAdsErrorCode.rateLimited,
    _ => RahaAdsErrorCode.network,
  };
  throw RahaAdsException(
    code,
    'Raha request failed with HTTP ${response.statusCode}.',
    statusCode: response.statusCode,
  );
}

Future<T> _guardNetwork<T>(Future<T> Function() action) async {
  try {
    return await action();
  } on RahaAdsException {
    rethrow;
  } on DioException catch (error) {
    final code = switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.sendTimeout ||
      DioExceptionType.receiveTimeout =>
        RahaAdsErrorCode.timeout,
      _ => RahaAdsErrorCode.network,
    };
    throw RahaAdsException(
      code,
      'Raha network request failed: ${_describeDioError(error)}.',
      cause: error,
    );
  } on FormatException catch (error) {
    throw RahaAdsException(
      RahaAdsErrorCode.invalidResponse,
      'Malformed Raha response.',
      cause: error,
    );
  }
}

String _describeDioError(DioException error) {
  final parts = <String>[error.type.name];
  final message = error.message;
  if (message != null && message.trim().isNotEmpty) {
    parts.add(message.trim());
  }
  final cause = error.error;
  if (cause != null) {
    parts.add(cause.toString());
  }
  return parts.join(' | ');
}

void _logMalformedTracking(Response<dynamic> response, String expectedType) {
  if (!kDebugMode) return;
  final contentType = response.headers.value(Headers.contentTypeHeader);
  debugPrint(
    '[Raha Adsense] tracking $expectedType response malformed: '
    'HTTP ${response.statusCode}, content-type ${contentType ?? 'unknown'}',
  );
}

Uri _appendEventId(Uri uri, String eventId) {
  final withoutFragment = uri.removeFragment().toString();
  final separator = uri.hasQuery ? '&' : '?';
  final fragment = uri.hasFragment ? '#${uri.fragment}' : '';
  return Uri.parse(
    '$withoutFragment${separator}eventId='
    '${Uri.encodeQueryComponent(eventId)}$fragment',
  );
}
