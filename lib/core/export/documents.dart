import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// A titled table for a PDF or a spreadsheet (reports, the journal…).
class DocTable {
  const DocTable({
    required this.title,
    required this.columns,
    required this.rows,
    this.subtitle,
    this.numeric = const {},
  });

  final String title;
  final String? subtitle;
  final List<String> columns;

  /// Each row has one value per column (text or numbers).
  final List<List<Object?>> rows;

  /// Columns (by index) holding amounts: right-aligned, written as numbers.
  final Set<int> numeric;
}

/// Amiri covers English and Arabic, so learners' names print either way.
Future<pw.ThemeData> pdfTheme() async => pw.ThemeData.withFont(
  base: pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Regular.ttf')),
  bold: pw.Font.ttf(await rootBundle.load('assets/fonts/Amiri-Bold.ttf')),
);

bool _arabic(String s) => RegExp(r'[؀-ۿ]').hasMatch(s);

/// Text that lays out right-to-left when it is Arabic.
pw.Widget pdfText(String s, {pw.TextStyle? style, pw.TextAlign? align}) =>
    pw.Text(
      s,
      style: style,
      textAlign: align,
      textDirection: _arabic(s) ? pw.TextDirection.rtl : pw.TextDirection.ltr,
    );

String _cell(Object? v) => switch (v) {
  null => '',
  num n =>
    n == n.roundToDouble()
        ? n.round().toString().replaceAllMapped(
            RegExp(r'\B(?=(\d{3})+(?!\d))'),
            (_) => ',',
          )
        : n.toStringAsFixed(2),
  _ => '$v',
};

/// One or more tables as an A4 PDF, with a header line (organisation, date).
Future<Uint8List> tablesToPdf(
  List<DocTable> tables, {
  required String header,
}) async {
  final doc = pw.Document(theme: await pdfTheme());
  doc.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      header: (_) => pw.Padding(
        padding: const pw.EdgeInsets.only(bottom: 8),
        child: pdfText(
          header,
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ),
      footer: (c) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(
          '${c.pageNumber} / ${c.pagesCount}',
          style: const pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
        ),
      ),
      build: (_) => [
        for (final t in tables) ...[
          pdfText(
            t.title,
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          if (t.subtitle != null)
            pdfText(t.subtitle!, style: const pw.TextStyle(fontSize: 10)),
          pw.SizedBox(height: 6),
          pw.TableHelper.fromTextArray(
            headers: t.columns,
            data: [
              for (final r in t.rows) [for (final v in r) _cell(v)],
            ],
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              fontSize: 10,
            ),
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
            cellAlignments: {
              for (final i in t.numeric) i: pw.Alignment.centerRight,
            },
          ),
          pw.SizedBox(height: 16),
        ],
      ],
    ),
  );
  return doc.save();
}

String _xml(String s) => s
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;');

String _col(int i) {
  var n = i + 1;
  var s = '';
  while (n > 0) {
    final r = (n - 1) % 26;
    s = String.fromCharCode(65 + r) + s;
    n = (n - 1) ~/ 26;
  }
  return s;
}

/// Tables as an Excel workbook (.xlsx), one sheet each. Amounts stay
/// numbers, so the accountant can add them up.
Uint8List tablesToXlsx(List<DocTable> tables) {
  String sheetName(int i) {
    final clean = tables[i].title
        .replaceAll(RegExp(r'[\[\]\*\?/\\:]'), ' ')
        .trim();
    final name = clean.isEmpty ? 'Sheet${i + 1}' : clean;
    return name.length > 31 ? name.substring(0, 31) : name;
  }

  String sheet(DocTable t) {
    final rows = StringBuffer();
    void row(int r, List<Object?> values, {bool header = false}) {
      rows.write('<row r="${r + 1}">');
      for (final (c, v) in values.indexed) {
        final ref = '${_col(c)}${r + 1}';
        if (v is num && !header) {
          rows.write('<c r="$ref"><v>$v</v></c>');
        } else if (v != null && '$v'.isNotEmpty) {
          rows.write(
            '<c r="$ref" t="inlineStr"${header ? ' s="1"' : ''}>'
            '<is><t xml:space="preserve">${_xml('$v')}</t></is></c>',
          );
        }
      }
      rows.write('</row>');
    }

    row(0, t.columns, header: true);
    for (final (i, r) in t.rows.indexed) {
      row(i + 1, r);
    }
    return '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<sheetData>$rows</sheetData></worksheet>';
  }

  final archive = Archive();
  void add(String name, String content) {
    final bytes = utf8.encode(content);
    archive.addFile(ArchiveFile(name, bytes.length, bytes));
  }

  add(
    '[Content_Types].xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">'
        '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>'
        '<Default Extension="xml" ContentType="application/xml"/>'
        '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>'
        '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>'
        '${[for (var i = 0; i < tables.length; i++) '<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>'].join()}'
        '</Types>',
  );
  add(
    '_rels/.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>'
        '</Relationships>',
  );
  add(
    'xl/workbook.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" '
        'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"><sheets>'
        '${[for (var i = 0; i < tables.length; i++) '<sheet name="${_xml(sheetName(i))}" sheetId="${i + 1}" r:id="rId${i + 1}"/>'].join()}'
        '</sheets></workbook>',
  );
  add(
    'xl/_rels/workbook.xml.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">'
        '${[for (var i = 0; i < tables.length; i++) '<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>'].join()}'
        '<Relationship Id="rId${tables.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>'
        '</Relationships>',
  );
  // Style 1 = bold (the header row).
  add(
    'xl/styles.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>'
        '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">'
        '<fonts count="2"><font><sz val="11"/><name val="Calibri"/></font>'
        '<font><b/><sz val="11"/><name val="Calibri"/></font></fonts>'
        '<fills count="1"><fill><patternFill patternType="none"/></fill></fills>'
        '<borders count="1"><border/></borders>'
        '<cellStyleXfs count="1"><xf/></cellStyleXfs>'
        '<cellXfs count="2"><xf fontId="0"/><xf fontId="1" applyFont="1"/></cellXfs>'
        '</styleSheet>',
  );
  for (final (i, t) in tables.indexed) {
    add('xl/worksheets/sheet${i + 1}.xml', sheet(t));
  }
  return Uint8List.fromList(ZipEncoder().encode(archive));
}

/// Asks where to save [bytes]; true when saved.
Future<bool> saveDocument(String fileName, Uint8List bytes) async {
  final pdf = fileName.endsWith('.pdf');
  final saved = await FilePicker.saveFile(
    fileName: fileName,
    bytes: bytes,
    mimeType: pdf
        ? 'application/pdf'
        : 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet',
  );
  return saved != null;
}
