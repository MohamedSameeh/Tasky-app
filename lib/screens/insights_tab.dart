import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/task_model.dart';
import '../state/insights.dart';
import '../state/task_store.dart';
import '../theme/app_theme.dart';
import '../utils/dates.dart';
import '../widgets/common.dart';
import '../widgets/state_views.dart';

/// Dashboard computed on the device from the task list: completion rate,
/// tasks finished per day, and breakdowns by category and priority.
class InsightsTab extends StatefulWidget {
  final TaskStore store;

  /// True while this tab is on screen; charts animate in when it becomes true.
  final bool active;
  const InsightsTab({super.key, required this.store, required this.active});

  @override
  State<InsightsTab> createState() => _InsightsTabState();
}

class _InsightsTabState extends State<InsightsTab> {
  int _days = 7;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final store = widget.store;
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
                  child: Text('Insights', style: context.text.headlineMedium),
                ),
                SegmentedButton<int>(
                  showSelectedIcon: false,
                  style: const ButtonStyle(
                    visualDensity: VisualDensity.compact,
                  ),
                  segments: const [
                    ButtonSegment(value: 7, label: Text('7 days')),
                    ButtonSegment(value: 14, label: Text('14 days')),
                  ],
                  selected: {_days},
                  onSelectionChanged: (s) => setState(() => _days = s.first),
                ),
              ],
            ),
            const SizedBox(height: AppSpace.lg),
            if (store.error != null)
              ErrorState(message: '${store.error}', onRetry: store.retry)
            else if (store.loading)
              const Shimmer(
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: SkeletonBox(height: 104, radius: AppRadius.lg),
                        ),
                        SizedBox(width: AppSpace.md),
                        Expanded(
                          child: SkeletonBox(height: 104, radius: AppRadius.lg),
                        ),
                      ],
                    ),
                    SizedBox(height: AppSpace.md),
                    SkeletonBox(height: 260, radius: AppRadius.lg),
                    SizedBox(height: AppSpace.md),
                    SkeletonBox(height: 220, radius: AppRadius.lg),
                  ],
                ),
              )
            else if (store.tasks.isEmpty)
              const EmptyState(
                icon: Icons.insights_outlined,
                title: 'No data yet',
                message:
                    'Add and complete a few tasks and your progress will be '
                    'charted here.',
              )
            else
              ..._dashboard(context, Insights.compute(store.tasks, days: _days)),
          ],
        );
      },
    );
  }

  List<Widget> _dashboard(BuildContext context, Insights data) {
    final p = context.palette;
    final delta = data.doneInWindow - data.doneInPreviousWindow;
    return [
      Row(
        children: [
          Expanded(
            child: _Kpi(
              icon: Icons.task_alt,
              color: context.colors.primary,
              value: '${(data.completionRate * 100).round()}%',
              label: 'Completion rate',
              caption: '${data.done} of ${data.total} tasks',
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: _Kpi(
              icon: Icons.bolt_outlined,
              color: p.success,
              value: '${data.doneInWindow}',
              label: 'Done in $_days days',
              caption:
                  delta == 0
                      ? 'Same as the $_days days before'
                      : '${delta > 0 ? '+' : ''}$delta vs previous $_days',
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.md),
      Row(
        children: [
          Expanded(
            child: _Kpi(
              icon: Icons.error_outline,
              color: p.danger,
              value: '${data.overdue}',
              label: 'Overdue',
              caption:
                  data.overdue == 0 ? 'Nothing is late' : 'Need attention',
            ),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: _Kpi(
              icon: Icons.pending_actions_outlined,
              color: p.warning,
              value: '${data.open}',
              label: 'Open tasks',
              caption: '${data.dueToday} due today',
            ),
          ),
        ],
      ),
      const SizedBox(height: AppSpace.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Tasks completed', style: context.text.titleMedium),
            const SizedBox(height: 2),
            Text(
              data.bestDay == null
                  ? 'No tasks completed in the last $_days days'
                  : '${data.averagePerDay.toStringAsFixed(1)} a day on average · '
                      'best day ${friendlyDay(data.bestDay!.day)} (${data.bestDay!.done})',
              style: context.text.bodySmall,
            ),
            const SizedBox(height: AppSpace.xl),
            SizedBox(height: 180, child: _bars(context, data)),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('By category', style: context.text.titleMedium),
            const SizedBox(height: 2),
            Text('Completed out of all tasks', style: context.text.bodySmall),
            const SizedBox(height: AppSpace.md),
            for (final g in data.byCategory) _CategoryRow(g),
          ],
        ),
      ),
      const SizedBox(height: AppSpace.md),
      AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Open tasks by priority', style: context.text.titleMedium),
            const SizedBox(height: AppSpace.lg),
            _priorityDonut(context, data),
          ],
        ),
      ),
    ];
  }

  Widget _bars(BuildContext context, Insights data) {
    final c = context.colors;
    final p = context.palette;
    final maxDone = data.perDay.fold<int>(0, (m, d) => d.done > m ? d.done : m);
    final maxY = (maxDone < 4 ? 4 : maxDone + 1).toDouble();
    final wide = data.perDay.length <= 7;
    final today = dayOnly(DateTime.now());

    return BarChart(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutCubic,
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        borderData: FlBorderData(show: false),
        gridData: FlGridData(
          drawVerticalLine: false,
          horizontalInterval: maxY > 6 ? 2 : 1,
          getDrawingHorizontalLine:
              (_) => FlLine(color: p.border, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(),
          rightTitles: const AxisTitles(),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 24,
              interval: maxY > 6 ? 2 : 1,
              getTitlesWidget:
                  (value, meta) =>
                      value == maxY && maxY.toInt().isOdd && maxY > 6
                          ? const SizedBox.shrink()
                          : Text(
                            value.toInt().toString(),
                            style: context.text.labelSmall?.copyWith(
                              color: p.muted,
                            ),
                          ),
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 26,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= data.perDay.length) {
                  return const SizedBox.shrink();
                }
                final d = data.perDay[i].day;
                final isToday = d == today;
                // 14 bars: label every other day so labels never collide.
                if (!wide && (data.perDay.length - 1 - i).isOdd) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    wide ? DateFormat('E').format(d) : DateFormat('d').format(d),
                    style: context.text.labelSmall?.copyWith(
                      color: isToday ? c.primary : p.muted,
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => c.inverseSurface,
            getTooltipItem: (group, _, rod, __) {
              final d = data.perDay[group.x];
              return BarTooltipItem(
                '${DateFormat('EEE, MMM d').format(d.day)}\n${d.done} done',
                context.text.labelMedium!.copyWith(color: c.onInverseSurface),
              );
            },
          ),
        ),
        barGroups: [
          for (var i = 0; i < data.perDay.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: widget.active ? data.perDay[i].done.toDouble() : 0,
                  width: wide ? 22 : 11,
                  borderRadius: BorderRadius.circular(wide ? 7 : 4),
                  color:
                      data.perDay[i].day == today
                          ? c.primary
                          : c.primary.withValues(alpha: 0.45),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _priorityDonut(BuildContext context, Insights data) {
    final p = context.palette;
    final entries =
        data.openByPriority.entries.where((e) => e.value > 0).toList();
    if (entries.isEmpty) {
      return Text(
        'No open tasks. Everything is done.',
        style: context.text.bodyMedium?.copyWith(color: p.muted),
      );
    }
    return Row(
      children: [
        SizedBox(
          width: 132,
          height: 132,
          child: Stack(
            alignment: Alignment.center,
            children: [
              PieChart(
                PieChartData(
                  startDegreeOffset: -90,
                  sectionsSpace: 3,
                  centerSpaceRadius: 44,
                  sections: [
                    for (final e in entries)
                      PieChartSectionData(
                        value: e.value.toDouble(),
                        color: p.priority(e.key),
                        radius: 20,
                        showTitle: false,
                      ),
                  ],
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('${data.open}', style: context.text.headlineSmall),
                  Text('open', style: context.text.bodySmall),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpace.xl),
        Expanded(
          child: Column(
            children: [
              for (final e in entries)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 5),
                  child: Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          color: p.priority(e.key),
                          borderRadius: BorderRadius.circular(3),
                        ),
                      ),
                      const SizedBox(width: AppSpace.sm),
                      Expanded(
                        child: Text(
                          e.key == TaskPriority.none
                              ? 'No priority'
                              : e.key.label,
                          style: context.text.bodyMedium,
                        ),
                      ),
                      Text('${e.value}', style: context.text.titleSmall),
                    ],
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Kpi extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String value;
  final String label;
  final String caption;
  const _Kpi({
    required this.icon,
    required this.color,
    required this.value,
    required this.label,
    required this.caption,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 18, color: color),
              ),
              const SizedBox(width: AppSpace.sm),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.text.labelMedium?.copyWith(
                    color: context.palette.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpace.md),
          Text(value, style: context.text.headlineLarge),
          const SizedBox(height: 2),
          Text(
            caption,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final GroupStat stat;
  const _CategoryRow(this.stat);

  @override
  Widget build(BuildContext context) {
    final color = context.palette.category(stat.label);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(categoryIcon(stat.label), size: 19, color: color),
          ),
          const SizedBox(width: AppSpace.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        stat.label,
                        style: context.text.titleSmall,
                      ),
                    ),
                    Text(
                      '${stat.done}/${stat.total}',
                      style: context.text.labelMedium?.copyWith(
                        color: context.palette.muted,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 7),
                TweenAnimationBuilder<double>(
                  tween: Tween(begin: 0, end: stat.rate),
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutCubic,
                  builder:
                      (context, v, _) => LinearProgressIndicator(
                        value: v,
                        minHeight: 7,
                        borderRadius: BorderRadius.circular(4),
                        color: color,
                        backgroundColor: color.withValues(alpha: 0.15),
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
