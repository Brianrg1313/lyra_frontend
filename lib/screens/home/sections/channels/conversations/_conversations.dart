import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// Panel izquierdo de la seccion de canales: las conversaciones del canal que se
/// este mirando.
///
/// Todavia no existen, asi que por ahora es solo el marco —el titulo y el hueco
/// donde van a ir— y un mensaje que dice que es esto. Se deja armado y no vacio
/// para que la seccion ya se vea como va a ser: el panel ocupa su lugar, y
/// cuando el listado llegue se reemplaza solo el cuerpo.
class ConversationsPanel extends StatelessWidget {
  const ConversationsPanel({super.key});

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding),
    child: Column(children: [
      // La altura es la del boton y no la del texto: es la que mide el titulo
      // del panel de al lado, que si lleva botones. Sin esto las dos rayas
      // quedarian a distinta altura.
      SizedBox(
        height: AppSize.action,
        child: Align(
          alignment: Alignment.centerLeft,
          child: TextMedium(
            S.of(context).conversations,
            bold: true,
            ellipsis: true
          )
        )
      ),
      Separator.horizontal(
        margin: EdgeInsets.symmetric(vertical: AppSize.padding)
      ),
      Expanded(child: SectionMessage(
        icon: CI.mail,
        title: S.of(context).conversations_empty_title,
        subtitle: S.of(context).conversations_empty_subtitle
      ))
    ])
  );
}
