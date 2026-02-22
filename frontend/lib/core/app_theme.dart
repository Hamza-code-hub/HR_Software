import 'package:flutter/material.dart';

// ─── Enterprise App Theme Extension ──────────────────────────────────────────
// Use Theme.of(context).extension<AppColors>() to access these in any widget.
// This ensures ALL panels respond correctly to light/dark theme toggle.

@immutable
class AppColors extends ThemeExtension<AppColors> {
  const AppColors({
    required this.cardBg,
    required this.surfaceBg,
    required this.labelPrimary,
    required this.labelSecondary,
    required this.labelMuted,
    required this.border,
    required this.inputFill,
    required this.accentBlue,
    required this.accentGreen,
    required this.accentRed,
    required this.accentAmber,
    required this.accentPurple,
    required this.accentCyan,
    required this.sidebarBg,
    required this.sidebarText,
    required this.sidebarTextMuted,
    required this.sidebarActiveBg,
    required this.sidebarMiniRailBg,
    required this.shadow,
  });

  final Color cardBg;
  final Color surfaceBg;
  final Color labelPrimary;
  final Color labelSecondary;
  final Color labelMuted;
  final Color border;
  final Color inputFill;
  final Color accentBlue;
  final Color accentGreen;
  final Color accentRed;
  final Color accentAmber;
  final Color accentPurple;
  final Color accentCyan;
  // Sidebar is always dark (enterprise standard)
  final Color sidebarBg;
  final Color sidebarText;
  final Color sidebarTextMuted;
  final Color sidebarActiveBg;
  final Color sidebarMiniRailBg;
  final Color shadow;

  static const light = AppColors(
    cardBg:             Color(0xFFFFFFFF),
    surfaceBg:          Color(0xFFF1F5F9),
    labelPrimary:       Color(0xFF0F172A),
    labelSecondary:     Color(0xFF334155),
    labelMuted:         Color(0xFF64748B),
    border:             Color(0xFFE2E8F0),
    inputFill:          Color(0xFFF8FAFC),
    accentBlue:         Color(0xFF3B82F6),
    accentGreen:        Color(0xFF10B981),
    accentRed:          Color(0xFFEF4444),
    accentAmber:        Color(0xFFF59E0B),
    accentPurple:       Color(0xFF8B5CF6),
    accentCyan:         Color(0xFF0EA5E9),
    // Sidebar always dark
    sidebarBg:          Color(0xFF1E293B),
    sidebarText:        Color(0xFFE2E8F0),
    sidebarTextMuted:   Color(0xFF94A3B8),
    sidebarActiveBg:    Color(0xFF0EA5E9),
    sidebarMiniRailBg:  Color(0xFF0F172A),
    shadow:             Color(0x14000000),
  );

  static const dark = AppColors(
    cardBg:             Color(0xFF1E293B),
    surfaceBg:          Color(0xFF0F172A),
    labelPrimary:       Color(0xFFF1F5F9),
    labelSecondary:     Color(0xFFCBD5E1),
    labelMuted:         Color(0xFF94A3B8),
    border:             Color(0xFF334155),
    inputFill:          Color(0xFF1E293B),
    accentBlue:         Color(0xFF60A5FA),
    accentGreen:        Color(0xFF34D399),
    accentRed:          Color(0xFFF87171),
    accentAmber:        Color(0xFFFBBF24),
    accentPurple:       Color(0xFFA78BFA),
    accentCyan:         Color(0xFF38BDF8),
    // Sidebar always dark (slightly darker variant)
    sidebarBg:          Color(0xFF1E293B),
    sidebarText:        Color(0xFFE2E8F0),
    sidebarTextMuted:   Color(0xFF94A3B8),
    sidebarActiveBg:    Color(0xFF0EA5E9),
    sidebarMiniRailBg:  Color(0xFF0F172A),
    shadow:             Color(0x3D000000),
  );

  @override
  AppColors copyWith({
    Color? cardBg, Color? surfaceBg, Color? labelPrimary, Color? labelSecondary,
    Color? labelMuted, Color? border, Color? inputFill, Color? accentBlue,
    Color? accentGreen, Color? accentRed, Color? accentAmber, Color? accentPurple,
    Color? accentCyan, Color? sidebarBg, Color? sidebarText, Color? sidebarTextMuted,
    Color? sidebarActiveBg, Color? sidebarMiniRailBg, Color? shadow,
  }) => AppColors(
    cardBg:            cardBg            ?? this.cardBg,
    surfaceBg:         surfaceBg         ?? this.surfaceBg,
    labelPrimary:      labelPrimary      ?? this.labelPrimary,
    labelSecondary:    labelSecondary    ?? this.labelSecondary,
    labelMuted:        labelMuted        ?? this.labelMuted,
    border:            border            ?? this.border,
    inputFill:         inputFill         ?? this.inputFill,
    accentBlue:        accentBlue        ?? this.accentBlue,
    accentGreen:       accentGreen       ?? this.accentGreen,
    accentRed:         accentRed         ?? this.accentRed,
    accentAmber:       accentAmber       ?? this.accentAmber,
    accentPurple:      accentPurple      ?? this.accentPurple,
    accentCyan:        accentCyan        ?? this.accentCyan,
    sidebarBg:         sidebarBg         ?? this.sidebarBg,
    sidebarText:       sidebarText       ?? this.sidebarText,
    sidebarTextMuted:  sidebarTextMuted  ?? this.sidebarTextMuted,
    sidebarActiveBg:   sidebarActiveBg   ?? this.sidebarActiveBg,
    sidebarMiniRailBg: sidebarMiniRailBg ?? this.sidebarMiniRailBg,
    shadow:            shadow            ?? this.shadow,
  );

  @override
  AppColors lerp(AppColors? other, double t) {
    if (other is! AppColors) return this;
    return AppColors(
      cardBg:            Color.lerp(cardBg,            other.cardBg,            t)!,
      surfaceBg:         Color.lerp(surfaceBg,         other.surfaceBg,         t)!,
      labelPrimary:      Color.lerp(labelPrimary,      other.labelPrimary,      t)!,
      labelSecondary:    Color.lerp(labelSecondary,    other.labelSecondary,    t)!,
      labelMuted:        Color.lerp(labelMuted,        other.labelMuted,        t)!,
      border:            Color.lerp(border,            other.border,            t)!,
      inputFill:         Color.lerp(inputFill,         other.inputFill,         t)!,
      accentBlue:        Color.lerp(accentBlue,        other.accentBlue,        t)!,
      accentGreen:       Color.lerp(accentGreen,       other.accentGreen,       t)!,
      accentRed:         Color.lerp(accentRed,         other.accentRed,         t)!,
      accentAmber:       Color.lerp(accentAmber,       other.accentAmber,       t)!,
      accentPurple:      Color.lerp(accentPurple,      other.accentPurple,      t)!,
      accentCyan:        Color.lerp(accentCyan,        other.accentCyan,        t)!,
      sidebarBg:         Color.lerp(sidebarBg,         other.sidebarBg,         t)!,
      sidebarText:       Color.lerp(sidebarText,       other.sidebarText,       t)!,
      sidebarTextMuted:  Color.lerp(sidebarTextMuted,  other.sidebarTextMuted,  t)!,
      sidebarActiveBg:   Color.lerp(sidebarActiveBg,   other.sidebarActiveBg,   t)!,
      sidebarMiniRailBg: Color.lerp(sidebarMiniRailBg, other.sidebarMiniRailBg, t)!,
      shadow:            Color.lerp(shadow,            other.shadow,            t)!,
    );
  }

  // --- Aliases for better compatibility across screens ---
  Color get textPrimary   => labelPrimary;
  Color get textSecondary => labelSecondary;
  Color get textTertiary  => labelMuted;
}

// ─── Helper Extension ─────────────────────────────────────────────────────────
// Usage: context.appColors.cardBg

extension AppColorsX on BuildContext {
  AppColors get appColors =>
      Theme.of(this).extension<AppColors>() ?? AppColors.light;

  TextTheme get textTheme => Theme.of(this).textTheme;
}

// ─── Theme Builders ───────────────────────────────────────────────────────────

ThemeData buildLightTheme() {
  const scheme = ColorScheme.light(
    primary:            Color(0xFF0EA5E9),
    onPrimary:          Color(0xFFFFFFFF),
    primaryContainer:   Color(0xFFE0F2FE),
    secondary:          Color(0xFF10B981),
    onSecondary:        Color(0xFFFFFFFF),
    surface:            Color(0xFFF1F5F9),
    onSurface:          Color(0xFF0F172A),
    surfaceContainerHighest: Color(0xFFE2E8F0),
    outline:            Color(0xFFCBD5E1),
    error:              Color(0xFFEF4444),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFFF1F5F9),
    cardColor: const Color(0xFFFFFFFF),
    dividerColor: const Color(0xFFE2E8F0),
    fontFamily: 'Inter',
    extensions: const [AppColors.light],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFFFFFFF),
      foregroundColor: Color(0xFF0F172A),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFFFFFFFF),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF0EA5E9), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF64748B)),
      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF0EA5E9),
        foregroundColor: Colors.white,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF0EA5E9)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFFF1F5F9),
      labelStyle: const TextStyle(color: Color(0xFF334155), fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFFFFFFFF),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
    ),
  );
}

ThemeData buildDarkTheme() {
  const scheme = ColorScheme.dark(
    primary:            Color(0xFF38BDF8),
    onPrimary:          Color(0xFF0F172A),
    primaryContainer:   Color(0xFF0C4A6E),
    secondary:          Color(0xFF34D399),
    onSecondary:        Color(0xFF0F172A),
    surface:            Color(0xFF0F172A),
    onSurface:          Color(0xFFF1F5F9),
    surfaceContainerHighest: Color(0xFF1E293B),
    outline:            Color(0xFF334155),
    error:              Color(0xFFF87171),
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: scheme,
    scaffoldBackgroundColor: const Color(0xFF0F172A),
    cardColor: const Color(0xFF1E293B),
    dividerColor: const Color(0xFF334155),
    fontFamily: 'Inter',
    extensions: const [AppColors.dark],
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF1E293B),
      foregroundColor: Color(0xFFF1F5F9),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E293B),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Color(0xFF334155)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF1E293B),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF334155)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF38BDF8), width: 2),
      ),
      labelStyle: const TextStyle(color: Color(0xFF94A3B8)),
      hintStyle: const TextStyle(color: Color(0xFF64748B)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF38BDF8),
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
        textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: const Color(0xFF38BDF8)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: const Color(0xFF1E293B),
      labelStyle: const TextStyle(color: Color(0xFFCBD5E1), fontSize: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1E293B),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    snackBarTheme: const SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(10))),
    ),
  );
}
