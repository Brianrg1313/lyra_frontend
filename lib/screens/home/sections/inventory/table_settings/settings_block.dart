import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Un grupo de datos de los ajustes de una tabla, sobre su propia superficie.
///
/// La superficie es un bloque **sobre** la hoja de la pantalla
/// ([Surface.over]) y no otra hoja: lo que separa es un grupo de datos del
/// siguiente, no una pantalla de otra. Es el mismo criterio con el que se
/// arma el perfil de una empresa.
///
/// El subtitulo no es decorativo: casi ningun grupo de esta pantalla se
/// explica solo con su titulo —"lo que ve la IA" y "canales conectados" son
/// los dos conceptos que hay que introducir, no recordar.
class SettingsBlock extends StatelessWidget {
  const SettingsBlock({
    super.key,
    required this.title,
    required this.child,
    this.subtitle,
    this.action
  });

  final String title;
  final String? subtitle;
  final Widget child;

  /// Lo que se puede hacer con el grupo entero y no con un dato suyo. Va en el
  /// titulo porque no pertenece a ninguna fila.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Padding(
      padding: EdgeInsets.only(bottom: AppSize.spaceXS),
      child: Surface.over(
        padding: EdgeInsets.all(AppSize.spaceS),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(child: TextMedium(title, bold: true, ellipsis: true)),
              ?action
            ]),
            if (subtitle != null) ...[
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                subtitle!,
                lines: 3,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ],
            SizedBox(height: AppSize.spaceS),
            child
          ]
        )
      )
    );
  }
}

/// Un dato de un bloque: con que se lo reconoce, como se llama, para que sirve
/// y cuanto vale.
///
/// El valor va **debajo** del nombre y no pegado al borde derecho: casi todos
/// los de esta pantalla necesitan una linea que los explique (que significa
/// "declarada", por que hay dos fechas), y una fila de etiqueta y valor no
/// deja lugar para eso. Leido en una columna, cada dato son tres renglones
/// que se leen de corrido.
///
/// El valor es un [child] y no un texto porque no siempre es algo que se lee:
/// la visibilidad es una etiqueta de color y los tipos de columna son una
/// hilera de ellas. Lo que si es un texto se arma con [SettingsValue], que es
/// esta misma caja con un renglon adentro.
class SettingsRow extends StatelessWidget {
  const SettingsRow({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.hint,
    this.action
  });

  /// Con que se reconoce el dato de un vistazo, sin leer su nombre.
  final IconData icon;

  final String label;

  /// Cuanto vale el dato.
  final Widget child;

  /// Que significa el dato, en una linea. Opcional a proposito: se escribe
  /// donde el nombre no alcanza y se deja afuera donde el nombre ya lo dice
  /// todo.
  final String? hint;

  /// Lo que se hace con el dato: editarlo, copiarlo. Va al borde derecho de la
  /// fila y no debajo del valor porque opera sobre el dato entero, no sobre lo
  /// que hoy vale.
  ///
  /// En `null` no queda hueco reservado —a diferencia de la ficha de la
  /// empresa— porque aca la mayoria de los datos no se editan: es una pantalla
  /// de estado con dos textos que se escriben, y una columna de botones vacia
  /// prometeria acciones que no existen.
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // Baja el icono hasta el renglon del nombre: alineado al tope queda
          // colgando arriba de la primera letra.
          padding: EdgeInsets.only(top: AppSize.gap * 0.5),
          child: Icon(icon, size: AppSize.text, color: scheme.text.secondary)
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextSmall(label, color: scheme.text.secondary),
            SizedBox(height: AppSize.gap * 0.5),
            child,
            if (hint != null) ...[
              SizedBox(height: AppSize.gap * 0.5),
              TextSmall(
                hint!,
                lines: 3,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ]
          ]
        )),
        if (action != null) ...[
          SizedBox(width: AppSize.gap),
          action!
        ]
      ]
    );
  }
}

/// Un dato que se lee: [SettingsRow] con su valor escrito.
///
/// Un valor vacio se dice con palabras y en gris ([empty]): un guion o un
/// renglon en blanco se leen como que la ficha se rompio, no como que ese dato
/// no esta cargado.
class SettingsValue extends StatelessWidget {
  const SettingsValue({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.hint,
    this.empty,
    this.selectable = false,
    this.action
  });

  final IconData icon;
  final String label;
  final String value;
  final String? hint;

  /// Que decir cuando no hay valor. Sin esto se muestra el vacio tal cual, que
  /// es lo correcto para los datos que ya vienen escritos como texto.
  final String? empty;

  /// Si el valor se puede seleccionar para copiarlo. Va donde el dato se usa
  /// afuera de la app (el identificador de la tabla), no donde solo se lee.
  final bool selectable;

  /// Lo que se hace con el dato. Ver [SettingsRow.action].
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);
    final blank = value.trim().isEmpty;

    return SettingsRow(
      icon: icon,
      label: label,
      hint: hint,
      action: action,
      child: TextMedium(
        blank ? (empty ?? "") : value,
        lines: 3,
        ellipsis: true,
        selectable: !blank && selectable,
        color: blank ? scheme.text.secondary : null
      )
    );
  }
}

/// Los datos de un bloque, uno debajo del otro y separados por una linea.
///
/// La separacion es mas ancha que la de una lista cualquiera porque cada dato
/// ya no es un renglon: son tres —nombre, valor y explicacion— y apretados uno
/// contra otro dejan de leerse como datos distintos.
class SettingsList extends StatelessWidget {
  const SettingsList({super.key, required this.rows});

  final List<Widget> rows;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      for (int i = 0; i < rows.length; i++) ...[
        if (i > 0) Separator.horizontal(
          margin: EdgeInsets.symmetric(vertical: AppSize.spaceS)
        ),
        rows[i]
      ]
    ]
  );
}

/// Etiqueta de un estado: icono y texto sobre un relleno tenue de su propio
/// color.
///
/// Es para lo que la ficha **dice** de un dato y no para lo que el dato vale:
/// cuanto ve el modelo de una columna, de que tipo es, si un canal esta
/// pausado. Se leen de un vistazo y ninguno se edita, asi que no son una fila
/// mas.
///
/// El color lo pone quien la usa y no la etiqueta: es semantico —el color de
/// marca cuando el dato habilita algo, gris cuando solo informa— y vive junto
/// al estado que lo significa.
class SettingsTag extends StatelessWidget {
  const SettingsTag({
    super.key,
    required this.label,
    required this.color,
    this.icon
  });

  final String label;
  final Color color;

  /// Sin icono la etiqueta es solo su texto. Es lo que corresponde donde son
  /// varias en hilera y el icono seria ruido repetido.
  final IconData? icon;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSize.gap,
      vertical: AppSize.gap * 0.4
    ),
    decoration: BoxDecoration(
      // Un fondo apenas tenido en vez de uno lleno: la etiqueta acompana al
      // dato, no compite con el.
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSize.corner)
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: AppSize.text * 0.9, color: color),
          SizedBox(width: AppSize.gap * 0.5)
        ],
        TextSmall(label, color: color)
      ]
    )
  );
}

/// Un numero grande con lo que cuenta debajo.
///
/// Es para las tres cifras que contestan "que tan grande es esta tabla"
/// —cuantos registros, cuantas columnas, cuantos canales la leen—, que son lo
/// primero que se mira al entrar y no tienen por que buscarse dentro de una
/// lista de filas.
class SettingsStat extends StatelessWidget {
  const SettingsStat({
    super.key,
    required this.icon,
    required this.value,
    required this.label,
    this.tint
  });

  final IconData icon;

  /// La cifra ya escrita: quien la arma decide como se lee un numero que no se
  /// pudo contar.
  final String value;

  final String label;

  /// Color del numero, para cuando la cifra significa algo (que un canal
  /// llegue a la tabla). Sin el va el color del texto.
  final Color? tint;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface(
      padding: EdgeInsets.all(AppSize.spaceXS),
      color: scheme.surface,
      radius: AppSize.cornerInset(AppSize.gap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppSize.text, color: scheme.text.secondary),
          SizedBox(height: AppSize.gap),
          // Grande pero no el doble ([TextLarge]): son tres cifras una al lado
          // de la otra en una tarjeta, no el titulo de la pantalla.
          TextMedium(
            value,
            multiplier: 1.6,
            bold: true,
            ellipsis: true,
            color: tint
          ),
          SizedBox(height: AppSize.gap * 0.5),
          TextSmall(label, ellipsis: true, color: scheme.text.secondary)
        ]
      )
    );
  }
}

/// Boton de una accion sobre un dato de los ajustes.
///
/// Es del tamaño del renglon y sin relleno hasta que se lo apunta: la pantalla
/// es para leer, y botones pintados todo el tiempo en cada fila la
/// convertirian en una botonera. El color de reposo es el de la tarjeta y no
/// transparente, para que los dos extremos de la animacion de [FeedbackButton]
/// sean opacos.
///
/// Es hermano del boton de la ficha de la empresa y no el mismo: son dos
/// secciones distintas, y compartir un widget de una fila las ataria por algo
/// que solo es parecido.
class SettingsAction extends StatelessWidget {
  const SettingsAction({
    super.key,
    required this.icon,
    required this.message,
    required this.action
  });

  final IconData icon;

  /// Que hace el boton. Es lo unico que lo nombra: no lleva texto.
  final String message;

  final void Function() action;

  /// Lado del boton. Sale del tamaño del texto y no de [AppSize.button] porque
  /// convive con un renglon, no con una barra de acciones.
  static double get size => AppSize.text * 2;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      message: message,
      width: size,
      height: size,
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.surfaceOver,
      feedbackColor: scheme.line,
      child: Center(child: Icon(
        icon,
        size: AppSize.text,
        color: scheme.text.secondary
      ))
    );
  }
}

/// Un dato que se elige de una lista, dibujado como el boton que la despliega.
///
/// Es la version de [SettingsAction] para lo que no es una accion sino un
/// valor: muestra **lo que hoy vale** —con su icono y su color, que en la
/// visibilidad significan algo— y al tocarlo despliega las opciones. Por eso no
/// es un [SelectInput]: no se esta rellenando un formulario que despues se
/// guarda, se esta cambiando un dato que ya existe y se guarda solo. Tres
/// campos de formulario por fila, en una lista de veinte columnas, serian
/// sesenta cajas de formulario para leer una tabla.
///
/// El desplegable se ancla **a este boton** ([showSelectMenu] mide el widget
/// que le pasan), asi que quien lo abre recibe el contexto de aca adentro y no
/// el de la fila: colgado de la fila se abriria desde el borde izquierdo.
///
/// Se estira a lo que le den: siempre va dentro de una celda con ancho
/// (`Expanded`), nunca suelto en un `Wrap`.
class SettingsSelect extends StatelessWidget {
  const SettingsSelect({
    super.key,
    required this.label,
    required this.open,
    this.icon,
    this.color,
    this.message
  });

  /// Lo que vale hoy, ya escrito.
  final String label;

  /// Abre el desplegable. Recibe el contexto del boton, que es lo que le da su
  /// posicion en pantalla.
  final Future<void> Function(BuildContext anchor) open;

  final IconData? icon;

  /// Color del icono y del texto, para cuando el valor significa algo (los tres
  /// estados de la visibilidad). Sin el va el color del texto normal.
  final Color? color;

  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: () => open(context),
      message: message,
      height: AppSize.button,
      padding: EdgeInsets.only(
        left: AppSize.spaceXS,
        right: AppSize.gap
      ),
      radius: AppSize.cornerInset(AppSize.spaceXS),
      // El color de la pagina y no el de la tarjeta: el bloque ya es una
      // superficie sobre ella, y un relleno del mismo color no se veria.
      color: scheme.surface.withAlpha(150),
      feedbackColor: scheme.surface,
      child: Row(children: [
        if (icon != null) ...[
          Icon(icon, size: AppSize.text * 0.9, color: color ?? scheme.icon),
          SizedBox(width: AppSize.gap * 0.75)
        ],
        Expanded(child: TextSmall(label, ellipsis: true, color: color)),
        SizedBox(width: AppSize.gap * 0.5),
        Icon(
          CI.arrow_down,
          size: AppSize.text * 1.5,
          color: scheme.text.secondary
        )
      ])
    );
  }
}
