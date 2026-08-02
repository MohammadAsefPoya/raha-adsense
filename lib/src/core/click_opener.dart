import 'dart:async';

import '../models/models.dart';

typedef RahaClickOpener = FutureOr<void> Function(
  Uri destinationUrl,
  RahaAdInfo info,
);
