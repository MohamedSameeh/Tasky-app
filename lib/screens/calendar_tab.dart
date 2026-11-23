import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';
import '../models/task_model.dart';
import '../state/task_store.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';
import 'nav.dart';

/// Month / week calendar with a dot per task and the selected day's list.
class CalendarTab extends StatefulWidget {
  final TaskStore store;
  final VoidCallback onAdd;
  final ValueChanged<DateTime> onDayChanged;

  const CalendarTab({
    super.key,
    required this.store,
    required this.onAdd,
    required this.onDayChanged,
  });

  @override
  State<CalendarTab> createState() => _CalendarTabState();
}

class _CalendarTabState extends State<CalendarTab> {
  DateTime _selected = dayOnly(DateTime.now());
  DateTime _focused = DateTime.now();
  CalendarFormat _format = CalendarFormat.month;

  @override
  void initState() {
    super.initState();
    widget.onDayChanged(_selected);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
        final byDay = <DateTime, List<Task>>{};
        for (final t in store.tasks) {
          if (t.taskTime == null) continue;
          byDay.putIfAbsent(dayOnly(t.taskTime!), () => []).add(t);
        }
        final dayTasks = List<Task>.of(byDay[_selected] ?? const [])..sort((
          a,
          b,
        ) {
          if (a.isCompleted != b.isCompleted) return a.isCompleted ? 1 : -1;
          return b.priority.compareTo(a.priority);
        });
        final open = dayTasks.where((t) => !t.isCompleted).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.md,
            AppSpace.lg,
            96,
          ),
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('Calendar', style: context.text.headlineMedium),
                ),
                TextButton.icon(
                  onPressed: () {
                    final now = DateTime.now();
                    setState(() {
                      _selected = dayOnly(now);
                      _focused = now;
                    });
                    widget.onDayChanged(_selected);
                  },
                  icon: const Icon(Icons.today_outlined, size: 18),
                  label: const Text('Today'),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.md),
            AppCard(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 12),
              child: _calendar(context, byDay),
            ),
            SectionHeader(
              friendlyDay(_selected) == 'Today'
                  ? 'Today, ${DateFormat('MMM d').format(_selected)}'
                  : DateFormat('EEEE, MMM d').format(_selected),
              trailing:
                  dayTasks.isEmpty
                      ? null
                      : Text(
                        open == 0
                            ? 'All done'
                            : '$open open of ${dayTasks.length}',
                        style: context.text.labelMedium?.copyWith(
                          color: context.palette.muted,
                        ),
                      ),
            ),
            if (store.loading)
              const TaskListSkeleton(count: 3)
            else if (store.error != null)
              ErrorState(message: '${store.error}', onRetry: store.retry)
            else if (dayTasks.isEmpty)
              EmptyState(
                compact: true,
                icon: Icons.event_available_outlined,
                title: 'A clear day',
                message: 'Nothing is planned for this date yet.',
                actionLabel: 'Add a task for this day',
                onAction: widget.onAdd,
              )
            else
              ...dayTasks.map((t) => TaskRow(t, showDate: false)),
          ],
        );
      },
    );
  }

  Widget _calendar(BuildContext context, Map<DateTime, List<Task>> byDay) {
    final c = context.colors;
    final p = context.palette;
    final dayStyle = context.text.bodyMedium!;
    BoxDecoration cell(Color? fill, {Color? border}) => BoxDecoration(
      color: fill,
      shape: BoxShape.circle,
      border: border == null ? null : Border.all(color: border, width: 1.5),
    );

    return TableCalendar<Task>(
      focusedDay: _focused,
      firstDay: DateTime(2000),
      lastDay: DateTime(2100),
      calendarFormat: _format,
      startingDayOfWeek: StartingDayOfWeek.monday,
      availableCalendarFormats: const {
        CalendarFormat.month: 'Month',
        CalendarFormat.week: 'Week',
      },
      rowHeight: 52,
      daysOfWeekHeight: 26,
      availableGestures: AvailableGestures.horizontalSwipe,
      selectedDayPredicate: (day) => isSameDay(_selected, day),
      eventLoader: (day) => byDay[dayOnly(day)] ?? const [],
      onDaySelected: (selectedDay, focusedDay) {
        setState(() {
          _selected = dayOnly(selectedDay);
          _focused = focusedDay;
        });
        widget.onDayChanged(_selected);
      },
      onFormatChanged: (f) => setState(() => _format = f),
      onPageChanged: (focusedDay) => _focused = focusedDay,
      headerStyle: HeaderStyle(
        titleTextStyle: context.text.titleMedium!,
        formatButtonShowsNext: false,
        formatButtonTextStyle: context.text.labelMedium!.copyWith(
          color: c.primary,
        ),
        formatButtonDecoration: BoxDecoration(
          color: c.primaryContainer,
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
        formatButtonPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 5,
        ),
        leftChevronIcon: Icon(Icons.chevron_left, color: c.onSurface),
        rightChevronIcon: Icon(Icons.chevron_right, color: c.onSurface),
        leftChevronPadding: const EdgeInsets.all(8),
        rightChevronPadding: const EdgeInsets.all(8),
        leftChevronMargin: EdgeInsets.zero,
        rightChevronMargin: const EdgeInsets.only(left: 4),
        headerPadding: const EdgeInsets.symmetric(vertical: 4),
      ),
      daysOfWeekStyle: DaysOfWeekStyle(
        weekdayStyle: context.text.labelSmall!.copyWith(color: p.muted),
        weekendStyle: context.text.labelSmall!.copyWith(color: p.muted),
      ),
      calendarStyle: CalendarStyle(
        outsideDaysVisible: false,
        cellMargin: const EdgeInsets.fromLTRB(6, 2, 6, 11),
        defaultTextStyle: dayStyle,
        weekendTextStyle: dayStyle,
        selectedTextStyle: context.text.titleSmall!.copyWith(
          color: c.onPrimary,
        ),
        todayTextStyle: context.text.titleSmall!.copyWith(color: c.primary),
        selectedDecoration: cell(c.primary),
        todayDecoration: cell(null, border: c.primary),
      ),
      calendarBuilders: CalendarBuilders(
        markerBuilder: (context, day, tasks) {
          if (tasks.isEmpty) return null;
          final open = tasks.where((t) => !t.isCompleted).length;
          final hasOverdue = tasks.any((t) => t.isOverdue);
          final dots = open == 0 ? 1 : open.clamp(1, 3);
          final color =
              open == 0 ? p.success : (hasOverdue ? p.danger : c.primary);
          return Positioned(
            bottom: 2,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var i = 0; i < dots; i++)
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.symmetric(horizontal: 1.2),
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }
}
