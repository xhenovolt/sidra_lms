import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../media/data/media_repository.dart';
import '../../media/presentation/media_widgets.dart';
import '../domain/content_blocks.dart';
import '../domain/external_link.dart';
import 'simple_markdown.dart';

/// Renders one content block. Adding a block type = one case here plus
/// one in [ContentBlock.fromJson]. Curriculum structure never lives here.
class BlockView extends StatelessWidget {
  const BlockView({super.key, required this.block, this.onOpenAssessment});

  final ContentBlock block;
  final void Function(String assessmentId)? onOpenAssessment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final text = theme.textTheme;
    final scheme = theme.colorScheme;

    return switch (block) {
      HeadingBlock(:final text, :final level) => Padding(
        padding: const EdgeInsets.only(top: Space.sm),
        child: Text(
          text,
          style: switch (level) {
            1 => theme.textTheme.headlineSmall,
            2 => theme.textTheme.titleLarge,
            _ => theme.textTheme.titleMedium,
          },
        ),
      ),
      RichTextBlock(:final text) => SimpleMarkdown(text),
      ImageBlock(:final mediaAssetId, :final caption) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SidraImage(assetId: mediaAssetId, fit: BoxFit.contain),
          if (caption != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                caption,
                style: text.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
            ),
        ],
      ),
      AudioBlock(:final mediaAssetId, :final title, :final transcript) =>
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SidraAudioPlayer(assetId: mediaAssetId, title: title),
            if (transcript != null)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(transcript, style: text.bodySmall),
              ),
          ],
        ),
      VideoBlock(:final mediaAssetId) => SidraVideoPlayer(
        assetId: mediaAssetId,
      ),
      AttachmentBlock(:final mediaAssetId, :final title) => _AttachmentTile(
        assetId: mediaAssetId,
        title: title,
      ),
      QuranTextBlock() => _QuranCard(block: block as QuranTextBlock),
      TranslationBlock(:final text, :final translator) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            text,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
            ),
          ),
          if (translator != null)
            Text(
              '— $translator',
              style: theme.textTheme.bodySmall?.copyWith(
                color: scheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
      TransliterationBlock(:final text) => Text(
        text,
        style: theme.textTheme.bodyLarge?.copyWith(
          fontStyle: FontStyle.italic,
          color: scheme.onSurfaceVariant,
        ),
      ),
      ReferenceBlock(:final citation, :final source, :final url) => ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.menu_book_outlined),
        title: Text(citation, style: text.bodyMedium),
        subtitle: source == null ? null : Text(source),
        trailing: url == null ? null : const Icon(Icons.open_in_new, size: 18),
        onTap: url == null
            ? null
            : () => launchUrl(
                Uri.parse(url),
                mode: LaunchMode.externalApplication,
              ),
      ),
      CalloutBlock(:final text, :final tone) => _Callout(
        text: text,
        tone: tone,
      ),
      AssessmentBlock(:final assessmentId) => Card(
        child: ListTile(
          leading: Icon(Icons.quiz_outlined, color: scheme.primary),
          title: const Text('Check your understanding'),
          subtitle: const Text('Take the short quiz for this lesson'),
          trailing: const Icon(Icons.chevron_right),
          onTap: onOpenAssessment == null
              ? null
              : () => onOpenAssessment!(assessmentId),
        ),
      ),
      DividerBlock() => const Divider(height: Space.xl),
      final ExternalLinkBlock b => ExternalLinkCard(block: b),
      UnknownBlock() => const SizedBox.shrink(),
    };
  }
}

class _QuranCard extends StatelessWidget {
  const _QuranCard({required this.block});
  final QuranTextBlock block;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: scheme.tertiaryContainer.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(Radii.md),
        border: Border.all(color: scheme.tertiary.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Directionality(
            textDirection: TextDirection.rtl,
            child: SelectableText(
              block.arabic,
              style: AppTheme.quranText(context),
              textAlign: TextAlign.center,
            ),
          ),
          if (block.reference != null)
            Padding(
              padding: const EdgeInsets.only(top: Space.xs),
              child: Text(
                block.reference!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.labelMedium
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ),
        ],
      ),
    );
  }
}

class _Callout extends StatelessWidget {
  const _Callout({required this.text, required this.tone});
  final String text;
  final CalloutTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, bg, fg) = switch (tone) {
      CalloutTone.warning => (
        Icons.warning_amber_rounded,
        scheme.errorContainer,
        scheme.onErrorContainer,
      ),
      CalloutTone.note => (
        Icons.sticky_note_2_outlined,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
      ),
      CalloutTone.info => (
        Icons.info_outline,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(Space.md),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(Radii.md),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg),
          const SizedBox(width: Space.sm),
          Expanded(
            child: SimpleMarkdown(
              text,
              style: Theme.of(context).textTheme.bodyMedium
                  ?.copyWith(color: fg),
            ),
          ),
        ],
      ),
    );
  }
}

class _AttachmentTile extends ConsumerWidget {
  const _AttachmentTile({required this.assetId, required this.title});
  final String assetId;
  final String title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      child: ListTile(
        leading: const Icon(Icons.attach_file),
        title: Text(title),
        trailing: const Icon(Icons.open_in_new, size: 18),
        onTap: () async {
          final repo = await ref.read(mediaRepositoryProvider.future);
          final source = await repo.resolve(assetId);
          final uri = switch (source) {
            LocalMedia(:final file) => Uri.file(file.path),
            RemoteMedia(:final url) => Uri.parse(url),
          };
          await launchUrl(uri, mode: LaunchMode.externalApplication);
        },
      ),
    );
  }
}

/// Preview card for a YouTube, Telegram or web link. Opens outside the app.
class ExternalLinkCard extends StatelessWidget {
  const ExternalLinkCard({super.key, required this.block});
  final ExternalLinkBlock block;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final thumb = youtubeThumbnail(block.uri);
    final (icon, providerLabel, color) = switch (block.provider) {
      LinkProvider.youtube => (
        Icons.smart_display,
        l10n.linkProviderYoutube,
        const Color(0xFFD32F2F),
      ),
      LinkProvider.telegram => (
        Icons.send,
        l10n.linkProviderTelegram,
        const Color(0xFF229ED9),
      ),
      LinkProvider.web => (Icons.language, block.uri.host, scheme.primary),
    };
    final title = (block.title?.trim().isNotEmpty ?? false)
        ? block.title!.trim()
        : block.uri.host + block.uri.path;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => launchUrl(block.uri, mode: LaunchMode.externalApplication),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (thumb != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: thumb,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) =>
                          ColoredBox(color: scheme.surfaceContainerHighest),
                    ),
                    Center(
                      child: Icon(
                        Icons.play_circle_fill,
                        size: 56,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ListTile(
              leading: Icon(icon, color: color),
              title: Text(title, maxLines: 2, overflow: TextOverflow.ellipsis),
              subtitle: Text(
                [
                  providerLabel,
                  if (block.description?.trim().isNotEmpty ?? false)
                    block.description!.trim(),
                ].join(' · '),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Tooltip(
                message: l10n.linkOpen,
                child: const Icon(Icons.open_in_new, size: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
