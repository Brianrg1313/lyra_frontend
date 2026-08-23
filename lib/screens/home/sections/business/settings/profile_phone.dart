import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';
import 'package:app/services/catalog/country_catalog_service.dart';

// WIDGETS
import 'package:core/form.dart';

import 'country_flag.dart';
import 'profile_field.dart';

/// El telefono de la empresa: el codigo de pais se elige y el numero se
/// escribe.
///
/// Son dos campos y no uno porque son dos datos distintos con dos formas
/// distintas de cargarse. El codigo es una lista cerrada —los paises que la
/// plataforma tiene habilitados— y nadie se acuerda del de ningun pais que no
/// sea el suyo; el numero es lo unico que de verdad hay que teclear. Escritos
/// juntos en un campo de texto, lo que pasaba era lo de siempre: se cargaba el
/// numero sin codigo, o con `(0212)`, o con espacios, y el backend lo rechazaba
/// —solo acepta digitos y un `+` (`0-9+`, hasta 16)— sin que la ficha supiera
/// explicar por que.
///
/// El codigo se muestra con la bandera del pais, que es como se lo reconoce:
/// `+58` es Venezuela para quien ya lo sabe, la bandera lo es para todos.
///
/// Se guarda con un boton y no al terminar de escribir, al reves que los otros
/// datos que se eligen ([ProfileSelectField]): un numero a medio teclear es un
/// numero valido para cualquier validacion, asi que guardar solo porque el
/// campo perdio el foco mandaria telefonos partidos. El boton aparece cuando
/// hay algo distinto de lo guardado, y desaparece cuando no.
class BusinessProfilePhone extends StatefulWidget {
  const BusinessProfilePhone({
    super.key,
    required this.phone,
    required this.country
  });

  /// El telefono tal como esta guardado (`+584121234567`), o vacio.
  final String phone;

  /// El pais donde opera la empresa. Es de donde sale el codigo propuesto
  /// cuando la empresa todavia no cargo ningun telefono: el de su pais es el
  /// que va a querer casi siempre.
  final String country;

  @override
  State<BusinessProfilePhone> createState() => _BusinessProfilePhoneState();
}

class _BusinessProfilePhoneState extends State<BusinessProfilePhone> {
  final _form = FormController();

  /// Lo ultimo que el backend acepto. Es contra lo que se compara para saber si
  /// hay algo que guardar, y a lo que se vuelve si el envio falla.
  late String _saved = widget.phone;

  /// El pais elegido en el desplegable.
  ///
  /// Se lleva aparte y no se le pregunta al controlador del campo: el
  /// desplegable resuelve que opcion le toca recien al montarse, y para
  /// entonces esta fila ya decidio —en el mismo build— si hay algo que
  /// guardar. Preguntandole a el, la ficha abria con el boton de guardar
  /// puesto sin que nadie hubiera tocado nada.
  late String _dial = _initialCode;

  /// El pais del telefono guardado, o el de la empresa si el telefono no trae
  /// codigo (o no hay telefono todavia).
  late final _code = InputController.select(
    key: "PHONE_CODE",
    form: _form,
    initial: _initialCode
  );

  late final _number = InputController(
    key: "PHONE_NUMBER",
    form: _form,
    initial: _split.number,
    pattern: "[0-9]",
    type: InputType.numeric,
    min: 4,
    // El backend acepta 16 caracteres contando el `+`, y el codigo de pais se
    // lleva hasta tres. Es el mismo tope que pone E.164 al numero entero.
    max: 12,
    customErrors: _errors
  );

  /// Los errores nombran el dato como lo nombra la ficha. Son los de siempre:
  /// lo unico que cambia es de que estan hablando.
  Map<InputError, String> get _errors => {
    InputError.empty: S.of(context).form_empty_ma(
      S.of(context).business_profile_phone
    ),
    InputError.invalid: S.of(context).form_invalid_ma(
      S.of(context).business_profile_phone
    ),
    InputError.long: S.of(context).form_long_ma(
      S.of(context).business_profile_phone
    ),
    InputError.incomplete: S.of(context).form_incomplete_ma(
      S.of(context).business_profile_phone
    )
  };

  String get _initialCode {
    final country = CountryCatalogService().byPhone(widget.phone);
    if (country != null) return country.code;

    // Sin telefono guardado no se propone nada si el pais tampoco esta: un
    // codigo puesto solo es un dato que nadie cargo.
    return widget.phone.isEmpty ? widget.country : "";
  }

  ({String dial, String number}) get _split =>
    CountryCatalogService().splitPhone(widget.phone);

  /// Si ya se escucha lo que se teclea. Es una vez sola, y no en `initState`:
  /// tocar [_number] es armarlo, y sus errores se escriben con el idioma de la
  /// app, que ahi todavia no se puede leer.
  bool _listening = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    if (_listening) return;
    _listening = true;

    // Escribir un digito puede hacer aparecer (o desaparecer) el boton de
    // guardar, asi que la fila se redibuja con cada tecla.
    _number.textController.addListener(_listener);
  }

  @override
  void didUpdateWidget(BusinessProfilePhone old) {
    super.didUpdateWidget(old);

    // El perfil se releyo y el telefono quedo en otra cosa: no fue esta fila
    // (ahi [_saved] ya estaria al dia), asi que se la alinea.
    if (widget.phone != _saved) {
      _saved = widget.phone;
      _reset();
    }
  }

  @override
  void dispose() {
    if (_listening) _number.textController.removeListener(_listener);
    _form.dispose();
    super.dispose();
  }

  void _listener() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    // Se observa el catalogo: si se habilita una region con la ficha abierta,
    // su codigo aparece en la lista sin recargar nada.
    final catalog = context.watch<CountryCatalogService>();

    return ProfileFieldFrame(
      icon: CI.phone,
      label: S.of(context).business_profile_phone,
      description: S.of(context).business_profile_phone_note,
      action: _changed ? ProfileTextAction(
        label: S.of(context).save,
        action: _save
      ) : null,
      child: ConstrainedBox(
        // Mas ancha que las otras filas de la ficha porque son dos campos y no
        // uno: con el ancho de un campo solo, el numero —que es lo que de
        // verdad se escribe— quedaba mas angosto que el codigo.
        constraints: BoxConstraints(maxWidth: AppSize.action * 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(width: _codeWidth, child: SelectInput(
              key: ValueKey("phone_code_$_saved"),
              controller: _code,
              options: _options(catalog),
              placeholder: S.of(context).business_profile_phone_code,
              emptyText: S.of(context).business_profile_select_empty,
              radius: AppSize.cornerInset(AppSize.gap),
              buttonSpace: false,
              onSelected: (option) => setState(() => _dial = option.value)
            )),
            SizedBox(width: AppSize.gap),
            Expanded(child: Input(
              controller: _number,
              placeholder: S.of(context).business_profile_phone_number,
              radius: AppSize.cornerInset(AppSize.gap),
              onSubmit: _save
            ))
          ]
        )
      )
    );
  }

  /// Ancho de la lista de codigos: lo que miden la bandera, el codigo mas largo
  /// (`+507`) y la flecha, y nada mas.
  ///
  /// Es a proposito mucho mas angosto que el numero. Los dos campos no valen lo
  /// mismo: el codigo son tres digitos que se eligen una vez y el numero es lo
  /// unico que se teclea, asi que el ancho tiene que decir cual de los dos es
  /// el dato. Ademas es el ancho del desplegable que cuelga de el, y de ahi que
  /// no sea todavia mas chico: los nombres de los paises se leen ahi.
  static double get _codeWidth => AppSize.action * 2.6;

  /// Un codigo por pais habilitado, con su bandera. El dial es lo que se lee en
  /// el campo cerrado y el nombre lo que se busca al elegir.
  List<SelectOption> _options(CountryCatalogService catalog) => [
    for (final country in catalog.countries)
      if (country.phone.isNotEmpty) SelectOption(
        value: country.code,
        placeholder: country.dial,
        subtitle: country.name,
        leading: CountryFlag(country: country)
      )
  ];

  /// El telefono como viaja: `+` , codigo y numero, sin nada en el medio.
  ///
  /// Sin numero no hay telefono aunque haya codigo: se manda vacio, que es como
  /// se borra el dato. Sin codigo se manda lo escrito tal cual —es lo que hacia
  /// el campo de texto de antes—, en vez de inventar un pais.
  String get _value {
    final number = _number.value.trim();
    if (number.isEmpty) return "";

    final dial = CountryCatalogService().byCode(_dial)?.phone;
    if (dial == null || dial.isEmpty) return number;

    return "+$dial$number";
  }

  bool get _changed => _value != _saved;

  Future<void> _save() async {
    if (!_changed) return;

    // Un numero vacio es borrar el telefono, y eso se puede: casi todo el
    // perfil es opcional. Lo que no se manda es un numero a medio escribir.
    final value = _value;
    if (value.isNotEmpty && !_form.validate()) return;

    _form.loading.value = true;

    final saved = await context.read<BusinessService>().editProfile(
      context,
      "PHONE",
      value
    );

    if (!mounted) return;

    _form.loading.value = false;

    // Si fallo, el error ya lo mostro el servicio y lo escrito se queda en la
    // fila para corregirlo: volver atras lo tecleado seria perderlo dos veces.
    if (!saved) return;

    setState(() => _saved = value);
  }

  /// Deja los dos campos mostrando lo guardado.
  void _reset() {
    _number.textController.text = CountryCatalogService()
      .splitPhone(_saved)
      .number;

    _dial = _initialCode;
    _code.selectedValue = _dial;
  }
}
