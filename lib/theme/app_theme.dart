import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/task_model.dart';

/// Spacing scale (dp).
class AppSpace {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;
}

/// Corner radius scale (dp).
class AppRadius {
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double pill = 999;
}

/// Raw color tokens. Widgets should read colors from the theme
/// (`Theme.of(context).colorScheme` / `context.palette`), not from here.
class AppColors {
  /// Tasky's brand purple, taken from the original UI.
  static const brand = Color(0xFF6200EE);
  static const brandDeep = Color(0xFF4A148C);
  static const brandOnDark = Color(0xFFB79CFF);

  static const success = Color(0xFF12A56B);
  static const warning = Color(0xFFE08A00);
  static const danger = Color(0xFFD93A4A);
  static const info = Color(0xFF2F7DE1);
}

/// Semantic colors that Material's [ColorScheme] has no slot for.
@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color muted;
  final Color border;
  final Color card;
  final Color skeleton;
  final Color skeletonHighlight;
  final List<Color> heroGradient;

  const AppPalette({
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.muted,
    required this.border,
    required this.card,
    required this.skeleton,
    required this.skeletonHighlight,
    required this.heroGradient,
  });

  static const light = AppPalette(
    success: AppColors.success,
    warning: AppColors.warning,
    danger: AppColors.danger,
    info: AppColors.info,
    muted: Color(0xFF6E6A7C),
    border: Color(0xFFE7E4EF),
    card: Colors.white,
    skeleton: Color(0xFFECE9F3),
    skeletonHighlight: Color(0xFFF8F7FB),
    heroGradient: [Color(0xFF6200EE), Color(0xFF8E3DFF)],
  );

  static const dark = AppPalette(
    success: Color(0xFF3DD69A),
    warning: Color(0xFFFFB74A),
    danger: Color(0xFFFF6B78),
    info: Color(0xFF6CAEFF),
    muted: Color(0xFFA29DB3),
    border: Color(0xFF2E2A3A),
    card: Color(0xFF1C1925),
    skeleton: Color(0xFF262231),
    skeletonHighlight: Color(0xFF332E41),
    heroGradient: [Color(0xFF4A12B8), Color(0xFF7B3BEA)],
  );

  Color category(String name) {
    switch (name) {
      case TaskCategories.orders:
        return info;
      case TaskCategories.marketing:
        return const Color(0xFFE0569B);
      case TaskCategories.suppliers:
        return warning;
      case TaskCategories.finance:
        return success;
      default:
        return const Color(0xFF8A63F5);
    }
  }

  Color priority(TaskPriority p) {
    switch (p) {
      case TaskPriority.urgent:
        return danger;
      case TaskPriority.high:
        return warning;
      case TaskPriority.medium:
        return info;
      case TaskPriority.low:
        return success;
      case TaskPriority.none:
        return muted;
    }
  }

  @override
  AppPalette copyWith() => this;

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return t < 0.5 ? this : other;
  }
}

extension AppThemeX on BuildContext {
  AppPalette get palette => Theme.of(this).extension<AppPalette>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
}

IconData categoryIcon(String name) {
  switch (name) {
    case TaskCategories.orders:
      return Icons.inventory_2_outlined;
    case TaskCategories.marketing:
      return Icons.campaign_outlined;
    case TaskCategories.suppliers:
      return Icons.local_shipping_outlined;
    case TaskCategories.finance:
      return Icons.receipt_long_outlined;
    default:
      return Icons.person_outline;
  }
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final palette = isDark ? AppPalette.dark : AppPalette.light;

    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
    ).copyWith(
      primary: isDark ? AppColors.brandOnDark : AppColors.brand,
      onPrimary: isDark ? const Color(0xFF22005D) : Colors.white,
      primaryContainer:
          isDark ? const Color(0xFF34225C) : const Color(0xFFEDE4FF),
      onPrimaryContainer:
          isDark ? const Color(0xFFE6DBFF) : const Color(0xFF2A0A6B),
      surface: isDark ? const Color(0xFF131118) : const Color(0xFFF7F6FB),
      onSurface: isDark ? const Color(0xFFECE9F4) : const Color(0xFF17141F),
      onSurfaceVariant: palette.muted,
      surfaceContainerLowest: palette.card,
      surfaceContainerLow: palette.card,
      surfaceContainer:
          isDark ? const Color(0xFF201D2A) : const Color(0xFFF1EFF7),
      surfaceContainerHigh:
          isDark ? const Color(0xFF272332) : const Color(0xFFEBE8F3),
      surfaceContainerHighest:
          isDark ? const Color(0xFF2E2A3A) : const Color(0xFFE5E1EF),
      outline: isDark ? const Color(0xFF575168) : const Color(0xFFB9B4C7),
      outlineVariant: palette.border,
      error: palette.danger,
    );

    // Type scale: Inter. Each style asks google_fonts for its real weight
    // (copyWith(fontWeight:) on a Google font would not load that weight).
    TextStyle s(
      double size,
      FontWeight weight, {
      double? height,
      double spacing = 0,
      Color? color,
    }) => GoogleFonts.inter(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: spacing,
      color: color ?? scheme.onSurface,
    );
    const w4 = FontWeight.w400, w6 = FontWeight.w600;
    const w7 = FontWeight.w700, w8 = FontWeight.w800;
    final textTheme = TextTheme(
      displayLarge: s(48, w8, height: 1.1, spacing: -1.4),
      displayMedium: s(40, w8, height: 1.1, spacing: -1.2),
      displaySmall: s(34, w8, height: 1.15, spacing: -1),
      headlineLarge: s(32, w8, height: 1.15, spacing: -0.8),
      headlineMedium: s(26, w8, height: 1.2, spacing: -0.6),
      headlineSmall: s(22, w7, height: 1.25, spacing: -0.4),
      titleLarge: s(18, w7, height: 1.3, spacing: -0.2),
      titleMedium: s(16, w6, height: 1.35, spacing: -0.1),
      titleSmall: s(14, w6, height: 1.35),
      bodyLarge: s(16, w4, height: 1.45),
      bodyMedium: s(14, w4, height: 1.45),
      bodySmall: s(12.5, w4, height: 1.4, color: palette.muted),
      labelLarge: s(14, w6),
      labelMedium: s(12, w6),
      labelSmall: s(11, w6, spacing: 0.3),
    );

    OutlineInputBorder inputBorder(Color c, [double w = 1]) =>
        OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: c, width: w),
        );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      primaryColor: scheme.primary,
      scaffoldBackgroundColor: scheme.surface,
      textTheme: textTheme,
      extensions: [palette],
      splashFactory: InkSparkle.splashFactory,
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.windows: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.macOS: FadeForwardsPageTransitionsBuilder(),
          TargetPlatform.linux: FadeForwardsPageTransitionsBuilder(),
        },
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        foregroundColor: scheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: textTheme.titleLarge,
      ),
      cardTheme: CardThemeData(
        color: palette.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg),
          side: BorderSide(color: palette.border),
        ),
      ),
      dividerTheme: DividerThemeData(color: palette.border, thickness: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: palette.card,
        hintStyle: textTheme.bodyMedium?.copyWith(color: palette.muted),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpace.lg,
          vertical: 14,
        ),
        border: inputBorder(palette.border),
        enabledBorder: inputBorder(palette.border),
        focusedBorder: inputBorder(scheme.primary, 1.6),
        errorBorder: inputBorder(palette.danger),
        focusedErrorBorder: inputBorder(palette.danger, 1.6),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(64, 52),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(64, 52),
          textStyle: textTheme.labelLarge?.copyWith(fontSize: 16),
          side: BorderSide(color: palette.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.md + 2),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(textStyle: textTheme.labelLarge),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: scheme.primary,
        foregroundColor: scheme.onPrimary,
        elevation: 3,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.lg + 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: scheme.primaryContainer,
        height: 68,
        elevation: 0,
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => textTheme.labelMedium?.copyWith(
            color:
                states.contains(WidgetState.selected)
                    ? scheme.primary
                    : palette.muted,
          ),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            size: 24,
            color:
                states.contains(WidgetState.selected)
                    ? scheme.primary
                    : palette.muted,
          ),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: palette.card,
        selectedColor: scheme.primaryContainer,
        side: WidgetStateBorderSide.resolveWith(
          (states) =>
              states.contains(WidgetState.selected)
                  ? BorderSide(color: scheme.primary, width: 1.4)
                  : BorderSide(color: palette.border),
        ),
        labelStyle: textTheme.labelLarge?.copyWith(fontSize: 13),
        showCheckmark: false,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.pill),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: palette.card,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.xl),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
      ),
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          textStyle: WidgetStatePropertyAll(textTheme.labelLarge),
          side: WidgetStatePropertyAll(BorderSide(color: palette.border)),
          backgroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected)
                    ? scheme.primaryContainer
                    : palette.card,
          ),
          foregroundColor: WidgetStateProperty.resolveWith(
            (states) =>
                states.contains(WidgetState.selected)
                    ? scheme.primary
                    : scheme.onSurface,
          ),
        ),
      ),
    );
  }
}
