import 'package:app/services/files/cdn_service.dart';

/// De donde cuelga un archivo: de la empresa que lo subio o de la plataforma.
///
/// No es una clasificacion nuestra: son dos espacios distintos del backend
/// (`/rigel/media` y `/rigel/assets`) con dos direcciones base distintas, y un
/// id de uno pedido en el otro es un 404. Por eso el archivo llega diciendo cual
/// es el suyo y no hay que deducirlo de en que parte de la respuesta aparecio.
enum FileScope {
  /// Lo que subio una empresa: su logo, la foto de un producto, un documento.
  media,

  /// Lo que es de la app y es igual para todos: banderas, iconos.
  assets;

  static FileScope from(dynamic raw) =>
    raw?.toString().toLowerCase() == "assets" ? assets : media;
}

/// Un archivo del backend, tal como lo describe cualquier respuesta que
/// devuelva uno.
///
/// **No trae direccion.** Un archivo es un id, y la direccion se arma poniendo
/// ese id detras de la base que `/init` entrego ([CdnService]). Es la misma
/// decision que ya toma el backend al guardar un id en `companies`.`profile` y
/// no una URL: una direccion guardada envejece el dia que cambia el dominio, el
/// CDN o el proveedor, y la copia que ya esta en pantalla envejece con ella. El
/// id no envejece nunca.
///
/// Lo que si trae es con que tamanos existe ([variants]): las miniaturas se
/// renderizaron al subir el archivo y son las que hay. Pedir una que no se
/// renderizo no falla —el backend devuelve la grande—, pero pedir la que existe
/// es la diferencia entre bajar 8 KB y bajar 2 MB para dibujar 44 pixeles.
class FileModel {
  const FileModel({
    required this.id,
    this.scope = FileScope.media,
    this.mime = "",
    this.width,
    this.height,
    this.variants = const []
  });

  /// Id publico (uuid). Es lo unico que las demas tablas guardan, y lo que se
  /// le pone detras a la base para llegar a los bytes.
  final String id;

  final FileScope scope;

  /// Tipo real del contenido, leido de los bytes y no del nombre. Es con lo que
  /// se decide si esto se dibuja como imagen o se ofrece como documento.
  final String mime;

  /// Medidas del original, en pixeles. Solo en imagenes.
  final int? width;
  final int? height;

  /// Anchos de las miniaturas que este archivo **tiene**, de menor a mayor.
  ///
  /// Es por archivo y no por tipo de archivo: una imagen mas chica que el ancho
  /// de la miniatura se guarda sin ella, y esta lista es como se sabe.
  final List<int> variants;

  /// Lee el archivo de una respuesta, o `null` si no hay ninguno.
  ///
  /// Sin id no hay archivo aunque venga el resto: no habria de donde bajarlo, y
  /// quien lo esperaba dibuja lo que dibuja cuando no hay imagen.
  static FileModel? from(dynamic json) {
    if (json is! Map) return null;

    final id = json["id"]?.toString().trim() ?? "";
    if (id.isEmpty) return null;

    return FileModel(
      id: id,
      scope: FileScope.from(json["scope"]),
      mime: json["mime"]?.toString().trim() ?? "",
      width: _size(json["width"]),
      height: _size(json["height"]),
      variants: _variants(json["variants"])
    );
  }

  static int? _size(dynamic raw) {
    if (raw is num) return raw.toInt();
    return int.tryParse("$raw");
  }

  /// Los anchos disponibles, ordenados de menor a mayor. Se ordenan aca y no se
  /// confia en como vinieron porque [sized] elige recorriendo.
  static List<int> _variants(dynamic raw) {
    if (raw is! List) return const [];

    final widths = <int>[
      for (final value in raw)
        if (_size(value) case final width? when width > 0) width
    ];

    widths.sort();

    return widths;
  }

  /// La direccion del archivo entero, o `""` si todavia no hay base con que
  /// armarla. Vacia se lee igual que "no hay imagen", que es lo que hace falta.
  String get url => CdnService().url(scope, id);

  /// La miniatura mas chica que exista, o el archivo entero si no se renderizo
  /// ninguna. Es para donde el tamano lo pone el diseno y no el dato: una fila
  /// de un listado, un avatar.
  String get thumbnail => sized(1);

  /// La direccion de la version mas chica que **cubra** [width] pixeles, o la
  /// del archivo entero si ninguna llega.
  ///
  /// Se elige la mas chica que alcance y no la mas parecida: una imagen mas
  /// chica que el hueco se ve borrosa, que es peor que tardar un poco mas.
  String sized(int width) {
    for (final variant in variants) {
      if (variant >= width) return CdnService().url(scope, id, width: variant);
    }

    return url;
  }

  /// Igualdad por valor: el logo viaja como parte del perfil y de la fila de un
  /// listado, que se comparan para decidir si hace falta repintar.
  @override
  bool operator ==(Object other) =>
    other is FileModel && other.id == id && other.scope == scope;

  @override
  int get hashCode => Object.hash(id, scope);

  @override
  String toString() => "FileModel($id)";
}
