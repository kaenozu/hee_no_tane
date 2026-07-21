/// lib/data/repositories/comparison_repository.dart
///
/// 価格比較履歴をschemaVersion付きJSONとしてSharedPreferencesへ保存・復元する。
/// クイズ本体のセーブデータと分離し、価格比較機能だけを安全に更新するために存在する。
///
/// 関連:
///   - save_repository.dart
///   - ../../domain/price_comparison/models.dart
///   - ../../features/comparison/comparison_result_screen.dart
library;

import 'dart:convert';

import 'package:hee_no_tane_app/data/repositories/save_repository.dart';
import 'package:hee_no_tane_app/domain/price_comparison/comparison_engine.dart';
import 'package:hee_no_tane_app/domain/price_comparison/models.dart';
import 'package:hee_no_tane_app/domain/price_comparison/pricing_calculator.dart';

class ComparisonLoadException implements Exception {
  final String message;
  final Object? cause;

  const ComparisonLoadException(this.message, {this.cause});
}

class ComparisonSaveException implements Exception {
  final String message;
  final Object? cause;

  const ComparisonSaveException(this.message, {this.cause});
}

class SavedComparison {
  final String id;
  final DateTime savedAt;
  final List<Offer> offers;
  final ComparisonResult result;

  const SavedComparison({
    required this.id,
    required this.savedAt,
    required this.offers,
    required this.result,
  });

  String get title => offers.map((offer) => offer.productName).join(' / ');
}

class ComparisonRepository {
  static const int schemaVersion = 1;
  static const String _key = 'hee_no_tane_price_comparisons';
  static const int _maxEntries = 20;

  final PreferenceStore _store;
  Future<void>? _operationTail;

  ComparisonRepository({PreferenceStore? store})
    : _store = store ?? SharedPreferencesAsyncStore();

  Future<List<SavedComparison>> loadAll() async {
    try {
      final raw = await _store.getString(_key);
      if (raw == null || raw.isEmpty) return const <SavedComparison>[];
      final decoded = jsonDecode(raw);
      if (decoded is! Map) throw const FormatException('root must be an object');
      final root = Map<String, dynamic>.from(decoded);
      if (root['schemaVersion'] != schemaVersion) {
        throw const FormatException('unsupported schemaVersion');
      }
      final entries = root['entries'];
      if (entries is! List) throw const FormatException('entries must be a list');
      return entries.map((entry) {
        if (entry is! Map) throw const FormatException('entry must be an object');
        return _decodeEntry(Map<String, dynamic>.from(entry));
      }).toList(growable: false);
    } catch (error) {
      throw ComparisonLoadException('比較履歴を読み込めませんでした。', cause: error);
    }
  }

  Future<SavedComparison> save(List<Offer> offers) {
    return _enqueue<SavedComparison>(() async {
      try {
        final current = await loadAll();
        final savedAt = DateTime.now().toUtc();
        final item = SavedComparison(
          id: savedAt.microsecondsSinceEpoch.toString(),
          savedAt: savedAt,
          offers: List<Offer>.unmodifiable(offers),
          result: _calculate(offers),
        );
        final next = <SavedComparison>[item, ...current].take(_maxEntries).toList();
        await _store.setString(
          _key,
          jsonEncode(<String, dynamic>{
            'schemaVersion': schemaVersion,
            'entries': next.map(_encodeEntry).toList(growable: false),
          }),
        );
        return item;
      } on ComparisonLoadException catch (error) {
        throw ComparisonSaveException(error.message, cause: error);
      } catch (error) {
        throw ComparisonSaveException('比較結果を保存できませんでした。', cause: error);
      }
    });
  }

  Future<void> clear() => _enqueue<void>(() async => _store.remove(_key));

  SavedComparison _decodeEntry(Map<String, dynamic> json) {
    final rawOffers = json['offers'];
    if (rawOffers is! List || rawOffers.length < 2 || rawOffers.length > 5) {
      throw const FormatException('offers must contain 2 to 5 items');
    }
    final offers = rawOffers.map((raw) {
      if (raw is! Map) throw const FormatException('offer must be an object');
      return _decodeOffer(Map<String, dynamic>.from(raw));
    }).toList(growable: false);
    return SavedComparison(
      id: json['id'] as String,
      savedAt: DateTime.parse(json['savedAt'] as String),
      offers: offers,
      result: _calculate(offers),
    );
  }

  Map<String, dynamic> _encodeEntry(SavedComparison item) => <String, dynamic>{
    'id': item.id,
    'savedAt': item.savedAt.toIso8601String(),
    'offers': item.offers.map(_encodeOffer).toList(growable: false),
  };

  Map<String, dynamic> _encodeOffer(Offer offer) => <String, dynamic>{
    'id': offer.id,
    'productName': offer.productName,
    'storeName': offer.storeName,
    'price': offer.price,
    'taxIncluded': offer.taxIncluded,
    'taxRate': offer.taxRate,
    'percentageDiscount': offer.percentageDiscount,
    'fixedDiscount': offer.fixedDiscount,
    'couponDiscount': offer.couponDiscount,
    'couponMinimumSubtotal': offer.couponMinimumSubtotal,
    'pointRate': offer.pointRate,
    'fixedPoints': offer.fixedPoints,
    'earnedPoints': offer.earnedPoints,
    'shippingFee': offer.shippingFee,
    if (offer.quantity != null)
      'quantity': <String, dynamic>{
        'value': offer.quantity!.value,
        'unit': offer.quantity!.unit.jsonValue,
        'packageCount': offer.quantity!.packageCount,
        'measureKind': offer.quantity!.measureKind.name,
      },
  };

  Offer _decodeOffer(Map<String, dynamic> json) {
    final quantityJson = json['quantity'];
    final quantity = quantityJson is Map
        ? _decodeQuantity(Map<String, dynamic>.from(quantityJson))
        : null;
    return Offer(
      id: json['id'] as String,
      productName: json['productName'] as String,
      storeName: json['storeName'] as String,
      price: json['price'] as int,
      taxIncluded: json['taxIncluded'] as bool,
      taxRate: (json['taxRate'] as num).toDouble(),
      quantity: quantity,
      percentageDiscount: (json['percentageDiscount'] as num?)?.toDouble() ?? 0,
      fixedDiscount: json['fixedDiscount'] as int? ?? 0,
      couponDiscount: json['couponDiscount'] as int? ?? 0,
      couponMinimumSubtotal: json['couponMinimumSubtotal'] as int?,
      pointRate: (json['pointRate'] as num?)?.toDouble() ?? 0,
      fixedPoints: json['fixedPoints'] as int? ?? 0,
      earnedPoints: json['earnedPoints'] as int?,
      shippingFee: json['shippingFee'] as int?,
    );
  }

  Quantity _decodeQuantity(Map<String, dynamic> json) => Quantity(
    value: (json['value'] as num).toDouble(),
    unit: unitFromJson(json['unit'] as String),
    packageCount: json['packageCount'] as int? ?? 1,
    measureKind: MeasureKind.values.byName(
      json['measureKind'] as String? ?? MeasureKind.item.name,
    ),
  );

  ComparisonResult _calculate(List<Offer> offers) => rankOffers(<String, PriceBreakdown>{
    for (final offer in offers)
      offer.id: calculatePrice(
        offer,
        context: PurchaseContext(shippingFee: offer.shippingFee),
      ),
  });

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final previous = _operationTail;
    final future = previous == null ? operation() : previous.then((_) => operation());
    final tail = future.then<void>((_) {}, onError: (Object _, StackTrace _) {});
    _operationTail = tail;
    tail.whenComplete(() {
      if (identical(_operationTail, tail)) _operationTail = null;
    });
    return future;
  }
}
