import 'dart:io';

import 'package:file_selector/file_selector.dart';

/// Como lee el backend el archivo que se sube para armar una tabla.
///
/// No es el formato del archivo sino **con que parser lo abre el backend**, y
/// por eso son dos y no uno por extension: `POST /tables/import/.../excel/` y
/// `POST /tables/import/.../csv/`. La rama de Excel abre cualquier planilla
/// (xlsx, xls, ods, ...); la de CSV es texto separado por comas o punto y coma.
enum ImportFormat {
  excel("excel"),
  csv("csv");

  const ImportFormat(this.segment);

  /// El tramo de la ruta del endpoint que corresponde a este formato.
  final String segment;
}

/// Extensiones que se le ofrecen al usuario en el dialogo del sistema, y las
/// unicas que [importFormatOf] reconoce.
///
/// Son las que sabe leer el backend: la rama de Excel usa una libreria que abre
/// toda la familia de planillas —no solo `.xlsx`—, asi que se listan todas en
/// vez de obligar a exportar a un formato en particular. Sin punto: es como las
/// pide el dialogo del sistema.
const List<String> kImportExtensions = [
  "xlsx",
  "xlsm",
  "xlsb",
  "xls",
  "ods",
  "csv"
];

/// Con que parser hay que abrir [path], o `null` si su extension no es una
/// planilla ni un CSV.
///
/// Se decide por la extension y no por el contenido porque es lo que decide la
/// ruta a la que se sube, y es tambien lo unico que se sabe antes de leer el
/// archivo. Nunca deberia dar `null` viniendo del dialogo (que ya filtra), pero
/// se comprueba igual: en Linux y macOS el usuario puede escribir el nombre a
/// mano y saltearse el filtro.
ImportFormat? importFormatOf(String path) {
  final name = _fileName(path);
  final dot = name.lastIndexOf(".");

  if (dot <= 0 || dot == name.length - 1) return null;

  final extension = name.substring(dot + 1).toLowerCase();

  if (!kImportExtensions.contains(extension)) return null;

  return extension == "csv" ? ImportFormat.csv : ImportFormat.excel;
}

/// El nombre con el que nace la tabla importada: el del archivo, sin extension.
///
/// Se manda desde aca y no se deja que lo deduzca el backend porque del otro
/// lado el nombre del archivo llega como lo arme el multipart, y una ruta de
/// Windows entera quedaria de titulo. Devuelve vacio si no queda nada usable, y
/// en ese caso el backend pone el suyo por defecto.
String importTableName(String path) {
  final name = _fileName(path);
  final dot = name.lastIndexOf(".");

  // Un nombre que arranca con punto (`.csv`) es todo extension: no queda nada
  // de titulo, y por eso se corta en `dot >= 0` y no en `dot > 0`.
  return (dot < 0 ? name : name.substring(0, dot)).trim();
}

/// El ultimo tramo de una ruta, con cualquiera de los dos separadores: el
/// dialogo devuelve rutas del sistema y en Windows vienen con "\\".
String _fileName(String path) {
  final slash = path.lastIndexOf("/");
  final backslash = path.lastIndexOf("\\");
  final cut = slash > backslash ? slash : backslash;

  return cut < 0 ? path : path.substring(cut + 1);
}

/// Abre el dialogo del sistema para elegir la planilla a importar, filtrado a
/// [kImportExtensions]: los demas archivos no se pueden ni seleccionar.
///
/// [label] es como se llama ese grupo de tipos en el desplegable del dialogo
/// ("Planillas y CSV"), y llega traducido desde la pantalla porque este archivo
/// no tiene contexto con el que traducirlo.
///
/// Devuelve `null` si se cerro el dialogo sin elegir nada.
Future<File?> pickImportFile({required String label}) async {
  final picked = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: label,
        extensions: kImportExtensions,
        // Windows filtra por extension, pero macOS e iOS lo hacen por UTI y
        // Android por MIME: sin estos dos el dialogo de esas plataformas no
        // filtraria nada y dejaria elegir cualquier archivo.
        uniformTypeIdentifiers: const [
          "org.openxmlformats.spreadsheetml.sheet",
          "com.microsoft.excel.xls",
          "org.oasis-open.opendocument.spreadsheet",
          "public.comma-separated-values-text"
        ],
        mimeTypes: const [
          "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
          "application/vnd.ms-excel",
          "application/vnd.oasis.opendocument.spreadsheet",
          "text/csv"
        ]
      )
    ]
  );

  return picked == null ? null : File(picked.path);
}
