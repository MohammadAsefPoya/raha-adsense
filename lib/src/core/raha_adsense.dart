import 'package:flutter/foundation.dart';

import '../config/raha_adsense_config.dart';
import '../errors/raha_adsense_exception.dart';
import '../models/ad_response.dart';
import '../models/models.dart';
import 'click_opener.dart';
import 'raha_adsense_runtime.dart';

abstract final class RahaAdsense {
  static RahaAdsenseRuntime? _runtime;

  static bool get isReady => _runtime != null;

  static Future<void> setup({
    required String appId,
    RahaClickOpener? clickOpener,
  }) async {
    if (_runtime != null) {
      throw StateError('RahaAdsense.setup() may be called only once.');
    }
    final runtime = RahaAdsenseRuntime(
      config: RahaAdsenseConfig.production(
        appId: appId,
        clickOpener: clickOpener,
      ),
    );
    try {
      await runtime.initialize();
      _runtime = runtime;
    } catch (_) {
      runtime.dispose();
      rethrow;
    }
  }

  static Future<RahaAdResponse?> adRequest({
    required RahaAdFormat type,
    RahaBannerSize? bannerSize,
    Map<String, Object?> signals = const <String, Object?>{},
  }) {
    final value = runtime;
    return switch (type) {
      RahaAdFormat.banner => bannerSize == null
          ? throw const RahaAdsException.invalidRequest(
              'bannerSize is required for a banner ad request.',
            )
          : value.requestBannerAd(size: bannerSize, signals: signals),
      RahaAdFormat.video => bannerSize != null
          ? throw const RahaAdsException.invalidRequest(
              'bannerSize must be omitted for a video ad request.',
            )
          : value.requestVideoAd(signals: signals),
      RahaAdFormat.interstitial => bannerSize != null
          ? throw const RahaAdsException.invalidRequest(
              'bannerSize must be omitted for an interstitial ad request.',
            )
          : value.requestInterstitialAd(signals: signals),
      RahaAdFormat.native => bannerSize != null
          ? throw const RahaAdsException.invalidRequest(
              'bannerSize must be omitted for a native ad request.',
            )
          : value.requestNativeAd(signals: signals),
    };
  }

  static RahaAdsenseRuntime get runtime {
    final value = _runtime;
    if (value == null) {
      throw const RahaAdsException(
        RahaAdsErrorCode.notInitialized,
        'Call and await RahaAdsense.setup() before requesting or building ads.',
      );
    }
    return value;
  }

  @visibleForTesting
  static void resetForTesting() {
    _runtime?.dispose();
    _runtime = null;
  }
}
