import 'package:material_ui/material_ui.dart';

/// Geçici ekran. Görev 8'de Ayarlar ekranıyla değişir.
class AyarlarScreen extends StatelessWidget {
  const AyarlarScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SafeArea(child: Center(child: Text('Ayarlar')));
  }
}
