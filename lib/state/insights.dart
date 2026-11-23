import '../models/task_model.dart';

class DayCount {
  final DateTime day;
  final int done;
  const DayCount(this.day, this.done);
}

class GroupStat {
  final String label;
  final int total;
  final int done;
  const GroupStat(this.label, this.total, this.done);
  int get open => total - done;
  double get rate => total == 0 ? 0 : done / total;
}

/// Numbers shown on the Insights tab, computed from the task list on the device.
class Insights {
  final int total;
  final int done;
  final int open;
  final int overdue;
  final int dueToday;

  /// Tasks completed per day, oldest first, for the selected window.
  final List<DayCount> perDay;
  final int doneInWindow;
  final int doneInPreviousWindow;
  final List<GroupStat> byCategory;

  /// Open tasks per priority (highest first).
  final Map<TaskPriority, int> openByPriority;

  const Insights({
    required this.total,
    required this.done,
    required this.open,
    required this.overdue,
    required this.dueToday,
    required this.perDay,
    required this.doneInWindow,
    required this.doneInPreviousWindow,
    required this.byCategory,
    required this.openByPriority,
  });

  double get completionRate => total == 0 ? 0 : done / total;
  double get averagePerDay =>
      perDay.isEmpty ? 0 : doneInWindow / perDay.length;

  DayCount? get bestDay {
    DayCount? best;
    for (final d in perDay) {
      if (d.done > 0 && (best == null || d.done > best.done)) best = d;
    }
    return best;
  }

  static Insights compute(List<Task> tasks, {int days = 7, DateTime? now}) {
    final n = now ?? DateTime.now();
    final today = DateTime(n.year, n.month, n.day);
    DateTime dayOf(DateTime d) => DateTime(d.year, d.month, d.day);

    final counts = <DateTime, int>{};
    var prev = 0;
    final windowStart = today.subtract(Duration(days: days - 1));
    final prevStart = windowStart.subtract(Duration(days: days));
    for (final t in tasks) {
      final c = t.completedAt;
      if (!t.isCompleted || c == null) continue;
      final d = dayOf(c);
      if (!d.isBefore(windowStart) && !d.isAfter(today)) {
        counts[d] = (counts[d] ?? 0) + 1;
      } else if (!d.isBefore(prevStart) && d.isBefore(windowStart)) {
        prev++;
      }
    }
    final perDay = [
      for (var i = 0; i < days; i++)
        DayCount(
          DateTime(windowStart.year, windowStart.month, windowStart.day + i),
          counts[DateTime(
                windowStart.year,
                windowStart.month,
                windowStart.day + i,
              )] ??
              0,
        ),
    ];

    final catNames = <String>[
      ...TaskCategories.all,
      ...{
        for (final t in tasks)
          if (!TaskCategories.all.contains(t.category)) t.category,
      },
    ];
    final byCategory = <GroupStat>[
      for (final c in catNames)
        GroupStat(
          c,
          tasks.where((t) => t.category == c).length,
          tasks.where((t) => t.category == c && t.isCompleted).length,
        ),
    ]..removeWhere((g) => g.total == 0);

    final openByPriority = <TaskPriority, int>{
      for (final p in TaskPriority.values.reversed)
        p: tasks.where((t) => !t.isCompleted && t.priorityLevel == p).length,
    };

    final done = tasks.where((t) => t.isCompleted).length;
    return Insights(
      total: tasks.length,
      done: done,
      open: tasks.length - done,
      overdue: tasks.where((t) => t.isOverdue).length,
      dueToday: tasks.where((t) => t.isDueToday && !t.isCompleted).length,
      perDay: perDay,
      doneInWindow: perDay.fold(0, (s, d) => s + d.done),
      doneInPreviousWindow: prev,
      byCategory: byCategory,
      openByPriority: openByPriority,
    );
  }
}
