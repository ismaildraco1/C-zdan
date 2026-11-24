import 'package:material_ui/material_ui.dart';

/// Geri düğmeli ekran başlığı.
class ScreenHeader extends StatelessWidget {
  const ScreenHeader({super.key, required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IconButton(
          tooltip: 'Geri dön',
          onPressed: () => Navigator.of(context).maybePop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
          constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
        ),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            title,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
          ),
        ),
      ],
    );
  }
}

/// Çıkış ve hesap silme gibi işlemlerden sonra tüm açık ekranları kapatır;
/// kökte (oturuma göre Giriş ya da ana ekran) kalınır.
void popToRoot(BuildContext context) =>
    Navigator.of(context).popUntil((route) => route.isFirst);
