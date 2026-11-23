import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../state/task_query.dart';
import '../state/task_store.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/state_views.dart';
import 'nav.dart';

/// Every task, with search, status chips, a filter sheet and sorting.
class TasksTab extends StatefulWidget {
  final TaskStore store;
  final VoidCallback onAdd;
  const TasksTab({super.key, required this.store, required this.onAdd});

  @override
  State<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends State<TasksTab> {
  final _search = TextEditingController();
  TaskQuery _query = const TaskQuery();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  void _reset() {
    _search.clear();
    setState(() => _query = TaskQuery(sort: _query.sort));
  }

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<TaskQuery>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder:
          (_) => _FilterSheet(initial: _query, tasks: widget.store.tasks),
    );
    if (result != null) setState(() => _query = result);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final all = store.tasks;
        final results = _query.apply(all);
        int countFor(StatusFilter s) =>
            _query.copyWith(status: s).apply(all).length;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.md,
                AppSpace.lg,
                AppSpace.md,
              ),
              child: Text('All tasks', style: context.text.headlineMedium),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.lg),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _search,
                      onChanged:
                          (v) => setState(
                            () => _query = _query.copyWith(text: v),
                          ),
                      textInputAction: TextInputAction.search,
                      decoration: InputDecoration(
                        hintText: 'Search tasks, notes, categories',
                        prefixIcon: const Icon(Icons.search, size: 22),
                        suffixIcon:
                            _query.text.isEmpty
                                ? null
                                : IconButton(
                                  tooltip: 'Clear search',
                                  icon: const Icon(Icons.close, size: 20),
                                  onPressed: () {
                                    _search.clear();
                                    setState(
                                      () =>
                                          _query = _query.copyWith(text: ''),
                                    );
                                  },
                                ),
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpace.sm),
                  _FilterButton(
                    count: _query.sheetFilterCount,
                    onTap: _openFilters,
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 60,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpace.lg,
                  vertical: AppSpace.md,
                ),
                children: [
                  for (final s in StatusFilter.values)
                    Padding(
                      padding: const EdgeInsets.only(right: AppSpace.sm),
                      child: ChoiceChip(
                        label: Text('${s.label}  ${countFor(s)}'),
                        selected: _query.status == s,
                        onSelected:
                            (_) => setState(
                              () => _query = _query.copyWith(status: s),
                            ),
                      ),
                    ),
                ],
              ),
            ),
            if (_query.sheetFilterCount > 0) _activeFilters(context),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, 6, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      store.loading
                          ? 'Loading…'
                          : '${results.length} ${results.length == 1 ? 'task' : 'tasks'}',
                      style: context.text.labelLarge?.copyWith(
                        color: context.palette.muted,
                      ),
                    ),
                  ),
                  PopupMenuButton<TaskSort>(
                    tooltip: 'Sort tasks',
                    initialValue: _query.sort,
                    onSelected:
                        (s) => setState(
                          () => _query = _query.copyWith(sort: s),
                        ),
                    itemBuilder:
                        (_) => [
                          for (final s in TaskSort.values)
                            PopupMenuItem(value: s, child: Text(s.label)),
                        ],
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 8,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.swap_vert,
                            size: 18,
                            color: context.colors.primary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _query.sort.label,
                            style: context.text.labelLarge?.copyWith(
                              color: context.colors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _body(context, results)),
          ],
        );
      },
    );
  }

  Widget _activeFilters(BuildContext context) {
    final chips = <Widget>[
      for (final c in _query.categories)
        InputChip(
          label: Text(c),
          onDeleted:
              () => setState(
                () =>
                    _query = _query.copyWith(
                      categories: {..._query.categories}..remove(c),
                    ),
              ),
        ),
      for (final p in _query.priorities)
        InputChip(
          label: Text(p.label),
          onDeleted:
              () => setState(
                () =>
                    _query = _query.copyWith(
                      priorities: {..._query.priorities}..remove(p),
                    ),
              ),
        ),
      if (_query.dueRange != null)
        InputChip(
          label: Text(
            '${DateFormat('MMM d').format(_query.dueRange!.start)} - '
            '${DateFormat('MMM d').format(_query.dueRange!.end)}',
          ),
          onDeleted:
              () => setState(
                () => _query = _query.copyWith(clearDueRange: true),
              ),
        ),
    ];
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppSpace.lg, 0, AppSpace.lg, 8),
        itemCount: chips.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpace.sm),
        itemBuilder: (_, i) => chips[i],
      ),
    );
  }

  Widget _body(BuildContext context, List<Task> results) {
    final store = widget.store;
    if (store.error != null) {
      return ErrorState(message: '${store.error}', onRetry: store.retry);
    }
    if (store.loading) {
      return const SingleChildScrollView(
        physics: NeverScrollableScrollPhysics(),
        padding: EdgeInsets.all(AppSpace.lg),
        child: TaskListSkeleton(count: 6),
      );
    }
    if (store.tasks.isEmpty) {
      return SingleChildScrollView(
        child: EmptyState(
          image: 'assets/images/tasky_homescreen.png',
          title: 'No tasks yet',
          message: 'Add your first task and it will show up here.',
          actionLabel: 'Add a task',
          onAction: widget.onAdd,
        ),
      );
    }
    if (results.isEmpty) {
      return SingleChildScrollView(
        child: EmptyState(
          icon: Icons.search_off_outlined,
          title: 'No tasks match',
          message:
              _query.text.trim().isEmpty
                  ? 'Try removing a filter to see more tasks.'
                  : 'Nothing found for "${_query.text.trim()}". '
                      'Check the spelling or clear the filters.',
          actionLabel: 'Clear search and filters',
          onAction: _reset,
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(
        AppSpace.lg,
        AppSpace.sm,
        AppSpace.lg,
        96,
      ),
      itemCount: results.length,
      itemBuilder: (_, i) => TaskRow(results[i], key: ValueKey(results[i].id)),
    );
  }
}

class _FilterButton extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _FilterButton({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = count > 0;
    final c = context.colors;
    return Semantics(
      label: active ? 'Filters, $count active' : 'Filters',
      button: true,
      excludeSemantics: true,
      child: Material(
        color: active ? c.primary : context.palette.card,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          side: BorderSide(
            color: active ? c.primary : context.palette.border,
          ),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 52,
            height: 52,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Icon(Icons.tune, color: active ? c.onPrimary : c.onSurface),
                if (active)
                  Positioned(
                    top: 7,
                    right: 7,
                    child: Container(
                      width: 17,
                      height: 17,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: c.onPrimary,
                        shape: BoxShape.circle,
                      ),
                      child: Text(
                        '$count',
                        style: context.text.labelSmall?.copyWith(
                          color: c.primary,
                          fontSize: 10,
                          letterSpacing: 0,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FilterSheet extends StatefulWidget {
  final TaskQuery initial;
  final List<Task> tasks;
  const _FilterSheet({required this.initial, required this.tasks});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late TaskQuery _q = widget.initial;

  DateTimeRange _range(int fromDays, int toDays) {
    final today = dayOnly(DateTime.now());
    return DateTimeRange(
      start: today.add(Duration(days: fromDays)),
      end: today.add(Duration(days: toDays)),
    );
  }

  bool _same(DateTimeRange? a, DateTimeRange b) =>
      a != null && a.start == b.start && a.end == b.end;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: DateTime(now.year + 3),
      initialDateRange: _q.dueRange,
    );
    if (picked != null) setState(() => _q = _q.copyWith(dueRange: picked));
  }

  Widget _label(String text) => Padding(
    padding: const EdgeInsets.only(top: AppSpace.lg + 4, bottom: AppSpace.md),
    child: Text(text, style: context.text.titleSmall),
  );

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    final count = _q.apply(widget.tasks).length;
    final thisWeek = _range(0, 6);
    final next30 = _range(0, 29);
    final past = _range(-30, -1);
    final custom =
        _q.dueRange != null &&
        !_same(_q.dueRange, thisWeek) &&
        !_same(_q.dueRange, next30) &&
        !_same(_q.dueRange, past);

    Widget rangeChip(String label, DateTimeRange r) => FilterChip(
      label: Text(label),
      selected: _same(_q.dueRange, r),
      onSelected:
          (on) => setState(
            () =>
                _q =
                    on
                        ? _q.copyWith(dueRange: r)
                        : _q.copyWith(clearDueRange: true),
          ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpace.xl,
        0,
        AppSpace.xl,
        AppSpace.lg + MediaQuery.of(context).viewInsets.bottom,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Filter and sort',
                    style: context.text.headlineSmall,
                  ),
                ),
                TextButton(
                  onPressed:
                      () => setState(
                        () =>
                            _q = TaskQuery(text: _q.text, status: _q.status),
                      ),
                  child: const Text('Reset'),
                ),
              ],
            ),
            _label('Category'),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final c in TaskCategories.all)
                  FilterChip(
                    avatar: Icon(
                      categoryIcon(c),
                      size: 16,
                      color: p.category(c),
                    ),
                    label: Text(c),
                    selected: _q.categories.contains(c),
                    onSelected:
                        (on) => setState(() {
                          final next = {..._q.categories};
                          on ? next.add(c) : next.remove(c);
                          _q = _q.copyWith(categories: next);
                        }),
                  ),
              ],
            ),
            _label('Priority'),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final pr in TaskPriority.values.reversed)
                  if (pr != TaskPriority.none)
                    FilterChip(
                      avatar: Icon(Icons.flag, size: 16, color: p.priority(pr)),
                      label: Text(pr.label),
                      selected: _q.priorities.contains(pr),
                      onSelected:
                          (on) => setState(() {
                            final next = {..._q.priorities};
                            on ? next.add(pr) : next.remove(pr);
                            _q = _q.copyWith(priorities: next);
                          }),
                    ),
              ],
            ),
            _label('Due date'),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                rangeChip('Next 7 days', thisWeek),
                rangeChip('Next 30 days', next30),
                rangeChip('Past 30 days', past),
                FilterChip(
                  avatar: const Icon(Icons.date_range, size: 16),
                  label: Text(
                    custom
                        ? '${DateFormat('MMM d').format(_q.dueRange!.start)} - '
                            '${DateFormat('MMM d').format(_q.dueRange!.end)}'
                        : 'Custom range',
                  ),
                  selected: custom,
                  onSelected: (_) => _pickRange(),
                ),
              ],
            ),
            _label('Sort by'),
            Wrap(
              spacing: AppSpace.sm,
              runSpacing: AppSpace.sm,
              children: [
                for (final s in TaskSort.values)
                  ChoiceChip(
                    label: Text(s.label),
                    selected: _q.sort == s,
                    onSelected:
                        (_) => setState(() => _q = _q.copyWith(sort: s)),
                  ),
              ],
            ),
            const SizedBox(height: AppSpace.xl),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context, _q),
                child: Text('Show $count ${count == 1 ? 'task' : 'tasks'}'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
