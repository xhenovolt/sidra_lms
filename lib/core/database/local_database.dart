import 'dart:convert';

import 'package:sqflite/sqflite.dart';

import '../errors/app_failure.dart';

/// On-device SQLite store: cached curriculum, lesson content, local progress
/// and the sync outbox. One database file per signed-in user, so learners
/// sharing a device never see each other's data.
///
/// Rows keep the server JSON in a `json` column plus the few indexed columns
/// queries need. The schema mirrors server concepts but is a cache, not a
/// replica: the server stays the source of truth.
class LocalDatabase {
  LocalDatabase._(this.db);

  final Database db;

  static const version = 1;

  static Future<LocalDatabase> open(
    String path, {
    DatabaseFactory? factory,
  }) async {
    try {
      final f = factory ?? databaseFactory;
      final db = await f.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: version,
          onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
          onCreate: (db, _) => _create(db),
        ),
      );
      return LocalDatabase._(db);
    } catch (e) {
      throw StorageFailure('Could not open local database', cause: e);
    }
  }

  static Future<void> _create(Database db) async {
    final b = db.batch();
    b.execute('''
      create table courses (
        id text primary key,
        json text not null,
        content_version integer not null,
        in_catalogue integer not null default 0,
        fetched_at text not null
      )''');
    b.execute('''
      create table my_courses (
        course_id text primary key,
        json text not null,
        fetched_at text not null
      )''');
    // Units, nodes, lessons, order and book level labels for one course.
    b.execute('''
      create table course_outlines (
        course_id text primary key,
        json text not null,
        fetched_at text not null
      )''');
    b.execute('''
      create table lesson_content (
        lesson_id text primary key,
        course_id text not null,
        content_version integer not null,
        json text not null,
        fetched_at text not null
      )''');
    b.execute(
      'create index lesson_content_course on lesson_content (course_id)',
    );
    b.execute('''
      create table assessments (
        id text primary key,
        lesson_id text,
        course_id text not null,
        json text not null,
        fetched_at text not null
      )''');
    // Merged view of progress; synced = 0 while an outbox op is pending.
    b.execute('''
      create table progress (
        lesson_id text primary key,
        course_id text not null,
        json text not null,
        synced integer not null
      )''');
    b.execute('create index progress_course on progress (course_id)');
    b.execute('''
      create table attempts (
        id text primary key,
        assessment_id text not null,
        json text not null,
        synced integer not null
      )''');
    // Pending writes to replay against the server, oldest first.
    // state: pending | rejected (server refused; kept, never discarded)
    b.execute('''
      create table outbox (
        op_id text primary key,
        op_type text not null,
        ref_key text,
        payload text not null,
        created_at text not null,
        attempts integer not null default 0,
        next_attempt_at text,
        last_error text,
        state text not null default 'pending'
      )''');
    b.execute('create index outbox_ref on outbox (op_type, ref_key)');
    b.execute('''
      create table media_files (
        asset_id text primary key,
        course_id text,
        local_path text,
        bytes integer,
        url text,
        state text not null,
        updated_at text not null
      )''');
    b.execute('create index media_files_course on media_files (course_id)');
    b.execute('''
      create table downloads (
        course_id text primary key,
        state text not null,
        total_bytes integer,
        done_bytes integer,
        error text,
        updated_at text not null
      )''');
    b.execute('create table kv (key text primary key, value text not null)');
    await b.commit(noResult: true);
  }

  Future<void> close() => db.close();

  // ---------------------------------------------------------- helpers --

  static String now() => DateTime.now().toUtc().toIso8601String();

  static String encode(Object? value) => jsonEncode(value);

  static Map<String, dynamic> decodeMap(Object? text) =>
      Map<String, dynamic>.from(jsonDecode(text! as String) as Map);

  Future<T> guard<T>(Future<T> Function() op) async {
    try {
      return await op();
    } on AppFailure {
      rethrow;
    } catch (e) {
      throw StorageFailure('Local storage error', cause: e);
    }
  }

  Future<String?> getKv(String key) async {
    final r = await db.query('kv', where: 'key = ?', whereArgs: [key]);
    return r.isEmpty ? null : r.first['value'] as String;
  }

  Future<void> setKv(String key, String value) => db.insert('kv', {
    'key': key,
    'value': value,
  }, conflictAlgorithm: ConflictAlgorithm.replace);
}
