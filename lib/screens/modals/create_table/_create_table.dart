import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/products/table_request.dart';
import 'package:app/services/stock/tables/tables_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/buttons.dart';

/// Alta de una tabla de productos. Reemplaza a la vieja sub-pagina de creacion:
/// ahora la tabla se crea vacia, solo con su cabecera (titulo, descripcion y
/// color), y las columnas se definen despues.
///
/// Es un modal y no una pantalla porque el formulario es corto y de tamaño fijo.
/// Se abre desde el listado de tablas ([ProductTablesSection]) y, al cerrarse,
/// el listado se recarga para mostrar la tabla nueva.
class CreateTableModal extends StatefulWidget {
  const CreateTableModal({super.key});

  @override
  State<CreateTableModal> createState() => _CreateTableModalState();
}

class _CreateTableModalState extends State<CreateTableModal> {
  final _form = FormController();

  /// Letras (con tildes y dieresis), digitos, espacios y la puntuacion que
  /// suele llevar el nombre de una tabla: `Precio (IVA inc.)`, `Talla / Color`.
  static const _namePattern = "[A-Za-zÀ-ÖØ-öø-ÿ0-9 '&.,()/\\-]";

  late final _title = InputController(
    key: "TITLE",
    form: _form,
    pattern: _namePattern,
    min: 3,
    max: 60,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).table_title_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).table_title_input),
      InputError.long: S.of(context).form_long_ma(S.of(context).table_title_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).table_title_input)
    }
  );

  /// Descripcion opcional: sin `obligatory`, solo se valida el largo.
  late final _description = InputController(
    key: "DESCRIPTION",
    form: _form,
    max: 240,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(S.of(context).table_description_title)
    }
  );

  /// Paleta de la que sale el color de la tabla. Son los codigos que viajan al
  /// backend y no se traducen: literales ARGB de Flutter (`0x` mas 8 digitos
  /// hex, con el alpha adelante), que es el unico formato que acepta el alta.
  static const _palette = <String>[
    "0xFFF87171", // rojo
    "0xFFEF4444", // rojo intenso
    "0xFFFB923C", // naranja
    "0xFFF59E0B", // ambar oscuro
    "0xFFFBBF24", // ambar
    "0xFF34D399", // verde
    "0xFF10B981", // esmeralda
    "0xFF14B8A6", // verde azulado
    "0xFF22D3EE", // cyan
    "0xFF60A5FA", // azul
    "0xFF3B82F6", // azul intenso
    "0xFF818CF8", // indigo
    "0xFF8B5CF6", // violeta intenso
    "0xFFA78BFA", // violeta
    "0xFFF472B6", // rosa
    "0xFFEC4899", // rosa intenso
    "0xFF94A3B8", // gris
    "0xFF64748B"  // gris oscuro
  ];

  /// Color elegido. Arranca con el primero puesto para que el alta siempre lleve
  /// uno y no haya un estado "sin color".
  String _color = _palette.first;

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
          child: TextMedium(S.of(context).create_table_subtitle)
        ),
        Input(
          title: S.of(context).table_title_input,
          placeholder: S.of(context).table_title_placeholder,
          controller: _title,
          leftIcon: Icon(CI.list, color: ThemeColor.of(context).icon),
          next: _description.focus
        ),
        Input(
          title: S.of(context).table_description_title,
          placeholder: S.of(context).table_description_placeholder,
          controller: _description,
          leftIcon: Icon(CI.pen, color: ThemeColor.of(context).icon)
        ),
        SizedBox(height: AppSize.spaceXS),
        _colorSelector(context),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).create_table,
          loading: _form.loading,
          action: _submit
        )
      ])
  );

  /// Selector de color: la etiqueta y, debajo, la paleta de swatches. El
  /// seleccionado se marca con un anillo y un tilde.
  Widget _colorSelector(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      TextSmall(
        S.of(context).table_color_title,
        color: ThemeColor.of(context).text.secondary
      ),
      SizedBox(height: AppSize.gap),
      Wrap(
        spacing: AppSize.spaceS,
        runSpacing: AppSize.spaceS,
        children: [
          for (final color in _palette) _Swatch(
            color: color,
            selected: color == _color,
            onTap: () => setState(() => _color = color)
          )
        ]
      )
    ]
  );

  void _submit() {
    if (!_form.validate()) return;

    _form.loading.value = true;

    context.read<TablesService>().create(context, _payload())
      .then((_) {
        if (!mounted) return;
        _form.loading.value = false;
        FloatFlag.of(context).message(S.of(context).table_created);
        Navigator.pop(context);
      })
      .catchError((_) {
        // El error ya se mostro en el servicio; aca solo se suelta el boton.
        if (!mounted) return;
        _form.loading.value = false;
      });
  }

  /// Cuerpo de la peticion. Los textos se leen de los controladores; el color,
  /// del estado del selector.
  Map<String, dynamic> _payload() => createTableRequest(
    title: _title.value,
    description: _description.value,
    color: _color
  );
}

/// Circulo de un color de la paleta. Cuando esta [selected] lo rodea un anillo
/// del color de texto principal y le aparece un tilde encima.
class _Swatch extends StatelessWidget {
  const _Swatch({
    required this.color,
    required this.selected,
    required this.onTap
  });

  /// Literal ARGB del color, tal como viaja al backend (`0xFF60A5FA`).
  final String color;
  final bool selected;
  final void Function() onTap;

  @override
  Widget build(BuildContext context) {
    final swatch = _parse(color);

    return FeedbackButton(
      action: onTap,
      width: AppSize.action,
      height: AppSize.action,
      message: color,
      child: Center(child: Container(
        width: AppSize.action * .7,
        height: AppSize.action * .7,
        decoration: BoxDecoration(
          color: swatch,
          shape: BoxShape.circle,
          border: selected
            ? Border.all(color: ThemeColor.of(context).text.primary, width: 2)
            : null
        ),
        child: selected
          ? const Center(child: Icon(Icons.check, color: Colors.white, size: 16))
          : null
      ))
    );
  }

  /// Convierte el literal ARGB (`0xFFRRGGBB`) a un [Color]. `int.tryParse`
  /// entiende el prefijo `0x` sin pasarle `radix`. Ante un formato inesperado
  /// cae a gris, para no reventar el pintado por un color mal formado.
  static Color _parse(String argb) {
    final parsed = int.tryParse(argb);
    if (parsed == null) return const Color(0xFF94A3B8);
    return Color(parsed);
  }
}
