import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_controller.dart';
import '../../state/portfolio_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/fields.dart';
import '../widgets/header.dart';

/// Hesabı kalıcı siler. Kullanıcı e-posta adresini yazarak onaylar.
class HesapSilScreen extends StatefulWidget {
  const HesapSilScreen({super.key});

  @override
  State<HesapSilScreen> createState() => _HesapSilScreenState();
}

class _HesapSilScreenState extends State<HesapSilScreen> {
  // Silme sonrası oturum kapanır; e-postayı baştan saklarız.
  late final String _email = context.read<AuthController>().user!.email;
  final _typed = TextEditingController();

  @override
  void dispose() {
    _typed.dispose();
    super.dispose();
  }

  bool get _matches =>
      _typed.text.trim().toLowerCase() == _email.trim().toLowerCase();

  Future<void> _delete() async {
    final auth = context.read<AuthController>();
    final portfolio = context.read<PortfolioController>();
    final ok = await auth.deleteAccount(_typed.text);
    if (!ok) return;
    await portfolio.clear();
    if (mounted) popToRoot(context);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ScreenHeader(title: 'Hesabı sil'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFBECEA),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: const Color(0xFFEBC3BE)),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Bu işlem geri alınamaz',
                            style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF8A2820))),
                        SizedBox(height: 8),
                        Text(
                          'Hesabını silersen şunlar kalıcı olarak kaldırılır:',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF5A2A25), height: 1.55),
                        ),
                        SizedBox(height: 6),
                        Text(
                          '• Kayıtlı tüm varlıkların ve miktarların\n• Profil bilgilerin\n• Fiyat bildirimlerin',
                          style: TextStyle(
                              fontSize: 14, color: Color(0xFF5A2A25), height: 1.7),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Onaylamak için e-posta adresini yaz: $_email',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.muted,
                        height: 1.5),
                  ),
                  const SizedBox(height: 8),
                  LabeledField(
                    id: 'onay',
                    label: 'E-posta',
                    controller: _typed,
                    keyboardType: TextInputType.emailAddress,
                    hint: _email,
                    onChanged: (_) => setState(() {}),
                  ),
                  if (auth.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(auth.error!,
                          style: const TextStyle(color: AppColors.down)),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: AppColors.hairline)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  PrimaryButton(
                    label: 'Hesabı kalıcı olarak sil',
                    destructive: true,
                    onPressed: (_matches && !auth.busy) ? _delete : null,
                  ),
                  const SizedBox(height: 4),
                  TextLink(
                    label: 'Vazgeç',
                    onTap: () => Navigator.of(context).maybePop(),
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
