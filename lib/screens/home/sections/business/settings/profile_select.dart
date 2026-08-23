import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:app/screens/modals/edit_business_field/business_field.dart';

import 'profile_field.dart';

/// Un dato del perfil que se elige de una lista cerrada —el sector, el idioma,
/// la moneda—, con el desplegable en el lugar del valor.
///
/// Elegir no es escribir: no hay nada que redactar, ni que validar, ni un error
/// que leer debajo. Abrir un modal para eso es tres pasos (abrir, elegir,
/// guardar) donde solo hay uno, y encima tapa la ficha desde la que se estaba
/// mirando el resto. Aca la opcion elegida **es** el valor que se lee, y
/// tocarla despliega las otras en el mismo sitio.
///
/// Por eso tampoco lleva boton de guardar: elegir una opcion es el cambio, asi
/// que se manda ahi mismo. Mientras viaja, el campo queda deshabilitado —lo
/// hace [FormController.loading]— para que no se elija otra cosa encima de la
/// que todavia no se guardo.
///
/// Si el guardado falla, el desplegable vuelve a lo que habia: el error ya lo
/// muestra el servicio, y dejar en pantalla una opcion que el backend no acepto
/// es la unica forma de que la ficha mienta.
class ProfileSelectField extends StatefulWidget {
  const ProfileSelectField({
    super.key,
    required this.icon,
    required this.label,
    required this.field,
    this.description
  });

  final IconData icon;
  final String label;

  /// El dato: con que clave viaja, que hay elegido hoy y entre que opciones.
  final BusinessField field;

  final String? description;

  @override
  State<ProfileSelectField> createState() => _ProfileSelectFieldState();
}

class _ProfileSelectFieldState extends State<ProfileSelectField> {
  final _form = FormController();

  /// El `initial` es el codigo guardado (`RETAIL`) y no la etiqueta que se lee:
  /// [SelectInput] lo traduce a su opcion al montarse.
  late final _input = InputController.select(
    key: widget.field.key,
    form: _form,
    initial: widget.field.value,
    obligatory: true
  );

  /// Lo ultimo que el backend acepto. Es contra lo que se compara para saber si
  /// hay algo que mandar, y a lo que se vuelve si el envio falla.
  late String _saved = widget.field.value;

  /// Cambia cada vez que hay que rearmar el desplegable con lo que dice el
  /// controlador: al volver atras un envio fallido, o cuando el dato cambio por
  /// fuera de esta fila. [SelectInput] se sincroniza al montarse, asi que la
  /// unica forma de que relea el valor es que sea otro widget.
  int _revision = 0;

  @override
  void didUpdateWidget(ProfileSelectField old) {
    super.didUpdateWidget(old);

    // El perfil se releyo y este dato quedo en otra cosa: no fue este
    // desplegable (ahi [_saved] ya estaria al dia), asi que se lo alinea. Sin
    // `setState`: el rebuild viene inmediatamente despues de esto.
    if (widget.field.value != _saved) _reset(widget.field.value);
  }

  @override
  void dispose() {
    // El form es de esta fila, asi que libera al controlador con el. El
    // desplegable no lo toca: no es suyo, se lo prestamos.
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: widget.icon,
    label: widget.label,
    description: widget.description,
    child: ConstrainedBox(
      // El desplegable no se estira con la columna: es una lista de opciones
      // cortas (un idioma, un codigo de moneda) y un campo del ancho de la
      // ficha deja la etiqueta sola en un extremo y la flecha en el otro.
      constraints: BoxConstraints(maxWidth: _fieldWidth),
      child: SelectInput(
        key: ValueKey("${widget.field.key}_${_saved}_$_revision"),
        controller: _input,
        options: widget.field.options,
        placeholder: S.of(context).business_profile_select,
        emptyText: S.of(context).business_profile_select_empty,
        radius: AppSize.cornerInset(AppSize.gap),
        // Sin hueco para el error debajo: lo unico que puede salir mal aca es
        // el envio, y eso se avisa con la bandera flotante como el resto de las
        // escrituras del perfil.
        buttonSpace: false,
        onSelected: _save
      )
    )
  );

  /// Ancho del desplegable. Es el de un campo de formulario, no el de la
  /// columna: asi mide lo mismo en la ficha ancha y en la angosta, y las tres
  /// listas del perfil quedan alineadas entre si.
  static double get _fieldWidth => AppSize.action * 6;

  Future<void> _save(SelectOption option) async {
    // Volver a elegir lo mismo no es un cambio: se evita el viaje y la
    // relectura del perfil que lo dejaria todo igual.
    if (option.value == _saved) return;

    final service = context.read<BusinessService>();

    _form.loading.value = true;

    final saved = await service.editProfile(
      context,
      widget.field.key,
      option.value
    );

    if (!mounted) return;

    _form.loading.value = false;

    if (!saved) {
      setState(() => _reset(_saved));
      return;
    }

    // Sin aviso de guardado: la opcion elegida se quedo en el desplegable, que
    // es donde se estaba mirando. Lo que si se avisa es el fallo, y de eso se
    // encarga el servicio.
    setState(() => _saved = option.value);
  }

  /// Deja el desplegable mostrando [value]: se lo escribe al controlador y se
  /// lo rearma, que es lo unico que hace que vuelva a leerlo.
  void _reset(String value) {
    _saved = value;
    _input.selectedValue = value;
    _revision++;
  }
}
