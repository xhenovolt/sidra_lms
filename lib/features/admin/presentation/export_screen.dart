import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/data/data_providers.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import 'admin_common.dart';

/// Columns, in order, for each export (`admin_export(kind)`).
const exportColumns = {
  'learners': [
    'name',
    'phone',
    'email',
    'username',
    'active',
    'joined',
    'courses',
  ],
  'enrolments': [
    'learner',
    'course',
    'status',
    'source',
    'enrolled',
    'completed',
    'lessons_done',
    'lessons_total',
  ],
  'payments': [
    'date',
    'learner',
    'course',
    'amount',
    'currency',
    'method',
    'status',
    'reference',
  ],
  'progress': [
    'learner',
    'course',
    'lesson',
    'status',
    'completed',
    'last_opened',
  ],
};

/// Rows as CSV with a header line; quotes where needed. Starts with a
/// byte-order mark so Excel reads Arabic names correctly.
String toCsv(List<String> columns, List<Map<String, dynamic>> rows) {
  String cell(Object? v) {
    final s = v?.toString() ?? '';
    return RegExp(r'[",\r\n]').hasMatch(s) ? '"${s.replaceAll('"', '""')}"' : s;
  }

  return '﻿${[columns.join(','), for (final r in rows) columns.map((c) => cell(r[c])).join(',')].join('\r\n')}\r\n';
}

/// Settings → Export data: spreadsheets of learners, enrolments, payments
/// and progress, so the organisation's records are never locked in the app.
class ExportScreen extends ConsumerStatefulWidget {
  const ExportScreen({super.key});

  @override
  ConsumerState<ExportScreen> createState() => _ExportScreenState();
}

class _ExportScreenState extends ConsumerState<ExportScreen> {
  String? _busy;

  Future<void> _export(String kind) async {
    final l10n = AppLocalizations.of(context);
    setState(() => _busy = kind);
    List<Map<String, dynamic>>? rows;
    await runAdminAction(context, () async {
      rows = await ref
          .read(postgresApiProvider)
          .rpcRows('admin_export', params: {'p_kind': kind});
    });
    if (!mounted) return;
    setState(() => _busy = null);
    final data = rows;
    if (data == null) return;
    final messenger = ScaffoldMessenger.of(context);
    if (data.isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(l10n.exportEmpty)));
      return;
    }
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final bytes = Uint8List.fromList(
      utf8.encode(toCsv(exportColumns[kind]!, data)),
    );
    final saved = await FilePicker.saveFile(
      fileName: 'sidra-$kind-$today.csv',
      bytes: bytes,
      mimeType: 'text/csv',
    );
    if (saved != null && mounted) {
      messenger.showSnackBar(
        SnackBar(content: Text(l10n.exportSaved(data.length))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final items = [
      (
        'learners',
        Icons.people_outline,
        l10n.exportLearners,
        l10n.exportLearnersHint,
      ),
      (
        'enrolments',
        Icons.how_to_reg_outlined,
        l10n.exportEnrolments,
        l10n.exportEnrolmentsHint,
      ),
      (
        'payments',
        Icons.payments_outlined,
        l10n.exportPayments,
        l10n.exportPaymentsHint,
      ),
      (
        'progress',
        Icons.insights_outlined,
        l10n.exportProgress,
        l10n.exportProgressHint,
      ),
    ];
    return Scaffold(
      appBar: AppBar(title: Text(l10n.exportTitle)),
      body: ListView(
        padding: const EdgeInsets.all(Space.md),
        children: [
          Text(l10n.exportNote, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: Space.md),
          for (final (kind, icon, title, hint) in items)
            Card(
              child: ListTile(
                leading: Icon(icon),
                title: Text(title),
                subtitle: Text(hint),
                trailing: _busy == kind
                    ? const SizedBox.square(
                        dimension: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.file_download_outlined),
                onTap: _busy == null ? () => _export(kind) : null,
              ),
            ),
        ],
      ),
    );
  }
}
