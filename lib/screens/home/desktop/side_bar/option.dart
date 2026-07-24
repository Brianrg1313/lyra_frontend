import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

class Option extends StatelessWidget {
  const Option({
    required this.icon,
    required this.title,
    required this.action,
    required this.isExpanded,
    this.isActive = false,
    this.badge = 0,
    super.key
  });

  final IconData icon;
  final String title;
  final void Function() action;
  final bool isExpanded;
  final bool isActive;
  final int badge;

  @override
  Widget build(BuildContext context) => Row(children: [
    Row(children: [
      // El indicador ocupa su espacio siempre, activo o no, para que los
      // iconos de todas las opciones queden alineados en la misma columna.
      Container(
        height: AppSize.action,
        width: 3,
        decoration: BoxDecoration(
          color: isActive
            ? ThemeColor.of(context).accent
            : Colors.transparent,
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppSize.corner),
            bottomRight: Radius.circular(AppSize.corner)
          )
        )
      ),
      SizedBox(
        width: AppSize.padding - 3,
      )
    ]),
    Expanded(child: FeedbackButton(
      action: action,
      message: title,
      feedbackColor: ThemeColor.of(context).line,
      color: isActive ? ThemeColor.of(context).line : null,
      child: Row(children: [
        SizedBox(
          width: AppSize.action,
          height: AppSize.action,
          child: Center(child: Icon(
            icon,
            color: isActive
              ? ThemeColor.of(context).primary
              : ThemeColor.of(context).text.secondary
          ))
        ),
        if (isExpanded) ...[
          Expanded(child: TextMedium(title, ellipsis: true)),
          if (badge > 0) Container(
            margin: EdgeInsets.only(right: AppSize.spaceXS),
            padding: EdgeInsets.symmetric(
              horizontal: AppSize.gap,
              vertical: AppSize.gap / 2
            ),
            decoration: BoxDecoration(
              color: ThemeColor.of(context).primary,
              borderRadius: BorderRadius.circular(AppSize.corner)
            ),
            child: TextSmall("$badge", color: Colors.white)
          )
        ]
      ])
    )),
    SizedBox(width: AppSize.padding)
  ]);
}
