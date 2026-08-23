/// El orden en que el usuario dejo las columnas, y la aritmetica de arrastrarlas
/// de lugar.
///
/// Vive aparte y es puro por el mismo motivo que la geometria de la planilla
/// (`SheetMetrics`): no depende de nada del arbol de widgets ni de la red, asi
/// que se prueba solo.
///
/// El orden se guarda como una lista de FIELD_ID y no de posiciones, y esa es
/// toda la gracia: una lista de posiciones se rompe con cualquier cambio de la
/// estructura —una columna que se crea, otra que se elimina, la que el backend
/// devuelve en otro lugar— y una de ids sigue valiendo igual. Por eso el orden
/// que eligio el usuario sobrevive a que la tabla se relea entera.
library;

import 'package:app/services/stock/tables/table_structure_model.dart';

/// Los campos de [fields] puestos en el orden de [order] (FIELD_IDs).
///
/// Lo que manda es [order]. Un campo que no este ahi —uno recien creado, o uno
/// que agrego otro cliente— va al final, en el orden en que lo trajo la
/// estructura: es el mismo lugar donde nace una columna nueva, asi que no se
/// mueve nada de lugar por haberla creado.
///
/// Con [order] vacio no hay nada que reordenar y se devuelve **la misma lista**,
/// sin copiarla: es lo que pasa mientras el usuario no arrastro ninguna columna,
/// que es casi siempre.
///
/// Un campo sin FIELD_ID no se puede emparejar con nada, asi que tampoco se
/// ordena: queda al final junto con los que no estaban en [order]. Por eso
/// `SheetColumns` no deja arrastrar en una tabla que tenga alguno.
List<TableFieldModel> fieldsInOrder(
  List<TableFieldModel> fields,
  List<String> order
) {
  if (order.isEmpty || fields.length < 2) return fields;

  final rank = <String, int>{};
  for (final (index, id) in order.indexed) {
    if (id.isNotEmpty) rank[id] = index;
  }

  final known = <TableFieldModel>[];
  final rest = <TableFieldModel>[];

  for (final field in fields) {
    (rank.containsKey(field.id) ? known : rest).add(field);
  }

  if (known.length < 2) return fields;

  known.sort((a, b) => rank[a.id]!.compareTo(rank[b.id]!));

  return [...known, ...rest];
}

/// De que lugar de la fila sale el valor de cada columna de la planilla.
///
/// [fields] son los campos como los da la estructura —que es contra lo que estan
/// alineados los registros leidos— y [ordered] los mismos, en el orden en que se
/// los ve. Detras van [free] columnas libres, que todavia no son campos: no
/// tienen donde guardar, pero lo que se escriba en ellas necesita un lugar
/// propio en el borrador de la fila, y se les da el que les tocaria si se
/// crearan (detras de todos los campos, que es donde nacen).
///
/// Esto es lo que hace que arrastrar una columna no cueste nada: lo unico que
/// cambia de lugar es un `int` por columna, y ni un registro se toca.
List<int> slotsOf(
  List<TableFieldModel> fields,
  List<TableFieldModel> ordered, {
  required int free
}) {
  final place = {for (final (index, field) in fields.indexed) field: index};

  return [
    for (final field in ordered) place[field] ?? 0,
    for (int index = 0; index < free; index++) fields.length + index
  ];
}

/// El orden que queda al llevar la columna [from] hasta el borde [to].
///
/// [to] es un **borde** y no una columna: `0` es delante de la primera y
/// `order.length` es detras de la ultima. Se lee asi porque es exactamente lo
/// que marca la linea mientras se arrastra —cae *entre* dos columnas, no
/// *sobre* una— y por eso soltar en el borde izquierdo de la propia columna, o
/// en el derecho, no la mueve.
///
/// Devuelve **la misma lista** cuando no hay nada que mover, para que quien
/// llama pueda saberlo comparando identidades y no gastar un repintado.
List<String> movedOrder(
  List<String> order, {
  required int from,
  required int to
}) {
  if (from < 0 || from >= order.length) return order;
  if (to < 0 || to > order.length) return order;

  // Soltarla donde ya estaba: los dos bordes que la rodean la dejan igual.
  if (to == from || to == from + 1) return order;

  final moved = [...order];
  final id = moved.removeAt(from);

  // Sacarla corrio un lugar todo lo que tenia detras, incluido el borde donde
  // se la quiere dejar.
  moved.insert(to > from ? to - 1 : to, id);

  return moved;
}

/// El borde donde caeria una columna que se suelta en [x].
///
/// [edges] son los bordes izquierdos de cada columna mas el final de la ultima
/// (un valor mas que columnas hay), y solo se miran las primeras [columns]:
/// detras estan las libres del final, que todavia no son campos de la tabla y
/// no reciben nada.
///
/// Se compara contra el **medio** de cada columna y no contra su borde, que es
/// lo que hace que la linea salte cuando la columna arrastrada ya tapo mas de
/// media vecina en vez de en cuanto la roza.
int dropEdgeAt(List<double> edges, double x, {required int columns}) {
  final last = columns < edges.length - 1 ? columns : edges.length - 1;

  for (int index = 0; index < last; index++) {
    if (x < (edges[index] + edges[index + 1]) / 2) return index;
  }

  return last < 0 ? 0 : last;
}
