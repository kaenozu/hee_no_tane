/// test/domain/price_comparison/input_validator_test.dart
///
/// 全角数字・カンマ・率・容量の正規化と不正値拒否を検証する。
///
/// 関連:
///   - lib/domain/price_comparison/input_validator.dart
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/price_comparison/input_validator.dart';

void main() {
  test('全角数字とカンマと円記号を整数円へ変換する', () {
    expect(
      InputValidator.parseMoney('￥１，２３４円', fieldName: '価格'),
      1234,
    );
  });

  test('10%を0.10へ変換する', () {
    expect(
      InputValidator.parsePercent('１０％', fieldName: '割引率'),
      closeTo(0.10, 0.000001),
    );
  });

  test('小数円は拒否する', () {
    expect(
      () => InputValidator.parseMoney('398.5', fieldName: '価格'),
      throwsA(isA<InputValidationException>()),
    );
  });

  test('容量は小数6桁まで許可する', () {
    expect(
      InputValidator.parseOptionalQuantity('０．１２５', fieldName: '容量'),
      closeTo(0.125, 0.000001),
    );
  });
}
