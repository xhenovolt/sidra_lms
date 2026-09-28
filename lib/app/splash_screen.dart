import 'package:flutter/material.dart';

import '../core/theme/app_tokens.dart';
import '../shared/widgets/sidra_mark.dart';

/// Shown while Sidra starts (session restore). Matches the Android launch
/// screen exactly, so the hand-over is seamless: the Sidra logo in the
/// middle, "from Almuntahha" at the bottom, on the brand background — also
/// in dark mode, where the dark-green logo would not be readable.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SidraColors.parchment,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),
            const SidraMark(size: 112),
            const Spacer(),
            Padding(
              padding: const EdgeInsets.only(bottom: Space.lg),
              child: Image.asset(
                'assets/branding/from_almuntahha.png',
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
