import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/format.dart';
import '../../core/theme.dart';
import '../../domain/asset_kind.dart';
import '../../domain/models.dart';
import '../../state/market_controller.dart';
import '../../state/portfolio_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/fields.dart';
import '../widgets/header.dart';

const _chipLabels = {
  AssetKind.gramGold: 'Gram Altın',
  AssetKind.quarterGold: 'Çeyrek',
  AssetKind.halfGold: 'Yarım',
  AssetKind.fullGold: 'Tam',
  AssetKind.usd: 'USD',
  AssetKind.eur: 'EUR',
  AssetKind.gbp: 'GBP',
};

/// Yeni varlık ekler; `editing` verilirse o kaydın miktarını ve notunu düzenler.
class VarlikEkleScreen extends StatefulWidget {
  const VarlikEkleScreen({super.key, this.editing});

  final Holding? editing;

  @override
  State<VarlikEkleScreen> createState() => _VarlikEkleScreenState();
}

class _VarlikEkleScreenState extends State<VarlikEkleScreen> {
  late AssetKind _kind = widget.editing?.kind ?? AssetKind.values.first;
  late final TextEditingController _amount = TextEditingController(
    text: widget.editing == null ? '' : formatAmount(widget.editing!.amount),
  );
  late final TextEditingController _note = TextEditingController(
    text: widget.editing?.note ?? '',
  );

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  bool _saving = false;
  String? _saveError;

  bool get _isEdit => widget.editing != null;
  double? get _parsed => parseAmount(_amount.text);

  String? get _reason {
    if (_parsed != null) return null;
    return _amount.text.trim().isEmpty
        ? 'Önce bir miktar yaz.'
        : 'Miktar 0’dan büyük bir sayı olmalı.';
  }

  Future<void> _save() async {
    final amount = _parsed;
    if (amount == null || _saving) return;
    setState(() {
      _saving = true;
      _saveError = null;
    });
    final portfolio = context.read<PortfolioController>();
    try {
      final ok = _isEdit
          ? await portfolio.update(
              widget.editing!.id,
              amount,
              _note.text.trim(),
            )
          : await portfolio.add(_kind, amount, _note.text.trim());
      if (!mounted) return;
      if (ok) {
        Navigator.of(context).pop();
      } else {
        setState(() => _saveError = portfolio.error);
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quote = context.watch<MarketController>().quotes[_kind];
    final amount = _parsed;
    final value = (quote != null && amount != null) ? amount * quote.buy : null;
    final reason = _reason;

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ScreenHeader(
                title: _isEdit ? 'Miktarı düzenle' : 'Varlık ekle',
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.only(bottom: 16),
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (_isEdit)
                          Text(
                            _kind.label,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        else ...[
                          const Text(
                            'Ne ekliyorsun?',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.muted,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              for (final k in AssetKind.values)
                                _TypeChip(
                                  id: 'tur-${k.name}',
                                  label: _chipLabels[k]!,
                                  selected: k == _kind,
                                  onTap: () => setState(() => _kind = k),
                                ),
                            ],
                          ),
                        ],
                        const SizedBox(height: 24),
                        LabeledField(
                          id: 'miktar',
                          label: 'Miktar',
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          suffix: _kind.unit,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 14),
                        LabeledField(
                          id: 'not',
                          label: 'Not (isteğe bağlı)',
                          controller: _note,
                          onChanged: (_) => setState(() {}),
                        ),
                        const SizedBox(height: 22),
                        _Preview(kind: _kind, quote: quote, value: value),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: _isEdit ? 'Değişiklikleri kaydet' : 'Portföye ekle',
                    onPressed: (amount == null || _saving) ? null : _save,
                  ),
                  if (_saveError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _saveError!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.down,
                        ),
                      ),
                    ),
                  if (reason != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        reason,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
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

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.id,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String id;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      key: Key(id),
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.green : AppColors.card,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: selected ? AppColors.green : const Color(0xFFD5DCD7),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w600,
            color: selected ? Colors.white : AppColors.ink,
          ),
        ),
      ),
    );
  }
}

class _Preview extends StatelessWidget {
  const _Preview({
    required this.kind,
    required this.quote,
    required this.value,
  });

  final AssetKind kind;
  final Quote? quote;
  final double? value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
      decoration: BoxDecoration(
        color: AppColors.green,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Şu anki değeri',
            style: TextStyle(fontSize: 12, color: Color(0xFFA9C3BA)),
          ),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value == null ? '—' : formatTry(value!),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            quote == null
                ? 'Fiyat bekleniyor'
                : '1 ${kind.unit} = ₺ ${formatMoney(quote!.buy)} (alış fiyatı) · canlı',
            style: const TextStyle(fontSize: 12, color: Color(0xFFA9C3BA)),
          ),
        ],
      ),
    );
  }
}
