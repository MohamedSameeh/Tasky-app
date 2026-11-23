import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Friendly "nothing here" view with an optional action.
class EmptyState extends StatelessWidget {
  final IconData icon;
  final String? image;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final bool compact;

  const EmptyState({
    super.key,
    this.icon = Icons.inbox_outlined,
    this.image,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpace.xxl,
          vertical: compact ? AppSpace.xl : AppSpace.xxl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (image != null)
              Container(
                padding: const EdgeInsets.all(AppSpace.xl),
                decoration: BoxDecoration(
                  // The illustration has a white backdrop baked in.
                  color: Colors.white,
                  border: Border.all(color: context.palette.border),
                  borderRadius: BorderRadius.circular(AppRadius.xl),
                ),
                child: Image.asset(image!, height: 150),
              )
            else
              Container(
                width: compact ? 64 : 88,
                height: compact ? 64 : 88,
                decoration: BoxDecoration(
                  color: c.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: compact ? 30 : 40, color: c.primary),
              ),
            SizedBox(height: compact ? AppSpace.lg : AppSpace.xl),
            Text(
              title,
              textAlign: TextAlign.center,
              style: context.text.titleLarge,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              style: context.text.bodyMedium?.copyWith(
                color: context.palette.muted,
              ),
            ),
            if (actionLabel != null) ...[
              const SizedBox(height: AppSpace.xl),
              FilledButton.tonal(
                onPressed: onAction,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpace.sm),
                  child: Text(actionLabel!),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const ErrorState({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpace.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 88,
              height: 88,
              decoration: BoxDecoration(
                color: context.palette.danger.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.cloud_off_outlined,
                size: 40,
                color: context.palette.danger,
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            Text(
              "We couldn't load your tasks",
              textAlign: TextAlign.center,
              style: context.text.titleLarge,
            ),
            const SizedBox(height: AppSpace.sm),
            Text(
              message,
              textAlign: TextAlign.center,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: context.text.bodyMedium?.copyWith(
                color: context.palette.muted,
              ),
            ),
            const SizedBox(height: AppSpace.xl),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

/// Animated shimmer wrapper for skeleton placeholders.
class Shimmer extends StatefulWidget {
  final Widget child;
  const Shimmer({super.key, required this.child});

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1300),
  )..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = context.palette;
    return AnimatedBuilder(
      animation: _c,
      child: widget.child,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (rect) {
            final dx = rect.width * (_c.value * 2 - 1);
            return LinearGradient(
              colors: [p.skeleton, p.skeletonHighlight, p.skeleton],
              stops: const [0.35, 0.5, 0.65],
            ).createShader(rect.shift(Offset(dx, 0)));
          },
          child: child,
        );
      },
    );
  }
}

class SkeletonBox extends StatelessWidget {
  final double? width;
  final double height;
  final double radius;
  const SkeletonBox({
    super.key,
    this.width,
    this.height = 14,
    this.radius = AppRadius.sm,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: context.palette.skeleton,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// Placeholder for a list of task cards while the first snapshot loads.
class TaskListSkeleton extends StatelessWidget {
  final int count;
  final bool withHero;
  const TaskListSkeleton({super.key, this.count = 5, this.withHero = false});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading tasks',
      child: Shimmer(
        child: Column(
          children: [
            if (withHero) ...[
              const SkeletonBox(height: 132, radius: AppRadius.xl),
              const SizedBox(height: AppSpace.xl),
            ],
            for (var i = 0; i < count; i++)
              Container(
                margin: const EdgeInsets.only(bottom: AppSpace.md),
                padding: const EdgeInsets.all(AppSpace.lg),
                decoration: BoxDecoration(
                  border: Border.all(color: context.palette.border),
                  borderRadius: BorderRadius.circular(AppRadius.lg),
                ),
                child: Row(
                  children: [
                    const SkeletonBox(width: 26, height: 26, radius: 13),
                    const SizedBox(width: AppSpace.lg),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          FractionallySizedBox(
                            widthFactor: i.isEven ? 0.85 : 0.6,
                            child: const SkeletonBox(height: 15),
                          ),
                          const SizedBox(height: AppSpace.md),
                          const Row(
                            children: [
                              SkeletonBox(width: 70, height: 18, radius: 9),
                              SizedBox(width: AppSpace.sm),
                              SkeletonBox(width: 56, height: 18, radius: 9),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
