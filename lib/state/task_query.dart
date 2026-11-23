import 'package:flutter/material.dart' show DateTimeRange;
import '../models/task_model.dart';

enum StatusFilter {
  all('All'),
  open('Open'),
  done('Done'),
  overdue('Overdue');

  const StatusFilter(this.label);
  final String label;
}

enum TaskSort {
  dueDate('Due date'),
  priority('Priority'),
  newest('Newest first'),
  title('Title A-Z');

  const TaskSort(this.label);
  final String label;
}

/// Search text + filters + sort for the Tasks tab. Pure and immutable so the
/// filtering rules can be unit tested without widgets.
class TaskQuery {
  final String text;
  final StatusFilter status;
  final Set<TaskPriority> priorities;
  final Set<String> categories;
  final DateTimeRange? dueRange;
  final TaskSort sort;

  const TaskQuery({
    this.text = '',
    this.status = StatusFilter.all,
    this.priorities = const {},
    this.categories = const {},
    this.dueRange,
    this.sort = TaskSort.dueDate,
  });

  TaskQuery copyWith({
    String? text,
    StatusFilter? status,
    Set<TaskPriority>? priorities,
    Set<String>? categories,
    DateTimeRange? dueRange,
    bool clearDueRange = false,
    TaskSort? sort,
  }) {
    return TaskQuery(
      text: text ?? this.text,
      status: status ?? this.status,
      priorities: priorities ?? this.priorities,
      categories: categories ?? this.categories,
      dueRange: clearDueRange ? null : (dueRange ?? this.dueRange),
      sort: sort ?? this.sort,
    );
  }

  /// Number of filters set in the filter sheet (status chips and search text
  /// are visible on the screen itself, so they are not counted).
  int get sheetFilterCount =>
      priorities.length + categories.length + (dueRange != null ? 1 : 0);

  bool get isDefault =>
      text.trim().isEmpty &&
      status == StatusFilter.all &&
      sheetFilterCount == 0;

  bool matches(Task t) {
    final q = text.trim().toLowerCase();
    if (q.isNotEmpty &&
        !t.title.toLowerCase().contains(q) &&
        !t.description.toLowerCase().contains(q) &&
        !t.category.toLowerCase().contains(q)) {
      return false;
    }
    switch (status) {
      case StatusFilter.all:
        break;
      case StatusFilter.open:
        if (t.isCompleted) return false;
      case StatusFilter.done:
        if (!t.isCompleted) return false;
      case StatusFilter.overdue:
        if (!t.isOverdue) return false;
    }
    if (priorities.isNotEmpty && !priorities.contains(t.priorityLevel)) {
      return false;
    }
    if (categories.isNotEmpty && !categories.contains(t.category)) {
      return false;
    }
    if (dueRange != null) {
      final d = t.taskTime;
      if (d == null) return false;
      final day = DateTime(d.year, d.month, d.day);
      final s = dueRange!.start, e = dueRange!.end;
      if (day.isBefore(DateTime(s.year, s.month, s.day)) ||
          day.isAfter(DateTime(e.year, e.month, e.day))) {
        return false;
      }
    }
    return true;
  }

  List<Task> apply(List<Task> all) {
    final out = all.where(matches).toList();
    final far = DateTime(9999);
    int byDue(Task a, Task b) =>
        (a.taskTime ?? far).compareTo(b.taskTime ?? far);
    switch (sort) {
      case TaskSort.dueDate:
        out.sort((a, b) {
          // Open tasks first, then by due date.
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          final c = a.isCompleted ? byDue(b, a) : byDue(a, b);
          return c != 0 ? c : b.priority.compareTo(a.priority);
        });
      case TaskSort.priority:
        out.sort((a, b) {
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          final c = b.priority.compareTo(a.priority);
          return c != 0 ? c : byDue(a, b);
        });
      case TaskSort.newest:
        out.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case TaskSort.title:
        out.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
    return out;
  }
}
