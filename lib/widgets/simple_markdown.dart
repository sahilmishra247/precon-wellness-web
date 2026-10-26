import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Renders the small subset of Markdown the library articles use:
/// `#` and `###` headings, `*` bullets, `1.` numbered items and **bold**.
class SimpleMarkdown extends StatelessWidget {
  final String text;
  final bool isDark;
  const SimpleMarkdown({super.key, required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final body = TextStyle(fontSize: 15, height: 1.65, color: AppColors.textSecondary(isDark));
    final children = <Widget>[];
    for (final raw in text.trim().split('\n')) {
      final line = raw.trimRight();
      if (line.trim().isEmpty) {
        children.add(const SizedBox(height: 8));
      } else if (line.startsWith('### ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(top: 12, bottom: 4),
          child: Text(line.substring(4),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark))),
        ));
      } else if (line.startsWith('# ')) {
        children.add(Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Text(line.substring(2),
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary(isDark))),
        ));
      } else {
        final bullet = RegExp(r'^\s*(\*|-|\d+\.)\s+(.*)$').firstMatch(line);
        if (bullet != null) {
          final marker = bullet.group(1)!;
          children.add(Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              SizedBox(width: 22, child: Text(marker == '*' || marker == '-' ? '•' : marker, style: body)),
              Expanded(child: Text.rich(_inline(bullet.group(2)!, body))),
            ]),
          ));
        } else {
          children.add(Text.rich(_inline(line, body)));
        }
      }
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: children);
  }

  TextSpan _inline(String s, TextStyle base) {
    final spans = <TextSpan>[];
    final parts = s.split('**');
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(
        text: parts[i],
        style: i.isOdd ? TextStyle(fontWeight: FontWeight.w600, color: AppColors.textPrimary(isDark)) : null,
      ));
    }
    return TextSpan(style: base, children: spans);
  }
}
