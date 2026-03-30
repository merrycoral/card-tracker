import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/card_model.dart';
import '../models/performance_model.dart';
import '../providers/performance_provider.dart';
import '../services/notification_service.dart';
import '../widgets/performance_chart.dart';
import 'add_card_screen.dart';

class CardDetailScreen extends ConsumerStatefulWidget {
  final CardModel card;

  const CardDetailScreen({super.key, required this.card});

  @override
  ConsumerState<CardDetailScreen> createState() => _CardDetailScreenState();
}

class _CardDetailScreenState extends ConsumerState<CardDetailScreen> {
  late DateTime _selectedMonth;
  final _amountCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonth = DateTime(now.year, now.month);
    _loadCurrentMonthAmount();
  }

  void _loadCurrentMonthAmount() {
    final p = ref.read(performancesProvider.notifier).getPerformance(
          widget.card.id,
          _selectedMonth.year,
          _selectedMonth.month,
        );
    _amountCtrl.text = p != null ? p.usedAmount.toStringAsFixed(0) : '';
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    super.dispose();
  }

  void _savePerformance() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    if (amount == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('올바른 금액을 입력하세요')),
      );
      return;
    }

    final performance = PerformanceModel(
      id: const Uuid().v4(),
      cardId: widget.card.id,
      year: _selectedMonth.year,
      month: _selectedMonth.month,
      usedAmount: amount,
    );

    ref.read(performancesProvider.notifier).upsertPerformance(performance);

    final rate = widget.card.targetAmount > 0
        ? (amount / widget.card.targetAmount * 100)
        : 0.0;

    if (rate >= widget.card.alertThreshold) {
      await NotificationService().showAchievementNotification(
        card: widget.card,
        achievementRate: rate,
      );
    }

    if (mounted) {
      FocusScope.of(context).unfocus();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${_selectedMonth.month}월 실적이 저장되었습니다.')),
      );
    }
  }

  void _changeMonth(int delta) {
    setState(() {
      _selectedMonth = DateTime(
        _selectedMonth.year,
        _selectedMonth.month + delta,
      );
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadCurrentMonthAmount());
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    final color = Color(card.colorValue);
    final performances = ref.watch(performancesProvider.notifier).getCardPerformances(card.id);
    final currentPerf = ref.watch(performancesProvider.notifier).getPerformance(
          card.id,
          _selectedMonth.year,
          _selectedMonth.month,
        );

    final usedAmount = currentPerf?.usedAmount ?? 0.0;
    final rate = card.targetAmount > 0
        ? (usedAmount / card.targetAmount * 100).clamp(0.0, 100.0)
        : 0.0;
    final isAchieved = rate >= 100;

    return Scaffold(
      appBar: AppBar(
        title: Text(card.name),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddCardScreen(existingCard: card),
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCardHeader(card, color),
          const SizedBox(height: 20),
          _buildMonthSelector(),
          const SizedBox(height: 16),
          _buildPerformanceInput(rate, isAchieved, color),
          const SizedBox(height: 24),
          if (performances.length > 1) ...[
            const Text(
              '월별 달성률 추이',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 200,
              child: PerformanceChart(
                performances: performances,
                targetAmount: card.targetAmount,
                cardColor: color,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCardHeader(CardModel card, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 38,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(card.company,
                      style: TextStyle(fontSize: 13, color: Colors.grey[600])),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _infoChip('월 목표', _formatAmount(card.targetAmount)),
              _infoChip('알림 임계값', '${card.alertThreshold.toStringAsFixed(0)}%'),
            ],
          ),
          if (card.benefit.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(card.benefit,
                style: TextStyle(fontSize: 13, color: Colors.grey[700])),
          ],
        ],
      ),
    );
  }

  Widget _infoChip(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey[600])),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
      ],
    );
  }

  Widget _buildMonthSelector() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => _changeMonth(-1),
        ),
        Text(
          DateFormat('yyyy년 M월').format(_selectedMonth),
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => _changeMonth(1),
        ),
      ],
    );
  }

  Widget _buildPerformanceInput(double rate, bool isAchieved, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('실적 입력',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: _amountCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  hintText: '사용 금액 (원)',
                  suffixText: '원',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
              ),
            ),
            const SizedBox(width: 10),
            ElevatedButton(
              onPressed: _savePerformance,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('저장'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '달성률',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
            Text(
              '${rate.toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isAchieved ? Colors.green : color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: rate / 100,
            minHeight: 14,
            backgroundColor: Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(
              isAchieved ? Colors.green : color,
            ),
          ),
        ),
        if (isAchieved)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text('목표 달성 완료!',
                style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
          ),
      ],
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만원';
    }
    return '${amount.toStringAsFixed(0)}원';
  }
}
