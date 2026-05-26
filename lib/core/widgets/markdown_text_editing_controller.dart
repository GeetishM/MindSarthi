import 'package:flutter/material.dart';

class MarkdownParser {
  static List<InlineSpan> parse(
    String text, {
    required TextStyle? style,
    required Color syntaxColor,
    required TextStyle boldStyle,
    required TextStyle italicStyle,
    required TextStyle underlineStyle,
    required TextStyle strikethroughStyle,
    required TextStyle codeStyle,
    required TextStyle headingStyle,
    required bool showSyntax,
  }) {
    if (text.isEmpty) return [];

    final topLevelRegExp = RegExp(
      r'(```[\s\S]*?```)|(\*\*\*.*?\*\*\*)|(\*\*.*?\*\*)|(\*.*?\*)|(__.*?__)|(~~.*?~~)|(`.*?`)|(^### .*$)',
      multiLine: true,
    );

    final nestedRegExp = RegExp(
      r'(\*\*\*.*?\*\*\*)|(\*\*.*?\*\*)|(\*.*?\*)|(__.*?__)|(~~.*?~~)',
      multiLine: true,
    );

    List<InlineSpan> parseInternal(String text, TextStyle? currentStyle, bool isTopLevel) {
      if (text.isEmpty) return [];

      final activeRegExp = isTopLevel ? topLevelRegExp : nestedRegExp;
      final match = activeRegExp.firstMatch(text);
      if (match == null) {
        return [TextSpan(text: text, style: currentStyle)];
      }

      final List<InlineSpan> spans = [];

      // 1. Text before match
      if (match.start > 0) {
        spans.addAll(parseInternal(text.substring(0, match.start), currentStyle, isTopLevel));
      }

      // 2. The match itself
      final matchedText = match.group(0)!;

      if (isTopLevel && match.group(1) != null) {
        // Code block: ```[\s\S]*?```
        final content = matchedText.substring(3, matchedText.length - 3);
        if (showSyntax) {
          spans.add(TextSpan(text: '```', style: currentStyle?.copyWith(color: syntaxColor)));
        }
        spans.add(TextSpan(text: content, style: currentStyle?.merge(codeStyle)));
        if (showSyntax) {
          spans.add(TextSpan(text: '```', style: currentStyle?.copyWith(color: syntaxColor)));
        }
      } else {
        if (matchedText.startsWith('***') && matchedText.endsWith('***') && matchedText.length >= 6) {
          final content = matchedText.substring(3, matchedText.length - 3);
          if (showSyntax) {
            spans.add(TextSpan(text: '***', style: currentStyle?.copyWith(color: syntaxColor)));
          }
          spans.addAll(parseInternal(content, currentStyle?.merge(boldStyle).merge(italicStyle), false));
          if (showSyntax) {
            spans.add(TextSpan(text: '***', style: currentStyle?.copyWith(color: syntaxColor)));
          }
        } else if (matchedText.startsWith('**') && matchedText.endsWith('**') && matchedText.length >= 4) {
          final content = matchedText.substring(2, matchedText.length - 2);
          if (showSyntax) {
            spans.add(TextSpan(text: '**', style: currentStyle?.copyWith(color: syntaxColor)));
          }
          spans.addAll(parseInternal(content, currentStyle?.merge(boldStyle), false));
          if (showSyntax) {
            spans.add(TextSpan(text: '**', style: currentStyle?.copyWith(color: syntaxColor)));
          }
        } else if (matchedText.startsWith('__') && matchedText.endsWith('__') && matchedText.length >= 4) {
          final content = matchedText.substring(2, matchedText.length - 2);
          if (showSyntax) {
            spans.add(TextSpan(text: '__', style: currentStyle?.copyWith(color: syntaxColor)));
          }
          spans.addAll(parseInternal(content, currentStyle?.merge(underlineStyle), false));
          if (showSyntax) {
            spans.add(TextSpan(text: '__', style: currentStyle?.copyWith(color: syntaxColor)));
          }
        } else if (matchedText.startsWith('~~') && matchedText.endsWith('~~') && matchedText.length >= 4) {
          final content = matchedText.substring(2, matchedText.length - 2);
          if (showSyntax) {
            spans.add(TextSpan(text: '~~', style: currentStyle?.copyWith(color: syntaxColor)));
          }
          spans.addAll(parseInternal(content, currentStyle?.merge(strikethroughStyle), false));
          if (showSyntax) {
            spans.add(TextSpan(text: '~~', style: currentStyle?.copyWith(color: syntaxColor)));
          }
        } else if (matchedText.startsWith('*') && matchedText.endsWith('*') && matchedText.length >= 2) {
          final content = matchedText.substring(1, matchedText.length - 1);
          if (showSyntax) {
            spans.add(TextSpan(text: '*', style: currentStyle?.copyWith(color: syntaxColor)));
          }
          spans.addAll(parseInternal(content, currentStyle?.merge(italicStyle), false));
          if (showSyntax) {
            spans.add(TextSpan(text: '*', style: currentStyle?.copyWith(color: syntaxColor)));
          }
        } else if (isTopLevel && matchedText.startsWith('`') && matchedText.endsWith('`') && matchedText.length >= 2) {
          final content = matchedText.substring(1, matchedText.length - 1);
          if (showSyntax) {
            spans.add(TextSpan(text: '`', style: currentStyle?.copyWith(color: syntaxColor)));
          }
          spans.add(TextSpan(text: content, style: currentStyle?.merge(codeStyle)));
          if (showSyntax) {
            spans.add(TextSpan(text: '`', style: currentStyle?.copyWith(color: syntaxColor)));
          }
        } else if (isTopLevel && matchedText.startsWith('### ')) {
          if (showSyntax) {
            spans.add(TextSpan(text: '### ', style: currentStyle?.copyWith(color: syntaxColor)));
          }
          final content = matchedText.substring(4);
          spans.addAll(parseInternal(content, currentStyle?.merge(headingStyle), false));
        } else {
          spans.add(TextSpan(text: matchedText, style: currentStyle));
        }
      }

      // 3. Text after match
      if (match.end < text.length) {
        spans.addAll(parseInternal(text.substring(match.end), currentStyle, isTopLevel));
      }

      return spans;
    }

    return parseInternal(text, style, true);
  }
}

class MarkdownTextEditingController extends TextEditingController {
  final Color syntaxColor;
  final TextStyle boldStyle;
  final TextStyle italicStyle;
  final TextStyle underlineStyle;
  final TextStyle strikethroughStyle;
  final TextStyle codeStyle;
  final TextStyle headingStyle;

  MarkdownTextEditingController({
    super.text,
    required this.syntaxColor,
    required this.boldStyle,
    required this.italicStyle,
    required this.underlineStyle,
    required this.strikethroughStyle,
    required this.codeStyle,
    required this.headingStyle,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    final textVal = value.text;
    final children = MarkdownParser.parse(
      textVal,
      style: style,
      syntaxColor: syntaxColor,
      boldStyle: boldStyle,
      italicStyle: italicStyle,
      underlineStyle: underlineStyle,
      strikethroughStyle: strikethroughStyle,
      codeStyle: codeStyle,
      headingStyle: headingStyle,
      showSyntax: true,
    );
    return TextSpan(children: children, style: style);
  }
}
