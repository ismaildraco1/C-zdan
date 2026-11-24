import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/fields.dart';

class GirisScreen extends StatefulWidget {
  const GirisScreen({super.key});

  @override
  State<GirisScreen> createState() => _GirisScreenState();
}

class _GirisScreenState extends State<GirisScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _submitted = false;
  String? _authError;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  String? get _emailError => _submitted ? Validators.email(_email.text) : null;
  String? get _passwordError =>
      _submitted ? Validators.required(_password.text, 'Şifreni yaz.') : null;

  Future<void> _submit() async {
    setState(() => _submitted = true);
    if (Validators.email(_email.text) != null || _password.text.isEmpty) return;
    // Başarılı girişte kök ekran kendiliğinden ana ekrana geçer.
    final auth = context.read<AuthController>();
    setState(() => _authError = null);
    final ok = await auth.signIn(_email.text, _password.text);
    if (!ok && mounted) setState(() => _authError = auth.error);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthController>();
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 48, 24, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: AppColors.green,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.account_balance_wallet_outlined,
                    color: Color(0xFFE0BE6A),
                    size: 32,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Cüzdan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              const Text(
                'Altın ve dövizlerinin güncel değeri, tek ekranda.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              LabeledField(
                id: 'eposta',
                label: 'E-posta',
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                error: _emailError,
                onChanged: (_) => setState(() {}),
              ),
              const SizedBox(height: 14),
              LabeledField(
                id: 'sifre',
                label: 'Şifre',
                controller: _password,
                obscure: true,
                error: _passwordError,
                onChanged: (_) => setState(() {}),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextLink(
                  label: 'Şifremi unuttum',
                  onTap: () => Navigator.of(context).pushNamed('/sifre'),
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
                label: 'Giriş yap',
                onPressed: auth.busy ? null : _submit,
              ),
              const SizedBox(height: 22),
              const _OrDivider(),
              const SizedBox(height: 18),
              SocialButton(
                label: 'Google ile devam et',
                onTap: (auth.busy || !auth.supportsSocialLogin)
                    ? null
                    : () => auth.google(),
              ),
              const SizedBox(height: 10),
              SocialButton(
                label: 'Apple ile devam et',
                dark: true,
                onTap: (auth.busy || !auth.supportsSocialLogin)
                    ? null
                    : () => auth.apple(),
              ),
              if (!auth.supportsSocialLogin)
                const Padding(
                  padding: EdgeInsets.only(top: 10),
                  child: Text(
                    'Google ve Apple ile giriş yakında.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, color: AppColors.muted),
                  ),
                ),
              const SizedBox(height: 28),
              Wrap(
                alignment: WrapAlignment.center,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  const Text(
                    'Hesabın yok mu?',
                    style: TextStyle(fontSize: 14, color: AppColors.muted),
                  ),
                  TextLink(
                    label: 'Kayıt ol',
                    onTap: () => Navigator.of(context).pushNamed('/kayit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _OrDivider extends StatelessWidget {
  const _OrDivider();

  @override
  Widget build(BuildContext context) {
    const line = Expanded(child: Divider(color: Color(0xFFD5DCD7), height: 1));
    return const Row(
      children: [
        line,
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            'veya',
            style: TextStyle(fontSize: 13, color: AppColors.muted),
          ),
        ),
        line,
      ],
    );
  }
}
