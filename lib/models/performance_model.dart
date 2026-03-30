import 'package:hive/hive.dart';

part 'performance_model.g.dart';

@HiveType(typeId: 1)
class PerformanceModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String cardId;

  @HiveField(2)
  late int year;

  @HiveField(3)
  late int month;

  @HiveField(4)
  late double usedAmount;

  PerformanceModel({
    required this.id,
    required this.cardId,
    required this.year,
    required this.month,
    required this.usedAmount,
  });
}
