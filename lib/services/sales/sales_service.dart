import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// SERVICES
import 'package:app/services/badges/badges_service.dart';
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sale_progress_model.dart';
import 'package:app/services/sales/sources/sales_source.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/toolkit/deployment.dart';

enum SalesStatus { idle, loading, ready, empty, error }

/// **Every sale the company has going, and every one it finished**
/// (`GET /sales`, `PUT /sales/fulfillment`).
///
/// One question runs under both lists: *what is still owed to somebody?* A
/// ticket a till has open owes the cashier a charge; a customer the assistant
/// is holding stock for owes the company money, or the company owes them an
/// account to pay into; a charged sale that has not left the shop owes them a
/// box. Only when nothing is owed in either direction is a sale finished, and
/// that is the whole split between the two sections.
///
/// **One service, one open section.** The two tabs are the same endpoint with a
/// different `SECTION`, so they share this and [open] switches it: a work list
/// is read now, and keeping the other tab's page warm would be keeping a
/// snapshot of a board that has moved since. The [channel] and [mine] filters
/// survive the switch because they are the same question on either side; the
/// [stage] does not, because a stage belongs to exactly one section.
///
/// **And it listens.** `sale/progress` is what makes this a board rather than a
/// query somebody refreshes ([SaleProgressModel]), and it is handled in two
/// ways because a notice is thin on purpose:
///
/// - **A row this list already holds** is relabelled in place, and moved to the
///   top: the notice carries the measured stage, so a reread would ask for a
///   number it was already handed. If the new stage puts it outside what is on
///   screen —the other section, or another stage than the one being filtered
///   by— the row is dropped instead.
/// - **A sale it does not hold** cannot be drawn from a notice: it says where a
///   sale stands and not what it is worth or who is buying. So the first page
///   is read again, debounced, and only while the list is *on* the first page —
///   past it, the list is somebody's scroll and rebuilding it under them would
///   lose their place, so it is announced ([pending]) and they decide.
///
/// It is ephemeral: the sales section owns it and it is discarded on the way
/// out, like the money services one section over.
class SalesService extends ChangeNotifier {
  SalesService({SalesSource? source}) : _injected = source {
    // Registered before the connection is even open: the socket notes its
    // listeners down and hooks them up when it connects, and they survive a
    // reconnection.
    _unlisten = ConnectionService().on(SaleProgressModel.event, _onProgress);
    _unlistenOpened = ConnectionService().on(BadgesService.openedEvent, _onOpened);

    // What a notice cannot cover: the drop itself. A board is live while the
    // connection is, and what moved while this app was not in the room was
    // emitted to nobody and is not queued anywhere — a phone that slept, a wifi
    // that changed and a server that restarted all end with a list drawing what
    // was true before, and nothing on it saying so. Coming back is therefore a
    // reread and not a redraw.
    _reconnected = ConnectionService().onRestored(_onRestored);
  }

  final SalesSource? _injected;

  SalesSource get _source => _injected ?? Sources.sales;

  /// How many sales are read at a time. The backend caps the page at 100; a
  /// board is read down and not scrolled forever, so fifty is a screenful and a
  /// half.
  static const int _pageSize = 50;

  /// How far into the list the backend lets a request page (`Pipeline.window`).
  /// It is spelled here so the "load more" stops offering a page that would
  /// come back as a 400: the two lists are merged in memory on the other side,
  /// so a deep page costs its offset, and the archive of everything ever sold
  /// is the register's own search.
  static const int _window = 1000;

  /// How long a movement on a sale nobody is holding waits before the first
  /// page is read again.
  ///
  /// It is a debounce and not a delay: charging a ticket announces the invoice
  /// closing, the stock moving and the sale landing, and three notices in the
  /// same second have to cost one read. Long enough to collect a burst, short
  /// enough that somebody watching the counter sees the sale appear.
  static const Duration _catchUpDelay = Duration(milliseconds: 1200);

  SalesStatus _status = SalesStatus.idle;

  final List<SaleModel> _sales = [];

  SaleSection _section = SaleSection.process;
  String _stage = "";
  String _channel = "";
  bool _mine = false;

  int _total = 0;
  int _page = 0;

  bool _reading = false;
  bool _moreFailed = false;
  int _generation = 0;

  /// Movements on sales this list does not hold, waiting to be picked up. It is
  /// only ever above zero when the catch-up could not run on its own.
  int _pending = 0;

  Timer? _catchUp;
  void Function()? _unlisten;
  void Function()? _unlistenOpened;
  void Function()? _reconnected;

  /// `true` once the section was left.
  ///
  /// It is needed here and not in the money services because this one reads
  /// **on its own**: the catch-up is fired by a timer nobody is awaiting, so a
  /// page can land after the board it was for is gone, and notifying a disposed
  /// notifier is an assert in debug.
  bool _disposed = false;

  @override
  void dispose() {
    _disposed = true;

    _catchUp?.cancel();
    _catchUp = null;

    _unlisten?.call();
    _unlisten = null;

    _unlistenOpened?.call();
    _unlistenOpened = null;

    _reconnected?.call();
    _reconnected = null;

    super.dispose();
  }

  /// Announces a change, unless the section was left while a read was in
  /// flight.
  void _notify() {
    if (_disposed) return;

    notifyListeners();
  }

  // ─── What is on screen ──────────────────────────────────────────────────────

  SalesStatus get status => _status;

  List<SaleModel> get sales => _sales;

  /// Which of the two lists is open.
  SaleSection get section => _section;

  /// The stage the list is narrowed to, empty for the whole section.
  String get stage => _stage;

  /// The channel it is narrowed to, empty for all of them.
  String get channel => _channel;

  /// Whether it is showing only what the person signed in sold.
  bool get mine => _mine;

  /// How many sales the **section** holds. It is not how many are listed: a
  /// [stage] narrows the page and not the query —a stage is measured, so Mongo
  /// cannot filter by it— so a narrow stage answers with fewer rows than a page
  /// while this still counts the section.
  int get total => _total;

  /// Whether anything narrows the list.
  bool get isFiltered => _stage.isNotEmpty || _channel.isNotEmpty || _mine;

  /// Whether the filters in force leave the conversations out.
  ///
  /// [channel] and [mine] are **questions about tickets** — a conversation the
  /// assistant is in the middle of has no till and no seller — so the backend
  /// answers them with tickets alone rather than filing a deal under somebody.
  /// The bar says so; a list that quietly drops half its rows is a list nobody
  /// trusts.
  bool get isTicketsOnly => _channel.isNotEmpty || _mine;

  /// Whether there is another page to ask for.
  ///
  /// It is measured against [total] and not against how many rows came in,
  /// which is the difference a [stage] filter makes: it narrows the page, so a
  /// short page is not the end of the list. The window is the backend's own —
  /// past it the answer is a 400 that names the archive, and an offer that
  /// cannot be honoured is worse than none.
  bool get hasMore =>
    _page > 0 && _page * _pageSize < _total && (_page + 1) * _pageSize <= _window;

  /// Whether the last "load more" failed, so the button offers a retry instead
  /// of another page.
  bool get moreFailed => _moreFailed;

  /// Movements the list could not pick up on its own, waiting for somebody to
  /// ask for them. Zero while the board is keeping itself up to date.
  int get pending => _pending;

  // ─── Reading ────────────────────────────────────────────────────────────────

  /// Opens one of the two lists, reading it if it is not the one already on
  /// screen. It is what each tab calls when it mounts.
  Future<void> open(SaleSection section) {
    if (_section == section && _status != SalesStatus.idle) {
      return Future.value();
    }

    _section = section;
    // A stage belongs to exactly one section, so carrying it across would be
    // asking the backend for a contradiction — which it resolves in favour of
    // the stage, quietly reopening the tab that was just left.
    _stage = "";

    return _read(1, reset: true);
  }

  Future<void> retry() => _read(1, reset: true);

  /// Rereads the first page, picking up whatever moved while it was not
  /// looking. It is what the pending banner calls, and what a write on this
  /// screen falls back to.
  Future<void> refresh() => _read(1, reset: true);

  /// Narrows the list to one stage, or widens it to the whole section with an
  /// empty code.
  Future<void> filterStage(String value) {
    if (value == _stage) return Future.value();

    _stage = value;

    return _read(1, reset: true);
  }

  /// Narrows it to sales that came in through one channel. It leaves the
  /// conversations out — see [isTicketsOnly].
  Future<void> filterChannel(String value) {
    if (value == _channel) return Future.value();

    _channel = value;

    return _read(1, reset: true);
  }

  /// Shows only what the person signed in sold, under the same rule.
  Future<void> filterMine(bool value) {
    if (value == _mine) return Future.value();

    _mine = value;

    return _read(1, reset: true);
  }

  /// Drops every filter at once, keeping the open section.
  Future<void> clearFilters() {
    if (!isFiltered) return Future.value();

    _stage = "";
    _channel = "";
    _mine = false;

    return _read(1, reset: true);
  }

  Future<void> more() {
    if (_reading || _moreFailed || !hasMore) return Future.value();

    return _read(_page + 1);
  }

  Future<void> retryMore() {
    if (_reading || !hasMore) return Future.value();

    _moreFailed = false;

    return _read(_page + 1);
  }

  // ─── The two writes ─────────────────────────────────────────────────────────

  /// **Records how a sale reaches its customer, and how far that got.**
  ///
  /// It is one of the two writes this screen makes, and the only fact in the
  /// whole pipeline that is not measured: no collection in the platform can see
  /// a van leaving or a customer walking in for their box, so somebody says it.
  ///
  /// The answer carries the sale with the stage it now reads as, so the row is
  /// written from it rather than from a reread — and if that stage moved it to
  /// the other list, it leaves this one. The backend announces the same
  /// movement to every screen of the company; this is just the one that already
  /// has it in hand.
  ///
  /// Returns whether it was recorded. A refusal is shown and the row is left
  /// exactly as it was: a handover drawn as done because the write failed is a
  /// box nobody is going to send.
  Future<bool> fulfil(
    BuildContext context, {
    required Map<String, dynamic> request
  }) async {
    final SaleModel? sale;

    try {
      sale = await _source.fulfil(request);
    } catch (error) {
      if (kDebugMode) print("fulfilSale failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    if (sale != null) _receive(sale);

    return true;
  }

  /// **Approves a sale whose payment nobody had checked**, which closes it.
  ///
  /// The other thing on this board that only a person can say. The customer
  /// says the money is sent —that is what puts the sale at "Pago por
  /// verificar"— and nothing in this platform can see a bank: the transfer
  /// happened somewhere else and the comprobante is a photo on WhatsApp. So
  /// somebody looks at it and says so, and this is where they say it.
  ///
  /// It is a mark on the **conversation** (`PUT /chats/stage`, `STAGE: sold`)
  /// and not a sales endpoint, because that is where the payment marker it also
  /// settles lives: approving is one statement about both, and splitting it in
  /// two would leave a sale closed with the money still queued for somebody to
  /// verify.
  ///
  /// **The row is dropped rather than rewritten.** The answer is the stage now
  /// in force and not a sale, so there is nothing to write over the row with —
  /// and there is no need: an approved sale is closed, which is the other
  /// section. The backend announces the movement to every screen of the company
  /// as usual, but not always under the id this list holds (approving opens the
  /// register's own ticket for a purchase that never had one, and the notice
  /// carries the ticket), so the row this board has in hand is taken off here
  /// instead of being left to a notice that may name something else.
  ///
  /// **It is addressed by the conversation and not by the row**
  /// ([SaleModel.conversation]). The two are the same value on a deal and are
  /// not on anything else: every sale gets a ticket now, so a purchase arranged
  /// over a channel is a row whose id names the register's document while the
  /// stage it stands at —«Pago por verificar»— is the conversation's. Sending
  /// that id closed nothing and answered `404 chat_not_found`. The row is still
  /// what the board holds it by, which is what [_left] takes it off with.
  ///
  /// Returns whether it was approved. A refusal is shown and the row is left
  /// exactly where it was: a sale drawn as closed because the write failed is a
  /// payment nobody is ever going to check.
  Future<bool> approve(BuildContext context, {required SaleModel sale}) async {
    final chat = sale.conversation;

    if (chat.isEmpty) return false;

    try {
      await _source.approve(chat);
    } catch (error) {
      if (kDebugMode) print("approveSale failed: $error");

      if (context.mounted) _report(context, error);

      return false;
    }

    _left(sale.id);

    return true;
  }

  // ─── Seams ──────────────────────────────────────────────────────────────────
  //
  // The board's two hard parts are what a page becomes and what a notice does
  // to it, and neither can be exercised without the network unless there is a
  // way in. These are it — the same pair `PosInvoiceService` exposes, and for
  // the same reason: **no test may hit the network**.

  /// Puts a board on the table without a read.
  @visibleForTesting
  void seed(
    List<SaleModel> sales, {
    SaleSection section = SaleSection.process,
    String stage = "",
    int? total,
    int page = 1
  }) {
    _section = section;
    _stage = stage;
    _sales
      ..clear()
      ..addAll(sales);
    _total = total ?? sales.length;
    _page = page;
    _pending = 0;
    _status = sales.isEmpty ? SalesStatus.empty : SalesStatus.ready;
  }

  /// Feeds in a `sale/progress` frame exactly as the socket delivers it.
  @visibleForTesting
  void receive(dynamic data) => _onProgress(data);

  // ─── Internals ──────────────────────────────────────────────────────────────

  /// Writes the sale the handover answered with over the row it belongs to, or
  /// takes the row out when the sale is no longer in the open section.
  void _receive(SaleModel sale) {
    if (sale.id.isEmpty) return;

    final index = _sales.indexWhere((row) => row.id == sale.id);

    if (index == -1) return;

    final belongs = (sale.section == null || sale.section == _section)
      && (_stage.isEmpty || sale.stage == _stage);

    if (belongs) {
      _sales[index] = sale;
    } else {
      _sales.removeAt(index);
      if (_total > 0) _total--;
      _status = _sales.isEmpty ? SalesStatus.empty : SalesStatus.ready;
    }

    _notify();
  }

  /// Takes a row off the list because the sale left it, on a write whose answer
  /// cannot redraw it.
  ///
  /// It is the half of [_onProgress] that drops a row, reached from a write
  /// instead of from a notice. On the `done` tab the same movement is an
  /// arrival and there is nothing to draw it from, so the first page is read
  /// again — under the same rule as a notice about a sale nobody holds: silent
  /// on page one, announced past it, where the list is somebody's scroll.
  void _left(String id) {
    final index = _sales.indexWhere((row) => row.id == id);

    if (index != -1) {
      _sales.removeAt(index);
      if (_total > 0) _total--;
      _status = _sales.isEmpty ? SalesStatus.empty : SalesStatus.ready;

      _notify();

      return;
    }

    if (_section != SaleSection.done) return;

    if (_page > 1) {
      _pending++;
      _notify();

      return;
    }

    unawaited(_read(1, reset: true, silent: true));
  }

  /// The connection came back. Whatever moved while it was down was never
  /// delivered, and the server keeps no backlog to ask it for, so the board is
  /// read again rather than trusted.
  ///
  /// It is the same two answers a movement on a sale nobody is holding gets:
  /// on the first page it is a silent reread —the rows on screen stay until the
  /// new ones land, so a drop does not blank the board— and past it the list is
  /// somebody's scroll, so they are told there is something to pick up instead
  /// of having their place taken away.
  void _onRestored() {
    if (_disposed || _status == SalesStatus.idle) return;

    if (_page > 1) {
      _pending++;
      _notify();

      return;
    }

    _catchUp?.cancel();
    _catchUp = null;

    unawaited(_read(1, reset: true, silent: true));
  }

  /// **The person opened [sale]**: it stops being new for them (`sales.new`). Only a sale that
  /// came in through a channel can be, and it is addressed by its chat.
  void review(SaleModel sale) {
    if (sale.chat.isEmpty) return;

    if (sale.unseen) _opened(sale.chat);
    unawaited(BadgesService().opened(BadgeRow.sale, sale.chat));
  }

  /// This person opened a sale, here or on another screen.
  void _onOpened(dynamic data) {
    if (data is! Map || BadgeRow.from(data["kind"]) != BadgeRow.sale) return;

    _opened((data["id"] ?? "").toString());
  }

  void _opened(String chat) {
    if (chat.isEmpty) return;

    var changed = false;

    for (var index = 0; index < _sales.length; index++) {
      final row = _sales[index];
      if (row.chat != chat || !row.unseen) continue;

      _sales[index] = row.opened;
      changed = true;
    }

    if (changed) _notify();
  }

  /// A sale moved somewhere in the company.
  void _onProgress(dynamic data) {
    final notice = SaleProgressModel.fromEvent(data);

    if (notice.isEmpty) return;

    final index = _sales.indexWhere((row) => row.id == notice.id);

    if (index == -1) {
      _arrived(notice);
      return;
    }

    // It left this list: the other section, a stage the filter does not show,
    // or nowhere at all (a cancelled invoice, a checkout that failed).
    if (notice.isGone
      || notice.section != _section
      || (_stage.isNotEmpty && notice.stage != _stage)) {
      _sales.removeAt(index);
      if (_total > 0) _total--;
      _status = _sales.isEmpty ? SalesStatus.empty : SalesStatus.ready;

      _notify();

      return;
    }

    // Newest movement first is the order the backend answers in, so the row
    // that just moved belongs at the top — and that is also where somebody
    // watching the board is looking.
    final row = _sales.removeAt(index).moved(
      stage: notice.stage,
      label: notice.label,
      section: notice.section,
      level: notice.level,
      attention: notice.attention,
      since: notice.since
    );

    _sales.insert(0, row);

    _notify();
  }

  /// A movement on a sale this list is not holding. It may belong here now —
  /// a ticket just opened at the counter, a conversation that reached the point
  /// of being a sale— and there is no way to draw the row from the notice: it
  /// says where a sale stands, not what it is worth or who is buying.
  void _arrived(SaleProgressModel notice) {
    // Nothing this list could show. Checked before anything is scheduled, which
    // is what keeps a busy counter from rereading `process` every time a sale
    // lands in `done`.
    if (notice.isGone || notice.section != _section) return;
    if (_stage.isNotEmpty && notice.stage != _stage) return;
    if (isTicketsOnly && notice.source == SaleSource.chat) return;

    // Past the first page the list is somebody's scroll: rebuilding it from the
    // top would take away the row they were reading. They are told instead.
    if (_page > 1) {
      _pending++;
      _notify();

      return;
    }

    _catchUp?.cancel();
    _catchUp = Timer(_catchUpDelay, () {
      _catchUp = null;
      unawaited(_read(1, reset: true, silent: true));
    });
  }

  /// Reads one page.
  ///
  /// [silent] is the catch-up: the rows already on screen stay while the new
  /// ones are asked for, and a failure leaves them alone. It is a redraw
  /// nobody asked for, so it must not be able to blank the board — the worst it
  /// does is announce that there is something to pick up by hand.
  Future<void> _read(int page, {bool reset = false, bool silent = false}) async {
    if (_reading && !reset) return;

    _reading = true;
    _moreFailed = false;

    if (reset) {
      _generation++;

      if (!silent) {
        _sales.clear();
        _page = 0;
        _status = SalesStatus.loading;
        _notify();
      }
    }

    final generation = _generation;

    final SalesPage result;

    try {
      result = await _source.page(
        section: _section,
        stage: _stage,
        channel: _channel,
        mine: _mine,
        page: page,
        size: _pageSize
      );
    } catch (error) {
      if (kDebugMode) print("loadSales failed: $error");

      if (generation != _generation) return;

      _reading = false;

      if (silent) {
        // The board is still the last thing that was true. What is lost is the
        // movement that triggered this, so it is offered as something to pick
        // up rather than swallowed.
        _pending++;
      } else {
        _nothing();
      }

      _notify();

      return;
    }

    if (generation != _generation) return;

    _reading = false;

    if (!result.isLoaded) {
      if (silent) {
        _pending++;
      } else {
        _nothing();
      }

      _notify();

      return;
    }

    if (reset) {
      _sales.clear();
      _pending = 0;
      _catchUp?.cancel();
      _catchUp = null;
    }

    _total = result.total;
    _page = page;
    _sales.addAll(result.sales);

    _status = _sales.isEmpty ? SalesStatus.empty : SalesStatus.ready;

    _notify();
  }

  /// A read that failed. With nothing on screen it is an error to retry; with
  /// rows already there it is only the next page that did not come, and the
  /// board stays.
  void _nothing() {
    if (_sales.isEmpty) {
      _status = SalesStatus.error;
      return;
    }

    _moreFailed = true;
  }

  void _report(BuildContext context, Object error) {
    FloatFlag.of(context).fromError(
      error is Map && error.isNotEmpty ? error : {"message": error.toString()}
    );
  }
}
