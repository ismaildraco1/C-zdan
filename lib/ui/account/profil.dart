import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../data/auth_repository.dart';
import '../../state/auth_controller.dart';
import '../widgets/avatar.dart';
import '../widgets/buttons.dart';
import '../widgets/fields.dart';
import '../widgets/header.dart';

class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});

  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  late final UserProfile _user = context.read<AuthController>().user!;
  late final _first = TextEditingController(text: _user.firstName);
  late final _last = TextEditingController(text: _user.lastName);
  late final _email = TextEditingController(text: _user.email);
  late final _phone = TextEditingController(text: _user.phone);
  bool _submitted = false;

  @override
  void dispose() {
    _first.dispose();
    _last.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  String? get _firstError =>
      _submitted ? Validators.required(_first.text, 'Adını yaz.') : null;
  String? get _lastError =>
      _submitted ? Validators.required(_last.text, 'Soyadını yaz.') : null;

  Future<void> _save() async {
    setState(() => _submitted = true);
    if (Validators.required(_first.text, 'x') != null ||
        Validators.required(_last.text, 'x') != null) {
      return;
    }
    await context.read<AuthController>().saveProfile(
      UserProfile(
        firstName: _first.text.trim(),
        lastName: _last.text.trim(),
        email: _user.email,
        phone: _phone.text.trim(),
      ),
    );
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _signOut() async {
    await context.read<AuthController>().signOut();
    if (mounted) popToRoot(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(12, 12, 12, 0),
              child: ScreenHeader(title: 'Kullanıcı bilgileri'),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                children: [
                  Center(child: Avatar(_user.initials, size: 84)),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: LabeledField(
                          id: 'ad',
                          label: 'Ad',
                          controller: _first,
                          error: _firstError,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: LabeledField(
                          id: 'soyad',
                          label: 'Soyad',
                          controller: _last,
                          error: _lastError,
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    id: 'eposta',
                    label: 'E-posta (değiştirilemez)',
                    controller: _email,
                    enabled: false,
                  ),
                  const SizedBox(height: 14),
                  LabeledField(
                    id: 'telefon',
                    label: 'Telefon',
                    controller: _phone,
                    keyboardType: TextInputType.phone,
                    onChanged: (_) => setState(() {}),
                  ),
                  const Padding(
                    padding: EdgeInsets.fromLTRB(4, 24, 0, 8),
                    child: Text(
                      'Hesap',
                      style: TextStyle(
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
                        InkWell(
                          onTap: () =>
                              Navigator.of(context)
                                  .pushNamed('/sifre-degistir'),
                          child: Container(
                            height: 50,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: const Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Şifreyi değiştir',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                                Icon(
                                  Icons.chevron_right_rounded,
                                  color: AppColors.muted,
                                ),
                              ],
                            ),
                          ),
                        ),
                        const Divider(height: 1, color: Color(0xFFE8ECE9)),
                        _DangerRow(label: 'Çıkış yap', onTap: _signOut),
                        const Divider(height: 1, color: Color(0xFFE8ECE9)),
                        _DangerRow(
                          label: 'Hesabı sil',
                          onTap: () =>
                              Navigator.of(context).pushNamed('/hesap-sil'),
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
              child: PrimaryButton(
                label: 'Değişiklikleri kaydet',
                onPressed: _save,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DangerRow extends StatelessWidget {
  const _DangerRow({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        height: 50,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.down,
          ),
        ),
      ),
    );
  }
}
