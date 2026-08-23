import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/files/file_model.dart';
import 'package:app/toolkit/api.dart';

/// De donde se bajan las imagenes.
///
/// Ninguna respuesta de esta api trae una direccion de imagen: trae **ids** (ver
/// [FileModel]). Las direcciones se arman con las dos bases que `/init` entrega
/// una sola vez, en `cdn`: [media] para lo que subio una empresa y [assets] para
/// lo que es de la plataforma. Una direccion es `<base>/<id>`, y una miniatura
/// `<base>/<id>@<ancho>`.
///
/// Que la direccion sea configuracion y no un valor guardado es lo que deja
/// mudar los archivos —a un CDN, a otro dominio, a otro proveedor— sin tocar la
/// app ni las filas que los referencian: cambia una variable del backend y el
/// proximo `/init` ya reparte la base nueva. Por eso esto es un servicio y no
/// una constante de esta app.
///
/// Es singleton y se registra en `initialBuilder` con
/// `ChangeNotifierProvider.value`, como los catalogos: lo puebla
/// [ClientService.resolve] antes de levantar el arbol, asi que para cuando el
/// primer logo se dibuja la base ya esta.
///
/// ```dart
/// // Desde el archivo, que es lo normal.
/// Image.network(business.logo!.thumbnail);
///
/// // Con un id suelto (una bandera del catalogo de paises).
/// CdnService().url(FileScope.assets, country.flag);
/// ```
class CdnService extends ChangeNotifier {
  //SINGLETON
  static final CdnService _singleton = CdnService._internal();

  factory CdnService() => _singleton;

  CdnService._internal();

  String _media = "";
  String _assets = "";

  /// Base de los archivos de una empresa (`.../rigel/media`).
  String get media => _media;

  /// Base de los archivos de la plataforma (`.../rigel/assets`).
  String get assets => _assets;

  /// Si ya hay con que armar direcciones. Sin esto ninguna imagen se puede
  /// bajar, pero tampoco es un error: se dibuja lo que se dibuja cuando una
  /// empresa no subio logo.
  bool get isReady => _media.isNotEmpty && _assets.isNotEmpty;

  /// La base de un espacio, o `""` si todavia no llego.
  String base(FileScope scope) => scope == FileScope.assets ? _assets : _media;

  /// La direccion de un archivo, o `""` si no hay base o no hay id.
  ///
  /// [width] pide una miniatura. Un ancho que ese archivo no tenga no falla —el
  /// backend devuelve la grande—, pero se pide el que existe: el archivo dice
  /// cuales tiene ([FileModel.variants]).
  String url(FileScope scope, String? id, {int? width}) {
    final file = id?.trim() ?? "";
    final root = base(scope);

    if (file.isEmpty || root.isEmpty) return "";

    return width == null ? "$root/$file" : "$root/$file@$width";
  }

  /// Guarda las bases que trajo `/init`.
  ///
  /// El backend puede mandarlas relativas (`/rigel/media`), que es lo correcto
  /// para un frontend servido desde su mismo host y lo que devuelve cuando no
  /// hay CDN configurado. Aca eso no alcanza —esto no corre en una pagina, no
  /// hay contra que resolverlas—, asi que se completan con el origen de la api,
  /// que es de donde salieron.
  void seed(dynamic data) {
    if (data is! Map) return;

    _media = _absolute(data["media"]);
    _assets = _absolute(data["assets"]);

    notifyListeners();
  }

  /// Una base como se la puede usar: absoluta y sin barra final.
  static String _absolute(dynamic value) {
    final base = (value?.toString().trim() ?? "").replaceAll(RegExp(r"/+$"), "");

    if (base.isEmpty) return "";
    if (base.contains("://")) return base;

    return "$apiOrigin${base.startsWith("/") ? "" : "/"}$base";
  }

  /// Olvida las bases. Para el cierre de sesion, junto al resto de los
  /// servicios: la proxima sesion las vuelve a traer, y puede traerlas
  /// distintas.
  void clear() {
    _media = "";
    _assets = "";

    notifyListeners();
  }
}
