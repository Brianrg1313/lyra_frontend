import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Etiqueta de un estado: icono y texto sobre un relleno tenue de su propio
/// color.
///
/// Es para lo que la ficha **dice** de un dato y no para lo que el dato vale:
/// la situacion legal de la empresa junto a su nombre, y si una direccion de
/// correo se comprobo junto a la direccion. Los dos se leen de un vistazo y
/// ninguno de los dos se edita, asi que no son una fila mas.
///
/// El color lo pone quien la usa y no la etiqueta: es semantico —verde llega,
/// ambar nadie lo comprobo— y vive junto al estado que lo significa, no aca.
class ProfileTag extends StatelessWidget {
  const ProfileTag({
    super.key,
    required this.icon,
    required this.label,
    required this.color
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: AppSize.spaceXS,
      vertical: AppSize.gap / 2
    ),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(AppSize.corner)
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppSize.text, color: color),
        SizedBox(width: AppSize.gap),
        TextSmall(label, color: color)
      ]
    )
  );
}
