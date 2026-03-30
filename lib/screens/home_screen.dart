import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../providers/card_provider.dart';
import '../providers/performance_provider.dart';
import '../widgets/card_tile.dart';
import 'add_card_screen.dart';
import 'card_detail_screen.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardsProvider);
    final selectedMonth = ref.watch(selectedMonthProvider);
    final performancesNotifier = ref.read(performancesProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('카드 실적 관리'),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _MonthSelectorBar(
            selectedMonth: selectedMonth,
            onChanged: (dt) => ref.read(selectedMonthProvider.notifier).state = dt,
          ),
        ),
      ),
      body: cards.isEmpty
          ? _emptyState(context)
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: cards.length,
              itemBuilder: (context, index) {
                final card = cards[index];
                final performance = performancesNotifier.getPerformance(
                  card.id,
                  selectedMonth.year,
                  selectedMonth.month,
                );
                return CardTile(
                  card: card,
                  performance: performance,
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CardDetailScreen(card: card),
                    ),
                  ),
                  onDelete: () => _confirmDelete(context, ref, card.id, card.name),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddCardScreen()),
        ),
        icon: const Icon(Icons.add),
        label: const Text('카드 추가'),
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.credit_card, size: 72, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text(
            '등록된 카드가 없습니다',
            style: TextStyle(fontSize: 16, color: Colors.grey[500]),
          ),
          const SizedBox(height: 8),
          Text(
            '카드 추가 버튼을 눌러 시작하세요',
            style: TextStyle(fontSize: 13, color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    String cardId,
    String cardName,
  ) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('카드 삭제'),
        content: Text('$cardName 카드를 삭제하시겠습니까?\n관련 실적 데이터도 함께 삭제됩니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () {
              ref.read(cardsProvider.notifier).deleteCard(cardId);
              // Also delete all performances for this card
              final allPerfs = ref.read(performancesProvider);
              for (final p in allPerfs.where((p) => p.cardId == cardId)) {
                ref.read(performancesProvider.notifier)
                    .deletePerformance(p.cardId, p.year, p.month);
              }
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
  }
}

class _MonthSelectorBar extends StatelessWidget {
  final DateTime selectedMonth;
  final ValueChanged<DateTime> onChanged;

  const _MonthSelectorBar({
    required this.selectedMonth,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left, size: 20),
            padding: EdgeInsets.zero,
            onPressed: () => onChanged(
              DateTime(selectedMonth.year, selectedMonth.month - 1),
            ),
          ),
          Text(
            DateFormat('yyyy년 M월').format(selectedMonth),
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right, size: 20),
            padding: EdgeInsets.zero,
            onPressed: () => onChanged(
              DateTime(selectedMonth.year, selectedMonth.month + 1),
            ),
          ),
        ],
      ),
    );
  }
}
