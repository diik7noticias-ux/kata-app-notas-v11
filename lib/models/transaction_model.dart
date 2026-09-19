import 'package:hive/hive.dart';
part 'transaction_model.g.dart';

@HiveType(typeId: 1)
class Transaction {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  String description;

  @HiveField(3)
  double amount;

  @HiveField(4)
  DateTime date;

  @HiveField(5)
  bool isIncome;

  Transaction({
    required this.id,
    required this.title,
    this.description = '',
    required this.amount,
    required this.date,
    this.isIncome = false,
  });
}