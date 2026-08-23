// SERVICES
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/files/file_model.dart';

/// Ancho de la miniatura que el backend renderiza para una foto de producto.
///
/// Es la unica que existe (ver `Gallery`: sube con el proposito `product`, que
/// recorta a 1400px y renderiza esta), asi que pedir otra no falla pero baja la
/// grande. La celda de la planilla dibuja 40 pixeles y esta pesa 8 KB: es la
/// diferencia entre abrir una tabla y bajar el catalogo entero.
const int kProductImageWidth = 320;

/// Una foto de un producto, tal como quedo guardada en su celda.
///
/// La columna de imagenes de una tabla guarda **una lista de ids de archivo** y
/// la primera es la portada (ver `Gallery` del backend). No guarda direcciones:
/// una direccion envejece el dia que cambia el dominio o el CDN, y el id no
/// envejece nunca —la direccion se arma con la base que `/init` reparte una sola
/// vez ([CdnService])—.
///
/// La excepcion es lo que llego en una importacion: ahi la columna trae la
/// direccion de la empresa, que es un dato suyo y no un archivo nuestro. Se
/// distingue por [isStored] y hay que distinguirla, porque las dos cosas se
/// borran distinto: la nuestra se baja del backend, la de ella se borra como se
/// borra cualquier valor de una celda.
class ProductImage {
  const ProductImage._(this.id, this.address);

  /// Una foto que subio la empresa por la api: es un archivo nuestro y lo unico
  /// que se guarda de ella es su id.
  const ProductImage.stored(String id) : this._(id, "");

  /// Una direccion que trajo una importacion. No es un archivo de la
  /// plataforma: no se puede pedir por id ni borrar del backend.
  const ProductImage.external(String address) : this._("", address);

  /// Id publico del archivo, o vacio si la foto es externa.
  final String id;

  /// Direccion tal como la guardo la empresa, o vacia si la foto es nuestra.
  final String address;

  /// Si los bytes los guarda esta plataforma. Es lo que decide si eliminarla es
  /// una baja contra el backend o vaciar la celda.
  bool get isStored => id.isNotEmpty;

  /// La foto entera, para verla en grande. Vacia si todavia no hay base con que
  /// armarla, que se lee igual que "no hay imagen".
  String get url =>
    isStored ? CdnService().url(FileScope.media, id) : address;

  /// La miniatura, que es con lo que se dibuja una celda. Una foto externa no
  /// tiene: se baja tal cual esta, que es lo unico que hay de ella.
  String get thumbnail => isStored
    ? CdnService().url(FileScope.media, id, width: kProductImageWidth)
    : address;

  /// Lo que se guarda en la celda por esta foto: su id, o la direccion si es de
  /// la empresa.
  String get stored => isStored ? id : address;

  /// Lee la galeria de una celda.
  ///
  /// El valor guardado puede ser cualquiera de estas cuatro cosas, y las cuatro
  /// se leen igual porque las cuatro existen de verdad en las tablas: la lista
  /// de ids que escribe la api, un id suelto de antes de que hubiera galerias,
  /// una direccion que trajo una importacion, o nada.
  static List<ProductImage> from(dynamic raw) {
    if (raw is List) {
      return [for (final entry in raw) ?_one(entry)];
    }

    final image = _one(raw);

    return image == null ? const [] : [image];
  }

  /// Lee la galeria que devuelve el backend despues de agregar o quitar una foto
  /// (`{ images: [...] }`).
  ///
  /// Es la lista que queda, ya resuelta: cada foto nuestra viene como un archivo
  /// ([FileModel]) y las de una importacion, como `{ id: null, url }`. Se guarda
  /// de ella lo unico que la celda necesita —el id, o la direccion— porque es lo
  /// unico que la columna guarda.
  static List<ProductImage> fromResponse(dynamic data) {
    final images = data is Map ? data["images"] : data;

    if (images is! List) return const [];

    return [
      for (final entry in images)
        if (entry is Map) ?_one(entry["id"] ?? entry["url"])
    ];
  }

  /// Lo que hay que dejar en la celda por estas fotos: la lista de ids, en
  /// orden, que es como la guarda el backend.
  static List<String> valuesOf(List<ProductImage> images) =>
    [for (final image in images) image.stored];

  /// Una entrada de la columna, sea lo que sea que haya guardado.
  ///
  /// Un uuid es un archivo nuestro y cualquier otra cosa con forma de direccion
  /// es de la empresa. Lo que no es ni una cosa ni la otra —un resto de una
  /// importacion torcida, un vacio— no es una foto y se deja afuera: la celda
  /// muestra lo que se puede dibujar.
  static ProductImage? _one(dynamic raw) {
    final value = raw?.toString().trim() ?? "";

    if (value.isEmpty) return null;
    if (_uuid.hasMatch(value)) return ProductImage.stored(value);

    return value.contains("://") ? ProductImage.external(value) : null;
  }

  static final RegExp _uuid = RegExp(
    r"^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$",
    caseSensitive: false
  );

  @override
  bool operator ==(Object other) =>
    other is ProductImage && other.id == id && other.address == address;

  @override
  int get hashCode => Object.hash(id, address);
}
