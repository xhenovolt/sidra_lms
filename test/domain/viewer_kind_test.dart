import 'package:flutter_test/flutter_test.dart';
import 'package:sidra_lms/features/media/presentation/media_viewer.dart';

void main() {
  test('each file type opens the right way', () {
    expect(viewerKindFor(fileName: 'recitation.wav'), ViewerKind.audio);
    expect(viewerKindFor(fileName: 'clip.mp4'), ViewerKind.video);
    expect(viewerKindFor(fileName: 'page.jpg'), ViewerKind.image);
    expect(
      viewerKindFor(kind: 'audio', fileName: 'recitation.wav'),
      ViewerKind.audio,
    );
    expect(viewerKindFor(mimeType: 'audio/wav'), ViewerKind.audio);
    expect(viewerKindFor(mimeType: 'image/jpeg'), ViewerKind.image);
    expect(viewerKindFor(kind: 'video'), ViewerKind.video);
    expect(viewerKindFor(fileName: 'Worksheet.PDF'), ViewerKind.pdf);
    expect(viewerKindFor(fileName: 'notes.txt'), ViewerKind.text);
    expect(viewerKindFor(fileName: 'plan.docx'), ViewerKind.office);
    expect(viewerKindFor(kind: 'link'), ViewerKind.link);
  });
}
