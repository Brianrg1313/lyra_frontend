import 'dart:async';

import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/connection/connection_service.dart';
import 'package:app/services/pos/pos_cart_line.dart';
import 'package:app/services/pos/pos_invoice_event.dart';
import 'package:app/services/pos/pos_invoice_model.dart';
import 'package:app/services/pos/pos_product_model.dart';
import 'package:app/services/stock/movements/stock_changed_model.dart';
import 'package:app/toolkit/api.dart';

/// What the ticket on screen is up to.
///
/// [idle] is a counter with nothing on it: no invoice has been opened, so
/// nothing is held anywhere. [ready] is an open invoice, which is a ticket with
/// a code and units taken off the shelf for it.
enum PosInvoiceStatus { idle, opening, ready, closing, error }

/// **The ticket being rung up, which is an invoice on the backend.**
///
/// It used to be a list in memory. It cannot be: everything that happens while a
/// customer is standing at the counter has to be *somewhere*, and the client's
/// memory is the one place it may not be — a reload loses the sale, a second
/// till cannot see it, and, the part that costs a company money, **the units
/// nobody has taken off the shelf yet go on being offered to every other
/// terminal and every bot**.
///
/// So the ticket is a document from the moment the first product lands on it:
///
/// ```
/// POST /pos/invoices          the ticket exists, code and all; nothing charged
/// PUT  /pos/invoices/items    a product goes on it — and its units are HELD
/// POST /pos/invoices/close    the held units become sold; the ticket is sealed
/// POST /pos/invoices/cancel   every held unit goes back on sale
/// ```
///
/// **The invoice opens on the first line and not when the screen does.** An
/// empty invoice per till per shift would be a tab nobody opened, holding
/// nothing, that somebody has to clean up; the ticket code is only worth minting
/// when there is a sale to put it on.
///
/// ## What is drawn versus what is true
///
/// Every write answers with the whole invoice, and that answer is the truth:
/// prices, quantities and totals are the backend's, which is what makes the
/// figure on the screen and the figure that gets charged the same figure. But a
/// counter cannot wait for a round trip before drawing a tap, so a change is
/// applied here first and reconciled with the answer when it lands — and only
/// when nothing else is in flight ([_pending]), because adopting an older
/// answer over a newer tap is how a quantity jumps backwards while somebody is
/// pressing "+".
///
/// A write that fails does not leave a guess on the screen: the invoice is read
/// again and the ticket goes back to what the backend has. The reason is left in
/// [error] for whoever asked to announce.
///
/// ## Leaving POS does not throw the ticket away
///
/// The page discards this service, not the invoice: the document stays open and
/// its units stay held, and [recover] finds it again the next time this till
/// opens the counter. Giving the units back is [discard], which is a decision
/// somebody makes — the customer changed their mind — and never a side effect of
/// closing a window.
///
/// ## The ticket is told what happens to it elsewhere
///
/// A ticket is a document, and a document can be touched from screens this
/// counter cannot see: another register charges it, the stock panel cancels it,
/// the units it was holding are given back. **None of that is visible from
/// here** — the invoice goes on saying it holds what it was holding — so the
/// counter would find out with a customer already paying.
///
/// So it listens, and reacts to the three things that change a sale:
///
/// | Notice | What it means | What happens here |
/// |---|---|---|
/// | `invoice/updated` | somebody wrote a line on this ticket | it is read again |
/// | `invoice/closed` / `invoice/cancelled` | this ticket is finished elsewhere | the counter starts clean |
/// | `stock/changed` | a balance moved | the ticket checks its own holds |
///
/// The last one is the one that cannot be answered by re-reading: releasing a
/// hold does not touch the invoice, so what says the units are gone is the
/// **ledger's own counter** against what this ticket claims — see [_onStock].
/// What it found is left in [notice] for the panel to announce.
class PosInvoiceService extends ChangeNotifier {
  /// Subscribes to what the company does to this ticket while nobody here is
  /// looking. The handlers are registered on construction and not when an
  /// invoice is opened, because a ticket recovered on load ([recover]) has to
  /// be watched too, and the socket keeps them across a reconnection.
  PosInvoiceService() {
    _unlisten = [
      for (final event in const [
        PosInvoiceEvent.updated,
        PosInvoiceEvent.closed,
        PosInvoiceEvent.cancelled,
        StockChangedModel.event
      ])
        ConnectionService().on(event, (data) => receive(event, data))
    ];
  }

  /// How each subscription is dropped. Without this the handlers outlive the
  /// page —the connection is a singleton and this service is not— and a closed
  /// counter would go on reading invoices.
  List<void Function()> _unlisten = const [];

  /// Most units one line may carry. A guard against a stuck key on the "+",
  /// not a business rule: nobody sells a thousand of one thing by tapping.
  static const int maxQuantity = 999;

  /// Highest tax percentage the ticket accepts. A rate is written as `16` and
  /// not as `0.16` (the same as the backend's `TAX`), so anything past a
  /// hundred is a typo and not a country.
  static const double maxTax = 100;

  PosInvoiceStatus _status = PosInvoiceStatus.idle;

  PosInvoice? _invoice;

  /// The lines as they are drawn. They are the backend's after every settled
  /// answer, and one tap ahead of it in between.
  List<PosCartLine> _lines = const [];

  /// Percentage charged on the ticket.
  ///
  /// **It starts at zero and is set at the counter.** Neither the business
  /// profile nor `/pos/` carries a rate, and defaulting to the one of whatever
  /// country this app was written in would quietly overcharge every business
  /// that does not charge it. It travels on every line as it is created, and
  /// changing it rewrites the lines that are already there.
  double _tax = 0;

  /// How many writes are in flight. While it is not zero the screen is ahead of
  /// the backend on purpose and no answer is adopted.
  int _pending = 0;

  /// The invoice being opened, so two products tapped at once do not open two
  /// tickets. Everything that needs an invoice awaits this one.
  Future<bool>? _opening;

  /// Whether this counter is the one ending the ticket right now.
  ///
  /// Charging and cancelling are announced to the whole company, and the notice
  /// can beat the answer home — which would have the till that pressed the
  /// button told that somebody else pressed it.
  bool _ending = false;

  /// Where a line's key comes from while it is being created. Two typed-in
  /// charges called the same thing are two charges, so they cannot be keyed by
  /// what they say.
  int _sequence = 0;

  /// The last failure, already normalized to `{message, action}` by the api
  /// layer. Whoever asked for the write reads it to announce it and it is
  /// cleared on the next attempt.
  Map<String, dynamic>? _error;

  /// What happened to this ticket somewhere else and has not been said out loud
  /// yet. Unlike [error] it belongs to nobody who asked for anything: it arrives
  /// on its own, so it waits here until the panel announces it.
  PosTicketNotice? _notice;

  /// What the notice is about — the product whose units were let go. Empty on
  /// the ones that are about the whole ticket.
  String _noticeLabel = "";

  PosInvoiceStatus get status => _status;

  /// The open invoice, or null when nothing has been rung up yet.
  PosInvoice? get invoice => _invoice;

  /// The ticket's code (`K7M4-2QX9`), empty until the invoice is opened. It is
  /// the real name of this sale, and it exists long before it is paid.
  String get ticket => _invoice?.ticket ?? "";

  List<PosCartLine> get lines => _lines;

  bool get isEmpty => _lines.isEmpty;

  /// Whether a write is travelling. It is what dims the checkout while the
  /// ticket is still settling.
  bool get isBusy => _pending > 0 || _status == PosInvoiceStatus.opening;

  bool get isClosing => _status == PosInvoiceStatus.closing;

  Map<String, dynamic>? get error => _error;

  /// What the company did to this ticket, waiting to be announced. It is
  /// cleared by [clearNotice] once it has been, so it is said once and not on
  /// every rebuild.
  PosTicketNotice? get notice => _notice;

  /// The product named by [notice], when it names one.
  String get noticeLabel => _noticeLabel;

  /// Whether some of what is on the ticket is no longer set aside for this
  /// customer. It is what dims nothing and warns about everything: the sale can
  /// still be charged —the backend takes the units again when it closes, or
  /// refuses saying they are gone— but the counter has to know.
  bool get isShort => _lines.any((line) => !line.isHeld);

  /// Everything on the ticket, counting units and not lines: three of one
  /// product is three products to whoever is bagging them.
  int get units => _lines.fold(0, (sum, line) => sum + line.quantity);

  double get subtotal => _lines.fold(0, (sum, line) => sum + line.total);

  double get taxRate => _tax;

  double get tax => subtotal * _tax / 100;

  double get total => subtotal + tax;

  // ─── Reading ────────────────────────────────────────────────────────────────

  /// Picks up the invoice this till left open, if it left one.
  ///
  /// `MINE=1` narrows the company's open tabs to the terminal asking, which is
  /// how a register gets its own screen back after a reload without a device id
  /// ever travelling in or out. It is the oldest one: this counter only builds
  /// one at a time, so more than one means an earlier session ended without
  /// charging or cancelling, and the one that has been holding units longest is
  /// the one somebody has to deal with.
  ///
  /// Finding nothing is the ordinary case and not a failure — most of the time
  /// the till was left clean.
  Future<void> recover() async {
    if (_invoice != null || _status == PosInvoiceStatus.opening) return;

    dynamic data;

    try {
      // The filters travel in the query string and not in the path: `Uri`
      // escapes a `?` written into a path, which would ask for every open tab
      // in the company without saying so.
      data = await api.get(
        path: "/pos/invoices/",
        version: "v1",
        query: {"MINE": 1, "SIZE": 1}
      );
    } catch (error) {
      if (kDebugMode) print("recoverPosInvoice failed: $error");

      // Nothing is reported: the counter works without recovering anything, and
      // an error about a ticket nobody has opened yet would be noise on a
      // screen that has not been used.
      return;
    }

    final invoices = data is Map ? data["invoices"] : null;

    if (invoices is! List || invoices.isEmpty) return;

    final invoice = PosInvoice.fromJson(invoices.first);

    if (!invoice.isValid || !invoice.isOpen) return;

    _adopt(invoice);

    _status = PosInvoiceStatus.ready;

    notifyListeners();
  }

  /// Takes an invoice as if the backend had just answered with it.
  ///
  /// Nothing in the app calls this: every other way into this service travels.
  /// It exists so the rules that hang off a ticket —what its lines add up to,
  /// what rate they carry, what the panel draws— can be pinned without a
  /// network, which they otherwise could not be at all.
  @visibleForTesting
  void seed(PosInvoice invoice) {
    _adopt(invoice);

    _status = PosInvoiceStatus.ready;

    notifyListeners();
  }

  // ─── Writing ────────────────────────────────────────────────────────────────

  /// Puts a product on the ticket, or adds a unit to the line it already has —
  /// **and holds its units right then**, so from this instant no other till, no
  /// stock screen and no bot is offered them.
  ///
  /// Returns `false` when it could not go on: a product with no price (null is
  /// not zero, see [PosProduct.price]) is refused here, and a shelf that cannot
  /// cover the unit is refused by the backend with the reason left in [error].
  /// Either way nothing changes — the product simply does not go on the ticket,
  /// instead of going on it and being discovered missing when the customer is
  /// already paying.
  Future<bool> add(PosProduct product) async {
    if (product.id.isEmpty || product.price == null) return false;

    if (!await _ensure()) return false;

    final index = _lines.indexWhere((line) => line.productId == product.id);

    // Drawn before it travels. The key is the product's own id until the
    // backend answers with the line's, which is also what makes a second tap
    // land on this same line instead of opening another one.
    if (index == -1) {
      _lines = [
        ..._lines,
        PosCartLine(
          key: "${PosCartLine.draft}${product.id}",
          label: product.label,
          price: product.price ?? 0,
          quantity: 1,
          productId: product.id,
          // Drawn as held for the same reason the line is drawn at all: the
          // write that holds it is already travelling, and the answer is what
          // corrects both.
          held: 1
        )
      ];
    } else {
      _lines = _replace(index, _lines[index].withQuantity(_lines[index].quantity + 1));
    }

    notifyListeners();

    return await _write({"PRODUCT_ID": product.id, "ADD": 1, "TAX": _tax});
  }

  /// Charges an amount that is not a product: a delivery, a repair, something
  /// the catalog does not have yet.
  ///
  /// It is a line of its own and never merges with another one, even written
  /// the same: two charges called "delivery" on one ticket are two things that
  /// happened, and collapsing them would lose one of the two prices.
  ///
  /// **It holds nothing.** There is no product, so there is no shelf to take
  /// anything off — it is money on the ticket and silence in the ledger, and
  /// the seller and the till are on the document for whoever audits it.
  Future<bool> addAmount({required String label, required double price}) async {
    final name = label.trim();

    if (name.isEmpty || price < 0) return false;

    if (!await _ensure()) return false;

    _sequence++;

    _lines = [
      ..._lines,
      PosCartLine(
        key: "${PosCartLine.draft}$_sequence",
        label: name,
        price: price,
        quantity: 1
      )
    ];

    notifyListeners();

    return await _write({"CONCEPT": name, "ADD": 1, "PRICE": price, "TAX": _tax});
  }

  /// One unit more of a line.
  Future<bool> increase(String key) {
    final line = _find(key);

    if (line == null || line.quantity >= maxQuantity) return Future.value(false);

    return _step(line, 1);
  }

  /// One unit less, and **the line comes off the ticket at one**. Taking the
  /// last unit off is how a product is un-rung at a counter, and it is also what
  /// gives its units straight back to the shelf.
  Future<bool> decrease(String key) {
    final line = _find(key);

    if (line == null) return Future.value(false);

    return _step(line, -1);
  }

  /// Takes the whole line off the ticket, giving back everything it held.
  Future<bool> remove(String key) async {
    final line = _find(key);

    if (line == null) return false;

    final address = _address(line);

    if (address == null) return false;

    _lines = _lines.where((entry) => entry.key != key).toList(growable: false);

    notifyListeners();

    return await _write({...address, "QUANTITY": 0});
  }

  /// Sets the percentage charged on the ticket.
  ///
  /// **The rate lives on the lines and not on the ticket**: the backend freezes
  /// it when a line is created, so that a ticket charges what was quoted while
  /// the customer was standing there. Changing it therefore rewrites every line
  /// that is already on the invoice — one write each, in order — instead of one
  /// call that does not exist.
  ///
  /// Anything outside 0–[maxTax] is clamped instead of refused: the field that
  /// writes it already validates, and this is the last guard before a total
  /// nobody can explain.
  Future<void> setTax(double rate) async {
    final value = rate.isNaN ? 0.0 : rate.clamp(0.0, maxTax).toDouble();

    if (value == _tax) return;

    _tax = value;

    notifyListeners();

    for (final line in [..._lines]) {
      final address = _address(line);

      if (address == null) continue;

      // The quantity travels with it because the endpoint always wants to be
      // told how many the line ends up with; it is the one it already has.
      if (!await _write({...address, "QUANTITY": line.quantity, "TAX": value})) return;
    }
  }

  /// **Charges the ticket.** The held units become sold, the shelf is debited
  /// and the document is sealed with the code it has carried all along.
  ///
  /// The money is not sent: the backend computes it from the lines and refuses
  /// to take a total from the client at all, because the figure a company
  /// reconciles its register against cannot come from the screen being
  /// reconciled. What comes back is the finished ticket, which is what the
  /// counter announces.
  ///
  /// Returns null when it could not be charged, with the reason in [error] —
  /// somebody else charged it, or a line's units are no longer there.
  Future<PosInvoice?> checkout({
    required String method,
    String reference = "",
    String note = ""
  }) async {
    final invoice = _invoice;

    if (invoice == null || _lines.isEmpty || _status == PosInvoiceStatus.closing) {
      return null;
    }

    _error = null;
    _ending = true;
    _status = PosInvoiceStatus.closing;
    notifyListeners();

    dynamic data;

    try {
      data = await api.post(
        path: "/pos/invoices/close/",
        version: "v1",
        data: {
          "ID": invoice.id,
          "METHOD": method,
          if (reference.trim().isNotEmpty) "REFERENCE": reference.trim(),
          if (note.trim().isNotEmpty) "NOTE": note.trim()
        }
      );
    } catch (error) {
      if (kDebugMode) print("closePosInvoice failed: $error");

      _ending = false;
      _fail(error);
      _status = PosInvoiceStatus.ready;

      // The close is the one write that can fail on something that changed
      // underneath (a line's units are gone, somebody else charged it), so the
      // ticket is read again rather than left as it was drawn.
      await _refresh();

      notifyListeners();

      return null;
    }

    final sale = PosInvoice.fromJson(data);

    _ending = false;

    if (!sale.isValid) {
      _status = PosInvoiceStatus.ready;
      notifyListeners();

      return null;
    }

    // The sale is somebody else's to draw now. The counter goes back to an
    // empty ticket, ready for the next customer.
    _reset();

    return sale;
  }

  /// Throws the ticket away: every unit it was holding goes back on sale and
  /// the document is closed as cancelled.
  ///
  /// **It is the call that must be made when a sale does not happen.** Until it
  /// is, the products on this invoice are held and no other till is offered
  /// them. The document is kept and not deleted — a cart somebody built and
  /// walked away from is a fact about the day.
  ///
  /// With no invoice open it is a local clear and nothing travels: there is
  /// nothing holding anything.
  Future<bool> discard() async {
    final invoice = _invoice;

    if (invoice == null) {
      _reset();

      return true;
    }

    _error = null;
    _ending = true;

    try {
      await api.post(
        path: "/pos/invoices/cancel/",
        version: "v1",
        data: {"ID": invoice.id}
      );
    } catch (error) {
      if (kDebugMode) print("cancelPosInvoice failed: $error");

      _ending = false;
      _fail(error);
      notifyListeners();

      return false;
    }

    _ending = false;

    _reset();

    return true;
  }

  /// Marks the notice as said, so it is announced once.
  void clearNotice() {
    if (_notice == null) return;

    _notice = null;
    _noticeLabel = "";
  }

  // ─── What the company does to this ticket ───────────────────────────────────

  /// Takes an event as if the socket had just delivered it.
  ///
  /// It is the one door in: the constructor points every subscription at it, and
  /// a test drives the same rules without a connection. Everything it can do is
  /// harmless when the notice is about somebody else's ticket, which is the
  /// ordinary case — every terminal in the company receives all of them.
  @visibleForTesting
  void receive(String event, dynamic data) {
    switch (event) {
      case PosInvoiceEvent.updated:
        _onWritten(data);
      case PosInvoiceEvent.closed:
        _onFinished(data, PosTicketNotice.charged);
      case PosInvoiceEvent.cancelled:
        _onFinished(data, PosTicketNotice.cancelled);
      case StockChangedModel.event:
        _onStock(data);
    }
  }

  /// Somebody wrote a line on this ticket from another screen.
  ///
  /// The notice carries what the invoice comes to and not what changed, so the
  /// document is read back in full. Nothing is done while a write of this
  /// counter's own is travelling: the echo of that write is this same event, and
  /// re-reading over a tap that has not landed is how a quantity walks backwards.
  void _onWritten(dynamic data) {
    final invoice = _invoice;
    final event = PosInvoiceEvent.fromEvent(data);

    if (invoice == null || _pending > 0 || event.id != invoice.id) return;

    // The echo of a write that already landed here: the figures agree, so there
    // is nothing to go and read. Cents and not exact equality because the total
    // is money that travelled as a number.
    if (event.units == units && (event.total - total).abs() < 0.01) return;

    unawaited(_refresh());
  }

  /// This ticket ended somewhere else: another register charged it, or somebody
  /// cancelled it. Either way it is not this counter's to write on any more, so
  /// it starts clean — and says why, which is the whole point of listening.
  void _onFinished(dynamic data, PosTicketNotice reason) {
    final invoice = _invoice;
    final event = PosInvoiceEvent.fromEvent(data);

    if (invoice == null || _ending || event.id != invoice.id) return;

    _notice = reason;
    _noticeLabel = "";

    _reset();
  }

  /// A balance moved, and this ticket checks whether what moved was **its own
  /// hold**.
  ///
  /// This is the one thing a counter cannot learn by reading its own invoice.
  /// Releasing a hold from the stock screen moves the ledger and does not touch
  /// the document, so the ticket goes on saying it holds units the shelf no
  /// longer holds — the exact case the register discovers when the customer is
  /// already paying.
  ///
  /// What proves it is one comparison: the notice carries **the whole company's**
  /// `reserved` for that product, so `reserved` below what *this ticket alone*
  /// claims to hold is arithmetic, not a guess — those units cannot be held by
  /// anyone. The lines are cut down to what is left, oldest first.
  ///
  /// The other direction is not detectable and is deliberately not attempted: a
  /// release masked by another till's hold looks like a balance that did not
  /// move. It is bounded on the other side by the close, which takes the units
  /// again before it charges and refuses when the shelf cannot cover them.
  ///
  /// Nothing is done while a write is in flight: what is drawn is a tap ahead of
  /// the backend on purpose, and the balance travelling belongs to the ticket
  /// this counter is still writing.
  void _onStock(dynamic data) {
    if (_invoice == null || _pending > 0) return;

    final change = StockChangedModel.fromEvent(data);

    if (change.isEmpty) return;

    final mine = _lines
      .where((line) => line.productId == change.productId)
      .fold(0, (sum, line) => sum + line.held);

    if (mine == 0 || change.reserved >= mine) return;

    final rebuilt = <PosCartLine>[];

    // What is left of the shelf's hold to hand out among this ticket's lines.
    int left = change.reserved;
    String label = "";

    for (final line in _lines) {
      if (line.productId != change.productId) {
        rebuilt.add(line);
        continue;
      }

      if (line.held <= left) {
        left -= line.held;
        rebuilt.add(line);
        continue;
      }

      if (label.isEmpty) label = line.label;

      rebuilt.add(line.withHeld(left));

      left = 0;
    }

    _lines = List.unmodifiable(rebuilt);

    _notice = PosTicketNotice.released;
    _noticeLabel = label;

    notifyListeners();
  }

  @override
  void dispose() {
    for (final remove in _unlisten) {
      remove();
    }

    _unlisten = const [];

    super.dispose();
  }

  // ─── Internals ──────────────────────────────────────────────────────────────

  /// Makes sure there is an invoice to write on, opening one the first time.
  ///
  /// Two products tapped in the same instant must not open two tickets, so the
  /// attempt is shared: the second tap awaits the first one's invoice instead of
  /// starting another.
  Future<bool> _ensure() {
    if (_invoice != null) return Future.value(true);

    final opening = _opening;

    if (opening != null) return opening;

    final attempt = _open();
    _opening = attempt;

    return attempt.whenComplete(() => _opening = null);
  }

  Future<bool> _open() async {
    _error = null;
    _status = PosInvoiceStatus.opening;
    notifyListeners();

    dynamic data;

    try {
      // No `TABLE_ID`: the backend sells the company's main table and says
      // which one it was, so the counter never carries a table id from screen
      // to screen. `TAX` is the rate every line inherits unless it carries its
      // own — and they all carry their own, so this is only the ticket's
      // default.
      data = await api.post(
        path: "/pos/invoices/",
        version: "v1",
        data: {"TAX": _tax}
      );
    } catch (error) {
      if (kDebugMode) print("openPosInvoice failed: $error");

      _fail(error);
      _status = PosInvoiceStatus.error;
      notifyListeners();

      return false;
    }

    final invoice = PosInvoice.fromJson(data);

    if (!invoice.isValid) {
      _status = PosInvoiceStatus.error;
      notifyListeners();

      return false;
    }

    _invoice = invoice;
    _status = PosInvoiceStatus.ready;
    notifyListeners();

    return true;
  }

  /// One line edit: it travels, and what comes back replaces what is drawn when
  /// nothing else is still in flight.
  Future<bool> _write(Map<String, dynamic> body) async {
    final invoice = _invoice;

    if (invoice == null) return false;

    _error = null;
    _pending++;

    dynamic data;

    try {
      data = await api.put(
        path: "/pos/invoices/items/",
        version: "v1",
        data: {"ID": invoice.id, ...body}
      );
    } catch (error) {
      if (kDebugMode) print("writePosInvoiceLine failed: $error");

      _pending--;
      _fail(error);

      // What is on screen was a guess and the guess was wrong. Reading the
      // invoice again is what puts the ticket back to what is actually held —
      // leaving the line drawn would be a unit nobody has.
      await _refresh();

      notifyListeners();

      return false;
    }

    _pending--;

    final answer = data is Map ? data["invoice"] : null;
    final updated = PosInvoice.fromJson(answer);

    // An answer that arrives while another tap is already travelling is older
    // than the screen: adopting it would walk a quantity backwards under the
    // finger that is pressing "+". The last one home is the one that lands.
    if (updated.isValid && _pending == 0) _adopt(updated);

    notifyListeners();

    return true;
  }

  /// Reads the invoice back and draws what it says.
  ///
  /// It is what a failed write falls back on, so it never reports anything of
  /// its own: the failure being recovered from is what gets announced, and a
  /// second error over it would say the same thing twice.
  Future<void> _refresh() async {
    final invoice = _invoice;

    if (invoice == null || _pending > 0) return;

    dynamic data;

    try {
      // The company's open tabs and not this till's: an invoice this counter is
      // holding can have been charged from another register, and `MINE` would
      // hide exactly the case that has to be noticed. A hundred is the page the
      // endpoint caps at, and a shop with more open tabs than that has a
      // problem this read is not going to solve.
      data = await api.get(
        path: "/pos/invoices/",
        version: "v1",
        query: {"SIZE": 100}
      );
    } catch (error) {
      if (kDebugMode) print("readPosInvoice failed: $error");

      return;
    }

    final invoices = data is Map ? data["invoices"] : null;

    if (invoices is! List) return;

    for (final entry in invoices) {
      final open = PosInvoice.fromJson(entry);

      if (open.id != invoice.id) continue;

      _adopt(open);

      return;
    }

    // It is not open any more: somebody charged it or cancelled it from another
    // screen. The counter cannot go on writing to it, so it starts clean.
    _reset();
  }

  /// Moves a line by [delta] units.
  Future<bool> _step(PosCartLine line, int delta) async {
    final address = _address(line);

    if (address == null) return false;

    final quantity = line.quantity + delta;
    final index = _lines.indexOf(line);

    _lines = quantity <= 0
      ? _lines.where((entry) => entry.key != line.key).toList(growable: false)
      : _replace(index, line.withQuantity(quantity));

    notifyListeners();

    // `ADD` and not a computed total: a counter is a screen where two taps
    // arrive within one round trip, and a relative move is the only one that
    // cannot lose a unit between them.
    return await _write({...address, "ADD": delta});
  }

  /// How a line is pointed at on the backend.
  ///
  /// A product is addressed by its id, which is what makes two taps on the same
  /// tile one line of two whatever else is travelling. A charge that is not a
  /// product has only its own line id, so it cannot be edited until the backend
  /// has answered with one — which is why it is drawn as pending until then.
  Map<String, dynamic>? _address(PosCartLine line) {
    final product = line.productId;

    if (product != null) return {"PRODUCT_ID": product};

    return line.isPending ? null : {"LINE_ID": line.key};
  }

  PosCartLine? _find(String key) {
    for (final line in _lines) {
      if (line.key == key) return line;
    }

    return null;
  }

  List<PosCartLine> _replace(int index, PosCartLine line) => [
    for (int i = 0; i < _lines.length; i++)
      if (i == index) line else _lines[i]
  ];

  /// Takes the backend's invoice as what is drawn.
  ///
  /// The rate is read back from the lines because the ticket's own default does
  /// not travel in the response: every line is created carrying it, so the
  /// first line's rate is the ticket's. An invoice with no lines keeps whatever
  /// was set here, which is the counter's own setting and not the document's.
  void _adopt(PosInvoice invoice) {
    _invoice = invoice;

    _lines = [
      for (final line in invoice.items)
        PosCartLine(
          key: line.lineId,
          label: line.name,
          price: line.price,
          quantity: line.quantity,
          productId: line.productId,
          held: line.held
        )
    ];

    if (invoice.items.isNotEmpty) _tax = invoice.items.first.taxRate;
  }

  /// Back to a counter with nothing on it. The rate survives: it is how this
  /// till charges, not something about the sale that just ended.
  void _reset() {
    _invoice = null;
    _lines = const [];
    _pending = 0;
    _status = PosInvoiceStatus.idle;

    notifyListeners();
  }

  void _fail(dynamic error) {
    _error = error is Map ? Map<String, dynamic>.from(error) : null;
  }
}
