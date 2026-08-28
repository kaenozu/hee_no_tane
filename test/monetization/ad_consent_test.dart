import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/monetization/ad_consent.dart';

void main() {
  test('consent info update times out when UMP never calls back', () async {
    final stopwatch = Stopwatch()..start();

    final result = await AdConsent.requestConsentInfoUpdateForTesting(
      (onSuccess, onError) {},
      timeout: const Duration(milliseconds: 20),
    );

    stopwatch.stop();
    expect(result, isFalse);
    expect(
      stopwatch.elapsed,
      greaterThanOrEqualTo(const Duration(milliseconds: 20)),
    );
  });

  test('late consent callbacks cannot complete the request twice', () async {
    late void Function() onSuccess;

    final result = AdConsent.requestConsentInfoUpdateForTesting((
      success,
      onError,
    ) {
      onSuccess = success;
    }, timeout: const Duration(milliseconds: 20));

    expect(await result, isFalse);
    onSuccess();
  });
}
