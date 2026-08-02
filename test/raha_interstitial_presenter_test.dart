import 'package:flutter_test/flutter_test.dart';
import 'package:raha_adsense/raha_adsense.dart';

void main() {
  test('interstitial format is public', () {
    expect(RahaAdFormat.interstitial, isNotNull);
  });
}
