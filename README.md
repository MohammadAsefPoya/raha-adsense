# Raha Adsense

Flutter SDK for Raha banner and video advertising.

Compatible with Flutter SDK `3.24.0` and higher, using Dart `>=3.5.0 <4.0.0`.

```dart
await RahaAdsense.setup(appId: '743e8c4b-08e0-4152-877e-e035f7d92d9a');
```

```dart
const RahaBannerAd(
  size: RahaBannerSize.mobile320x50,
  signals: {'genre': 'news', 'language': 'fa'},
)
```

```dart
const RahaVideoAd(
  signals: {'genre': 'sports', 'playback_position': 'pre_roll'},
)
```

For STB or other custom shells, provide a global click opener during setup.
Raha still tracks the click first, then passes the tracked destination URL to
your opener:

```dart
await RahaAdsense.setup(
  appId: '743e8c4b-08e0-4152-877e-e035f7d92d9a',
  clickOpener: (destinationUrl, adInfo) async {
    await StbNativeBridge.openAdUrl(destinationUrl.toString());
  },
);
```

```dart
const RahaNativeAd(
  signals: {'genre': 'business', 'language': 'fa'},
)
```

```dart
final ad = await RahaAdsense.adRequest(
  type: RahaAdFormat.interstitial,
  signals: const {'screen': 'article_complete'},
);

if (ad is RahaInterstitialAdResponse && context.mounted) {
  await RahaInterstitialPresenter.show(context: context, ad: ad);
}
```

The publisher supplies only the Raha app ID and optional contextual signals.
API and CDN endpoints, timeouts, retry policy, logging, placement IDs, tracking
URLs, and viewability thresholds are owned by the package.

Version 2.0.0 expects the backend response shape with top-level `id`, `format`,
tracking URLs, optional `clickUrl`, and a format-specific `asset` object.
