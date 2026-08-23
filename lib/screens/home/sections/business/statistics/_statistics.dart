import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/section_message.dart';

/// Pestana de estadisticas: como le va a la empresa —ventas, movimiento,
/// crecimiento— sin salir de ella.
///
/// Es lo mismo que miran las secciones de reportes del side bar, pero de esta
/// empresa y resumido; todavia no hay de donde sacarlo, asi que la pestana
/// existe pero avisa que falta (ver `BusinessEmployeesTab`).
class BusinessStatisticsTab extends StatelessWidget {
  const BusinessStatisticsTab({super.key});

  @override
  Widget build(BuildContext context) => SectionMessage(
    icon: CI.chart,
    title: S.of(context).coming_soon,
    subtitle: S.of(context).business_statistics_soon
  );
}
