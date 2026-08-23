import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

import 'business_field.dart';

/// Cambia **un** dato del perfil de la empresa.
///
/// Es un formulario de un solo campo a proposito: el perfil se corrige donde se
/// lo lee —se toca el renglon que esta mal y se escribe—, no abriendo el
/// formulario entero para cambiar el telefono. Lo que se guarda es solo ese
/// campo (ver [BusinessService.editProfile]).
///
/// No sabe que dato esta editando: lo describe quien lo abre ([field]) y de ahi
/// sale todo —que forma tiene, cuanto mide, si puede quedar vacio—. Agregar un
/// dato de texto a la ficha no es tocar este modal.
///
/// Solo los datos que se **escriben** llegan aca. Los que se eligen de una lista
/// cerrada (el sector, el idioma, la moneda) se cambian en su propia fila, sin
/// modal: elegir no necesita ni teclado ni boton de guardar (ver
/// `ProfileSelectField`).
///
/// Se cierra devolviendo `true` cuando el cambio entro. El perfil no se
/// devuelve: el servicio ya lo releyo y la ficha se repinta sola.
class EditBusinessFieldModal extends StatefulWidget {
  const EditBusinessFieldModal({
    super.key,
    required this.label,
    required this.field
  });

  /// Como se llama el dato en la ficha. Es el titulo del campo y con lo que se
  /// arman los errores, asi que el formulario habla del mismo dato que la fila
  /// desde la que se abrio.
  final String label;

  final BusinessField field;

  @override
  State<EditBusinessFieldModal> createState() => _EditBusinessFieldModalState();
}

class _EditBusinessFieldModalState extends State<EditBusinessFieldModal> {
  final _form = FormController();

  /// El controlador se arma con lo que dice el dato: lo que hay guardado abre
  /// el campo lleno, y el resto —la forma, el largo, si es obligatorio— es lo
  /// que se valida al guardar.
  late final _input = InputController(
    key: widget.field.key,
    form: _form,
    initial: widget.field.value,
    pattern: widget.field.pattern,
    type: widget.field.type,
    min: widget.field.min,
    max: widget.field.max,
    obligatory: widget.field.obligatory,
    customErrors: _errors
  );

  /// Los errores nombran el dato como lo nombra la ficha, no con un texto por
  /// campo: son los mismos cuatro de siempre y lo unico que cambia es de que
  /// estan hablando.
  Map<InputError, String> get _errors => {
    InputError.empty: S.of(context).form_empty_ma(widget.label),
    InputError.invalid: S.of(context).form_invalid_ma(widget.label),
    InputError.long: S.of(context).form_long_ma(widget.label),
    InputError.incomplete: S.of(context).form_incomplete_ma(widget.label)
  };

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// Ancho del formulario. Es fijo y no un maximo porque el modal se ajusta a
  /// lo que mide su contenido (ver `ModalDesktop`), y un campo de un dato corto
  /// —un telefono, un codigo postal— lo dejaba mas angosto que su propio
  /// titulo. Con un ancho de base todos los datos se editan en la misma caja,
  /// midan lo que midan. En ventana chica el dialogo lo recorta solo.
  static const double _width = 400;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Input(
          title: widget.label,
          placeholder: widget.field.hint ?? widget.label,
          controller: _input,
          autofocus: true,
          onSubmit: _submit
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).save,
          loading: _form.loading,
          action: _submit
        )
      ])
  );

  Future<void> _submit() async {
    if (!_form.validate()) return;

    // El valor se lee del controlador y no de `_form.data`: ese solo junta lo
    // que quedo escrito, y un campo vaciado —que es borrar el dato— no llegaria
    // nunca al backend.
    final value = _input.value;

    // Nada que guardar. Se cierra sin escribir: una peticion y una relectura
    // del perfil para dejar todo como estaba es peor que no hacer nada.
    if (value.trim() == widget.field.value.trim()) {
      Navigator.pop(context);
      return;
    }

    _form.loading.value = true;

    final saved = await context.read<BusinessService>().editProfile(
      context,
      widget.field.key,
      value
    );

    if (!mounted) return;

    _form.loading.value = false;

    // Si fallo, el error ya se mostro en el servicio: el modal se queda abierto
    // con lo escrito para corregirlo o cerrarlo a mano.
    if (!saved) return;

    // Sin aviso de guardado: el modal se cierra y la fila de atras ya muestra
    // el valor nuevo. Anunciar lo que se esta viendo es una bandera que tapa
    // parte de la ficha para contar algo que la ficha ya conto. Las banderas
    // del perfil quedan para lo que **no** se ve: los errores.
    Navigator.pop(context, true);
  }
}
