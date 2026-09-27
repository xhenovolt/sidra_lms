import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../admin/data/admin_repository.dart';
import '../../admin/presentation/admin_common.dart';
import '../../lessons/domain/external_link.dart';
import '../data/content_repository.dart';
import '../data/link_preview.dart';
import '../../media/presentation/media_viewer.dart';
import '../../media/presentation/capture_sheet.dart';

typedef ResourceKey = ({ResourceTarget target, String id});

final resourcesProvider = FutureProvider.autoDispose
    .family<List<Resource>, ResourceKey>(
      (ref, k) =>
          ref.watch(contentRepositoryProvider).resourcesFor(k.target, k.id),
    );

final linkPreviewServiceProvider = Provider((_) => LinkPreviewService());

/// Every format Sidra accepts for teaching material.
const allowedResourceExtensions = [
  'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', //
  'jpg', 'jpeg', 'png', 'webp', //
  'mp3', 'wav', 'm4a', 'aac', //
  'mp4', 'mov',
];

IconData resourceIcon(String kind) => switch (kind) {
  'image' => Icons.image_outlined,
  'audio' => Icons.headphones_outlined,
  'video' => Icons.movie_outlined,
  'link' => Icons.link,
  'document' => Icons.description_outlined,
  _ => Icons.insert_drive_file_outlined,
};

String formatBytes(int? bytes) {
  if (bytes == null) return '';
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Opens a resource: files through a signed URL (checked by the database),
/// links in the browser / their app.
Future<void> openResource(
  BuildContext context,
  WidgetRef ref,
  Resource r,
) async {
  final l10n = AppLocalizations.of(context);
  try {
    await openInApp(
      context,
      assetId: r.isLink ? null : r.mediaAssetId,
      url: r.url,
      kind: r.kind,
      mimeType: r.mimeType,
      fileName: r.fileName,
      title: r.title.isEmpty ? (r.fileName ?? '') : r.title,
    );
  } on AppFailure catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            e is ForbiddenFailure ? l10n.resourceLocked : l10n.genericError,
          ),
        ),
      );
    }
  }
}

/// Learners: the files and links attached to a lesson (or course, unit…).
class ResourceListView extends ConsumerWidget {
  const ResourceListView({
    super.key,
    required this.target,
    required this.id,
    this.title,
  });
  final ResourceTarget target;
  final String id;

  /// Heading (defaults to "Resources").
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final list = ref.watch(resourcesProvider((target: target, id: id)));
    final items = (list.value ?? const <Resource>[])
        .where((r) => r.published)
        .toList();
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(title ?? l10n.resourcesTitle, style: theme.textTheme.titleMedium),
        const SizedBox(height: Space.xs),
        for (final r in items)
          Card(
            child: ListTile(
              leading: Icon(resourceIcon(r.kind)),
              title: Text(r.title),
              subtitle: Text(
                [
                  if (r.isLink) Uri.tryParse(r.url ?? '')?.host ?? '',
                  if (!r.isLink) ?r.fileName,
                  if (r.bytes != null) formatBytes(r.bytes),
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              trailing: Icon(
                r.isLink ? Icons.open_in_new : Icons.download_outlined,
                size: 20,
              ),
              onTap: () => openResource(context, ref, r),
            ),
          ),
      ],
    );
  }
}

/// Admins and teachers: attach, check, order, hide or remove resources.
class ResourceManager extends ConsumerWidget {
  const ResourceManager({
    super.key,
    required this.target,
    required this.id,
    this.header = true,
  });

  final ResourceTarget target;
  final String id;
  final bool header;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final key = (target: target, id: id);
    final list = ref.watch(resourcesProvider(key));
    final repo = ref.read(contentRepositoryProvider);
    void reload() => ref.invalidate(resourcesProvider(key));

    Future<void> act(Future<void> Function() f) async {
      if (await runAdminAction(context, f, success: l10n.adminSaved)) reload();
    }

    final items = list.value ?? const <Resource>[];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (header)
          Row(
            children: [
              Expanded(
                child: Text(
                  l10n.resourcesTitle,
                  style: theme.textTheme.titleMedium,
                ),
              ),
            ],
          ),
        Wrap(
          spacing: Space.sm,
          children: [
            OutlinedButton.icon(
              onPressed: () async {
                if (await uploadResourceFlow(
                  context,
                  ref,
                  target,
                  id,
                  position: items.length,
                )) {
                  reload();
                }
              },
              icon: const Icon(Icons.upload_file),
              label: Text(l10n.resourceUpload),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                if (await addLinkFlow(
                  context,
                  ref,
                  target,
                  id,
                  position: items.length,
                )) {
                  reload();
                }
              },
              icon: const Icon(Icons.add_link),
              label: Text(l10n.resourceAddLink),
            ),
          ],
        ),
        const SizedBox(height: Space.xs),
        switch (list) {
          AsyncData() when items.isEmpty => Padding(
            padding: const EdgeInsets.symmetric(vertical: Space.sm),
            child: Text(l10n.resourcesNone, style: theme.textTheme.bodySmall),
          ),
          AsyncData() => Column(
            children: [
              for (final (i, r) in items.indexed)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(resourceIcon(r.kind)),
                  title: Text(r.title),
                  subtitle: Text(
                    [
                      if (!r.published) l10n.adminHidden,
                      if (r.isLink)
                        r.verified
                            ? l10n.resourceVerified
                            : l10n.resourceNotVerified,
                      if (r.isLink) Uri.tryParse(r.url ?? '')?.host ?? '',
                      if (!r.isLink) ?r.fileName,
                      if (r.bytes != null) formatBytes(r.bytes),
                      ?r.language,
                    ].join(' · '),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  trailing: PopupMenuButton<String>(
                    onSelected: (v) async {
                      switch (v) {
                        case 'preview':
                          await showResourcePreview(context, ref, r);
                        case 'up' || 'down':
                          final ids = [for (final x in items) x.linkId!];
                          final j = v == 'up' ? i - 1 : i + 1;
                          ids.insert(j, ids.removeAt(i));
                          await act(() => repo.reorderLinks(ids));
                        case 'toggle':
                          await act(
                            () => repo.setLinkStatus(r.linkId!, !r.published),
                          );
                        case 'remove':
                          if (await confirm(
                                context,
                                title: l10n.resourceRemove,
                                message: l10n.resourceRemoveBody(r.title),
                                destructive: true,
                              ) &&
                              context.mounted) {
                            await act(() => repo.detach(r.linkId!));
                          }
                      }
                    },
                    itemBuilder: (_) => [
                      PopupMenuItem(
                        value: 'preview',
                        child: Text(l10n.adminPreview),
                      ),
                      if (i > 0)
                        PopupMenuItem(
                          value: 'up',
                          child: Text(l10n.adminMoveUp),
                        ),
                      if (i < items.length - 1)
                        PopupMenuItem(
                          value: 'down',
                          child: Text(l10n.adminMoveDown),
                        ),
                      PopupMenuItem(
                        value: 'toggle',
                        child: Text(
                          r.published ? l10n.resourceHide : l10n.resourceShow,
                        ),
                      ),
                      PopupMenuItem(
                        value: 'remove',
                        child: Text(l10n.resourceRemove),
                      ),
                    ],
                  ),
                  onTap: () => showResourcePreview(context, ref, r),
                ),
            ],
          ),
          AsyncError(:final error) => ErrorView(error: error, onRetry: reload),
          _ => const LinearProgressIndicator(),
        },
      ],
    );
  }
}

/// Upload a document, picture, recording or video and attach it.
Future<bool> uploadResourceFlow(
  BuildContext context,
  WidgetRef ref,
  ResourceTarget target,
  String targetId, {
  int position = 0,
}) async {
  final l10n = AppLocalizations.of(context);
  var captured = await captureContent(
    context,
    fileExtensions: allowedResourceExtensions,
  );
  if (captured == null || !context.mounted) return false;
  if (captured.kind == 'text') captured = await pastedTextAsFile(captured);
  if (!context.mounted) return false;
  final picked = (name: captured.name, size: captured.bytes);
  final path = captured.path;
  final details = await _resourceDetails(
    context,
    ref,
    title: picked.name.replaceAll(RegExp(r'\.[^.]+$'), ''),
    subtitle: '${picked.name} · ${formatBytes(picked.size)}',
  );
  if (details == null || !context.mounted) return false;
  final profile = await ref.read(profileProvider.future);
  if (!context.mounted) return false;
  final kind = captured.kind == 'text' ? 'document' : captured.kind;
  var ok = false;
  await showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (dialogContext) => _UploadProgress(
      run: (onProgress) async {
        final assetId = await ref
            .read(adminRepositoryProvider)
            .uploadMedia(
              filePath: path,
              fileName: picked.name,
              kind: kind,
              uploaderId: profile.id,
              folder: 'resources',
              title: details.title,
              onProgress: onProgress,
            );
        await ref
            .read(contentRepositoryProvider)
            .addResource(
              target: target,
              targetId: targetId,
              uploaderId: profile.id,
              position: position,
              values: {
                'kind': kind,
                'title': details.title,
                'description': details.description,
                'language': details.language,
                'provider': 'cloudinary',
                'media_asset_id': assetId,
                'file_name': picked.name,
                'mime_type': mimeTypeFor(picked.name),
                'extension': picked.name.contains('.')
                    ? picked.name.split('.').last.toLowerCase()
                    : null,
                'bytes': picked.size,
              },
            );
        ok = true;
      },
      label: l10n.resourceUploading(picked.name),
    ),
  );
  return ok;
}

/// Add an external link: fetch a preview, let the admin check it, save.
Future<bool> addLinkFlow(
  BuildContext context,
  WidgetRef ref,
  ResourceTarget target,
  String targetId, {
  int position = 0,
}) async {
  final result = await showDialog<_LinkResult>(
    context: context,
    builder: (_) => const _LinkDialog(),
  );
  if (result == null || !context.mounted) return false;
  final profile = await ref.read(profileProvider.future);
  if (!context.mounted) return false;
  return runAdminAction(
    context,
    () => ref
        .read(contentRepositoryProvider)
        .addResource(
          target: target,
          targetId: targetId,
          uploaderId: profile.id,
          position: position,
          values: {
            'kind': 'link',
            'title': result.title,
            'description': result.description,
            'language': result.language,
            'provider': 'external',
            'url': result.preview.url,
            'preview': result.preview.toJson(),
            if (result.verified) ...{
              'verified_by': profile.id,
              'verified_at': DateTime.now().toUtc().toIso8601String(),
            },
          },
        ),
    success: AppLocalizations.of(context).adminSaved,
  );
}

class _LinkResult {
  _LinkResult(
    this.preview,
    this.title,
    this.description,
    this.language,
    this.verified,
  );
  final LinkPreview preview;
  final String title;
  final String? description;
  final String? language;
  final bool verified;
}

class _LinkDialog extends ConsumerStatefulWidget {
  const _LinkDialog();

  @override
  ConsumerState<_LinkDialog> createState() => _LinkDialogState();
}

class _LinkDialogState extends ConsumerState<_LinkDialog> {
  final _url = TextEditingController();
  final _title = TextEditingController();
  final _description = TextEditingController();
  String? _language;
  LinkPreview? _preview;
  bool _loading = false;
  String? _error;

  Future<void> _check() async {
    final l10n = AppLocalizations.of(context);
    final uri = parseExternalLink(_url.text);
    if (uri == null) {
      setState(() => _error = l10n.linkUrlInvalid);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final p = await ref.read(linkPreviewServiceProvider).fetch(uri.toString());
    if (!mounted) return;
    setState(() {
      _loading = false;
      _preview = p;
      if (_title.text.trim().isEmpty && p.title != null) _title.text = p.title!;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = _preview;
    return AlertDialog(
      title: Text(l10n.resourceAddLink),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _url,
                autofocus: true,
                keyboardType: TextInputType.url,
                textDirection: TextDirection.ltr,
                decoration: InputDecoration(
                  labelText: l10n.linkUrlLabel,
                  hintText: 'https://…',
                  errorText: _error,
                  suffixIcon: IconButton(
                    tooltip: l10n.resourceCheckLink,
                    icon: const Icon(Icons.travel_explore),
                    onPressed: _loading ? null : _check,
                  ),
                ),
                onSubmitted: (_) => _check(),
              ),
              if (_loading) const LinearProgressIndicator(),
              if (p != null) ...[
                const SizedBox(height: Space.sm),
                LinkPreviewCard(preview: p),
                const SizedBox(height: Space.sm),
                AdminField(controller: _title, label: l10n.adminTitle),
                AdminField(
                  controller: _description,
                  label: l10n.adminDescription,
                  maxLines: 2,
                ),
                LanguageDropdown(
                  value: _language,
                  label: l10n.resourceLanguage,
                  onChanged: (v) => setState(() => _language = v),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.adminCancel),
        ),
        if (p == null)
          FilledButton(
            onPressed: _loading ? null : _check,
            child: Text(l10n.resourceCheckLink),
          )
        else
          FilledButton(
            onPressed: _title.text.trim().isEmpty && p.title == null
                ? null
                : () => Navigator.pop(
                    context,
                    _LinkResult(
                      p,
                      _title.text.trim().isEmpty
                          ? (p.title ?? p.domain)
                          : _title.text.trim(),
                      nullIfBlank(_description.text),
                      _language,
                      p.available,
                    ),
                  ),
            child: Text(
              p.available ? l10n.resourceLooksRight : l10n.resourceSaveAnyway,
            ),
          ),
      ],
    );
  }
}

/// What an external link turned out to be. Honest about missing previews.
class LinkPreviewCard extends StatelessWidget {
  const LinkPreviewCard({super.key, required this.preview});
  final LinkPreview preview;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final p = preview;
    return Card(
      clipBehavior: Clip.antiAlias,
      color: p.available ? null : theme.colorScheme.tertiaryContainer,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (p.thumbnail != null)
            AspectRatio(
              aspectRatio: 16 / 9,
              child: CachedNetworkImage(
                imageUrl: p.thumbnail!,
                fit: BoxFit.cover,
                errorWidget: (_, _, _) => ColoredBox(
                  color: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(Space.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!p.available)
                  Text(
                    l10n.resourcePreviewUnavailable(p.reason ?? ''),
                    style: theme.textTheme.labelLarge,
                  ),
                if (p.title != null)
                  Text(p.title!, style: theme.textTheme.titleSmall),
                if (p.description != null)
                  Text(
                    p.description!,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall,
                  ),
                const SizedBox(height: Space.xxs),
                Text(
                  [p.siteName ?? p.domain, ?p.contentType].join(' · '),
                  style: theme.textTheme.labelSmall,
                ),
                SelectableText(
                  p.url,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Look before learners do: images inline, other files described and
/// openable, links with their preview.
Future<void> showResourcePreview(
  BuildContext context,
  WidgetRef ref,
  Resource r,
) async {
  final l10n = AppLocalizations.of(context);
  String? imageUrl;
  if (r.kind == 'image' && r.mediaAssetId != null) {
    try {
      imageUrl = await ref
          .read(contentRepositoryProvider)
          .mediaUrl(r.mediaAssetId!);
    } on AppFailure {
      imageUrl = null;
    }
  }
  if (!context.mounted) return;
  await showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(r.title),
      content: SizedBox(
        width: 480,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (imageUrl != null)
                ClipRRect(
                  borderRadius: BorderRadius.circular(Radii.md),
                  child: CachedNetworkImage(imageUrl: imageUrl),
                ),
              if (r.isLink && r.preview != null)
                LinkPreviewCard(
                  preview: LinkPreview.fromJson(r.preview!, r.url ?? ''),
                ),
              const SizedBox(height: Space.sm),
              for (final (k, v) in [
                (l10n.resourceFile, r.fileName),
                (l10n.resourceType, r.mimeType ?? r.kind),
                (
                  l10n.resourceSize,
                  r.bytes == null ? null : formatBytes(r.bytes),
                ),
                (l10n.resourceLanguage, r.language),
                (l10n.adminDescription, r.description),
                if (r.isLink) (l10n.linkUrlLabel, r.url),
              ])
                if (v != null && v.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: Space.xxs),
                    child: Text('$k: $v'),
                  ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: Text(l10n.close),
        ),
        FilledButton.icon(
          onPressed: () => openResource(context, ref, r),
          icon: const Icon(Icons.open_in_new),
          label: Text(l10n.resourceOpen),
        ),
      ],
    ),
  );
}

class _Details {
  _Details(this.title, this.description, this.language);
  final String title;
  final String? description;
  final String? language;
}

Future<_Details?> _resourceDetails(
  BuildContext context,
  WidgetRef ref, {
  required String title,
  required String subtitle,
}) {
  final l10n = AppLocalizations.of(context);
  final t = TextEditingController(text: title);
  final d = TextEditingController();
  String? language;
  return showDialog<_Details>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.resourceUpload),
        content: SizedBox(
          width: 440,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
              AdminField(controller: t, label: l10n.adminTitle, required: true),
              AdminField(
                controller: d,
                label: l10n.adminDescription,
                maxLines: 2,
              ),
              LanguageDropdown(
                value: language,
                label: l10n.resourceLanguage,
                onChanged: (v) => setState(() => language = v),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () {
              if (t.text.trim().isEmpty) return;
              Navigator.pop(
                dialogContext,
                _Details(t.text.trim(), nullIfBlank(d.text), language),
              );
            },
            child: Text(l10n.resourceUploadNow),
          ),
        ],
      ),
    ),
  );
}

/// Shows real upload progress; closes itself when done or failed.
class _UploadProgress extends StatefulWidget {
  const _UploadProgress({required this.run, required this.label});
  final Future<void> Function(void Function(int, int) onProgress) run;
  final String label;

  @override
  State<_UploadProgress> createState() => _UploadProgressState();
}

class _UploadProgressState extends State<_UploadProgress> {
  double? _progress;
  int _sent = 0;
  int _total = 0;
  String? _error;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    setState(() {
      _error = null;
      _progress = null;
    });
    try {
      await widget.run((sent, total) {
        if (mounted && total > 0) {
          setState(() {
            _progress = sent / total;
            _sent = sent;
            _total = total;
          });
        }
      });
      if (mounted) Navigator.pop(context);
    } on AppFailure catch (e) {
      if (mounted) {
        setState(
          () => _error = e is OfflineFailure
              ? AppLocalizations.of(context).adminNeedsConnection
              : e.message,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return AlertDialog(
      title: Text(_error == null ? l10n.uploadUploading : l10n.uploadFailed),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.label),
          const SizedBox(height: Space.sm),
          if (_error == null) ...[
            LinearProgressIndicator(value: _progress),
            if (_total > 0)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(
                  '${formatFileSize(_sent)} / ${formatFileSize(_total)}',
                ),
              ),
          ] else
            Text(
              _error!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
      actions: [
        if (_error != null) ...[
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(onPressed: _start, child: Text(l10n.retry)),
        ],
      ],
    );
  }
}

/// A language picker backed by the languages table.
class LanguageDropdown extends ConsumerWidget {
  const LanguageDropdown({
    super.key,
    required this.value,
    required this.label,
    required this.onChanged,
    this.allowNone = true,
    this.noneLabel,
  });

  final String? value;
  final String label;
  final ValueChanged<String?> onChanged;
  final bool allowNone;
  final String? noneLabel;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final langs = ref.watch(languagesProvider).value ?? const <Language>[];
    return DropdownButtonFormField<String?>(
      initialValue: langs.any((l) => l.code == value) ? value : null,
      decoration: InputDecoration(labelText: label),
      items: [
        if (allowNone)
          DropdownMenuItem(
            value: null,
            child: Text(noneLabel ?? l10n.languageNotSet),
          ),
        for (final l in langs)
          DropdownMenuItem(
            value: l.code,
            child: Text(
              l.nativeName == null || l.nativeName == l.name
                  ? l.name
                  : '${l.name} · ${l.nativeName}',
            ),
          ),
      ],
      onChanged: onChanged,
    );
  }
}

/// Files and links of one unit or section, in a sheet.
Future<void> showResourcesSheet(
  BuildContext context, {
  required ResourceTarget target,
  required String id,
  required String title,
}) => showModalBottomSheet<void>(
  context: context,
  isScrollControlled: true,
  showDragHandle: true,
  builder: (context) => SizedBox(
    height: MediaQuery.sizeOf(context).height * 0.7,
    child: ListView(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: Space.sm),
        ResourceManager(target: target, id: id),
      ],
    ),
  ),
);
