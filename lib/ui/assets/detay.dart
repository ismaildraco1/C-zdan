import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../domain/portfolio.dart';
import '../../state/market_controller.dart';
import '../../state/portfolio_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/header.dart';
import 'chart.dart';

/// Tek bir varlığın değeri, fiyat grafiği, alış/satış fiyatı ve düzenle/sil işlemleri.
class DetayScreen extends StatelessWidget {
  const DetayScreen({super.key, required this.holding});

  final Holding holding;

  Future<void> _confirmDelete(BuildContext context, Holding h) async {
    final portfolio = context.read<PortfolioController>();
    final navigator = Navigator.of(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Varlığı sil?'),
        content: Text(
          '${formatAmount(h.amount)} ${h.kind.unit} ${h.kind.label} portföyünden kaldırılacak.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Vazgeç'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: AppColors.down),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await portfolio.remove(h.id);
      navigator.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioController>();
    final market = context.watch<MarketController>();
    final matches = portfolio.holdings.where((x) => x.id == holding.id);
    if (matches.isEmpty) return const Scaffold(body: SizedBox.shrink());
    final h = matches.first;

    final quote = market.quotes[h.kind];
    final value = portfolio.valueOf(h);
    final change = dayChange([h], market.quotes);
    final history = market.history(h.kind);
    final fx = !h.kind.isGold;
    String price(double v) => fx ? formatRate(v) : formatMoney(v);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 16),
                children: [
                  ScreenHeader(title: h.kind.label),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Elindeki ${formatAmount(h.amount)} ${h.kind.unit}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppColors.muted,
                          ),
                        ),
                        const SizedBox(height: 2),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerLeft,
                          child: Text(
                            value == null ? '—' : formatTry(value),
                            style: const TextStyle(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              letterSpacing: -0.5,
                            ),
                          ),
                        ),
                        if (quote != null && change.amount != 0)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              '${change.amount > 0 ? '▲' : '▼'} ${formatTry(change.amount.abs())} · ${formatPercent(change.percent)} bugün',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: changeColorFor(change.amount),
                              ),
                            ),
                          ),
                        const SizedBox(height: 18),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.card,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: history.length >= 2
                              ? PriceChart(values: history)
                              : const SizedBox(
                                  height: 150,
                                  child: Center(
                                    child: Text(
                                      'Grafik için fiyat bekleniyor',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: AppColors.muted,
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _Stat(
                              'Alış',
                              quote == null ? '—' : price(quote.buy),
                            ),
                            const SizedBox(width: 10),
                            _Stat(
                              'Satış',
                              quote == null ? '—' : price(quote.sell),
                            ),
                            const SizedBox(width: 10),
                            _Stat(
                              'Oturum aralığı',
                              history.isEmpty
                                  ? '—'
                                  : '${price(history.reduce((a, b) => a < b ? a : b))} – ${price(history.reduce((a, b) => a > b ? a : b))}',
                              small: true,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: PrimaryButton(
                      label: 'Miktarı düzenle',
                      onPressed: () =>
                          Navigator.of(context)
                              .pushNamed('/ekle', arguments: h),
                    ),
                  ),
                  const SizedBox(width: 10),
                  SizedBox(
                    height: 54,
                    child: OutlinedButton(
                      onPressed: () => _confirmDelete(context, h),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.down,
                        side: const BorderSide(color: Color(0xFFD9B3AE)),
                        backgroundColor: AppColors.card,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Varlığı sil',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Color changeColorFor(double amount) =>
    amount > 0 ? AppColors.up : AppColors.down;

class _Stat extends StatelessWidget {
  const _Stat(this.label, this.value, {this.small = false});

  final String label;
  final String value;
  final bool small;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.card,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, color: AppColors.muted),
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: TextStyle(
                  fontSize: small ? 14 : 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
