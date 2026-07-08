import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:hee_no_tane_app/domain/models/question.dart';
import 'package:hee_no_tane_app/domain/models/hee_card.dart';
import 'package:hee_no_tane_app/domain/models/enemy.dart';

void main() {
  group('Question JSON parse', () {
    test('parses valid JSON', () {
      final json = jsonDecode('''
        {
          "id": "q_test_001",
          "category": "nature_geography",
          "difficulty": "easy",
          "question": "test question?",
          "choices": ["A", "B", "C", "D"],
          "answerIndex": 0,
          "explanation": "test explanation",
          "relatedCardId": "card_test_001",
          "sourceNote": "test source",
          "verified": true
        }
      ''') as Map<String, dynamic>;

      final q = Question.fromJson(json);
      expect(q.id, 'q_test_001');
      expect(q.choices.length, 4);
      expect(q.answerIndex, 0);
      expect(q.verified, true);
    });

    test('handles missing fields gracefully', () {
      expect(() => Question.fromJson({} as Map<String, dynamic>), throwsA(anything));
    });
  });

  group('HeeCard JSON parse', () {
    test('parses valid JSON', () {
      final json = jsonDecode('''
        {
          "id": "card_test_001",
          "title": "Test Card",
          "category": "nature_geography",
          "shortText": "short",
          "detailText": "detail",
          "imageAsset": "assets/images/cards/test.png",
          "rarity": "normal",
          "sourceNote": "test"
        }
      ''') as Map<String, dynamic>;

      final card = HeeCard.fromJson(json);
      expect(card.id, 'card_test_001');
      expect(card.title, 'Test Card');
      expect(card.rarity, 'normal');
    });

    test('handles empty imageAsset', () {
      final json = jsonDecode('''
        {
          "id": "card_test_002",
          "title": "No Image",
          "category": "science",
          "shortText": "short",
          "detailText": "detail",
          "imageAsset": "",
          "rarity": "rare",
          "sourceNote": "test"
        }
      ''') as Map<String, dynamic>;

      final card = HeeCard.fromJson(json);
      expect(card.imageAsset, '');
      expect(card.rarity, 'rare');
    });
  });

  group('Enemy JSON parse', () {
    test('parses valid JSON', () {
      final json = jsonDecode('''
        {
          "id": "enemy_test_001",
          "name": "Test Slime",
          "type": "normal",
          "maxHp": 20,
          "attack": 8,
          "imageAsset": "assets/images/enemies/slime.png"
        }
      ''') as Map<String, dynamic>;

      final e = Enemy.fromJson(json);
      expect(e.id, 'enemy_test_001');
      expect(e.maxHp, 20);
      expect(e.attack, 8);
      expect(e.type, 'normal');
    });

    test('parses boss enemy', () {
      final json = jsonDecode('''
        {
          "id": "enemy_boss_001",
          "name": "Boss",
          "type": "boss",
          "maxHp": 48,
          "attack": 10,
          "imageAsset": ""
        }
      ''') as Map<String, dynamic>;

      final e = Enemy.fromJson(json);
      expect(e.type, 'boss');
      expect(e.maxHp, 48);
    });
  });
}
