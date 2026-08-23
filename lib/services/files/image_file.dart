import 'dart:io';
import 'dart:typed_data';

// PACKAGES
import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';

/// Elegir una imagen del disco y dejarla lista para subirla.
///
/// Son dos pasos y no uno porque en el medio pasa lo que de verdad importa: la
/// imagen se recorta antes de viajar (ver `CropImageModal`). Lo que se elige
/// son los bytes originales, lo que se sube son los del recorte, y ninguno de
/// los dos es el archivo que el cliente tiene guardado.

/// Extensiones que se le ofrecen al cliente en el dialogo del sistema.
///
/// Son las que sabe leer el backend: reconoce el formato por los bytes y
/// rechaza todo lo que no este en su lista —SVG incluido, que no es una imagen
/// sino un documento que puede traer script—. Ofrecer aca una que alla se
/// rechaza es dejar elegir un archivo que despues no entra.
const List<String> kImageExtensions = ["jpg", "jpeg", "png", "gif", "webp"];

/// Cuanto pesa como maximo lo que se manda, en bytes. Es el limite del
/// multipart del backend (10 MB): pasarse es un rechazo del otro lado, asi que
/// se avisa antes de subir nada.
///
/// El recorte casi siempre pesa mucho menos que el original, pero se mide el
/// original igual: una foto de 40 MB hay que decodificarla entera en memoria
/// para recortarla, y eso es lo que conviene no intentar.
const int kImageMaxBytes = 10 * 1024 * 1024;

/// Abre el dialogo del sistema filtrado a imagenes y devuelve sus bytes, o
/// `null` si se cerro sin elegir nada.
///
/// [label] es como se llama ese grupo de tipos en el desplegable del dialogo, y
/// llega traducido desde la pantalla: este archivo no tiene contexto con el que
/// traducirlo.
Future<Uint8List?> pickImageBytes({required String label}) async {
  final picked = await openFile(
    acceptedTypeGroups: [
      XTypeGroup(
        label: label,
        extensions: kImageExtensions,
        // Windows filtra por extension, pero macOS e iOS lo hacen por UTI y
        // Android por MIME: sin estos dos el dialogo de esas plataformas
        // dejaria elegir cualquier archivo.
        uniformTypeIdentifiers: const ["public.image"],
        mimeTypes: const [
          "image/jpeg",
          "image/png",
          "image/gif",
          "image/webp"
        ]
      )
    ]
  );

  return picked?.readAsBytes();
}

/// Deja [bytes] en un archivo temporal y lo devuelve.
///
/// Existe porque la subida viaja como multipart y el cliente de multipart pide
/// un archivo, no un bloque de memoria: lo que se sube nacio de un recorte
/// hecho en pantalla y nunca fue un archivo del cliente. Quien lo llama lo
/// borra cuando termina ([discardTempImage]): la carpeta temporal la limpia el
/// sistema, pero no hoy.
Future<File> writeTempImage(Uint8List bytes, {String name = "image"}) async {
  final directory = await getTemporaryDirectory();
  final stamp = DateTime.now().microsecondsSinceEpoch;
  final file = File("${directory.path}${Platform.pathSeparator}${name}_$stamp.png");

  await file.writeAsBytes(bytes, flush: true);

  return file;
}

/// Borra el archivo temporal de una subida. No falla si ya no esta: es
/// limpieza, y no poder limpiar no es un error que valga contarle a nadie.
Future<void> discardTempImage(File file) async {
  try {
    if (await file.exists()) await file.delete();
  } catch (_) {}
}
