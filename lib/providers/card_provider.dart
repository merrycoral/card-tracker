import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/card_model.dart';

final cardBoxProvider = Provider<Box<CardModel>>((ref) {
  return Hive.box<CardModel>('cards');
});

final cardsProvider = StateNotifierProvider<CardsNotifier, List<CardModel>>((ref) {
  final box = ref.watch(cardBoxProvider);
  return CardsNotifier(box);
});

class CardsNotifier extends StateNotifier<List<CardModel>> {
  final Box<CardModel> _box;

  CardsNotifier(this._box) : super(_box.values.toList());

  void addCard(CardModel card) {
    _box.put(card.id, card);
    state = _box.values.toList();
  }

  void updateCard(CardModel card) {
    _box.put(card.id, card);
    state = _box.values.toList();
  }

  void deleteCard(String id) {
    _box.delete(id);
    state = _box.values.toList();
  }

  CardModel? getCard(String id) {
    return _box.get(id);
  }
}
