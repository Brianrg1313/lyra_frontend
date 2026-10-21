import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:genui/genui.dart' as genui;
import 'package:json_schema_builder/json_schema_builder.dart' as js;

// WIDGETS
import 'package:core/button.dart';
import 'package:app/screens/home/sections/dashboard/widgets/usage_bar.dart';

/// The widgets the assistant may draw in the chat (GenUI's vocabulary).
///
/// Layout comes from GenUI's basic catalog (`Column`, `Row`: plain Flutter
/// flex); everything visible is drawn with `core`, so a generated answer looks
/// like the rest of the app and follows its theme. Each item's schema is what
/// the model is told it can send: keep names and properties stable, a rename
/// breaks every prompt that learned the old one.
abstract final class LyraCatalog {
  /// Sent by the model in `createSurface.catalogId`.
  static const String id = "lyra.catalog.v1";

  static genui.Catalog build() => genui.Catalog([
    genui.BasicCatalogItems.column,
    genui.BasicCatalogItems.row,
    _text,
    _card,
    _divider,
    _button,
    _metric,
    _progress,
    _item
  ], catalogId: id);
}

typedef _Data = Map<String, Object?>;

_Data _data(genui.CatalogItemContext context) => context.data as _Data;

final _text = genui.CatalogItem(
  name: "Text",
  dataSchema: js.S.object(
    description: "A line or paragraph of text. Markdown is not rendered: use a Card with Items for lists.",
    properties: {
      "text": genui.A2uiSchemas.stringReference(),
      "variant": js.S.string(enumValues: ["title", "body", "caption"])
    },
    required: ["text"]
  ),
  widgetBuilder: (item) {
    final data = _data(item);

    return genui.BoundString(
      dataContext: item.dataContext,
      value: data["text"],
      builder: (context, value) => switch (data["variant"]) {
        "title" => TextMedium(value ?? "", multiplier: 1.25, bold: true, lines: 3),
        "caption" => TextSmall(value ?? "", color: ThemeColor.of(context).text.secondary, lines: 6),
        _ => TextMedium(value ?? "", lines: 40)
      }
    );
  }
);

final _card = genui.CatalogItem(
  name: "Card",
  dataSchema: js.S.object(
    description: "A bordered panel grouping one child (usually a Column).",
    properties: {"child": genui.A2uiSchemas.componentReference()},
    required: ["child"]
  ),
  widgetBuilder: (item) {
    final scheme = ThemeColor.of(item.buildContext);

    return Surface.line(
      width: double.infinity,
      color: scheme.surfaceOver,
      borderColor: scheme.lineOver,
      radius: AppSize.cornerInset(AppSize.gap),
      padding: EdgeInsets.all(AppSize.spaceS),
      child: item.buildChild(_data(item)["child"] as String)
    );
  }
);

final _divider = genui.CatalogItem(
  name: "Divider",
  dataSchema: js.S.object(description: "A thin horizontal line."),
  widgetBuilder: (item) => Separator.horizontal()
);

final _button = genui.CatalogItem(
  name: "Button",
  dataSchema: js.S.object(
    description: "A control the person presses. Its action event comes back as their next turn.",
    properties: {
      "label": genui.A2uiSchemas.stringReference(),
      "variant": js.S.string(enumValues: ["primary", "secondary"]),
      "action": genui.A2uiSchemas.action()
    },
    required: ["label", "action"]
  ),
  // Shares a Row with its siblings instead of overflowing it.
  isImplicitlyFlexible: true,
  widgetBuilder: (item) {
    final data = _data(item);

    return genui.BoundString(
      dataContext: item.dataContext,
      value: data["label"],
      builder: (context, label) {
        void press() => _dispatch(item, data["action"]);

        return data["variant"] == "primary"
          ? MainButton(title: label, action: press)
          : Button(title: label, action: press);
      }
    );
  }
);

/// Sends a control's `event` back through the surface: GenUI turns it into
/// the person's next message.
Future<void> _dispatch(genui.CatalogItemContext item, Object? action) async {
  if (action is! Map || action["event"] is! Map) return;

  final event = (action["event"] as Map).cast<String, Object?>();
  final context = await genui.resolveContext(item.dataContext, (event["context"] as Map?)?.cast<String, Object?>());

  item.dispatchEvent(genui.UserActionEvent(
    name: event["name"] as String,
    sourceComponentId: item.id,
    context: context
  ));
}

final _metric = genui.CatalogItem(
  name: "Metric",
  dataSchema: js.S.object(
    description: "One figure with its label and, optionally, its change in percent against a previous period.",
    properties: {
      "label": js.S.string(),
      "value": genui.A2uiSchemas.numberReference(),
      "format": js.S.string(enumValues: ["number", "currency", "percent"]),
      "delta": js.S.number(description: "Change in percent: 12.4 reads +12.4%.")
    },
    required: ["label", "value"]
  ),
  isImplicitlyFlexible: true,
  widgetBuilder: (item) {
    final data = _data(item);

    return genui.BoundNumber(
      dataContext: item.dataContext,
      value: data["value"],
      builder: (context, value) => StatTile(
        label: data["label"] as String? ?? "",
        value: (value ?? 0).toDouble(),
        format: switch (data["format"]) {
          "currency" => ChartFormat.currency(compact: false, decimals: 2),
          "percent" => ChartFormat.percent(),
          _ => ChartFormat.number()
        },
        delta: (data["delta"] as num?)?.toDouble()
      )
    );
  }
);

final _progress = genui.CatalogItem(
  name: "Progress",
  dataSchema: js.S.object(
    description: "A labelled bar filled from 0 to 1 (usage, stock left, progress of a task).",
    properties: {
      "label": js.S.string(),
      "caption": js.S.string(),
      "value": genui.A2uiSchemas.numberReference(description: "From 0 to 1."),
      "tone": js.S.string(enumValues: ["good", "warning", "critical"])
    },
    required: ["label", "value"]
  ),
  widgetBuilder: (item) {
    final data = _data(item);

    return genui.BoundNumber(
      dataContext: item.dataContext,
      value: data["value"],
      builder: (context, value) {
        final fraction = (value ?? 0).toDouble().clamp(0.0, 1.0);

        return UsageBar(
          label: data["label"] as String? ?? "",
          caption: data["caption"] as String?,
          value: fraction,
          color: _tone(context, data["tone"]) ?? _level(context, fraction)
        );
      }
    );
  }
);

final _item = genui.CatalogItem(
  name: "Item",
  dataSchema: js.S.object(
    description: "A row of a list: an icon, a title, a subtitle and a trailing note.",
    properties: {
      "title": js.S.string(),
      "subtitle": js.S.string(),
      "trailing": js.S.string(),
      "icon": js.S.string(enumValues: _icons.keys.toList()),
      "tone": js.S.string(enumValues: ["good", "warning", "critical"])
    },
    required: ["title"]
  ),
  widgetBuilder: (item) {
    final data = _data(item);
    final context = item.buildContext;
    final scheme = ThemeColor.of(context);
    final tone = _tone(context, data["tone"]);

    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSize.gap * 0.6),
      child: Row(children: [
        Container(
          width: AppSize.button,
          height: AppSize.button,
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(AppSize.cornerInset(AppSize.gap, AppSize.gap * 2))
          ),
          child: Stack(children: [
            Center(child: Icon(_icons[data["icon"]] ?? CI.info, size: AppSize.text * 1.3, color: scheme.icon)),
            if (tone != null) Positioned(
              right: AppSize.gap * 0.6,
              bottom: AppSize.gap * 0.6,
              child: Container(
                width: AppSize.gap * 1.4,
                height: AppSize.gap * 1.4,
                decoration: BoxDecoration(color: tone, shape: BoxShape.circle)
              )
            )
          ])
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextMedium(data["title"] as String? ?? "", bold: true, ellipsis: true),
            if (data["subtitle"] case final String subtitle) TextSmall(subtitle, color: scheme.text.secondary, ellipsis: true)
          ]
        )),
        if (data["trailing"] case final String trailing) TextSmall(trailing, color: scheme.text.secondary)
      ])
    );
  }
);

const Map<String, IconData> _icons = {
  "sale": CI.sale,
  "inventory": CI.inventory,
  "employee": CI.employee,
  "chat": CI.chat,
  "wallet": CI.wallet,
  "delivery": CI.delivery,
  "calendar": CI.calendar,
  "info": CI.info
};

Color? _tone(BuildContext context, Object? tone) {
  final chart = ThemeColor.of(context).chart;

  return switch (tone) {
    "good" => chart.good,
    "warning" => chart.warning,
    "critical" => chart.critical,
    _ => null
  };
}

/// What is left reads by how little: a near-empty bar is the alarm.
Color _level(BuildContext context, double fraction) {
  final chart = ThemeColor.of(context).chart;

  if (fraction < 0.15) return chart.critical;
  if (fraction < 0.35) return chart.warning;
  return chart.good;
}
