import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'todo_item.dart';
import 'todo_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter((await getApplicationDocumentsDirectory()).path);
  Hive.registerAdapter(TodoItemAdapter());
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  final TodoService _todoService = TodoService();

  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Hive TODO List',
      debugShowCheckedModeBanner: false,
      home: FutureBuilder(
        future: _todoService.getAllTodos(),
        builder: (context, AsyncSnapshot<List<TodoItem>> snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return TodoListPage(snapshot.data ?? []);
          }
          return const CircularProgressIndicator();
        },
      ),
    );
  }
}

class TodoListPage extends StatefulWidget {
  final List<TodoItem> todos;

  const TodoListPage(this.todos, {super.key});

  @override
  _TodoListPageState createState() => _TodoListPageState();
}

class _TodoListPageState extends State<TodoListPage> {
  final TodoService _todoService = TodoService();
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Hive TODO List'),
        backgroundColor: Colors.black,
      ),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<TodoItem>('todoBox').listenable(),
        builder: (context, Box<TodoItem> box, _) {
          return ListView.builder(
            itemCount: box.values.length,
            itemBuilder: (context, index) {
              var todo = box.getAt(index);
              return ListTile(
                title: Text(todo!.title),
                leading: Checkbox(
                  value: todo.isCompleted,
                  onChanged: (val) {
                    _todoService.toggleCompleted(index, todo);
                  },
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.delete),
                  onPressed: () {
                    _todoService.deleteTodo(index);
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.green,
        onPressed: () async {
          showDialog(
              context: context,
              builder: (context) {
                return AlertDialog(
                  title: const Text('Add Todo'),
                  content: TextField(
                    controller: _controller,
                  ),
                  actions: [
                    ElevatedButton(
                      child: const Text('Add'),
                      onPressed: () {
                        if (_controller.text.isNotEmpty) {
                          var todo = TodoItem(_controller.text);
                          _todoService.addTodo(todo);
                          _controller.clear();
                          Navigator.pop(context);
                        }
                      },
                    )
                  ],
                );
              });
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}