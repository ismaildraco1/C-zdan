import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';
import '../widgets/buttons.dart';
import '../widgets/header.dart';

/// Kayıt oldu ama e-posta doğrulaması bekleniyor. Hata değil, bir sonraki adım.
class DogrulamaScreen extends StatelessWidget {
  const DogrulamaScreen({super.key, required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(32, 120, 32, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE3EBE6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 34,
                    color: AppColors.green,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'E-postanı doğrula',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Text(
                '$email adresine bir doğrulama bağlantısı gönderdik. Bağlantıya dokunduktan sonra giriş yapabilirsin. Gelmezse gereksiz klasörüne de bak.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  color: AppColors.muted,
                  height: 1.55,
                ),
              ),
              const SizedBox(height: 32),
              PrimaryButton(
                label: 'Giriş ekranına dön',
                onPressed: () => popToRoot(context),
              ),
              const SizedBox(height: 8),
              Center(
                child: TextLink(
                  label: 'Başka bir adres kullan',
                  onTap: () => Navigator.of(context).maybePop(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
