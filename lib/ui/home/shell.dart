import 'package:material_ui/material_ui.dart';

import '../widgets/bottom_nav.dart';
import 'ayarlar.dart';
import 'piyasa.dart';
import 'portfoy.dart';

/// Oturum açıkken görünen ana kabuk: alt menü ve üç sekme.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _index,
        children: const [PortfoyScreen(), PiyasaScreen(), AyarlarScreen()],
      ),
      bottomNavigationBar: AppBottomNav(
        index: _index,
        onTab: (i) => setState(() => _index = i),
        onAdd: () => Navigator.of(context).pushNamed('/ekle'),
      ),
    );
  }
}
