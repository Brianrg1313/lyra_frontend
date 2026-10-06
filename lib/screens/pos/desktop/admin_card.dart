import 'dart:async';

import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

// SERVICES
import 'package:app/services/client/client_service.dart';
import 'package:app/services/pos/pos_service.dart';

/// Whoever is attending the counter: their picture, their name, their email
/// and how much they have sold today, with the button to leave POS mode below
/// everything.
///
/// It is the bottom half of the left panel (see [PosLeftPanel]), and because
/// of that it measures what its content needs instead of stretching: the top
/// half is the one that keeps whatever is left over.
class PosAdminCard extends StatelessWidget {
  const PosAdminCard({super.key});

  /// The avatar of whoever is attending, next to the name and not above it:
  /// it does not need to be as big as in a standalone profile card.
  static double get _avatarSize => AppSize.picture;

  @override
  Widget build(BuildContext context) {
    final client = context.watch<ClientService>();
    final pos = context.watch<PosService>();

    return Padding(
      padding: EdgeInsets.all(AppSize.padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              ProfilePicture(
                kind: ProfileKind.user,
                url: client.picture,
                size: _avatarSize,
                label: client.fullName
              ),
              SizedBox(width: AppSize.gap),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextLarge(client.fullName, ellipsis: true),
                  TextSmall(client.email, ellipsis: true)
                ]
              ))
            ]
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: AppSize.gap),
            // The two badges split the row instead of measuring their content:
            // the panel is 300 wide and `AppSize` scales x1.25 on hi-dpi, where
            // "12 sales today" next to the clock no longer fits and overflows.
            child: Row(children: [
              Expanded(child: Surface.over(
                radius: AppSize.cornerInset(AppSize.gap),
                padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap),
                child: Center(child: _Sales(pos: pos))
              )),
              SizedBox(width: AppSize.gap),
              Expanded(child: Surface.over(
                radius: AppSize.cornerInset(AppSize.gap),
                padding: EdgeInsets.symmetric(horizontal: AppSize.spaceXS, vertical: AppSize.gap),
                child: const Center(child: _Clock())
              ))
            ])
          ),
          FocusableWidget(
            child: Surface.over(
              radius: AppSize.cornerInset(AppSize.gap),
              padding: EdgeInsets.all(AppSize.spaceXS),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.exit_to_app_rounded, color: Colors.red.withAlpha(150)),
                  SizedBox(width: AppSize.gap),
                  TextMedium(S.of(context).pos_close, color: Colors.red.withAlpha(150))
                ])
            )
          )
        ]
      )
    );
  }
}

/// How much whoever is attending has sold today, according to how the
/// [PosService] load turned out.
class _Sales extends StatelessWidget {
  const _Sales({required this.pos});

  final PosService pos;

  @override
  Widget build(BuildContext context) => switch (pos.status) {
    PosSummaryStatus.idle || PosSummaryStatus.loading => const Loading(),
    PosSummaryStatus.error => GestureDetector(
      onTap: pos.retry,
      child: TextSmall(S.of(context).stock_summary_retry)
    ),
    PosSummaryStatus.ready => TextMedium(
      S.of(context).pos_sales_today(pos.mineSales),
      bold: true
    )
  };
}

/// The current time, so whoever is attending the counter has it in sight
/// without looking for the system clock.
class _Clock extends StatefulWidget {
  const _Clock();

  @override
  State<_Clock> createState() => _ClockState();
}

class _ClockState extends State<_Clock> {
  DateTime _now = DateTime.now();
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() => _now = DateTime.now()));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return TextMedium(DateFormat.jm(locale).format(_now));
  }
}