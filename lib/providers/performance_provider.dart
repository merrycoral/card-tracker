import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/performance_model.dart';

final performanceBoxProvider = Provider<Box<PerformanceModel>>((ref) {
  return Hive.box<PerformanceModel>('performances');
});

final performancesProvider =
    StateNotifierProvider<PerformancesNotifier, List<PerformanceModel>>((ref) {
  final box = ref.watch(performanceBoxProvider);
  return PerformancesNotifier(box);
});

class PerformancesNotifier extends StateNotifier<List<PerformanceModel>> {
  final Box<PerformanceModel> _box;

  PerformancesNotifier(this._box) : super(_box.values.toList());

  void upsertPerformance(PerformanceModel performance) {
    final key = '${performance.cardId}_${performance.year}_${performance.month}';
    _box.put(key, performance);
    state = _box.values.toList();
  }

  void deletePerformance(String cardId, int year, int month) {
    final key = '${cardId}_${year}_${month}';
    _box.delete(key);
    state = _box.values.toList();
  }

  PerformanceModel? getPerformance(String cardId, int year, int month) {
    final key = '${cardId}_${year}_${month}';
    return _box.get(key);
  }

  List<PerformanceModel> getCardPerformances(String cardId) {
    return state.where((p) => p.cardId == cardId).toList()
      ..sort((a, b) {
        final aVal = a.year * 12 + a.month;
        final bVal = b.year * 12 + b.month;
        return aVal.compareTo(bVal);
      });
  }
}

// Selected month provider for filtering
final selectedMonthProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month);
});
