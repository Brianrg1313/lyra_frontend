import 'dart:async';

import 'package:flutter/foundation.dart' show kIsWeb, defaultTargetPlatform;
import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// PACKAGES
import 'package:provider/provider.dart';
import 'package:window_manager/window_manager.dart';

// SERVICES
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/pos/pos_catalog_service.dart';
import 'package:app/services/pos/pos_invoice_service.dart';
import 'package:app/services/pos/pos_methods_service.dart';
import 'package:app/services/pos/pos_service.dart';

// WIDGETS
import './left_panel.dart';
import './center_panel.dart';
import './right_panel.dart';

/// Layout of the POS mode screen: three panels in a row, with the same `gap`
/// between them and against the edge that the home uses.
///
/// The two on the sides are as wide as they need and the one in the middle
/// keeps the rest: they are going to hold fixed-width lists (what is being
/// charged, the payment detail), while the central one shows the catalog and
/// is therefore the only one that makes use of every extra pixel.
///
/// There is no `DeviceSelector` like in the home: a three-panel counter is
/// desktop-only. When POS gets a phone version, it won't be this narrower
/// layout, it will be a different screen.
class PosBody extends StatefulWidget {
  const PosBody({super.key});

  /// Left panel width. Fixed for the same reason as the side bar: what goes
  /// inside are rows of known height, and making them wider as the window
  /// grows shows nothing more.
  static const double leftWidth = 300;

  /// Right panel width. A bit wider than the left one: it is where the
  /// amounts land, which is what cannot be cut.
  static const double rightWidth = 340;

  @override
  State<PosBody> createState() => _PosBodyState();
}

class _PosBodyState extends State<PosBody> {
  /// How much whoever is attending has sold today. The page owns it and it is
  /// discarded when leaving it: no other place in the app needs it.
  final _summary = PosService();

  /// The products on sale. It is created here and not in the central panel
  /// —which is the only one drawing them today— because what is picked from
  /// the grid is what the left panel charges: the two halves of a sale read the
  /// same catalog.
  final _catalog = PosCatalogService();

  /// The ticket being rung up. It is created here for the same reason as the
  /// catalog —the grid in the middle writes it and the panel on the right draws
  /// it— and it is the invoice the backend is holding units for, not a list in
  /// memory (see [PosInvoiceService]).
  final _ticket = PosInvoiceService();

  /// How a sale can be paid. It is a closed vocabulary the backend owns, read
  /// once when the register opens so the checkout does not have to wait for it
  /// with a customer standing there.
  final _methods = PosMethodsService();

  /// Whether this page is the one that put the window in full screen, so
  /// leaving POS only undoes what entering it did.
  bool _fullScreen = false;

  @override
  void initState() {
    super.initState();

    // A counter runs with nothing else on the screen: the till is the only
    // thing whoever is charging looks at, and the desktop behind it is one
    // mis-click away from covering the ticket. The window bar stays —it is
    // drawn above the `Navigator`—, so the back button that leaves POS is
    // still there.
    unawaited(_enterFullScreen());

    // The counter is a screen that has to be told things: what is left of a
    // product changes at the other till and this one must not go on offering
    // it. The call is idempotent, and it is here and not only in the home
    // because POS is a standalone page that can be opened straight from its
    // URL.
    unawaited(ConnectionService().open());

    // Every read leaves in the same frame: the summary fills the card at the
    // bottom left, the catalog the grid in the middle, the methods the payment
    // picker, and the ticket picks up whatever this till left open. None of
    // them depends on another —the categories the strip draws travel with the
    // summary, but the products do not need them to be read.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _summary.load();
      _catalog.load();
      _methods.load();
      _ticket.recover();
    });
  }

  /// Takes the window to full screen, remembering whether it already was:
  /// only what POS turned on is turned off when leaving it.
  ///
  /// Windows-only. It is the only platform where the app owns its window
  /// (`window_manager` is initialized for it alone in `starter`); on web the
  /// browser is the one that decides, and it only grants full screen from a
  /// gesture, not from opening a page.
  ///
  /// The platform is read off the framework and not off [AppController]
  /// —which is what the rest of the app asks— because the controller is only
  /// booted by `starter`: a widget test mounts this page without it, and an
  /// unbooted controller throws instead of answering that there is no window.
  Future<void> _enterFullScreen() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.windows) return;
    if (await windowManager.isFullScreen()) return;
    if (!mounted) return;

    _fullScreen = true;
    await windowManager.setFullScreen(true);

    // POS can be left while the window is still changing, in which case the
    // exit in `dispose` ran before this call landed and it is this one that
    // has to undo it.
    if (!mounted) await windowManager.setFullScreen(false);
  }

  @override
  void dispose() {
    // Leaving the counter gives the window back the way it was found.
    if (_fullScreen) unawaited(windowManager.setFullScreen(false));

    _summary.dispose();
    _catalog.dispose();
    // The invoice is not cancelled here. Leaving the counter is not the same
    // decision as throwing a ticket away: the document stays open, its units
    // stay held, and `recover` finds it again the next time this till opens.
    _ticket.dispose();
    _methods.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MultiProvider(
    providers: [
      ChangeNotifierProvider<PosService>.value(value: _summary),
      ChangeNotifierProvider<PosCatalogService>.value(value: _catalog),
      ChangeNotifierProvider<PosInvoiceService>.value(value: _ticket),
      ChangeNotifierProvider<PosMethodsService>.value(value: _methods)
    ],
    child: Padding(
      padding: EdgeInsets.all(AppSize.gap),
      child: Row(children: [
        const SizedBox(width: PosBody.leftWidth, child: PosLeftPanel()),
        SizedBox(width: AppSize.gap),
        const Expanded(child: PosCenterPanel()),
        SizedBox(width: AppSize.gap),
        const SizedBox(width: PosBody.rightWidth, child: PosRightPanel())
      ])
    )
  );
}
