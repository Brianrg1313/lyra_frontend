import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';
import 'package:app/services/sign_in/login_method.dart';
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/button.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

/// El login son dos envios sobre la misma pantalla: primero el correo, y con lo
/// que responde el backend se sabe como se sigue. Solo la contraseña se pide
/// aca; el codigo se completa en `/login/code` y los OAuth todavia no hacen
/// nada.
class _DesktopBodyState extends State<DesktopBody> {
  final _form = FormController();

  late final _email = InputController.email(
    form: _form,
    obligatory: true,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(S.of(context).email_input),
      InputError.empty: S.of(context).form_empty_ma(S.of(context).email_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).email_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).email_input)
    }
  );

  late final _password = InputController.password(
    form: _form,
    obligatory: true
  );

  /// Correo del que el backend ya resolvio el metodo, y el metodo que resolvio.
  ///
  /// Se guarda el correo junto al metodo porque el campo se sigue pudiendo
  /// editar: mientras lo escrito sea este, el proximo envio completa el metodo;
  /// si cambia, se vuelve a preguntar en vez de mandar la contraseña a una
  /// cuenta distinta de la que la pidio.
  String? _resolved;
  LoginMethod? _method;

  bool get _askPassword => _method == LoginMethod.password;

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Skeleton.simple(
    padding: EdgeInsets.all(AppSize.spaceM),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextLarge(S.of(context).sign_in),
            Padding(
              padding: EdgeInsets.only(
                top: AppSize.gap,
                bottom: AppSize.action
              ),
              child: TextMedium(S.of(context).sign_in_subtitle)
            ),
            Input(
              placeholder: S.of(context).email_input,
              controller: _email,
              next: _askPassword ? _password.focus : null,
              onSubmit: _askPassword ? null : _submit
            ),
            if (_askPassword)
              Input(
                autofocus: true,
                placeholder: S.of(context).password_input,
                controller: _password,
                onSubmit: _submit
              ),
            SizedBox(height: AppSize.padding),
            Button(
              title: _askPassword ? S.of(context).login : S.of(context).next,
              loading: _form.loading,
              action: _submit
            ),
            SizedBox(height: AppSize.action),
            FeedbackButton(
              color: ThemeColor.of(context).surface.withAlpha(0),
              action: () => Navis.push(context, "/sign_up"),
              feedbackColor: ThemeColor.of(context).surface,
              padding: EdgeInsets.symmetric(
                vertical: AppSize.spaceXS,
                horizontal: AppSize.spaceS
              ),
              child: TextMedium(
                S.of(context).dont_have_account,
                color: ThemeColor.of(context).primary
              )
            )
          ])
      )
    )
  );

  void _submit() {
    if (_askPassword && _email.value == _resolved) return _signIn();

    _resolve();
  }

  /// Primer paso. Valida solo el correo: el campo de contraseña puede seguir en
  /// pantalla de un correo anterior y todavia vacio, y no es lo que se manda.
  void _resolve() {
    if (!_email.validate(_email)) return;

    _form.loading.value = true;

    final email = _email.value;

    context.read<SignInService>().resolveMethod(context, email)
      .then((method) {
        if (!mounted) return;
        _form.loading.value = false;

        // Google, Apple y Facebook llegan hasta aca pero todavia no estan
        // implementados: no hay pantalla a la que llevar ni nada mas que pedir,
        // asi que el login se queda como esta.
        if (method == null || !method.isAvailable) return;

        if (method == LoginMethod.code) {
          Navis.push(context, "/login/code");
          return;
        }

        setState(() {
          _method = method;
          _resolved = email;
        });
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;

        // El backend responde lo mismo para un correo no registrado que para
        // uno sin metodo configurado —a proposito, para que no se puedan
        // averiguar correos registrados—, asi que lo unico que se puede marcar
        // es el correo.
        _email.status.setStatus(InputStatus.error, InputError.invalid);
      });
  }

  /// Segundo paso cuando el metodo es contraseña.
  void _signIn() {
    if (!_form.validate()) return;

    _form.loading.value = true;

    final client = context.read<ClientService>();

    context.read<SignInService>().signInWithPassword(context, _email.value, _password.value)
      // El token ya quedo guardado, pero `resolve` solo corre al arrancar la
      // app: sin esto la instancia global entraria al home sin cliente cargado
      // y los widgets del side bar leerian una sesion vacia.
      .then((_) => client.resolve())
      .then((redirect) {
        if (!mounted) return;
        _form.loading.value = false;
        Navis.pushAndClearStack(context, redirect ?? "/home");
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;

        _password.status.setStatus(InputStatus.error, InputError.invalid);
      });
  }
}
