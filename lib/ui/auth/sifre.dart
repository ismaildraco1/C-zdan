import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/fields.dart';
import '../widgets/header.dart';

class SifreScreen extends StatefulWidget {
  const SifreScreen({super.key});

  @override
  State<SifreScreen> createState() => _SifreScreenState();
}

class _SifreScreenState extends State<SifreScreen> {
  final _email = TextEditingController();
  bool _submitted = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    setState(() => _submitted = true);
    if (Validators.email(_email.text) != null) return;
    final email = _email.text.trim();
    final ok = await context.read<AuthController>().sendReset(email);
    if (ok && mounted) {
      Navigator.of(context).pushNamed('/sifre-gonderildi', arguments: email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const ScreenHeader(title: 'Şifremi unuttum'),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 16, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Hesabını açtığın e-posta adresini yaz. Şifreni yenilemen için sana bir bağlantı göndereceğiz.',
                      style: TextStyle(
                          fontSize: 15, color: AppColors.muted, height: 1.55),
                    ),
                    const SizedBox(height: 24),
                    LabeledField(
                      id: 'eposta',
                      label: 'E-posta',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      error: _submitted ? Validators.email(_email.text) : null,
                      onChanged: (_) => setState(() {}),
                    ),
                    if (auth.error != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(auth.error!,
                            style: const TextStyle(color: AppColors.down)),
                      ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: 'Sıfırlama bağlantısı gönder',
                      onPressed: auth.busy ? null : _send,
                    ),
                    const SizedBox(height: 24),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text('Hatırladın mı?',
                            style: TextStyle(
                                fontSize: 14, color: AppColors.muted)),
                        TextLink(
                          label: 'Giriş yap',
                          onTap: () => Navigator.of(context).maybePop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
