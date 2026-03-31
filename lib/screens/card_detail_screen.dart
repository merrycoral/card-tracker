import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';
import '../models/card_model.dart';
import '../models/performance_model.dart';
import '../providers/open_banking_provider.dart';
import '../providers/performance_provider.dart';
import '../services/notification_service.dart';
import '../services/open_banking_service.dart';
import '../widgets/performance_chart.dart';
import 'add_card_screen.dart';
import 'bank_connect_screen.dart';

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
          // 오픈뱅킹 연동 버튼
          Consumer(builder: (_, ref, __) {
            final mapping = ref.watch(obCardMappingProvider);
            final isLinked = mapping.containsKey(card.id);
            return IconButton(
              icon: Icon(
                isLinked ? Icons.link : Icons.link_off,
                color: isLinked ? Colors.green : null,
              ),
              tooltip: isLinked ? '오픈뱅킹 연동됨' : '오픈뱅킹 연동',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => BankConnectScreen(appCard: card),
                ),
              ),
            );
          }),
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
          // 오픈뱅킹 연동 시 자동 불러오기 버튼
          _OBSyncButton(card: card, selectedMonth: _selectedMonth, onSynced: (amount) {
            _amountCtrl.text = amount.toStringAsFixed(0);
          }),
          const SizedBox(height: 12),
          _buildPerformanceInput(rate, isAchieved, color),
          const SizedBox(height: 24),
          // 실거래 내역 (오픈뱅킹 연동 시)
          _OBTransactionList(card: card, selectedMonth: _selectedMonth),
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

// ── 오픈뱅킹 자동 동기화 버튼 ─────────────────────────────────────────────────

class _OBSyncButton extends ConsumerWidget {
  final CardModel card;
  final DateTime selectedMonth;
  final ValueChanged<double> onSynced;

  const _OBSyncButton({
    required this.card,
    required this.selectedMonth,
    required this.onSynced,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapping = ref.watch(obCardMappingProvider);
    final cardNo = mapping[card.id];
    if (cardNo == null) return const SizedBox.shrink();

    final usageAsync = ref.watch(obMonthlyUsageProvider(
      usageParams(cardNo, selectedMonth.year, selectedMonth.month),
    ));

    return usageAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (e, _) => const SizedBox.shrink(),
      data: (amount) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: Colors.blue[50],
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.blue.shade200),
        ),
        child: Row(
          children: [
            const Icon(Icons.sync, size: 18, color: Colors.blue),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('오픈뱅킹 실시간 내역',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue)),
                  Text(
                    '승인 금액: ${_fmt(amount)}',
                    style: TextStyle(fontSize: 13, color: Colors.blue[800]),
                  ),
                ],
              ),
            ),
            ElevatedButton(
              onPressed: () => onSynced(amount),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                textStyle: const TextStyle(fontSize: 12),
              ),
              child: const Text('적용'),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(double v) =>
      v >= 10000 ? '${(v / 10000).toStringAsFixed(0)}만원' : '${v.toStringAsFixed(0)}원';
}

// ── 실거래 내역 리스트 ────────────────────────────────────────────────────────

class _OBTransactionList extends ConsumerWidget {
  final CardModel card;
  final DateTime selectedMonth;

  const _OBTransactionList({required this.card, required this.selectedMonth});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mapping = ref.watch(obCardMappingProvider);
    final cardNo = mapping[card.id];
    if (cardNo == null) return const SizedBox.shrink();

    final txnsAsync = ref.watch(obTransactionsProvider(
      txnParams(cardNo, selectedMonth.year, selectedMonth.month),
    ));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('실거래 내역',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            txnsAsync.maybeWhen(
              data: (txns) => Text('${txns.length}건',
                  style: TextStyle(fontSize: 13, color: Colors.grey[600])),
              orElse: () => const SizedBox.shrink(),
            ),
          ],
        ),
        const SizedBox(height: 8),
        txnsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
          error: (e, _) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text('내역 조회 실패: $e',
                style: const TextStyle(color: Colors.red, fontSize: 13)),
          ),
          data: (txns) {
            if (txns.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text('이번 달 사용 내역이 없습니다.',
                      style: TextStyle(color: Colors.grey[500])),
                ),
              );
            }
            return Column(
              children: txns.map((t) => _TransactionTile(txn: t)).toList(),
            );
          },
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final OBTransaction txn;
  const _TransactionTile({required this.txn});

  @override
  Widget build(BuildContext context) {
    final fmt = NumberFormat('#,###');
    final dateFmt = DateFormat('M/d HH:mm');
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: txn.isCancelled ? Colors.grey[50] : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  txn.merchantName,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    decoration: txn.isCancelled
                        ? TextDecoration.lineThrough
                        : null,
                    color: txn.isCancelled ? Colors.grey : null,
                  ),
                ),
                Text(
                  dateFmt.format(txn.approvedAt),
                  style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${fmt.format(txn.approvedAmount)}원',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: txn.isCancelled ? Colors.grey : Colors.black,
                  decoration: txn.isCancelled
                      ? TextDecoration.lineThrough
                      : null,
                ),
              ),
              if (txn.isCancelled)
                const Text('취소',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.red,
                        fontWeight: FontWeight.bold)),
            ],
          ),
        ],
      ),
    );
  }
}
