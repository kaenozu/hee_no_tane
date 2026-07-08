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
      final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
      final deck = await _deckRepo.loadDailyDeck(dateStr);
      final allCards = await _cardRepo.loadAllCards();

      setState(() {
        _deck = deck;
        _cards = allCards;
        _isLoading = false;
      });

      final todayCount = await _userRepo.getTodayReadCount(dateStr);
      setState(() => _readCount = todayCount);
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
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('へぇ', style: TextStyle(fontWeight: FontWeight.w700, color: cs.primary)),
            const Text('の種'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.bookmark_border),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const SavedScreen()));
              setState(() {});
            },
          ),
          IconButton(
            icon: const Icon(Icons.person_outline),
            onPressed: () async {
              await Navigator.push(context, MaterialPageRoute(builder: (context) => const MyPageScreen()));
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
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.cloud_off_rounded, size: 48, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text('読み込めませんでした', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Text(_error, style: Theme.of(context).textTheme.bodySmall, textAlign: TextAlign.center),
            ],
          ),
        ),
      );
    }
    final todayCards = _todayCards();
    if (todayCards.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.library_books_outlined, size: 64, color: Colors.grey[300]),
              const SizedBox(height: 16),
              Text('今日のカードはまだないみたい', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Colors.grey[600])),
              const SizedBox(height: 8),
              Text('後でもう一度確認してみてね', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[400])),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: Row(
            children: [
              Icon(Icons.today_rounded, size: 18, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 6),
              Text('今日のへぇ', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const Spacer(),
              Text('${todayCards.length}枚', style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey[500])),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.only(bottom: 24),
            itemCount: todayCards.length + 1,
            itemBuilder: (context, index) {
              if (index == todayCards.length) {
                return _buildFooter();
              }
              return HeeCardTile(
                card: todayCards[index],
                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => CardDetailScreen(card: todayCards[index])),
                  );
                  final today = DateTime.now();
                  final dateStr = '${today.year}-${today.month.toString().padLeft(2, '0')}-${today.day.toString().padLeft(2, '0')}';
                  await _userRepo.recordRead(dateStr);
                  await _userRepo.recordCardReadToday(dateStr);
                  final todayCount = await _userRepo.getTodayReadCount(dateStr);
                  setState(() => _readCount = todayCount);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final cs = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.primary.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.auto_stories_rounded, size: 16, color: cs.primary),
          const SizedBox(width: 6),
          Text(
            '今日は $_readCount 枚読了',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}
