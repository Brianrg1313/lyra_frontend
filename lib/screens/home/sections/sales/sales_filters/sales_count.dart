import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sales/sales_service.dart';

// WIDGETS


/// How many sales the **section** holds.
///
/// It is not how many are listed, and it is not adjusted for the state filter:
/// a stage narrows the page and not the query on the other side, so a count
/// that pretended otherwise would be this app inventing a number nobody
/// measured.
class SalesCount extends StatelessWidget {
  const SalesCount({super.key, required this.service});

  final SalesService service;

  @override
  Widget build(BuildContext context) => TextSmall(
    S.of(context).sales_count(service.total),
    ellipsis: true,
    color: ThemeColor.of(context).text.secondary
  );
}
