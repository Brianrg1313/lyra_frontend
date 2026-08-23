import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/channels/channel_lite_model.dart';
import 'package:app/services/channels/channels_service.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';

import 'channel_state_tag.dart';

/// Fila del listado de canales: el icono de la red, el nombre que le puso la
/// empresa con el estado en que esta y, debajo, la tabla de la que contesta.
///
/// **No se toca.** La fila no navega: a la configuracion se entra por "editar"
/// del menu de opciones. El tap queda libre para lo que va a ser —elegir el
/// canal cuyas conversaciones se miran al lado (ver [ChannelsSection])— y hasta
/// entonces la tarjeta es un contenedor y no un boton, para no ofrecer un clic
/// que no lleva a ningun lado.
///
/// Va en dos renglones y no en uno porque el panel de canales es angosto: en una
/// sola linea, el nombre —lo unico que se lee para elegir— quedaria recortado a
/// dos palabras para hacerle lugar al resto. Arriba va entonces lo que
/// identifica al canal, y abajo lo que lo describe, en una linea sola que se
/// corta donde llegue.
///
/// A la derecha lleva el boton de sus opciones, que es desde donde se lo pausa
/// y se lo desconecta sin tener que abrirlo ([_OptionsButton]).
///
/// Del catalogo se lleva **solo el nombre y el icono ya resueltos** y no el
/// proveedor entero: el catalogo se carga una vez y no cambia, asi que esto lo
/// deja de escuchar apenas llego.
class ChannelListRow extends StatelessWidget {
  const ChannelListRow({super.key, required this.channel});

  final ChannelLiteModel channel;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, icon) = context
      .select<ChannelCatalogService, (String, IconData)>((catalog) {
        final provider = catalog.byCode(channel.provider);

        // Sin catalogo (todavia cargando, o fallo) se muestra el codigo crudo:
        // "whatsapp" dice menos que "WhatsApp Business" pero mucho mas que un
        // hueco, y la fila no depende de esa lectura para existir.
        return (provider?.name ?? channel.provider, provider?.icon ?? CI.link);
      });

    // La tabla de la que lee el canal se busca por id en la misma cache que usa
    // la seccion de productos. Vacio mientras las tablas no esten cargadas (o si
    // la tabla elegida ya no existe), y entonces la fila cae en su descripcion.
    final table = channel.tableId.isEmpty ? "" : context.select<
      TablesService,
      String
    >((service) {
      for (final current in service.tables) {
        if (current.id == channel.tableId) return current.title;
      }

      return "";
    });

    return Surface.line(
      padding: EdgeInsets.all(AppSize.spaceXS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Surface(
            width: AppSize.button,
            height: AppSize.button,
            color: scheme.surfaceOver,
            radius: AppSize.cornerInset(AppSize.spaceXS),
            child: Center(child: Icon(
              icon,
              size: AppSize.text * 1.2,
              // Un canal pausado se ve apagado tambien en su icono: es lo
              // primero que se mira de la fila.
              color: channel.enabled ? scheme.icon : scheme.text.secondary
            ))
          ),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(child: TextMedium(
                  channel.name,
                  ellipsis: true,
                  bold: true
                )),
                SizedBox(width: AppSize.gap),
                ChannelStateTag(channel: channel)
              ]),
              // Debajo del nombre va **de que datos contesta el canal**, que es
              // lo que lo distingue de otro de la misma red: la red ya se lee en
              // el icono de la izquierda, asi que repetirla aca se comeria el
              // renglon sin agregar nada.
              //
              // Sin tabla elegida queda la descripcion, y sin ninguna de las dos
              // la red: un renglon en blanco desalinearia la fila contra las
              // demas del listado.
              TextSmall(
                table.isNotEmpty
                  ? table
                  : channel.description.isEmpty ? label : channel.description,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          )),
          SizedBox(width: AppSize.spaceXS),
          _OptionsButton(channel: channel)
        ])
      );
  }
}

/// El boton de las opciones de un canal, con el desplegable que despliega.
///
/// Es un widget aparte y no un metodo de la fila porque el desplegable se
/// cuelga **de el**: se ancla al contexto de quien lo abre, y ese tiene que ser
/// el boton y no la fila entera, o se abriria desde el borde izquierdo.
class _OptionsButton extends StatelessWidget {
  const _OptionsButton({required this.channel});

  final ChannelLiteModel channel;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: () => _open(context),
    width: AppSize.button,
    height: AppSize.button,
    radius: AppSize.cornerInset(AppSize.spaceXS),
    message: S.of(context).channel_options,
    child: Center(child: Icon(
      CI.dots_horizontal,
      size: AppSize.text * 1.2,
      color: ThemeColor.of(context).icon
    ))
  );

  /// Abre el desplegable anclado al boton. Sin buscador y sin la medida de un
  /// formulario ([dense]): son tres opciones, no una lista.
  Future<void> _open(BuildContext context) async {
    final picked = await showSelectMenu(
      context: context,
      dense: true,
      options: [
        SelectOption(
          value: "edit",
          placeholder: S.of(context).edit_channel,
          icon: CI.edit
        ),
        SelectOption(
          value: "toggle",
          placeholder: channel.enabled
            ? S.of(context).channel_pause
            : S.of(context).channel_resume,
          icon: channel.enabled
            ? Icons.pause_circle_outline
            : Icons.play_circle_outline
        ),
        SelectOption(
          value: "delete",
          placeholder: S.of(context).delete_channel,
          icon: CI.trash
        )
      ]
    );

    if (picked == null || !context.mounted) return;

    switch (picked.value) {
      case "edit":
        Navis.push(context, "/home/channels/${channel.id}");
      case "toggle":
        await _toggle(context);
      case "delete":
        await _delete(context);
    }
  }

  /// Pausa o reanuda el canal. No se pregunta nada: es reversible con el mismo
  /// clic y no se pierde ni un dato, la configuracion queda intacta.
  Future<void> _toggle(BuildContext context) async {
    // El aviso se arma antes: el servicio corrige la fila en el acto y este
    // contexto puede repintarse mientras el cambio viaja.
    final message = channel.enabled
      ? S.of(context).channel_paused
      : S.of(context).channel_resumed;

    final changed = await context.read<ChannelsService>().toggle(
      context,
      channel
    );

    // Si fallo, el servicio ya volvio la fila a como estaba y mostro el error.
    if (!changed) return;

    FloatFlag.of().message(message);
  }

  /// Desconecta el canal, previa confirmacion.
  ///
  /// Se pregunta aca y no en el servicio porque lo que se lleva la baja no cabe
  /// en el listado: **las credenciales se van con el canal**, asi que volver a
  /// conectar esa misma cuenta significa pedirle los tokens a Meta otra vez. El
  /// aviso nombra el canal para que no se confirme sobre la fila equivocada.
  Future<void> _delete(BuildContext context) async {
    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).channel_delete_title,
      message: S.of(context).channel_delete_message(channel.name),
      confirmText: S.of(context).delete_channel,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    // El aviso se arma **antes** de la baja: cuando esta salga bien, esta fila
    // ya no va a existir —el listado se repinta sin ella— y su contexto no
    // servira ni para leer el texto.
    final message = S.of(context).channel_deleted;

    final deleted = await context.read<ChannelsService>().remove(
      context,
      channel
    );

    // Si fallo, el error ya se mostro en el servicio y el canal sigue en el
    // listado, que es lo que corresponde: no se desconecto nada.
    if (!deleted) return;

    // Sin contexto: el de la fila se desmonto con ella. La bandera flotante se
    // cuelga del navegador, que sigue ahi.
    FloatFlag.of().message(message);
  }
}
