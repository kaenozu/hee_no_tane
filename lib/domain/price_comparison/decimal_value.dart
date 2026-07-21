/// lib/domain/price_comparison/decimal_value.dart
///
/// 価格計算で利用する、外部依存のない固定小数値。
/// Python の Decimal と同じく10進数を正確に保持し、指定規則で丸める。
library;

enum MoneyRounding { halfUp, down, up }

final class DecimalValue implements Comparable<DecimalValue> {
  final BigInt _coefficient;
  final int scale;

  DecimalValue._(BigInt coefficient, this.scale)
    : assert(scale >= 0),
      _coefficient = coefficient;

  factory DecimalValue.parse(String source) {
    final value = source.trim();
    if (!RegExp(r'^[+-]?(?:\d+(?:\.\d*)?|\.\d+)$').hasMatch(value)) {
      throw FormatException('Invalid decimal value: $source');
    }

    final negative = value.startsWith('-');
    final unsigned = value.startsWith('-') || value.startsWith('+')
        ? value.substring(1)
        : value;
    final parts = unsigned.split('.');
    final integerPart = parts.first.isEmpty ? '0' : parts.first;
    final fractionPart = parts.length == 2 ? parts[1] : '';
    final digits = '$integerPart$fractionPart';
    var coefficient = BigInt.parse(digits.isEmpty ? '0' : digits);
    if (negative) coefficient = -coefficient;
    return DecimalValue._normalized(coefficient, fractionPart.length);
  }

  factory DecimalValue.fromInt(int value) =>
      DecimalValue._(BigInt.from(value), 0);

  factory DecimalValue._normalized(BigInt coefficient, int scale) {
    if (coefficient == BigInt.zero) return DecimalValue._(BigInt.zero, 0);
    var normalizedCoefficient = coefficient;
    var normalizedScale = scale;
    while (normalizedScale > 0 &&
        normalizedCoefficient.remainder(BigInt.from(10)) == BigInt.zero) {
      normalizedCoefficient ~/= BigInt.from(10);
      normalizedScale--;
    }
    return DecimalValue._(normalizedCoefficient, normalizedScale);
  }

  static final DecimalValue zero = DecimalValue.fromInt(0);
  static final DecimalValue one = DecimalValue.fromInt(1);
  static final DecimalValue hundred = DecimalValue.fromInt(100);

  bool get isZero => _coefficient == BigInt.zero;
  bool get isNegative => _coefficient.isNegative;
  bool get isPositive => _coefficient > BigInt.zero;

  DecimalValue get abs =>
      isNegative ? DecimalValue._normalized(-_coefficient, scale) : this;

  DecimalValue operator +(DecimalValue other) {
    final commonScale = scale > other.scale ? scale : other.scale;
    final left = _coefficient * _pow10(commonScale - scale);
    final right = other._coefficient * _pow10(commonScale - other.scale);
    return DecimalValue._normalized(left + right, commonScale);
  }

  DecimalValue operator -(DecimalValue other) {
    final commonScale = scale > other.scale ? scale : other.scale;
    final left = _coefficient * _pow10(commonScale - scale);
    final right = other._coefficient * _pow10(commonScale - other.scale);
    return DecimalValue._normalized(left - right, commonScale);
  }

  DecimalValue operator -() => DecimalValue._normalized(-_coefficient, scale);

  DecimalValue operator *(DecimalValue other) => DecimalValue._normalized(
    _coefficient * other._coefficient,
    scale + other.scale,
  );

  DecimalValue divide(
    DecimalValue other, {
    int resultScale = 12,
    MoneyRounding rounding = MoneyRounding.halfUp,
  }) {
    if (other.isZero) throw IntegerDivisionByZeroException();
    if (resultScale < 0) {
      throw ArgumentError.value(resultScale, 'resultScale', 'must be >= 0');
    }

    final exponent = other.scale + resultScale - scale;
    final numerator = exponent >= 0
        ? _coefficient * _pow10(exponent)
        : _coefficient;
    final denominator = exponent >= 0
        ? other._coefficient
        : other._coefficient * _pow10(-exponent);
    final quotient = _divideRounded(numerator, denominator, rounding);
    return DecimalValue._normalized(quotient, resultScale);
  }

  DecimalValue quantize(
    int targetScale, {
    MoneyRounding rounding = MoneyRounding.halfUp,
  }) {
    if (targetScale < 0) {
      throw ArgumentError.value(targetScale, 'targetScale', 'must be >= 0');
    }
    if (targetScale >= scale) return this;

    final divisor = _pow10(scale - targetScale);
    final rounded = _divideRounded(_coefficient, divisor, rounding);
    return DecimalValue._normalized(rounded, targetScale);
  }

  int toInt({MoneyRounding rounding = MoneyRounding.down}) {
    final rounded = quantize(0, rounding: rounding);
    return rounded._coefficient.toInt();
  }

  String toFixed(
    int fractionDigits, {
    MoneyRounding rounding = MoneyRounding.halfUp,
  }) {
    final rounded = quantize(fractionDigits, rounding: rounding);
    final negative = rounded._coefficient.isNegative;
    final digits = rounded._coefficient.abs().toString().padLeft(
      fractionDigits + 1,
      '0',
    );
    final prefix = negative ? '-' : '';
    if (fractionDigits == 0) return '$prefix$digits';
    final split = digits.length - fractionDigits;
    return '$prefix${digits.substring(0, split)}.${digits.substring(split)}';
  }

  @override
  int compareTo(DecimalValue other) {
    final commonScale = scale > other.scale ? scale : other.scale;
    final left = _coefficient * _pow10(commonScale - scale);
    final right = other._coefficient * _pow10(commonScale - other.scale);
    return left.compareTo(right);
  }

  bool operator <(DecimalValue other) => compareTo(other) < 0;
  bool operator <=(DecimalValue other) => compareTo(other) <= 0;
  bool operator >(DecimalValue other) => compareTo(other) > 0;
  bool operator >=(DecimalValue other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DecimalValue && compareTo(other) == 0;

  @override
  int get hashCode {
    final normalized = DecimalValue._normalized(_coefficient, scale);
    return Object.hash(normalized._coefficient, normalized.scale);
  }

  @override
  String toString() {
    final negative = _coefficient.isNegative;
    final digits = _coefficient.abs().toString().padLeft(scale + 1, '0');
    final prefix = negative ? '-' : '';
    if (scale == 0) return '$prefix$digits';
    final split = digits.length - scale;
    return '$prefix${digits.substring(0, split)}.${digits.substring(split)}';
  }

  static BigInt _divideRounded(
    BigInt numerator,
    BigInt denominator,
    MoneyRounding rounding,
  ) {
    if (denominator == BigInt.zero) throw IntegerDivisionByZeroException();

    final negative = numerator.isNegative != denominator.isNegative;
    final absoluteNumerator = numerator.abs();
    final absoluteDenominator = denominator.abs();
    var quotient = absoluteNumerator ~/ absoluteDenominator;
    final remainder = absoluteNumerator.remainder(absoluteDenominator);

    final increment = switch (rounding) {
      MoneyRounding.down => false,
      MoneyRounding.up => remainder != BigInt.zero,
      MoneyRounding.halfUp => remainder * BigInt.from(2) >= absoluteDenominator,
    };
    if (increment) quotient += BigInt.one;
    return negative ? -quotient : quotient;
  }

  static BigInt _pow10(int exponent) {
    if (exponent < 0) {
      throw ArgumentError.value(exponent, 'exponent', 'must be >= 0');
    }
    return BigInt.from(10).pow(exponent);
  }
}
