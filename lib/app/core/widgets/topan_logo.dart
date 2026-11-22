import 'package:flutter/material.dart';

/// Logo resmi Topan (sama dengan landing page).
/// [full] = logo lengkap dengan tulisan "topan GPS TRACKER",
/// selain itu hanya simbol tornado + pin.
class TopanLogo extends StatelessWidget {
  final double size;
  final bool full;

  const TopanLogo({super.key, this.size = 40, this.full = false});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      full ? 'assets/images/logo_full.png' : 'assets/images/logo_mark.png',
      height: size,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.medium,
      semanticLabel: 'Topan',
    );
  }
}
