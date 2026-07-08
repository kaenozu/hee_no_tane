import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hee_no_tane_app/models/card.dart';
import 'package:hee_no_tane_app/widgets/confidence_badge.dart';
import 'package:hee_no_tane_app/data/user_repository.dart';
import 'package:hee_no_tane_app/data/card_repository.dart';

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
    if (mounted) {
      setState(() => _isSaved = saved);
    }
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
              title: Text(widget.card.quiz.question),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(
                  widget.card.quiz.choices.length,
                  (index) {
                    final isCorrect = index == widget.card.quiz.answerIndex;
                    Color? tileColor;
                    if (_answered) {
                      tileColor = isCorrect
                          ? Colors.green.withValues(alpha: 0.15)
                          : _selectedAnswer == index
                              ? Colors.red.withValues(alpha: 0.15)
                              : null;
                    }
                    return Container(
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      decoration: tileColor != null
                          ? BoxDecoration(
                              color: tileColor,
                              borderRadius: BorderRadius.circular(8),
                            )
                          : null,
                      child: RadioListTile<int>(
                        title: Text(widget.card.quiz.choices[index]),
                        value: index,
                        groupValue: _selectedAnswer,
                        onChanged: _answered
                            ? null
                            : (value) {
                                setState(() => _selectedAnswer = value);
                                setDialogState(() {});
                              },
                      ),
                    );
                  },
                ),
              ),
              actions: [
                if (!_answered)
                  TextButton(
                    onPressed: _selectedAnswer == null
                        ? null
                        : () {
                            setState(() => _answered = true);
                            setDialogState(() {});
                          },
                    child: const Text('回答する'),
                  ),
                if (_answered) ...[
                  Text(
                    _selectedAnswer == widget.card.quiz.answerIndex
                        ? '正解！'
                        : '不正解...',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: _selectedAnswer == widget.card.quiz.answerIndex
                          ? Colors.green
                          : Colors.red,
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('閉じる'),
                  ),
                ],
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Scaffold(
      appBar: AppBar(
        title: const Text('カード詳細'),
        actions: [
          IconButton(
            icon: Icon(_isSaved ? Icons.bookmark : Icons.bookmark_border),
            onPressed: _toggleSave,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              card.title,
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            ConfidenceBadge(level: card.confidenceLevel),
            const SizedBox(height: 16),
            Text(
              '30秒でへぇ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(card.shortBody),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (context) {
                    return AlertDialog(
                      title: const Text('もっと深掘り'),
                      content: SingleChildScrollView(
                        child: Text(card.longBody),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('閉じる'),
                        ),
                      ],
                    );
                  },
                );
              },
              icon: const Icon(Icons.expand_more),
              label: const Text('もっと深掘りする'),
            ),
            const SizedBox(height: 24),
            Text(
              '出典',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...card.sources.map((source) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: InkWell(
                  onTap: () async {
                    final uri = Uri.parse(source.url);
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    }
                  },
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          source.title,
                          style: TextStyle(color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      Icon(Icons.open_in_new, size: 16, color: Theme.of(context).colorScheme.primary),
                    ],
                  ),
                ),
              );
            }),
            if (_relatedCards.isNotEmpty) ...[
              const SizedBox(height: 24),
              Text(
                '関連するへぇ',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ..._relatedCards.entries.map((entry) {
                return ListTile(
                  title: Text(entry.value.title),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CardDetailScreen(card: entry.value),
                      ),
                    );
                  },
                );
              }),
            ],
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _showQuiz,
                child: const Text('さっきのへぇ、覚えてる？'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
