import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Portföy · Piyasa · Ekle · Ayarlar. "Ekle" sekme değil, ayrı bir ekran açar.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({
    super.key,
    required this.index,
    required this.onTab,
    required this.onAdd,
  });

  /// 0 Portföy, 1 Piyasa, 2 Ayarlar
  final int index;
  final ValueChanged<int> onTab;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: [
              _item('nav-portfoy', Icons.account_balance_wallet_outlined,
                  'Portföy', index == 0, () => onTab(0)),
              _item('nav-piyasa', Icons.show_chart_rounded, 'Piyasa',
                  index == 1, () => onTab(1)),
              _add(),
              _item('nav-ayarlar', Icons.tune_rounded, 'Ayarlar', index == 2,
                  () => onTab(2)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(String id, IconData icon, String label, bool active,
      VoidCallback onTap) {
    final color = active ? AppColors.green : AppColors.muted;
    return Expanded(
      child: InkWell(
        key: Key(id),
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 24, color: color),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _add() {
    return Expanded(
      child: InkWell(
        key: const Key('nav-ekle'),
        onTap: onAdd,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: AppColors.gold,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.add_rounded, size: 18, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            const Text(
              'Ekle',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.muted),
            ),
          ],
        ),
      ),
    );
  }
}
