import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/fields.dart';
import '../widgets/header.dart';

class KayitScreen extends StatefulWidget {
  const KayitScreen({super.key});

  @override
  State<KayitScreen> createState() => _KayitScreenState();
}

class _KayitScreenState extends State<KayitScreen> {
  final _first = TextEditingController();
  final _last = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _accepted = false;
  bool _submitted = false;
  String? _authError;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? _err(String? Function() check) => _submitted ? check() : null;

  bool get _valid =>
      Validators.required(_first.text, 'x') == null &&
      Validators.required(_last.text, 'x') == null &&
      Validators.email(_email.text) == null &&
      Validators.password(_password.text) == null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (!_valid) return;
    final auth = context.read<AuthController>();
    setState(() => _authError = null);
    final ok = await auth.signUp(
      firstName: _first.text,
      lastName: _last.text,
      email: _email.text,
      password: _password.text,
    );
    if (!mounted) return;
    final pending = auth.confirmationEmail;
    if (ok) {
      popToRoot(context);
    } else if (pending != null) {
      // Hata değil: hesap açıldı, e-posta doğrulaması bekleniyor.
      auth.clearConfirmation();
      Navigator.of(context).pushNamed('/dogrulama', arguments: pending);
    } else {
      setState(() => _authError = auth.error);
    }
  }

  Future<void> _social(Future<bool> Function() action) async {
    final auth = context.read<AuthController>();
    setState(() => _authError = null);
    final ok = await action();
    if (!mounted) return;
    if (ok) {
      popToRoot(context);
    } else {
      setState(() => _authError = auth.error);
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
              const ScreenHeader(title: 'Hesap oluştur'),
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const Text(
                      'Varlıklarını kaydet, her cihazdan güncel değerini gör.',
                      style: TextStyle(
                        fontSize: 15,
                        color: AppColors.muted,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: LabeledField(
                            id: 'ad',
                            label: 'Ad',
                            controller: _first,
                            error: _err(
                              () => Validators.required(
                                _first.text,
                                'Adını yaz.',
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: LabeledField(
                            id: 'soyad',
                            label: 'Soyad',
                            controller: _last,
                            error: _err(
                              () => Validators.required(
                                _last.text,
                                'Soyadını yaz.',
                              ),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      id: 'eposta',
                      label: 'E-posta',
                      controller: _email,
                      keyboardType: TextInputType.emailAddress,
                      error: _err(() => Validators.email(_email.text)),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 14),
                    LabeledField(
                      id: 'sifre',
                      label: 'Şifre',
                      controller: _password,
                      obscure: true,
                      hint: 'En az 8 karakter',
                      error: _err(() => Validators.password(_password.text)),
                      onChanged: (_) => setState(() {}),
                    ),
                    CheckboxListTile(
                      key: const Key('kosul'),
                      value: _accepted,
                      onChanged: (v) => setState(() => _accepted = v ?? false),
                      controlAffinity: ListTileControlAffinity.leading,
                      contentPadding: EdgeInsets.zero,
                      activeColor: AppColors.green,
                      title: const Text(
                        'Kullanım koşullarını ve gizlilik politikasını okudum, kabul ediyorum.',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.muted,
                          height: 1.5,
                        ),
                      ),
                    ),
                    if (_authError != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          _authError!,
                          style: const TextStyle(
                            color: AppColors.down,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    PrimaryButton(
                      label: 'Hesap oluştur',
                      onPressed: (_accepted && !auth.busy) ? _submit : null,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        const Expanded(
                          child: Divider(color: Color(0xFFD5DCD7), height: 1),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text(
                            'veya',
                            style: TextStyle(
                              fontSize: 13,
                              color: AppColors.muted,
                            ),
                          ),
                        ),
                        const Expanded(
                          child: Divider(color: Color(0xFFD5DCD7), height: 1),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: SocialButton(
                            label: 'Google',
                            onTap: (auth.busy || !auth.supportsSocialLogin)
                                ? null
                                : () => _social(auth.google),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: SocialButton(
                            label: 'Apple',
                            dark: true,
                            onTap: (auth.busy || !auth.supportsSocialLogin)
                                ? null
                                : () => _social(auth.apple),
                          ),
                        ),
                      ],
                    ),
                    if (!auth.supportsSocialLogin)
                      const Padding(
                        padding: EdgeInsets.only(top: 10),
                        child: Text(
                          'Google ve Apple ile giriş yakında.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.muted,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        const Text(
                          'Zaten hesabın var mı?',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.muted,
                          ),
                        ),
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
