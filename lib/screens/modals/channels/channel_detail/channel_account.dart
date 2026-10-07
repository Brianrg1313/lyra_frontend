import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/channels/channel_detail_model.dart';
import 'package:app/screens/home/sections/_section/form/form_block.dart';

// WIDGETS

/// The two facts about a channel that are read and never written: which
/// account on the network it is attached to, and its own id.
///
/// Neither is edited and that is why they are up here instead of among the
/// pickers below. The account id is **computed by the backend** out of the
/// configuration —it is not a field anybody types— and the channel id is what
/// identifies this connection to support and in a table's "who reads me"
/// list. Both are selectable because the only thing anybody does with them is
/// copy them into a message.
///
/// The account line is left out entirely when the channel has none yet, which
/// is the normal state of a channel registered before its tokens exist: an
/// empty "Account: —" would read as something having gone missing.
class ChannelAccount extends StatelessWidget {
  const ChannelAccount({super.key, required this.detail});

  final ChannelDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final account = detail.externalId ?? "";

    return FormBlock(
      title: S.of(context).channel_account_title,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (account.isNotEmpty) ...[
            _Line(label: S.of(context).channel_account_id, value: account),
            SizedBox(height: AppSize.gap)
          ],
          _Line(label: S.of(context).channel_own_id, value: detail.id)
        ]
      )
    );
  }
}

/// One `label: value` line. The value can be selected and the label cannot:
/// what gets copied is the id, never the word in front of it.
class _Line extends StatelessWidget {
  const _Line({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextSmall(label, color: scheme.text.secondary),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: TextSmall(
          value,
          selectable: true,
          lines: 2,
          ellipsis: true,
          textAlign: TextAlign.end
        ))
      ]
    );
  }
}
