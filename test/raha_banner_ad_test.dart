import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raha_adsense/src/models/models.dart';
import 'package:raha_adsense/src/widgets/raha_banner_ad.dart';

void main() {
  test('canRenderExactBanner accepts loose exact-compatible constraints', () {
    expect(
      canRenderExactBanner(
        const BoxConstraints(maxWidth: 400, maxHeight: 100),
        RahaBannerSize.mobile320x50,
      ),
      isTrue,
    );
  });

  test('canRenderExactBanner rejects tight stretched constraints', () {
    expect(
      canRenderExactBanner(
        const BoxConstraints.tightFor(width: 400, height: 50),
        RahaBannerSize.mobile320x50,
      ),
      isFalse,
    );
  });
}
