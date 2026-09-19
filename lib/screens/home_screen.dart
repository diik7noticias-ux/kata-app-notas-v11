import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';

part 'home_screen.g.dart';

@HiveType(typeId: 0)
class Task {
  @HiveField(0)
  final String id;

  @HiveField(1)
  String title;

  @HiveField(2)
  bool isCompleted;

  Task({
    required this.id,
    required this.title,
    this.isCompleted = false,
  });
}

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Box<Task> taskBox;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

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
    Hive.registerAdapter(TaskAdapter());
    taskBox = await Hive.openBox<Task>('tasks');
    setState(() {});
  }

  Future<void> _addTask(String title) async {
    final newTask = Task(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
    );
    await taskBox.add(newTask);
    setState(() {});
  }

  Future<void> _toggleTaskStatus(String id) async {
    final task = taskBox.get(id);
    if (task != null) {
      task.isCompleted = !task.isCompleted;
      await taskBox.put(id, task);
    }
  }

  Future<void> _deleteTask(String id) async {
    await taskBox.delete(id);
    setState(() {});
  }

  List<Task> _filterTasks(List<Task> tasks) {
    if (_searchQuery.isEmpty) {
      return tasks;
    }
    return tasks.where((task) =>
        task.title.toLowerCase().contains(_searchQuery.toLowerCase())).toList();
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
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Pesquisar tarefas...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (value) {
                setState(() {
                  _searchQuery = value;
                });
              },
            ),
          ),
        ),
      ),
      body: ValueListenableBuilder<Box<Task>>(
        valueListenable: taskBox.listenable(),
        builder: (context, box, _) {
          final tasks = box.values.toList();
          final filteredTasks = _filterTasks(tasks);
          return filteredTasks.isEmpty
              ? const Center(
                  child: Text('Nenhuma tarefa encontrada'),
                )
              : ListView.builder(
                  itemCount: filteredTasks.length,
                  itemBuilder: (context, index) {
                    final task = filteredTasks[index];
                    return ListTile(
                      title: Text(
                        task.title,
                        style: TextStyle(
                          decoration: task.isCompleted
                              ? TextDecoration.lineThrough
                              : TextDecoration.none,
                        ),
                      ),
                      leading: Checkbox(
                        value: task.isCompleted,
                        onChanged: (value) => _toggleTaskStatus(task.id),
                      ),
                      trailing: IconButton(
                        icon: const Icon(Icons.delete),
                        onPressed: () => _deleteTask(task.id),
                      ),
                    );
                  },
                );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final title = await showDialog<String>(
            context: context,
            builder: (context) {
              final controller = TextEditingController();
              return AlertDialog(
                title: const Text('Nova Tarefa'),
                content: TextField(
                  controller: controller,
                  decoration: const InputDecoration(hintText: 'Digite a tarefa'),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pop(context, controller.text);
                    },
                    child: const Text('Adicionar'),
                  ),
                ],
              );
            },
          );
          if (title != null && title.isNotEmpty) {
            _addTask(title);
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}