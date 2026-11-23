import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../data/auth_repository.dart';
import 'add_edit_task_screen.dart';
import 'calendar_tab.dart';
import 'insights_tab.dart';
import 'tasks_tab.dart';
import 'today_tab.dart';

/// Signed-in shell: Today, Calendar, Tasks (search + filters) and Insights.
class HomeScreen extends StatefulWidget {
  final AppUser user;
  const HomeScreen({super.key, required this.user});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _index = 0;
  DateTime? _calendarDay;

  void _goTo(int i) => setState(() => _index = i);

  void _addTask() {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder:
            (context) => AddEditTaskScreen(
              userId: widget.user.uid,
              // Adding from the calendar pre-fills the selected day.
              initialDate: _index == 1 ? _calendarDay : null,
            ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final store = AppScope.tasks;
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            TodayTab(
              user: widget.user,
              store: store,
              onSearch: () => _goTo(2),
              onAdd: _addTask,
            ),
            CalendarTab(
              store: store,
              onAdd: _addTask,
              onDayChanged: (d) => _calendarDay = d,
            ),
            TasksTab(store: store, onAdd: _addTask),
            InsightsTab(store: store, active: _index == 3),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _addTask,
        tooltip: 'New task',
        child: const Icon(Icons.add, size: 28),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(color: Theme.of(context).dividerTheme.color!),
          ),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: _goTo,
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.wb_sunny_outlined),
              selectedIcon: Icon(Icons.wb_sunny),
              label: 'Today',
            ),
            NavigationDestination(
              icon: Icon(Icons.calendar_month_outlined),
              selectedIcon: Icon(Icons.calendar_month),
              label: 'Calendar',
            ),
            NavigationDestination(
              icon: Icon(Icons.checklist_outlined),
              selectedIcon: Icon(Icons.checklist),
              label: 'Tasks',
            ),
            NavigationDestination(
              icon: Icon(Icons.insights_outlined),
              selectedIcon: Icon(Icons.insights),
              label: 'Insights',
            ),
          ],
        ),
      ),
    );
  }
}
