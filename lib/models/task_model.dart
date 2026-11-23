/// Priority levels. Stored in Firestore as the int [value] in the existing
/// `priority` field (legacy documents used 1-10; anything above 4 reads as urgent).
enum TaskPriority {
  none(0, 'No priority'),
  low(1, 'Low'),
  medium(2, 'Medium'),
  high(3, 'High'),
  urgent(4, 'Urgent');

  const TaskPriority(this.value, this.label);
  final int value;
  final String label;

  static TaskPriority fromValue(int v) {
    if (v <= 0) return TaskPriority.none;
    if (v >= 4) return TaskPriority.urgent;
    return TaskPriority.values[v];
  }
}

/// Built-in categories a small business would recognise.
class TaskCategories {
  static const orders = 'Orders';
  static const marketing = 'Marketing';
  static const suppliers = 'Suppliers';
  static const finance = 'Finance';
  static const personal = 'Personal';
  static const all = [orders, marketing, suppliers, finance, personal];
  static const fallback = personal;
}

class Task {
  final String? id;
  final String title;
  final String description;
  final DateTime? taskTime;
  final int priority;
  final bool isCompleted;
  final DateTime createdAt;
  final String category;
  final DateTime? completedAt;

  const Task({
    this.id,
    required this.title,
    this.description = '',
    this.taskTime,
    this.priority = 0,
    this.isCompleted = false,
    required this.createdAt,
    this.category = TaskCategories.fallback,
    this.completedAt,
  });

  TaskPriority get priorityLevel => TaskPriority.fromValue(priority);

  /// Open and due before today.
  bool get isOverdue {
    if (isCompleted || taskTime == null) return false;
    final n = DateTime.now();
    return taskTime!.isBefore(DateTime(n.year, n.month, n.day));
  }

  bool get isDueToday {
    if (taskTime == null) return false;
    final n = DateTime.now();
    return taskTime!.year == n.year &&
        taskTime!.month == n.month &&
        taskTime!.day == n.day;
  }

  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? taskTime,
    bool clearTaskTime = false,
    int? priority,
    bool? isCompleted,
    String? category,
    DateTime? completedAt,
    bool clearCompletedAt = false,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      taskTime: clearTaskTime ? null : (taskTime ?? this.taskTime),
      priority: priority ?? this.priority,
      isCompleted: isCompleted ?? this.isCompleted,
      createdAt: createdAt,
      category: category ?? this.category,
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
    );
  }

  /// Marks done/undone and stamps the completion time used by Insights.
  Task toggled(bool done) => copyWith(
    isCompleted: done,
    completedAt: done ? DateTime.now() : null,
    clearCompletedAt: !done,
  );
}
