import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_controller.dart';
import '../../state/market_controller.dart';
import '../widgets/avatar.dart';

class AyarlarScreen extends StatefulWidget {
  const AyarlarScreen({super.key});

  @override
  State<AyarlarScreen> createState() => _AyarlarScreenState();
}

class _AyarlarScreenState extends State<AyarlarScreen> {
  // Bu anahtarlar şimdilik yalnızca ekranda durur, kaydedilmez.
  // Ayar deposu (cihaz ya da hesap) seçilince kalıcı hale getirilecek.
  bool _notifications = true;
  bool _lock = true;
  bool _hideBalance = false;

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthController>().user;
    final source = context.watch<MarketController>().sourceName;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        children: [
          const Text(
            'Ayarlar',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 16),
          if (user != null)
            Material(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(18),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => Navigator.of(context).pushNamed('/profil'),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Avatar(user.initials),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.fullName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user.email,
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
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.muted,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          _Group('Tercihler', [
            const _ValueRow('Ana para birimi', 'Türk Lirası (₺)'),
            const _ValueRow('Değer hesabı', 'Alış fiyatı'),
            _SwitchRow(
              id: 'bildirim',
              label: 'Fiyat bildirimleri',
              value: _notifications,
              onChanged: (v) => setState(() => _notifications = v),
            ),
            const _ValueRow('Görünüm', 'Sistem', muted: true),
          ]),
          _Group('Güvenlik', [
            _SwitchRow(
              id: 'kilit',
              label: 'Parmak izi / Face ID ile aç',
              value: _lock,
              onChanged: (v) => setState(() => _lock = v),
            ),
            _SwitchRow(
              id: 'gizle',
              label: 'Bakiyeyi gizle',
              value: _hideBalance,
              onChanged: (v) => setState(() => _hideBalance = v),
            ),
          ]),
          _Group('Hakkında', [
            _ValueRow('Fiyat kaynağı', source),
            const _ValueRow('Sürüm', '0.1.0'),
          ]),
        ],
      ),
    );
  }
}

class _Group extends StatelessWidget {
  const _Group(this.title, this.rows);

  final String title;
  final List<Widget> rows;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 22, 0, 8),
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.muted,
            ),
          ),
        ),
        Material(
          color: AppColors.card,
          clipBehavior: Clip.antiAlias,
          borderRadius: BorderRadius.circular(16),
          child: Column(
            children: [
              for (var i = 0; i < rows.length; i++) ...[
                if (i > 0) const Divider(height: 1, color: Color(0xFFE8ECE9)),
                rows[i],
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _ValueRow extends StatelessWidget {
  const _ValueRow(this.label, this.value, {this.muted = false});

  final String label;
  final String value;
  final bool muted;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 50),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: muted ? AppColors.muted : AppColors.ink,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: const TextStyle(fontSize: 14, color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.id,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String id;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      key: Key(id),
      value: value,
      onChanged: onChanged,
      activeTrackColor: AppColors.green,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
      title: Text(
        label,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
    );
  }
}
