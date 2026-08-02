enum RahaAdsErrorCode {
  invalidConfiguration,
  notInitialized,
  inventory,
  placementNotFound,
  ambiguousPlacement,
  invalidRequest,
  timeout,
  network,
  rateLimited,
  unauthorized,
  malformedResponse,
  invalidResponse,
  unsupportedCreative,
  trackingRejected,
  clickLaunch,
  layout,
}

final class RahaAdsException implements Exception {
  const RahaAdsException(
    this.code,
    this.message, {
    this.statusCode,
    this.cause,
  });

  const RahaAdsException.invalidRequest(String message)
      : this(RahaAdsErrorCode.invalidRequest, message);

  final RahaAdsErrorCode code;
  final String message;
  final int? statusCode;
  final Object? cause;

  @override
  String toString() => 'RahaAdsException($code): $message';
}
