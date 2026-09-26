import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/lessons/domain/content_blocks.dart';
import 'package:sidra_lms/features/lessons/domain/external_link.dart';

void main() {
  group('parseExternalLink', () {
    test('accepts web links and adds https when missing', () {
      expect(
        parseExternalLink(' youtu.be/dQw4w9WgXcQ ').toString(),
        'https://youtu.be/dQw4w9WgXcQ',
      );
      expect(
        parseExternalLink('http://example.org/a?b=1').toString(),
        'http://example.org/a?b=1',
      );
    });

    test('rejects anything that is not a plain web link', () {
      for (final bad in [
        '',
        'javascript:alert(1)',
        'mailto:someone@example.com',
        'file:///etc/passwd',
        'intent://scan#Intent;end',
        'https://has space.com',
        'localhost',
        'ftp://example.com',
      ]) {
        expect(parseExternalLink(bad), isNull, reason: bad);
      }
    });
  });

  test('detects the provider', () {
    LinkProvider of(String s) => linkProviderOf(parseExternalLink(s)!);
    expect(
      of('https://www.youtube.com/watch?v=dQw4w9WgXcQ'),
      LinkProvider.youtube,
    );
    expect(
      of('https://m.youtube.com/shorts/dQw4w9WgXcQ'),
      LinkProvider.youtube,
    );
    expect(of('https://t.me/almuntahha/12'), LinkProvider.telegram);
    expect(of('https://youtube.com.evil.example/x'), LinkProvider.web);
    expect(of('https://quran.com/1'), LinkProvider.web);
  });

  test('finds YouTube video ids for thumbnails', () {
    String? id(String s) => youtubeVideoId(parseExternalLink(s)!);
    expect(id('https://youtu.be/dQw4w9WgXcQ?t=42'), 'dQw4w9WgXcQ');
    expect(
      id('https://www.youtube.com/watch?v=dQw4w9WgXcQ&list=x'),
      'dQw4w9WgXcQ',
    );
    expect(id('https://youtube.com/shorts/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    expect(id('https://youtube.com/embed/dQw4w9WgXcQ'), 'dQw4w9WgXcQ');
    expect(id('https://youtube.com/@almuntahha'), isNull);
    expect(id('https://t.me/x/1'), isNull);
    expect(
      youtubeThumbnail(parseExternalLink('youtu.be/dQw4w9WgXcQ')!),
      'https://img.youtube.com/vi/dQw4w9WgXcQ/hqdefault.jpg',
    );
  });

  test('external_link rows become link blocks; unsafe ones are dropped', () {
    final ok = ContentBlock.fromJson({
      'id': 'b1',
      'position': 0,
      'block_type': 'external_link',
      'body': {'url': 'https://t.me/almuntahha/12', 'title': 'Notes'},
    });
    expect(ok, isA<ExternalLinkBlock>());
    expect((ok as ExternalLinkBlock).provider, LinkProvider.telegram);
    expect(ok.title, 'Notes');

    final bad = ContentBlock.fromJson({
      'id': 'b2',
      'position': 1,
      'block_type': 'external_link',
      'body': {'url': 'javascript:alert(1)'},
    });
    expect(bad, isA<UnknownBlock>());
  });
}
