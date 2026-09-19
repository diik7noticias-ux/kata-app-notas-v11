import 'package:hive/hive.dart';
import 'package:intl/intl.dart';
import '../models/finance_model.dart';

class FinanceService {
  static const String _entriesBoxName = 'finance_entries';
  static const String _expensesBoxName = 'finance_expenses';

  late Box<FinanceEntry> _entriesBox;
  late Box<FinanceExpense> _expensesBox;

  Future<void> init() async {
    await Hive.initFlutter();
    Hive.registerAdapter(FinanceEntryAdapter());
    Hive.registerAdapter(FinanceExpenseAdapter());

    _entriesBox = await Hive.openBox<FinanceEntry>(_entriesBoxName);
    _expensesBox = await Hive.openBox<FinanceExpense>(_expensesBoxName);
  }

  Future<void> addEntry(FinanceEntry entry) async {
    await _entriesBox.add(entry);
  }

  Future<void> addExpense(FinanceExpense expense) async {
    await _expensesBox.add(expense);
  }

  List<FinanceEntry> getAllEntries() {
    return _entriesBox.values.toList();
  }

  List<FinanceExpense> getAllExpenses() {
    return _expensesBox.values.toList();
  }

  List<FinanceEntry> getEntriesByDate(String date) {
    return _entriesBox.values
        .where((entry) => entry.date == date)
        .toList();
  }

  List<FinanceExpense> getExpensesByDate(String date) {
    return _expensesBox.values
        .where((expense) => expense.date == date)
        .toList();
  }

  double getTotalEntries() {
    return _entriesBox.values.fold(0.0, (sum, entry) => sum + entry.amount);
  }

  double getTotalExpenses() {
    return _expensesBox.values.fold(0.0, (sum, expense) => sum + expense.amount);
  }

  double getNetBalance() {
    return getTotalEntries() - getTotalExpenses();
  }

  String formatCurrency(double amount) {
    return '\$${amount.toStringAsFixed(2)}';
  }

  String formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }
}