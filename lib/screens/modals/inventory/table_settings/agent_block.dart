import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_model.dart';

// WIDGETS
import 'package:app/screens/modals/shared/settings/settings_block.dart';

/// How much the model sees of this table and what it can do with it.
///
/// It is the question that brings most people to this screen: the table is
/// loaded so that a bot answers with it, so what matters is not how many
/// columns it has but how many of them it can cite, how many it can use
/// without saying them and how many it does not even know.
///
/// The four capabilities below are not configured here or anywhere:
/// **they come out of the column types**. A table can be searched by meaning
/// because it has an indexed column, and it reserves stock because it has a
/// stock column. That is why each one says in a line what enables it —or what
/// it is missing—, which is the only actionable thing: it is fixed in the
/// spreadsheet, changing the type of a column.
class TableAgentBlock extends StatelessWidget {
  const TableAgentBlock({super.key, required this.detail});

  final TableDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final agent = detail.agent;

    return SettingsBlock(
      title: S.of(context).table_settings_agent_title,
      subtitle: S.of(context).table_settings_agent_subtitle,
      child: SettingsList(rows: [
        SettingsRow(
          icon: CI.eye,
          label: S.of(context).table_settings_agent_visibility,
          hint: S.of(context).table_settings_agent_visibility_hint,
          child: Wrap(
            spacing: AppSize.gap,
            runSpacing: AppSize.gap * 0.5,
            children: [
              for (final state in TableFieldVisibility.values)
                _VisibilityCount(
                  state: state,
                  count: detail.columns.of(state)
                )
            ]
          )
        ),
        SettingsValue(
          icon: CI.search,
          label: S.of(context).table_settings_agent_searchable,
          value: agent.searchable
            ? S.of(context).table_settings_available
            : S.of(context).table_settings_unavailable,
          hint: agent.searchable
            ? S.of(context).table_settings_agent_searchable_on
            : S.of(context).table_settings_agent_searchable_off
        ),
        SettingsValue(
          icon: CI.list,
          label: S.of(context).table_settings_agent_filterable,
          value: S.of(context).table_settings_column_count(agent.filterable),
          hint: S.of(context).table_settings_agent_filterable_hint
        ),
        SettingsValue(
          icon: Icons.inventory_2_outlined,
          label: S.of(context).table_settings_agent_stock,
          value: agent.stock
            ? S.of(context).table_settings_available
            : S.of(context).table_settings_unavailable,
          hint: agent.stock
            ? S.of(context).table_settings_agent_stock_on
            : S.of(context).table_settings_agent_stock_off
        ),
        SettingsValue(
          icon: CI.image,
          label: S.of(context).table_settings_agent_image,
          value: agent.image
            ? S.of(context).table_settings_available
            : S.of(context).table_settings_unavailable,
          hint: agent.image
            ? S.of(context).table_settings_agent_image_on
            : S.of(context).table_settings_agent_image_off
        )
      ])
    );
  }
}

/// How many columns there are in a visibility state, with what that state
/// means below.
///
/// The three always go, also the ones at zero: the row answers "what the model
/// sees" and for that the three states have to be seen together. A zero that
/// disappears would force knowing the list by heart to notice that one is
/// missing.
///
/// The one at zero is drawn dimmed, so that the ones that do have columns are
/// read first.
class _VisibilityCount extends StatelessWidget {
  const _VisibilityCount({required this.state, required this.count});

  final TableFieldVisibility state;
  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final color = count == 0
      ? scheme.text.secondary
      : switch (state) {
          TableFieldVisibility.visible => scheme.primary,
          TableFieldVisibility.declared => scheme.accent,
          TableFieldVisibility.hidden => scheme.text.secondary
        };

    return Tooltip(
      message: state.hint(context),
      child: SettingsTag(
        icon: state.icon,
        label: S.of(context).table_settings_type_count(
          state.label(context),
          count
        ),
        color: color
      )
    );
  }
}