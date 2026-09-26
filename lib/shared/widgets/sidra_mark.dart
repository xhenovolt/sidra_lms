import 'package:flutter/material.dart';

/// Sidra's logo: the green mark on its light tile, as on the app icon.
/// The tile keeps the mark legible in dark mode too.
class SidraMark extends StatelessWidget {
  const SidraMark({super.key, this.size = 40});

  final double size;

  /// Background of the logo artwork (and of the launcher icon).
  static const tile = Color(0xFFF6F8F8);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Semantics(
        label: 'Sidra',
        image: true,
        child: Container(
          width: size,
          height: size,
          padding: EdgeInsets.all(size * 0.16),
          decoration: BoxDecoration(
            color: tile,
            borderRadius: BorderRadius.circular(size * 0.28),
            border: Border.all(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
          child: Image.asset(
            'assets/branding/mark.png',
            fit: BoxFit.contain,
            filterQuality: FilterQuality.medium,
          ),
        ),
      ),
    );
  }
}
