import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/business/business_profile_model.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

import 'notice.dart';

class CreateBusinessModal extends StatefulWidget {
  const CreateBusinessModal({super.key});

  @override
  State<CreateBusinessModal> createState() => _CreateBusinessModalState();
}

class _CreateBusinessModalState extends State<CreateBusinessModal> {
  final _form = FormController();

  /// Letras (con tildes y dieresis), N/n, digitos y la puntuacion habitual de
  /// una razon social: `Acme S.A.`, `Foo & Bar, Ltd.`
  static const _legalNamePattern = "[A-Za-zÀ-ÖØ-öø-ÿ0-9 '&.,\\-]";

  late final _legalName = InputController(
    key: "LEGAL_NAME",
    form: _form,
    pattern: _legalNamePattern,
    min: 3,
    max: 100,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).business_legal_name_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).business_legal_name_input),
      InputError.long: S.of(context).form_long_ma(S.of(context).business_legal_name_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).business_legal_name_input)
    }
  );

  late final _type = InputController.select(
    key: "ACTIVITY_TYPE",
    form: _form,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).business_type_input)
    }
  );

  /// Los sectores salen de [BusinessActivity] y no de una lista escrita aca: es
  /// la misma que traduce el perfil cuando el backend devuelve el sector, asi
  /// que lo que se elige al crear la empresa se lee despues con ese nombre.
  ///
  /// El `value` viaja al backend y no se traduce; solo el `placeholder` es
  /// localizable.
  late final _types = [
    for (final activity in BusinessActivity.catalog)
      SelectOption(value: activity.value, placeholder: activity.label(context))
  ];

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 380),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: EdgeInsets.only(bottom: AppSize.spaceS),
          child: TextMedium(S.of(context).create_business_subtitle)
        ),
        Input(
          placeholder: S.of(context).business_legal_name_input,
          title: S.of(context).business_legal_name_input,
          controller: _legalName,
          leftIcon: Icon(CI.store, color: ThemeColor.of(context).icon),
          next: _type.focus
        ),
        SelectInput(
          placeholder: S.of(context).business_type_placeholder,
          title: S.of(context).business_type_input,
          emptyText: S.of(context).business_type_empty,
          controller: _type,
          options: _types
        ),
        SizedBox(height: AppSize.spaceXS),
        const CreateBusinessNotice(),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).create_business,
          loading: _form.loading,
          action: _submit
        )
      ])
  );

  void _submit() {
    if (!_form.validate()) return;

    _form.loading.value = true;

    context.read<BusinessService>().createBusiness(context, _form.data)
      .then((_) {
        if (!mounted) return;
        _form.loading.value = false;
        Navigator.pop(context);
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;
      });
  }
}
