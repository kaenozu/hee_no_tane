import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/models/card.dart';
import 'package:hee_no_tane_app/widgets/card_tile.dart';
import 'package:hee_no_tane_app/data/card_repository.dart';
import 'package:hee_no_tane_app/data/user_repository.dart';
import 'package:hee_no_tane_app/screens/card_detail_screen.dart';

class SavedScreen extends StatefulWidget {
  const SavedScreen({super.key});

  @override
  State<SavedScreen> createState() => _SavedScreenState();
}

class _SavedScreenState extends State<SavedScreen> {
  late final UserRepository _userRepo;
  late final CardRepository _cardRepo;
  List<String> _savedIds = [];
  Map<String, HeeCard> _cards = {};

  @override
  void initState() {
    super.initState();
    _userRepo = UserRepository();
    _cardRepo = CardRepository();
    _loadSaved();
  }

  Future<void> _loadSaved() async {
    final saved = await _userRepo.getSavedCardIds();
    final allCards = await _cardRepo.loadAllCards();
    setState(() {
      _savedIds = saved;
      _cards = allCards;
    });
  }

  @override
  Widget build(BuildContext context) {
    final savedCards = _savedIds.map((id) => _cards[id]).whereType<HeeCard>().toList();
    return Scaffold(
      appBar: AppBar(title: const Text('保存したへぇ')),
      body: savedCards.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey[300]),
                    const SizedBox(height: 16),
                    Text('保存したカードはまだないよ', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[500])),
                    const SizedBox(height: 8),
                    Text('気に入ったへぇを保存してみてね', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400])),
                  ],
                ),
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: savedCards.length,
              itemBuilder: (context, index) {
                return HeeCardTile(
                  card: savedCards[index],
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => CardDetailScreen(card: savedCards[index])),
                    );
                    setState(() {});
                  },
                );
              },
            ),
    );
  }
}
