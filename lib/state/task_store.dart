import 'dart:async';
import 'package:flutter/foundation.dart';
import '../data/task_repository.dart';
import '../models/task_model.dart';

/// One shared subscription to the signed-in user's tasks. Every tab listens to
/// this store instead of opening its own stream.
class TaskStore extends ChangeNotifier {
  TaskStore(this._repository);

  final TaskRepository _repository;
  StreamSubscription<List<Task>>? _sub;
  String? _userId;

  List<Task> _tasks = const [];
  bool _loading = true;
  Object? _error;

  List<Task> get tasks => _tasks;
  bool get loading => _loading;
  Object? get error => _error;

  /// Starts (or restarts) listening for [userId]'s tasks.
  void bind(String userId) {
    if (_userId == userId && _sub != null) return;
    _userId = userId;
    // Called while the auth gate builds, so do not notify synchronously.
    _listen(notify: false);
  }

  void retry() {
    if (_userId != null) _listen();
  }

  void _listen({bool notify = true}) {
    _sub?.cancel();
    _loading = true;
    _error = null;
    if (notify) notifyListeners();
    _sub = _repository
        .watchTasks(_userId!)
        .listen(
          (list) {
            _tasks = list;
            _loading = false;
            _error = null;
            notifyListeners();
          },
          onError: (Object e) {
            _loading = false;
            _error = e;
            notifyListeners();
          },
        );
  }

  /// Called on sign-out.
  void unbind() {
    _sub?.cancel();
    _sub = null;
    _userId = null;
    _tasks = const [];
    _loading = true;
    _error = null;
  }

  Task? byId(String? id) {
    if (id == null) return null;
    for (final t in _tasks) {
      if (t.id == id) return t;
    }
    return null;
  }

  Future<void> save(Task task) => _repository.setTask(_userId!, task);

  Future<void> toggle(Task task, bool done) =>
      _repository.setTask(_userId!, task.toggled(done));

  Future<void> delete(Task task) => _repository.deleteTask(_userId!, task.id!);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
