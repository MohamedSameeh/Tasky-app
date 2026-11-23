import 'package:flutter/material.dart';
import '../app_scope.dart';
import '../models/task_model.dart';
import '../widgets/common.dart';
import '../widgets/task_list_item.dart';
import 'task_details_screen.dart';

void openTaskDetails(BuildContext context, Task task) {
  final uid = AppScope.auth.currentUser?.uid;
  if (uid == null) return;
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => TaskDetailsScreen(userId: uid, task: task),
    ),
  );
}

/// Toggles a task and offers an undo, so a slip of the thumb is harmless.
Future<void> toggleTask(BuildContext context, Task task, bool done) async {
  try {
    await AppScope.tasks.toggle(task, done);
  } catch (_) {
    if (context.mounted) {
      showAppSnack(context, 'Could not update the task', error: true);
    }
  }
}

/// A task row wired to details + toggle, used by every list in the app.
class TaskRow extends StatelessWidget {
  final Task task;
  final bool showDate;
  const TaskRow(this.task, {super.key, this.showDate = true});

  @override
  Widget build(BuildContext context) {
    return TaskListItem(
      task: task,
      showDate: showDate,
      onTap: () => openTaskDetails(context, task),
      onStatusChanged: (done) => toggleTask(context, task, done),
    );
  }
}
