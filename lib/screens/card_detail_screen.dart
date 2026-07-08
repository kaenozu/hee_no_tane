import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hee_no_tane_app/models/card.dart';
import 'package:hee_no_tane_app/widgets/confidence_badge.dart';
import 'package:hee_no_tane_app/data/user_repository.dart';
import 'package:hee_no_tane_app/data/card_repository.dart';

final Map<String, IconData> _sourceIcons = {
  'official': Icons.account_balance_rounded,
  'academic': Icons.school_rounded,
  'wiki': Icons.menu_book_rounded,
  'news': Icons.newspaper_rounded,
  'website': Icons.language_rounded,
};

class CardDetailScreen extends StatefulWidget {
  final HeeCard card;
  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late final UserRepository _userRepo;
  late final CardRepository _cardRepo;
  bool _isSaved = false;
  int? _selectedAnswer;
  bool _answered = false;
  Map<String, HeeCard> _relatedCards = {};
  bool _showLongBody = false;

  @override
  void initState() {
    super.initState();
    _userRepo = UserRepository();
    _cardRepo = CardRepository();
    _checkSaved();
    _loadRelatedCards();
  }

  Future<void> _checkSaved() async {
    final saved = await _userRepo.isCardSaved(widget.card.id);
    if (mounted) setState(() => _isSaved = saved);
  }

  Future<void> _loadRelatedCards() async {
    final allCards = await _cardRepo.loadAllCards();
    if (mounted) {
      setState(() {
        _relatedCards = {
          for (final id in widget.card.relatedCardIds)
            if (allCards.containsKey(id)) id: allCards[id]!
        };
      });
    }
  }

  Future<void> _toggleSave() async {
    if (_isSaved) {
      await _userRepo.unsaveCard(widget.card.id);
    } else {
      await _userRepo.saveCard(widget.card.id);
    }
    setState(() => _isSaved = !_isSaved);
  }

  void _showQuiz() {
    setState(() {
      _selectedAnswer = null;
      _answered = false;
    });
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Row(
                children: [
                  Icon(Icons.quiz_rounded, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  const Expanded(child: Text('さっきのへぇ、覚えてる？', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600))),
                ],
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.card.quiz.question, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500, height: 1.4)),
                  const SizedBox(height: 16),
                  ...List.generate(widget.card.quiz.choices.length, (index) {
                    final isCorrect = index == widget.card.quiz.answerIndex;
                    Color? bgColor;
                    if (_answered) {
                      bgColor = isCorrect ? Colors.green.withValues(alpha: 0.1) : _selectedAnswer == index ? Colors.red.withValues(alpha: 0.1) : null;
                    }
                    return Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _answered && isCorrect ? Colors.green : _answered && _selectedAnswer == index ? Colors.red : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: InkWell(
                        onTap: _answered ? null : () {
                          setState(() => _selectedAnswer = index);
                          setDialogState(() {});
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                          child: Row(
                            children: [
                              Container(
                                width: 28, height: 28,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _selectedAnswer == index ? (_answered && isCorrect ? Colors.green : _answered ? Colors.red : Theme.of(context).colorScheme.primary) : Colors.grey[200],
                                ),
                                child: Center(child: Text('${index + 1}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _selectedAnswer == index ? Colors.white : Colors.grey[600]))),
                              ),
                              const SizedBox(width: 12),
                              Expanded(child: Text(widget.card.quiz.choices[index], style: const TextStyle(fontSize: 14))),
                              if (_answered && isCorrect) const Icon(Icons.check_circle, color: Colors.green, size: 20),
                              if (_answered && !isCorrect && _selectedAnswer == index) const Icon(Icons.cancel, color: Colors.red, size: 20),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                  if (_answered) ...[
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _selectedAnswer == widget.card.quiz.answerIndex ? Colors.green.withValues(alpha: 0.06) : Colors.red.withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(_selectedAnswer == widget.card.quiz.answerIndex ? Icons.emoji_events_rounded : Icons.sentiment_dissatisfied_rounded, size: 20, color: _selectedAnswer == widget.card.quiz.answerIndex ? Colors.green : Colors.red),
                          const SizedBox(width: 8),
                          Expanded(child: Text(widget.card.quiz.explanation, style: TextStyle(fontSize: 13, height: 1.4, color: Colors.grey[700]))),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
              actions: [
                if (!_answered)
                  TextButton(
                    onPressed: _selectedAnswer == null ? null : () {
                      setState(() => _answered = true);
                      setDialogState(() {});
                    },
                    style: TextButton.styleFrom(foregroundColor: Theme.of(context).colorScheme.primary),
                    child: const Text('回答する', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                if (_answered)
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('閉じる', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final card = widget.card;
    return Scaffold(
      appBar: AppBar(
        title: SizedBox(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('へぇ', style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary)),
              const Text('詳細'),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border, key: ValueKey(_isSaved)),
            ),
            onPressed: _toggleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(card.title, style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w700, height: 1.3)),
            const SizedBox(height: 12),
            Row(
              children: [
                ConfidenceBadge(level: card.confidenceLevel),
                const Spacer(),
              ],
            ),
            const SizedBox(height: 24),
            _sectionHeader(context, Icons.timer_outlined, '30秒でへぇ'),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(card.shortBody, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.7)),
            ),
            const SizedBox(height: 20),
            if (!_showLongBody)
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showLongBody = true),
                  icon: const Icon(Icons.expand_more_rounded),
                  label: const Text('もっと深掘りする'),
                  style: TextButton.styleFrom(foregroundColor: cs.primary),
                ),
              ),
            if (_showLongBody) ...[
              _sectionHeader(context, Icons.auto_stories_rounded, 'もっと深掘り'),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: cs.primary.withValues(alpha: 0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.primary.withValues(alpha: 0.1)),
                ),
                child: Text(card.longBody, style: Theme.of(context).textTheme.bodyLarge?.copyWith(height: 1.8)),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextButton.icon(
                  onPressed: () => setState(() => _showLongBody = false),
                  icon: const Icon(Icons.expand_less_rounded),
                  label: const Text('閉じる'),
                ),
              ),
            ],
            const SizedBox(height: 24),
            _sectionHeader(context, Icons.source_rounded, '出典'),
            const SizedBox(height: 8),
            ...card.sources.map((source) => _sourceCard(context, source)),
            if (_relatedCards.isNotEmpty) ...[
              const SizedBox(height: 24),
              _sectionHeader(context, Icons.link_rounded, '関連するへぇ'),
              const SizedBox(height: 8),
              ..._relatedCards.entries.map((entry) => _relatedCardTile(context, entry.value)),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _showQuiz,
                icon: const Icon(Icons.quiz_rounded),
                label: const Text('さっきのへぇ、覚えてる？'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(BuildContext context, IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 6),
        Text(text, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _sourceCard(BuildContext context, HeeCardSource source) {
    final style = Theme.of(context).textTheme;
    final typeIcon = _sourceIcons[source.sourceType] ?? Icons.language_rounded;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        onTap: () async {
          final uri = Uri.parse(source.url);
          if (await canLaunchUrl(uri)) await launchUrl(uri);
        },
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(typeIcon, size: 20, color: Colors.grey[500]),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(source.title, style: style.bodyMedium?.copyWith(fontWeight: FontWeight.w500)),
                    if (source.retrievedAt.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text('参照: ${source.retrievedAt}', style: style.bodySmall?.copyWith(color: Colors.grey[500])),
                    ],
                  ],
                ),
              ),
              Icon(Icons.open_in_new_rounded, size: 16, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _relatedCardTile(BuildContext context, HeeCard related) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
        leading: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(Icons.auto_stories_rounded, size: 20, color: Theme.of(context).colorScheme.primary),
        ),
        title: Text(related.title, style: const TextStyle(fontWeight: FontWeight.w500)),
        subtitle: Text(related.hook, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
        trailing: Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => CardDetailScreen(card: related)));
        },
      ),
    );
  }
}
