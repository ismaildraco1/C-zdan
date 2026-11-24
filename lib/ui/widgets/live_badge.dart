import 'dart:async';

import 'package:intl/intl.dart';
import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/market_controller.dart';

/// "Canlı · 14:32" ya da fiyat bayatsa "Son güncelleme 14:32" etiketi.
/// Olay gelmese bile saniyede bir yeniden çizilir, çünkü bayatlama olaysız olur.
class LiveBadge extends StatefulWidget {
  const LiveBadge({super.key, this.now = DateTime.now});

  /// Saat kaynağı; testlerde sabit bir an verilir.
  final DateTime Function() now;

  @override
  State<LiveBadge> createState() => _LiveBadgeState();
}

class _LiveBadgeState extends State<LiveBadge> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketController>();
    final last = market.lastUpdate;
    final stale = market.isStale(widget.now());
    final time = last == null ? '' : DateFormat('HH:mm').format(last);
    final text = last == null
        ? 'Fiyatlar bekleniyor'
        : stale
            ? 'Son güncelleme $time'
            : 'Canlı · $time';
    // Canlı: yeşil. Bayat ya da henüz veri yok: soluk, bir şey doğru gösterilmiyor.
    final live = last != null && !stale;
    final textColor = live ? const Color(0xFF1F5C47) : AppColors.muted;
    return Container(
      key: const Key('live-badge'),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: live ? const Color(0xFFE3EBE6) : const Color(0xFFE8ECE9),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(
              color: live ? AppColors.up : AppColors.muted,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
