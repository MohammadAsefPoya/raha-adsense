import 'package:flutter_test/flutter_test.dart';
import 'package:raha_adsense/src/errors/raha_adsense_exception.dart';
import 'package:raha_adsense/src/network/raha_adsense_api.dart';

void main() {
  test('normalizes signal keys and preserves scalar values', () {
    final result = validateAndNormalizePublisherSignals(
      const {'Genre': 'news', 'score': 1.5, 'live': true, 'tags': ['fa', null]},
    );

    expect(result, {
      'genre': 'news',
      'score': 1.5,
      'live': true,
      'tags': ['fa', null],
    });
  });

  test('rejects duplicate normalized signal keys', () {
    expect(
      () => validateAndNormalizePublisherSignals(
        const {'Genre': 'news', 'genre': 'sports'},
      ),
      throwsA(
        isA<RahaAdsException>().having(
          (error) => error.code,
          'code',
          RahaAdsErrorCode.invalidRequest,
        ),
      ),
    );
  });

  test('rejects unsupported signal values', () {
    expect(
      () => validateAndNormalizePublisherSignals(
        const {'genre': {'nested': true}},
      ),
      throwsA(isA<RahaAdsException>()),
    );
  });
}
