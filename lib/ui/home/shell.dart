import 'package:material_ui/material_ui.dart';

/// Geçici ana ekran. Görev 6'da Portföy / Piyasa / Ekle / Ayarlar kabuğuyla değişir.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Varlıklarım')));
  }
}
