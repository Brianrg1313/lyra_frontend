import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:url_launcher/url_launcher.dart';

/// An answer's text. Models write Markdown (lists, bold, code, tables), so it
/// is rendered as such, with the sizes and colours of `core`'s text instead of
/// Material's, selectable to copy a piece of it.
class AssistantMarkdown extends StatelessWidget {
  const AssistantMarkdown(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final base = TextStyle(fontSize: AppSize.text * 1.08, height: 1.55, color: scheme.text.primary);
    final code = base.copyWith(fontFamily: "monospace", fontSize: AppSize.text * 0.95);
    final radius = BorderRadius.circular(AppSize.cornerInset(AppSize.gap, AppSize.gap * 2));

    return MarkdownBody(
      data: text,
      selectable: true,
      softLineBreak: true,
      onTapLink: (_, href, _) {
        if (href case final String link?) launchUrl(Uri.parse(link));
      },
      styleSheet: MarkdownStyleSheet(
        p: base,
        a: base.copyWith(color: scheme.primary),
        strong: base.copyWith(fontWeight: FontWeight.w700),
        em: base.copyWith(fontStyle: FontStyle.italic),
        del: base.copyWith(decoration: TextDecoration.lineThrough),
        h1: base.copyWith(fontSize: AppSize.text * 1.6, fontWeight: FontWeight.w700),
        h2: base.copyWith(fontSize: AppSize.text * 1.4, fontWeight: FontWeight.w700),
        h3: base.copyWith(fontSize: AppSize.text * 1.2, fontWeight: FontWeight.w700),
        h4: base.copyWith(fontWeight: FontWeight.w700),
        h5: base.copyWith(fontWeight: FontWeight.w700),
        h6: base.copyWith(fontWeight: FontWeight.w700),
        listBullet: base,
        blockSpacing: AppSize.spaceXS,
        listIndent: AppSize.spaceM,
        blockquote: base.copyWith(color: scheme.text.secondary),
        blockquotePadding: EdgeInsets.only(left: AppSize.spaceXS),
        blockquoteDecoration: BoxDecoration(border: Border(left: BorderSide(color: scheme.line, width: 3))),
        code: code.copyWith(backgroundColor: scheme.surfaceOver),
        codeblockPadding: EdgeInsets.all(AppSize.spaceS),
        codeblockDecoration: BoxDecoration(color: scheme.surfaceOver, borderRadius: radius),
        tableHead: base.copyWith(fontWeight: FontWeight.w700),
        tableBody: base,
        tableBorder: TableBorder.all(color: scheme.line),
        tableCellsPadding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap),
        horizontalRuleDecoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.line)))
      )
    );
  }
}
