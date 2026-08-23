import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// La imagen de una empresa: su logo si lo tiene, y si no el avatar en
/// gradiente con la inicial de su nombre.
///
/// Vive aca arriba y no dentro del selector o de la ficha porque una empresa se
/// dibuja igual en los dos, solo que mas grande en uno que en otro. Cuando el
/// avatar de una empresa cambie —otra forma, otro degradado— tiene que cambiar
/// en todos lados a la vez, y eso solo pasa si es el mismo widget.
///
/// [url] es la direccion ya armada del logo: la arma quien tiene el archivo,
/// poniendo su id detras de la base que entrego `/init` (ver `FileModel`). Sin
/// ella —vacia porque la empresa no subio ninguno, o porque la base todavia no
/// llego— y tambien si no se puede bajar, se dibuja el avatar.
class BusinessAvatar extends StatelessWidget {
  const BusinessAvatar({
    super.key,
    required this.name,
    required this.size,
    this.url
  });

  final String name;
  final double size;
  final String? url;

  @override
  Widget build(BuildContext context) {
    final logo = url;

    if (logo == null || logo.isEmpty) return _fallback(context);

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppSize.corner),
      child: Image.network(
        logo,
        width: size,
        height: size,
        fit: BoxFit.cover,
        // Un logo que no baja no es un error que valga un cartel: la empresa se
        // sigue reconociendo por su inicial, igual que antes de subirlo.
        errorBuilder: (context, error, stack) => _fallback(context)
      )
    );
  }

  /// El avatar en gradiente con la inicial. Sin nombre —una empresa recien
  /// creada que todavia no se leyo— va el icono de tienda.
  Widget _fallback(BuildContext context) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(AppSize.corner),
      border: Border(
        top: BorderSide(color: Colors.white.withAlpha(40)),
        left: BorderSide(color: Colors.white.withAlpha(40))
      ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [Colors.white.withAlpha(50), Colors.white.withAlpha(0)]
      )
    ),
    child: Center(child: name.isEmpty
      ? Icon(CI.store, size: size * 0.4, color: ThemeColor.of(context).icon)
      // La inicial se mide contra el avatar y no contra el texto de la app: el
      // mismo widget se dibuja de 44 en una fila y de 72 en el perfil, y con un
      // cuerpo fijo se veria diminuta en el grande.
      : TextLarge(
        name.characters.first.toUpperCase(),
        multiplier: (size * 0.4) / AppSize.text
      ))
  );
}
