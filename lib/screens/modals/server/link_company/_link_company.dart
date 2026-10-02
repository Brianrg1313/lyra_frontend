import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/toolkit/settings/initial_builder.dart' show hybridService;
import 'package:app/services/business/business_model.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// Asks to join this server's company with its company online (`business.md` B-30, plan D18):
/// once, when [HybridService.shouldAskLink] says so, or whenever the server section offers it
/// ([force]). Says nothing when the account manages no company online. A "not now" to the
/// unasked question is remembered, so it isn't asked again.
Future<void> askLinkCompany(BuildContext context, {bool force = false}) async {
  if (!force && !hybridService.shouldAskLink) return;

  final candidates = await hybridService.linkCandidates().catchError((_) => const <BusinessModel>[]);
  if (candidates.isEmpty || !context.mounted) return;

  final s = S.of(context);
  final linked = await showModal(
    context: context,
    title: candidates.length == 1 ? s.hybrid_link_title(candidates.single.name) : s.hybrid_link_pick_title,
    builder: (context) => LinkCompanyModal(candidates: candidates)
  );

  if (!context.mounted) return;

  if (linked is BusinessModel) {
    FloatFlag.of(context).message(S.of(context).hybrid_link_done(linked.name));
  } else if (!force) {
    hybridService.declineLink();
  }
}

/// The question in plain words: what joining does (the same information in both places, kept
/// equal, so Lyra works without the internet and the online sections work here), and whose the
/// information stays. With several companies online, which one this is, the one named like this
/// server's first. Pops the joined company.
class LinkCompanyModal extends StatefulWidget {
  const LinkCompanyModal({super.key, required this.candidates});

  final List<BusinessModel> candidates;

  @override
  State<LinkCompanyModal> createState() => _LinkCompanyModalState();
}

class _LinkCompanyModalState extends State<LinkCompanyModal> {
  final _form = FormController();
  late final _company = InputController.select(
    key: "COMPANY",
    form: _form,
    obligatory: true,
    initial: widget.candidates.first.id
  );

  static const double _width = 440;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final subtitle = ThemeColor.of(context).subtitle;

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextMedium(s.hybrid_link_subtitle, lines: 6, color: subtitle),
          SizedBox(height: AppSize.spaceS),
          TextSmall(s.hybrid_link_trust, lines: 3, color: subtitle),
          SizedBox(height: AppSize.spaceM),
          if (widget.candidates.length > 1)
            SelectInput(
              placeholder: s.hybrid_link_pick_title,
              controller: _company,
              options: [
                for (final company in widget.candidates)
                  SelectOption(value: company.id, placeholder: company.name)
              ]
            ),
          MainButton(title: s.hybrid_link_join, loading: _form.loading, action: _join),
          SizedBox(height: AppSize.spaceXS),
          Button(title: s.hybrid_link_later, action: () => Navigator.pop(context))
        ]
      )
    );
  }

  Future<void> _join() async {
    if (_form.loading.value || !_form.validate()) return;

    final company = widget.candidates.firstWhere(
      (company) => company.id == _company.value,
      orElse: () => widget.candidates.first
    );

    _form.loading.value = true;

    try {
      await hybridService.link(company);
      if (mounted) Navigator.pop(context, company);
    } catch (e) {
      if (!mounted) return;
      _form.loading.value = false;
      FloatFlag.showFromError(e);
    }
  }
}
