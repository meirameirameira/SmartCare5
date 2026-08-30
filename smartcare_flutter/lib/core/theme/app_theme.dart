import 'package:flutter/material.dart';

/// Cores semânticas de saúde (crítico / atenção / ok) resolvidas por tema.
///
/// Ficam em um [ThemeExtension] para que os widgets nunca escrevam
/// `Colors.red` direto — no tema escuro os tons são ajustados sem tocar nas
/// telas.
@immutable
class HealthColors extends ThemeExtension<HealthColors> {
  const HealthColors({
    required this.critical,
    required this.warning,
    required this.info,
    required this.ok,
    required this.criticalSurface,
    required this.warningSurface,
    required this.infoSurface,
    required this.okSurface,
  });

  final Color critical;
  final Color warning;
  final Color info;
  final Color ok;
  final Color criticalSurface;
  final Color warningSurface;
  final Color infoSurface;
  final Color okSurface;

  static const _light = HealthColors(
    critical: Color(0xFFD32F2F),
    warning: Color(0xFFF57C00),
    info: Color(0xFF1976D2),
    ok: Color(0xFF2E7D5E),
    criticalSurface: Color(0xFFFDECEA),
    warningSurface: Color(0xFFFFF3E0),
    infoSurface: Color(0xFFE3F2FD),
    okSurface: Color(0xFFD4EDE4),
  );

  static const _dark = HealthColors(
    critical: Color(0xFFFF7A72),
    warning: Color(0xFFFFB74D),
    info: Color(0xFF64B5F6),
    ok: Color(0xFF6FD3A8),
    criticalSurface: Color(0xFF3A1F1E),
    warningSurface: Color(0xFF3A2A16),
    infoSurface: Color(0xFF17293A),
    okSurface: Color(0xFF17332A),
  );

  @override
  HealthColors copyWith({
    Color? critical,
    Color? warning,
    Color? info,
    Color? ok,
    Color? criticalSurface,
    Color? warningSurface,
    Color? infoSurface,
    Color? okSurface,
  }) =>
      HealthColors(
        critical: critical ?? this.critical,
        warning: warning ?? this.warning,
        info: info ?? this.info,
        ok: ok ?? this.ok,
        criticalSurface: criticalSurface ?? this.criticalSurface,
        warningSurface: warningSurface ?? this.warningSurface,
        infoSurface: infoSurface ?? this.infoSurface,
        okSurface: okSurface ?? this.okSurface,
      );

  @override
  HealthColors lerp(ThemeExtension<HealthColors>? other, double t) {
    if (other is! HealthColors) return this;
    return HealthColors(
      critical: Color.lerp(critical, other.critical, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      ok: Color.lerp(ok, other.ok, t)!,
      criticalSurface: Color.lerp(criticalSurface, other.criticalSurface, t)!,
      warningSurface: Color.lerp(warningSurface, other.warningSurface, t)!,
      infoSurface: Color.lerp(infoSurface, other.infoSurface, t)!,
      okSurface: Color.lerp(okSurface, other.okSurface, t)!,
    );
  }
}

/// Atalho de leitura das cores semânticas dentro dos widgets.
extension HealthColorsContext on BuildContext {
  HealthColors get health =>
      Theme.of(this).extension<HealthColors>() ?? HealthColors._light;
}

/// Temas claro e escuro do SmartCare 5.0.
///
/// O tema escuro é novo nesta fase e atende tanto conforto visual noturno
/// quanto economia de bateria em telas OLED.
abstract final class SmartCareTheme {
  static const primaryGreen = Color(0xFF2E7D5E);
  static const primaryGreenDark = Color(0xFF1B5C43);
  static const primaryGreenLight = Color(0xFFD4EDE4);
  static const accentBlue = Color(0xFF1976D2);
  static const dangerRed = Color(0xFFD32F2F);
  static const warnAmber = Color(0xFFF57C00);
  static const surface = Color(0xFFF7F9F8);

  static ThemeData get light => _base(
        Brightness.light,
        ColorScheme.fromSeed(
          seedColor: primaryGreen,
          primary: primaryGreen,
          surface: Colors.white,
          surfaceContainerHighest: surface,
        ),
        scaffoldBackground: surface,
        appBarBackground: primaryGreenDark,
        healthColors: HealthColors._light,
        indicatorColor: primaryGreenLight,
      );

  static ThemeData get dark => _base(
        Brightness.dark,
        ColorScheme.fromSeed(
          seedColor: primaryGreen,
          brightness: Brightness.dark,
          primary: const Color(0xFF6FD3A8),
          surface: const Color(0xFF141B18),
        ),
        scaffoldBackground: const Color(0xFF0E1412),
        appBarBackground: const Color(0xFF15211C),
        healthColors: HealthColors._dark,
        indicatorColor: const Color(0xFF244A3B),
      );

  static ThemeData _base(
    Brightness brightness,
    ColorScheme scheme, {
    required Color scaffoldBackground,
    required Color appBarBackground,
    required HealthColors healthColors,
    required Color indicatorColor,
  }) {
    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor: scaffoldBackground,
      extensions: [healthColors],
      appBarTheme: AppBarTheme(
        backgroundColor: appBarBackground,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: indicatorColor,
        labelTextStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        color: scheme.surface,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      fontFamily: 'Roboto',
    );
  }
}
