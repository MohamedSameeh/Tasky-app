import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import 'common.dart';

/// One task row: round checkbox, title, then category / due date / priority.
class TaskListItem extends StatelessWidget {
  final Task task;
  final VoidCallback onTap;
  final Function(bool) onStatusChanged;
  final bool showDate;

  const TaskListItem({
    super.key,
    required this.task,
    required this.onTap,
    required this.onStatusChanged,
    this.showDate = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final done = task.isCompleted;
    final overdue = task.isOverdue;
    final due = task.taskTime;
    final dueColor =
        overdue
            ? p.danger
            : (task.isDueToday && !done ? context.colors.primary : p.muted);

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: AppCard(
        onTap: onTap,
        padding: const EdgeInsets.fromLTRB(8, 12, 14, 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskCheck(
              value: done,
              onChanged: onStatusChanged,
              semanticLabel:
                  done
                      ? 'Mark ${task.title} as not done'
                      : 'Mark ${task.title} as done',
            ),
            const SizedBox(width: 6),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 7),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 200),
                      style: context.text.titleSmall!.copyWith(
                        fontSize: 15,
                        height: 1.3,
                        color: done ? p.muted : context.colors.onSurface,
                        decoration:
                            done
                                ? TextDecoration.lineThrough
                                : TextDecoration.none,
                        decorationColor: p.muted,
                      ),
                      child: Text(
                        task.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 9),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        CategoryChip(task.category),
                        if (task.priorityLevel != TaskPriority.none && !done)
                          PriorityChip(task.priorityLevel),
                        if (showDate && due != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                overdue
                                    ? Icons.error_outline
                                    : Icons.event_outlined,
                                size: 14,
                                color: dueColor,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                overdue
                                    ? 'Overdue · ${friendlyDay(due)}'
                                    : friendlyDay(due),
                                style: context.text.labelMedium?.copyWith(
                                  color: dueColor,
                                ),
                              ),
                            ],
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8, left: 4),
              child: Icon(Icons.chevron_right, size: 20, color: p.muted),
            ),
          ],
        ),
      ),
    );
  }
}
