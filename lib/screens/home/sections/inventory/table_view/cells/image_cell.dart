import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/inventory/product_image.dart';

import '../sheet_style.dart';
import '../state/sheet_controller.dart';
import '../state/sheet_cursor.dart';

/// La celda de un campo de tipo imagen.
///
/// **Siempre es un cuadrado**, y del mismo lado en todas las filas: el alto de
/// una fila menos su aire. La columna se sigue pudiendo ensanchar —es una
/// columna como cualquier otra— pero la foto no se estira con ella: se dibuja en
/// su cuadrado contra el borde izquierdo y lo que sobra queda vacio. Es lo que
/// hace que una columna de fotos se lea como una tira pareja: con la foto
/// ocupando la celda entera, cada ancho de columna daria un recorte distinto y
/// una foto vertical se veria como una franja.
///
/// Lo que se ve es la **portada** —la primera de la galeria— y no la galeria
/// entera: en una fila de planilla no entran tres fotos, y la que define al
/// producto es la primera (ver `Gallery` del backend). Las demas existen igual y
/// se cargan desde el mismo desplegable.
///
/// Y se dibuja la miniatura, no la foto: el backend renderiza una de 320px al
/// subirla ([kProductImageWidth]) y esto mide cuarenta. Pedir la grande seria
/// bajar megas por fila para dibujar un cuadradito.
///
/// Vacia se ve como un boton de agregar y no como una celda en blanco: es lo que
/// dice que ahi va una foto y que se pone tocando. Toda la celda abre el
/// desplegable ([SheetController.pickImage]) —eso lo maneja [SheetCellView],
/// como en cualquier otra— asi que aca no hay ningun toque propio.
class ImageCell extends StatelessWidget {
  const ImageCell({
    super.key,
    required this.raw,
    required this.row,
    required this.column
  });

  /// El valor guardado de la celda, tal como vino: la lista de ids de la
  /// galeria, un id suelto o la direccion que trajo una importacion. Se lee sin
  /// convertirlo a texto porque una galeria **no es** un texto: `toString()` de
  /// una lista da `[a, b]`, que no es ninguna imagen.
  final dynamic raw;

  /// En que fila esta. Decide de que banda de la cebra es su fondo, y con eso el
  /// relleno del cuadro (ver [SheetStyle.frameFill]).
  final int row;

  /// En que columna esta. Junto con [row] es lo que le permite reconocer que la
  /// subida en curso es la suya.
  final int column;

  @override
  Widget build(BuildContext context) {
    final sheet = SheetTheme.of(context);
    final images = ProductImage.from(raw);
    final cover = images.isEmpty ? null : images.first;

    // El cuadrado sale del alto de la fila y no de un numero propio: la fila
    // mide siempre lo mismo, asi que la celda tambien, y con `AspectRatio` no
    // hay que descontar a mano ni el aire de la celda ni el grosor del borde.
    return SizedBox(
      height: double.infinity,
      child: Center(child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AspectRatio(
          aspectRatio: 1,
          child: ValueListenableBuilder<SheetCell?>(
            valueListenable: context.read<SheetController>().uploading,
            builder: (context, uploading, child) => _frame(
              context,
              sheet,
              cover,
              busy: uploading != null && uploading.at(row, column)
            )
          ))
      ))
    );
  }

  /// El cuadro: la foto, el cargando mientras sube una, o el hueco de cuando no
  /// hay ninguna.
  Widget _frame(
    BuildContext context,
    SheetStyle sheet,
    ProductImage? cover, {
    required bool busy
  }) => Surface(
    width: double.infinity,
    height: double.infinity,
    radius: sheet.frameRadius,
    color: sheet.frameFill(row: row),
    child: busy
      ? const Center(child: Loading())
      : cover == null
        ? _empty(sheet)
        : _picture(sheet, cover)
  );

  /// La foto. Va recortada al cuadro y llenandolo ([BoxFit.cover]): una foto de
  /// producto no tiene por que ser cuadrada, y dejarla entera seria dibujarla
  /// diminuta con dos franjas vacias a los costados.
  Widget _picture(SheetStyle sheet, ProductImage cover) => ClipRRect(
    borderRadius: BorderRadius.circular(sheet.frameRadius),
    child: Image.network(
      cover.thumbnail,
      fit: BoxFit.cover,
      width: double.infinity,
      height: double.infinity,
      // Un id que ya no resuelve, o una direccion de una importacion que se
      // cayo: se ve como una celda sin foto, que es lo que hay.
      errorBuilder: (context, error, stack) => _empty(sheet)
    )
  );

  /// Lo que se ve cuando el producto no tiene foto: el mismo cuadro con el icono
  /// de agregar, en gris. No es un aviso de que falta algo —una foto es
  /// opcional— sino donde tocar para ponerla.
  Widget _empty(SheetStyle sheet) => Center(child: Icon(
    CI.add_image,
    size: AppSize.text * 1.2,
    color: sheet.scheme.text.secondary
  ));
}
