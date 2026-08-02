import 'dart:async';

import 'package:flutter/material.dart';
import 'package:visibility_detector/visibility_detector.dart';

import '../core/viewability_policy.dart';
import '../errors/raha_adsense_exception.dart';
import '../models/ad_response.dart';

abstract final class RahaInterstitialPresenter {
  static Future<void> show({
    required BuildContext context,
    required RahaInterstitialAdResponse ad,
  }) {
    if (!ad.markShownOnce()) {
      throw const RahaAdsException(
        RahaAdsErrorCode.invalidRequest,
        'This interstitial ad response has already been shown.',
      );
    }
    return Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        fullscreenDialog: true,
        builder: (_) => _RahaInterstitialRoute(ad: ad),
      ),
    );
  }
}

class _RahaInterstitialRoute extends StatefulWidget {
  const _RahaInterstitialRoute({required this.ad});

  final RahaInterstitialAdResponse ad;

  @override
  State<_RahaInterstitialRoute> createState() => _RahaInterstitialRouteState();
}

class _RahaInterstitialRouteState extends State<_RahaInterstitialRoute>
    with WidgetsBindingObserver {
  bool _foreground = true;
  bool _imageDecoded = false;
  bool _impressionRecorded = false;
  double _visibleFraction = 0;
  Timer? _impressionTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    _foreground = state == AppLifecycleState.resumed;
    _evaluateViewability();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _impressionTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = widget.ad;
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned.fill(
              child: VisibilityDetector(
                key: ValueKey(
                  'raha-interstitial-${ad.info.adId}-${ad.info.placementId}',
                ),
                onVisibilityChanged: (info) {
                  _visibleFraction = info.visibleFraction;
                  _evaluateViewability();
                },
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: ad.openClick,
                  child: Center(
                    child: AspectRatio(
                      aspectRatio: ad.width / ad.height,
                      child: Image.network(
                        ad.imageUrl.toString(),
                        fit: BoxFit.contain,
                        frameBuilder: (context, child, frame, sync) {
                          if (frame != null || sync) {
                            WidgetsBinding.instance.addPostFrameCallback((_) {
                              if (!mounted || _imageDecoded) return;
                              _imageDecoded = true;
                              _evaluateViewability();
                            });
                          }
                          return child;
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
            PositionedDirectional(
              top: 8,
              end: 8,
              child: IconButton.filled(
                tooltip: 'Close',
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _evaluateViewability() {
    if (_impressionRecorded) return;
    final qualified = _foreground &&
        _imageDecoded &&
        _visibleFraction >= bannerVisibleFraction;
    if (!qualified) {
      _impressionTimer?.cancel();
      _impressionTimer = null;
      return;
    }
    _impressionTimer ??= Timer(bannerVisibleDuration, _recordImpression);
  }

  Future<void> _recordImpression() async {
    if (_impressionRecorded) return;
    await widget.ad.recordImpression();
    if (!mounted) return;
    _impressionRecorded = true;
  }
}
