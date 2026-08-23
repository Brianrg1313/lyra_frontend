import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

import './conversations/_conversations.dart';
import './channel_list/_channel_list.dart';

/// Canales: es el contenido de la seccion `channels` del home.
///
/// Un canal es una cuenta de una red (un numero de WhatsApp, una pagina de
/// Facebook, un perfil de Instagram) conectada a la empresa, con un modelo de
/// IA atendiendo del otro lado. El canal **es** el bot: no hay uno sin el otro,
/// asi que el listado de canales es el listado de bots de la empresa.
///
/// La pantalla son dos paneles al lado. A la derecha, los canales: son pocos
/// —una empresa tiene tres o cuatro cuentas, no cien— y se miran para elegir,
/// no para leerlos. A la izquierda, las conversaciones del que se este mirando,
/// que es donde de verdad se pasa el tiempo: son mensajes, crecen sin techo y
/// se leen renglon por renglon.
///
/// El panel de la izquierda es todavia un placeholder ([ConversationsPanel]) y
/// por eso el de la derecha no tiene canal seleccionado: la seleccion recien
/// tiene sentido cuando haya conversaciones que mostrar de el.
class ChannelsSection extends StatelessWidget {
  const ChannelsSection({super.key});

  /// Ancho del panel de canales. Es fijo y no una fraccion del ancho de la
  /// pantalla porque una fila de canal mide siempre lo mismo —un icono, el
  /// nombre y su estado— y ensancharla no muestra nada mas. Todo lo que sobra
  /// se lo quedan las conversaciones, que si aprovechan el espacio.
  static double get _listWidth => AppSize.action * 7;

  @override
  Widget build(BuildContext context) => Row(children: [
    SizedBox(width: _listWidth, child: const ChannelListPanel()),
    SizedBox(width: AppSize.gap),
    const Expanded(child: ConversationsPanel()),
  ]);
}
