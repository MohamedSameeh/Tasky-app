import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/task_repository.dart';
import '../models/task_model.dart';

/// Cloud Firestore implementation of [TaskRepository].
/// Layout: users/{uid}/tasks/{taskId}.
class FirestoreService implements TaskRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _tasks(String userId) =>
      _db.collection('users').doc(userId).collection('tasks');

  @override
  Stream<List<Task>> watchTasks(String userId) {
    return _tasks(userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map(_fromDoc).toList());
  }

  @override
  Future<void> setTask(String userId, Task task) {
    return _tasks(userId).doc(task.id).set(_toMap(task));
  }

  @override
  Future<void> deleteTask(String userId, String taskId) {
    return _tasks(userId).doc(taskId).delete();
  }

  static Task _fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Task(
      id: doc.id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      taskTime: (data['taskTime'] as Timestamp?)?.toDate(),
      priority: (data['priority'] as num?)?.toInt() ?? 0,
      isCompleted: data['isCompleted'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      category: data['category'] ?? TaskCategories.fallback,
      completedAt: (data['completedAt'] as Timestamp?)?.toDate(),
    );
  }

  static Map<String, dynamic> _toMap(Task task) {
    return {
      'title': task.title,
      'description': task.description,
      'taskTime':
          task.taskTime != null ? Timestamp.fromDate(task.taskTime!) : null,
      'priority': task.priority,
      'isCompleted': task.isCompleted,
      'createdAt': Timestamp.fromDate(task.createdAt),
      'category': task.category,
      'completedAt':
          task.completedAt != null
              ? Timestamp.fromDate(task.completedAt!)
              : null,
    };
  }
}
