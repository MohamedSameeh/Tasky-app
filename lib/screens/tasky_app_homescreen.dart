import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../models/task_model.dart';
import '../widgets/task_list_item.dart';
import 'add_edit_task_screen.dart';
import 'task_details_screen.dart';

enum TaskFilter { today, upcoming, all }

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final AuthService _authService = AuthService(FirebaseAuth.instance);
  final FirestoreService _firestoreService = FirestoreService();
  final User? _user = FirebaseAuth.instance.currentUser;
  String _searchQuery = '';
  TaskFilter _currentFilter = TaskFilter.today;

  String _getFilterText() {
    switch (_currentFilter) {
      case TaskFilter.today:
        return 'Today';
      case TaskFilter.upcoming:
        return 'Upcoming';
      case TaskFilter.all:
        return 'All Tasks';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: RichText(
          text: const TextSpan(
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              fontFamily: 'Inter',
            ),
            children: [
              TextSpan(text: 'Task', style: TextStyle(color: Colors.black)),
              TextSpan(text: 'y', style: TextStyle(color: Color(0xFF6200EE))),
            ],
          ),
        ),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.logout, color: Colors.red),
            label: const Text('Log out', style: TextStyle(color: Colors.red)),
            onPressed: () async {
              await _authService.signOut();
            },
          ),
        ],
      ),
      body:
          _user == null
              ? const Center(child: Text("No user logged in."))
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value.toLowerCase();
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search for your task...',
                        prefixIcon: const Icon(Icons.search),
                        filled: true,
                        fillColor: Colors.grey.shade100,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Row(
                      children: [
                        PopupMenuButton<TaskFilter>(
                          onSelected: (TaskFilter result) {
                            setState(() {
                              _currentFilter = result;
                            });
                          },
                          itemBuilder:
                              (BuildContext context) =>
                                  <PopupMenuEntry<TaskFilter>>[
                                    const PopupMenuItem<TaskFilter>(
                                      value: TaskFilter.today,
                                      child: Text('Today'),
                                    ),
                                    const PopupMenuItem<TaskFilter>(
                                      value: TaskFilter.upcoming,
                                      child: Text('Upcoming'),
                                    ),
                                    const PopupMenuItem<TaskFilter>(
                                      value: TaskFilter.all,
                                      child: Text('All Tasks'),
                                    ),
                                  ],
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade300),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Text(_getFilterText()),
                                const Icon(Icons.arrow_drop_down),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: StreamBuilder<List<Task>>(
                      stream: _firestoreService.getTasks(_user!.uid),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text('Error: ${snapshot.error}'),
                          );
                        }
                        if (!snapshot.hasData || snapshot.data!.isEmpty) {
                          return _buildEmptyState();
                        }

                        final allTasks = snapshot.data!;

                        // --- Filtering Logic ---
                        final now = DateTime.now();
                        final today = DateTime(now.year, now.month, now.day);

                        List<Task> dateFilteredTasks;
                        switch (_currentFilter) {
                          case TaskFilter.today:
                            dateFilteredTasks =
                                allTasks
                                    .where(
                                      (task) =>
                                          task.taskTime != null &&
                                          isSameDay(task.taskTime, today),
                                    )
                                    .toList();
                            break;
                          case TaskFilter.upcoming:
                            dateFilteredTasks =
                                allTasks
                                    .where(
                                      (task) =>
                                          task.taskTime != null &&
                                          task.taskTime!.isAfter(today),
                                    )
                                    .toList();
                            break;
                          case TaskFilter.all:
                            dateFilteredTasks = allTasks;
                            break;
                        }

                        final searchFilteredTasks =
                            dateFilteredTasks
                                .where(
                                  (task) => task.title.toLowerCase().contains(
                                    _searchQuery,
                                  ),
                                )
                                .toList();

                        final pendingTasks =
                            searchFilteredTasks
                                .where((t) => !t.isCompleted)
                                .toList();
                        final completedTasks =
                            searchFilteredTasks
                                .where((t) => t.isCompleted)
                                .toList();

                        return ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            ...pendingTasks.map(
                              (task) => _buildTaskItem(context, task),
                            ),
                            if (completedTasks.isNotEmpty) ...[
                              Padding(
                                padding: const EdgeInsets.only(
                                  top: 16.0,
                                  bottom: 8.0,
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 4,
                                      ),
                                      decoration: BoxDecoration(
                                        border: Border.all(
                                          color: Colors.grey.shade300,
                                        ),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: const Text(
                                        'Completed',
                                        style: TextStyle(
                                          color: Colors.grey,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              ...completedTasks.map(
                                (task) => _buildTaskItem(context, task),
                              ),
                            ],
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          if (_user != null) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => AddEditTaskScreen(userId: _user!.uid),
              ),
            );
          }
        },
        backgroundColor: Colors.black87,
        child: const Icon(Icons.add, color: Colors.white, size: 32),
        shape: const CircleBorder(),
      ),
    );
  }

  Widget _buildTaskItem(BuildContext context, Task task) {
    return TaskListItem(
      task: task,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder:
                (context) => TaskDetailsScreen(userId: _user!.uid, task: task),
          ),
        );
      },
      onStatusChanged: (isCompleted) {
        final updatedTask = Task(
          id: task.id,
          title: task.title,
          description: task.description,
          taskTime: task.taskTime,
          priority: task.priority,
          isCompleted: isCompleted,
          createdAt: task.createdAt,
        );
        _firestoreService.setTask(_user!.uid, updatedTask);
      },
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/tasky_homescreen.png', height: 200),
          const SizedBox(height: 24),
          const Text(
            'What do you want to do today?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Tap + to add your tasks',
            style: TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}
