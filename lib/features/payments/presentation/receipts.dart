import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../../core/export/documents.dart';
import '../../../core/theme/app_tokens.dart';
import '../../../l10n/app_localizations.dart';
import '../../../shared/models/json.dart';
import '../../../shared/widgets/state_views.dart';
import '../data/payments_repository.dart';

final myPaymentHistoryProvider = FutureProvider.autoDispose<List<Json>>(
  (ref) => ref.watch(paymentsRepositoryProvider).myPaymentHistory(),
);

String receiptNo(Object? n) => 'SR-${'$n'.padLeft(6, '0')}';

String _status(AppLocalizations l10n, String s) => switch (s) {
  'verified' => l10n.paymentVerified,
  'reversed' => l10n.paymentReversed,
  'failed' => l10n.paymentFailed,
  'rejected' => l10n.paymentRejected,
  'pending' => l10n.paymentPending,
  _ => l10n.paymentInProgress,
};

/// The learner's payments in every course; confirmed ones open a receipt.
class MyPaymentsScreen extends ConsumerWidget {
  const MyPaymentsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final rows = ref.watch(myPaymentHistoryProvider);
    final date = DateFormat.yMMMd(l10n.localeName);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rcMyPayments)),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(myPaymentHistoryProvider.future),
        child: switch (rows) {
          AsyncData(:final value) when value.isEmpty => ListView(
            children: [
              EmptyView(
                icon: Icons.receipt_long_outlined,
                title: l10n.rcNoPayments,
              ),
            ],
          ),
          AsyncData(:final value) => ListView.separated(
            itemCount: value.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, i) {
              final p = value[i];
              final receipt = p['receipt_number'];
              final refunded = p.numOrNull('refunded') ?? 0;
              final from = p.dateOrNull('covers_from');
              final until = p.dateOrNull('covers_until');
              return ListTile(
                leading: Icon(
                  receipt != null
                      ? Icons.receipt_long_outlined
                      : Icons.hourglass_empty,
                ),
                title: Text(
                  '${p.strOrNull('course') ?? ''} · '
                  '${formatMoney(p.numOrNull('amount') ?? 0, p.strOrNull('currency') ?? 'UGX')}',
                ),
                subtitle: Text(
                  [
                    date.format(DateTime.parse(p.str('created_at')).toLocal()),
                    _status(l10n, p.str('status')),
                    if (from != null && until != null)
                      l10n.rcCovers(date.format(from), date.format(until)),
                    if (refunded > 0)
                      l10n.rcRefunded(
                        formatMoney(refunded, p.strOrNull('currency') ?? 'UGX'),
                      ),
                    if (receipt != null) receiptNo(receipt),
                  ].join(' · '),
                ),
                trailing: receipt != null
                    ? const Icon(Icons.chevron_right)
                    : null,
                onTap: receipt == null
                    ? null
                    : () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => ReceiptScreen(paymentId: p.str('id')),
                        ),
                      ),
              );
            },
          ),
          AsyncError(:final error) => ListView(
            children: [
              ErrorView(
                error: error,
                onRetry: () => ref.invalidate(myPaymentHistoryProvider),
              ),
            ],
          ),
          _ => const LoadingView(),
        },
      ),
    );
  }
}

/// One receipt, as issued by the database, with a PDF to keep or share.
class ReceiptScreen extends ConsumerStatefulWidget {
  const ReceiptScreen({super.key, required this.paymentId});
  final String paymentId;

  @override
  ConsumerState<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends ConsumerState<ReceiptScreen> {
  late Future<Json> _receipt = _load();
  bool _saving = false;

  Future<Json> _load() =>
      ref.read(paymentsRepositoryProvider).receipt(widget.paymentId);

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.rcReceipt)),
      body: FutureBuilder<Json>(
        future: _receipt,
        builder: (context, snap) {
          if (snap.hasError) {
            return ErrorView(
              error: snap.error!,
              onRetry: () => setState(() => _receipt = _load()),
            );
          }
          if (!snap.hasData) return const LoadingView();
          final r = snap.data!;
          final lines = receiptLines(l10n, r);
          return ListView(
            padding: const EdgeInsets.all(Space.lg),
            children: [
              Text(
                r.strOrNull('org_name') ?? '',
                style: theme.textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              Text(
                '${l10n.rcReceipt} ${receiptNo(r['receipt_number'])}',
                style: theme.textTheme.titleMedium,
                textAlign: TextAlign.center,
              ),
              if (r.str('status') == 'reversed')
                Padding(
                  padding: const EdgeInsets.only(top: Space.xs),
                  child: Text(
                    l10n.rcCancelled,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              const SizedBox(height: Space.md),
              Card(
                child: Column(
                  children: [
                    for (final (k, v) in lines)
                      ListTile(dense: true, title: Text(k), trailing: Text(v)),
                  ],
                ),
              ),
              const SizedBox(height: Space.md),
              FilledButton.icon(
                onPressed: _saving
                    ? null
                    : () async {
                        setState(() => _saving = true);
                        final bytes = await receiptPdf(l10n, r);
                        final ok = await saveDocument(
                          'receipt-${receiptNo(r['receipt_number'])}.pdf',
                          bytes,
                        );
                        if (!context.mounted) return;
                        setState(() => _saving = false);
                        if (ok) {
                          ScaffoldMessenger.of(
                            context,
                          ).showSnackBar(SnackBar(content: Text(l10n.rcSaved)));
                        }
                      },
                icon: const Icon(Icons.picture_as_pdf_outlined),
                label: Text(l10n.rcSavePdf),
              ),
              const SizedBox(height: Space.sm),
              Text(
                l10n.rcIssuedNote,
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ],
          );
        },
      ),
    );
  }
}

/// The receipt's lines (label, value), shared by the screen and the PDF.
List<(String, String)> receiptLines(AppLocalizations l10n, Json r) {
  final date = DateFormat.yMMMd(l10n.localeName);
  final currency = r.strOrNull('currency') ?? 'UGX';
  final from = r.dateOrNull('covers_from');
  final until = r.dateOrNull('covers_until');
  final refunded = r.numOrNull('refunded') ?? 0;
  return [
    (l10n.rcReceivedFrom, r.strOrNull('learner') ?? ''),
    if (r.strOrNull('learner_phone') != null)
      (l10n.rcPhone, r.str('learner_phone')),
    (l10n.rcFor, r.strOrNull('course') ?? ''),
    if (from != null && until != null)
      (l10n.rcPeriod, '${date.format(from)} – ${date.format(until)}'),
    (l10n.rcAmount, formatMoney(r.numOrNull('amount') ?? 0, currency)),
    if (refunded > 0) (l10n.rcRefundedLabel, formatMoney(refunded, currency)),
    (l10n.rcMethod, _method(l10n, r.strOrNull('method') ?? '')),
    if (r.strOrNull('provider_reference') != null)
      (l10n.rcTransactionId, r.str('provider_reference')),
    if (r.strOrNull('paid_on') != null)
      (l10n.rcPaidOn, date.format(DateTime.parse(r.str('paid_on')))),
    if (r.strOrNull('received_by') != null)
      (l10n.rcConfirmedBy, r.str('received_by')),
    (l10n.rcSidraRef, r.strOrNull('reference') ?? ''),
  ];
}

String _method(AppLocalizations l10n, String m) => switch (m) {
  'marzpay' => l10n.methodMarzPay,
  'mobile_money' => l10n.payMethodMobileMoney,
  'bank' => l10n.payMethodBank,
  'cash' => l10n.methodCash,
  _ => l10n.methodOther,
};

/// The receipt as an A5 PDF.
Future<Uint8List> receiptPdf(AppLocalizations l10n, Json r) async {
  final doc = pw.Document(theme: await pdfTheme());
  final contact = [
    ?r.strOrNull('org_phone'),
    ?r.strOrNull('org_email'),
  ].join(' · ');
  doc.addPage(
    pw.Page(
      pageFormat: PdfPageFormat.a5,
      margin: const pw.EdgeInsets.all(28),
      build: (_) => pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.stretch,
        children: [
          pdfText(
            r.strOrNull('org_name') ?? '',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
            align: pw.TextAlign.center,
          ),
          if (r.strOrNull('org_name_ar') != null)
            pdfText(
              r.str('org_name_ar'),
              style: const pw.TextStyle(fontSize: 14),
              align: pw.TextAlign.center,
            ),
          if (contact.isNotEmpty)
            pdfText(
              contact,
              style: const pw.TextStyle(fontSize: 9),
              align: pw.TextAlign.center,
            ),
          pw.SizedBox(height: 12),
          pdfText(
            '${l10n.rcReceipt} ${receiptNo(r['receipt_number'])}',
            style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            align: pw.TextAlign.center,
          ),
          if (r.str('status') == 'reversed')
            pdfText(
              l10n.rcCancelled,
              style: const pw.TextStyle(color: PdfColors.red),
              align: pw.TextAlign.center,
            ),
          pw.SizedBox(height: 12),
          for (final (k, v) in receiptLines(l10n, r))
            pw.Padding(
              padding: const pw.EdgeInsets.symmetric(vertical: 3),
              child: pw.Row(
                children: [
                  pw.Expanded(
                    child: pdfText(
                      k,
                      style: const pw.TextStyle(color: PdfColors.grey700),
                    ),
                  ),
                  pw.Expanded(child: pdfText(v, align: pw.TextAlign.right)),
                ],
              ),
            ),
          pw.Spacer(),
          pdfText(
            l10n.rcIssuedNote,
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
            align: pw.TextAlign.center,
          ),
        ],
      ),
    ),
  );
  return doc.save();
}
