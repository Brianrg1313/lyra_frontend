import 'dart:async';

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

/// Verificacion de una de las direcciones de correo de la empresa.
///
/// Una direccion que alguien escribio es una afirmacion; verificarla es lo que
/// la convierte en un hecho. Se le manda un codigo a la casilla y leerlo **es**
/// la prueba: por eso el codigo nunca viaja en la respuesta y por eso este
/// modal no puede hacer nada por su cuenta.
///
/// Lo que se prueba es que la casilla existe y que la empresa la lee, no que la
/// empresa sea quien dice ser: eso es su situacion legal, la otorga el proceso
/// de verificacion y no se toca desde ninguna pantalla.
///
/// El codigo se pide al abrir y no con un boton: abrir esto ya es haber pedido
/// que se verifique, y un modal que arranca con un campo vacio y un aviso de
/// "primero pedi el codigo" es un paso que no decide nada. El reenvio si es un
/// boton, con el minuto de espera que impone el backend —es el unico lugar de
/// la ficha que le escribe a una direccion que tipeo alguien—.
///
/// Si el pedido falla el formulario se muestra igual. El caso mas comun es
/// justamente el rechazo por esperar: quiere decir que hace un momento se mando
/// uno, que sigue siendo valido, asi que lo que hay que hacer es escribirlo y
/// no volver a pedirlo.
///
/// Se cierra devolviendo `true` cuando la direccion quedo verificada. La lista
/// no se devuelve: el servicio ya releyo el perfil y la ficha se repinta sola.
class VerifyBusinessEmailModal extends StatefulWidget {
  const VerifyBusinessEmailModal({super.key, required this.email});

  /// La direccion que se esta verificando.
  final BusinessEmailModel email;

  @override
  State<VerifyBusinessEmailModal> createState() =>
    _VerifyBusinessEmailModalState();
}

class _VerifyBusinessEmailModalState extends State<VerifyBusinessEmailModal> {
  final _form = FormController();
  final _resending = ValueNotifier<bool>(false);

  /// Cuantos digitos tiene el codigo. Los que manda el backend.
  static const int _spaces = 6;

  /// Cuanto hay que esperar para pedir otro codigo. Es el mismo minuto que
  /// aplica el backend: contarlo aca no lo reemplaza —el que manda es el de
  /// alla— pero evita que el boton exista solo para ser rechazado.
  static const int _cooldown = 60;

  /// A donde se mando el codigo. Sale de la respuesta y no de lo que hay en
  /// pantalla: es la direccion **guardada**, asi que un tipeo se ve aca y no en
  /// la casilla de un desconocido.
  late String _sentTo = widget.email.email;

  Timer? _timer;
  int _left = _cooldown;

  late final _code = InputController.code(
    form: _form,
    spaces: _spaces,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).code_input),
      InputError.invalid: S.of(context).form_invalid_ma(
        S.of(context).code_input
      ),
      InputError.incomplete: S.of(context).form_incomplete_ma(
        S.of(context).code_input
      )
    }
  );

  @override
  void initState() {
    super.initState();

    // Despues del primer cuadro: pedir el codigo escribe en el servicio, y
    // hacerlo mientras se monta el arbol notifica a quien se esta montando.
    WidgetsBinding.instance.addPostFrameCallback((_) => _send());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _resending.dispose();
    _form.dispose();
    super.dispose();
  }

  /// Ancho de base, el mismo que el de los formularios del perfil: este modal
  /// se abre desde la misma fila que ellos. Es fijo porque el contenido —un
  /// codigo de seis casillas— mide mucho menos que la frase que lo explica.
  static const double _width = 400;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return ConstrainedBox(
      constraints: const BoxConstraints(minWidth: _width, maxWidth: _width),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextMedium(
            S.of(context).business_email_verify_sent,
            lines: 3,
            color: scheme.text.secondary
          ),
          SizedBox(height: AppSize.gap),
          // La direccion se puede seleccionar: si el codigo no llego, lo
          // primero que se hace es leerla letra por letra.
          TextMedium(_sentTo, bold: true, lines: 2, selectable: true),
          SizedBox(height: AppSize.spaceS),
          CodeInput(
            spaces: _spaces,
            autofocus: true,
            controller: _code,
            onEditingComplete: (_) => _submit()
          ),
          SizedBox(height: AppSize.gap),
          _resend(context, scheme),
          SizedBox(height: AppSize.spaceM),
          Button(
            title: S.of(context).business_email_verify,
            loading: _form.loading,
            action: _submit
          )
        ]
      )
    );
  }

  /// Pedir otro codigo, o cuanto falta para poder pedirlo. Mientras corre el
  /// minuto es un texto y no un boton apagado: un boton que no se puede tocar
  /// invita a tocarlo, y lo que hay que hacer en ese rato es mirar la casilla.
  Widget _resend(BuildContext context, SchemeColor scheme) {
    if (_left > 0) {
      return TextSmall(
        S.of(context).resend_code_timer(_time),
        textAlign: TextAlign.center,
        color: scheme.text.secondary
      );
    }

    return ValueListenableBuilder<bool>(
      valueListenable: _resending,
      builder: (context, busy, _) => FeedbackButton(
        action: busy ? null : _send,
        message: S.of(context).resend_code,
        height: AppSize.button,
        radius: AppSize.cornerInset(AppSize.gap),
        color: scheme.surface,
        feedbackColor: scheme.surfaceOver,
        child: Center(child: TextSmall(
          S.of(context).resend_code,
          color: busy ? scheme.text.secondary : scheme.primary
        ))
      )
    );
  }

  String get _time {
    final minutes = _left ~/ 60;
    final seconds = _left % 60;

    return "$minutes:${seconds.toString().padLeft(2, "0")}";
  }

  /// Pide el codigo. Es la misma llamada al abrir y al reenviar: lo unico que
  /// cambia es que la segunda vez ya hay algo en pantalla.
  Future<void> _send() async {
    _resending.value = true;

    final sent = await context.read<BusinessService>().sendEmailCode(
      context,
      widget.email.id
    );

    if (!mounted) return;

    _resending.value = false;

    // Si no se mando, el error ya se mostro y el formulario se queda como
    // estaba: puede haber un codigo anterior todavia vivo. El reloj arranca
    // igual, porque lo que impide pedir otro es el minuto del backend y ese
    // corre desde el ultimo envio, no desde el ultimo intento.
    setState(() {
      if (sent != null && sent.isNotEmpty) _sentTo = sent;
    });

    _countdown();
  }

  void _countdown() {
    _timer?.cancel();
    setState(() => _left = _cooldown);

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }

      if (_left <= 1) {
        timer.cancel();
        setState(() => _left = 0);
        return;
      }

      setState(() => _left--);
    });
  }

  Future<void> _submit() async {
    if (!_form.validate()) return;

    _form.loading.value = true;

    final verified = await context.read<BusinessService>().verifyEmail(
      context,
      widget.email.id,
      _code.value.trim()
    );

    if (!mounted) return;

    _form.loading.value = false;

    // El error ya lo mostro el servicio; aca solo se marca donde hay que
    // corregir, que es el unico campo que hay.
    if (!verified) {
      _code.status.setStatus(InputStatus.error, InputError.invalid);
      return;
    }

    // Sin aviso: al cerrarse el modal la etiqueta de la fila ya dice
    // "verificada", que es exactamente lo que la bandera iba a contar.
    Navigator.pop(context, true);
  }
}
