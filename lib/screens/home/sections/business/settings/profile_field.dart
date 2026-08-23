import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/modals/edit_business_field/_edit_business_field.dart';
import 'package:app/screens/modals/edit_business_field/business_field.dart';

/// El esqueleto de un dato del perfil, de arriba abajo: que dato es, para que
/// sirve y cuanto vale.
///
/// No es una fila de etiqueta y valor con el dato pegado al borde derecho: eso
/// obliga a cruzar la pantalla para leer cada renglon y no deja lugar para
/// explicar nada. Aca el dato se lee en una sola columna —icono y nombre, la
/// explicacion debajo, el valor al final— y lo unico que queda a la derecha es
/// lo que se puede hacer con el.
///
/// El valor es un [child] y no un texto porque no siempre es algo que se lee:
/// los datos que se eligen de una lista traen ahi su propio desplegable (ver
/// `ProfileSelectField`). Lo que se lee es [ProfileField], que es esta misma
/// caja con un texto adentro.
///
/// La [description] es opcional a proposito: se escribe donde el nombre del
/// dato no alcanza para saber que se esta cargando (que es la razon social, a
/// donde escribe un cliente que necesita ayuda) y se deja afuera donde el
/// nombre ya lo dice todo. Explicar lo obvio es tanto ruido como no explicar lo
/// que hace falta.
class ProfileFieldFrame extends StatelessWidget {
  const ProfileFieldFrame({
    super.key,
    required this.icon,
    required this.label,
    required this.child,
    this.description,
    this.note,
    this.action
  });

  /// Con que se reconoce el dato de un vistazo, sin leer su nombre. Es lo que
  /// deja recorrer la columna con la vista: los correos son sobres, las fechas
  /// calendarios.
  final IconData icon;

  final String label;

  /// Cuanto vale el dato: el texto que dice lo que hay guardado, o con que se
  /// cambia cuando cambiarlo es elegir de una lista.
  final Widget child;

  /// Para que sirve el dato, en una linea. Ver la nota de la clase.
  final String? description;

  /// Aclaracion al lado del nombre, para lo que el dato tiene que decir de si
  /// mismo y no de su valor (que un correo es el principal). Va arriba y no
  /// junto al valor porque califica al dato, no a lo que vale hoy.
  final String? note;

  /// Lo que se puede hacer con el dato. En `null` queda el hueco igual, para
  /// que los nombres midan lo mismo en todas las filas y la columna de botones
  /// no se corra sola.
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
          padding: EdgeInsets.only(top: AppSize.gap),
          child: Icon(icon, size: AppSize.text, color: scheme.text.secondary)
        ),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _title(context, scheme),
            if (description != null) ...[
              SizedBox(height: AppSize.gap / 2),
              TextSmall(
                description!,
                lines: 3,
                ellipsis: true,
                color: scheme.text.secondary
              )
            ],
            SizedBox(height: AppSize.gap),
            child
          ]
        ))
      ]
    );
  }

  /// El renglon del nombre: como se llama el dato a la izquierda y que se puede
  /// hacer con el a la derecha.
  Widget _title(BuildContext context, SchemeColor scheme) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: Padding(
        // El mismo desplazamiento del icono, por lo mismo: el nombre convive
        // con un boton mas alto que su renglon.
        padding: EdgeInsets.only(top: AppSize.gap / 2),
        child: Row(children: [
          Flexible(child: TextMedium(label, bold: true, ellipsis: true)),
          if (note != null) ...[
            SizedBox(width: AppSize.gap),
            TextSmall(note!, color: scheme.primary)
          ]
        ])
      )),
      SizedBox(width: AppSize.gap),
      action ?? SizedBox(width: ProfileAction.size)
    ]
  );
}

/// Un dato del perfil que se lee: el valor escrito y, cuando se puede cambiar,
/// el boton de editarlo.
///
/// El formulario que lo cambia es un modal de un solo campo porque escribir
/// pide sitio —un teclado, un error debajo, un boton de guardar— y eso no entra
/// en el renglon de una ficha. Los datos que se eligen no pasan por ahi: se
/// cambian donde se leen (`ProfileSelectField`).
///
/// Un dato editable se dibuja **aunque este vacio**: casi todo el perfil es
/// opcional y esta fila es el unico lugar desde donde se lo carga, asi que
/// esconderla no seria no mostrar un dato, seria no dejar cargarlo. En ese caso
/// dice que no hay nada y el boton pasa a ser el de agregar. Lo que no se
/// edita —lo que escribe la plataforma— si desaparece cuando no esta: ahi la
/// fila no ofreceria nada.
class ProfileField extends StatelessWidget {
  const ProfileField({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.description,
    this.note,
    this.field,
    this.selectable = false,
    this.trailing
  });

  final IconData icon;
  final String label;
  final String value;
  final String? description;
  final String? note;

  /// Como se edita el dato, o `null` si no se edita desde aca: la situacion
  /// legal la otorga la verificacion y las fechas de registro las pone el
  /// sistema.
  final BusinessField? field;

  /// Si el valor se puede seleccionar para copiarlo. Va donde el dato se usa
  /// afuera de la app (el correo, el sitio), no donde solo se lee.
  final bool selectable;

  /// Acciones propias del dato, cuando tiene alguna ademas de editarse (copiar
  /// el identificador, taparlo). Reemplazan al boton de editar.
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: icon,
    label: label,
    description: description,
    note: note,
    action: _action(context),
    child: _value(context)
  );

  /// Lo que vale el dato, o que no vale nada. El aviso va en gris y con
  /// palabras: un guion o un renglon en blanco se leen como que la ficha se
  /// rompio, no como que ese dato todavia no se cargo.
  Widget _value(BuildContext context) {
    if (value.isEmpty) {
      return TextMedium(
        S.of(context).business_profile_empty,
        color: ThemeColor.of(context).text.secondary
      );
    }

    return TextMedium(value, lines: 3, ellipsis: true, selectable: selectable);
  }

  Widget? _action(BuildContext context) {
    if (trailing != null) return trailing;
    if (field == null) return null;

    // Sobre una fila vacia el lapiz miente: no hay nada que corregir. La misma
    // accion, con el nombre y el icono de lo que de verdad va a pasar.
    return ProfileAction(
      icon: value.isEmpty ? CI.plus : CI.edit,
      message: _title(context),
      action: () => _edit(context)
    );
  }

  /// Como se llama la accion sobre el dato: cargarlo si no esta, cambiarlo si
  /// esta. Es el mensaje del boton y el titulo del formulario, que son la misma
  /// frase leida dos veces.
  String _title(BuildContext context) => value.isEmpty
    ? S.of(context).business_profile_add(label)
    : S.of(context).business_profile_edit(label);

  /// Abre el formulario del dato. Lo que cambie lo guarda el propio modal
  /// contra el servicio, que relee el perfil: aca no queda nada por hacer
  /// cuando se cierra.
  Future<void> _edit(BuildContext context) => showModal(
    context: context,
    title: _title(context),
    builder: (BuildContext context) => EditBusinessFieldModal(
      label: label,
      field: field!
    )
  );
}

/// Accion de un dato escrita con todas las letras.
///
/// Es para lo que no tiene un icono que se entienda solo: agregar un correo es
/// un mas, pero "volverlo el principal" no es ninguna forma. Un icono que hay
/// que adivinar —o apuntar con el raton para leer su tooltip— es peor que el
/// texto que iba a ahorrar.
///
/// Del alto de [ProfileAction] y con el mismo reposo apagado: conviven en la
/// misma fila, y uno de los dos mas alto o mas pintado se leeria como el
/// importante.
class ProfileTextAction extends StatelessWidget {
  const ProfileTextAction({
    super.key,
    required this.label,
    required this.action
  });

  /// Que hace el boton. Se lee dos veces: es su texto y tambien lo que le
  /// anuncia al lector de pantalla.
  final String label;

  final void Function() action;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return FeedbackButton(
      action: action,
      message: label,
      height: ProfileAction.size,
      padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS),
      radius: AppSize.cornerInset(AppSize.gap),
      color: scheme.surfaceOver,
      feedbackColor: scheme.line,
      // `min` para que el boton mida lo que mide su texto: en la fila de
      // acciones el ancho que llega es el que sobra, y una fila que se estira
      // lo tomaria entero.
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [TextSmall(label, color: scheme.primary)]
      )
    );
  }
}

/// Boton de una accion sobre un dato del perfil.
///
/// Es del tamaño del renglon y sin relleno hasta que se lo apunta: son uno por
/// fila y pintados todo el tiempo convertirian la ficha —que es para leer— en
/// una botonera. El color de reposo es el de la tarjeta, no transparente, para
/// que los dos extremos de la animacion de [FeedbackButton] sean opacos.
class ProfileAction extends StatelessWidget {
  const ProfileAction({
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
