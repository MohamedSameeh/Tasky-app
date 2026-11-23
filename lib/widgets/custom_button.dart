import 'package:flutter/material.dart';

/// Full-width primary button with a built-in loading state.
class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: loading ? null : onPressed,
        style: FilledButton.styleFrom(
          disabledBackgroundColor: scheme.primary.withValues(alpha: 0.6),
          disabledForegroundColor: scheme.onPrimary,
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 180),
          child:
              loading
                  ? SizedBox(
                    key: const ValueKey('loading'),
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.4,
                      color: scheme.onPrimary,
                    ),
                  )
                  : Row(
                    key: ValueKey(text),
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(text),
                      if (icon != null) ...[
                        const SizedBox(width: 8),
                        Icon(icon, size: 20),
                      ],
                    ],
                  ),
        ),
      ),
    );
  }
}
