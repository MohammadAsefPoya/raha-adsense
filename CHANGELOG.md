## 2.0.0

- Migrated ad decision parsing to the new format-specific backend response.
- Added public native and image-interstitial response types.
- Added `RahaNativeAd` and `RahaInterstitialPresenter`.
- Removed public/common response assumptions around creative IDs, media URLs,
  and MIME types.
- Keeps compatibility with Flutter SDK 3.24.0 and higher.

## 1.0.0

- Initial Raha Adsense Flutter SDK with setup, manual ad requests, banner ads,
  video ads, placement resolution, signal validation, URL validation, retry,
  and controlled impression/click tracking.
