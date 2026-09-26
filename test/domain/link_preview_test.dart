import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/content/data/link_preview.dart';

/// Serves canned responses by URL, so previews are tested without network.
class FakeAdapter implements HttpClientAdapter {
  FakeAdapter(this.pages);
  final Map<String, (int, String, String)> pages; // url → status, type, body
  final requested = <String>[];

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    final url = options.uri.toString();
    requested.add(url);
    final hit = pages.entries
        .where((e) => url.startsWith(e.key))
        .firstOrNull
        ?.value;
    final (status, type, body) = hit ?? (404, 'text/html', 'not found');
    return ResponseBody.fromBytes(
      utf8.encode(body),
      status,
      headers: {
        Headers.contentTypeHeader: [type],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}

LinkPreviewService serviceWith(FakeAdapter a) =>
    LinkPreviewService(Dio()..httpClientAdapter = a);

void main() {
  test('reads a page title, description and https image', () async {
    final a = FakeAdapter({
      'https://example.org/lesson': (
        200,
        'text/html; charset=utf-8',
        '<html><head><title>Ignored</title>'
            '<meta property="og:title" content="Makhārij &amp; practice">'
            '<meta name="description" content="Where each letter is pronounced">'
            '<meta property="og:image" content="/img/cover.png">'
            '<script>alert(1)</script></head></html>',
      ),
    });
    final p = await serviceWith(a).fetch('https://example.org/lesson');
    expect(p.available, isTrue);
    expect(p.title, 'Makhārij & practice');
    expect(p.description, 'Where each letter is pronounced');
    expect(p.thumbnail, 'https://example.org/img/cover.png');
    expect(p.domain, 'example.org');
  });

  test('YouTube uses its official oEmbed details', () async {
    final a = FakeAdapter({
      'https://www.youtube.com/oembed': (
        200,
        'application/json',
        jsonEncode({
          'title': 'Learn the Arabic alphabet',
          'author_name': 'Almuntahha',
          'thumbnail_url': 'https://i.ytimg.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
          'provider_name': 'YouTube',
        }),
      ),
    });
    final p = await serviceWith(a).fetch('https://youtu.be/dQw4w9WgXcQ');
    expect(p.available, isTrue);
    expect(p.title, 'Learn the Arabic alphabet');
    expect(p.siteName, 'YouTube');
    expect(a.requested.single, startsWith('https://www.youtube.com/oembed'));
  });

  test('a removed video says so instead of faking a preview', () async {
    final a = FakeAdapter({
      'https://www.youtube.com/oembed': (404, 'text/plain', 'Not Found'),
    });
    final p = await serviceWith(a).fetch('https://youtu.be/dQw4w9WgXcQ');
    expect(p.available, isFalse);
    expect(p.reason, contains('private, removed'));
  });

  test('files are described, not downloaded', () async {
    final a = FakeAdapter({
      'https://files.example.org/worksheet.pdf': (
        200,
        'application/pdf',
        '%PDF-1.7',
      ),
    });
    final p = await serviceWith(a)
        .fetch('https://files.example.org/worksheet.pdf');
    expect(p.available, isTrue);
    expect(p.contentType, 'application/pdf');
    expect(p.title, 'worksheet.pdf');
  });

  test('unsafe or broken links never pretend to be fine', () async {
    final a = FakeAdapter({});
    final svc = serviceWith(a);
    expect((await svc.fetch('javascript:alert(1)')).available, isFalse);
    expect((await svc.fetch('data:text/html,hi')).available, isFalse);
    expect(a.requested, isEmpty, reason: 'nothing fetched for unsafe links');
    final missing = await svc.fetch('https://example.org/gone');
    expect(missing.available, isFalse);
    expect(missing.reason, contains('404'));
  });

  test('http images are dropped (only https is shown)', () async {
    final a = FakeAdapter({
      'https://example.org/': (
        200,
        'text/html',
        '<meta property="og:title" content="T">'
            '<meta property="og:image" content="http://insecure.example/x.png">',
      ),
    });
    final p = await serviceWith(a).fetch('https://example.org/');
    expect(p.thumbnail, isNull);
  });
}
