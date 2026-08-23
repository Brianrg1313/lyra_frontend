import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_email_model.dart';
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

/// Alta y edicion de una direccion de correo de la empresa.
///
/// Es el mismo formulario para las dos cosas porque son los mismos tres datos:
/// la direccion, para que es y como se la llama. Lo unico que cambia es si se
/// abre vacio ([email] en `null`) o con lo que hay guardado.
///
/// Cual es la principal no se decide aca: se promueve desde la ficha, sobre la
/// direccion que se quiere ascender, que es donde se ve cual lo es hoy.
///
/// Se cierra devolviendo `true` cuando el cambio entro. La lista no se
/// devuelve: el servicio ya releyo el perfil y la ficha se repinta sola.
class EditBusinessEmailModal extends StatefulWidget {
  const EditBusinessEmailModal({super.key, this.email});

  /// La direccion que se esta editando, o `null` para agregar una.
  final BusinessEmailModel? email;

  @override
  State<EditBusinessEmailModal> createState() => _EditBusinessEmailModalState();
}

class _EditBusinessEmailModalState extends State<EditBusinessEmailModal> {
  final _form = FormController();

  /// Lo que acepta `LABEL` en el backend. El guion va ultimo y sin escapar: en
  /// cualquier otro lugar seria un rango entre los dos caracteres que lo rodean.
  static const _labelPattern = "[A-Za-z0-9 .,&'()/+üÜñáéíóúÑÁÉÍÓÚ-]";

  late final _address = InputController(
    key: "EMAIL",
    form: _form,
    initial: widget.email?.email ?? "",
    type: InputType.email,
    pattern: "[A-Za-z0-9_@.-]",
    min: 6,
    max: 255,
    obligatory: true,
    customErrors: _errors(S.of(context).business_email_address)
  );

  late final _purpose = InputController.select(
    key: "PURPOSE",
    form: _form,
    initial: (widget.email?.purpose ?? BusinessEmailPurpose.general).value,
    obligatory: true,
    customErrors: _errors(S.of(context).business_email_purpose)
  );

  late final _label = InputController(
    key: "LABEL",
    form: _form,
    initial: widget.email?.label ?? "",
    pattern: _labelPattern,
    max: 64,
    customErrors: _errors(S.of(context).business_email_label)
  );

  Map<InputError, String> _errors(String field) => {
    InputError.empty: S.of(context).form_empty_ma(field),
    InputError.invalid: S.of(context).form_invalid_ma(field),
    InputError.long: S.of(context).form_long_ma(field),
    InputError.incomplete: S.of(context).form_incomplete_ma(field)
  };

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  /// El mismo ancho de base que el resto de los formularios del perfil: se
  /// abren desde las mismas filas y uno mas angosto que el anterior se lee como
  /// otro tipo de ventana. Ver la nota en `EditBusinessFieldModal`.
  static const double _width = 400;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Input(
          title: S.of(context).business_email_address,
          placeholder: S.of(context).business_email_address_hint,
          controller: _address,
          autofocus: true
        ),
        SizedBox(height: AppSize.spaceS),
        SelectInput(
          title: S.of(context).business_email_purpose,
          placeholder: S.of(context).business_profile_select,
          emptyText: S.of(context).business_profile_select_empty,
          controller: _purpose,
          options: [
            for (final purpose in BusinessEmailPurpose.values) SelectOption(
              value: purpose.value,
              placeholder: purpose.label(context)
            )
          ]
        ),
        SizedBox(height: AppSize.spaceS),
        Input(
          title: S.of(context).business_email_label,
          placeholder: S.of(context).business_email_label_hint,
          controller: _label,
          onSubmit: _submit
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).save,
          loading: _form.loading,
          action: _submit
        )
      ]
    )
  );

  Future<void> _submit() async {
    if (!_form.validate()) return;

    // Los valores se leen de los controladores y no de `_form.data`: ese solo
    // junta lo que quedo escrito, y un nombre borrado —que es sacarle el
    // nombre a la direccion— no llegaria nunca al backend.
    final data = {
      "EMAIL": _address.value.trim(),
      "PURPOSE": _purpose.value,
      "LABEL": _label.value.trim()
    };

    _form.loading.value = true;

    final service = context.read<BusinessService>();
    final current = widget.email;

    final saved = current == null
      ? await service.addEmail(context, data)
      : await service.editEmail(context, current.id, data);

    if (!mounted) return;

    _form.loading.value = false;

    // Si fallo, el error ya se mostro en el servicio: el modal se queda abierto
    // con lo escrito para corregirlo o cerrarlo a mano.
    if (!saved) return;

    // Sin aviso de guardado, como el resto de las escrituras del perfil: al
    // cerrarse el modal la lista ya trae la direccion nueva o corregida. Solo
    // se avisa lo que no se ve, que son los errores.
    Navigator.pop(context, true);
  }
}
