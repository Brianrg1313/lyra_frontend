import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';

class ProfileCard extends StatelessWidget {
  const ProfileCard({
    required this.isExpanded,
    super.key,
  });

  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    final client = context.watch<ClientService>();
    final picture = client.picture;

    return Padding(
    padding: EdgeInsets.all(AppSize.padding),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: AppSize.action,
          height: AppSize.action,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppSize.action),
            border: Border(
              top: BorderSide(color: Colors.white.withAlpha(40)),
              left: BorderSide(color: Colors.white.withAlpha(40))
            ),
            // El gradiente queda de fondo: se ve mientras la imagen carga y
            // tambien cuando el cliente no tiene foto.
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withAlpha(50),
                Colors.white.withAlpha(0)
              ]),
            image: picture != null && picture.isNotEmpty
              ? DecorationImage(
                  image: NetworkImage(picture),
                  fit: BoxFit.cover)
              : null
          )
        ),
        // El espacio va dentro del Expanded para que pueda comprimirse a 0
        // mientras el sideBar anima su ancho; si fuera un SizedBox fijo
        // provocaria overflow en los primeros frames de la expansion.
        if (isExpanded) Expanded(child: Padding(
          padding: EdgeInsets.only(left: AppSize.spaceXS),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextLarge(client.fullName, ellipsis: true, multiplier: 1.5),
              TextSmall(client.email, ellipsis: true)
            ])))
      ])
    );
  }
}
