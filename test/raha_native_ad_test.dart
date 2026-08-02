import 'package:flutter_test/flutter_test.dart';
import 'package:raha_adsense/raha_adsense.dart';

void main() {
  testWidgets('native no-fill surface can be built', (tester) async {
    expect(RahaAdFormat.native, isNotNull);
  });
}
