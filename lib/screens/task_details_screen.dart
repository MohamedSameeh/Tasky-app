import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../app_scope.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import 'add_edit_task_screen.dart';
import 'nav.dart';

class TaskDetailsScreen extends StatelessWidget {
  final String userId;
  final Task task;

  const TaskDetailsScreen({super.key, required this.userId, required this.task});

  Future<void> _deleteTask(BuildContext context, Task task) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Delete this task?'),
            content: Text(
              '"${task.title}" will be removed for good.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(context, true),
                child: Text(
                  'Delete',
                  style: TextStyle(color: context.palette.danger),
                ),
              ),
            ],
          ),
    );

    if (confirmed == true) {
      await AppScope.taskRepository.deleteTask(userId, task.id!);
      if (context.mounted) {
        Navigator.pop(context);
        showAppSnack(context, 'Task deleted');
      }
    }
  }

  void _editTask(BuildContext context, Task task) {
    Navigator.push(
      context,
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (context) => AddEditTaskScreen(userId: userId, task: task),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Follow the store so edits and the done toggle show up immediately.
    return ListenableBuilder(
      listenable: AppScope.tasks,
      builder: (context, _) {
        final task = AppScope.tasks.byId(this.task.id) ?? this.task;
        final p = context.palette;
        final done = task.isCompleted;

        return Scaffold(
          appBar: AppBar(
            title: const Text('Task'),
            actions: [
              IconButton(
                tooltip: 'Edit task',
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _editTask(context, task),
              ),
              IconButton(
                tooltip: 'Delete task',
                icon: Icon(Icons.delete_outline, color: p.danger),
                onPressed: () => _deleteTask(context, task),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(
              AppSpace.xl,
              AppSpace.sm,
              AppSpace.xl,
              AppSpace.xl,
            ),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: _StatusPill(task: task),
              ),
              const SizedBox(height: AppSpace.md),
              Text(
                task.title,
                style: context.text.headlineMedium?.copyWith(
                  color: done ? p.muted : null,
                  decoration: done ? TextDecoration.lineThrough : null,
                  decorationColor: p.muted,
                ),
              ),
              const SizedBox(height: AppSpace.lg),
              Wrap(
                spacing: AppSpace.sm,
                runSpacing: AppSpace.sm,
                children: [
                  CategoryChip(task.category, dense: false),
                  PriorityChip(task.priorityLevel, dense: false),
                ],
              ),
              const SizedBox(height: AppSpace.xl),
              AppCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.sm,
                ),
                child: Column(
                  children: [
                    _buildDetailRow(
                      context,
                      icon: Icons.event_outlined,
                      title: 'Due date',
                      value:
                          task.taskTime != null
                              ? '${friendlyDay(task.taskTime!)}'
                                  '${daysFromToday(task.taskTime!).abs() <= 1 ? ' · ${DateFormat('MMM d').format(task.taskTime!)}' : ''}'
                              : 'Not set',
                      valueColor: task.isOverdue ? p.danger : null,
                    ),
                    const Divider(height: 1),
                    _buildDetailRow(
                      context,
                      icon: Icons.flag_outlined,
                      title: 'Priority',
                      value: task.priorityLevel.label,
                    ),
                    const Divider(height: 1),
                    _buildDetailRow(
                      context,
                      icon: Icons.schedule_outlined,
                      title: 'Created',
                      value: DateFormat.yMMMd().format(task.createdAt),
                    ),
                    if (done && task.completedAt != null) ...[
                      const Divider(height: 1),
                      _buildDetailRow(
                        context,
                        icon: Icons.check_circle_outline,
                        title: 'Completed',
                        value: DateFormat(
                          'MMM d, h:mm a',
                        ).format(task.completedAt!),
                        valueColor: p.success,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: AppSpace.xl),
              Text('Notes', style: context.text.titleMedium),
              const SizedBox(height: AppSpace.sm),
              Text(
                task.description.isEmpty
                    ? 'No notes yet. Tap edit to add details.'
                    : task.description,
                style: context.text.bodyLarge?.copyWith(
                  color: task.description.isEmpty ? p.muted : null,
                ),
              ),
            ],
          ),
          bottomNavigationBar: SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.xl,
                AppSpace.sm,
                AppSpace.xl,
                AppSpace.lg,
              ),
              child:
                  done
                      ? OutlinedButton.icon(
                        onPressed: () => toggleTask(context, task, false),
                        icon: const Icon(Icons.undo, size: 20),
                        label: const Text('Mark as not done'),
                      )
                      : FilledButton.icon(
                        onPressed: () => toggleTask(context, task, true),
                        icon: const Icon(Icons.check, size: 20),
                        label: const Text('Mark as done'),
                      ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String value,
    Color? valueColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.primary),
          const SizedBox(width: AppSpace.md),
          Text(
            title,
            style: context.text.bodyMedium?.copyWith(
              color: context.palette.muted,
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: context.text.titleSmall?.copyWith(color: valueColor),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final Task task;
  const _StatusPill({required this.task});

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final (String label, Color color, IconData icon) =
        task.isCompleted
            ? ('Done', p.success, Icons.check_circle)
            : task.isOverdue
            ? ('Overdue', p.danger, Icons.error)
            : task.isDueToday
            ? ('Due today', context.colors.primary, Icons.wb_sunny)
            : ('Open', p.info, Icons.radio_button_unchecked);
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 250),
      child: TagChip(
        key: ValueKey(label),
        label: label,
        color: color,
        icon: icon,
        dense: false,
      ),
    );
  }
}
