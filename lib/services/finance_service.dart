import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/finance_model.dart';

class FinanceService {
  static const String _financeRecordsBoxName = 'finance_records';
  late Box<FinanceRecord> _financeRecordsBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FinanceRecordAdapter());
    _financeRecordsBox = await Hive.openBox<FinanceRecord>(_financeRecordsBoxName);
  }

  Future<void> addRecord(FinanceRecord record) async {
    await _financeRecordsBox.add(record);
  }

  List<FinanceRecord> getAllRecords() {
    return _financeRecordsBox.values.toList();
  }

  List<FinanceRecord> getRecordsByDate(DateTime date) {
    return _financeRecordsBox.values
        .where((record) => record.date.year == date.year && record.date.month == date.month && record.date.day == date.day)
        .toList();
  }

  double getTotalIncome() {
    return _financeRecordsBox.values
        .where((record) => record.isIncome)
        .fold(0.0, (sum, record) => sum + record.amount);
  }

  double getTotalExpense() {
    return _financeRecordsBox.values
        .where((record) => !record.isIncome)
        .fold(0.0, (sum, record) => sum + record.amount);
  }

  double getNetBalance() {
    return getTotalIncome() - getTotalExpense();
  }

  String formatCurrency(double amount) {
    return 'R\)${amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=\d{3}+(?!\d))'),
          (Match m) => '${m.group(1)},',
        )}';
  }

  String formatDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }
}