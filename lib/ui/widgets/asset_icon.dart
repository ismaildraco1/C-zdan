import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../../domain/asset_kind.dart';

/// Varlık türünü gösteren yuvarlak simge: altın için "Au", dövizler için işareti.
class AssetIcon extends StatelessWidget {
  const AssetIcon(this.kind, {super.key, this.size = 40});

  final AssetKind kind;
  final double size;

  static String glyph(AssetKind k) => switch (k) {
    AssetKind.usd => r'$',
    AssetKind.eur => '€',
    AssetKind.gbp => '£',
    _ => 'Au',
  };

  @override
  Widget build(BuildContext context) {
    final gold = kind.isGold;
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: gold ? const Color(0xFFEADFC0) : const Color(0xFFDCE8E1),
        shape: BoxShape.circle,
      ),
      child: Text(
        glyph(kind),
        style: TextStyle(
          fontSize: gold ? 13 : 16,
          fontWeight: FontWeight.w700,
          color: gold ? const Color(0xFF6B5316) : AppColors.green,
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
