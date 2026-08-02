import 'package:flutter/foundation.dart';

import 'raha_adsense_endpoints.dart';

final class RahaAdsenseConfig {
  RahaAdsenseConfig.production({required this.appId})
      : endpoints = RahaAdsenseEndpoints.production,
        enableDebugLogs = kDebugMode,
        requestTimeout = const Duration(seconds: 9),
        inventoryTtl = const Duration(minutes: 5);

  @visibleForTesting
  const RahaAdsenseConfig.forTesting({
    required this.appId,
    required this.endpoints,
    this.enableDebugLogs = false,
    this.requestTimeout = const Duration(seconds: 9),
    this.inventoryTtl = const Duration(minutes: 5),
  });

  final String appId;
  final RahaAdsenseEndpoints endpoints;
  final bool enableDebugLogs;
  final Duration requestTimeout;
  final Duration inventoryTtl;
}
