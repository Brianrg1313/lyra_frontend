import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/connections/connection_catalog_service.dart';
import 'package:app/services/connections/connection_lite_model.dart';
import 'package:app/services/connections/connections_service.dart';

// WIDGETS
import 'package:core/form.dart';

import 'connection_state_tag.dart';

/// Fila del listado de conexiones: el icono del servicio, el nombre que le puso
/// la empresa con el estado en que esta y, debajo, de que servicio es la cuenta y
/// cuantos bots estan contestando a traves de ella.
///
/// Al tocarla se abre su configuracion (`/home/connections/:id`), que es lo unico
/// que se hace con una cuenta conectada: revisarle o corregirle las credenciales.
/// A la derecha lleva el boton de sus opciones, que es desde donde se la pausa y
/// se la desconecta sin tener que abrirla ([_OptionsButton]).
///
/// Del catalogo se lleva **solo el nombre y el icono ya resueltos** y no el
/// proveedor entero: el catalogo se carga una vez y no cambia, asi que esto lo
/// deja de escuchar apenas llego.
class ConnectionListRow extends StatelessWidget {
  const ConnectionListRow({super.key, required this.connection});

  final ConnectionLiteModel connection;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, icon) = context
      .select<ConnectionCatalogService, (String, IconData)>((catalog) {
        final provider = catalog.byCode(connection.provider);

        // Sin catalogo (todavia cargando, o fallo) se muestra el codigo crudo:
        // "whatsapp" dice menos que "WhatsApp Business" pero mucho mas que un
        // hueco, y la fila no depende de esa lectura para existir.
        return (provider?.name ?? connection.provider, provider?.icon ?? CI.link);
      });

    return FeedbackButton(
      action: () => Navis.push(context, "/home/connections/${connection.id}"),
      color: scheme.surfaceOver,
      padding: EdgeInsets.all(AppSize.spaceS),
      child: Row(children: [
        Container(
          width: AppSize.action,
          height: AppSize.action,
          decoration: BoxDecoration(
            color: scheme.surfaceOver,
            borderRadius: BorderRadius.circular(AppSize.corner)
          ),
          child: Center(child: Icon(
            icon,
            size: AppSize.text * 1.2,
            // Una cuenta pausada se ve apagada tambien en su icono: es lo
            // primero que se mira de la fila.
            color: connection.enabled ? scheme.icon : scheme.text.secondary
          ))
        ),
        SizedBox(width: AppSize.spaceS),
        Expanded(child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Flexible(child: TextMedium(
                connection.name,
                ellipsis: true,
                bold: true
              )),
              SizedBox(width: AppSize.spaceS),
              ConnectionStateTag(connection: connection)
            ]),
            SizedBox(height: AppSize.gap),
            TextSmall(
              _subtitle(context, label),
              ellipsis: true,
              color: scheme.text.secondary
            )
          ]
        )),
        SizedBox(width: AppSize.spaceS),
        _OptionsButton(connection: connection)
      ])
    );
  }

  /// Que servicio es, cuanto esta corriendo encima y, si la tiene, la descripcion
  /// que le puso la empresa, en un solo renglon.
  ///
  /// El servicio va primero porque es lo que identifica la cuenta —dos filas
  /// pueden llamarse parecido— y los bots inmediatamente despues: es lo que
  /// vuelve util la fila, y lo que la baja se lleva puesto.
  String _subtitle(BuildContext context, String label) => [
    label,
    S.of(context).connection_bot_count(connection.bots),
    if (connection.description.isNotEmpty) connection.description
  ].join(" · ");
}

/// El boton de las opciones de una conexion, con el desplegable que despliega.
///
/// Es un widget aparte y no un metodo de la fila porque el desplegable se cuelga
/// **de el**: se ancla al contexto de quien lo abre, y ese tiene que ser el boton
/// y no la fila entera, o se abriria desde el borde izquierdo.
///
/// Las dos cosas que ofrece se resuelven aca y no en la fila: la fila es lo que se
/// toca para entrar en la configuracion, y estas dos no entran en ella.
class _OptionsButton extends StatelessWidget {
  const _OptionsButton({required this.connection});

  final ConnectionLiteModel connection;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: () => _open(context),
    width: AppSize.action,
    height: AppSize.action,
    color: ThemeColor.of(context).surfaceOver,
    message: S.of(context).connection_options,
    child: Center(child: Icon(
      CI.dots_horizontal,
      size: AppSize.text * 1.2,
      color: ThemeColor.of(context).icon
    ))
  );

  /// Abre el desplegable anclado al boton. Sin buscador y sin la medida de un
  /// formulario ([dense]): son dos opciones, no una lista.
  Future<void> _open(BuildContext context) async {
    final picked = await showSelectMenu(
      context: context,
      dense: true,
      options: [
        SelectOption(
          value: "toggle",
          placeholder: connection.enabled
            ? S.of(context).connection_pause
            : S.of(context).connection_resume,
          icon: connection.enabled
            ? Icons.pause_circle_outline
            : Icons.play_circle_outline
        ),
        SelectOption(
          value: "delete",
          placeholder: S.of(context).delete_connection,
          icon: CI.trash
        )
      ]
    );

    if (picked == null || !context.mounted) return;

    switch (picked.value) {
      case "toggle":
        await _toggle(context);
      case "delete":
        await _delete(context);
    }
  }

  /// Pausa o reanuda la cuenta. No se pregunta nada: es reversible con el mismo
  /// clic y no se pierde ni un dato —ni la configuracion ni los bots que corren
  /// sobre ella—, solo dejan de contestar.
  Future<void> _toggle(BuildContext context) async {
    // El aviso se arma antes: el servicio corrige la fila en el acto y este
    // contexto puede repintarse mientras el cambio viaja.
    final message = connection.enabled
      ? S.of(context).connection_paused
      : S.of(context).connection_resumed;

    final changed = await context.read<ConnectionsService>().toggle(
      context,
      connection
    );

    // Si fallo, el servicio ya volvio la fila a como estaba y mostro el error.
    if (!changed) return;

    FloatFlag.of().message(message);
  }

  /// Desconecta la cuenta, previa confirmacion.
  ///
  /// Se pregunta aca y no en el servicio porque lo que se lleva la baja no cabe
  /// en el listado, y son dos cosas: **las credenciales**, asi que volver a
  /// conectar esa misma cuenta significa pedirle los tokens al servicio otra vez,
  /// y **los bots que contestaban a traves de ella**, porque un bot sin cuenta no
  /// tiene por donde contestar. Lo segundo solo se nombra cuando hay alguno, y es
  /// la razon de que pausar exista: eso los deja quietos sin borrarlos.
  ///
  /// El aviso nombra la cuenta para que no se confirme sobre la fila equivocada.
  Future<void> _delete(BuildContext context) async {
    final message = StringBuffer(
      S.of(context).connection_delete_message(connection.name)
    );

    if (connection.bots > 0) {
      message
        ..write(" ")
        ..write(S.of(context).connection_delete_bots(connection.bots));
    }

    final confirmed = await showAlertModal(
      context: context,
      title: S.of(context).connection_delete_title,
      message: message.toString(),
      confirmText: S.of(context).delete_connection,
      cancelText: S.of(context).cancel
    );

    if (!confirmed || !context.mounted) return;

    // El aviso se arma **antes** de la baja: cuando esta salga bien, esta fila ya
    // no va a existir —el listado se repinta sin ella— y su contexto no servira
    // ni para leer el texto.
    final done = S.of(context).connection_deleted;

    final deleted = await context.read<ConnectionsService>().remove(
      context,
      connection
    );

    // Si fallo, el error ya se mostro en el servicio y la cuenta sigue en el
    // listado, que es lo que corresponde: no se desconecto nada.
    if (!deleted) return;

    // Sin contexto: el de la fila se desmonto con ella. La bandera flotante se
    // cuelga del navegador, que sigue ahi.
    FloatFlag.of().message(done);
  }
}
