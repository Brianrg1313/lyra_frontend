import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Todo lo que las celdas necesitan para pintarse, resuelto **una sola vez** por
/// planilla.
///
/// Una celda no tiene nada propio que decidir: el color de fondo, el borde y la
/// tipografia son los mismos para todas, y solo cambian segun cuatro estados
/// (fila par o impar de la cebra, elegida o no). Si cada una los armara por su
/// cuenta —que es lo que pasaba— cada repintado alocaria un [BoxDecoration] y un
/// [TextStyle] nuevos por celda, y como Flutter compara esos objetos para
/// decidir si hace falta repintar, dos objetos iguales pero distintos lo obligan
/// a repintar igual.
///
/// Aca se arman una vez y se comparten: las celdas reciben **la misma instancia**
/// y el motor puede saltear el repintado.
class SheetStyle {
  SheetStyle({
    required this.scheme,
    required this.rowHeight,
    required this.gutterWidth
  }) : cellPadding = EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
       framePadding = EdgeInsets.all(AppSize.gap),
       frameRadius = AppSize.gap,
       // Los cuatro lados estan **siempre**, y los dos que no son la cuadricula
       // van transparentes. Un borde ocupa lugar: si el del cursor apareciera
       // recien al elegir la celda, entrar en ella le comeria un pixel por lado
       // al contenido y el texto pegaria un salto —justo cuando se lo va a
       // escribir, que es cuando mas se nota—. Asi la caja mide lo mismo elegida
       // que no, y lo unico que cambia al elegirla es el color.
       _line = Border(
         top: const BorderSide(color: Colors.transparent),
         left: const BorderSide(color: Colors.transparent),
         right: BorderSide(color: scheme.table.lines),
         bottom: BorderSide(color: scheme.table.lines)
       ),
       _selected = Border.all(color: scheme.table.currentCell),
       value = TextStyle(fontSize: AppSize.text, color: scheme.text.primary),
       readOnlyValue = TextStyle(
         fontSize: AppSize.text,
         color: scheme.text.secondary
       ),
       title = TextStyle(
         fontSize: AppSize.text,
         fontWeight: FontWeight.w600,
         color: scheme.text.primary
       ),
       pendingTitle = TextStyle(
         fontSize: AppSize.text,
         fontWeight: FontWeight.w600,
         color: scheme.text.secondary
       ),
       number = TextStyle(
         fontSize: AppSize.text * 0.85,
         color: scheme.text.secondary
       ),
       symbol = TextStyle(fontSize: AppSize.text, color: scheme.text.secondary),
       code = TextStyle(fontSize: AppSize.text, color: scheme.text.secondary);

  final SchemeColor scheme;
  final double rowHeight;
  final double gutterWidth;

  final EdgeInsets cellPadding;

  /// Aire de una celda que dibuja **su propio marco** adentro (la de una lista,
  /// que se ve como el boton de un desplegable).
  ///
  /// Es parejo por los cuatro lados, y ahi esta la diferencia con
  /// [cellPadding]: ese separa un texto de los bordes y solo tiene sentido a los
  /// costados, pero un marco que se apoya arriba y abajo contra la cuadricula se
  /// confunde con ella. Deja el marco despegado de la celda por igual, que es lo
  /// que lo hace leer como algo que esta **dentro** de la celda y no como la
  /// celda misma.
  final EdgeInsets framePadding;

  /// Cuanto se redondea ese marco. Es un radio corto a proposito: el de siempre
  /// ([AppSize.corner]) es el de una tarjeta y en una caja del alto de una fila
  /// se come las esquinas.
  final double frameRadius;

  /// Los dos bordes de una celda: el de siempre (la cuadricula a la derecha y
  /// abajo, `table.lines`, y los otros dos lados transparentes) y el del cursor
  /// (los cuatro lados, `table.currentCell`).
  ///
  /// Los dos miden lo mismo —un pixel por lado, los cuatro lados siempre— y esa
  /// es toda la gracia: elegir una celda cambia un color y no la caja, asi que
  /// el contenido no se mueve.
  final Border _line;
  final Border _selected;

  /// Color de lo que senala donde se esta parado: la linea de donde va a caer
  /// una columna que se arrastra, el velo sobre la que viaja y el spinner de la
  /// fila que se esta guardando. Es el mismo del borde del cursor
  /// (`table.currentCell`), asi que todo lo que marca la posicion se lee como
  /// una sola cosa.
  ///
  /// Va aca y no en cada pieza para que no queden colores de la planilla fuera
  /// de esta clase: las que lo usan ya reciben el estilo.
  late final Color accent = scheme.table.currentCell;

  /// Fondo de las bandas que no son datos —la fila de campos y la de numeros—
  /// y del encabezado fantasma de una columna que se arrastra. Es
  /// `table.headers`.
  late final Color headerFill = scheme.table.headers;

  /// Texto de una celda que se escribe, y de una que no (los campos que lleva el
  /// backend: se ven como un dato mas, pero apagados).
  final TextStyle value;
  final TextStyle readOnlyValue;

  /// Titulo de un campo, y el mismo mientras el cambio viaja: ya es lo que va a
  /// quedar, pero todavia no volvio del backend.
  final TextStyle title;
  final TextStyle pendingTitle;

  /// Numero de fila de la banda de la izquierda.
  final TextStyle number;

  /// Lo que acompana a un valor sin ser el valor: el simbolo de la moneda de un
  /// precio, y lo que venga despues de la misma naturaleza. Va en gris al lado
  /// del dato para que se lea de un vistazo cual es el numero y cual la unidad.
  final TextStyle symbol;

  /// El texto de un codigo: el SKU.
  ///
  /// Va en gris y no con el color del dato porque un codigo no es un dato que se
  /// lea: es una etiqueta con la que se encuentra el producto. Nadie compara dos
  /// SKU de un vistazo como compara dos precios, asi que en una planilla llena
  /// esa columna no tiene por que pesar como las demas —al contrario, en negro
  /// es la que mas ruido hace, porque son las cadenas mas largas y las mas
  /// ilegibles—.
  ///
  /// Se escribe igual que cualquier celda: gris no quiere decir apagado (ver
  /// [readOnlyValue], que es otra cosa aunque hoy se vean parecidas).
  final TextStyle code;

  /// Decoracion de una celda del cuerpo.
  ///
  /// Son dos cosas independientes: el **borde** lo decide el cursor ([selected]
  /// es esta celda, no su fila) y el **fondo** lo decide la fila entera
  /// ([fill]). Por eso viajan separadas: la celda del cursor lleva su marco
  /// dentro de una fila que ya esta resaltada, y no al reves.
  ///
  /// [row] solo se mira cuando el fondo es el de siempre, que es la cebra: esa
  /// alterna por posicion y no por lo que la fila sea (ver [_cells]).
  BoxDecoration cell({
    required int row,
    required bool selected,
    SheetRowFill fill = SheetRowFill.plain
  }) => _cells[switch (fill) {
    SheetRowFill.plain => row.isOdd ? 2 : 0,
    SheetRowFill.over => 4,
    SheetRowFill.selected => 6
  } + (selected ? 1 : 0)];

  /// Relleno del marco de una celda que se ve como un control (la de una lista).
  ///
  /// Tiene que despegarse del fondo de **su** fila, y ahi esta el detalle: con
  /// la cebra la planilla usa sus dos superficies fila por medio (ver [_cells]),
  /// asi que no hay un solo color que se note en las dos. En el tema claro, un
  /// marco del color de una fila par desaparece sobre una par y se ve sobre una
  /// impar; con el otro pasa lo contrario.
  ///
  /// Por eso el marco se lleva **la que su fila no esta usando**: siempre es la
  /// otra, asi que siempre se ve, en los dos temas y en las dos bandas de la
  /// cebra.
  Color frameFill({required int row}) =>
    row.isOdd ? scheme.table.background : scheme.table.even;

  /// Decoracion de una celda de la fila de campos.
  BoxDecoration field({required bool selected}) =>
    selected ? _fieldSelected : _field;

  /// Decoracion de una celda de la banda de numeros.
  ///
  /// Sigue a su fila: el resaltado no se puede cortar en el numero, o la fila
  /// quedaria pintada a medias. Por eso toma el mismo [SheetRowFill] que el
  /// cuerpo y no un booleano suyo.
  BoxDecoration gutter({SheetRowFill fill = SheetRowFill.plain}) =>
    switch (fill) {
      SheetRowFill.plain => _gutter,
      SheetRowFill.over => _gutterOver,
      SheetRowFill.selected => _gutterSelected
    };

  /// La cebra: las filas pares van sobre `table.background`, el fondo de una
  /// fila cualquiera, y las impares sobre `table.even`, que el esquema ofrece
  /// justamente para distinguir una fila de la de al lado.
  ///
  /// Alterna por **posicion** y nada mas: los registros y las filas en blanco de
  /// abajo son una sola grilla continua, asi que la banda sigue de largo y no se
  /// corta donde termina lo cargado.
  /// Los cuatro fondos que puede tener una fila —las dos bandas de la cebra, la
  /// que tiene el mouse encima y la del cursor— cada uno con sus dos bordes. El
  /// orden es el que arma [cell]: de a pares, primero el borde de la cuadricula
  /// y despues el del cursor.
  late final List<BoxDecoration> _cells = [
    BoxDecoration(color: scheme.table.background, border: _line),
    BoxDecoration(color: scheme.table.background, border: _selected),
    BoxDecoration(color: scheme.table.even, border: _line),
    BoxDecoration(color: scheme.table.even, border: _selected),
    BoxDecoration(color: scheme.table.over, border: _line),
    BoxDecoration(color: scheme.table.over, border: _selected),
    BoxDecoration(color: scheme.table.rowSelected, border: _line),
    BoxDecoration(color: scheme.table.rowSelected, border: _selected)
  ];

  late final BoxDecoration _field =
    BoxDecoration(color: headerFill, border: _line);
  late final BoxDecoration _fieldSelected =
    BoxDecoration(color: headerFill, border: _selected);

  late final BoxDecoration _gutter =
    BoxDecoration(color: headerFill, border: _line);
  late final BoxDecoration _gutterOver =
    BoxDecoration(color: scheme.table.over, border: _line);
  late final BoxDecoration _gutterSelected =
    BoxDecoration(color: scheme.table.rowSelected, border: _line);
}

/// Con que se pinta el fondo de una fila.
///
/// Son los tres estados en que puede estar una fila entera, y estan aca —y no
/// como dos booleanos sueltos en cada celda— porque son excluyentes y tienen un
/// orden: el cursor le gana al mouse. Una fila donde se esta parado y encima
/// tiene el puntero se ve como la fila donde se esta parado; si fuera al reves,
/// pasar el mouse por la planilla taparia el unico rastro de donde se habia
/// quedado uno.
enum SheetRowFill {
  /// El fondo de siempre: la cebra, que alterna por posicion.
  plain,

  /// La fila que tiene el mouse encima (`table.over`).
  over,

  /// La fila donde esta el cursor (`table.rowSelected`).
  selected
}

/// Baja el [SheetStyle] a todas las celdas.
///
/// Es un [InheritedWidget] y no un provider porque no cambia nunca mientras la
/// planilla este abierta: solo se rehace si cambia el tema, y ahi `SchemeColor`
/// es otra instancia. Comparar por identidad alcanza y es lo mas barato que hay.
class SheetTheme extends InheritedWidget {
  const SheetTheme({super.key, required this.style, required super.child});

  final SheetStyle style;

  static SheetStyle of(BuildContext context) =>
    context.dependOnInheritedWidgetOfExactType<SheetTheme>()!.style;

  @override
  bool updateShouldNotify(SheetTheme old) =>
    !identical(old.style.scheme, style.scheme) ||
    old.style.rowHeight != style.rowHeight;
}
