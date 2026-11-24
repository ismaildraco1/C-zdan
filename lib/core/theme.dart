import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background = Color(0xFFF2F4F1);
  static const green = Color(0xFF0E3B31);
  static const gold = Color(0xFFC8A24A);
  static const ink = Color(0xFF10211C);
  static const muted = Color(0xFF5E6B66);
  static const up = Color(0xFF1F7A4D);
  static const down = Color(0xFFA8322A);
  static const hairline = Color(0xFFE1E6E2);
  static const card = Color(0xFFFFFFFF);
}

/// Tek açık tema. Testlerde `useGoogleFonts: false` verilir (ağ çağrısı yok).
ThemeData buildTheme({bool useGoogleFonts = true}) {
  final base = ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AppColors.background,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      primary: AppColors.green,
      secondary: AppColors.gold,
      surface: AppColors.card,
    ),
  );
  final text = useGoogleFonts
      ? GoogleFonts.interTextTheme(base.textTheme)
      : base.textTheme;
  return base.copyWith(
    textTheme: text.apply(
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
  );
}
