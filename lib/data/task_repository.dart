import '../models/task_model.dart';

abstract class TaskRepository {
  /// Live list of the user's tasks, newest first.
  Stream<List<Task>> watchTasks(String userId);

  /// Creates the task when [Task.id] is null, otherwise overwrites it.
  Future<void> setTask(String userId, Task task);
  Future<void> deleteTask(String userId, String taskId);
}
