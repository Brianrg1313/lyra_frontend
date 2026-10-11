/// One sale of the company, wherever it is standing right now.
///
/// It mirrors a row of `GET /lyra/v1/sales` (`model:/sales/pipeline.js`), and
/// the first thing to know about it is that **nothing on the backend stores a
/// list of these**. Every row is read from the collection that owns it —an open
/// ticket off the till's invoice, a purchase off the conversation the assistant
/// is holding, a charged sale off its own document— and merged on read. So a
/// row is a *measurement*, not a record: it changes because the thing behind it
/// changed, never because somebody wrote to a sales table.
///
/// That is why the columns a given source does not have are **null and not
/// zero**: a conversation that has not been priced yet has no total, and a `0`
/// there would be a claim that this sale is worth nothing.
library;

// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

/// Where a row came from, which is what decides what it can carry and what can
/// be done to it.
enum SaleSource {
  /// A cart a till still has open. It holds units and it has not been charged,
  /// so it has no handover to be at a point of.
  invoice,

  /// A charged sale. The only source with a handover, and the only one
  /// `PUT /lyra/v1/sales/fulfillment` accepts.
  ticket,

  /// A purchase the assistant is in the middle of over a channel. It has no
  /// till, no seller and no price yet.
  chat;

  /// The code as it travels. It is the enum's own name in all three cases, so
  /// it is written once here rather than repeated as a field.
  String get value => name;

  /// The source [raw] names, or [chat] when it is not one of them — the
  /// conversation is the reading that promises the least: no ticket, no money,
  /// nothing to hand over.
  static SaleSource from(dynamic raw) => switch (raw?.toString().trim()) {
    "invoice" => SaleSource.invoice,
    "ticket" => SaleSource.ticket,
    _ => SaleSource.chat
  };
}

/// The two lists the sales screen is split into.
///
/// **A sale is done when the money arrived and the goods left**, and that is
/// the whole rule. The case it exists for: a customer buys over WhatsApp and
/// the ticket is charged, so every other screen calls it sold — while the box
/// is still on a shelf waiting for a driver.
enum SaleSection {
  /// Something is still missing before the customer is done with it.
  process,

  /// Charged, collected and in the customer's hands.
  done;

  String get value => name;

  /// The section [raw] names, or null when the field is absent — which is not
  /// the same as unknown: a `sale/progress` notice with a null section is a row
  /// **leaving both lists** (a cancelled invoice, a checkout that failed).
  static SaleSection? from(dynamic raw) => switch (raw?.toString().trim()) {
    "process" => SaleSection.process,
    "done" => SaleSection.done,
    _ => null
  };
}

/// The dot a row gets, in the vocabulary the badges and the conversations
/// already use — a third screen does not invent a third palette.
enum SaleLevel {
  /// It is moving and nobody here is holding it up.
  info,

  /// Somebody has to do something about it.
  warning,

  /// It is finished.
  success;

  String get value => name;

  static SaleLevel from(dynamic raw) => switch (raw?.toString().trim()) {
    "warning" => SaleLevel.warning,
    "success" => SaleLevel.success,
    _ => SaleLevel.info
  };
}

/// A sale as the list draws it.
class SaleModel {
  const SaleModel({
    required this.id,
    this.source = SaleSource.chat,
    this.ticket = "",
    this.number = "",
    this.stage = "",
    this.label = "",
    this.section,
    this.level = SaleLevel.info,
    this.attention = false,
    this.since,
    this.channel = "",
    this.customer = "",
    this.contact = "",
    this.units = 0,
    this.total,
    this.currency = "",
    this.method = "",
    this.collected,
    this.outstanding,
    this.mode = "",
    this.state = "",
    this.seller = "",
    this.chat = "",
    this.date,
    this.updated,
    this.unseen = false
  });

  /// The handover state that means the customer has it. It is spelled here —
  /// and not read off the catalog `GET /lyra/v1/sales/stages` hands over —
  /// because it is the one value this app has to *decide* something by: whether
  /// a row still has a handover to record. It mirrors `Fulfillment.DONE`
  /// (`model:/sales/fulfillment.js`), the same way `PosInvoiceEvent` spells the
  /// four invoice event names.
  static const String delivered = "done";

  /// The stage of a sale whose customer says they paid and which nobody has
  /// checked. See [canApprove].
  static const String verifying = "verifying";

  /// What identifies the row. It is the sale's own id for a ticket or an
  /// invoice, and the **conversation's** for a deal: a chat is what a client
  /// opens, so it is what names it — falling back to the customer's contact on
  /// a deal whose chat session already expired, which keeps its state and is
  /// still a sale. It is what a row is opened, dropped and relabelled by, and
  /// it is **not** what a chat write is addressed with (see [conversation]).
  final String id;

  final SaleSource source;

  /// The ticket code (`K7M4-2QX9`), which is how people name the same sale out
  /// loud. Empty on a conversation, which has not been rung up.
  final String ticket;

  /// The branch's consecutive number of a completed sale, with the branch's series (`A-000123`).
  /// Internal control, not a fiscal number: a gap is a missing sale. Empty until it is completed.
  final String number;

  /// Where it stands, as a code (`shipping`, `verifying`, `owed`). It is what
  /// the stage filter compares against; what is *shown* is [label].
  final String stage;

  /// What the stage is called, **as the backend wrote it**. It is not
  /// translated here for the same reason a provider's name is not: the catalog
  /// that decides the wording lives on the other side
  /// (`model:/sales/progress.js`), so a stage added there shows up without a
  /// new version of the app.
  final String label;

  /// Which of the two lists the row belongs to.
  ///
  /// Null on a row that came off `GET /lyra/v1/sales`: the whole page belongs
  /// to the section that was asked for, so the field does not travel per row.
  /// It is present on the answer to a handover write, which is exactly the
  /// moment a row can change sides.
  final SaleSection? section;

  final SaleLevel level;

  /// Whether the sale is waiting on **somebody here** (send it, verify the
  /// transfer, charge the ticket) rather than on the customer (pay, come and
  /// collect). It is the difference between what is on your plate and what is
  /// on theirs.
  final bool attention;

  /// When it reached this stage. It is what the list is really read by: a
  /// ticket that has been waiting for a driver since this morning is a
  /// different problem from one charged a minute ago.
  final DateTime? since;

  /// Where the sale came in through: the counter (`pos`) or a channel.
  final String channel;

  /// Who is buying, already read down to the one value a list shows.
  final String customer;

  /// How to reach them: the phone number a conversation is happening on, the
  /// contact written on the ticket.
  final String contact;

  final int units;

  /// What it comes to. **Null on a conversation**, which has not been priced.
  final double? total;

  final String currency;

  /// How it is being settled. Empty until there is a payment on it.
  final String method;

  /// How much of it has come in. Null on anything but a credit ticket: every
  /// other method is money that was there when the ticket was written.
  final double? collected;

  /// What is still owed on it, under the same rule as [collected].
  final double? outstanding;

  /// **How** the customer gets it: `immediate`, `pickup`, `delivery`. Empty
  /// when nobody has said — which is honest and not a gap: a sale that came in
  /// through a channel could be either, and guessing would send a driver to a
  /// customer who was coming to collect.
  final String mode;

  /// **Where that got to**: `pending`, `dispatched`, `done`. Empty on a row
  /// with no handover at all — an open invoice has not been charged, so there
  /// is nothing to hand over yet.
  final String state;

  /// Who sold it, by name and never by id. A conversation the assistant is
  /// holding has no seller.
  final String seller;

  /// The conversation behind it, when there is one. A ticket rung up from a
  /// WhatsApp order carries it too.
  final String chat;

  /// When the sale started: the invoice was opened, the conversation began.
  final DateTime? date;

  /// Last movement on it, which is the order the list comes in.
  final DateTime? updated;

  /// A sale that came in through a channel and that this person has not opened yet: what the
  /// side bar's `sales.new` counts, row by row. A sale rung up at the counter never is.
  final bool unseen;

  /// Whether the row is a conversation rather than a sale with a document
  /// behind it. It is what the table checks before drawing a price or a seller.
  bool get isDeal => source == SaleSource.chat;

  /// Whether it is a cart a till still has open.
  bool get isOpen => source == SaleSource.invoice;

  /// Whether there is still a handover to record on it.
  ///
  /// Only a **charged** sale has one: an open invoice has not been paid for
  /// (the backend answers 409) and a conversation has no document at all. And
  /// only while the customer does not have it — a delivered ticket that is
  /// still owed money is a debt, not a delivery.
  bool get canFulfil =>
    source == SaleSource.ticket && state.isNotEmpty && state != delivered;

  /// **Whether somebody can approve this sale from here.**
  ///
  /// Only a sale standing at [verifying]: the customer says the money is sent
  /// and nobody has looked. That is the one point of the pipeline where a
  /// person is the missing step and where saying "the money arrived" is a
  /// statement they are in a position to make — they have the comprobante in
  /// front of them on the panel that offers the button.
  ///
  /// The stage is spelled here for the same reason [delivered] is: it is a
  /// value this app has to **decide** something by, not one it draws. It
  /// mirrors `Progress.VERIFYING` (`model:/sales/progress.js`).
  ///
  /// **It is not only a conversation's row.** Every sale gets a ticket now,
  /// whatever it came from, and an invoice opened for a purchase being arranged
  /// over a channel is drawn at *that conversation's* stage
  /// (`Pipeline.#stage`) — so a row standing here can just as easily be an
  /// `invoice` whose [id] is the register's document. Which is why the write
  /// goes to [conversation] and why a row without one is not offered the
  /// button: the endpoint addresses a chat, and there is nothing else to
  /// address it with.
  bool get canApprove => stage == verifying && conversation.isNotEmpty;

  /// **The conversation this sale is approved against**, which is the only
  /// thing `PUT /chats/stage` can be addressed by.
  ///
  /// It is [chat] and deliberately never [id]: a ticket or an invoice standing
  /// at [verifying] is one drawn at the stage of the conversation behind it,
  /// and its [id] names the register's document — a chat that does not exist,
  /// which the backend answers 404 to. On a deal the two are the same value,
  /// except on a conversation whose chat session expired: [id] falls back to
  /// the customer's contact there, and the contact is not a chat either.
  String get conversation => chat;

  /// Whether anything has been collected against it, which separates a credit
  /// ticket nobody has paid from one that is halfway there.
  bool get isPartial =>
    (collected ?? 0) > 0 && (outstanding ?? 0) > 0;

  /// The same sale after a `sale/progress` notice: the stage moved and nothing
  /// else about it did.
  ///
  /// It is a rewrite of the seven fields the notice carries and not a reread,
  /// because a stage is **measured** and the notice already carries the
  /// measurement. What the notice does not say —the total, the customer, what
  /// has been collected— is what the row already holds, and inventing a reread
  /// per notice would be one request per till in the shop.
  SaleModel moved({
    required String stage,
    required String label,
    required SaleSection? section,
    required SaleLevel level,
    required bool attention,
    DateTime? since
  }) => SaleModel(
    id: id,
    source: source,
    ticket: ticket,
    number: number,
    stage: stage,
    label: label,
    section: section,
    level: level,
    attention: attention,
    since: since ?? this.since,
    channel: channel,
    customer: customer,
    contact: contact,
    units: units,
    total: total,
    currency: currency,
    method: method,
    collected: collected,
    outstanding: outstanding,
    mode: mode,
    state: state,
    seller: seller,
    chat: chat,
    date: date,
    // The movement is what the list is ordered by, and it just happened.
    updated: since ?? DateTime.now(),
    unseen: unseen
  );

  /// The same sale, opened by this person.
  SaleModel get opened => SaleModel(
    id: id,
    source: source,
    ticket: ticket,
    number: number,
    stage: stage,
    label: label,
    section: section,
    level: level,
    attention: attention,
    since: since,
    channel: channel,
    customer: customer,
    contact: contact,
    units: units,
    total: total,
    currency: currency,
    method: method,
    collected: collected,
    outstanding: outstanding,
    mode: mode,
    state: state,
    seller: seller,
    chat: chat,
    date: date,
    updated: updated
  );

  factory SaleModel.fromJson(Map<String, dynamic> data) => SaleModel(
    id: (data["id"] ?? "").toString(),
    source: SaleSource.from(data["source"]),
    ticket: (data["ticket"] ?? "").toString(),
    number: (data["number"] ?? "").toString(),
    stage: (data["stage"] ?? "").toString(),
    label: (data["label"] ?? "").toString(),
    section: SaleSection.from(data["section"]),
    level: SaleLevel.from(data["level"]),
    attention: data["attention"] == true,
    since: saleDate(data["since"]),
    channel: (data["channel"] ?? "").toString(),
    customer: (data["customer"] ?? "").toString(),
    contact: (data["contact"] ?? "").toString(),
    units: saleCount(data["units"]),
    total: saleAmount(data["total"]),
    currency: (data["currency"] ?? "").toString().toUpperCase(),
    method: (data["method"] ?? "").toString(),
    collected: saleAmount(data["collected"]),
    outstanding: saleAmount(data["outstanding"]),
    mode: (data["mode"] ?? "").toString(),
    state: (data["state"] ?? "").toString(),
    seller: (data["seller"] ?? "").toString(),
    chat: (data["chat"] ?? "").toString(),
    date: saleDate(data["date"]),
    updated: saleDate(data["updated"]),
    unseen: data["unseen"] == true
  );
}

/// One page of one section of the list.
class SalesPage {
  const SalesPage({
    this.section = SaleSection.process,
    this.page = 1,
    this.size = 0,
    this.total = 0,
    this.sales = const [],
    this.isLoaded = false
  });

  /// Which of the two lists was answered. It is echoed back by the endpoint
  /// because a `STAGE` already implies its section and can override the one
  /// that was asked for.
  final SaleSection section;

  final int page;
  final int size;

  /// How many sales the **section** holds, which is not how many the page
  /// carries: a `STAGE` narrows the page and not the query (a stage is
  /// measured, so Mongo cannot filter by it), so a narrow stage answers with
  /// fewer rows than `size` while this still counts the whole section.
  final int total;

  final List<SaleModel> sales;

  final bool isLoaded;

  factory SalesPage.fromResponse(dynamic data) {
    if (data is! Map) return const SalesPage();

    return SalesPage(
      section: SaleSection.from(data["section"]) ?? SaleSection.process,
      page: saleCount(data["page"]),
      size: saleCount(data["size"]),
      total: saleCount(data["total"]),
      sales: [
        for (final row in catalogRows(data["sales"])) SaleModel.fromJson(row)
      ],
      isLoaded: true
    );
  }
}

/// An amount, or **null when there is none**.
///
/// It is not the money section's `moneyDouble`, which answers `0` for a missing
/// field: half the columns of this list are legitimately absent —a conversation
/// has no total, a cash ticket has nothing outstanding— and a zero there would
/// be read as a priced sale worth nothing and as a debt of nothing.
double? saleAmount(dynamic raw) => switch (raw) {
  final num value => value.toDouble(),
  final String text => double.tryParse(text.trim()),
  _ => null
};

/// A count. Units are the one number every source answers, so this one does
/// fall back to zero.
int saleCount(dynamic raw) => switch (raw) {
  final num value => value.toInt(),
  final String text => int.tryParse(text.trim()) ?? 0,
  _ => 0
};

/// A date as the backend writes it (ISO, UTC), or null. It is **not** converted
/// here: whoever draws it moves it to local time, which is where the language
/// to write it in is also known.
DateTime? saleDate(dynamic raw) {
  if (raw == null) return null;
  if (raw is DateTime) return raw;

  return DateTime.tryParse(raw.toString().trim());
}
