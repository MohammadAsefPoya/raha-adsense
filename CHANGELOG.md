# Changelog

All notable changes to this package are documented in this file.

## [Unreleased]

- Prepare documentation and package metadata for pub.dev publication.
- Clarify README usage examples and changelog release history.

## [2.0.0] - 2026-08-04

### Added

- `RahaNativeAd` support for native ad rendering.
- `RahaInterstitialPresenter` to display interstitial ad responses.

### Changed

- Migrated ad decision parsing to a format-specific backend response.
- Removed assumptions about creative IDs, media URLs, and MIME types in public
  response handling.
- Maintained compatibility with Flutter SDK `3.24.0` and higher.

## [1.0.0] - Initial release

### Added

- Initial Raha Adsense Flutter SDK with setup, manual ad requests, banner ads,
  video ads, placement resolution, signal validation, URL validation, retry,
  and controlled impression/click tracking.
