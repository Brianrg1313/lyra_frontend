import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/channels/channel_catalog_service.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';

import 'settings_block.dart';

/// Los canales que leen esta tabla.
///
/// **Van en dos listas y no en una**, porque son dos cosas distintas y solo
/// una es una decision:
///
/// - los que **eligieron** esta tabla como fuente de datos, y
/// - los que **no configuraron ninguna**, que el runtime lee como "todas las
///   tablas de la empresa" y por lo tanto tambien leen esta.
///
/// Mostrar solo los primeros seria la respuesta comoda y la equivocada. Una
/// empresa leyendo "no esta conectada a ningun canal" mientras un bot sin
/// fuentes dicta sus precios de costo por WhatsApp es exactamente lo que este
/// bloque existe para evitar, asi que los segundos se muestran igual de
/// grandes y con el aviso de por que estan ahi.
///
/// Del catalogo de canales se lleva **solo el nombre y el icono ya resueltos**
/// de cada red y no el proveedor entero: el catalogo se lee una vez y no
/// cambia, asi que esto lo deja de escuchar apenas llego.
class TableChannelsBlock extends StatelessWidget {
  const TableChannelsBlock({super.key, required this.detail});

  final TableDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final channels = detail.channels;

    return SettingsBlock(
      title: S.of(context).table_settings_channels_title,
      subtitle: S.of(context).table_settings_channels_subtitle,
      child: !channels.reached
        ? Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(
                S.of(context).table_settings_channels_none,
                lines: 2,
                color: scheme.text.secondary
              ),
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                S.of(context).table_settings_channels_none_hint,
                lines: 3,
                color: scheme.text.secondary
              )
            ]
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (channels.linked.isNotEmpty) _Group(
                label: S.of(context).table_settings_channels_linked,
                readers: channels.linked
              ),
              if (channels.open.isNotEmpty) ...[
                if (channels.linked.isNotEmpty)
                  SizedBox(height: AppSize.spaceS),
                _Group(
                  label: S.of(context).table_settings_channels_open,
                  hint: S.of(context).table_settings_channels_open_hint,
                  readers: channels.open
                )
              ]
            ]
          )
    );
  }
}

/// Una de las dos listas, con su titulo y —cuando hace falta explicar por que
/// esos bots estan ahi— su linea debajo.
class _Group extends StatelessWidget {
  const _Group({required this.label, required this.readers, this.hint});

  final String label;
  final String? hint;
  final List<TableChannelReader> readers;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextSmall(label, color: scheme.text.secondary),
        if (hint != null) ...[
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(hint!, lines: 4, color: scheme.accent)
        ],
        SizedBox(height: AppSize.gap),
        for (int i = 0; i < readers.length; i++) ...[
          if (i > 0) SizedBox(height: AppSize.gap),
          _ReaderRow(reader: readers[i])
        ]
      ]
    );
  }
}

/// Un bot que lee la tabla: el icono de su red, como se llama, en que estado
/// esta y por que cuenta contesta.
///
/// **Se toca y lleva a su configuracion** (`/home/channels/:id`), que es lo
/// unico que se puede hacer al respecto: desde que canal se lee una tabla se
/// elige del lado del canal, en su fuente de datos.
class _ReaderRow extends StatelessWidget {
  const _ReaderRow({required this.reader});

  final TableChannelReader reader;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, icon) = context
      .select<ChannelCatalogService, (String, IconData)>((catalog) {
        final provider = catalog.byCode(reader.provider);

        // Sin catalogo (todavia cargando, o fallo) se muestra el codigo crudo:
        // "whatsapp" dice menos que "WhatsApp Business" pero mucho mas que un
        // hueco, y la fila no depende de esa lectura para existir.
        return (provider?.name ?? reader.provider, provider?.icon ?? CI.link);
      });

    // Debajo del nombre va por donde contesta el bot: la cuenta que usa y que
    // atiende de ella. Sin ninguna de las dos queda la red, que es lo unico
    // que siempre esta: un renglon en blanco desalinearia la fila contra las
    // demas.
    final subtitle = [
      if (reader.connectionName.isNotEmpty) reader.connectionName,
      if (reader.scopeName.isNotEmpty) reader.scopeName
    ].join(" · ");

    return FeedbackButton(
      action: () => Navis.push(context, "/home/channels/${reader.id}"),
      padding: EdgeInsets.all(AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.spaceS),
      color: scheme.surface,
      message: S.of(context).edit_channel,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppSize.gap * 0.5),
            child: Icon(
              icon,
              size: AppSize.text,
              // Un canal pausado se ve apagado tambien en su icono: es lo
              // primero que se mira de la fila.
              color: reader.enabled ? scheme.icon : scheme.text.secondary
            )
          ),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Flexible(child: TextMedium(
                  reader.name,
                  bold: true,
                  ellipsis: true
                )),
                SizedBox(width: AppSize.gap),
                _ReaderStateTag(reader: reader)
              ]),
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                subtitle.isNotEmpty ? subtitle : label,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          ))
        ]
      )
    );
  }
}

/// En que estado esta el bot, con los mismos tres carteles del listado de
/// canales y por el mismo orden: pausado gana sobre lo demas —si esta apagado
/// no importa que este completo—, despues "falta configurar" y recien si esta
/// entero y encendido, "conectado".
///
/// Importa aca tanto como alla: un bot conectado a esta tabla pero pausado no
/// esta contestando con ella, y uno a medio configurar tampoco.
class _ReaderStateTag extends StatelessWidget {
  const _ReaderStateTag({required this.reader});

  final TableChannelReader reader;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    final (label, color) = switch (reader) {
      TableChannelReader(enabled: false) => (
        S.of(context).channel_state_paused,
        scheme.text.secondary
      ),
      TableChannelReader(ready: false) => (
        // El color de aviso y no un rojo: falta terminarlo, no se rompio nada.
        S.of(context).channel_state_pending,
        scheme.accent
      ),
      _ => (S.of(context).channel_state_ready, scheme.primary)
    };

    return SettingsTag(label: label, color: color);
  }
}
