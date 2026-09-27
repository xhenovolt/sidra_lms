import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../shared/widgets/sidra_mark.dart';

/// Shown while Sidra starts (session restore). Matches the Android launch
/// screen exactly, so the hand-over is seamless: the mark in the middle,
/// "from Almuntahha" at the bottom.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      backgroundColor: dark ? SidraColors.teal900 : SidraColors.parchment,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const SidraMark(size: 112),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: Space.lg),
              child: Image.asset(
                dark
                    ? 'assets/branding/from_almuntahha_dark.png'
                    : 'assets/branding/from_almuntahha.png',
                width: 200,
                semanticLabel: 'from Almuntahha',
              ),
            ),
          ],
        ),
      ),
    );
  }
}
