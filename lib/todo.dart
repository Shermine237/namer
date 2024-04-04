import 'dart:async';
import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';

class Task{
  String title;
  String body;

  Task(this.title, this.body);
}

class ToDoPage extends StatefulWidget {
  const ToDoPage({super.key});

  @override
  _ToDoPageState createState() => _ToDoPageState();
}

class _ToDoPageState extends State<ToDoPage> {
  late DatabaseReference _tasksRef;
  late final List<Task> _tasks = [];
  late List<Task> _selectedTasks;
  final TextEditingController _taskNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tasksRef = FirebaseDatabase.instance.ref().child("tasks");
    _selectedTasks = [];

    _getAllTasks();
  }

  void _getAllTasks() async {
    try {
      _tasksRef.onValue.listen((event) {
        DataSnapshot dataSnapshot = event.snapshot;
        Map<dynamic, dynamic>? values = dataSnapshot.value as Map<dynamic, dynamic>?;

        if (values != null) {
          _tasks.clear();
          values.forEach((key, value) {
            _tasks.add(Task(value['title'], value['body']));
          });
        }
      });
    } catch (e) {
      throw Exception('Échec de la récupération des tâches : $e');
    }
  }

  Future<void> _addTask(Task task) async {
    try {
      await _tasksRef.push().set({
        "title": task.title,
        "body": task.body,
      });
    } on FirebaseException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de l'ajout de la tâche : ${e.message}"))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Échec de l'ajout de la tâche : $e"))
      );
    }
  }

  void _removeTask(Task task) {
    try {
      _tasksRef
          .orderByChild("title")
          .equalTo(task.title)
          .once()
          .then((DatabaseEvent event) {
        if (event.snapshot.value != null) {
          Map<dynamic, dynamic> values = event.snapshot.value as Map<dynamic, dynamic>;
          values.forEach((key, value) {
            if(value['body'] == task.body){
              _tasksRef.child(key).remove();
            }
          });
        }
      }).catchError((e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to remove task: $e")),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to remove task: $e")),
      );
    }
  }

  Future<void> _deleteSelectedTasks(List<Task> tasks) async {
    bool confirmDelete = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmation'),
          content: const Text('Voulez-vous vraiment supprimer les taches sélectionnées ?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(false);
              },
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(true);
              },
              child: const Text('Supprimer'),
            ),
          ],
        );
      },
    );

    if (confirmDelete && tasks.isNotEmpty) {
      for (final task in tasks) {
        _removeTask(task);
      }
      _selectedTasks.clear();
    }
  }

  Stream<List<Task>> _tasksStream() async* {
    while (true) {
      yield _tasks;
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("To-Do Liste"),
        actions: [
          Visibility(
            visible: _selectedTasks.isNotEmpty,
            child: IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () {
                _deleteSelectedTasks(_selectedTasks);
              },
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Task>>(
              stream: _tasksStream(),
              builder: (context, snapshot) {
                if (snapshot.hasData) {
                  List<Task> tasks = snapshot.data!;

                  return ListView.builder(
                    itemCount: tasks.length,
                    itemBuilder: (context, index) {
                      Task task = tasks[index];
                      return ListTile(
                        title: Text(task.title),
                        subtitle: Text(task.body),
                        leading: Checkbox(
                          value: _selectedTasks.contains(task),
                          onChanged: (value) {
                            setState(() {
                              if (value == true && !_selectedTasks.contains(task)) {
                                _selectedTasks.add(task);
                              } else {
                                _selectedTasks.remove(task);
                              }
                            });
                          },
                        ),
                      );
                    },
                  );
                } else {
                  return const CircularProgressIndicator();
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _taskNameController,
              onSubmitted: (taskTitle) {
                if (taskTitle.isNotEmpty) {
                  _addTask(Task(taskTitle, "Pas de description"));
                  _taskNameController.clear();
                }
              },
              decoration: InputDecoration(
                labelText: "Nouvelle tâche",
                suffixIcon: IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: () {
                    final taskTitle = _taskNameController.text.trim();
                    if (taskTitle.isNotEmpty) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          String enteredText = '';
                          return AlertDialog(
                            title: const Text('Description'),
                            content: TextField(
                              onChanged: (value) {
                                enteredText = value;
                              },
                              maxLines: null,
                            ),
                            actions: [
                              TextButton(
                                child: const Text('Annuler'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                              TextButton(
                                child: const Text('Ajouter'),
                                onPressed: () {
                                  _addTask(Task(taskTitle, enteredText));
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                      _taskNameController.clear();
                    }
                  },
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
