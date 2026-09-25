import 'package:flutter/material.dart';

import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';

/// Downloads tab — offline course packages (wired in Phase 4/5).
class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.downloadsTitle)),
      body: EmptyView(
        icon: Icons.download_for_offline_outlined,
        title: l10n.downloadsEmptyTitle,
        message: l10n.downloadsEmptyBody,
      ),
    );
  }
}
