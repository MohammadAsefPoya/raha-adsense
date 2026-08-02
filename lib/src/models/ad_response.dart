import '../errors/raha_adsense_exception.dart';
import 'models.dart';

sealed class RahaAdResponse {
  RahaAdResponse._({
    required this.info,
    required this.isClickable,
    required Future<void> Function() recordImpression,
    required Future<void> Function() openClick,
  })  : _recordImpression = recordImpression,
        _openClick = openClick;

  final RahaAdInfo info;
  final bool isClickable;

  final Future<void> Function() _recordImpression;
  final Future<void> Function() _openClick;
  Future<void>? _impressionFuture;

  Future<void> recordImpression() {
    return _impressionFuture ??= Future<void>.sync(_recordImpression);
  }

  Future<void> openClick() async {
    if (!isClickable) {
      throw const RahaAdsException(
        RahaAdsErrorCode.clickLaunch,
        'This ad has no click destination.',
      );
    }
    await _openClick();
  }
}

final class RahaBannerAdResponse extends RahaAdResponse {
  RahaBannerAdResponse._({
    required super.info,
    required super.isClickable,
    required this.imageUrl,
    required this.width,
    required this.height,
    required super.recordImpression,
    required super.openClick,
  }) : super._();

  final Uri imageUrl;
  final int width;
  final int height;
}

final class RahaVideoAdResponse extends RahaAdResponse {
  RahaVideoAdResponse._({
    required super.info,
    required super.isClickable,
    required this.videoUrl,
    required this.posterUrl,
    required this.duration,
    required super.recordImpression,
    required super.openClick,
  }) : super._();

  final Uri videoUrl;
  final Uri? posterUrl;
  final Duration duration;
}

final class RahaInterstitialAdResponse extends RahaAdResponse {
  RahaInterstitialAdResponse._({
    required super.info,
    required super.isClickable,
    required this.imageUrl,
    required this.width,
    required this.height,
    required super.recordImpression,
    required super.openClick,
  }) : super._();

  final Uri imageUrl;
  final int width;
  final int height;

  bool _shown = false;

  bool markShownOnce() {
    if (_shown) return false;
    _shown = true;
    return true;
  }
}

final class RahaNativeAdResponse extends RahaAdResponse {
  RahaNativeAdResponse._({
    required super.info,
    required super.isClickable,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.iconUrl,
    required this.cta,
    required super.recordImpression,
    required super.openClick,
  }) : super._();

  final String title;
  final String? description;
  final Uri? imageUrl;
  final Uri? iconUrl;
  final String? cta;
}

RahaBannerAdResponse buildRahaBannerAdResponse({
  required RahaAdInfo info,
  required bool isClickable,
  required Uri imageUrl,
  required int width,
  required int height,
  required Future<void> Function() recordImpression,
  required Future<void> Function() openClick,
}) {
  return RahaBannerAdResponse._(
    info: info,
    isClickable: isClickable,
    imageUrl: imageUrl,
    width: width,
    height: height,
    recordImpression: recordImpression,
    openClick: openClick,
  );
}

RahaVideoAdResponse buildRahaVideoAdResponse({
  required RahaAdInfo info,
  required bool isClickable,
  required Uri videoUrl,
  required Uri? posterUrl,
  required Duration duration,
  required Future<void> Function() recordImpression,
  required Future<void> Function() openClick,
}) {
  return RahaVideoAdResponse._(
    info: info,
    isClickable: isClickable,
    videoUrl: videoUrl,
    posterUrl: posterUrl,
    duration: duration,
    recordImpression: recordImpression,
    openClick: openClick,
  );
}

RahaInterstitialAdResponse buildRahaInterstitialAdResponse({
  required RahaAdInfo info,
  required bool isClickable,
  required Uri imageUrl,
  required int width,
  required int height,
  required Future<void> Function() recordImpression,
  required Future<void> Function() openClick,
}) {
  return RahaInterstitialAdResponse._(
    info: info,
    isClickable: isClickable,
    imageUrl: imageUrl,
    width: width,
    height: height,
    recordImpression: recordImpression,
    openClick: openClick,
  );
}

RahaNativeAdResponse buildRahaNativeAdResponse({
  required RahaAdInfo info,
  required bool isClickable,
  required String title,
  required String? description,
  required Uri? imageUrl,
  required Uri? iconUrl,
  required String? cta,
  required Future<void> Function() recordImpression,
  required Future<void> Function() openClick,
}) {
  return RahaNativeAdResponse._(
    info: info,
    isClickable: isClickable,
    title: title,
    description: description,
    imageUrl: imageUrl,
    iconUrl: iconUrl,
    cta: cta,
    recordImpression: recordImpression,
    openClick: openClick,
  );
}
