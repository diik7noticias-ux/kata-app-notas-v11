import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:search_choices/search_choices.dart';

part 'home_screen.g.dart';

@HiveType(typeId: 0)
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
  bool isIncome;

  @HiveField(5)
  DateTime date;

  Transaction({
    required this.id,
    required this.title,
    this.description = '',
    this.amount = 0.0,
    this.isIncome = false,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  String get formattedDate => '${date.day}/${date.month}/${date.year}';
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Transaction> transactionBox;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _initHive() async {
    await Hive.initFlutter();
    Hive.registerAdapter(TransactionAdapter());
    transactionBox = await Hive.openBox<Transaction>('transactions');
    setState(() {});
  }

  Future<void> _addTransaction(Transaction transaction) async {
    await transactionBox.add(transaction);
    setState(() {});
  }

  Future<void> _toggleTransactionStatus(String id) async {
    final transaction = transactionBox.get(id);
    if (transaction != null) {
      transaction.isIncome = !transaction.isIncome;
      await transactionBox.put(id, transaction);
    }
  }

  Future<void> _deleteTransaction(String id) async {
    await transactionBox.delete(id);
    setState(() {});
  }

  List<Transaction> _filterTransactions(List<Transaction> transactions) {
    if (_searchQuery.isEmpty && _selectedDate == null) {
      return transactions;
    }

    return transactions.where((transaction) =>
        transaction.title.toLowerCase().contains(_searchQuery.toLowerCase()) &&
        (_selectedDate == null || transaction.date.year == _selectedDate!.year &&
            transaction.date.month == _selectedDate!.month &&
            transaction.date.day == _selectedDate!.day)
    ).toList();
  }

  Future<void> _showAddTransactionDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final isIncome = true;

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Nova Transação'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: titleController,
                      decoration: const InputDecoration(
                        labelText: 'Destino/Produto',
                        hintText: 'Digite o nome do destino ou produto',
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descrição',
                        hintText: 'Digite a descrição',
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: amountController,
                      decoration: const InputDecoration(
                        labelText: 'Quantia',
                        hintText: 'Digite o valor',
                      ),
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Entrada/Saída: '),
                        Radio<bool>(
                          value: true,
                          groupValue: isIncome,
                          onChanged: (value) {
                            setState(() {
                              isIncome = value!;
                            });
                          },
                        ),
                        const Text('Entrada'),
                        Radio<bool>(
                          value: false,
                          groupValue: isIncome,
                          onChanged: (value) {
                            setState(() {
                              isIncome = value!;
                            });
                          },
                        ),
                        const Text('Saída'),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now(),
                          firstDate: DateTime(2000),
                          lastDate: DateTime(2100),
                        );
                        if (date != null) {
                          setState(() {
                            _selectedDate = date;
                          });
                        }
                      },
                      child: const Text('Selecionar Data'),
                    ),
                    if (_selectedDate != null)
                      Text('Data selecionada: ${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}'),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Adicionar'),
                  onPressed: () {
                    if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                      final newTransaction = Transaction(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        title: titleController.text,
                        description: descriptionController.text,
                        amount: double.tryParse(amountController.text) ?? 0.0,
                        isIncome: isIncome,
                        date: _selectedDate ?? DateTime.now(),
                      );
                      _addTransaction(newTransaction);
                      Navigator.of(context).pop();
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildTransactionSummary() {
    final transactions = transactionBox.values.toList();
    final income = transactions.where((t) => t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final expenses = transactions.where((t) => !t.isIncome).fold(0.0, (sum, t) => sum + t.amount);
    final balance = income - expenses;

    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildSummaryItem('Entradas', income, Colors.green),
                _buildSummaryItem('Saídas', expenses, Colors.red),
                _buildSummaryItem('Saldo', balance, balance >= 0 ? Colors.green : Colors.red),
              ],
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                _showAddTransactionDialog();
              },
              child: const Text('Adicionar Transação'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, double value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        const SizedBox(height: 4),
        Text('R\$${value.toStringAsFixed(2)}', style: TextStyle(fontWeight: FontWeight.bold, color: color)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notas V11'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                SearchChoices<String>.single(
                  items: [],
                  hint: 'Pesquisar transações...',
                  onChanged: (value) {
                    setState(() {
                      _searchQuery = value ?? '';
                    });
                  },
                ),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(2000),
                      lastDate: DateTime(2100),
                    );
                    if (date != null) {
                      setState(() {
                        _selectedDate = date;
                      });
                    }
                  },
                  child: const Text('Filtro por Data'),
                ),
              ],
            ),
          ),
        ),
      ),
      body: Column(
        children: [
          _buildTransactionSummary(),
          Expanded(
            child: ValueListenableBuilder<Box<Transaction>>(
              valueListenable: transactionBox.listenable(),
              builder: (context, box, _) {
                final transactions = box.values.toList();
                final filteredTransactions = _filterTransactions(transactions);
                return filteredTransactions.isEmpty
                    ? const Center(
                        child: Text('Nenhuma transação encontrada'),
                      )
                    : ListView.builder(
                        itemCount: filteredTransactions.length,
                        itemBuilder: (context, index) {
                          final transaction = filteredTransactions[index];
                          final color = transaction.isIncome ? Colors.green : Colors.red;
                          return Card(
                            child: ListTile(
                              title: Text(
                                transaction.title,
                                style: TextStyle(
                                  color: color,
                                  decoration: TextDecoration.none,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  if (transaction.description.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 4.0),
                                      child: Text(
                                        transaction.description,
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                    ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'Data: ${transaction.formattedDate}',
                                      style: const TextStyle(fontSize: 14),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 4.0),
                                    child: Text(
                                      'R\$${transaction.amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: color,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              trailing: IconButton(
                                icon: const Icon(Icons.delete),
                                onPressed: () => _deleteTransaction(transaction.id),
                              ),
                            ),
                          );
                        },
                      );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddTransactionDialog,
        tooltip: 'Adicionar Transação',
        child: const Icon(Icons.add),
      ),
    );
  }
}