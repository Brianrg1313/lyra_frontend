import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';
import 'package:core/form.dart';

/// A zone being written: the area as the company names it, and the price of
/// its own when it differs from the option's.
///
/// Its controllers belong to no form ([InputController] builds each one its
/// own): rows come and go, and a controller that registered in the panel's
/// form would stay in it —and be validated— after its row was removed.
class ZoneDraft {
  ZoneDraft({String initialName = "", String initialFee = ""})
    : name = InputController(
        key: "ZONE_NAME",
        initial: initialName,
        max: 80
      ),
      fee = InputController(
        key: "ZONE_FEE",
        initial: initialFee,
        pattern: "[0-9.,]",
        max: 16
      );

  final InputController name;
  final InputController fee;

  void dispose() {
    name.dispose();
    fee.dispose();
  }
}

/// The zones of a local option: one row each, and a button to add another.
///
/// Rows and not a list of names in one box because a zone may carry a price
/// of its own, and a price has to be written next to the one area it belongs
/// to. An area left blank is not a zone and is dropped on saving, so adding a
/// row by mistake costs nothing.
class ZoneRows extends StatelessWidget {
  const ZoneRows({
    super.key,
    required this.title,
    required this.zones,
    required this.onAdd,
    required this.onRemove
  });

  /// Written by the panel, so this row set is titled like every other field
  /// of the form.
  final String title;

  final List<ZoneDraft> zones;
  final void Function() onAdd;
  final void Function(ZoneDraft zone) onRemove;

  /// Most areas one option may list (the backend's `Delivery.#maxZones`).
  static const int limit = 100;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextSmall(title),
          SizedBox(height: AppSize.gap / 2),
          TextSmall(
            S.of(context).business_delivery_zones_note,
            lines: 3,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.gap),
          for (final zone in zones) KeyedSubtree(
            // The row follows its draft and not its position: without this,
            // removing the first row would leave every input below it drawing
            // the controller of the row that was above.
            key: ObjectKey(zone),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Input(
                    placeholder: S.of(context).business_delivery_zone_name,
                    controller: zone.name
                  )
                ),
                SizedBox(width: AppSize.gap),
                Expanded(
                  flex: 2,
                  child: Input(
                    placeholder: S.of(context).business_delivery_zone_fee,
                    controller: zone.fee
                  )
                ),
                SizedBox(width: AppSize.gap),
                // The height of the input box, so the button sits on the line
                // of the fields it removes and not above them.
                SizedBox(
                  height: AppSize.action,
                  child: Center(child: FocusableWidget(
                    action: () => onRemove(zone),
                    message: S.of(context).business_delivery_zone_remove,
                    child: Icon(
                      CI.trash,
                      size: AppSize.text * 1.1,
                      color: scheme.text.secondary
                    )
                  ))
                )
              ]
            )
          ),
          if (zones.length < limit) Align(
            alignment: Alignment.centerLeft,
            child: Button(
              width: null,
              title: S.of(context).business_delivery_zone_add,
              leftIcon: Icon(CI.plus, color: scheme.button.text),
              action: onAdd
            )
          )
        ]
      )
    );
  }
}
