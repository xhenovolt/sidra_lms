import 'package:flutter/material.dart';

import '../../../core/theme/app_tokens.dart';

/// Minimal Markdown for lesson text: paragraphs, `- ` bullets, `1. `
/// numbered items, **bold** and *italic*. Deliberately small: teachers
/// write short explanations, and a full Markdown engine adds weight and
/// attack surface (links, HTML) that lessons do not need.
class SimpleMarkdown extends StatelessWidget {
  const SimpleMarkdown(this.text, {super.key, this.style});

  final String text;
  final TextStyle? style;

  static final _inline = RegExp(r'(\*\*[^*]+\*\*|\*[^*]+\*)');
  static final _numbered = RegExp(r'^(\d+)\.\s+');

  static List<InlineSpan> inlineSpans(String line) {
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _inline.allMatches(line)) {
      if (m.start > last) {
        spans.add(TextSpan(text: line.substring(last, m.start)));
      }
      final token = m.group(0)!;
      spans.add(
        token.startsWith('**')
            ? TextSpan(
                text: token.substring(2, token.length - 2),
                style: const TextStyle(fontWeight: FontWeight.w700),
              )
            : TextSpan(
                text: token.substring(1, token.length - 1),
                style: const TextStyle(fontStyle: FontStyle.italic),
              ),
      );
      last = m.end;
    }
    if (last < line.length) spans.add(TextSpan(text: line.substring(last)));
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyLarge;
    final blocks = text.trim().split(RegExp(r'\n\s*\n'));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final (i, block) in blocks.indexed) ...[
          if (i > 0) const SizedBox(height: Space.sm),
          for (final line in block.split('\n')) _line(line.trimRight(), base),
        ],
      ],
    );
  }

  Widget _line(String line, TextStyle? base) {
    String? marker;
    var content = line;
    if (line.startsWith('- ') || line.startsWith('* ')) {
      marker = '•';
      content = line.substring(2);
    } else if (_numbered.firstMatch(line) case final m?) {
      marker = '${m.group(1)}.';
      content = line.substring(m.end);
    }
    final rich = Text.rich(
      TextSpan(style: base, children: inlineSpans(content)),
    );
    if (marker == null) return rich;
    return Padding(
      padding: const EdgeInsetsDirectional.only(start: Space.xs, top: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 22, child: Text(marker, style: base)),
          Expanded(child: rich),
        ],
      ),
    );
  }
}
