import 'package:hive/hive.dart';

part 'card_model.g.dart';

@HiveType(typeId: 0)
class CardModel extends HiveObject {
  @HiveField(0)
  late String id;

  @HiveField(1)
  late String name;

  @HiveField(2)
  late String company;

  @HiveField(3)
  late double targetAmount;

  @HiveField(4)
  late String benefit;

  @HiveField(5)
  late int colorValue;

  @HiveField(6)
  late double alertThreshold;

  CardModel({
    required this.id,
    required this.name,
    required this.company,
    required this.targetAmount,
    required this.benefit,
    required this.colorValue,
    this.alertThreshold = 80.0,
  });
}
