import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/repository_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/widgets/state_views.dart';
import '../../curriculum/domain/curriculum_models.dart';
import '../data/admin_repository.dart';
import 'admin_common.dart';

final _booksProvider = FutureProvider.autoDispose<List<Book>>(
  (ref) => ref.watch(adminRepositoryProvider).books(),
);

final _bookLevelsProvider = FutureProvider.autoDispose
    .family<List<BookStructureLevel>, String>(
      (ref, bookId) => ref.watch(adminRepositoryProvider).levelsForBook(bookId),
    );

/// Admin: books and how each one is organised.
class BooksTab extends ConsumerWidget {
  const BooksTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final books = ref.watch(_booksProvider);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          if (await _bookDialog(context, ref)) ref.invalidate(_booksProvider);
        },
        icon: const Icon(Icons.add),
        label: Text(l10n.adminNewBook),
      ),
      body: switch (books) {
        AsyncData(:final value) when value.isEmpty => EmptyView(
          icon: Icons.menu_book_outlined,
          title: l10n.adminNoBooksTitle,
          message: l10n.adminNoBooksBody,
        ),
        AsyncData(:final value) => ListView(
          padding: const EdgeInsets.only(bottom: 96),
          children: [for (final b in value) _BookTile(book: b)],
        ),
        AsyncError(:final error) => ErrorView(
          error: error,
          onRetry: () => ref.invalidate(_booksProvider),
        ),
        _ => const LoadingView(),
      },
    );
  }
}

class _BookTile extends ConsumerWidget {
  const _BookTile({required this.book});
  final Book book;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final levels = ref.watch(_bookLevelsProvider(book.id)).value;
    return ExpansionTile(
      leading: const Icon(Icons.menu_book_outlined),
      title: Text(book.title),
      subtitle: Text(
        levels == null || levels.isEmpty
            ? l10n.adminNoStructure
            : levels.map((l) => l.labelSingular).join(' → '),
      ),
      children: [
        ListTile(
          leading: const Icon(Icons.account_tree_outlined),
          title: Text(l10n.adminSetStructure),
          subtitle: Text(l10n.adminSetStructureHint),
          onTap: () async {
            if (await _structureDialog(context, ref, book)) {
              ref.invalidate(_bookLevelsProvider(book.id));
            }
          },
        ),
        ListTile(
          leading: const Icon(Icons.edit_outlined),
          title: Text(l10n.adminEdit),
          onTap: () async {
            if (await _bookDialog(context, ref, book: book)) {
              ref.invalidate(_booksProvider);
            }
          },
        ),
      ],
    );
  }
}

Future<bool> _bookDialog(
  BuildContext context,
  WidgetRef ref, {
  Book? book,
}) async {
  final l10n = AppLocalizations.of(context);
  final form = GlobalKey<FormState>();
  final title = TextEditingController(text: book?.title);
  final author = TextEditingController(text: book?.author);
  final description = TextEditingController(text: book?.description);
  final edition = TextEditingController(text: book?.edition);
  final isbn = TextEditingController(text: book?.isbn);
  final notes = TextEditingController(text: book?.copyrightNotes);
  var language = book?.language ?? 'ar';
  String? cover = book?.coverAssetId;
  var uploading = false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(book == null ? l10n.adminNewBook : l10n.adminEdit),
        content: SizedBox(
          width: 480,
          child: Form(
            key: form,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  AdminField(
                    controller: title,
                    label: l10n.adminTitle,
                    required: true,
                  ),
                  AdminField(controller: author, label: l10n.adminAuthor),
                  DropdownButtonFormField<String>(
                    initialValue: language,
                    decoration: InputDecoration(labelText: l10n.adminLanguage),
                    items: const [
                      DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      DropdownMenuItem(value: 'en', child: Text('English')),
                    ],
                    onChanged: (v) => setState(() => language = v!),
                  ),
                  const SizedBox(height: Space.md),
                  AdminField(
                    controller: description,
                    label: l10n.adminDescription,
                    maxLines: 3,
                  ),
                  AdminField(controller: edition, label: l10n.adminEdition),
                  AdminField(controller: isbn, label: 'ISBN'),
                  AdminField(
                    controller: notes,
                    label: l10n.adminCopyright,
                    maxLines: 2,
                  ),
                  OutlinedButton.icon(
                    onPressed: uploading
                        ? null
                        : () async {
                            final file = await pickLocalFile(FileType.image);
                            if (file == null || !context.mounted) return;
                            final profile = await ref.read(
                              profileProvider.future,
                            );
                            setState(() => uploading = true);
                            if (!context.mounted) return;
                            await runAdminAction(context, () async {
                              cover = await ref
                                  .read(adminRepositoryProvider)
                                  .uploadMedia(
                                    filePath: file.path,
                                    fileName: file.name,
                                    kind: 'image',
                                    uploaderId: profile.id,
                                    folder: 'covers',
                                  );
                            });
                            if (context.mounted) {
                              setState(() => uploading = false);
                            }
                          },
                    icon: Icon(
                      cover == null ? Icons.upload : Icons.check_circle,
                    ),
                    label: Text(l10n.adminCover),
                  ),
                ],
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () async {
              if (!form.currentState!.validate()) return;
              final ok = await runAdminAction(
                context,
                () => ref.read(adminRepositoryProvider).save('books', {
                  'title': title.text.trim(),
                  'author': nullIfBlank(author.text),
                  'language': language,
                  'description': nullIfBlank(description.text),
                  'edition': nullIfBlank(edition.text),
                  'isbn': nullIfBlank(isbn.text),
                  'copyright_notes': nullIfBlank(notes.text),
                  'cover_asset_id': cover,
                  'status': 'published',
                }, id: book?.id),
              );
              if (ok && dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}

const _customKey = '__custom__';

/// Pick a ready-made structure or define custom levels.
Future<bool> _structureDialog(
  BuildContext context,
  WidgetRef ref,
  Book book,
) async {
  final l10n = AppLocalizations.of(context);
  String template = bookStructureTemplates.keys.first;
  final custom = <TextEditingController>[TextEditingController()];
  var isCustom = false;

  final ok = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(l10n.adminSetStructure),
        content: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(l10n.adminStructureExplain),
                const SizedBox(height: Space.md),
                RadioGroup<String>(
                  groupValue: isCustom ? _customKey : template,
                  onChanged: (v) => setState(() {
                    isCustom = v == _customKey;
                    if (!isCustom) template = v!;
                  }),
                  child: Column(
                    children: [
                      for (final name in bookStructureTemplates.keys)
                        RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          value: name,
                          title: Text(name),
                        ),
                      RadioListTile<String>(
                        contentPadding: EdgeInsets.zero,
                        value: _customKey,
                        title: Text(l10n.adminCustomStructure),
                      ),
                    ],
                  ),
                ),
                if (isCustom) ...[
                  for (final (i, c) in custom.indexed)
                    Padding(
                      padding: const EdgeInsets.only(bottom: Space.xs),
                      child: TextField(
                        controller: c,
                        decoration: InputDecoration(
                          labelText: '${l10n.adminLevel} ${i + 1}',
                          hintText: l10n.adminLevelHint,
                        ),
                      ),
                    ),
                  if (custom.length < 6)
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => custom.add(TextEditingController())),
                      icon: const Icon(Icons.add),
                      label: Text(l10n.adminAddLevel),
                    ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(l10n.adminCancel),
          ),
          FilledButton(
            onPressed: () async {
              final levels = isCustom
                  ? [
                      for (final c in custom)
                        if (c.text.trim().isNotEmpty)
                          BookLevelDraft(
                            slugify(c.text).replaceAll('-', '_'),
                            c.text.trim(),
                            c.text.trim(),
                            usesPage: true,
                          ),
                    ]
                  : bookStructureTemplates[template]!;
              if (levels.isEmpty) return;
              final ok = await runAdminAction(
                context,
                () => ref
                    .read(adminRepositoryProvider)
                    .createStructure(
                      bookId: book.id,
                      name: isCustom ? l10n.adminCustomStructure : template,
                      levels: levels,
                    ),
              );
              if (ok && dialogContext.mounted) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: Text(l10n.adminSave),
          ),
        ],
      ),
    ),
  );
  return ok ?? false;
}
