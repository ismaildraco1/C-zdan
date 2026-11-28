import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../domain/asset_kind.dart';

/// Varlık türünü gösteren yuvarlak simge: altın için "Au", gümüş için "Ag",
/// dövizler için işareti.
class AssetIcon extends StatelessWidget {
  const AssetIcon(this.kind, {super.key, this.size = 40});

  final AssetKind kind;
  final double size;

  static String glyph(AssetKind k) => switch (k) {
    AssetKind.usd => r'$',
    AssetKind.eur => '€',
    AssetKind.gbp => '£',
    AssetKind.silver => 'Ag',
    _ => 'Au',
  };

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = switch (kind.group) {
      AssetGroup.gold => (const Color(0xFFEADFC0), const Color(0xFF6B5316)),
      AssetGroup.silver => (const Color(0xFFE2E5E9), const Color(0xFF4A535E)),
      AssetGroup.fx => (const Color(0xFFDCE8E1), AppColors.green),
    };
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: background, shape: BoxShape.circle),
      child: Text(
        glyph(kind),
        style: TextStyle(
          fontSize: kind.group == AssetGroup.fx ? 16 : 13,
          fontWeight: FontWeight.w700,
          color: foreground,
        ),
      ),
    );
  }
}

/// `▲ %0,21` / `▼ %0,12` biçiminde günlük değişim metni.
String changeText(double percent, String formatted) {
  if (percent > 0) return '▲ $formatted';
  if (percent < 0) return '▼ $formatted';
  return formatted;
}

Color changeColor(double percent) => percent > 0
    ? AppColors.up
    : percent < 0
    ? AppColors.down
    : AppColors.muted;
