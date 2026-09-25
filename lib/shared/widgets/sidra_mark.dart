import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

/// Placeholder brand mark (Arabic letter sīn in a soft tile) until the
/// Almuntahha logo asset is supplied.
class SidraMark extends StatelessWidget {
  const SidraMark({super.key, this.size = 40});

  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: scheme.primary,
          borderRadius: BorderRadius.circular(size * 0.28),
        ),
        child: Text(
          'س',
          textDirection: TextDirection.rtl,
          style: TextStyle(
            fontFamily: SidraFonts.arabic,
            fontSize: size * 0.55,
            height: 1.1,
            color: scheme.onPrimary,
          ),
        ),
      ),
    );
  }
}
