import 'package:material_ui/material_ui.dart';

import '../../core/theme.dart';

/// Baş harflerle yuvarlak kullanıcı simgesi.
class Avatar extends StatelessWidget {
  const Avatar(this.initials, {super.key, this.size = 52});

  final String initials;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: const BoxDecoration(
        color: AppColors.green,
        shape: BoxShape.circle,
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontSize: size * 0.34,
          fontWeight: FontWeight.w700,
          color: const Color(0xFFE0BE6A),
        ),
      ),
    );
  }
}
