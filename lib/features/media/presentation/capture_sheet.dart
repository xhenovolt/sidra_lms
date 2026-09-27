import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_document_scanner/google_mlkit_document_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../admin/data/admin_repository.dart' show fileKindFor;
import '../../audio/presentation/audio_widgets.dart';

/// Ways to add content, straight from the phone.
enum CaptureSource {
  photo, // camera
  video, // camera
  scan, // document scanner: several pages → one PDF
  audio, // microphone
  gallery, // pictures / videos already on the phone
  file, // any document
  paste, // text from the clipboard
}

/// What was captured. [text] is set for pasted text (no file).
class CapturedFile {
  const CapturedFile({
    required this.path,
    required this.name,
    required this.kind,
    required this.bytes,
    this.text,
    this.pages,
  });
  final String path;
  final String name;

  /// image | audio | video | document | text
  final String kind;
  final int bytes;
  final String? text;

  /// Scanned PDF: number of pages.
  final int? pages;
}

String formatFileSize(int bytes) {
  if (bytes < 1024) return '$bytes B';
  if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(0)} KB';
  return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
}

/// Files above this size get a warning before upload (mobile data).
const largeFileBytes = 25 * 1024 * 1024;

/// Offers the allowed ways to add content, captures it, then shows what
/// will be uploaded (name, type, size, preview) for confirmation.
Future<CapturedFile?> captureContent(
  BuildContext context, {
  Set<CaptureSource> allow = const {...CaptureSource.values},
  List<String> fileExtensions = const [
    'pdf', 'doc', 'docx', 'ppt', 'pptx', 'xls', 'xlsx', 'txt', //
    'jpg', 'jpeg', 'png', 'webp', 'mp3', 'wav', 'm4a', 'aac', 'mp4', 'mov',
  ],
}) async {
  final l10n = AppLocalizations.of(context);
  final choices = <(CaptureSource, IconData, String)>[
    (CaptureSource.photo, Icons.photo_camera_outlined, l10n.capPhoto),
    (CaptureSource.video, Icons.videocam_outlined, l10n.capVideo),
    (CaptureSource.scan, Icons.document_scanner_outlined, l10n.capScan),
    (CaptureSource.audio, Icons.mic_none, l10n.capAudio),
    (CaptureSource.gallery, Icons.photo_library_outlined, l10n.capGallery),
    (CaptureSource.file, Icons.attach_file, l10n.capFile),
    (CaptureSource.paste, Icons.content_paste, l10n.capPaste),
  ].where((c) => allow.contains(c.$1)).toList();

  final source = choices.length == 1
      ? choices.single.$1
      : await showModalBottomSheet<CaptureSource>(
          context: context,
          showDragHandle: true,
          builder: (context) => SafeArea(
            child: GridView.count(
              crossAxisCount: 4,
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(
                Space.md,
                0,
                Space.md,
                Space.md,
              ),
              children: [
                for (final c in choices)
                  InkWell(
                    borderRadius: BorderRadius.circular(Radii.md),
                    onTap: () => Navigator.pop(context, c.$1),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircleAvatar(radius: 24, child: Icon(c.$2)),
                        const SizedBox(height: Space.xs),
                        Text(
                          c.$3,
                          textAlign: TextAlign.center,
                          style: Theme.of(context).textTheme.labelSmall,
                          maxLines: 2,
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        );
  if (source == null || !context.mounted) return null;

  CapturedFile? captured;
  try {
    captured = switch (source) {
      CaptureSource.photo => await _fromXFile(
        await ImagePicker().pickImage(
          source: ImageSource.camera,
          maxWidth: 2000,
          maxHeight: 2000,
          imageQuality: 85,
        ),
        'image',
      ),
      CaptureSource.video => await _fromXFile(
        await ImagePicker().pickVideo(
          source: ImageSource.camera,
          maxDuration: const Duration(minutes: 15),
        ),
        'video',
      ),
      CaptureSource.gallery => await _fromXFile(
        await ImagePicker().pickMedia(
          maxWidth: 2000,
          maxHeight: 2000,
          imageQuality: 85,
        ),
        null,
      ),
      CaptureSource.scan => await _scan(),
      CaptureSource.audio => context.mounted ? await _record(context) : null,
      CaptureSource.file => await _file(fileExtensions),
      CaptureSource.paste => await _paste(),
    };
  } on PlatformException catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.capFailed(e.message ?? e.code))),
      );
    }
    return null;
  }
  if (captured == null || !context.mounted) return null;
  if (captured.kind == 'text') return captured;
  return _confirm(context, captured);
}

Future<CapturedFile?> _fromXFile(XFile? x, String? kind) async {
  if (x == null) return null;
  final size = await File(x.path).length();
  return CapturedFile(
    path: x.path,
    name: x.name,
    kind: kind ?? fileKindFor(x.name),
    bytes: size,
  );
}

Future<CapturedFile?> _scan() async {
  final scanner = DocumentScanner(
    options: DocumentScannerOptions(
      documentFormats: const {DocumentFormat.pdf},
      pageLimit: 50,
      mode: ScannerMode.full,
      isGalleryImport: true,
    ),
  );
  try {
    final result = await scanner.scanDocument();
    final pdf = result.pdf;
    if (pdf == null) return null;
    final path = pdf.uri.startsWith('file:')
        ? Uri.parse(pdf.uri).toFilePath()
        : pdf.uri;
    final stamp = DateTime.now();
    final name =
        'scan-${stamp.year}${_two(stamp.month)}${_two(stamp.day)}-${_two(stamp.hour)}${_two(stamp.minute)}.pdf';
    return CapturedFile(
      path: path,
      name: name,
      kind: 'document',
      bytes: await File(path).length(),
      pages: pdf.pageCount,
    );
  } finally {
    await scanner.close();
  }
}

String _two(int v) => v.toString().padLeft(2, '0');

Future<CapturedFile?> _file(List<String> extensions) async {
  final f = await FilePicker.pickFile(
    type: FileType.custom,
    allowedExtensions: extensions,
  );
  final path = f?.path;
  if (f == null || path == null) return null;
  return CapturedFile(
    path: path,
    name: f.name,
    kind: fileKindFor(f.name),
    bytes: await File(path).length(),
  );
}

Future<CapturedFile?> _paste() async {
  final data = await Clipboard.getData(Clipboard.kTextPlain);
  final text = data?.text?.trim();
  if (text == null || text.isEmpty) return null;
  // No file yet: a text block uses the text; resources write it to a file.
  return CapturedFile(
    path: '',
    name: 'pasted-text.txt',
    kind: 'text',
    bytes: text.length,
    text: text,
  );
}

/// Pasted text as a .txt file (for uploading as a resource).
Future<CapturedFile> pastedTextAsFile(CapturedFile pasted) async {
  final dir = await getTemporaryDirectory();
  final file = File(
    '${dir.path}${Platform.pathSeparator}pasted-${const Uuid().v4().substring(0, 8)}.txt',
  );
  await file.writeAsString(pasted.text ?? '');
  return CapturedFile(
    path: file.path,
    name: pasted.name,
    kind: 'document',
    bytes: await file.length(),
  );
}

Future<CapturedFile?> _record(BuildContext context) async {
  final audio = await showModalBottomSheet<RecordedAudio>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (_) => const _RecordSheet(),
  );
  if (audio == null) return null;
  return CapturedFile(
    path: audio.path,
    name: audio.fileName,
    kind: 'audio',
    bytes: await File(audio.path).length(),
  );
}

class _RecordSheet extends StatefulWidget {
  const _RecordSheet();

  @override
  State<_RecordSheet> createState() => _RecordSheetState();
}

class _RecordSheetState extends State<_RecordSheet> {
  RecordedAudio? _audio;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(l10n.capAudio, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: Space.sm),
          VoiceRecorder(onChanged: (a) => setState(() => _audio = a)),
          FilledButton(
            onPressed: _audio == null
                ? null
                : () => Navigator.pop(context, _audio),
            child: Text(l10n.portionUseRecording),
          ),
        ],
      ),
    );
  }
}

/// Shows what will be uploaded — including how much storage it takes —
/// before anything is sent.
Future<CapturedFile?> _confirm(BuildContext context, CapturedFile f) {
  final l10n = AppLocalizations.of(context);
  final theme = Theme.of(context);
  final big = f.bytes > largeFileBytes;
  return showModalBottomSheet<CapturedFile>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (context) => Padding(
      padding: const EdgeInsets.fromLTRB(Space.md, 0, Space.md, Space.lg),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (f.kind == 'image')
              ClipRRect(
                borderRadius: BorderRadius.circular(Radii.md),
                child: Image.file(
                  File(f.path),
                  height: 240,
                  fit: BoxFit.contain,
                ),
              )
            else if (f.kind == 'audio')
              VoicePlayer(filePath: f.path, title: f.name, icon: Icons.mic)
            else
              Icon(
                f.kind == 'video'
                    ? Icons.movie_outlined
                    : Icons.description_outlined,
                size: 72,
                color: theme.colorScheme.primary,
              ),
            const SizedBox(height: Space.sm),
            Text(
              f.name,
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: Space.xs),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: Space.sm,
              children: [
                Chip(
                  avatar: const Icon(Icons.sd_storage_outlined, size: 18),
                  label: Text(l10n.capSize(formatFileSize(f.bytes))),
                ),
                if (f.pages != null) Chip(label: Text(l10n.capPages(f.pages!))),
              ],
            ),
            if (big)
              Padding(
                padding: const EdgeInsets.only(top: Space.xs),
                child: Text(
                  l10n.capLarge,
                  textAlign: TextAlign.center,
                  style: TextStyle(color: theme.colorScheme.error),
                ),
              ),
            const SizedBox(height: Space.md),
            FilledButton.icon(
              onPressed: () => Navigator.pop(context, f),
              icon: const Icon(Icons.cloud_upload_outlined),
              label: Text(l10n.capUse),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(l10n.adminCancel),
            ),
          ],
        ),
      ),
    ),
  );
}
