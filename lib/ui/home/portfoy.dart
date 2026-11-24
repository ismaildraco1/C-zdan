import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/models.dart';
import '../../domain/portfolio.dart';
import '../../state/market_controller.dart';
import '../../state/portfolio_controller.dart';
import '../widgets/asset_icon.dart';
import '../widgets/buttons.dart';
import '../widgets/title_bar.dart';

class PortfoyScreen extends StatelessWidget {
  const PortfoyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final portfolio = context.watch<PortfolioController>();
    final market = context.watch<MarketController>();
    final holdings = portfolio.holdings;
    final change = dayChange(holdings, market.quotes);

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const TitleBar(title: 'Varlıklarım'),
          const SizedBox(height: 18),
          _Hero(
            total: portfolio.total,
            change: change,
            hasHoldings: holdings.isNotEmpty,
          ),
          const SizedBox(height: 26),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Varlıklar',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
              const SizedBox(width: 8),
              const Flexible(
                child: Text(
                  'Alış fiyatı üzerinden',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: AppColors.muted),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          if (portfolio.loadFailed)
            _LoadError(
              message: portfolio.error ?? 'Varlıkların yüklenemedi. Bağlantını kontrol edip tekrar dene.',
              onRetry: portfolio.load,
            )
          else if (holdings.isEmpty)
            const _EmptyState()
          else
            for (final h in holdings)
              _HoldingRow(
                holding: h,
                value: portfolio.valueOf(h),
                quote: market.quotes[h.kind],
              ),
        ],
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero({
    required this.total,
    required this.change,
    required this.hasHoldings,
  });

  final double total;
  final ({double amount, double percent}) change;
  final bool hasHoldings;

  @override
  Widget build(BuildContext context) {
    final up = change.amount >= 0;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 22, 22, 20),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Toplam net değer',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFFA9C3BA),
            ),
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              formatTry(total),
              style: const TextStyle(
                fontSize: 38,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ),
          if (hasHoldings && change.amount != 0) ...[
            const SizedBox(height: 10),
            Text(
              '${up ? '▲' : '▼'} ${formatTry(change.amount.abs())} · ${formatPercent(change.percent)}',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFFE0BE6A),
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'bugün, açılışa göre',
              style: TextStyle(fontSize: 12, color: Color(0xFFA9C3BA)),
            ),
          ],
        ],
      ),
    );
  }
}

class _HoldingRow extends StatelessWidget {
  const _HoldingRow({
    required this.holding,
    required this.value,
    required this.quote,
  });

  final Holding holding;
  final double? value;
  final Quote? quote;

  @override
  Widget build(BuildContext context) {
    final q = quote;
    return InkWell(
      onTap: () =>
          Navigator.of(context).pushNamed('/detay', arguments: holding),
      child: Container(
        constraints: const BoxConstraints(minHeight: 64),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: AppColors.hairline)),
        ),
        child: Row(
          children: [
            AssetIcon(holding.kind),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    holding.kind.label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${formatAmount(holding.amount)} ${holding.kind.unit}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      value == null ? '—' : formatTry(value!),
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (q != null)
                      Text(
                        changeText(
                          q.changePercent,
                          formatPercent(q.changePercent),
                        ),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: changeColor(q.changePercent),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.down,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 8),
          TextLink(label: 'Tekrar dene', onTap: onRetry),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Column(
        children: [
          const Text(
            'İlk varlığını ekle',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Elindeki altın ve dövizleri gir, toplam değerini canlı fiyatlarla gör.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.muted, height: 1.5),
          ),
          const SizedBox(height: 20),
          PrimaryButton(
            label: 'Varlık ekle',
            onPressed: () => Navigator.of(context).pushNamed('/ekle'),
          ),
        ],
      ),
    );
  }
}
