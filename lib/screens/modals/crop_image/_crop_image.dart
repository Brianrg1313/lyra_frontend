import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
// La rueda del raton llega como una señal de puntero, y eso no lo exporta
// `material.dart`: sin esto no existen ni `PointerSignalEvent` ni el evento de
// scroll que se mira adentro.
import 'package:flutter/gestures.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:core/button.dart';

/// Recorta una imagen antes de subirla: se elige que parte de ella se ve y con
/// cuanto acercamiento, y lo que sale es ese cuadrado y nada mas.
///
/// Se recorta **aca y no del otro lado** porque el encuadre es una decision de
/// quien sube la foto, no del servidor: una foto apaisada metida a la fuerza en
/// un cuadrado deja afuera la mitad de la imagen, y cual mitad es justamente lo
/// unico que el backend no puede adivinar. Lo que se manda ya viene resuelto,
/// asi que la empresa ve antes de subir exactamente el logo que va a quedar.
///
/// El marco **es** el recorte: lo que se ve es lo que se guarda. No hay una
/// ventana movible sobre una imagen quieta sino al reves —la imagen se mueve
/// bajo una ventana fija—, que es como se encuadra en cualquier camara y no
/// obliga a acertarle a un rectangulo con el raton.
///
/// Abre centrada y llenando el marco (nunca con bordes vacios), asi que aceptar
/// sin tocar nada ya da un recorte razonable: el ajuste es para el que lo
/// necesita, no un tramite para el que no.
///
/// Devuelve los bytes del recorte en PNG por [Navigator.pop], o nada si se
/// cierra sin aceptar. No sube nada ni sabe para que es la imagen: eso es de
/// quien lo abre.
class CropImageModal extends StatefulWidget {
  const CropImageModal({super.key, required this.bytes, this.output = 512});

  /// La imagen tal como se eligio, sin tocar.
  final Uint8List bytes;

  /// Lado maximo del recorte, en pixeles. No se agranda nada para llegar a el:
  /// un logo chico sale chico, que es preferible a salir borroso.
  final int output;

  @override
  State<CropImageModal> createState() => _CropImageModalState();
}

class _CropImageModalState extends State<CropImageModal> {
  /// Lado del marco en pantalla. Es fijo y no una fraccion del ancho: el modal
  /// se mide por su contenido (`IntrinsicWidth`), asi que preguntar cuanto
  /// ancho hay para decidir cuanto ocupar es una vuelta que no cierra.
  static double get _frame => AppSize.picture * 5;

  /// Cuanto se puede acercar sobre lo que ya llena el marco. Cuatro veces es
  /// quedarse con un cuarto del lado de la imagen: mas que eso ya es recortar
  /// un detalle que va a subirse borroso.
  static const double _maxZoom = 4;

  ui.Image? _image;

  /// Acercamiento sobre [_cover]. En 1 la imagen llena el marco justo, que es
  /// el minimo: por debajo apareceria fondo vacio dentro del recorte.
  double _zoom = 1;

  /// Con cuanto acercamiento arranco el gesto en curso. El gesto informa
  /// cuanto se abrieron los dedos **desde que empezo**, no desde el ultimo
  /// aviso, asi que sin esto cada evento partiria de cero.
  double _startZoom = 1;

  /// Esquina superior izquierda de la imagen dentro del marco. Es negativa o
  /// cero: lo que se ve es una ventana sobre algo mas grande.
  Offset _offset = Offset.zero;

  /// Cuanto hay que agrandar la imagen para que llene el marco. Sale de sus
  /// proporciones, asi que se calcula una sola vez, al terminar de leerla.
  double _cover = 1;

  final _loading = ValueNotifier<bool>(false);

  /// Escala real con la que se dibuja: la que llena el marco por el
  /// acercamiento elegido.
  double get _scale => _cover * _zoom;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void dispose() {
    _image?.dispose();
    _loading.dispose();
    super.dispose();
  }

  /// Lee los bytes elegidos. Una imagen que no se puede leer no es una imagen:
  /// el modal se cierra y quien lo abrio avisa, porque es el que sabe de que
  /// foto estaba hablando.
  Future<void> _decode() async {
    try {
      final codec = await ui.instantiateImageCodec(widget.bytes);
      final frame = await codec.getNextFrame();

      if (!mounted) {
        frame.image.dispose();
        return;
      }

      setState(() {
        _image = frame.image;
        _cover = math.max(
          _frame / frame.image.width,
          _frame / frame.image.height
        );
        // Centrada: el sobrante que no entra en el marco se reparte igual de
        // los dos lados.
        _offset = Offset(
          (_frame - frame.image.width * _cover) / 2,
          (_frame - frame.image.height * _cover) / 2
        );
      });
    } catch (_) {
      if (mounted) Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: _frame,
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _viewport(context),
        SizedBox(height: AppSize.spaceXS),
        TextSmall(
          S.of(context).image_crop_hint,
          lines: 2,
          textAlign: TextAlign.center,
          color: ThemeColor.of(context).text.secondary
        ),
        SizedBox(height: AppSize.spaceS),
        _ZoomBar(
          value: (_zoom - 1) / (_maxZoom - 1),
          width: _frame,
          onChanged: _zoomBar
        ),
        SizedBox(height: AppSize.spaceM),
        Button(
          title: S.of(context).save,
          loading: _loading,
          action: _submit
        )
      ]
    )
  );

  /// El marco: la imagen debajo y, encima, todo lo que la mueve.
  Widget _viewport(BuildContext context) {
    final image = _image;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSize.corner),
      child: Container(
        width: _frame,
        height: _frame,
        color: ThemeColor.of(context).background,
        child: image == null
          ? const Center(child: Loading())
          // La rueda del raton es la unica forma de acercar sin dedos, asi que
          // se escucha aparte: los gestos de Flutter no la reportan.
          : Listener(
            onPointerSignal: _wheel,
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onScaleStart: (_) => _startZoom = _zoom,
              onScaleUpdate: _drag,
              child: Stack(children: [
                Positioned(
                  left: _offset.dx,
                  top: _offset.dy,
                  child: RawImage(
                    image: image,
                    width: image.width * _scale,
                    height: image.height * _scale,
                    filterQuality: FilterQuality.medium
                  )
                )
              ])
            )
          )
      )
    );
  }

  /// Un gesto de arrastrar o de pellizcar, que para Flutter son el mismo: uno
  /// con un dedo y otro con dos.
  void _drag(ScaleUpdateDetails details) => _move(
    zoom: _startZoom * details.scale,
    focus: details.localFocalPoint,
    delta: details.focalPointDelta
  );

  void _wheel(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;

    // Exponencial y no una suma: acercar dos muescas desde lejos tiene que
    // notarse lo mismo que acercarlas desde cerca.
    _move(
      zoom: _zoom * math.exp(-event.scrollDelta.dy / 250),
      focus: event.localPosition
    );
  }

  void _zoomBar(double value) => _move(
    zoom: 1 + value * (_maxZoom - 1),
    focus: Offset(_frame / 2, _frame / 2)
  );

  /// Mueve la imagen: la acerca a [zoom] dejando quieto lo que hay bajo
  /// [focus], y la corre [delta].
  ///
  /// El punto fijo es el del gesto y no el centro del marco porque es lo que se
  /// espera de un zoom: se acerca **sobre lo que se esta mirando**, no sobre el
  /// medio de la foto, que obligaria a recorrerla de nuevo despues de cada
  /// acercamiento.
  void _move({required double zoom, required Offset focus, Offset? delta}) {
    final image = _image;
    if (image == null) return;

    final previous = _scale;

    setState(() {
      _zoom = zoom.clamp(1.0, _maxZoom);

      final moved = focus - (focus - _offset) * (_scale / previous);

      _offset = _inside(moved + (delta ?? Offset.zero), image);
    });
  }

  /// Deja la imagen tapando el marco entero: correrla mas alla de su borde
  /// dejaria fondo vacio adentro del recorte, que es una esquina transparente
  /// en el logo.
  Offset _inside(Offset offset, ui.Image image) {
    final width = image.width * _scale;
    final height = image.height * _scale;

    return Offset(
      offset.dx.clamp(math.min(_frame - width, 0.0), 0.0),
      offset.dy.clamp(math.min(_frame - height, 0.0), 0.0)
    );
  }

  /// Dibuja lo que se ve en el marco y lo devuelve en PNG.
  ///
  /// Sale en PNG y no en el formato original porque lo que se guarda ya no es
  /// el archivo que se eligio sino un recorte: no hay bytes que conservar. El
  /// backend lo vuelve a codificar igual (a WebP, sin metadatos), asi que
  /// mandarlo comprimido con perdida seria comprimir dos veces la misma imagen.
  Future<void> _submit() async {
    final image = _image;
    if (image == null || _loading.value) return;

    _loading.value = true;

    final bytes = await _crop(image);

    if (!mounted) return;

    _loading.value = false;

    if (bytes == null) {
      FloatFlag.of(context).error(message: S.of(context).image_crop_failed);
      return;
    }

    Navigator.pop(context, bytes);
  }

  Future<Uint8List?> _crop(ui.Image image) async {
    // El marco, medido sobre la imagen: lo que se ve dividido por cuanto se la
    // agrando para verlo.
    final source = Rect.fromLTWH(
      -_offset.dx / _scale,
      -_offset.dy / _scale,
      _frame / _scale,
      _frame / _scale
    );

    // Nunca se agranda: un logo de 200 px sale de 200 px. Estirarlo hasta el
    // maximo no agrega un solo detalle, solo peso.
    final side = math.max(1, math.min(widget.output, source.width.round()));

    try {
      final recorder = ui.PictureRecorder();

      Canvas(recorder).drawImageRect(
        image,
        source,
        Rect.fromLTWH(0, 0, side.toDouble(), side.toDouble()),
        Paint()
          ..isAntiAlias = true
          ..filterQuality = FilterQuality.medium
      );

      final picture = recorder.endRecording();
      final rendered = await picture.toImage(side, side);

      picture.dispose();

      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);

      rendered.dispose();

      return data?.buffer.asUint8List();
    } catch (_) {
      return null;
    }
  }
}

/// La barra con la que se acerca la imagen.
///
/// Existe ademas de la rueda y del pellizco porque es lo unico de los tres que
/// **se ve**: sin ella, quien no sabe que la rueda acerca solo puede mover la
/// foto, y la mitad del recorte se le escapa.
///
/// Mide un ancho fijo, el del marco: vive dentro de un modal que se mide por su
/// contenido, y preguntar cuanto ancho hay disponible ahi no tiene respuesta.
class _ZoomBar extends StatelessWidget {
  const _ZoomBar({
    required this.value,
    required this.width,
    required this.onChanged
  });

  /// Cuanto acercamiento hay, de 0 (el minimo) a 1 (el maximo).
  final double value;

  final double width;
  final void Function(double value) onChanged;

  /// Lado del pulgar. Del alto del texto: es lo que se agarra con el raton, y
  /// mas chico que eso no se acierta.
  static double get _grip => AppSize.text * 1.4;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    // El pulgar recorre el hueco que le deja su propio diametro, asi que no se
    // sale por los extremos de la pista.
    final span = math.max(width - _grip, 1.0);

    void pick(Offset position) =>
      onChanged(((position.dx - (_grip / 2)) / span).clamp(0.0, 1.0));

    return SizedBox(
      width: width,
      height: _grip,
      child: GestureDetector(
        onTapDown: (details) => pick(details.localPosition),
        onPanStart: (details) => pick(details.localPosition),
        onPanUpdate: (details) => pick(details.localPosition),
        child: Stack(children: [
          Positioned.fill(child: Center(child: Container(
            height: AppSize.gap / 2,
            decoration: BoxDecoration(
              color: scheme.line,
              borderRadius: BorderRadius.circular(AppSize.gap)
            )
          ))),
          Positioned(
            top: 0,
            left: value.clamp(0.0, 1.0) * span,
            child: Container(
              width: _grip,
              height: _grip,
              decoration: BoxDecoration(
                color: scheme.primary,
                shape: BoxShape.circle
              )
            )
          )
        ])
      )
    );
  }
}
