import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:core/form.dart';

import 'profile_field.dart';

/// Desde cuando existe la empresa, cargada en tres campos: el año se escribe,
/// el mes se elige y el dia se escribe.
///
/// Antes era un solo campo de texto en el que habia que escribir `2019-05-03`,
/// con el formato explicado en una ayuda debajo. Nadie escribe una fecha asi:
/// se escribe como se dice, y lo que se cargaba —`3/5/2019`, `05-03-19`— el
/// backend lo rechazaba por formato sin que la ficha pudiera decir cual era el
/// formato bueno.
///
/// El mes es el unico de los tres que **se elige**, y no por capricho: es el
/// unico que no es un numero. Escrito como numero hay que saber si va antes o
/// despues del dia —que es justamente lo que cambia de pais a pais— y elegido
/// por su nombre esa pregunta no existe. Ademas es de donde sale cuantos dias
/// tiene la fecha, que es lo que se valida.
///
/// El orden es el de la fecha guardada (`YYYY-MM-DD`) y no el de ningun idioma:
/// los tres campos estan a la vista y cada uno dice que es, asi que no hay nada
/// que deducir del orden.
class BusinessProfileIncorporation extends StatefulWidget {
  const BusinessProfileIncorporation({super.key, required this.date});

  /// La fecha guardada, o `null` si la empresa todavia no la cargo.
  final DateTime? date;

  @override
  State<BusinessProfileIncorporation> createState() =>
    _BusinessProfileIncorporationState();
}

class _BusinessProfileIncorporationState
  extends State<BusinessProfileIncorporation> {
  final _form = FormController();

  /// Lo ultimo que el backend acepto, como viaja (`2019-05-03`) o vacio.
  late String _saved = _iso(widget.date);

  /// El mes elegido (`01`..`12`), o vacio.
  ///
  /// Se lleva aparte y no se le pregunta al desplegable por lo mismo que en el
  /// telefono: el desplegable resuelve que opcion le toca recien al montarse, y
  /// para entonces esta fila ya decidio si hay algo que guardar.
  late String _month = _pad(widget.date?.month);

  late final _year = InputController(
    key: "INCORPORATION_YEAR",
    form: _form,
    initial: widget.date == null ? "" : "${widget.date!.year}",
    pattern: "[0-9]",
    type: InputType.numeric,
    min: 4,
    max: 4,
    customErrors: _errors
  );

  late final _monthInput = InputController.select(
    key: "INCORPORATION_MONTH",
    form: _form,
    initial: _month
  );

  late final _day = InputController(
    key: "INCORPORATION_DAY",
    form: _form,
    initial: widget.date == null ? "" : _pad(widget.date!.day),
    pattern: "[0-9]",
    type: InputType.numeric,
    min: 1,
    max: 2,
    customErrors: _errors
  );

  /// Los errores nombran el dato como lo nombra la ficha: los tres campos son
  /// una sola fecha, asi que hablan de la fecha y no de "el año" o "el dia".
  Map<InputError, String> get _errors => {
    InputError.empty: S.of(context).form_empty_ma(
      S.of(context).business_profile_incorporation
    ),
    InputError.invalid: S.of(context).form_invalid_ma(
      S.of(context).business_profile_incorporation
    ),
    InputError.long: S.of(context).form_long_ma(
      S.of(context).business_profile_incorporation
    ),
    InputError.incomplete: S.of(context).form_incomplete_ma(
      S.of(context).business_profile_incorporation
    )
  };

  /// Si ya se escucha lo que se teclea. Una vez sola y no en `initState`: tocar
  /// los controladores es armarlos, y sus errores se escriben con el idioma de
  /// la app, que ahi todavia no se puede leer.
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_listening) return;
    _listening = true;

    // Escribir un digito puede hacer aparecer (o desaparecer) el boton de
    // guardar, asi que la fila se redibuja con cada tecla.
    _year.textController.addListener(_listener);
    _day.textController.addListener(_listener);
  }

  @override
  void didUpdateWidget(BusinessProfileIncorporation old) {
    super.didUpdateWidget(old);

    // El perfil se releyo y la fecha quedo en otra cosa: no fue esta fila (ahi
    // [_saved] ya estaria al dia), asi que se la alinea.
    if (_iso(widget.date) != _saved) {
      _saved = _iso(widget.date);
      _reset();
    }
  }

  @override
  void dispose() {
    if (_listening) {
      _year.textController.removeListener(_listener);
      _day.textController.removeListener(_listener);
    }

    _form.dispose();
    super.dispose();
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) => ProfileFieldFrame(
    icon: CI.calendar,
    label: S.of(context).business_profile_incorporation,
    action: _changed ? ProfileTextAction(
      label: S.of(context).save,
      action: _save
    ) : null,
    child: ConstrainedBox(
      constraints: BoxConstraints(maxWidth: AppSize.action * 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: AppSize.action * 2, child: Input(
            controller: _year,
            placeholder: S.of(context).business_profile_incorporation_year,
            radius: AppSize.cornerInset(AppSize.gap),
            onSubmit: _save
          )),
          SizedBox(width: AppSize.gap),
          // El mes se lleva el ancho que sobra: es el unico de los tres que
          // lleva una palabra y no dos digitos.
          Expanded(child: SelectInput(
            key: ValueKey("incorporation_month_$_saved"),
            controller: _monthInput,
            options: _months(context),
            placeholder: S.of(context).business_profile_incorporation_month,
            emptyText: S.of(context).business_profile_select_empty,
            radius: AppSize.cornerInset(AppSize.gap),
            buttonSpace: false,
            onSelected: (option) => setState(() => _month = option.value)
          )),
          SizedBox(width: AppSize.gap),
          SizedBox(width: AppSize.action * 1.8, child: Input(
            controller: _day,
            placeholder: S.of(context).business_profile_incorporation_day,
            radius: AppSize.cornerInset(AppSize.gap),
            onSubmit: _save
          ))
        ]
      )
    )
  );

  /// Los doce meses con su nombre, en el idioma de la app.
  ///
  /// Los nombres no los escribe esta app: los trae `intl`, con los datos que
  /// deja cargados `GlobalMaterialLocalizations` —el mismo lugar del que salen
  /// los nombres de los meses del calendario de Flutter—, asi que traducir la
  /// app no es escribir doce palabras mas.
  List<SelectOption> _months(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    final format = DateFormat.MMMM(locale);

    return [
      for (int month = 1; month <= 12; month++) SelectOption(
        value: _pad(month),
        placeholder: format.format(DateTime(2000, month))
      )
    ];
  }

  /// La fecha como viaja (`2019-05-03`), o vacio si los tres campos lo estan
  /// —que es como se borra— o si todavia no forman una fecha.
  String get _value {
    final year = _year.value.trim();
    final day = _day.value.trim();

    if (year.isEmpty || _month.isEmpty || day.isEmpty) return "";

    return "$year-$_month-${day.padLeft(2, "0")}";
  }

  bool get _changed => _value != _saved;

  Future<void> _save() async {
    if (!_changed) return;

    final value = _value;
    if (value.isNotEmpty && !_valid) return;

    _form.loading.value = true;

    final saved = await context.read<BusinessService>().editProfile(
      context,
      "INCORPORATION_DATE",
      value
    );

    if (!mounted) return;

    _form.loading.value = false;

    // Si fallo, el error ya lo mostro el servicio y lo escrito se queda en la
    // fila para corregirlo.
    if (!saved) return;

    setState(() => _saved = value);
  }

  /// Si los tres campos forman una fecha que existe.
  ///
  /// El largo y los digitos los mira el formulario; lo que no puede mirar es si
  /// la fecha **es una fecha**: el 31 de febrero pasa cualquier validacion de
  /// campo y no existe, y un año de cuatro digitos puede estar en el futuro.
  /// Cada error se marca en el campo que hay que corregir.
  bool get _valid {
    if (!_form.validate()) return false;

    final year = int.tryParse(_year.value.trim());
    final day = int.tryParse(_day.value.trim());

    // Una empresa no se constituyo el año que viene, y tampoco en el siglo XVI:
    // ahi lo que hay es un año mal tecleado.
    if (year == null || year < _minYear || year > DateTime.now().year) {
      _year.status.setStatus(InputStatus.error, InputError.invalid);
      return false;
    }

    final month = int.tryParse(_month);

    // El dia se valida contra **su** mes: `DateTime` no se queja de un 31 de
    // febrero, lo corre al 2 de marzo, asi que lo que se comprueba es que la
    // fecha que sale sea la que se escribio.
    final date = day == null || month == null
      ? null
      : DateTime(year, month, day);

    if (date == null || date.month != month || date.day != day) {
      _day.status.setStatus(InputStatus.error, InputError.invalid);
      return false;
    }

    return true;
  }

  /// El año mas viejo que se acepta. No hay empresas registradas aca de antes,
  /// y un año de tres cifras tecleado de mas es lo unico que llega por debajo.
  static const int _minYear = 1800;

  /// Deja los tres campos mostrando lo guardado.
  void _reset() {
    final date = widget.date;

    _year.textController.text = date == null ? "" : "${date.year}";
    _day.textController.text = date == null ? "" : _pad(date.day);

    _month = _pad(date?.month);
    _monthInput.selectedValue = _month.isEmpty ? null : _month;
  }

  /// La fecha como la espera el backend (`YYYY-MM-DD`), o vacio.
  static String _iso(DateTime? value) =>
    value == null ? "" : value.toIso8601String().split("T").first;

  /// Un numero de dos digitos, que es como viajan el mes y el dia.
  static String _pad(int? value) =>
    value == null ? "" : "$value".padLeft(2, "0");
}
