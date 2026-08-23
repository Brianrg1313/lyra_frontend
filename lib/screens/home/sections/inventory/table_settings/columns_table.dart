import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/table_field_options.dart';
import 'package:app/services/inventory/table_field_type.dart';
import 'package:app/services/stock/tables/table_detail_model.dart';
import 'package:app/services/stock/tables/table_detail_service.dart';

// WIDGETS
import 'package:core/form.dart';

import 'settings_block.dart';

/// Las columnas de la tabla, una por fila: con que se la reconoce, como se
/// llama, de que tipo es, cuanto ve de ella el modelo y —si es una lista— que
/// opciones ofrece.
///
/// Es una tabla y no una lista de fichas porque las columnas se leen
/// **comparandolas**: la pregunta que se contesta aca no es "que es la columna
/// Precio" sino "cuales de las veinte estan sin tipar" y "cual es la que el bot
/// no deberia estar diciendo". Puestas en columna, cada tipo y cada visibilidad
/// quedan uno debajo del otro y eso se ve de un vistazo; repartidos en
/// etiquetas dentro de cada ficha, hay que leer las veinte.
///
/// Y ademas se **edita** desde aca, que es lo que la hace una tabla y no un
/// informe: los tres datos que se comparan son los tres que se corrigen, y se
/// corrigen en el mismo renglon donde se los leyo. Cada eleccion se guarda sola
/// (ver [TableDetailService.editField]); no hay boton de guardar porque no hay
/// un formulario.
///
/// **En angosto la fila se parte en dos renglones** en vez de encoger las
/// celdas: la ficha se abre en dos columnas apenas la pantalla da, asi que esta
/// mitad puede medir poco mas de trescientos pixeles, y cinco celdas ahi dentro
/// dejan cada desplegable sin lugar ni para su etiqueta. Partida, el nombre se
/// lee entero arriba y los tres desplegables comparten el ancho abajo.
class TableColumnsTable extends StatelessWidget {
  const TableColumnsTable({super.key, required this.fields});

  final List<TableDetailFieldModel> fields;

  /// Ancho a partir del cual las cinco celdas entran en una fila.
  ///
  /// Es lo que mide la fila con cada desplegable en su ancho minimo util —el
  /// del tipo mas largo de la lista— mas el nombre de la columna. Por debajo,
  /// [_FieldRow] se parte en dos renglones.
  static double get _wide => AppSize.action * 11;

  /// Cuanto ocupa cada celda cuando entran todas en la fila.
  ///
  /// El nombre se lleva mas que los desplegables porque es lo unico de la fila
  /// que no se puede acortar: un tipo o una visibilidad son dos palabras
  /// conocidas, y el titulo de una columna importada de una planilla puede ser
  /// cualquier cosa.
  static const int _nameFlex = 4;
  static const int _cellFlex = 3;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      // Sin ancho medido se dibuja partida, que es la que se lee en cualquier
      // ancho.
      final wide = constraints.maxWidth.isFinite &&
        constraints.maxWidth >= _wide;

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // La cabecera solo tiene sentido sobre celdas alineadas: partida, no
          // encabeza nada.
          if (wide) ...[
            const _Head(),
            SizedBox(height: AppSize.gap)
          ],
          for (int i = 0; i < fields.length; i++) ...[
            if (i > 0) Separator.horizontal(
              margin: EdgeInsets.symmetric(vertical: AppSize.spaceXS)
            ),
            _FieldRow(field: fields[i], wide: wide)
          ]
        ]
      );
    }
  );
}

/// Que es cada celda de la fila.
///
/// Sobre la celda del icono no va nada: es el tipo dibujado, y ya lo dice la
/// celda que sigue.
class _Head extends StatelessWidget {
  const _Head();

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    Widget cell(int flex, String label) => Expanded(
      flex: flex,
      child: TextSmall(label, ellipsis: true, color: scheme.text.secondary)
    );

    return Row(children: [
      SizedBox(width: AppSize.button),
      SizedBox(width: AppSize.spaceXS),
      cell(
        TableColumnsTable._nameFlex,
        S.of(context).table_settings_column_field
      ),
      SizedBox(width: AppSize.gap),
      cell(
        TableColumnsTable._cellFlex,
        S.of(context).table_settings_column_type
      ),
      SizedBox(width: AppSize.gap),
      cell(
        TableColumnsTable._cellFlex,
        S.of(context).table_settings_column_visibility
      ),
      SizedBox(width: AppSize.gap),
      cell(
        TableColumnsTable._cellFlex,
        S.of(context).table_settings_column_options
      )
    ]);
  }
}

/// Una columna de la tabla: su icono, su nombre y sus tres desplegables.
///
/// Los tres se guardan solos al elegir y ninguno pregunta nada: son cambios de
/// una tabla que ya existe y todos tienen vuelta atras eligiendo el valor
/// anterior. El unico que ademas toca lo que hay cargado es el tipo, y eso lo
/// resuelve el backend reescribiendo la columna (ver `PUT /tables/fields/`).
class _FieldRow extends StatelessWidget {
  const _FieldRow({required this.field, required this.wide});

  final TableDetailFieldModel field;

  /// Si las cinco celdas entran en una fila. Ver la nota de
  /// [TableColumnsTable].
  final bool wide;

  @override
  Widget build(BuildContext context) {
    if (wide) {
      return Row(
        // Al medio y no arriba: una columna con descripcion mide dos renglones,
        // y sus desplegables colgados del primero se leerian como si fueran de
        // otra fila.
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          _TypeIcon(type: field.type),
          SizedBox(width: AppSize.spaceXS),
          Expanded(
            flex: TableColumnsTable._nameFlex,
            child: _Name(field: field)
          ),
          SizedBox(width: AppSize.gap),
          ..._cells(context)
        ]
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          _TypeIcon(type: field.type),
          SizedBox(width: AppSize.spaceXS),
          Expanded(child: _Name(field: field))
        ]),
        SizedBox(height: AppSize.gap),
        Row(children: _cells(context))
      ]
    );
  }

  /// Los tres desplegables, que son los mismos en los dos anchos: lo unico que
  /// cambia es si van al lado del nombre o debajo.
  List<Widget> _cells(BuildContext context) => [
    Expanded(
      flex: TableColumnsTable._cellFlex,
      child: SettingsSelect(
        label: field.type.label(context),
        message: S.of(context).table_settings_pick_type,
        open: _pickType
      )
    ),
    SizedBox(width: AppSize.gap),
    Expanded(
      flex: TableColumnsTable._cellFlex,
      child: SettingsSelect(
        icon: field.visibility.icon,
        label: field.visibility.label(context),
        color: _visibilityColor(context, field.visibility),
        message: S.of(context).table_settings_pick_visibility,
        open: _pickVisibility
      )
    ),
    SizedBox(width: AppSize.gap),
    Expanded(
      flex: TableColumnsTable._cellFlex,
      child: _Options(field: field)
    )
  ];

  /// Abre la lista de tipos, anclada al desplegable.
  ///
  /// Es la misma de la planilla ([TableFieldType.options]) y con buscador por lo
  /// mismo: son diecisiete, y con la lista abierta elegir pasa a ser escribir
  /// tres letras en vez de recorrerlos. Elegir el que ya tenia no manda nada.
  Future<void> _pickType(BuildContext anchor) async {
    final picked = await showSelectMenu(
      context: anchor,
      options: TableFieldType.options(anchor),
      selected: field.type.value,
      searchPlaceholder: S.of(anchor).table_field_type_placeholder,
      emptyText: S.of(anchor).table_field_type_empty,
      maxOptions: 4
    );

    if (picked == null || !anchor.mounted) return;

    final type = TableFieldType.from(picked.value);
    if (type == field.type) return;

    await anchor
      .read<TableDetailService>()
      .editField(anchor, field, type: type);
  }

  /// Abre los tres estados de visibilidad, anclados al desplegable.
  ///
  /// Cada uno va con su explicacion debajo ([TableFieldVisibility.hint]) y no
  /// solo con su nombre: los tres se llaman parecido, y el del medio —el que
  /// deja al modelo filtrar por una columna sin poder decir lo que vale— no lo
  /// adivina nadie leyendo "declarada". Sin buscador: son tres.
  Future<void> _pickVisibility(BuildContext anchor) async {
    final picked = await showSelectMenu(
      context: anchor,
      options: [
        for (final state in TableFieldVisibility.values) SelectOption(
          value: state.value,
          placeholder: state.label(anchor),
          subtitle: state.hint(anchor),
          icon: state.icon
        )
      ],
      selected: field.visibility.value,
      maxOptions: 3
    );

    if (picked == null || !anchor.mounted) return;

    final visibility = TableFieldVisibility.from(picked.value);
    if (visibility == field.visibility) return;

    await anchor
      .read<TableDetailService>()
      .editField(anchor, field, visibility: visibility);
  }
}

/// El tipo de la columna dibujado, en la misma caja que en la planilla.
class _TypeIcon extends StatelessWidget {
  const _TypeIcon({required this.type});

  final TableFieldType type;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      width: AppSize.button,
      height: AppSize.button,
      color: scheme.surface,
      radius: AppSize.cornerInset(AppSize.spaceXS),
      child: Center(child: Icon(
        type.icon,
        size: AppSize.text,
        color: scheme.icon
      ))
    );
  }
}

/// Como se llama la columna y, si la tiene, para que sirve.
///
/// El numero es el lugar que ocupa en la planilla, y va porque la lista esta en
/// ese orden: es lo que deja cruzar esta fila con la columna que se estaba
/// mirando alla sin tener que contar.
///
/// La descripcion solo se dibuja si esta: casi ninguna columna importada de una
/// planilla tiene, y el renglon vacio en todas haria la tabla el doble de larga
/// sin decir nada.
class _Name extends StatelessWidget {
  const _Name({required this.field});

  final TableDetailFieldModel field;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(children: [
          Flexible(child: TextMedium(field.name, bold: true, ellipsis: true)),
          SizedBox(width: AppSize.gap),
          TextSmall("${field.position + 1}", color: scheme.text.secondary)
        ]),
        if (field.description.isNotEmpty) ...[
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(
            field.description,
            lines: 2,
            ellipsis: true,
            color: scheme.text.secondary
          )
        ]
      ]
    );
  }
}

/// Las opciones de la columna, cuando es una lista.
///
/// En cualquier otro tipo la celda queda con un guion y no con un desplegable
/// apagado: las opciones no son un dato que ese campo tenga vacio, es un dato
/// que no existe para el.
///
/// El desplegable muestra las que hay y, pegada abajo, la fila para agregar una
/// (ver [showSelectMenu]): es donde se arma la lista sin tener que ir a la
/// planilla a buscar una celda de esa columna. Elegir una de las que ya estan no
/// hace nada —aca la lista es el dato, no un valor que se este eligiendo—, asi
/// que lo que devuelve el desplegable se descarta.
class _Options extends StatelessWidget {
  const _Options({required this.field});

  final TableDetailFieldModel field;

  /// Cuantas opciones tiene que tener la lista para que el desplegable traiga
  /// buscador. Con pocas, el buscador es una fila de mas entre el boton y lo
  /// que se quiere tocar.
  static const int _searchFrom = 6;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    if (field.type != TableFieldType.select) {
      return SizedBox();
    }

    final empty = field.options.isEmpty;

    return SettingsSelect(
      label: empty
        ? S.of(context).table_settings_options_empty
        : S.of(context).table_settings_options(field.options.length),
      color: empty ? scheme.text.secondary : null,
      message: S.of(context).table_settings_pick_options,
      open: _open
    );
  }

  Future<void> _open(BuildContext anchor) => showSelectMenu(
    context: anchor,
    options: [
      for (final option in field.options)
        SelectOption(value: option, placeholder: option)
    ],
    searchPlaceholder: field.options.length > _searchFrom
      ? S.of(anchor).table_field_option_search
      : null,
    emptyText: S.of(anchor).table_settings_options_empty,
    createText: S.of(anchor).table_field_option_create,
    createPlaceholder: S.of(anchor).table_field_option_placeholder,
    onCreate: (name) => _create(anchor, name)
  );

  /// Agrega una opcion a la lista desde el propio desplegable.
  ///
  /// Una opcion es una propiedad de la columna, asi que se guarda como se
  /// guarda cualquier otra: mandando la lista que tiene que quedar. Escribir una
  /// que ya estaba no crea nada ni falla —se devuelve la que hay, que es lo que
  /// quiso decir quien la escribio— y dos que solo se distinguen en mayusculas o
  /// tildes son la misma ([sameFieldOption]), porque serian indistinguibles al
  /// elegirlas.
  ///
  /// Devuelve `null` si no se pudo guardar; el error ya lo mostro el servicio y
  /// la fila del desplegable queda abierta con lo escrito para reintentar.
  Future<SelectOption?> _create(BuildContext context, String name) async {
    final existing = fieldOptionLike(field.options, name);
    if (existing != null) {
      return SelectOption(value: existing, placeholder: existing);
    }

    final options = fieldOptionsWith(field.options, name);
    if (options == null) return null;

    final saved = await context
      .read<TableDetailService>()
      .editField(context, field, options: options);

    if (!saved) return null;

    final created = name.trim();
    return SelectOption(value: created, placeholder: created);
  }
}

/// El color de un estado de visibilidad.
///
/// Son los tres estados leidos como lo que significan para quien mira la tabla:
/// el de marca cuando el agente puede citar el dato, el de aviso cuando lo usa
/// sin decirlo —que es el que hay que poder distinguir de un vistazo, porque es
/// donde vive el precio de costo— y gris cuando ni siquiera sabe que la columna
/// existe.
Color _visibilityColor(BuildContext context, TableFieldVisibility visibility) {
  final scheme = ThemeColor.of(context);

  return switch (visibility) {
    TableFieldVisibility.visible => scheme.primary,
    TableFieldVisibility.declared => scheme.accent,
    TableFieldVisibility.hidden => scheme.text.secondary
  };
}
