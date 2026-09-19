import 'package:hive/hive.dart';
part 'finance_model.g.dart';

@HiveType(typeId: 2)
class FinanceRecord {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  double amount;

  @HiveField(4)
  String destination;

  @HiveField(5)
  bool isIncome;

  @HiveField(6)
  DateTime date;

  FinanceRecord({
    required this.id,
    required this.title,
    this.description = '',
    required this.amount,
    required this.destination,
    required this.isIncome,
    required this.date,
  });
}