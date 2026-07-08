import 'package:flutter/material.dart';
import 'package:hee_no_tane_app/models/card.dart';
import 'package:hee_no_tane_app/models/deck.dart';
import 'package:hee_no_tane_app/widgets/card_tile.dart';
import 'package:hee_no_tane_app/data/deck_repository.dart';
import 'package:hee_no_tane_app/data/card_repository.dart';
import 'package:hee_no_tane_app/data/user_repository.dart';
import 'package:hee_no_tane_app/screens/card_detail_screen.dart';
import 'package:hee_no_tane_app/screens/saved_screen.dart';
import 'package:hee_no_tane_app/screens/mypage_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late final DeckRepository _deckRepo;
  late final CardRepository _cardRepo;
  late final UserRepository _userRepo;

  DailyDeck? _deck;
  Map<String, HeeCard> _cards = {};
  bool _isLoading = true;
  String _error = '';
  int _readCount = 0;

  @override
  void initState() {
    super.initState();
    _deckRepo = DeckRepository();
    _cardRepo = CardRepository();
    _userRepo = UserRepository();
    _loadTodayDeck();
  }

  Future<void> _loadTodayDeck() async {
    try {
      final today = DateTime.now();
      final dateStr =
          '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final deck = await _deckRepo.loadDailyDeck(dateStr);
      final allCards = await _cardRepo.loadAllCards();

      setState(() {
        _deck = deck;
        _cards = allCards;
        _isLoading = false;
      });

      final streak = await _userRepo.getStreakCurrent();
      setState(() => _readCount = streak);
    } catch (e) {
      setState(() => _error = '読み込みに失敗しました: $e');
    }
  }

  List<HeeCard> _todayCards() {
    if (_deck == null) return const <HeeCard>[];
    return _deck!.cardIds.map((id) => _cards[id]).whereType<HeeCard>().toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('へぇの種'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SavedScreen()),
              );
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MyPageScreen()),
              );
              setState(() {});
            },
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error.isNotEmpty) {
      return Center(child: Text(_error));
    }
    final todayCards = _todayCards();
    if (todayCards.isEmpty) {
      return const Center(
        child: Text('今日のカードがありません。\n後でもう一度確認してください。'),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: todayCards.length + 1,
      itemBuilder: (context, index) {
        if (index == todayCards.length) {
          return Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              '今日は $_readCount 枚読了',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodySmall,
            ),
          );
        }
        return HeeCardTile(
          card: todayCards[index],
          onTap: () async {
            await Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => CardDetailScreen(card: todayCards[index]),
              ),
            );
            final today = DateTime.now();
            final dateStr =
                '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
            await _userRepo.recordRead(dateStr);
            setState(() {});
          },
        );
      },
    );
  }
}
