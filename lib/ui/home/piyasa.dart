import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/asset_kind.dart';
import '../../domain/models.dart';
import '../../state/market_controller.dart';
import '../widgets/asset_icon.dart';
import '../widgets/title_bar.dart';

enum _Filter { all, gold, fx }

class _Row {
  const _Row(this.name, this.quote, {required this.fx, required this.gold});
  final String name;
  final Quote? quote;
  final bool fx;
  final bool gold;
}

class PiyasaScreen extends StatefulWidget {
  const PiyasaScreen({super.key});

  @override
  State<PiyasaScreen> createState() => _PiyasaScreenState();
}

class _PiyasaScreenState extends State<PiyasaScreen> {
  _Filter _filter = _Filter.all;

  List<_Row> _rows(MarketController m) {
    Quote? q(AssetKind k) => m.quotes[k];
    return [
      _Row('Gram Altın', q(AssetKind.gramGold), fx: false, gold: true),
      _Row('Çeyrek Altın', q(AssetKind.quarterGold), fx: false, gold: true),
      _Row('Yarım Altın', q(AssetKind.halfGold), fx: false, gold: true),
      _Row('Tam Altın', q(AssetKind.fullGold), fx: false, gold: true),
      _Row('Ons Altın', m.ons, fx: false, gold: true),
      _Row('USD / TL', q(AssetKind.usd), fx: true, gold: false),
      _Row('EUR / TL', q(AssetKind.eur), fx: true, gold: false),
      _Row('GBP / TL', q(AssetKind.gbp), fx: true, gold: false),
    ].where((r) {
      return switch (_filter) {
        _Filter.all => true,
        _Filter.gold => r.gold,
        _Filter.fx => r.fx,
      };
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final market = context.watch<MarketController>();
    final rows = _rows(market);
    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const TitleBar(title: 'Piyasa'),
          const SizedBox(height: 16),
          _Segments(
            value: _filter,
            onChanged: (f) => setState(() => _filter = f),
          ),
          const SizedBox(height: 18),
          const _TableHeader(),
          for (final r in rows) _MarketRow(row: r),
          const SizedBox(height: 12),
          const Text(
            'Fiyatlar anlık güncellenir.',
            style: TextStyle(fontSize: 12, color: AppColors.muted),
          ),
        ],
      ),
    );
  }
}

class _Segments extends StatelessWidget {
  const _Segments({required this.value, required this.onChanged});

  final _Filter value;
  final ValueChanged<_Filter> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, _Filter f) {
      final active = value == f;
      return Expanded(
        child: InkWell(
          key: Key('filtre-${f.name}'),
          borderRadius: BorderRadius.circular(9),
          onTap: () => onChanged(f),
          child: Container(
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: active ? AppColors.card : Colors.transparent,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: active ? FontWeight.w700 : FontWeight.w600,
                color: active ? AppColors.green : AppColors.muted,
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFE3EBE6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          seg('Tümü', _Filter.all),
          seg('Altın', _Filter.gold),
          seg('Döviz', _Filter.fx),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  const _TableHeader();

  @override
  Widget build(BuildContext context) {
    const style = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.muted,
      letterSpacing: 0.5,
    );
    return const Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(child: Text('ÜRÜN', style: style)),
          SizedBox(
            width: 92,
            child: Text('ALIŞ', textAlign: TextAlign.right, style: style),
          ),
          SizedBox(
            width: 92,
            child: Text('SATIŞ', textAlign: TextAlign.right, style: style),
          ),
        ],
      ),
    );
  }
}

class _MarketRow extends StatelessWidget {
  const _MarketRow({required this.row});

  final _Row row;

  @override
  Widget build(BuildContext context) {
    final q = row.quote;
    String price(double v) => row.fx ? formatRate(v) : formatMoney(v);
    const priceStyle = TextStyle(fontSize: 15, fontWeight: FontWeight.w600);
    return Container(
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppColors.hairline)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  row.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (q != null)
                  Text(
                    changeText(q.changePercent, formatPercent(q.changePercent)),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: changeColor(q.changePercent),
                    ),
                  ),
              ],
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              q == null ? '—' : price(q.buy),
              textAlign: TextAlign.right,
              style: priceStyle,
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              q == null ? '—' : price(q.sell),
              textAlign: TextAlign.right,
              style: priceStyle,
            ),
          ),
        ],
      ),
    );
  }
}
