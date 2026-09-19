import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:notas_v11/models/finance_model.dart';
import 'package:notas_v11/widgets/add_note_form.dart';

class FinanceScreen extends StatefulWidget {
  const FinanceScreen({super.key});

  @override
  State<FinanceScreen> createState() => _FinanceScreenState();
}

class _FinanceScreenState extends State<FinanceScreen> {
  late Box<FinanceRecord> financeBox;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  DateTime? _selectedDate;
  bool _isIncome = true;
  double _totalIncome = 0.0;
  double _totalExpense = 0.0;

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
    Hive.registerAdapter(FinanceRecordAdapter());
    financeBox = await Hive.openBox<FinanceRecord>('finance_records');
    _calculateTotals();
    setState(() {});
  }

  Future<void> _addFinanceRecord(FinanceRecord record) async {
    await financeBox.add(record);
    _calculateTotals();
    setState(() {});
  }

  void _calculateTotals() {
    _totalIncome = financeBox.values
        .where((record) => record.isIncome && record.amount > 0)
        .fold(0.0, (sum, record) => sum + record.amount);

    _totalExpense = financeBox.values
        .where((record) => !record.isIncome && record.amount > 0)
        .fold(0.0, (sum, record) => sum + record.amount);
  }

  List<FinanceRecord> _filterRecords(List<FinanceRecord> records) {
    if (_searchQuery.isEmpty && _selectedDate == null) {
      return records;
    }

    return records.where((record) {
      final matchesSearch = record.title.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesDate = _selectedDate == null || record.date == _selectedDate;

      return matchesSearch && matchesDate;
    }).toList();
  }

  Future<void> _showAddFinanceDialog() async {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final amountController = TextEditingController();
    final destinationController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Nova Transação'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Produto/Descrição',
                    hintText: 'Digite o nome do produto ou descrição',
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Detalhes',
                    hintText: 'Digite detalhes adicionais',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: destinationController,
                  decoration: const InputDecoration(
                    labelText: 'Destino',
                    hintText: 'Digite o destino (ex: Supermercado)',
                  ),
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
                    const Text('Entrada:'),
                    Switch(
                      value: _isIncome,
                      onChanged: (value) {
                        setState(() {
                          _isIncome = value;
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
                  child: Text(
                    _selectedDate == null
                        ? 'Selecionar Data'
                        : 'Data: ${DateFormat('dd/MM/yyyy').format(_selectedDate!)}',
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
              child: const Text('Adicionar'),
              onPressed: () {
                if (titleController.text.isNotEmpty && amountController.text.isNotEmpty) {
                  final newRecord = FinanceRecord(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    title: titleController.text,
                    description: descriptionController.text,
                    amount: double.tryParse(amountController.text) ?? 0.0,
                    destination: destinationController.text,
                    isIncome: _isIncome,
                    date: _selectedDate ?? DateTime.now(),
                  );
                  _addFinanceRecord(newRecord);
                  Navigator.of(context).pop();
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Por favor, preencha todos os campos obrigatórios')),
                  );
                }
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Registos Financeiros'),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) {
                  return AlertDialog(
                    title: const Text('Pesquisa'),
                    content: TextField(
                      controller: _searchController,
                      decoration: const InputDecoration(
                        labelText: 'Pesquisar',
                        hintText: 'Digite o que deseja pesquisar',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                    ),
                    actions: [
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                        },
                        child: const Text('Cancelar'),
                      ),
                      TextButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(() {
                            _searchQuery = '';
                          });
                          Navigator.of(context).pop();
                        },
                        child: const Text('Limpar'),
                      ),
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Entradas: ${_formatCurrency(_totalIncome)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'Total Saídas: ${_formatCurrency(_totalExpense)}',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: _showAddFinanceDialog,
                  child: const Text('Nova Transação'),
                ),
              ],
            ),
          ),
          Expanded(
            child: ValueListenableBuilder<Box<FinanceRecord>>(
              valueListenable: ValueListenable<Box<FinanceRecord>>.fromVoid(
                () => financeBox,
              ),
              builder: (context, box, _) {
                final records = _filterRecords(box.values.toList());
                return ListView.builder(
                  itemCount: records.length,
                  itemBuilder: (context, index) {
                    final record = records[index];
                    return Card(
                      child: ListTile(
                        title: Text(record.title),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(record.description.isEmpty
                                ? 'Sem descrição'
                                : record.description),
                            Text('Destino: ${record.destination}'),
                            Text(
                              'Data: ${DateFormat('dd/MM/yyyy').format(record.date)}',
                            ),
                          ],
                        ),
                        trailing: Text(
                          record.isIncome ? '+ ${_formatCurrency(record.amount)}' : '- ${_formatCurrency(record.amount)}',
                          style: TextStyle(
                            color: record.isIncome ? Colors.green : Colors.red,
                          ),
                        ),
                        onTap: () {
                          // Implementar detalhes da transação
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double amount) {
    return 'R\$ ${amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m.group(1)},',
        )}';
  }
}