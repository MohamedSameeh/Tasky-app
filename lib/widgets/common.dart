import 'package:flutter/material.dart';
import '../models/task_model.dart';
import '../theme/app_theme.dart';

/// App icon tile. Uses the same artwork as the launcher / web icon.
class AppLogoMark extends StatelessWidget {
  final double size;
  const AppLogoMark({super.key, this.size = 56});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(size * 0.26),
      child: Image.asset(
        'assets/images/app_icon.png',
        width: size,
        height: size,
        filterQuality: FilterQuality.medium,
      ),
    );
  }
}

/// "Tasky" wordmark with the brand-colored y, as in the original app bar.
class AppWordmark extends StatelessWidget {
  final double fontSize;
  final Color? color;
  final Color? accent;
  const AppWordmark({super.key, this.fontSize = 28, this.color, this.accent});

  @override
  Widget build(BuildContext context) {
    final style = context.text.headlineMedium!.copyWith(
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: -fontSize * 0.03,
      color: color ?? context.colors.onSurface,
    );
    return Text.rich(
      TextSpan(
        children: [
          const TextSpan(text: 'Task'),
          TextSpan(
            text: 'y',
            style: TextStyle(color: accent ?? context.colors.primary),
          ),
        ],
      ),
      style: style,
    );
  }
}

/// Bordered surface used for every card in the app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppSpace.lg),
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppRadius.lg);
    return Material(
      color: context.palette.card,
      shape: RoundedRectangleBorder(
        borderRadius: radius,
        side: BorderSide(color: context.palette.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String title;
  final int? count;
  final Color? color;
  final Widget? trailing;
  const SectionHeader(
    this.title, {
    super.key,
    this.count,
    this.color,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpace.xl, bottom: AppSpace.md),
      child: Row(
        children: [
          Text(
            title,
            style: context.text.titleMedium?.copyWith(color: color),
          ),
          if (count != null) ...[
            const SizedBox(width: AppSpace.sm),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: (color ?? context.colors.primary).withValues(
                  alpha: 0.12,
                ),
                borderRadius: BorderRadius.circular(AppRadius.pill),
              ),
              child: Text(
                '$count',
                style: context.text.labelMedium?.copyWith(
                  color: color ?? context.colors.primary,
                ),
              ),
            ),
          ],
          const Spacer(),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// Small tinted label: colored dot/icon + text.
class TagChip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData? icon;
  final bool dense;
  const TagChip({
    super.key,
    required this.label,
    required this.color,
    this.icon,
    this.dense = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 8 : 12,
        vertical: dense ? 3.5 : 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: dense ? 13 : 16, color: color)
          else
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          SizedBox(width: dense ? 5 : 7),
          Text(
            label,
            style: (dense ? context.text.labelSmall : context.text.labelLarge)
                ?.copyWith(color: color, letterSpacing: 0.1),
          ),
        ],
      ),
    );
  }
}

class CategoryChip extends StatelessWidget {
  final String category;
  final bool dense;
  const CategoryChip(this.category, {super.key, this.dense = true});

  @override
  Widget build(BuildContext context) => TagChip(
    label: category,
    color: context.palette.category(category),
    icon: dense ? null : categoryIcon(category),
    dense: dense,
  );
}

class PriorityChip extends StatelessWidget {
  final TaskPriority priority;
  final bool dense;
  const PriorityChip(this.priority, {super.key, this.dense = true});

  @override
  Widget build(BuildContext context) => TagChip(
    label: priority.label,
    color: context.palette.priority(priority),
    icon: priority == TaskPriority.none ? Icons.outlined_flag : Icons.flag,
    dense: dense,
  );
}

/// Round check control used on task rows and the details screen.
class TaskCheck extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final String semanticLabel;
  final double size;
  const TaskCheck({
    super.key,
    required this.value,
    required this.onChanged,
    required this.semanticLabel,
    this.size = 26,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Semantics(
      // Own node, so the row's tap target and its checkbox stay separate.
      container: true,
      label: semanticLabel,
      button: true,
      checked: value,
      excludeSemantics: true,
      child: InkResponse(
        onTap: () => onChanged(!value),
        radius: size,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? c.primary : Colors.transparent,
              border: Border.all(
                color: value ? c.primary : c.outline,
                width: 2,
              ),
            ),
            child: AnimatedScale(
              scale: value ? 1 : 0,
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutBack,
              child: Icon(Icons.check, size: size * 0.62, color: c.onPrimary),
            ),
          ),
        ),
      ),
    );
  }
}

void showAppSnack(BuildContext context, String message, {bool error = false}) {
  final messenger = ScaffoldMessenger.of(context);
  messenger.hideCurrentSnackBar();
  messenger.showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? context.palette.danger : null,
      duration: const Duration(seconds: 3),
    ),
  );
}
