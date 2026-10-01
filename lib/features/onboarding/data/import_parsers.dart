import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:xml/xml.dart';

/// One learner as read from a file, a list, contacts or a WhatsApp export,
/// before the server checks it. Only [name] and a phone or email are
/// needed; the rest is kept when present.
class ImportRow {
  ImportRow({
    this.name = '',
    this.phone = '',
    this.email = '',
    this.externalId = '',
    this.note = '',
    this.course = '',
    this.group = '',
    this.teacher = '',
    this.status = '',
    this.lastFeedback = '',
    this.page,
    this.line,
    this.lastSeen,
    this.messages = 0,
  });

  String name;
  String phone;
  String email;
  String externalId;
  String note;
  String course;
  String group;
  String teacher;
  String status;
  String lastFeedback;
  int? page;
  int? line;

  /// WhatsApp export: when this person last wrote, and how often.
  DateTime? lastSeen;
  int messages;

  Map<String, Object?> toPreview() => {
    'name': name,
    'phone': phone,
    'email': email,
    'external_id': externalId,
  };
}

/// What was read, plus anything the reader wants the person to know.
class ParsedImport {
  const ParsedImport(this.rows, {this.warnings = const [], this.source = 'csv'});
  final List<ImportRow> rows;
  final List<String> warnings;
  final String source;
}

// ------------------------------------------------------------- columns --

/// Header names recognised for each field (lower case, English and Arabic).
const _columns = <String, List<String>>{
  'name': ['name', 'full name', 'fullname', 'learner', 'learner name', 'student', 'student name', 'names', 'الاسم', 'اسم'],
  'first': ['first name', 'firstname', 'given name'],
  'last': ['last name', 'lastname', 'surname', 'family name'],
  'phone': ['phone', 'phone number', 'mobile', 'mobile number', 'tel', 'telephone', 'contact', 'whatsapp', 'number', 'الهاتف', 'رقم الهاتف', 'الجوال'],
  'email': ['email', 'e-mail', 'email address', 'البريد الإلكتروني'],
  'external_id': ['learner id', 'student id', 'id', 'reg no', 'registration number', 'admission number', 'reference', 'external id'],
  'note': ['notes', 'note', 'comments', 'comment', 'remarks', 'ملاحظات'],
  'course': ['course', 'class', 'subject', 'الدورة'],
  'group': ['group', 'teaching group', 'stream', 'المجموعة'],
  'teacher': ['teacher', 'ustadh', 'ustadha', 'instructor', 'المعلم'],
  'status': ['status', 'progress status'],
  'feedback': ['feedback', 'last feedback', 'teacher feedback'],
  'page': ['page', 'current page', 'صفحة'],
  'line': ['line', 'current line', 'سطر'],
  'level': ['level', 'starting level'],
  'gender': ['gender', 'sex'],
};

String? _fieldFor(String header) {
  final h = header.trim().toLowerCase().replaceAll(RegExp(r'[_\s]+'), ' ');
  for (final e in _columns.entries) {
    if (e.value.contains(h)) return e.key;
  }
  return null;
}

/// Rows of cells (first row = headers) → [ImportRow]s. Unknown columns go
/// into the note so nothing is lost.
ParsedImport rowsFromTable(List<List<String>> table, {String source = 'csv'}) {
  final warnings = <String>[];
  final cleaned = [
    for (final r in table)
      if (r.any((c) => c.trim().isNotEmpty)) r,
  ];
  if (cleaned.isEmpty) return ParsedImport(const [], source: source);
  final headers = cleaned.first;
  final fields = [for (final h in headers) _fieldFor(h)];
  if (!fields.contains('name') && !fields.contains('first')) {
    warnings.add('no_name_column');
  }
  if (!fields.contains('phone') && !fields.contains('email')) {
    warnings.add('no_phone_column');
  }
  final rows = <ImportRow>[];
  for (final cells in cleaned.skip(1)) {
    final r = ImportRow();
    String first = '', last = '';
    final extra = <String>[];
    for (var i = 0; i < cells.length && i < headers.length; i++) {
      final v = cells[i].trim();
      if (v.isEmpty) continue;
      switch (fields[i]) {
        case 'name':
          r.name = v;
        case 'first':
          first = v;
        case 'last':
          last = v;
        case 'phone':
          r.phone = v;
        case 'email':
          r.email = v;
        case 'external_id':
          r.externalId = v;
        case 'note':
          extra.add(v);
        case 'course':
          r.course = v;
        case 'group':
          r.group = v;
        case 'teacher':
          r.teacher = v;
        case 'status':
          r.status = v;
        case 'feedback':
          r.lastFeedback = v;
        case 'page':
          r.page = int.tryParse(v);
        case 'line':
          r.line = int.tryParse(v);
        case 'level' || 'gender':
          extra.add('${headers[i].trim()}: $v');
        default:
          extra.add('${headers[i].trim()}: $v');
      }
    }
    if (r.name.isEmpty && (first.isNotEmpty || last.isNotEmpty)) {
      r.name = '$first $last'.trim();
    }
    r.note = extra.join('; ');
    rows.add(r);
  }
  final courses = {for (final r in rows) if (r.course.isNotEmpty) r.course.toLowerCase()};
  if (courses.length > 1) warnings.add('several_courses');
  return ParsedImport(rows, warnings: warnings, source: source);
}

// ----------------------------------------------------------------- CSV --

/// CSV / TSV text (quoted fields, "" escapes, CRLF), delimiter detected.
List<List<String>> parseCsv(String text) {
  text = text.replaceFirst('﻿', '');
  final firstLine = text.split(RegExp(r'\r?\n')).first;
  final delim = [',', ';', '\t']
      .reduce((a, b) => firstLine.split(a).length >= firstLine.split(b).length ? a : b);
  final rows = <List<String>>[];
  var row = <String>[];
  final cell = StringBuffer();
  var quoted = false;
  for (var i = 0; i < text.length; i++) {
    final c = text[i];
    if (quoted) {
      if (c == '"') {
        if (i + 1 < text.length && text[i + 1] == '"') {
          cell.write('"');
          i++;
        } else {
          quoted = false;
        }
      } else {
        cell.write(c);
      }
    } else if (c == '"') {
      quoted = true;
    } else if (c == delim) {
      row.add(cell.toString());
      cell.clear();
    } else if (c == '\n' || c == '\r') {
      if (c == '\r' && i + 1 < text.length && text[i + 1] == '\n') i++;
      row.add(cell.toString());
      cell.clear();
      rows.add(row);
      row = <String>[];
    } else {
      cell.write(c);
    }
  }
  if (cell.isNotEmpty || row.isNotEmpty) {
    row.add(cell.toString());
    rows.add(row);
  }
  return rows;
}

// ---------------------------------------------------------------- XLSX --

/// The first worksheet of an .xlsx file as rows of text.
List<List<String>> parseXlsx(Uint8List bytes) {
  final zip = ZipDecoder().decodeBytes(bytes);
  String? read(String name) {
    final f = zip.findFile(name);
    return f == null ? null : utf8.decode(f.content as List<int>);
  }

  final shared = <String>[];
  final sst = read('xl/sharedStrings.xml');
  if (sst != null) {
    for (final si in XmlDocument.parse(sst).findAllElements('si')) {
      shared.add(si.findAllElements('t').map((t) => t.innerText).join());
    }
  }
  // The first sheet listed in the workbook (usually sheet1.xml).
  final sheetName = zip.files
      .map((f) => f.name)
      .where((n) => RegExp(r'^xl/worksheets/sheet\d+\.xml$').hasMatch(n))
      .fold<String?>(null, (a, b) => a == null || b.compareTo(a) < 0 ? b : a);
  final sheet = sheetName == null ? null : read(sheetName);
  if (sheet == null) return const [];
  int col(String ref) {
    var n = 0;
    for (final ch in ref.replaceAll(RegExp(r'\d'), '').codeUnits) {
      n = n * 26 + (ch - 64);
    }
    return n - 1;
  }

  final rows = <List<String>>[];
  for (final r in XmlDocument.parse(sheet).findAllElements('row')) {
    final cells = <String>[];
    for (final c in r.findElements('c')) {
      final idx = col(c.getAttribute('r') ?? 'A1');
      while (cells.length < idx) {
        cells.add('');
      }
      final t = c.getAttribute('t');
      final v = c.getElement('v')?.innerText ?? '';
      cells.add(switch (t) {
        's' => shared.elementAtOrNull(int.tryParse(v) ?? -1) ?? '',
        'inlineStr' => c.findAllElements('t').map((e) => e.innerText).join(),
        // Phone numbers saved as numbers lose the leading 0 / show 7.7E+8.
        _ when RegExp(r'^\d+(\.0+)?$').hasMatch(v) => v.split('.').first,
        _ when RegExp(r'^\d(\.\d+)?E\+\d+$', caseSensitive: false).hasMatch(v) =>
          double.parse(v).toStringAsFixed(0),
        _ => v,
      });
    }
    rows.add(cells);
  }
  return rows;
}

// -------------------------------------------------------- pasted lists --

final _phoneIn = RegExp(r'(\+?\d[\d\s().-]{7,}\d)');

/// "Name, 0772…", "Name - +256…", "0772… Name", "Name [tab] phone", or a
/// phone alone: one learner per line.
ParsedImport parsePastedList(String text) {
  final rows = <ImportRow>[];
  for (final raw in text.split(RegExp(r'\r?\n'))) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    final m = _phoneIn.firstMatch(line);
    final email = RegExp(r'[^\s,;]+@[^\s,;]+\.[^\s,;]+').firstMatch(line)?.group(0);
    var name = line;
    if (m != null) name = name.replaceFirst(m.group(0)!, ' ');
    if (email != null) name = name.replaceFirst(email, ' ');
    name = name.replaceAll(RegExp(r'^[\s,;:\t\-–]+|[\s,;:\t\-–]+$'), '').replaceAll(RegExp(r'\s+'), ' ');
    rows.add(ImportRow(name: name, phone: m?.group(0)?.trim() ?? '', email: email ?? ''));
  }
  return ParsedImport(rows, source: 'manual');
}

// ------------------------------------------------- WhatsApp chat export --

/// A chat exported from WhatsApp (group → ⋮ → More → Export chat → Without
/// media): everyone who wrote, or was added, with when they last wrote.
/// Senders saved in the exporting phone appear by NAME (no number); the
/// others by number. WhatsApp offers no way to read a group directly; this
/// is the user's own export, shared to Sidra.
ParsedImport parseWhatsAppExport(String text) {
  // Android: "30/09/2026, 14:05 - Name: text"  (also 30/09/26, 2:05 pm)
  // iPhone:  "[30/09/2026, 14:05:22] Name: text"
  final msg = RegExp(
    r'^\[?(\d{1,2})[/.](\d{1,2})[/.](\d{2,4}),?\s+(\d{1,2}):(\d{2})(?::\d{2})?\s*([AaPp]\.?\s?[Mm]\.?)?\]?\s*(?:-\s*)?([^:]{1,80}?):\s',
  );
  final added = RegExp(r'^\[?[\d/.,:\s]+(?:[AaPp]\.?\s?[Mm]\.?)?\]?\s*(?:-\s*)?(.+?) added (.+)$');
  final joined = RegExp(r'^\[?[\d/.,:\s]+(?:[AaPp]\.?\s?[Mm]\.?)?\]?\s*(?:-\s*)?(.+?) joined using');
  final people = <String, ImportRow>{};
  ImportRow person(String who) {
    who = who.replaceAll(RegExp('[\u200e\u200f\u202a-\u202e~]'), '').trim();
    final key = who.replaceAll(RegExp(r'[\s().-]'), '').toLowerCase();
    return people.putIfAbsent(key, () {
      final isPhone = RegExp(r'^\+?[\d\s().-]{8,}$').hasMatch(who);
      return ImportRow(name: isPhone ? '' : who, phone: isPhone ? who : '');
    });
  }

  for (final raw in const LineSplitter().convert(text.replaceFirst('﻿', ''))) {
    final line = raw.replaceAll('‎', '');
    final a = added.firstMatch(line);
    if (a != null) {
      for (final who in a.group(2)!.split(RegExp(r',| and '))) {
        if (who.trim().isNotEmpty && who.trim() != 'you') person(who);
      }
      continue;
    }
    final j = joined.firstMatch(line);
    if (j != null) {
      person(j.group(1)!);
      continue;
    }
    final m = msg.firstMatch(line);
    if (m == null) continue;
    final who = m.group(7)!;
    if (who.contains('Messages and calls are end-to-end encrypted')) continue;
    final p = person(who)..messages += 1;
    final day = int.parse(m.group(1)!), month = int.parse(m.group(2)!);
    var year = int.parse(m.group(3)!);
    if (year < 100) year += 2000;
    var hour = int.parse(m.group(4)!);
    final ampm = m.group(6)?.toLowerCase().replaceAll(RegExp(r'[.\s]'), '');
    if (ampm == 'pm' && hour < 12) hour += 12;
    if (ampm == 'am' && hour == 12) hour = 0;
    final at = DateTime.tryParse(
      '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')} ${hour.toString().padLeft(2, '0')}:${m.group(5)}',
    );
    if (at != null && (p.lastSeen == null || at.isAfter(p.lastSeen!))) p.lastSeen = at;
  }
  final rows = people.values.toList()
    ..sort((a, b) => (b.messages).compareTo(a.messages));
  return ParsedImport(
    rows,
    source: 'whatsapp',
    warnings: [if (rows.any((r) => r.phone.isEmpty)) 'names_without_numbers'],
  );
}
