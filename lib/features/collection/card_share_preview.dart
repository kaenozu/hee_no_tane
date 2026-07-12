/// Shareable card image preview and export dialog.
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/features/collection/card_share_service.dart';
import 'package:hee_no_tane_app/features/collection/category_util.dart';

class CardSharePreview extends StatelessWidget {
  static const logicalSize = Size(360, 450);

  final HeeCard card;

  const CardSharePreview({super.key, required this.card});

  @override
  Widget build(BuildContext context) {
    final accent = categoryColor(card.category);
    final titleSize = card.title.length > 32
        ? 22.0
        : card.title.length > 20
        ? 26.0
        : 30.0;
    final shortTextSize = card.shortText.length > 90
        ? 16.0
        : card.shortText.length > 60
        ? 18.0
        : 21.0;

    return SizedBox(
      key: const ValueKey('card-share-preview'),
      width: logicalSize.width,
      height: logicalSize.height,
      child: Material(
        color: const Color(0xFFF8F5EC),
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                accent.withValues(alpha: 0.18),
                const Color(0xFFF8F5EC),
                Colors.white,
              ],
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(26, 24, 26, 22),
            child: DefaultTextStyle(
              style: const TextStyle(
                fontFamily: 'NotoSansJP',
                color: Color(0xFF17352F),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: accent,
                          borderRadius: BorderRadius.circular(11),
                        ),
                        child: const Icon(
                          Icons.eco_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'へぇの種',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.78),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: accent.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Text(
                          categoryLabel(card.category),
                          style: TextStyle(
                            color: accent,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  Center(
                    child: Container(
                      width: 66,
                      height: 66,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.78),
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: accent.withValues(alpha: 0.28),
                        ),
                      ),
                      child: Icon(
                        Icons.auto_stories_rounded,
                        size: 34,
                        color: accent,
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),
                  SizedBox(
                    height: 78,
                    child: Center(
                      child: Text(
                        card.title,
                        textAlign: TextAlign.center,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: titleSize,
                          height: 1.25,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  if (card.rarity == 'rare') ...[
                    const SizedBox(height: 6),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF0B8),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.auto_awesome,
                              size: 13,
                              color: Color(0xFF9A6B00),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'RARE',
                              style: TextStyle(
                                color: Color(0xFF9A6B00),
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 1.0,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 18),
                  Container(
                    height: 1,
                    color: accent.withValues(alpha: 0.2),
                  ),
                  const SizedBox(height: 18),
                  Expanded(
                    child: Center(
                      child: Text(
                        card.shortText,
                        textAlign: TextAlign.center,
                        maxLines: 6,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: shortTextSize,
                          height: 1.55,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.source_outlined,
                          size: 14,
                          color: accent,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            '出典: ${card.sourceNote}',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontSize: 10,
                              height: 1.35,
                              color: Color(0xFF536C66),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    '今日もひとつ賢くなりました',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      color: Color(0xFF536C66),
                      letterSpacing: 0.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class CardShareDialog extends StatefulWidget {
  final HeeCard card;
  final CardShareGateway shareGateway;
  final CardShareImageRenderer imageRenderer;

  const CardShareDialog({
    super.key,
    required this.card,
    required this.shareGateway,
    required this.imageRenderer,
  });

  @override
  State<CardShareDialog> createState() => _CardShareDialogState();
}

class _CardShareDialogState extends State<CardShareDialog> {
  final GlobalKey _boundaryKey = GlobalKey();
  final GlobalKey _shareButtonKey = GlobalKey();
  bool _sharing = false;

  Future<void> _share() async {
    if (_sharing) return;

    setState(() => _sharing = true);

    try {
      final bytes = await widget.imageRenderer.render(
        _boundaryKey,
        pixelRatio: 3.0,
      );

      final buttonContext = _shareButtonKey.currentContext;
      final renderObject = buttonContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) {
        throw const CardShareException('共有メニューの表示位置を取得できませんでした。');
      }
      final sharePositionOrigin =
          renderObject.localToGlobal(Offset.zero) & renderObject.size;

      await widget.shareGateway.sharePng(
        bytes: bytes,
        fileName: _fileNameFor(widget.card.id),
        sharePositionOrigin: sharePositionOrigin,
      );

      if (mounted) Navigator.of(context).pop();
    } catch (e, stackTrace) {
      debugPrint('Failed to share card image: $e');
      debugPrintStack(stackTrace: stackTrace);
      if (!mounted) return;
      setState(() => _sharing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('共有画像を作成できませんでした。もう一度お試しください。')),
      );
    }
  }

  String _fileNameFor(String id) {
    final safeId = id.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return 'hee_card_${safeId.isEmpty ? 'card' : safeId}.png';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_sharing,
      child: AlertDialog(
        title: const Text('共有画像を確認'),
        content: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: CardSharePreview.logicalSize.width,
            maxHeight: MediaQuery.sizeOf(context).height * 0.58,
          ),
          child: AspectRatio(
            aspectRatio:
                CardSharePreview.logicalSize.width /
                CardSharePreview.logicalSize.height,
            child: FittedBox(
              fit: BoxFit.contain,
              child: RepaintBoundary(
                key: _boundaryKey,
                child: CardSharePreview(card: widget.card),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _sharing ? null : () => Navigator.of(context).pop(),
            child: const Text('キャンセル'),
          ),
          FilledButton.icon(
            key: _shareButtonKey,
            onPressed: _sharing ? null : _share,
            icon: _sharing
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.ios_share_rounded),
            label: Text(_sharing ? '作成中...' : '共有する'),
          ),
        ],
      ),
    );
  }
}
