import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'data/auth_repository.dart';
import 'data/demo/demo_auth_repository.dart';
import 'data/demo/demo_task_repository.dart';
import 'data/task_repository.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/firestore_service.dart';
import 'state/task_store.dart';
import 'state/theme_controller.dart';

/// `flutter run --dart-define=DEMO=true` swaps Firebase for in-memory demo data.
const bool kDemoMode = bool.fromEnvironment('DEMO');

/// Composition root: the one place that decides which data layer the app uses.
class AppScope {
  AppScope._();

  static late final AuthRepository auth;
  static late final TaskRepository taskRepository;
  static late final TaskStore tasks;
  static final ThemeController theme = ThemeController();

  static Future<void> init() async {
    if (kDemoMode) {
      auth = DemoAuthRepository();
      taskRepository = DemoTaskRepository();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      auth = AuthService(FirebaseAuth.instance);
      taskRepository = FirestoreService();
    }
    tasks = TaskStore(taskRepository);
    await theme.load();
  }
}
