import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/fields.dart';
import '../widgets/header.dart';

/// Yeni şifre belirler. `recovery: true` e-postadaki şifre yenileme bağlantısıyla
/// gelinen durumdur: yeni şifre belirlenene kadar ana ekran açılmaz ve geri dönüş
/// yoktur (yalnızca çıkış). `recovery: false` giriş yapmış kullanıcının
/// Profil'den şifre değiştirmesidir.
class YeniSifreScreen extends StatefulWidget {
  const YeniSifreScreen({super.key, required this.recovery});

  final bool recovery;

  @override
  State<YeniSifreScreen> createState() => _YeniSifreScreenState();
}

class _YeniSifreScreenState extends State<YeniSifreScreen> {
  final _new = TextEditingController();
  final _again = TextEditingController();
  String? _authError;

  @override
  void dispose() {
    _new.dispose();
    _again.dispose();
    super.dispose();
  }

  /// Gönderilemeyen durumun nedeni. Henüz yazılmamışsa ya da ikinci alan
  /// boşsa uyarı gösterilmez ama düğme yine pasiftir.
  String? get _reason {
    if (_new.text.isEmpty) return null;
    final weak = Validators.password(_new.text);
    if (weak != null) return weak;
    if (_again.text.isNotEmpty && _new.text != _again.text) {
      return 'Şifreler aynı değil.';
    }
    return null;
  }

  bool get _valid =>
      _new.text.isNotEmpty && _again.text.isNotEmpty && _reason == null;

  Future<void> _save() async {
    final auth = context.read<AuthController>();
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _authError = null);
    final ok = await auth.updatePassword(_new.text);
    if (!mounted) return;
    if (!ok) {
      setState(() => _authError = auth.error);
      return;
    }
    // Yenileme akışında kök ekran kendiliğinden ana ekrana geçer.
    if (!widget.recovery) {
      navigator.pop();
      messenger.showSnackBar(
        const SnackBar(content: Text('Şifren değiştirildi.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    final reason = _reason;
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            if (widget.recovery)
              const Padding(
                padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Yeni şifre belirle',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                  ),
                ),
              )
            else
              const Padding(
                padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
                child: ScreenHeader(title: 'Şifreyi değiştir'),
              ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
                children: [
                  Text(
                    widget.recovery
                        ? 'E-postandaki bağlantıyla geldin. Hesabın için yeni bir şifre yaz.'
                        : 'Hesabın için yeni bir şifre yaz.',
                    style: const TextStyle(
                      fontSize: 15,
                      color: AppColors.muted,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 20),
                  LabeledField(
                    id: 'yeni',
                    label: 'Yeni şifre',
                    controller: _new,
                    obscure: true,
                    hint: 'En az 8 karakter',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    id: 'tekrar',
                    label: 'Yeni şifre (tekrar)',
                    controller: _again,
                    obscure: true,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_authError != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Text(
                        _authError!,
                        style: const TextStyle(
                          color: AppColors.down,
                          fontWeight: FontWeight.w600,
                        ),
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
                    label: 'Şifreyi kaydet',
                    onPressed: (_valid && !auth.busy) ? _save : null,
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
                  if (widget.recovery) ...[
                    const SizedBox(height: 4),
                    TextLink(
                      label: 'Vazgeç ve çıkış yap',
                      onTap: () => context.read<AuthController>().signOut(),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
