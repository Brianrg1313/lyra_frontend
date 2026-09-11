/// The socket notices an invoice raises while it is open.
///
/// **A ticket is not only edited by the till it was opened at.** It is a
/// document, so the stock screen can cancel it, another register can charge it
/// and a line can come off it from somewhere this counter cannot see — and a
/// panel that only learns about that when it tries to charge would be a cashier
/// finding out with a customer in front of them.
///
/// The four names are a contract handwritten on both sides (the backend emits
/// them from the invoice routes), so they live in one place: a misspelled event
/// does not fail, it simply never arrives.
///
/// The payload is deliberately thin — the backend sends what a *screen* needs to
/// decide whether to look again, not the invoice itself, because every terminal
/// in the company receives it and almost none of them care. So this says which
/// ticket moved and how much of it there is now; whoever is holding that ticket
/// reads it back in full.
class PosInvoiceEvent {
  /// An invoice was opened somewhere in the company. Nothing listens to it yet:
  /// it is what the strip of open tabs would be drawn from, and the counter
  /// only ever holds the one it opened itself.
  static const String opened = "invoice/opened";

  /// A line was written on it: added, stepped or taken off.
  static const String updated = "invoice/updated";

  /// It was charged. The units it held are sold and the document is sealed.
  static const String closed = "invoice/closed";

  /// It was thrown away. Everything it held is back on sale.
  static const String cancelled = "invoice/cancelled";

  const PosInvoiceEvent({
    this.id = "",
    this.ticket = "",
    this.units = 0,
    this.total = 0
  });

  /// The invoice the notice is about. Empty when it could not be read, which is
  /// the only way one is discarded.
  final String id;

  /// The ticket code (`K7M4-2QX9`), which is how people name the same document.
  final String ticket;

  /// Units on it after the change. It is the cheap way to tell a notice that
  /// changes something apart from the echo of a write this till just made.
  final int units;

  /// What it comes to after the change, tax included.
  final double total;

  factory PosInvoiceEvent.fromEvent(dynamic data) {
    if (data is! Map) return const PosInvoiceEvent();

    return PosInvoiceEvent(
      id: (data["id"] ?? "").toString(),
      ticket: (data["ticket"] ?? "").toString(),
      units: switch (data["units"]) {
        final num value => value.toInt(),
        final String text => int.tryParse(text) ?? 0,
        _ => 0
      },
      total: switch (data["total"]) {
        final num value => value.toDouble(),
        final String text => double.tryParse(text) ?? 0,
        _ => 0
      }
    );
  }

  /// Whether the notice names an invoice at all.
  bool get isEmpty => id.isEmpty;
}

/// What happened to the ticket **somewhere other than this counter**, waiting to
/// be said out loud.
///
/// It is an enum and not a sentence because the copy belongs in the tree
/// (`S.of(context)`) and this is a service: what the service knows is which of
/// the three things happened, and the panel is what says it.
enum PosTicketNotice {
  /// Somebody charged it from another register. It is a finished sale now and
  /// this counter starts clean.
  charged,

  /// Somebody cancelled it — from another till, or from the stock screen. The
  /// units it was holding are back on sale.
  cancelled,

  /// Its held units were released underneath it: the shelf is holding fewer
  /// than this ticket claims. What is on the ticket stays, but it is no longer
  /// set aside for this customer.
  released
}
