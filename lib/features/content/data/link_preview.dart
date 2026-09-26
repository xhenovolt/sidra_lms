import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../lessons/domain/external_link.dart';

/// What we could learn about an external link, so an admin can check it
/// points where they meant before learners see it. Nothing from the page is
/// ever executed or rendered as HTML: only text fields and an https image.
class LinkPreview {
  const LinkPreview({
    required this.url,
    required this.domain,
    required this.available,
    this.title,
    this.description,
    this.thumbnail,
    this.siteName,
    this.contentType,
    this.reason,
  });

  factory LinkPreview.fromJson(Map<String, dynamic> j, String url) =>
      LinkPreview(
        url: url,
        domain: Uri.tryParse(url)?.host ?? url,
        available: j['status'] == 'ok',
        title: j['title'] as String?,
        description: j['description'] as String?,
        thumbnail: j['thumbnail'] as String?,
        siteName: j['site_name'] as String?,
        contentType: j['content_type'] as String?,
        reason: j['reason'] as String?,
      );

  final String url;
  final String domain;

  /// False when no metadata could be read (the link may still be fine).
  final bool available;
  final String? title;
  final String? description;
  final String? thumbnail;
  final String? siteName;
  final String? contentType;
  final String? reason;

  Map<String, Object?> toJson() => {
    'status': available ? 'ok' : 'unavailable',
    'title': ?title,
    'description': ?description,
    'thumbnail': ?thumbnail,
    'site_name': ?siteName,
    'content_type': ?contentType,
    'reason': ?reason,
    'checked_at': DateTime.now().toUtc().toIso8601String(),
  };
}

class LinkPreviewService {
  LinkPreviewService([Dio? dio])
    : _dio = _configure(
        dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 8),
                receiveTimeout: const Duration(seconds: 10),
                followRedirects: true,
                maxRedirects: 5,
                validateStatus: (_) => true,
                headers: {
                  'User-Agent':
                      'Mozilla/5.0 (Linux; Android 14) SidraLinkPreview/1.0',
                  'Accept': 'text/html,application/xhtml+xml,*/*;q=0.8',
                },
              ),
            ),
      );

  final Dio _dio;
  static const _maxBytes = 512 * 1024;

  /// Error pages are answers, not exceptions: they become "no preview".
  static Dio _configure(Dio d) => d..options.validateStatus = (_) => true;

  Future<LinkPreview> fetch(String input) async {
    final uri = parseExternalLink(input);
    if (uri == null) {
      return LinkPreview(
        url: input,
        domain: '',
        available: false,
        reason: 'not a web link',
      );
    }
    final url = uri.toString();
    try {
      final oembed = await _oembed(uri);
      if (oembed != null) return oembed;
      return await _page(uri);
    } catch (e) {
      return LinkPreview(
        url: url,
        domain: uri.host,
        available: false,
        reason: 'could not reach the page',
      );
    }
  }

  /// YouTube and Vimeo publish reliable metadata (no scraping needed).
  Future<LinkPreview?> _oembed(Uri uri) async {
    final provider = linkProviderOf(uri);
    final host = uri.host.toLowerCase();
    final endpoint = provider == LinkProvider.youtube
        ? 'https://www.youtube.com/oembed'
        : host.endsWith('vimeo.com')
        ? 'https://vimeo.com/api/oembed.json'
        : null;
    if (endpoint == null) return null;
    final res = await _dio.get<Object>(
      endpoint,
      queryParameters: {'url': uri.toString(), 'format': 'json'},
    );
    if (res.statusCode != 200 || res.data == null) {
      return LinkPreview(
        url: uri.toString(),
        domain: uri.host,
        available: false,
        reason: res.statusCode == 404 || res.statusCode == 401
            ? 'the video is private, removed or does not exist'
            : 'no details from the video site',
      );
    }
    final data = res.data is String
        ? jsonDecode(res.data! as String) as Map
        : res.data! as Map;
    return LinkPreview(
      url: uri.toString(),
      domain: uri.host,
      available: true,
      title: _clean(data['title']),
      description: _clean(data['author_name']),
      thumbnail: _safeImage(data['thumbnail_url'], uri),
      siteName: _clean(data['provider_name']),
      contentType: 'video',
    );
  }

  Future<LinkPreview> _page(Uri uri) async {
    final res = await _dio.get<ResponseBody>(
      uri.toString(),
      options: Options(responseType: ResponseType.stream),
    );
    final type = res.headers.value('content-type')?.split(';').first.trim();
    final finalUri = res.realUri;
    if ((res.statusCode ?? 0) >= 400) {
      await res.data?.stream.drain<void>();
      return LinkPreview(
        url: uri.toString(),
        domain: uri.host,
        available: false,
        contentType: type,
        reason: 'the page answered with error ${res.statusCode}',
      );
    }
    if (type != null && !type.contains('html')) {
      // A file (PDF, audio…): describe it, never download it all.
      await res.data?.stream.drain<void>();
      return LinkPreview(
        url: uri.toString(),
        domain: finalUri.host,
        available: true,
        title: Uri.decodeComponent(
          finalUri.pathSegments.lastOrNull ?? finalUri.host,
        ),
        contentType: type,
        siteName: finalUri.host,
      );
    }
    final bytes = BytesBuilder(copy: false);
    await for (final chunk in res.data!.stream) {
      bytes.add(chunk);
      if (bytes.length > _maxBytes) break;
    }
    final html = utf8.decode(bytes.takeBytes(), allowMalformed: true);
    String? meta(String name) {
      for (final pattern in [
        '<meta[^>]+(?:property|name)=["\']$name["\'][^>]*content=["\']([^"\']*)["\']',
        '<meta[^>]+content=["\']([^"\']*)["\'][^>]*(?:property|name)=["\']$name["\']',
      ]) {
        final m = RegExp(pattern, caseSensitive: false).firstMatch(html);
        if (m != null) return _clean(m.group(1));
      }
      return null;
    }

    final title =
        meta('og:title') ??
        meta('twitter:title') ??
        _clean(
          RegExp(
            r'<title[^>]*>([^<]*)</title>',
            caseSensitive: false,
          ).firstMatch(html)?.group(1),
        );
    final description =
        meta('og:description') ??
        meta('description') ??
        meta('twitter:description');
    final image = meta('og:image') ?? meta('twitter:image');
    final available = title != null || description != null;
    return LinkPreview(
      url: uri.toString(),
      domain: finalUri.host,
      available: available,
      title: title,
      description: description,
      thumbnail: _safeImage(image, finalUri),
      siteName: meta('og:site_name') ?? finalUri.host,
      contentType: type ?? 'text/html',
      reason: available ? null : 'the page has no title or description',
    );
  }

  /// Only https images are shown (resolved against the page address).
  static String? _safeImage(Object? raw, Uri base) {
    final s = _clean(raw);
    if (s == null) return null;
    final u = base.resolve(s);
    return u.scheme == 'https' ? u.toString() : null;
  }

  static String? _clean(Object? v) {
    if (v == null) return null;
    final s = '$v'
        .replaceAll(RegExp(r'<[^>]*>'), '')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll('&#39;', "'")
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    if (s.isEmpty) return null;
    return s.length > 300 ? '${s.substring(0, 300)}…' : s;
  }
}
