import '../errors/raha_adsense_exception.dart';
import '../models/models.dart';

final class PlacementRegistry {
  PlacementRegistry({required this.app});

  final RahaPublisherApp app;

  RahaPlacement resolveBanner(RahaBannerSize size) {
    final matches = app.placements
        .where(
          (placement) =>
              placement.format == RahaInventoryPlacementFormat.banner &&
              placement.size?.trim().toLowerCase() == size.wireValue,
        )
        .toList(growable: false);

    return _requireOne(matches, 'banner placement ${size.wireValue}');
  }

  RahaPlacement resolveVideo() {
    final matches = _formatMatches(RahaInventoryPlacementFormat.video);

    return _requireOne(matches, 'video placement');
  }

  RahaPlacement resolveInterstitial() {
    final matches = _formatMatches(RahaInventoryPlacementFormat.interstitial);

    return _requireOne(matches, 'interstitial placement');
  }

  RahaPlacement resolveNative() {
    final matches = _formatMatches(RahaInventoryPlacementFormat.native);

    return _requireOne(matches, 'native placement');
  }

  List<RahaPlacement> _formatMatches(RahaInventoryPlacementFormat format) {
    return app.placements
        .where((placement) => placement.format == format)
        .toList(growable: false);
  }

  RahaPlacement _requireOne(List<RahaPlacement> matches, String label) {
    if (matches.isEmpty) {
      throw RahaAdsException(
        RahaAdsErrorCode.placementNotFound,
        'No $label is configured for app ${app.id}.',
      );
    }
    if (matches.length > 1) {
      throw RahaAdsException(
        RahaAdsErrorCode.ambiguousPlacement,
        'Multiple $label values are configured for app ${app.id}.',
      );
    }
    return matches.single;
  }
}
