import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_profile_model.dart';
import 'package:app/services/business/business_service.dart';
import 'package:app/services/files/image_file.dart';

// WIDGETS
import 'package:app/screens/home/sections/business/business_avatar.dart';
import 'package:app/screens/modals/crop_image/_crop_image.dart';

/// La cara de la empresa: su logo, y desde donde se cambia.
///
/// Va a la izquierda del nombre y las etiquetas, dentro de la cabecera del
/// perfil (ver [BusinessProfileHeader]): es la otra mitad de la misma
/// presentacion —quien es la empresa— y no un bloque aparte. En una columna
/// propia obligaba a cruzar la pantalla para saber de que ficha era el dato que
/// se estaba corrigiendo, y dejaba una columna entera ocupada por una sola
/// imagen.
///
/// Que se puede cambiar no se explica con un texto: lleva el lapiz pegado abajo
/// a la derecha, encima de la propia imagen. Es el mismo gesto que ya tienen
/// las fotos en todos lados, y ocupa lo que ocupa un icono en vez de un renglon.
///
/// Cambiar el logo son tres pasos y ninguno se puede saltear: se elige el
/// archivo, se encuadra ([CropImageModal]) y recien entonces se sube. El
/// encuadre esta en el medio porque el logo se dibuja siempre cuadrado —en el
/// selector, aca— y de una foto apaisada hay que dejar afuera la
/// mitad: cual mitad es la unica parte de todo esto que el backend no puede
/// resolver solo.
///
/// Mientras sube tapa el logo con su propio cargando y no con el de la pestana:
/// lo unico que esta cambiando es la imagen, y el resto de la ficha se sigue
/// leyendo.
class BusinessProfileLogo extends StatefulWidget {
  const BusinessProfileLogo({super.key, required this.profile});

  final BusinessProfileModel profile;

  @override
  State<BusinessProfileLogo> createState() => _BusinessProfileLogoState();
}

class _BusinessProfileLogoState extends State<BusinessProfileLogo> {
  /// Lado del logo. Es el mismo widget que el del selector dibujado en grande,
  /// pero no tanto como cuando tenia una columna para el solo: aca se mide
  /// contra el nombre que tiene al lado, y mas alto que ese bloque de texto
  /// dejaria a la cabecera con un hueco al costado.
  static double get _size => AppSize.picture * 1.5;

  /// Se esta subiendo un logo. Bloquea la accion —dos subidas a la vez dejan a
  /// la empresa con la que conteste ultimo— y tapa la imagen con el cargando.
  bool _busy = false;

  @override
  Widget build(BuildContext context) => FeedbackButton(
    action: _change,
    message: _label(context),
    radius: AppSize.corner,
    child: _image(context, widget.profile)
  );

  /// El logo, con el lapiz encima y el cargando mientras se sube el nuevo.
  Widget _image(BuildContext context, BusinessProfileModel profile) => Stack(
    alignment: Alignment.center,
    children: [
      BusinessAvatar(
        name: profile.name,
        // La version que cubra el lado con el que se dibuja, no la original: el
        // logo se sube de hasta 10 MB y aca entra en un cuadrado chico.
        url: profile.logo?.sized(_size.round()),
        size: _size
      ),
      if (_busy) Container(
        width: _size,
        height: _size,
        decoration: BoxDecoration(
          color: ThemeColor.of(context).surface.withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(AppSize.corner)
        ),
        child: const Center(child: Loading())
      )
      // El lapiz desaparece mientras sube: la accion ya esta en curso, y
      // ofrecerla encima del cargando es ofrecer algo que no responde.
      else Positioned(
        right: AppSize.gap,
        bottom: AppSize.gap,
        child: _pen(context)
      )
    ]
  );

  /// El distintivo que dice que la imagen se toca. Va opaco y con borde porque
  /// se apoya sobre el logo: sobre una foto clara, un icono suelto no se ve.
  Widget _pen(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Container(
      padding: EdgeInsets.all(AppSize.gap),
      decoration: BoxDecoration(
        color: scheme.surfaceOver,
        shape: BoxShape.circle,
        border: Border.all(color: scheme.line)
      ),
      child: Icon(CI.pen, size: AppSize.text, color: scheme.icon)
    );
  }

  /// Como se llama la accion: cargar el logo si no hay ninguno, cambiarlo si ya
  /// hay. Es el texto del boton y lo que se le anuncia al lector de pantalla.
  String _label(BuildContext context) => widget.profile.logo == null
    ? S.of(context).business_logo_add
    : S.of(context).business_logo_change;

  /// Elegir, encuadrar y subir. Cualquiera de los dos primeros pasos se puede
  /// abandonar —cerrando el dialogo del sistema o el modal— y ahi no pasa nada:
  /// la empresa se queda con el logo que tenia.
  Future<void> _change() async {
    if (_busy) return;

    final bytes = await pickImageBytes(
      label: S.of(context).business_logo_files
    );

    if (bytes == null || !mounted) return;

    // El limite es el del backend. Se mide antes de leer la imagen: una foto
    // de 40 MB hay que decodificarla entera en memoria para recortarla, y ese
    // es el trabajo que no vale la pena hacer para que despues la rechacen.
    if (bytes.length > kImageMaxBytes) {
      FloatFlag.of(context).error(message: S.of(context).business_logo_large);
      return;
    }

    final cropped = await showModal(
      context: context,
      title: S.of(context).image_crop_title,
      builder: (BuildContext context) => CropImageModal(bytes: bytes)
    );

    // Se cerro el modal sin aceptar el encuadre.
    if (cropped is! Uint8List || !mounted) return;

    setState(() => _busy = true);

    // Nada que avisar cuando entra: el logo nuevo ya esta en pantalla. Si
    // fallo, el error lo mostro el servicio, asi que la respuesta no se mira.
    await _upload(cropped);

    if (!mounted) return;

    setState(() => _busy = false);
  }

  /// Sube el recorte. Viaja como archivo porque asi viaja un multipart, y el
  /// recorte nacio en memoria: se escribe en la carpeta temporal el tiempo que
  /// dura la subida y se borra pase lo que pase, incluso si la empresa se
  /// cambio mientras tanto.
  Future<bool> _upload(Uint8List bytes) async {
    final file = await writeTempImage(bytes, name: "logo");

    try {
      if (!mounted) return false;

      return await context.read<BusinessService>().setLogo(context, file);
    } finally {
      await discardTempImage(file);
    }
  }
}
