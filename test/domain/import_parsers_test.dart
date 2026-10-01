import 'dart:convert';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/onboarding/data/import_parsers.dart';

void main() {
  test('CSV: quoted cells, other delimiters, headers in any common wording', () {
    final table = parseCsv(
      'Full Name;Mobile;E-mail;Page;Line;Gender;Notes\r\n'
      '"Musa, Ahmed";0772 123 401;;18;3;M;"Strong ""madd"""\r\n'
      'Fatuma Ali;+256 701 234 567;f@x.org;21;;F;\r\n',
    );
    final p = rowsFromTable(table);
    expect(p.rows, hasLength(2));
    expect(p.rows[0].name, 'Musa, Ahmed');
    expect(p.rows[0].phone, '0772 123 401');
    expect(p.rows[0].page, 18);
    expect(p.rows[0].line, 3);
    expect(p.rows[0].note, contains('Strong "madd"'));
    expect(p.rows[0].note, contains('Gender: M'), reason: 'unknown/extra columns are kept');
    expect(p.rows[1].email, 'f@x.org');
    expect(p.warnings, isEmpty);
  });

  test('a file without a name or phone column says so', () {
    final p = rowsFromTable(parseCsv('A,B\n1,2\n'));
    expect(p.warnings, containsAll(['no_name_column', 'no_phone_column']));
  });

  test('first + last name columns make the name; several courses are flagged', () {
    final p = rowsFromTable(parseCsv('First Name,Surname,Phone,Course\nAhmed,Musa,0772,Yassarna\nYusuf,H,0773,Arabic\n'));
    expect(p.rows.first.name, 'Ahmed Musa');
    expect(p.warnings, contains('several_courses'));
  });

  test('pasted list: name and number in any order', () {
    final p = parsePastedList(
      'Ahmed Musa, 0772 123 401\n'
      '+256 701 234 567 Fatuma Ali\n'
      'Yusuf Hassan\t0752-999-888\n'
      '\n'
      '0774 000 111\n'
      'Mary mary@example.com',
    );
    expect([for (final r in p.rows) r.name], ['Ahmed Musa', 'Fatuma Ali', 'Yusuf Hassan', '', 'Mary']);
    expect(p.rows[1].phone, '+256 701 234 567');
    expect(p.rows[4].email, 'mary@example.com');
  });

  test('WhatsApp export (Android and iPhone): every sender once, with numbers or names', () {
    const chat =
        '30/09/2026, 08:00 - Messages and calls are end-to-end encrypted. No one outside of this chat can read them.\n'
        '29/09/2026, 07:55 - Ustadh Musa added +256 772 123 401 and Fatuma Ali\n'
        '30/09/2026, 08:01 - Ustadh Musa: Read page 18 today\n'
        '30/09/2026, 08:05 - +256 772 123 401: <Media omitted>\n'
        '30/09/2026, 9:15 pm - Fatuma Ali: Done, page 21\n'
        '[01/10/2026, 06:30:10] Yusuf H: Salaam\n'
        '30/09/2026, 10:00 - +256 701 999 000 joined using this group\'s invite link\n'
        'continuation line of a long message\n';
    final p = parseWhatsAppExport(chat);
    expect(p.source, 'whatsapp');
    final byKey = {for (final r in p.rows) r.name.isNotEmpty ? r.name : r.phone: r};
    expect(byKey.keys, containsAll(['Ustadh Musa', '+256 772 123 401', 'Fatuma Ali', 'Yusuf H', '+256 701 999 000']));
    expect(byKey['Fatuma Ali']!.lastSeen, DateTime(2026, 9, 30, 21, 15), reason: '9:15 pm');
    expect(byKey['Yusuf H']!.lastSeen, DateTime(2026, 10, 1, 6, 30));
    expect(byKey['+256 772 123 401']!.messages, 1);
    expect(p.rows.where((r) => r.name.contains('encrypted')), isEmpty);
    expect(p.warnings, contains('names_without_numbers'),
        reason: 'saved contacts appear by name only: their numbers must be added');
  });

  test('XLSX: shared strings, inline strings, numbers that were phone numbers', () {
    final arch = Archive()
      ..addFile(ArchiveFile.bytes('xl/sharedStrings.xml', utf8.encode(
          '<sst><si><t>Name</t></si><si><t>Phone</t></si><si><t>Ahmed Musa</t></si></sst>')))
      ..addFile(ArchiveFile.bytes('xl/worksheets/sheet1.xml', utf8.encode(
          '<worksheet><sheetData>'
          '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c></row>'
          '<row r="2"><c r="A2" t="s"><v>2</v></c><c r="B2"><v>256772123401</v></c></row>'
          '<row r="3"><c r="A3" t="inlineStr"><is><t>Fatuma</t></is></c><c r="B3"><v>7.72123402E+8</v></c></row>'
          '</sheetData></worksheet>')));
    final rows = parseXlsx(Uint8List.fromList(ZipEncoder().encode(arch)));
    final p = rowsFromTable(rows, source: 'excel');
    expect(p.rows.map((r) => (r.name, r.phone)), [
      ('Ahmed Musa', '256772123401'),
      ('Fatuma', '772123402'),
    ]);
  });
}
