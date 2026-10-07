import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';

// SERVICES
import 'package:app/services/home/home_service.dart';

// WIDGETS


/// What the header's search is doing to the board, while it is doing it.
///
/// The one control on this screen that is not the backend's: the list is read a
/// page at a time and `GET /sales` takes no search, so what is typed narrows
/// the rows that have been read and nothing further down. Said out loud for the
/// same reason the tickets-only line is: somebody who searches a ticket code
/// and finds nothing has to know whether that means "not in this company" or
/// "not on this page".
///
/// It listens to the search on its own so that typing rebuilds this line and
/// the rows, and not the controls above them.
class SalesSearchCaption extends StatelessWidget {
  const SalesSearchCaption({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: context.read<HomeService>().searchQuery,
    builder: (context, query, _) => query.isEmpty
      ? const SizedBox.shrink()
      : Padding(
          padding: EdgeInsets.only(top: AppSize.gap),
          child: TextSmall(
            S.of(context).sales_search_scope,
            lines: 2,
            color: ThemeColor.of(context).text.secondary
          )
        )
  );
}
