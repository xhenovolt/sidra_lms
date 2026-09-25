/// Small, strict helpers for decoding Data API / SQLite JSON maps.
///
/// Models are hand-written (no code generation) so the wire format is
/// explicit and reviewable next to the SQL schema.
typedef Json = Map<String, dynamic>;

extension JsonRead on Json {
  String str(String key) {
    final v = this[key];
    if (v is String) return v;
    throw FormatException('Expected string at "$key", got ${v.runtimeType}');
  }

  String? strOrNull(String key) => this[key] as String?;

  int integer(String key, {int? fallback}) {
    final v = this[key];
    if (v is int) return v;
    if (v is num) return v.toInt();
    if (v is String) return int.parse(v);
    if (v == null && fallback != null) return fallback;
    throw FormatException('Expected int at "$key", got ${v.runtimeType}');
  }

  int? intOrNull(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString());
  }

  /// Postgres numerics may arrive as strings ("12.50").
  double? numOrNull(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
  }

  bool boolean(String key, {bool fallback = false}) {
    final v = this[key];
    if (v is bool) return v;
    if (v is int) return v != 0; // SQLite
    return fallback;
  }

  bool? boolOrNull(String key) {
    final v = this[key];
    if (v == null) return null;
    if (v is bool) return v;
    if (v is int) return v != 0;
    return null;
  }

  DateTime? dateOrNull(String key) {
    final v = this[key];
    if (v == null) return null;
    return DateTime.parse(v as String);
  }

  List<String> strList(String key) {
    final v = this[key];
    if (v == null) return const [];
    return [for (final e in v as List) e.toString()];
  }

  Json obj(String key) {
    final v = this[key];
    if (v == null) return const {};
    return Map<String, dynamic>.from(v as Map);
  }
}

/// Parses a Postgres enum label into a Dart enum by name, with fallback for
/// labels added to the database after this app version shipped.
T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  final camel = name.replaceAllMapped(
    RegExp(r'_([a-z])'),
    (m) => m.group(1)!.toUpperCase(),
  );
  for (final v in values) {
    if (v.name == camel) return v;
  }
  return fallback;
}

/// Dart enum name → Postgres enum label (`teacherGated` → `teacher_gated`).
String enumToDb(Enum value) => value.name.replaceAllMapped(
  RegExp(r'[A-Z]'),
  (m) => '_${m.group(0)!.toLowerCase()}',
);
