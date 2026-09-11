/// **The rows a read-only side panel is built from.**
///
/// They were written for the table settings and they live here because a second
/// panel now draws them (the sale detail): the shapes are the panel's and not
/// one section's — a group of data points, a data point, its value, its label,
/// its figure, its action. A copy per section is the same widget written twice
/// and watched as the copies drift.
///
/// Nothing here decides anything. The colour of a tag, the wording of an empty
/// value and what a row is worth are all passed in, because those are the parts
/// each panel owns.
library;

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// A group of data points, over its own surface.
///
/// The surface is a block **over** the sheet of the screen ([Surface.over])
/// and not another sheet: what separates is one group of data points from the
/// next, not one screen from another. It is the same criterion with which the
/// business profile is built.
///
/// The subtitle is not decorative: almost no group of these panels explains
/// itself only with its title —"what the AI sees" and "connected channels" are
/// the two concepts that have to be introduced, not remembered.
class SettingsBlock extends StatelessWidget {
  const SettingsBlock({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// What can be done with the whole group and not with one of its data
  /// points. It goes in the title because it does not belong to any row.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: TextMedium(title, bold: true, ellipsis: true)),
              ?action
            ]),
            if (subtitle != null) ...[
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                subtitle!,
                lines: 3,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ],
            SizedBox(height: AppSize.spaceS),
            child
          ]
        )
      )
    );
  }
}

/// A data point of a block: what it is recognized by, what it is called, what
/// it is for and how much it is worth.
///
/// The value goes **below** the name and not glued to the right edge: almost
/// all the ones in this screen need a line that explains them (what "declared"
/// means, why there are two dates), and a label-and-value row leaves no room
/// for that. Read in a column, each data point is three lines that are read in
/// a row.
///
/// The value is a [child] and not a text because it is not always something
/// that is read: the visibility is a color label and the column types are a
/// row of them. What is a text is built with [SettingsValue], which is this
/// same box with a row inside.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.hint,
    this.action
  });

  /// What the data point is recognized by at a glance, without reading its
  /// name.
  final IconData icon;

  final String label;

  /// How much the data point is worth.
  final Widget child;

  /// What the data point means, in one line. Optional on purpose: it is
  /// written where the name is not enough and left out where the name already
  /// says everything.
  final String? hint;

  /// What is done with the data point: edit it, copy it. It goes on the right
  /// edge of the row and not below the value because it operates on the whole
  /// data point, not on what it is worth today.
  ///
  /// In `null` no slot is reserved —unlike the business card— because here
  /// most data points are not edited: it is a status screen with two texts
  /// that are written, and a column of empty buttons would promise actions
  /// that do not exist.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Lowers the icon to the name line: aligned to the top it would be
          // hanging above the first letter.
          padding: EdgeInsets.only(top: AppSize.gap * 0.5),
          child: Icon(icon, size: AppSize.text, color: scheme.text.secondary)
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextSmall(label, color: scheme.text.secondary),
            SizedBox(height: AppSize.gap * 0.5),
            child,
            if (hint != null) ...[
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                hint!,
                lines: 3,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          ]
        )),
        if (action != null) ...[
          SizedBox(width: AppSize.gap),
          action!
        ]
      ]
    );
  }
}

/// A data point that is read: [SettingsRow] with its value written.
///
/// An empty value is said with words and in grey ([empty]): a dash or a blank
/// line would be read as if the card broke, not as if that data point is not
/// loaded.
class SettingsValue extends StatelessWidget {
  const SettingsValue({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.empty,
    this.selectable = false,
    this.action
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;

  /// What to say when there is no value. Without it the empty is shown as is,
  /// which is what is right for the data points that already come written as
  /// text.
  final String? empty;

  /// Whether the value can be selected to copy it. It goes where the data
  /// point is used outside the app (the table identifier), not where it is
  /// only read.
  final bool selectable;

  /// What is done with the data point. See [SettingsRow.action].
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final blank = value.trim().isEmpty;

    return SettingsRow(
      icon: icon,
      label: label,
      hint: hint,
      action: action,
      child: TextMedium(
        blank ? (empty ?? "") : value,
        lines: 3,
        ellipsis: true,
        selectable: !blank && selectable,
        color: blank ? scheme.text.secondary : null
      )
    );
  }
}

/// The data points of a block, one below the other and separated by a line.
///
/// The separation is wider than that of any list because each data point is
/// no longer one line: they are three —name, value and explanation— and
/// pressed one against the other they stop being read as different data
/// points.
class SettingsList extends StatelessWidget {
  const SettingsList({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (int i = 0; i < rows.length; i++) ...[
        if (i > 0) Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
        ),
        rows[i]
      ]
    ]
  );
}

/// Label of a state: icon and text over a faint fill of its own color.
///
/// It is for what the card **says** about a data point and not for what the
/// data point is worth: how much the model sees of a column, what type it is,
/// whether a channel is paused. They are read at a glance and none is edited,
/// so they are not one more row.
///
/// The color is put by the one who uses it and not by the label: it is
/// semantic —the brand color when the data point enables something, grey when
/// it only informs— and lives next to the state that it means.
class SettingsTag extends StatelessWidget {
  const SettingsTag({
    super.key,
    required this.label,
    required this.color,
    this.icon
  });

  final String label;
  final Color color;

  /// Without an icon the label is only its text. It is what fits where they
  /// are several in a row and the icon would be repeated noise.
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSize.gap,
      vertical: AppSize.gap * 0.4
    ),
    decoration: BoxDecoration(
      // A barely tinted background instead of a full one: the label
      // accompanies the data point, it does not compete with it.
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSize.corner)
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSize.text * 0.9, color: color),
          SizedBox(width: AppSize.gap * 0.5)
        ],
        // Flexible and not bare: the tag shrinks to its label, so a label
        // longer than the row it sits in overflows the tag instead of wrapping
        // it. The table settings only ever gave it a word ("Texto", "Pública")
        // and never met it; the sale detail says whole sentences with one
        // ("said to be held, and nothing is"), and a panel is narrow.
        Flexible(child: TextSmall(label, ellipsis: true, color: color))
      ]
    )
  );
}

/// A big number with what it counts below.
///
/// It is for the three figures that answer "how big is this table" —how many
/// records, how many columns, how many channels read it—, which are the first
/// thing looked at when entering and do not have to be searched inside a list
/// of rows.
class SettingsStat extends StatelessWidget {
  const SettingsStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.tint
  });

  final IconData icon;

  /// The figure already written: whoever builds it decides how a number that
  /// could not be counted is read.
  final String value;

  final String label;

  /// Color of the number, for when the figure means something (that a channel
  /// reaches the table). Without it the text color goes.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      padding: EdgeInsets.all(AppSize.spaceXS),
      color: scheme.surface,
      radius: AppSize.cornerInset(AppSize.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.text, color: scheme.text.secondary),
          SizedBox(height: AppSize.gap),
          // Big but not double ([TextLarge]): they are three figures next to
          // each other in a card, not the title of the screen.
          TextMedium(
            value,
            multiplier: 1.6,
            bold: true,
            ellipsis: true,
            color: tint
          ),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(label, ellipsis: true, color: scheme.text.secondary)
        ]
      )
    );
  }
}

/// Button of an action on a settings data point.
///
/// It is the size of the row and without fill until it is pointed at: the
/// screen is for reading, and buttons painted all the time in each row would
/// turn it into a button panel. The rest color is the card's and not
/// transparent, so that the two ends of the [FeedbackButton] animation are
/// opaque.
///
/// It is a sibling of the business card button and not the same one: they are
/// two different sections, and sharing a row widget would tie them by
/// something that is only similar.
class SettingsAction extends StatelessWidget {
  const SettingsAction({
    super.key,
    required this.icon,
    required this.message,
    required this.action
  });

  final IconData icon;

  /// What the button does. It is the only thing that names it: it carries no
  /// text.
  final String message;

  final void Function() action;

  /// Side of the button. It comes from the size of the text and not from
  /// [AppSize.button] because it lives with a row, not with an action bar.
  static double get size => AppSize.text * 2;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      message: message,
      width: size,
      height: size,
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.surfaceOver,
      feedbackColor: scheme.line,
      child: Center(child: Icon(
        icon,
        size: AppSize.text,
        color: scheme.text.secondary
      ))
    );
  }
}

/// A two-state data point, drawn as the checkbox that says it.
///
/// It is the sibling of [SettingsSelect] for what turns on and off: the
/// checkbox **is** the value, so it is touched once and saves itself, without
/// unfolding a two-row list to choose between yes and no. The text to the side
/// says which of the two states is the one set, because a checkbox alone
/// forces knowing which question it answers.
///
/// Off it goes grey: in a list of twenty columns what has to be able to be
/// swept at a glance is which ones were left out.
///
/// It stretches to whatever it is given, same as [SettingsSelect]: it always
/// goes inside a cell with width.
class SettingsToggle extends StatelessWidget {
  const SettingsToggle({
    super.key,
    required this.value,
    required this.label,
    required this.toggle,
    this.message
  });

  /// In which state it is today.
  final bool value;

  /// What that state means, already written.
  final String label;

  /// Inverts it. Who passes it is who saves: nothing is saved optimistically
  /// here, the value that is drawn is the one the card has.
  final void Function() toggle;

  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: toggle,
      message: message,
      height: AppSize.button,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.spaceXS),
      // The same fill as the dropdown: the two are data points that are
      // touched and go in the same row, so they are drawn over the same box.
      color: scheme.surface.withAlpha(150),
      feedbackColor: scheme.surface,
      child: Row(children: [
        _Check(value: value),
        SizedBox(width: AppSize.gap * 0.75),
        Expanded(child: TextSmall(
          label,
          ellipsis: true,
          color: value ? null : scheme.text.secondary
        ))
      ])
    );
  }
}

/// The checkbox of [SettingsToggle]: square, filled when it is set.
///
/// It is the same mark the option cards of the forms use, and square for the
/// same reason: the square is the convention of "this turns on and off on its
/// own", against the circle of "one of these".
class _Check extends StatelessWidget {
  const _Check({required this.value});

  final bool value;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final size = AppSize.text * 1.2;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: value ? scheme.primary : Colors.transparent,
        border: Border.all(
          color: value ? scheme.primary : scheme.line,
          width: 1.5
        ),
        borderRadius: BorderRadius.circular(AppSize.gap)
      ),
      child: value
        ? Center(child: Icon(
            CI.check,
            size: size * 0.65,
            color: scheme.button.text
          ))
        : null
    );
  }
}

/// A data point chosen from a list, drawn as the button that unfolds it.
///
/// It is the version of [SettingsAction] for what is not an action but a
/// value: it shows **what it is worth today** —with its icon and its color,
/// which in the visibility mean something— and touching it unfolds the
/// options. That is why it is not a [SelectInput]: a form that will be saved
/// later is not being filled, a data point that already exists is being
/// changed and it saves itself. Three form fields per row, in a list of
/// twenty columns, would be sixty form boxes to read a table.
///
/// The dropdown is anchored **to this button** ([showSelectMenu] measures the
/// widget that is passed to it), so whoever opens it receives the context of
/// here inside and not the row's: hanging from the row it would open from the
/// left edge.
///
/// It stretches to whatever it is given: it always goes inside a cell with
/// width (`Expanded`), never loose in a `Wrap`.
class SettingsSelect extends StatelessWidget {
  const SettingsSelect({
    super.key,
    required this.label,
    required this.open,
    this.icon,
    this.color,
    this.message
  });

  /// What it is worth today, already written.
  final String label;

  /// Opens the dropdown. It receives the context of the button, which is what
  /// gives it its position on screen.
  final Future<void> Function(BuildContext anchor) open;

  final IconData? icon;

  /// Color of the icon and the text, for when the value means something (the
  /// three states of the visibility). Without it the normal text color goes.
  final Color? color;

  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: () => open(context),
      message: message,
      height: AppSize.button,
      padding: EdgeInsets.only(
        left: AppSize.spaceXS,
        right: AppSize.gap
      ),
      radius: AppSize.cornerInset(AppSize.spaceXS),
      // The page color and not the card one: the block is already a surface
      // over it, and a fill of the same color would not be seen.
      color: scheme.surface.withAlpha(150),
      feedbackColor: scheme.surface,
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: AppSize.text * 0.9, color: color ?? scheme.icon),
          SizedBox(width: AppSize.gap * 0.75)
        ],
        Expanded(child: TextSmall(label, ellipsis: true, color: color)),
        SizedBox(width: AppSize.gap * 0.5),
        Icon(
          CI.arrow_down,
          size: AppSize.text * 1.5,
          color: scheme.text.secondary
        )
      ])
    );
  }
}