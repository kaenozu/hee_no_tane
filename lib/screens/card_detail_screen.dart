import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:hee_no_tane_app/models/card.dart';
import 'package:hee_no_tane_app/widgets/confidence_badge.dart';
import 'package:hee_no_tane_app/data/user_repository.dart';

class CardDetailScreen extends StatefulWidget {
  final HeeCard card;
  const CardDetailScreen({super.key, required this.card});

  @override
  State<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends State<CardDetailScreen> {
  late final UserRepository _userRepo;
  bool _isSaved = false;

  @override
  void initState() {
    super.initState();
    _userRepo = UserRepository();
    _checkSaved();
  }

  Future<void> _checkSaved() async {
    final saved = await _userRepo.isCardSaved(widget.card.id);
    if (mounted) {
      setState(() => _isSaved = saved);
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
            const SizedBox(height: 24),
            Text(
              '関連するへぇ',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            ...card.relatedCardIds.map((id) {
              return ListTile(
                title: Text(id.replaceFirst('card_', '').replaceAll('_', ' ')),
                trailing: const Icon(Icons.chevron_right),
              );
            }),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  showDialog(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text(card.quiz.question),
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            card.quiz.choices.length,
                            (index) => RadioListTile(
                              title: Text(card.quiz.choices[index]),
                              value: index,
                              groupValue: -1,
                              onChanged: (value) {},
                            ),
                          ),
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
                child: const Text('さっきのへぇ、覚えてる？'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
