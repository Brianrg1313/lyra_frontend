import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';
import 'package:app/screens/modals/create_business/_create_business.dart';

/// Lo que se ve en una seccion del home cuando el cliente todavia no tiene
/// ninguna empresa.
///
/// Todo lo que vive dentro del home cuelga de la empresa activa —las tablas,
/// los canales, las conexiones, la empresa misma—, asi que sin ninguna no hay
/// nada que pedirle al backend: la seccion no se monta y en su lugar va este
/// mensaje con el alta, que es el unico camino desde el que arranca lo demas
/// (ver `homeContent`).
///
/// La que no pasa por aca es el dashboard, que es la portada del home y se ve
/// desde el primer dia. La seccion de empresas si, pero por el otro camino: no
/// esta bloqueada —es justamente donde se crea la primera— asi que se abre y
/// muestra esto como su contenido, porque sin ninguna empresa no hay detalle
/// que mostrar.
class NoBusinessSection extends StatelessWidget {
  const NoBusinessSection({super.key});

  @override
  Widget build(BuildContext context) => Surface(
    padding: EdgeInsets.all(AppSize.padding),
    child: SectionMessage(
      icon: CI.store,
      title: S.of(context).section_no_business_title,
      subtitle: S.of(context).section_no_business_subtitle,
      action: () => showModal(
        context: context,
        title: S.of(context).create_business,
        builder: (BuildContext context) => const CreateBusinessModal()
      ),
      actionLabel: S.of(context).create_business,
      actionIcon: CI.plus
    )
  );
}
