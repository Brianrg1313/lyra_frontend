import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_model.dart';

import 'columns_table.dart';
import 'settings_block.dart';

/// Las columnas de la tabla: cuantas hay de cada clase y despues una por una.
///
/// Arriba va el resumen por tipo —de que esta hecha la tabla— y debajo la lista
/// completa, en el mismo orden en que se ven en la planilla. Es lo que permite
/// contestar las dos preguntas que se hacen aca: "esta tabla tiene precios?" se
/// contesta con el resumen y "que tiene la tercera columna?" con la lista.
///
/// La lista es una tabla y no una hilera de fichas, y ademas se edita: el tipo,
/// la visibilidad y las opciones de cada columna se cambian en su propio
/// renglon (ver [TableColumnsTable]). El resumen de arriba no: son cuentas, y
/// se corrigen solas cuando se corrige la columna que las mueve.
///
/// **Las columnas de texto pelado se avisan.** Toda columna importada de una
/// planilla nace como texto, y una tabla que quedo entera asi guarda datos sin
/// que nadie —ni la IA— pueda compararlos, filtrarlos ni cotizarlos. No es un
/// error y por eso el aviso no es rojo: es lo que falta hacer, y se hace en la
/// misma pantalla.
class TableColumnsBlock extends StatelessWidget {
  const TableColumnsBlock({super.key, required this.detail});

  final TableDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final types = detail.columns.sorted;

    return SettingsBlock(
      title: S.of(context).table_settings_columns_title,
      subtitle: S.of(context).table_settings_columns_subtitle,
      child: detail.fields.isEmpty && types.isEmpty
        // Una tabla recien creada todavia no tiene columnas: se escriben en la
        // planilla, no aca, asi que este bloque solo lo dice.
        ? TextMedium(
            S.of(context).table_settings_columns_empty,
            lines: 2,
            color: scheme.text.secondary
          )
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (types.isNotEmpty) ...[
                TextSmall(
                  S.of(context).table_settings_types,
                  color: scheme.text.secondary
                ),
                SizedBox(height: AppSize.gap),
                Wrap(
                  spacing: AppSize.gap,
                  runSpacing: AppSize.gap,
                  children: [
                    for (final entry in types) SettingsTag(
                      icon: entry.key.icon,
                      label: S.of(context).table_settings_type_count(
                        entry.key.label(context),
                        entry.value
                      ),
                      color: scheme.text.secondary
                    )
                  ]
                ),
                SizedBox(height: AppSize.spaceS)
              ],
              if (detail.columns.untyped > 0) ...[
                _UntypedNotice(count: detail.columns.untyped),
                SizedBox(height: AppSize.spaceS)
              ],
              TableColumnsTable(fields: detail.fields)
            ]
          )
    );
  }
}

/// Cuantas columnas siguen siendo texto pelado, y por que importa.
///
/// Va en el color de marca y no en rojo: no se rompio nada, falta terminar de
/// tipar la tabla. Es el mismo criterio con el que un canal sin credenciales
/// dice "falta configurar" en vez de dar error.
class _UntypedNotice extends StatelessWidget {
  const _UntypedNotice({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      padding: EdgeInsets.all(AppSize.spaceXS),
      color: scheme.accent.withValues(alpha: 0.1),
      radius: AppSize.cornerInset(AppSize.spaceS),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(top: AppSize.gap * 0.5),
            child: Icon(CI.info, size: AppSize.text, color: scheme.accent)
          ),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextMedium(
                S.of(context).table_settings_untyped(count),
                lines: 2,
                color: scheme.accent
              ),
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                S.of(context).table_settings_untyped_hint,
                lines: 4,
                color: scheme.text.secondary
              )
            ]
          ))
        ]
      )
    );
  }
}
