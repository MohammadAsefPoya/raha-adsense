import 'dart:async';

import '../models/models.dart';

/// Custom callback for opening ad click destinations.
///
/// The SDK tracks clicks internally and then provides the resolved destination
/// URL and ad metadata to the host app. Use a custom opener when the app needs
/// to handle navigation in a platform-specific shell or custom browser.
typedef RahaClickOpener = FutureOr<void> Function(
  Uri destinationUrl,
  RahaAdInfo info,
);
