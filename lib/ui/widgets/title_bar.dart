import 'package:material_ui/material_ui.dart';

import 'live_badge.dart';

/// Sekme başlığı ve sağında canlı fiyat etiketi. Dar ekranda başlık kısalır,
/// satır taşmaz.
class TitleBar extends StatelessWidget {
  const TitleBar({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        const Flexible(child: LiveBadge()),
      ],
    );
  }
}
