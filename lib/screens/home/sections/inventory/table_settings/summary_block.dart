import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';

// WIDGETS
import 'package:app/screens/modals/edit_table_details/_edit_table_details.dart';
import 'package:app/screens/modals/edit_table_details/table_detail_field.dart';

import 'settings_block.dart';
import 'settings_format.dart';
import 'settings_id.dart';

/// La cabecera de los ajustes: de que tabla se trata y que tan grande es.
///
/// Arranca por las tres cifras que se vienen a mirar —cuantos registros,
/// cuantas columnas, cuantos bots la leen— porque son la respuesta al "como
/// esta esta tabla" que trae a alguien a esta pantalla. Los datos que se leen
/// palabra por palabra (la descripcion, el identificador) van debajo.
///
/// **Los registros pueden no saberse.** Las filas viven en otra base que las
/// columnas, asi que la cuenta puede fallar sola: cuando eso pasa la cifra no
/// es cero sino un hueco, y debajo aparece la fila que lo explica. Decir
/// "0 registros" de una tabla llena seria mentir justo donde alguien decide si
/// borrarla.
///
/// Es el unico bloque que se **escribe**. El titulo y la descripcion son los
/// dos datos de la tabla que alguien redacta —el resto lo cuenta el backend, o
/// se decide en otra pantalla— y se corrigen aca, en el renglon donde se leen,
/// con un formulario de un solo campo (ver [EditTableDetailsModal]).
class TableSummaryBlock extends StatelessWidget {
  const TableSummaryBlock({super.key, required this.detail});

  final TableDetailModel detail;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final records = detail.records;

    // Cuantos bots llegan a la tabla, por el camino que sea: los que la
    // eligieron y los que la leen por no haber elegido ninguna. Es la misma
    // cuenta que explica el bloque de canales, que es donde se desglosa.
    final readers = detail.channels.linked.length + detail.channels.open.length;

    return SettingsBlock(
      title: S.of(context).table_settings_summary_title,
      subtitle: S.of(context).table_settings_summary_subtitle,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: SettingsStat(
              icon: CI.list,
              // El hueco es un dato: ver la nota de la clase.
              value: records == null
                ? "—"
                : settingsNumber(context, records),
              label: S.of(context).table_settings_stat_records
            )),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: SettingsStat(
              icon: CI.documents,
              value: settingsNumber(context, detail.columns.total),
              label: S.of(context).table_settings_stat_columns
            )),
            SizedBox(width: AppSize.spaceXS),
            Expanded(child: SettingsStat(
              icon: CI.ia,
              value: settingsNumber(context, readers),
              label: S.of(context).table_settings_stat_channels,
              // Pintado solo cuando hay alguno: un cero en color de marca se
              // leeria como un estado y no como la ausencia de uno.
              tint: readers > 0 ? scheme.primary : null
            ))
          ]),
          SizedBox(height: AppSize.spaceS),
          SettingsList(rows: [
            if (records == null) SettingsRow(
              icon: CI.info,
              label: S.of(context).table_settings_stat_records,
              hint: S.of(context).table_settings_records_unknown_hint,
              child: TextMedium(
                S.of(context).table_settings_unknown,
                color: scheme.text.secondary
              )
            ),
            // El titulo va primero porque es de lo que habla todo lo demas:
            // hasta ahora la tabla solo se nombraba en la barra de arriba, que
            // es donde se lee y no donde se corrige.
            SettingsValue(
              icon: CI.list,
              label: S.of(context).table_settings_name,
              value: detail.name,
              hint: S.of(context).table_settings_name_hint,
              action: _edit(context, TableDetailField.title, detail.name)
            ),
            SettingsValue(
              icon: CI.pen,
              label: S.of(context).table_settings_description,
              value: detail.description,
              empty: S.of(context).table_settings_description_empty,
              action: _edit(
                context,
                TableDetailField.description,
                detail.description
              )
            ),
            // El identificador no se escribe ni se lee de corrido: se destapa,
            // se copia y se pega afuera. Por eso va en su propia caja con lo
            // que se hace con el (ver [TableSettingsId]) y no como un renglon
            // mas.
            SettingsRow(
              icon: CI.key,
              label: S.of(context).table_settings_id,
              hint: S.of(context).table_settings_id_hint,
              child: TableSettingsId(id: detail.id)
            )
          ])
        ]
      )
    );
  }

  /// El boton que corrige un dato escrito, o que lo carga si no esta.
  ///
  /// Sobre una fila vacia el lapiz miente —no hay nada que corregir— asi que
  /// es la misma accion con el nombre y el icono de lo que de verdad va a
  /// pasar. Es lo mismo que hace la ficha de la empresa, por lo mismo.
  ///
  /// El servicio se le pasa al modal por constructor: lo provee esta pagina y
  /// un dialogo se monta arriba del `Navigator`, donde ese provider ya no
  /// esta. Lo que se guarde no vuelve por aca —el servicio ya repinto la
  /// ficha—, asi que no hay nada que hacer al cerrarse.
  Widget _edit(BuildContext context, TableDetailField field, String value) {
    final label = field.label(context);
    final blank = value.trim().isEmpty;

    return SettingsAction(
      icon: blank ? CI.plus : CI.edit,
      message: blank
        ? S.of(context).table_settings_add(label)
        : S.of(context).table_settings_edit(label),
      action: () => showModal(
        context: context,
        title: blank
          ? S.of(context).table_settings_add(label)
          : S.of(context).table_settings_edit(label),
        builder: (_) => EditTableDetailsModal(
          field: field,
          service: context.read<TableDetailService>()
        )
      )
    );
  }
}

/// Las dos fechas de la tabla y la de su ultimo dato.
///
/// **Son dos cosas distintas y por eso son dos filas.** `updated` es el ultimo
/// cambio de estructura —la tabla o cualquiera de sus columnas—, y el ultimo
/// registro es cuando entro el ultimo dato. Una lista de precios importada en
/// marzo y recargada esta manana tiene la primera vieja y la segunda de hoy:
/// juntarlas en una sola fecha perderia justo la que se estuviera preguntando.
class TableDatesBlock extends StatelessWidget {
  const TableDatesBlock({super.key, required this.detail});

  final TableDetailModel detail;

  @override
  Widget build(BuildContext context) => SettingsBlock(
    title: S.of(context).table_settings_dates_title,
    subtitle: S.of(context).table_settings_dates_subtitle,
    child: SettingsList(rows: [
      SettingsValue(
        icon: CI.calendar,
        label: S.of(context).table_settings_created,
        value: settingsDate(context, detail.date),
        empty: S.of(context).table_settings_unknown
      ),
      SettingsValue(
        icon: CI.edit,
        label: S.of(context).table_settings_updated,
        value: settingsDate(context, detail.updated),
        hint: S.of(context).table_settings_updated_hint,
        empty: S.of(context).table_settings_unknown
      ),
      SettingsValue(
        icon: CI.save,
        label: S.of(context).table_settings_last_record,
        value: settingsDate(context, detail.lastRecord),
        hint: S.of(context).table_settings_last_record_hint,
        // Una tabla sin filas no tiene una fecha desconocida: no tiene fecha,
        // y son dos cosas que se contestan distinto.
        empty: detail.records == null
          ? S.of(context).table_settings_unknown
          : S.of(context).table_settings_no_records
      )
    ])
  );
}
