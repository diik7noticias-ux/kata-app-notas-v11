import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:notas_v11/models/transaction_model.dart';

class TransactionList extends StatefulWidget {
  const TransactionList({
    super.key,
    required this.transactions,
    required this.onTransactionSelected,
    required this.onTransactionDeleted,
    required this.onTransactionUpdated,
    this.showAddButton = true,
  });

  final List<Transaction> transactions;
  final Function(Transaction) onTransactionSelected;
  final Function(String) onTransactionDeleted;
  final Function(Transaction) onTransactionUpdated;
  final bool showAddButton;

  @override
  State<TransactionList> createState() => _TransactionListState();
}

class _TransactionListState extends State<TransactionList> {
  late List<Transaction> _filteredTransactions;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _filteredTransactions = List.from(widget.transactions);
    _searchController.addListener(_filterTransactions);
  }

  @override
  void didUpdateWidget(TransactionList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.transactions != widget.transactions) {
      setState(() {
        _filteredTransactions = List.from(widget.transactions);
      });
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_filterTransactions);
    _searchController.dispose();
    super.dispose();
  }

  void _filterTransactions() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filteredTransactions = widget.transactions.where((transaction) {
        return transaction.title.toLowerCase().contains(_searchQuery) ||
            transaction.description.toLowerCase().contains(_searchQuery) ||
            transaction.category.toLowerCase().contains(_searchQuery);
      }).toList();
    });
  }

  void _showTransactionDetails(Transaction transaction) {
    widget.onTransactionSelected(transaction);
  }

  void _showUpdateTransactionDialog(Transaction transaction) {
    final nameController = TextEditingController(text: transaction.title);
    final descriptionController = TextEditingController(text: transaction.description);
    final amountController = TextEditingController(text: transaction.amount.toString());
    final categoryController = TextEditingController(text: transaction.category);

    showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Editar Transação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome',
                    hintText: 'Digite o nome da transação',
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
                TextField(
                  controller: categoryController,
                  decoration: const InputDecoration(
                    labelText: 'Categoria',
                    hintText: 'Digite a categoria',
                  ),
                ),
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
              child: const Text('Salvar'),
              onPressed: () {
                final updatedTransaction = Transaction(
                  id: transaction.id,
                  title: nameController.text.trim(),
                  description: descriptionController.text.trim(),
                  amount: double.tryParse(amountController.text) ?? 0.0,
                  category: categoryController.text.trim(),
                  date: transaction.date,
                  type: transaction.type,
                );
                widget.onTransactionUpdated(updatedTransaction);
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pesquisar transações...',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: _filteredTransactions.length,
            itemBuilder: (context, index) {
              final transaction = _filteredTransactions[index];
              final isIncome = transaction.type == 'income';
              final color = isIncome ? Colors.green : Colors.red;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color,
                    child: Icon(
                      isIncome ? Icons.arrow_upward : Icons.arrow_downward,
                      color: Colors.white,
                    ),
                  ),
                  title: Text(
                    transaction.title,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        transaction.description,
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            transaction.category,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            transaction.date.toString().split(' ')[0],
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Text(
                    '${transaction.amount.toStringAsFixed(2)} €',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  onTap: () => _showTransactionDetails(transaction),
                  onLongPress: () => _showUpdateTransactionDialog(transaction),
                ),
              );
            },
          ),
        ),
        if (widget.showAddButton)
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: FloatingActionButton(
              onPressed: () {
                final newTransaction = Transaction(
                  id: DateTime.now().millisecondsSinceEpoch.toString(),
                  title: '',
                  description: '',
                  amount: 0.0,
                  category: '',
                  date: DateTime.now(),
                  type: 'expense',
                );
                widget.onTransactionSelected(newTransaction);
              },
              child: const Icon(Icons.add),
            ),
          ),
      ],
    );
  }
}