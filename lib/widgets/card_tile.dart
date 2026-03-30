import 'package:flutter/material.dart';
import '../models/card_model.dart';
import '../models/performance_model.dart';

class CardTile extends StatelessWidget {
  final CardModel card;
  final PerformanceModel? performance;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const CardTile({
    super.key,
    required this.card,
    required this.performance,
    required this.onTap,
    required this.onDelete,
  });

  double get achievementRate {
    if (performance == null || card.targetAmount == 0) return 0.0;
    return (performance!.usedAmount / card.targetAmount * 100).clamp(0.0, 100.0);
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(card.colorValue);
    final rate = achievementRate;
    final isAchieved = rate >= 100;
    final isWarning = rate >= card.alertThreshold && !isAchieved;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 28,
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          card.name,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        Text(
                          card.company,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isAchieved)
                    const Icon(Icons.check_circle, color: Colors.green, size: 20),
                  if (isWarning)
                    const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'delete') onDelete();
                    },
                    itemBuilder: (_) => [
                      const PopupMenuItem(value: 'delete', child: Text('삭제')),
                    ],
                    icon: const Icon(Icons.more_vert, size: 18),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    performance != null
                        ? '${_formatAmount(performance!.usedAmount)} / ${_formatAmount(card.targetAmount)}'
                        : '미입력 / ${_formatAmount(card.targetAmount)}',
                    style: const TextStyle(fontSize: 13),
                  ),
                  Text(
                    '${rate.toStringAsFixed(0)}%',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isAchieved
                          ? Colors.green
                          : isWarning
                              ? Colors.orange
                              : Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: rate / 100,
                  minHeight: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isAchieved
                        ? Colors.green
                        : isWarning
                            ? Colors.orange
                            : color,
                  ),
                ),
              ),
              if (card.benefit.isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  card.benefit,
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  String _formatAmount(double amount) {
    if (amount >= 10000) {
      return '${(amount / 10000).toStringAsFixed(0)}만원';
    }
    return '${amount.toStringAsFixed(0)}원';
  }
}
