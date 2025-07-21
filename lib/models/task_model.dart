import 'package:cloud_firestore/cloud_firestore.dart';

class Task {
  final String? id;
  final String title;
  final String description;
  final DateTime? taskTime;
  final int priority;
  final bool isCompleted;
  final Timestamp createdAt;

  Task({
    this.id,
    required this.title,
    this.description = '',
    this.taskTime,
    this.priority = 0,
    this.isCompleted = false,
    required this.createdAt,
  });

  factory Task.fromFirestore(DocumentSnapshot doc) {
    Map data = doc.data() as Map<String, dynamic>;
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      taskTime: (data['taskTime'] as Timestamp?)?.toDate(),
      priority: data['priority'] ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: data['createdAt'] ?? Timestamp.now(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'taskTime': taskTime != null ? Timestamp.fromDate(taskTime!) : null,
      'priority': priority,
      'isCompleted': isCompleted,
      'createdAt': createdAt,
    };
  }
}
