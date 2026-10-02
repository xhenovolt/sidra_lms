import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../../core/database/local_database.dart';
import '../../../core/errors/app_failure.dart';
import '../../../core/logging/app_logger.dart';
import '../../../core/network/postgres_api.dart';

/// Where a media asset can be played/shown from.
sealed class MediaSource {
  const MediaSource();
}

class LocalMedia extends MediaSource {
  const LocalMedia(this.file);
  final File file;
}

class RemoteMedia extends MediaSource {
  const RemoteMedia(this.url);
  final String url;
}

/// Resolves and downloads Cloudinary media.
///
/// URLs come from the database's `media_url()`, which refuses locked
/// content and signs private assets server-side. The app never holds a
/// Cloudinary secret. Downloaded files are preferred when present.
class MediaRepository {
  MediaRepository(
    this._local,
    this._api, {
    required this.mediaDir,
    Dio? downloader,
  }) : _dio = downloader ?? Dio();

  final LocalDatabase _local;
  final PostgresApi _api;
  final Directory mediaDir;
  final Dio _dio;
  static const _log = AppLogger('media');

  Future<MediaSource> resolve(String assetId, {String? transformation}) async {
    final row = await _row(assetId);
    if (transformation == null && row != null && row['state'] == 'done') {
      final f = File(row['local_path']! as String);
      if (f.existsSync()) return LocalMedia(f);
    }
    // Links expire (two hours, 0049): a remembered one is reused only while
    // it is fresh; after that the database is asked again — which also
    // re-checks that the learner still has access.
    if (transformation == null &&
        row?['url'] != null &&
        _fresh(row!['updated_at'])) {
      return RemoteMedia(row['url']! as String);
    }
    final url = await _api.rpc(
      'media_url',
      params: {'p_asset_id': assetId, 'p_transformation': transformation},
    );
    if (url is! String) throw const ServerFailure('No media URL returned');
    if (transformation == null) {
      await _local.db.insert('media_files', {
        'asset_id': assetId,
        'course_id': row?['course_id'],
        'local_path': row?['local_path'],
        'bytes': row?['bytes'],
        'url': url,
        'state': row?['state'] ?? 'remote',
        'updated_at': LocalDatabase.now(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
    }
    return RemoteMedia(url);
  }

  static const _linkLife = Duration(minutes: 60);

  static bool _fresh(Object? updatedAt) {
    final at = DateTime.tryParse('${updatedAt ?? ''}');
    return at != null &&
        DateTime.now().toUtc().difference(at.toUtc()) < _linkLife;
  }

  /// The file's extension: from the path (old links), or the `format`
  /// parameter of an expiring download link.
  static String _extension(String url) {
    final u = Uri.parse(url);
    final fromPath = p.extension(u.path);
    if (fromPath.isNotEmpty) return fromPath;
    final format = u.queryParameters['format'];
    return format == null || format.isEmpty ? '' : '.$format';
  }

  Future<Map<String, Object?>?> _row(String assetId) async {
    final r = await _local.db.query(
      'media_files',
      where: 'asset_id = ?',
      whereArgs: [assetId],
    );
    return r.isEmpty ? null : r.first;
  }

  /// Downloads one asset for offline use. Writes to a `.part` file first,
  /// then renames, so an interrupted download never looks complete.
  Future<int> download(
    String assetId, {
    required String courseId,
    CancelToken? cancelToken,
    void Function(int received, int total)? onProgress,
  }) async {
    final existing = await _row(assetId);
    if (existing?['state'] == 'done' &&
        File(existing!['local_path']! as String).existsSync()) {
      return (existing['bytes'] as int?) ?? 0;
    }
    final source = await resolve(assetId);
    if (source is LocalMedia) return source.file.lengthSync();
    final url = (source as RemoteMedia).url;

    await mediaDir.create(recursive: true);
    final ext = _extension(url);
    final target = File(p.join(mediaDir.path, '$assetId$ext'));
    final part = File('${target.path}.part');
    try {
      await _dio.download(
        url,
        part.path,
        cancelToken: cancelToken,
        onReceiveProgress: onProgress,
        deleteOnError: true,
      );
      if (target.existsSync()) await target.delete();
      await part.rename(target.path);
    } on DioException catch (e) {
      if (part.existsSync()) await part.delete();
      if (e.type == DioExceptionType.cancel) rethrow;
      if (e.response?.statusCode == 401 || e.response?.statusCode == 404) {
        // Signed URL no longer valid or asset removed: forget cached URL.
        await _local.db.update(
          'media_files',
          {'url': null},
          where: 'asset_id = ?',
          whereArgs: [assetId],
        );
      }
      throw const OfflineFailure('Download interrupted');
    } on FileSystemException catch (e) {
      if (part.existsSync()) await part.delete();
      // ENOSPC (28 on Linux/Android, 112 on Windows)
      if (e.osError?.errorCode == 28 || e.osError?.errorCode == 112) {
        throw const InsufficientStorageFailure();
      }
      throw StorageFailure('Could not save media', cause: e);
    }

    final bytes = target.lengthSync();
    await _local.db.insert('media_files', {
      'asset_id': assetId,
      'course_id': courseId,
      'local_path': target.path,
      'bytes': bytes,
      'url': url,
      'state': 'done',
      'updated_at': LocalDatabase.now(),
    }, conflictAlgorithm: ConflictAlgorithm.replace);
    _log.debug('downloaded', {'bytes': bytes});
    return bytes;
  }

  Future<int> downloadedBytes(String courseId) async {
    final r = await _local.db.rawQuery(
      "select coalesce(sum(bytes), 0) b from media_files "
      "where course_id = ? and state = 'done'",
      [courseId],
    );
    return (r.first['b'] as int?) ?? 0;
  }

  /// Deletes a course's downloaded media files.
  Future<void> removeCourse(String courseId) async {
    final rows = await _local.db.query(
      'media_files',
      where: "course_id = ? and state = 'done'",
      whereArgs: [courseId],
    );
    for (final r in rows) {
      final f = File(r['local_path']! as String);
      if (f.existsSync()) await f.delete();
    }
    await _local.db.update(
      'media_files',
      {'state': 'remote', 'local_path': null, 'bytes': null},
      where: 'course_id = ?',
      whereArgs: [courseId],
    );
  }
}
