import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/business/business_service.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// Pestana de empleados: la gente que entra a la empresa, con que rango y que
/// puede hacer cada uno.
///
/// Por ahora lo unico que hay es cuantos son. Ese numero vivia en el perfil y
/// se mudo aca, que es su seccion: la cedula de identidad de la empresa no
/// tiene por que cargar con una cuenta que nadie esta mirando.
///
/// Quienes son todavia no esta modelado del otro lado, asi que debajo del
/// numero queda el aviso. La pestana se muestra igual, y no se esconde, por lo
/// mismo que el side bar deja a la vista las secciones bloqueadas: asi se ve
/// desde el primer dia de que partes se compone una empresa.
class BusinessEmployeesTab extends StatefulWidget {
  const BusinessEmployeesTab({super.key});

  @override
  State<BusinessEmployeesTab> createState() => _BusinessEmployeesTabState();
}

class _BusinessEmployeesTabState extends State<BusinessEmployeesTab> {
  @override
  void initState() {
    super.initState();

    // Se difiere al primer frame porque la carga notifica al servicio, y
    // notificar mientras el arbol se esta montando es un rebuild en pleno
    // build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<BusinessService>().loadEmployees();
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = context.watch<BusinessService>();

    return switch (service.employeesStatus) {
      BusinessEmployeesStatus.error => SectionMessage(
        icon: CI.info,
        title: S.of(context).business_employees_error_title,
        subtitle: S.of(context).business_employees_error_subtitle,
        action: () => service.loadEmployees(force: true),
        actionLabel: S.of(context).business_list_retry
      ),
      BusinessEmployeesStatus.ready => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Count(total: service.employees),
          SizedBox(height: AppSize.padding),
          // El aviso ocupa lo que queda: la pestana sigue siendo, sobre todo,
          // la lista que todavia no esta.
          Expanded(child: SectionMessage(
            icon: CI.employee,
            title: S.of(context).coming_soon,
            subtitle: S.of(context).business_employees_soon
          ))
        ]
      ),
      _ => const Center(child: Loading())
    };
  }
}

/// Cuanta gente entra a la empresa, como tarjeta.
///
/// Es un dato y no un titulo: va sobre su superficie —un bloque sobre la hoja
/// del cuerpo, como los del perfil— y no suelto sobre el aviso.
class _Count extends StatelessWidget {
  const _Count({required this.total});

  final int total;

  @override
  Widget build(BuildContext context) {
    final scheme = ThemeColor.of(context);

    return Surface.over(
      padding: EdgeInsets.all(AppSize.padding),
      child: Row(children: [
        Icon(CI.employee, size: AppSize.text, color: scheme.text.secondary),
        SizedBox(width: AppSize.spaceXS),
        Expanded(child: TextSmall(
          S.of(context).business_employees_total,
          color: scheme.text.secondary
        )),
        TextLarge("$total")
      ])
    );
  }
}
