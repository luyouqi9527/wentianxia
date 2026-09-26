import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 全局主题：Material 3 + ColorScheme.fromSeed。
///
/// 新闻类应用以图片为主视觉，因此采用深色主题（深色背景下毛玻璃质感更明显）。
class AppTheme {
  const AppTheme._();

  /// 主题种子色。
  static const Color seedColor = Color(0xFF6750A4); // Material 3 默认 deepPurple 系

  static ThemeData get dark {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.dark,
    );
    return _base(scheme);
  }

  static ThemeData get light {
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: Brightness.light,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final bool isDark = scheme.brightness == Brightness.dark;
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? const Color(0xFF0E0E12) : scheme.surfaceContainerLowest,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: scheme.onSurface,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.transparent,
        selectedColor: scheme.primary.withValues(alpha: 0.45),
        side: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        labelStyle: TextStyle(color: scheme.onSurface),
        showCheckmark: false,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.transparent,
        elevation: 0,
        height: 66,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        indicatorColor: scheme.primary.withValues(alpha: 0.35),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
      cardTheme: CardThemeData(
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: scheme.primary),
      textTheme: const TextTheme(
        headlineSmall: TextStyle(fontWeight: FontWeight.w700, height: 1.25),
        titleMedium: TextStyle(fontWeight: FontWeight.w600),
        bodyMedium: TextStyle(height: 1.5),
        bodyLarge: TextStyle(height: 1.7, fontSize: 17),
      ),
    );
  }

  /// 系统状态栏/导航栏样式：透明沉浸式。
  static const SystemUiOverlayStyle systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarIconBrightness: Brightness.light,
  );
}
