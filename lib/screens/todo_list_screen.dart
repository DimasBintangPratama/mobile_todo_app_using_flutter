import 'package:flutter/material.dart';
import 'package:todo_app/models/todo.dart';
import 'package:todo_app/services/api_service.dart';
import 'package:todo_app/screens/add_todo_screen.dart';
import 'package:todo_app/screens/edit_todo_screen.dart'; // Import the new screen

class TodoListScreen extends StatefulWidget {
  @override
  _TodoListScreenState createState() => _TodoListScreenState();
}

class _TodoListScreenState extends State<TodoListScreen> {
  late Future<List<Todo>> _todoList;

  @override
  void initState() {
    super.initState();
    _fetchTodos();
  }

  void _fetchTodos() {
    setState(() {
      _todoList = ApiService().fetchTodos();
    });
  }

  Future<void> _updateTodoCompletion(Todo todo, bool? value) async {
    Todo updatedTodo = Todo(
      id: todo.id,
      title: todo.title,
      description: todo.description,
      completed: value ?? false,
    );

    try {
      await ApiService().updateTodo(updatedTodo);
      _fetchTodos();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update todo')),
      );
    }
  }

  Future<void> _deleteTodoConfirm(Todo todo) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Todo'),
        content: Text('Are you sure you want to delete this todo?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ApiService().deleteTodo(todo.id);
                _fetchTodos();
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Failed to delete todo')),
                );
              }
            },
            child: Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Todo App'),
      ),
      body: FutureBuilder<List<Todo>>(
        future: _todoList,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            print('Error: ${snapshot.error}');
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(child: Text('No todos available'));
          } else {
            final todos = snapshot.data!;
            print('Todos: $todos');
            return ListView.builder(
              itemCount: todos.length,
              itemBuilder: (context, index) {
                final todo = todos[index];
                return ListTile(
                  title: Text(todo.title),
                  subtitle: Text(todo.description),
                  trailing: Checkbox(
                    value: todo.completed,
                    onChanged: (bool? value) {
                      _updateTodoCompletion(todo, value);
                    },
                  ),
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => EditTodoScreen(todo: todo),
                      ),
                    );
                    if (result == true) {
                      _fetchTodos(); // Refresh the list after editing or deleting a todo
                    }
                  },
                );
              },
            );
          }
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddTodoScreen()),
          );
          if (result != null && result is Todo) {
            _fetchTodos(); // Refresh the list after adding a new todo
          }
        },
        child: Icon(Icons.add),
      ),
    );
  }
}
