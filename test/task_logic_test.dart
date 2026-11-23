import 'package:flutter/material.dart' show DateTimeRange;
import 'package:flutter_test/flutter_test.dart';
import 'package:tasky_app/data/demo/demo_task_repository.dart';
import 'package:tasky_app/models/task_model.dart';
import 'package:tasky_app/state/insights.dart';
import 'package:tasky_app/state/task_query.dart';

void main() {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  Task task(
    String title, {
    String category = TaskCategories.orders,
    TaskPriority priority = TaskPriority.none,
    int? dueIn,
    int? doneAgo,
  }) => Task(
    id: title,
    title: title,
    category: category,
    priority: priority.value,
    taskTime: dueIn == null ? null : today.add(Duration(days: dueIn)),
    isCompleted: doneAgo != null,
    completedAt:
        doneAgo == null
            ? null
            : today.subtract(Duration(days: doneAgo)).add(
              const Duration(hours: 1),
            ),
    createdAt: today.subtract(const Duration(days: 20)),
  );

  final tasks = [
    task('Ship order', priority: TaskPriority.high, dueIn: 0),
    task('Refund order', priority: TaskPriority.urgent, dueIn: -2),
    task('Pay rent', category: TaskCategories.finance, dueIn: 5),
    task('Send invoice', category: TaskCategories.finance, doneAgo: 0),
    task('Write newsletter', category: TaskCategories.marketing, doneAgo: 3),
    task('Old job', category: TaskCategories.marketing, doneAgo: 9),
  ];

  group('TaskQuery', () {
    test('search matches title and category, case-insensitive', () {
      expect(const TaskQuery(text: 'ORDER').apply(tasks).length, 2);
      expect(const TaskQuery(text: 'finance').apply(tasks).length, 2);
      expect(const TaskQuery(text: 'zzz').apply(tasks), isEmpty);
    });

    test('status filters', () {
      expect(const TaskQuery(status: StatusFilter.open).apply(tasks).length, 3);
      expect(const TaskQuery(status: StatusFilter.done).apply(tasks).length, 3);
      final overdue = const TaskQuery(status: StatusFilter.overdue).apply(tasks);
      expect(overdue.single.title, 'Refund order');
    });

    test('category, priority and date range combine', () {
      final q = TaskQuery(
        categories: const {TaskCategories.orders},
        priorities: const {TaskPriority.high, TaskPriority.urgent},
        dueRange: DateTimeRange(
          start: today,
          end: today.add(const Duration(days: 6)),
        ),
      );
      expect(q.apply(tasks).single.title, 'Ship order');
      expect(q.sheetFilterCount, 4);
    });

    test('priority sort puts urgent open tasks first', () {
      final sorted = const TaskQuery(sort: TaskSort.priority).apply(tasks);
      expect(sorted.first.title, 'Refund order');
      expect(sorted.last.isCompleted, isTrue);
    });
  });

  group('Insights', () {
    test('totals, overdue and per-day counts', () {
      final i = Insights.compute(tasks, days: 7);
      expect(i.total, 6);
      expect(i.done, 3);
      expect(i.completionRate, 0.5);
      expect(i.overdue, 1);
      expect(i.perDay.length, 7);
      expect(i.perDay.last.done, 1); // today
      expect(i.doneInWindow, 2);
      expect(i.doneInPreviousWindow, 1);
      expect(i.openByPriority[TaskPriority.urgent], 1);
      final finance = i.byCategory.firstWhere((g) => g.label == 'Finance');
      expect((finance.total, finance.done), (2, 1));
    });
  });

  test('demo repository creates, updates and deletes', () async {
    final repo = DemoTaskRepository();
    final first = await repo.watchTasks('u').first;
    expect(first.length, greaterThan(25));

    await repo.setTask('u', task('Brand new'));
    final added = await repo.watchTasks('u').first;
    expect(added.any((t) => t.title == 'Brand new'), isTrue);

    await repo.deleteTask('u', 'Brand new');
    final removed = await repo.watchTasks('u').first;
    expect(removed.any((t) => t.title == 'Brand new'), isFalse);
  });
}
