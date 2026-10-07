import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/business/business_branch_model.dart';
import 'package:app/services/inventory/product_date.dart';
import 'package:app/services/knowledge/knowledge_entry_model.dart';
import 'package:app/services/knowledge/knowledge_request.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

import './knowledge_lyra_notice.dart';
import './knowledge_product_picker.dart';
import './knowledge_snippets.dart';

/// Opens the panel that writes a new frequent question, or edits [entry].
///
/// Returns what the form collected, or `null` when it was closed without
/// saving. It writes nothing: the knowledge service is the section's, under
/// the navigator this panel opens on.
Future<KnowledgeDraft?> showKnowledgeForm(
  BuildContext context, {
  KnowledgeEntry? entry,
  List<BusinessBranchModel> branches = const [],
  bool branchesFailed = false
}) => showSideModal(
  context: context,
  title: entry == null
    ? S.of(context).knowledge_form_create_title
    : entry.isPending
      ? S.of(context).knowledge_form_answer_title
      : S.of(context).knowledge_form_edit_title,
  builder: (context) => KnowledgeFormModal(
    entry: entry,
    branches: branches,
    branchesFailed: branchesFailed
  )
).then((value) => value is KnowledgeDraft ? value : null);

/// One frequent question: how customers ask it, what Lyra should know to
/// answer it, and where and when that holds.
///
/// **The context is not the reply.** Lyra says it in her own words and adds
/// nothing it does not state, so it is written as facts about the topic —
/// conditions, deadlines, spots, hours, who confirms — and not as a message
/// to a customer. Left empty, the question waits and Lyra does not use it,
/// which is how a question is written before its answer is known.
///
/// **Where and when are fields, the rest is text.** The branch and the
/// products say what the answer is about (Lyra says it as that branch's or
/// those products'), and the dates are the days it holds — outside them Lyra
/// does not give it at all. Spots and hours are said inside the context, where
/// Lyra reads them as the company wrote them ([KnowledgeSnippets]).
///
/// It checks the dates here, in the backend's terms (real days, the first not
/// after the last), so a mistake is said beside the field and not after the
/// panel closed.
class KnowledgeFormModal extends StatefulWidget {
  const KnowledgeFormModal({
    super.key,
    this.entry,
    this.branches = const [],
    this.branchesFailed = false
  });

  /// The question being edited, or `null` for a new one.
  final KnowledgeEntry? entry;

  /// The company's branches. With none (a company of one place) the branch
  /// field is not drawn: everything is the whole company's.
  final List<BusinessBranchModel> branches;

  /// The branches could not be read: said, and the question keeps the branch
  /// it had.
  final bool branchesFailed;

  @override
  State<KnowledgeFormModal> createState() => _KnowledgeFormModalState();
}

class _KnowledgeFormModalState extends State<KnowledgeFormModal> {
  final _form = FormController();

  /// The value of the branch picker that means the whole company.
  static const String _company = "__company__";

  KnowledgeEntry? get _entry => widget.entry;

  late final List<KnowledgeProduct> _products = [...?_entry?.products];

  late final _question = InputController(
    key: "QUESTION",
    form: _form,
    obligatory: true,
    max: 500,
    initial: _entry?.question,
    customErrors: {
      InputError.empty: S.of(context).knowledge_form_question_empty,
      InputError.long: S.of(context).form_long_ma(S.of(context).knowledge_form_question)
    }
  );

  late final _answer = InputController(
    key: "ANSWER",
    form: _form,
    max: 4000,
    initial: _entry?.answer,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(S.of(context).knowledge_form_answer)
    }
  );

  late final _tags = InputController(
    key: "TAGS",
    form: _form,
    max: 500,
    initial: _entry?.tags.join(", "),
    customErrors: {
      InputError.long: S.of(context).form_long_ma(S.of(context).knowledge_form_tags)
    }
  );

  late final _branch = InputController.select(
    key: "BRANCH_ID",
    form: _form,
    initial: _entry?.branch?.id ?? _company
  );

  late final _from = InputController(
    key: "VALID_FROM",
    form: _form,
    max: 10,
    initial: _entry?.from
  );

  late final _until = InputController(
    key: "VALID_UNTIL",
    form: _form,
    max: 10,
    initial: _entry?.until
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  static const double _width = 480;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final s = S.of(context);
    final entry = _entry;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (entry != null && entry.source == KnowledgeSource.assistant)
            KnowledgeLyraNotice(entry: entry)
          else Padding(
            padding: EdgeInsets.only(bottom: AppSize.spaceS),
            child: TextSmall(s.knowledge_form_subtitle, lines: 3, color: scheme.text.secondary)
          ),
          Input(
            title: s.knowledge_form_question,
            placeholder: s.knowledge_form_question_hint,
            controller: _question,
            leftIcon: Icon(CI.help, color: scheme.icon)
          ),
          Input(
            title: s.knowledge_form_answer,
            placeholder: s.knowledge_form_answer_hint,
            controller: _answer,
            lines: 7
          ),
          _Note(text: s.knowledge_form_answer_note),
          KnowledgeSnippets(onAdd: _addLine),
          Input(
            title: _optional(s.knowledge_form_tags),
            placeholder: s.knowledge_form_tags_hint,
            controller: _tags,
            leftIcon: Icon(CI.bookmark, color: scheme.icon)
          ),
          _Note(text: s.knowledge_form_tags_note),
          if (widget.branchesFailed)
            _Note(text: s.knowledge_form_branches_error)
          else if (widget.branches.length > 1 || entry?.branch != null)
            SelectInput(
              title: _optional(s.knowledge_form_branch),
              placeholder: s.knowledge_form_branch_company,
              controller: _branch,
              options: [
                SelectOption(
                  value: _company,
                  placeholder: s.knowledge_form_branch_company,
                  subtitle: s.knowledge_form_branch_company_note,
                  icon: CI.globe_shopping
                ),
                for (final branch in widget.branches) SelectOption(
                  value: branch.id,
                  placeholder: branch.name,
                  icon: CI.store
                ),
                // A branch closed since: kept so the form shows what the
                // question has, and leaving it is the company's call.
                if (entry?.branch != null &&
                    !widget.branches.any((branch) => branch.id == entry!.branch!.id))
                  SelectOption(
                    value: entry!.branch!.id,
                    placeholder: entry.branch!.name,
                    icon: CI.store
                  )
              ],
              emptyText: s.knowledge_form_select_empty,
              searchable: widget.branches.length > 5,
              leftIcon: Icon(CI.store, color: scheme.icon)
            ),
          InputRow(
            title: _optional(s.knowledge_form_dates),
            spacing: AppSize.gap,
            children: [
              Input(
                placeholder: s.knowledge_form_from,
                controller: _from,
                formatters: const [DateSeparatorFormatter()]
              ),
              Input(
                placeholder: s.knowledge_form_until,
                controller: _until,
                formatters: const [DateSeparatorFormatter()]
              )
            ]
          ),
          _Note(text: s.knowledge_form_dates_note),
          SizedBox(height: AppSize.spaceXS),
          TextMedium(_optional(s.knowledge_form_products), multiplier: 0.9, bold: true),
          SizedBox(height: AppSize.gap / 2),
          _Note(text: s.knowledge_form_products_note),
          KnowledgeProductPicker(
            selected: _products,
            onAdd: (product) => setState(() => _products.add(product)),
            onRemove: (product) => setState(() => _products.remove(product))
          ),
          SizedBox(height: AppSize.spaceM),
          Button(title: s.save, action: _submit)
        ]
      )
    );
  }

  /// Adds a line at the end of the context and leaves the cursor after it,
  /// where the company fills the bracket in.
  void _addLine(String line) {
    final controller = _answer.textController;
    final current = controller.text.trimRight();
    final text = current.isEmpty ? line : "$current\n$line";

    controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length)
    );

    _answer.focus.requestFocus();
  }

  void _submit() {
    if (!_form.validate()) return;

    final from = _day(_from.text);
    final until = _day(_until.text);

    if (from == null || until == null || (from.isNotEmpty && until.isNotEmpty && from.compareTo(until) > 0)) {
      FloatFlag.of(context).error(message: S.of(context).knowledge_form_dates_invalid);
      return;
    }

    final branch = _branch.value;

    Navigator.pop(context, KnowledgeDraft(
      question: _question.text,
      answer: _answer.text,
      tags: splitKnowledgeTags(_tags.text),
      // Without a picker drawn the question keeps what it had: a failed read
      // of the branches is not the company deciding it holds everywhere.
      branchId: widget.branchesFailed
        ? _entry?.branch?.id ?? ""
        : branch == _company ? "" : branch,
      from: from,
      until: until,
      products: _products
    ));
  }

  /// A typed day as the backend takes it (`2026-12-31`), `""` for none, or
  /// `null` when it is not a day — a time is not one either: the dates are
  /// whole days.
  String? _day(String raw) {
    if (raw.trim().isEmpty) return "";

    final date = ProductDate.parse(raw);

    return date == null || date.hasTime ? null : date.stored;
  }

  String _optional(String label) => "$label · ${S.of(context).knowledge_form_optional}";
}

/// A line under a field saying what it is for.
class _Note extends StatelessWidget {
  const _Note({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: AppSize.spaceXS),
    child: TextSmall(text, lines: 3, color: ThemeColor.of(context).text.secondary)
  );
}
