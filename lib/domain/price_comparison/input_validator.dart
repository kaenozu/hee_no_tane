/// lib/domain/price_comparison/input_validator.dart
///
/// 価格比較画面の文字列入力を正規化し、整数円・率・容量へ安全に変換する。
/// 全角数字やカンマを許容しつつ、不正値を計算エンジンへ渡さないために存在する。
///
/// 関連:
///   - models.dart
///   - ../../features/comparison/offer_input_card.dart
library;

import 'models.dart';

class InputValidationException implements Exception {
  final List<String> messages;

  const InputValidationException(this.messages);

  @override
  String toString() => messages.join('\n');
}

class InputValidator {
  static const int maxMoney = 999999999999;
  static const double maxQuantity = 999999999999.999999;

  const InputValidator._();

  static String normalizeNumberText(String value) {
    final buffer = StringBuffer();
    for (final rune in value.trim().runes) {
      if (rune >= 0xFF10 && rune <= 0xFF19) {
        buffer.writeCharCode(0x30 + rune - 0xFF10);
      } else {
        buffer.writeCharCode(rune);
      }
    }
    return buffer
        .toString()
        .replaceAll('，', ',')
        .replaceAll('．', '.')
        .replaceAll('％', '%')
        .replaceAll(RegExp(r'[\s,]'), '');
  }

  static int parseMoney(
    String value, {
    required String fieldName,
    bool required = true,
    bool allowZero = true,
  }) {
    final normalized = normalizeNumberText(value)
        .replaceAll('¥', '')
        .replaceAll('￥', '')
        .replaceAll('円', '');
    if (normalized.isEmpty) {
      if (!required) return 0;
      throw InputValidationException(<String>['$fieldNameを入力してください。']);
    }
    if (!RegExp(r'^\d+$').hasMatch(normalized)) {
      throw InputValidationException(<String>['$fieldNameは1円単位の整数で入力してください。']);
    }
    final result = int.tryParse(normalized);
    if (result == null) {
      throw InputValidationException(<String>['$fieldNameが大きすぎます。']);
    }
    if (!allowZero && result == 0) {
      throw InputValidationException(<String>['$fieldNameは1円以上で入力してください。']);
    }
    if (result > maxMoney) {
      throw InputValidationException(<String>['$fieldNameが大きすぎます。']);
    }
    return result;
  }

  static int? parseOptionalMoney(String value, {required String fieldName}) {
    if (normalizeNumberText(value).isEmpty) return null;
    return parseMoney(value, fieldName: fieldName);
  }

  static double parsePercent(
    String value, {
    required String fieldName,
    bool required = false,
  }) {
    final normalized = normalizeNumberText(value).replaceAll('%', '');
    if (normalized.isEmpty) {
      if (required) {
        throw InputValidationException(<String>['$fieldNameを入力してください。']);
      }
      return 0;
    }
    if (!RegExp(r'^\d+(?:\.\d{1,6})?$').hasMatch(normalized)) {
      throw InputValidationException(<String>['$fieldNameは小数6桁以内で入力してください。']);
    }
    final percent = double.tryParse(normalized);
    if (percent == null || !percent.isFinite || percent < 0 || percent > 100) {
      throw InputValidationException(<String>['$fieldNameは0〜100の範囲で入力してください。']);
    }
    return percent / 100;
  }

  static double? parseOptionalQuantity(
    String value, {
    required String fieldName,
  }) {
    final normalized = normalizeNumberText(value);
    if (normalized.isEmpty) return null;
    if (!RegExp(r'^\d+(?:\.\d{1,6})?$').hasMatch(normalized)) {
      throw InputValidationException(<String>['$fieldNameは小数6桁以内で入力してください。']);
    }
    final quantity = double.tryParse(normalized);
    if (quantity == null || !quantity.isFinite || quantity <= 0) {
      throw InputValidationException(<String>['$fieldNameは0より大きい数値で入力してください。']);
    }
    if (quantity > maxQuantity) {
      throw InputValidationException(<String>['$fieldNameが大きすぎます。']);
    }
    return quantity;
  }

  static void validateOffer(Offer offer) {
    final errors = <String>[];
    if (offer.id.trim().isEmpty) errors.add('商品IDが空です。');
    if (offer.id.length > 64) errors.add('商品IDは64文字以内にしてください。');
    if (offer.productName.trim().isEmpty) errors.add('商品名を入力してください。');
    if (offer.productName.length > 256) errors.add('商品名は256文字以内にしてください。');
    if (offer.storeName.trim().isEmpty) errors.add('店舗名を入力してください。');
    if (offer.storeName.length > 256) errors.add('店舗名は256文字以内にしてください。');
    if (offer.price <= 0) errors.add('価格は1円以上で入力してください。');
    if (offer.taxRate < 0 || offer.taxRate > 1) {
      errors.add('税率は0〜100%の範囲で入力してください。');
    }
    if (offer.percentageDiscount < 0 || offer.percentageDiscount > 1) {
      errors.add('割引率は0〜100%の範囲で入力してください。');
    }
    if (offer.pointRate < 0 || offer.pointRate > 1) {
      errors.add('ポイント率は0〜100%の範囲で入力してください。');
    }
    if (offer.fixedDiscount < 0 ||
        offer.couponDiscount < 0 ||
        offer.fixedPoints < 0 ||
        (offer.earnedPoints != null && offer.earnedPoints! < 0) ||
        (offer.shippingFee != null && offer.shippingFee! < 0)) {
      errors.add('値引・ポイント・送料は0以上にしてください。');
    }
    if (offer.quantity != null &&
        (offer.quantity!.value <= 0 || offer.quantity!.packageCount < 1)) {
      errors.add('容量と個数は0より大きい値にしてください。');
    }
    if (errors.isNotEmpty) throw InputValidationException(errors);
  }
}
