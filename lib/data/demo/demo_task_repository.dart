import 'dart:async';
import '../../models/task_model.dart';
import '../task_repository.dart';

/// In-memory task store seeded with a small studio/shop's workload.
/// All dates are relative to "now" so the demo always looks current.
class DemoTaskRepository implements TaskRepository {
  DemoTaskRepository() : _tasks = _seed();

  final List<Task> _tasks;
  final _controller = StreamController<List<Task>>.broadcast();
  int _nextId = 1000;

  List<Task> get _snapshot {
    final list = List<Task>.of(_tasks);
    list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return List.unmodifiable(list);
  }

  @override
  Stream<List<Task>> watchTasks(String userId) async* {
    // Small delay so the loading skeleton is visible, like a first network read.
    await Future<void>.delayed(const Duration(milliseconds: 900));
    yield _snapshot;
    yield* _controller.stream;
  }

  @override
  Future<void> setTask(String userId, Task task) async {
    if (task.id == null) {
      _tasks.add(task.copyWith(id: 'demo-${_nextId++}'));
    } else {
      final i = _tasks.indexWhere((t) => t.id == task.id);
      if (i >= 0) {
        _tasks[i] = task;
      } else {
        _tasks.add(task);
      }
    }
    _controller.add(_snapshot);
  }

  @override
  Future<void> deleteTask(String userId, String taskId) async {
    _tasks.removeWhere((t) => t.id == taskId);
    _controller.add(_snapshot);
  }

  static List<Task> _seed() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    var n = 0;

    Task t(
      String title,
      String category,
      TaskPriority priority,
      int? dueIn, {
      int? doneAgo,
      String notes = '',
      int createdAgo = 3,
    }) {
      n++;
      final due = dueIn == null ? null : today.add(Duration(days: dueIn));
      // Spread completions through the working day.
      final completedAt =
          doneAgo == null
              ? null
              : today
                  .subtract(Duration(days: doneAgo))
                  .add(Duration(hours: 9 + (n % 8), minutes: (n * 7) % 60));
      return Task(
        id: 'demo-$n',
        title: title,
        description: notes,
        category: category,
        priority: priority.value,
        taskTime: due,
        isCompleted: doneAgo != null,
        completedAt:
            completedAt != null && completedAt.isAfter(now)
                ? now.subtract(const Duration(minutes: 5))
                : completedAt,
        createdAt: today
            .subtract(Duration(days: (doneAgo ?? 0) + createdAgo))
            .add(Duration(hours: 8, minutes: n)),
      );
    }

    const o = TaskCategories.orders;
    const m = TaskCategories.marketing;
    const s = TaskCategories.suppliers;
    const f = TaskCategories.finance;
    const p = TaskCategories.personal;

    return [
      // ---- Due today
      t(
        'Pack and ship order #1042',
        o,
        TaskPriority.high,
        0,
        notes:
            'Three speckled mugs, gift wrapped. Add a handwritten thank-you '
            'card and the care leaflet. Courier collects at 3 pm.',
        createdAgo: 1,
      ),
      t(
        'Call clay supplier about delayed delivery',
        s,
        TaskPriority.urgent,
        0,
        notes:
            'The 250 kg stoneware order was due last Thursday. Ask for a firm '
            'delivery date and whether they can split the shipment.',
        createdAgo: 2,
      ),
      t(
        'Send invoice to cafe wholesale account',
        f,
        TaskPriority.high,
        0,
        notes: '40 espresso cups + 40 saucers. Net 14 days. Attach delivery note.',
        createdAgo: 2,
      ),
      t(
        'Schedule this week\'s social posts',
        m,
        TaskPriority.medium,
        0,
        notes: 'Mon: kiln opening video. Wed: new glaze close-ups. Fri: market reminder.',
        createdAgo: 4,
      ),
      t(
        'Reply to custom dinner set request',
        o,
        TaskPriority.medium,
        0,
        notes: 'Customer wants 6 place settings in matte white. Quote price and a 5 week lead time.',
        createdAgo: 1,
      ),
      t('Print shipping labels for weekend orders', o, TaskPriority.medium, 0, doneAgo: 0, createdAgo: 1),
      t('Confirm courier pickup time', s, TaskPriority.low, 0, doneAgo: 0, createdAgo: 1),

      // ---- Overdue
      t(
        'Refund order #1031 (arrived chipped)',
        o,
        TaskPriority.urgent,
        -1,
        notes: 'Customer sent photos. Refund in full and offer a replacement bowl at cost.',
        createdAgo: 3,
      ),
      t(
        'Plan holiday sale discount codes',
        m,
        TaskPriority.high,
        -2,
        notes: 'Decide: 15% site-wide or free shipping over a minimum spend. Codes must be live by Friday.',
        createdAgo: 6,
      ),
      t(
        'Reconcile October card payments',
        f,
        TaskPriority.medium,
        -3,
        notes: 'Match payouts against the order export. Two payouts still unmatched.',
        createdAgo: 9,
      ),

      // ---- Upcoming
      t(
        'Write November newsletter: gift guide',
        m,
        TaskPriority.high,
        1,
        notes: 'Feature the mug sets, the small vases and gift cards. Send Tuesday 9 am.',
        createdAgo: 5,
      ),
      t('Order glaze: celadon and matte white', s, TaskPriority.medium, 1, notes: '5 kg of each. Check for the bulk discount.', createdAgo: 2),
      t('Restock boxes and tissue paper', o, TaskPriority.low, 2, createdAgo: 4),
      t('Book dentist appointment', p, TaskPriority.low, 2, createdAgo: 8),
      t(
        'Photograph new glaze collection',
        o,
        TaskPriority.medium,
        3,
        notes: 'Natural light by the window, linen backdrop. 12 products, 3 angles each.',
        createdAgo: 3,
      ),
      t('Design flyer for winter pop-up market', m, TaskPriority.medium, 4, notes: 'A5, print 200 copies. Include stall number and dates.', createdAgo: 4),
      t('Compare quotes for new kiln shelves', s, TaskPriority.low, 5, createdAgo: 6),
      t('Pay studio rent', f, TaskPriority.high, 6, createdAgo: 10),
      t(
        'File quarterly sales tax return',
        f,
        TaskPriority.urgent,
        9,
        notes: 'Export sales by region first. Accountant needs the figures two days before the deadline.',
        createdAgo: 7,
      ),
      t('Renew studio insurance', p, TaskPriority.medium, 12, createdAgo: 5),
      t('Draft spring workshop schedule', p, TaskPriority.none, null, notes: 'No date yet. Ideas: wheel throwing basics, glazing evening.', createdAgo: 2),

      // ---- Completed over the last two weeks
      t('Update stock counts after Saturday market', o, TaskPriority.medium, -1, doneAgo: 1),
      t('Reply to new product reviews', m, TaskPriority.low, -1, doneAgo: 1),
      t('Send tracking numbers to wholesale customer', o, TaskPriority.high, -2, doneAgo: 2),
      t('Chase unpaid invoice #207', f, TaskPriority.high, -2, doneAgo: 2),
      t('Post market stall photos', m, TaskPriority.low, -2, doneAgo: 2),
      t('Ship order #1038', o, TaskPriority.high, -3, doneAgo: 3),
      t('Pick up kiln parts from the post office', p, TaskPriority.low, -3, doneAgo: 3),
      t('Update shop banner for holiday sale', m, TaskPriority.medium, -4, doneAgo: 4),
      t('Ship order #1035 and #1036', o, TaskPriority.high, -4, doneAgo: 4),
      t('Negotiate bulk price for packaging', s, TaskPriority.medium, -4, doneAgo: 4),
      t('Return faulty batch of cork lids', s, TaskPriority.medium, -5, doneAgo: 5),
      t('Export sales report for accountant', f, TaskPriority.medium, -6, doneAgo: 6),
      t('Prepare for Saturday pottery class', p, TaskPriority.medium, -7, doneAgo: 7),
      t('Renew shop domain name', f, TaskPriority.high, -8, doneAgo: 8),
      t('Reorganise the glaze shelf', p, TaskPriority.low, -9, doneAgo: 9),
      t('Update wholesale price list', f, TaskPriority.medium, -10, doneAgo: 10),
      t('Order bubble wrap and tape', s, TaskPriority.low, -10, doneAgo: 10),
      t('Send samples to boutique stockist', o, TaskPriority.medium, -11, doneAgo: 11),
      t('Write product descriptions for new mugs', m, TaskPriority.medium, -12, doneAgo: 12),
    ];
  }
}
