import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../data/auth_repository.dart';
import '../models/task_model.dart';
import '../state/task_store.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import 'nav.dart';
import 'profile_screen.dart';

enum TaskFilter { today, upcoming, all }

/// Home: greeting, today's progress, then Today / Upcoming / All lists.
class TodayTab extends StatefulWidget {
  final AppUser user;
  final TaskStore store;
  final VoidCallback onSearch;
  final VoidCallback onAdd;

  const TodayTab({
    super.key,
    required this.user,
    required this.store,
    required this.onSearch,
    required this.onAdd,
  });

  @override
  State<TodayTab> createState() => _TodayTabState();
}

class _TodayTabState extends State<TodayTab> {
  TaskFilter _currentFilter = TaskFilter.today;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.md,
                AppSpace.lg,
                0,
              ),
              sliver: SliverToBoxAdapter(child: _header(context)),
            ),
            if (store.error != null)
              SliverFillRemaining(
                hasScrollBody: false,
                child: ErrorState(
                  message: '${store.error}',
                  onRetry: store.retry,
                ),
              )
            else if (store.loading)
              const SliverPadding(
                padding: EdgeInsets.all(AppSpace.lg),
                sliver: SliverToBoxAdapter(
                  child: TaskListSkeleton(withHero: true),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpace.lg,
                  AppSpace.lg,
                  AppSpace.lg,
                  96,
                ),
                sliver: SliverList.list(children: _content(context)),
              ),
          ],
        );
      },
    );
  }

  Widget _header(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMMM d').format(DateTime.now()),
                style: context.text.labelLarge?.copyWith(
                  color: context.palette.muted,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${greeting()}, ${widget.user.firstName}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.headlineSmall,
              ),
            ],
          ),
        ),
        IconButton(
          tooltip: 'Search tasks',
          onPressed: widget.onSearch,
          icon: const Icon(Icons.search),
        ),
        const SizedBox(width: 2),
        Semantics(
          label: 'Profile and settings',
          button: true,
          excludeSemantics: true,
          child: InkResponse(
            radius: 26,
            onTap:
                () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ProfileScreen(user: widget.user),
                  ),
                ),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: context.colors.primary,
              child: Text(
                widget.user.initials,
                style: context.text.labelLarge?.copyWith(
                  color: context.colors.onPrimary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _content(BuildContext context) {
    final all = widget.store.tasks;
    final today = dayOnly(DateTime.now());

    final dueToday = all.where((t) => t.isDueToday).toList();
    final doneToday = dueToday.where((t) => t.isCompleted).length;
    final overdue =
        all.where((t) => t.isOverdue).toList()
          ..sort((a, b) => a.taskTime!.compareTo(b.taskTime!));

    final children = <Widget>[
      _ProgressHero(
        done: doneToday,
        total: dueToday.length,
        overdue: overdue.length,
      ),
      const SizedBox(height: AppSpace.lg),
      SizedBox(
        width: double.infinity,
        child: SegmentedButton<TaskFilter>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(value: TaskFilter.today, label: Text('Today')),
            ButtonSegment(value: TaskFilter.upcoming, label: Text('Upcoming')),
            ButtonSegment(value: TaskFilter.all, label: Text('All tasks')),
          ],
          selected: {_currentFilter},
          onSelectionChanged:
              (s) => setState(() => _currentFilter = s.first),
        ),
      ),
    ];

    int byPriority(Task a, Task b) => b.priority.compareTo(a.priority);

    switch (_currentFilter) {
      case TaskFilter.today:
        final open =
            dueToday.where((t) => !t.isCompleted).toList()..sort(byPriority);
        final done = dueToday.where((t) => t.isCompleted).toList();
        if (all.isEmpty) {
          children.add(
            EmptyState(
              image: 'assets/images/tasky_homescreen.png',
              title: 'What do you want to do today?',
              message: 'Tap + to add your first task.',
              actionLabel: 'Add a task',
              onAction: widget.onAdd,
            ),
          );
        } else if (open.isEmpty && done.isEmpty && overdue.isEmpty) {
          children.add(
            EmptyState(
              icon: Icons.wb_sunny_outlined,
              title: 'Nothing due today',
              message: 'Enjoy the breathing room, or plan something ahead.',
              actionLabel: 'Add a task',
              onAction: widget.onAdd,
            ),
          );
        } else {
          if (overdue.isNotEmpty) {
            children.add(
              SectionHeader(
                'Overdue',
                count: overdue.length,
                color: context.palette.danger,
              ),
            );
            children.addAll(overdue.map((t) => TaskRow(t)));
          }
          children.add(SectionHeader('Due today', count: open.length));
          if (open.isEmpty) {
            children.add(
              const _InlineNote(
                icon: Icons.celebration_outlined,
                text: 'All of today\'s tasks are done. Nice work.',
              ),
            );
          }
          children.addAll(open.map((t) => TaskRow(t, showDate: false)));
          if (done.isNotEmpty) {
            children.add(
              SectionHeader(
                'Completed today',
                count: done.length,
                color: context.palette.success,
              ),
            );
            children.addAll(done.map((t) => TaskRow(t, showDate: false)));
          }
        }
      case TaskFilter.upcoming:
        final upcoming =
            all
                .where(
                  (t) =>
                      !t.isCompleted &&
                      t.taskTime != null &&
                      dayOnly(t.taskTime!).isAfter(today),
                )
                .toList()
              ..sort((a, b) => a.taskTime!.compareTo(b.taskTime!));
        if (upcoming.isEmpty) {
          children.add(
            EmptyState(
              icon: Icons.event_available_outlined,
              title: 'Nothing coming up',
              message: 'Tasks with a future due date will appear here.',
              actionLabel: 'Plan a task',
              onAction: widget.onAdd,
            ),
          );
        } else {
          DateTime? current;
          for (final t in upcoming) {
            final d = dayOnly(t.taskTime!);
            if (current != d) {
              current = d;
              children.add(
                SectionHeader(
                  friendlyDay(d),
                  count: upcoming
                      .where((x) => dayOnly(x.taskTime!) == d)
                      .length,
                ),
              );
            }
            children.add(TaskRow(t, showDate: false));
          }
        }
      case TaskFilter.all:
        final open =
            all.where((t) => !t.isCompleted).toList()..sort((a, b) {
              final far = DateTime(9999);
              return (a.taskTime ?? far).compareTo(b.taskTime ?? far);
            });
        final done =
            all.where((t) => t.isCompleted).toList()..sort(
              (a, b) => (b.completedAt ?? b.createdAt).compareTo(
                a.completedAt ?? a.createdAt,
              ),
            );
        if (all.isEmpty) {
          children.add(
            EmptyState(
              image: 'assets/images/tasky_homescreen.png',
              title: 'What do you want to do today?',
              message: 'Tap + to add your first task.',
              actionLabel: 'Add a task',
              onAction: widget.onAdd,
            ),
          );
        } else {
          children.add(SectionHeader('Open', count: open.length));
          children.addAll(open.map((t) => TaskRow(t)));
          if (done.isNotEmpty) {
            children.add(
              SectionHeader(
                'Completed',
                count: done.length,
                color: context.palette.success,
              ),
            );
            children.addAll(done.map((t) => TaskRow(t)));
          }
        }
    }
    return children;
  }
}

class _InlineNote extends StatelessWidget {
  final IconData icon;
  final String text;
  const _InlineNote({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpace.md),
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.palette.success),
          const SizedBox(width: AppSpace.sm),
          Expanded(
            child: Text(
              text,
              style: context.text.bodyMedium?.copyWith(
                color: context.palette.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient card: how much of today's list is done.
class _ProgressHero extends StatelessWidget {
  final int done;
  final int total;
  final int overdue;
  const _ProgressHero({
    required this.done,
    required this.total,
    required this.overdue,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total == 0 ? 0.0 : done / total;
    final left = total - done;
    final headline =
        total == 0
            ? 'Nothing due today'
            : left == 0
            ? 'All done for today'
            : '$left ${left == 1 ? 'task' : 'tasks'} left today';
    return Container(
      padding: const EdgeInsets.all(AppSpace.lg + 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: context.palette.heroGradient,
        ),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        boxShadow: [
          BoxShadow(
            color: AppColors.brand.withValues(alpha: 0.28),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "TODAY'S PROGRESS",
                  style: context.text.labelSmall?.copyWith(
                    color: Colors.white.withValues(alpha: 0.75),
                    letterSpacing: 0.9,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  headline,
                  style: context.text.headlineSmall?.copyWith(
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: AppSpace.md),
                Wrap(
                  spacing: AppSpace.sm,
                  runSpacing: AppSpace.sm,
                  children: [
                    _HeroPill(
                      icon: Icons.check_circle_outline,
                      text: '$done of $total done',
                    ),
                    if (overdue > 0)
                      _HeroPill(
                        icon: Icons.error_outline,
                        text: '$overdue overdue',
                      ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpace.md),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: ratio),
            duration: const Duration(milliseconds: 700),
            curve: Curves.easeOutCubic,
            builder: (context, value, _) {
              return SizedBox(
                width: 76,
                height: 76,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: value,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      color: Colors.white,
                      backgroundColor: Colors.white.withValues(alpha: 0.22),
                    ),
                    Center(
                      child: Text(
                        '${(value * 100).round()}%',
                        style: context.text.titleLarge?.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String text;
  const _HeroPill({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: context.text.labelMedium?.copyWith(color: Colors.white),
          ),
        ],
      ),
    );
  }
}
