/// Card share image generation and platform sharing abstractions.
library;

import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:share_plus/share_plus.dart';

class CardShareException implements Exception {
  final String message;
  final Object? cause;

  const CardShareException(this.message, {this.cause});

  @override
  String toString() => 'CardShareException: $message (cause: $cause)';
}

abstract interface class CardShareGateway {
  Future<void> sharePng({
    required Uint8List bytes,
    required String fileName,
    required Rect sharePositionOrigin,
  });
}

class SharePlusCardShareGateway implements CardShareGateway {
  const SharePlusCardShareGateway();

  @override
  Future<void> sharePng({
    required Uint8List bytes,
    required String fileName,
    required Rect sharePositionOrigin,
  }) async {
    if (bytes.isEmpty) {
      throw const CardShareException('共有画像の生成結果が空です。');
    }
    if (sharePositionOrigin.isEmpty) {
      throw const CardShareException('共有メニューの表示位置を取得できませんでした。');
    }

    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png')],
        fileNameOverrides: [fileName],
        sharePositionOrigin: sharePositionOrigin,
      ),
    );
  }
}

abstract interface class CardShareImageRenderer {
  Future<Uint8List> render(GlobalKey boundaryKey, {double pixelRatio = 3.0});
}

class RepaintBoundaryCardShareImageRenderer implements CardShareImageRenderer {
  const RepaintBoundaryCardShareImageRenderer();

  @override
  Future<Uint8List> render(
    GlobalKey boundaryKey, {
    double pixelRatio = 3.0,
  }) async {
    if (pixelRatio <= 0) {
      throw const CardShareException('共有画像の解像度が不正です。');
    }

    final boundaryContext = boundaryKey.currentContext;
    final renderObject = boundaryContext?.findRenderObject();
    if (renderObject is! RenderRepaintBoundary) {
      throw const CardShareException('共有画像の描画領域を取得できませんでした。');
    }

    ui.Image? image;
    try {
      image = await renderObject.toImage(pixelRatio: pixelRatio);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        throw const CardShareException('共有画像をPNGへ変換できませんでした。');
      }
      return byteData.buffer.asUint8List();
    } catch (e) {
      if (e is CardShareException) rethrow;
      throw CardShareException('共有画像の生成に失敗しました。', cause: e);
    } finally {
      image?.dispose();
    }
  }
}
