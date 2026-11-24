import 'package:material_ui/material_ui.dart';
import 'package:provider/provider.dart';

import '../../core/theme.dart';
import '../../state/auth_controller.dart';
import '../widgets/buttons.dart';
import '../widgets/header.dart';

class SifreGonderildiScreen extends StatelessWidget {
  const SifreGonderildiScreen({super.key, required this.email});

  final String email;

  Future<void> _resend(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    final ok = await context.read<AuthController>().sendReset(email);
    if (ok) {
      messenger.showSnackBar(
        const SnackBar(content: Text('Bağlantıyı yeniden gönderdik.')),
      );
    }
  }

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
                    Icons.mail_outline_rounded,
                    size: 34,
                    color: AppColors.green,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Bağlantıyı gönderdik',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 14),
              Text(
                '$email adresine şifre yenileme bağlantısı yolladık. Birkaç dakika içinde gelmezse gereksiz klasörüne de bak.',
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
                  label: 'Bağlantıyı yeniden gönder',
                  onTap: () => _resend(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
