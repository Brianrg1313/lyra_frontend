/// Cuerpos de las escrituras de un **registro** (una fila) de una tabla de
/// productos: el alta (`POST /v1/products/manage/`) y la edicion
/// (`PUT /v1/products/manage/`).
///
/// Viven aparte de la pantalla por el mismo motivo que los de las columnas (ver
/// `table_field_request.dart`): son el contrato con el backend, lo que se arma
/// aca es lo que se documenta del otro lado, y asi se puede probar sin montar la
/// planilla.
///
/// La empresa dueña no va en el cuerpo: viaja en la cabecera `business_id` de
/// todas las peticiones (ver `useBusiness` en `toolkit/api.dart`).
///
/// `DATA` esta indexado por FIELD_ID y **solo lleva lo que se toca**: la
/// planilla edita de a una celda, asi que mandar la fila entera reescribiria
/// campos que nadie miro (y pisaria lo que otro haya cargado en ellos mientras
/// tanto).
///
/// Forma del alta:
///
/// ```json
/// {
///   "TABLE_ID": "a1b2c3",
///   "DATA": {"d4e5f6": "Yerba 1kg", "a7b8c9": "22.50"}
/// }
/// ```
///
/// Forma de la edicion:
///
/// ```json
/// {
///   "TABLE_ID": "a1b2c3",
///   "ID": "r1s2t3",
///   "DATA": {"a7b8c9": "24.90"}
/// }
/// ```
library;

/// Arma el cuerpo del alta de un registro.
Map<String, dynamic> createRecordRequest({
  required String tableId,
  required Map<String, dynamic> values
}) => {"TABLE_ID": tableId, "DATA": values};

/// Arma el cuerpo de la edicion de un registro.
///
/// [id] es el identificador del registro, el que viene en la primera columna de
/// la pagina de datos y que la planilla no muestra. Sin el no hay edicion
/// posible: es lo unico que dice a que fila de la tabla se le esta escribiendo.
Map<String, dynamic> editRecordRequest({
  required String tableId,
  required String id,
  required Map<String, dynamic> values
}) => {"TABLE_ID": tableId, "ID": id, "DATA": values};
