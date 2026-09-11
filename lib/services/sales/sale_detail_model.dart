/// One sale opened up: what is on it, what it comes to, how it is being paid,
/// where it was made and how far the handover got.
///
/// It mirrors `GET /lyra/v1/sales/detail/:ID` (`Pipeline.detail`), which is the
/// row of `GET /lyra/v1/sales` with everything the list deliberately leaves
/// out — a page of fifty sales carrying every line of every one of them is a
/// payload nobody reads.
///
/// **It is one shape for all three sources.** A cart a till still has open, a
/// purchase the assistant is arranging over a channel and a charged ticket all
/// answer with the same keys, and what a given source genuinely does not have
/// reads `null` rather than zero: a conversation has no code, no seller, no tax
/// and no handover, because nobody has rung it up. That is the same rule
/// [SaleModel] follows, and it is why this is not three models.
library;

// SERVICES
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/files/file_model.dart';
import 'package:app/services/sales/sale_model.dart';

/// A sale in full.
class SaleDetailModel {
  const SaleDetailModel({
    this.id = "",
    this.source = SaleSource.chat,
    this.ticket = "",
    this.status = "",
    this.stage = "",
    this.label = "",
    this.section,
    this.level = SaleLevel.info,
    this.attention = false,
    this.since,
    this.channel = "",
    this.origin,
    this.customer = "",
    this.contact = "",
    this.chat = "",
    this.seller = "",
    this.note = "",
    this.currency = "",
    this.units = 0,
    this.subtotal,
    this.tax,
    this.taxes = const [],
    this.total,
    this.payment = const SalePaymentModel(),
    this.handover,
    this.held = 0,
    this.reservations,
    this.items = const [],
    this.opened,
    this.closed,
    this.date,
    this.updated
  });

  /// What names the sale: its own id for a ticket or an invoice, the
  /// conversation's for a deal.
  final String id;

  final SaleSource source;

  /// The ticket code as it is printed. Empty on a sale nobody rang up.
  final String ticket;

  /// What the *document* says about itself (`open`, `completed`, `cancelled`).
  /// It is not [stage]: the document knows it was charged, and the stage knows
  /// the customer is still waiting for the box. Empty on a conversation, which
  /// has no document.
  final String status;

  final String stage;

  /// What the stage is called, as the backend wrote it. Shown as received, like
  /// a provider's name — see [SaleModel.label].
  final String label;

  /// Which of the two lists it belongs to.
  final SaleSection? section;

  final SaleLevel level;

  /// Whether it is waiting on somebody here rather than on the customer.
  final bool attention;

  /// When it reached this stage.
  final DateTime? since;

  /// Where it came in through: the counter (`pos`) or a channel.
  final String channel;

  /// Where it was rung up or arranged. Null only on a sale too old to carry the
  /// block, which is a gap and not a value.
  final SaleOriginModel? origin;

  final String customer;

  /// How to reach them: the number a conversation is happening on, the contact
  /// written on the ticket.
  final String contact;

  /// The conversation behind it, when there is one. A ticket rung up from a
  /// WhatsApp order carries it too.
  final String chat;

  /// Who sold it, by name. Empty on a purchase the assistant is holding: nobody
  /// rang it up.
  final String seller;

  /// What was written on the ticket. Not the handover's note, which belongs to
  /// the delivery and is one field down.
  final String note;

  final String currency;

  final int units;

  /// What the lines come to before tax. **Null on a cart nothing in which can
  /// be priced** — a zero there would claim the sale is worth nothing.
  final double? subtotal;

  /// What was charged on it. Null on a conversation: nothing has applied a rate
  /// to it, and `0` would say this sale is tax-free.
  final double? tax;

  /// How much was taxed at each percentage, which is what a fiscal ticket
  /// prints. Empty on a sale with no tax on it at all.
  final List<SaleTaxModel> taxes;

  final double? total;

  final SalePaymentModel payment;

  /// How the customer gets it and how far that got. **Null when there is no
  /// handover to be at a point of**: an unpaid cart has not been charged and a
  /// conversation has no document.
  final SaleHandoverModel? handover;

  /// How many units the ledger is holding for this sale right now. It equals
  /// [units] on an ordinary open invoice and is zero once it is charged — those
  /// units are sold, not held.
  final int held;

  /// The customer's standing holds, one per reservation. **Null and not empty
  /// on a ticket**: a ticket holds its units on its own lines, so there is no
  /// list here rather than an empty one.
  final List<SaleHoldModel>? reservations;

  final List<SaleItemModel> items;

  /// When the first product went on it, and when it was charged. They are the
  /// same instant on a one-shot checkout and twenty minutes apart on an invoice
  /// somebody kept open.
  final DateTime? opened;
  final DateTime? closed;

  final DateTime? date;
  final DateTime? updated;

  /// Whether anything arrived at all. A response that does not even name the
  /// sale is a failed read and not a detail full of gaps.
  bool get isEmpty => id.isEmpty;

  /// Whether it is a conversation rather than a sale with a document behind it.
  bool get isDeal => source == SaleSource.chat;

  /// Whether it is a cart a till still has open.
  bool get isOpen => source == SaleSource.invoice;

  factory SaleDetailModel.fromJson(Map<String, dynamic> data) {
    final origin = data["origin"];
    final handover = data["fulfillment"];
    final holds = data["reservations"];

    // The customer is an object here and a single value on the list's rows: the
    // panel has room for both halves, and the name is not always the one that
    // identifies them.
    final customer = data["customer"];

    // `{ kind: "user", name }` — never a uid, which is not something the
    // backend hands out.
    final seller = data["seller"];

    return SaleDetailModel(
      id: (data["id"] ?? "").toString(),
      source: SaleSource.from(data["source"]),
      ticket: (data["ticket"] ?? "").toString(),
      status: (data["status"] ?? "").toString(),
      stage: (data["stage"] ?? "").toString(),
      label: (data["label"] ?? "").toString(),
      section: SaleSection.from(data["section"]),
      level: SaleLevel.from(data["level"]),
      attention: data["attention"] == true,
      since: saleDate(data["since"]),
      channel: (data["channel"] ?? "").toString(),
      origin: origin is Map ? SaleOriginModel.fromJson(saleFields(origin)) : null,
      customer: customer is Map ? (customer["name"] ?? "").toString() : "",
      contact: customer is Map ? (customer["contact"] ?? "").toString() : "",
      chat: (data["chat"] ?? "").toString(),
      seller: seller is Map ? (seller["name"] ?? "").toString() : "",
      note: (data["note"] ?? "").toString(),
      currency: (data["currency"] ?? "").toString().toUpperCase(),
      units: saleCount(data["units"]),
      subtotal: saleAmount(data["subtotal"]),
      tax: saleAmount(data["tax"]),
      taxes: [
        for (final row in catalogRows(data["taxes"])) SaleTaxModel.fromJson(row)
      ],
      total: saleAmount(data["total"]),
      payment: SalePaymentModel.fromJson(
        data["payment"] is Map ? saleFields(data["payment"] as Map) : const {}
      ),
      handover: handover is Map
        ? SaleHandoverModel.fromJson(saleFields(handover))
        : null,
      held: saleCount(data["held"]),
      // Null is a ticket's answer and `[]` is a conversation holding nothing.
      // The two are drawn differently, so the difference is kept.
      reservations: holds is List
        ? [for (final row in catalogRows(holds)) SaleHoldModel.fromJson(row)]
        : null,
      items: [
        for (final row in catalogRows(data["items"])) SaleItemModel.fromJson(row)
      ],
      opened: saleDate(data["opened"]),
      closed: saleDate(data["closed"]),
      date: saleDate(data["date"]),
      updated: saleDate(data["updated"])
    );
  }
}

/// How the sale is being settled.
class SalePaymentModel {
  const SalePaymentModel({
    this.method = "",
    this.name = "",
    this.reference = "",
    this.credit = false,
    this.collected,
    this.outstanding,
    this.proofs = const []
  });

  /// The settlement kind on a ticket, and the account the customer was handed
  /// on a conversation — the kind is only decided when the ticket is charged.
  final String method;

  /// What that is called, resolved on the backend. Shown as received.
  final String name;

  /// What the payment was identified by: a transfer's number, a reference the
  /// cashier wrote down.
  final String reference;

  /// Whether the sale was sold on credit, which is the only case anything can
  /// be owed on it: every other method is money that was there when the ticket
  /// was written.
  final bool credit;

  /// How much has come in, and what is still owed. **Null on anything but a
  /// credit ticket**, under the rule above.
  final double? collected;
  final double? outstanding;

  /// **El comprobante**: everything the customer sent to show the money went
  /// out, oldest first. Empty on a sale that has none — a ticket rung up at the
  /// counter has no conversation behind it and can never have one.
  ///
  /// It is a list because a customer who pays in two transfers sends two. The
  /// backend also hands over the newest on its own (`payment.proof`), which is
  /// [proof] here: the same entry, not a second read.
  final List<SaleProofModel> proofs;

  /// Whether there is a debt standing on this sale.
  bool get isOwed => (outstanding ?? 0) > 0;

  /// The newest comprobante — the one somebody about to approve the sale is
  /// actually looking at — or null when nothing was ever sent.
  SaleProofModel? get proof => proofs.isEmpty ? null : proofs.last;

  factory SalePaymentModel.fromJson(Map<String, dynamic> data) {
    // `proofs` is the whole list and `proof` is its last entry, so the list is
    // what is read: taking both would draw the newest one twice. A response
    // that carries only the newest —an older backend, a shape that changes— is
    // still a comprobante, so it is taken as a list of one.
    final all = catalogRows(data["proofs"]);
    final newest = data["proof"];

    return SalePaymentModel(
      method: (data["method"] ?? "").toString(),
      name: (data["name"] ?? "").toString(),
      reference: (data["reference"] ?? "").toString(),
      credit: data["credit"] == true,
      collected: saleAmount(data["collected"]),
      outstanding: saleAmount(data["outstanding"]),
      proofs: [
        for (final row in all.isEmpty && newest is Map
          ? [saleFields(newest)]
          : all) SaleProofModel.fromJson(row)
      ]
    );
  }
}

/// **One comprobante**: a single thing the customer sent to show they paid.
///
/// It is evidence and never a state (`model:/chat/proofs.js`). What the money
/// is doing lives on the payment marker beside it, which every write rebuilds
/// whole — so a comprobante kept inside it would be one that disappears at the
/// very moment somebody approves the sale it was sent for.
///
/// **Read as what was said and shown, never as a fact this platform checked.**
/// Nothing in the pipeline can see a bank: half of [text] is a model describing
/// a photo, and [reference] is digits the customer typed. The sale is approved
/// by a person, and this is what they look at first.
class SaleProofModel {
  const SaleProofModel({
    this.kind = "",
    this.file,
    this.text = "",
    this.reference = "",
    this.at
  });

  /// What arrived: `image` (a picture) or `text` (the customer's own words).
  ///
  /// It is the backend's word for it and not what decides how this is drawn —
  /// [isImage] and [isFile] do, off the file itself: an `image` entry whose
  /// bytes could not be stored still arrived, and it is the text that is left
  /// to show.
  final String kind;

  /// The stored picture. **Null on a `text` proof, and on an image the pipeline
  /// received and could not store** — the entry is kept either way, because
  /// something was sent and saying so is more use than a sale that looks as if
  /// nothing ever arrived.
  final FileModel? file;

  /// What came with it: the customer's message, and on an image the line the
  /// pipeline wrote describing it.
  final String text;

  /// The number in it, when the customer **typed** one. It is never read off a
  /// picture: a reference a model retyped is one whose digits survived and
  /// whose grouping did not.
  final String reference;

  /// When it arrived.
  final DateTime? at;

  /// Whether there is a picture to look at.
  bool get isImage => file != null && file!.mime.startsWith("image/");

  /// Whether what was sent is a file that is not a picture — a PDF the customer
  /// exported from their banking app. It is offered rather than drawn.
  bool get isFile => file != null && !isImage;

  /// Whether the entry says a picture came and there is none to show. It is not
  /// an empty proof: the description and the reference are still what a person
  /// reads, and the caveat is worth drawing.
  bool get isLostImage => file == null && kind == _image;

  /// Whether there is nothing in it at all, which is a row not worth drawing.
  bool get isEmpty =>
    file == null && text.isEmpty && reference.isEmpty;

  factory SaleProofModel.fromJson(Map<String, dynamic> data) => SaleProofModel(
    kind: (data["kind"] ?? "").toString(),
    // The file travels as the id-and-variants view every other image in this
    // platform uses; the address is built from the `cdn.media` base `/init`
    // handed over once.
    file: FileModel.from(data["file"]),
    text: (data["text"] ?? "").toString(),
    reference: (data["reference"] ?? "").toString(),
    at: saleDate(data["at"])
  );

  /// The one kind code this app has to decide anything by — see [isLostImage].
  static const String _image = "image";
}

/// How the customer gets the sale, and how far that got.
///
/// It is the one fact in the whole pipeline nobody measured: no collection can
/// see a van leaving or a customer walking in for their box, so [stored] says
/// whether somebody actually wrote this down or it is the reading of a sale
/// nobody filled a form in for.
class SaleHandoverModel {
  const SaleHandoverModel({
    this.mode = "",
    this.modeName = "",
    this.state = "",
    this.stateName = "",
    this.at,
    this.by = "",
    this.note = "",
    this.stored = false
  });

  /// `immediate` · `pickup` · `delivery`, and what each is called.
  final String mode;
  final String modeName;

  /// `pending` · `dispatched` · `done`, and what each is called.
  final String state;
  final String stateName;

  /// When it was recorded and by whom, **by name**: a uid is not something the
  /// backend hands out.
  final DateTime? at;
  final String by;

  /// The line somebody reads a week later: a tracking number, who collected it.
  final String note;

  /// Whether anybody said this. A counter sale is handed over by definition and
  /// one that came in through a channel is not, so an unstored reading is a
  /// default and not a record — which is exactly what somebody chasing a box
  /// needs to be told apart.
  final bool stored;

  /// Whether the customer has it.
  bool get isDelivered => state == SaleModel.delivered;

  factory SaleHandoverModel.fromJson(Map<String, dynamic> data) =>
    SaleHandoverModel(
      mode: (data["mode"] ?? "").toString(),
      modeName: (data["modeName"] ?? "").toString(),
      state: (data["state"] ?? "").toString(),
      stateName: (data["stateName"] ?? "").toString(),
      at: saleDate(data["at"]),
      by: (data["by"] ?? "").toString(),
      note: (data["note"] ?? "").toString(),
      stored: data["stored"] == true
    );
}

/// Where the sale was made: the till it was rung up on, or the bot that
/// arranged it. Never the device row id — an internal id does not travel.
class SaleOriginModel {
  const SaleOriginModel({
    this.kind = "",
    this.channel = "",
    this.terminal = "",
    this.bot = "",
    this.address = ""
  });

  /// `terminal` when a counter rang it up, `channel` when it came in over one.
  final String kind;

  final String channel;

  /// The till's own name.
  final String terminal;

  /// The bot that answered, by name, and the address it answered on.
  final String bot;
  final String address;

  /// Whether anything here is worth drawing. A sale too old to carry the block
  /// answers with its channel alone, which the panel already says one row up.
  bool get isEmpty => terminal.isEmpty && bot.isEmpty && address.isEmpty;

  factory SaleOriginModel.fromJson(Map<String, dynamic> data) {
    final bot = data["bot"];

    return SaleOriginModel(
      kind: (data["kind"] ?? "").toString(),
      channel: (data["channel"] ?? "").toString(),
      terminal: (data["terminal"] ?? "").toString(),
      bot: bot is Map ? (bot["name"] ?? "").toString() : "",
      address: bot is Map ? (bot["address"] ?? "").toString() : ""
    );
  }
}

/// One line of the sale.
///
/// A ticket's line and a conversation's cart entry are the same class because
/// they are the same thing at two moments, and the halves only one of them has
/// are null on the other: a cart entry has no tax, and an invoice line has no
/// expiring hold behind it.
class SaleItemModel {
  const SaleItemModel({
    this.productId = "",
    this.sku = "",
    this.name = "",
    this.qty = 0,
    this.price,
    this.list,
    this.discount,
    this.subtotal,
    this.taxRate,
    this.tax,
    this.total,
    this.held = 0,
    this.state = "",
    this.available,
    this.gone = false
  });

  /// The catalog row behind it. Empty on a charge that is not a product — a
  /// delivery fee, a concept typed at the till — which is exactly what tells
  /// the two apart.
  final String productId;

  final String sku;

  /// What it is called: the record's own name, falling back to what the
  /// conversation called it. A product whose record was deleted still has to
  /// say what the customer was offered.
  final String name;

  final int qty;

  /// What it is being sold at. **Null when the cart entry cannot be priced**,
  /// which is the whole reason a conversation can have no total.
  final double? price;

  /// The list price beside the net one, so a discounted line reads as the offer
  /// it is. Only a cart carries them; a ticket's line is already the net price.
  final double? list;
  final double? discount;

  final double? subtotal;

  /// The percentage applied to it and what that came to. Null on a cart entry:
  /// nothing has rung it up.
  final double? taxRate;
  final double? tax;

  final double? total;

  /// How many units the ledger is holding for this line right now.
  final int held;

  /// What the conversation says about it (`reserved`). Read together with
  /// [held]: a line that says reserved and holds nothing is a hold that expired
  /// or was released, which is a thing to see before promising the last one to
  /// somebody else.
  final String state;

  /// What was left on the shelf when the cart was told.
  final int? available;

  /// Whether the product can no longer be sold.
  final bool gone;

  /// Whether the line was quoted a price at all.
  bool get isPriced => price != null;

  /// Whether the cart says these units are set aside and the ledger disagrees.
  /// It is a promise the shelf is not keeping.
  bool get isUnheld => state == "reserved" && held <= 0;

  factory SaleItemModel.fromJson(Map<String, dynamic> data) => SaleItemModel(
    productId: (data["productId"] ?? "").toString(),
    sku: (data["sku"] ?? "").toString(),
    name: (data["name"] ?? "").toString(),
    qty: saleCount(data["qty"]),
    price: saleAmount(data["price"]),
    list: saleAmount(data["list"]),
    discount: saleAmount(data["discount"]),
    subtotal: saleAmount(data["subtotal"]),
    taxRate: saleAmount(data["taxRate"]),
    tax: saleAmount(data["tax"]),
    total: saleAmount(data["total"]),
    held: saleCount(data["held"]),
    state: (data["state"] ?? "").toString(),
    available: data["available"] == null ? null : saleCount(data["available"]),
    gone: data["gone"] == true
  );
}

/// How much was taxed at one percentage. It is the breakdown a fiscal ticket
/// prints, and it is the backend's arithmetic and never this app's.
class SaleTaxModel {
  const SaleTaxModel({this.rate = 0, this.base = 0, this.amount = 0});

  /// The percentage, written as `16` and never as `0.16`.
  final double rate;

  /// What was taxed at it, and what that came to.
  final double base;
  final double amount;

  factory SaleTaxModel.fromJson(Map<String, dynamic> data) => SaleTaxModel(
    rate: saleAmount(data["rate"]) ?? 0,
    base: saleAmount(data["base"]) ?? 0,
    amount: saleAmount(data["amount"]) ?? 0
  );
}

/// Units the shelf is keeping for this customer, from the ledger's own holds.
///
/// The cart says what they were quoted; this says what is actually set aside,
/// and the two disagreeing is one of the things the panel exists to show.
class SaleHoldModel {
  const SaleHoldModel({
    this.id = "",
    this.tableId = "",
    this.productId = "",
    this.sku = "",
    this.qty = 0,
    this.status = "",
    this.expiresAt,
    this.createdAt
  });

  final String id;
  final String tableId;
  final String productId;
  final String sku;
  final int qty;

  /// `pending` while it stands. Only the standing ones are read.
  final String status;

  /// When the hold lapses on its own, which is what makes it urgent.
  final DateTime? expiresAt;
  final DateTime? createdAt;

  factory SaleHoldModel.fromJson(Map<String, dynamic> data) => SaleHoldModel(
    id: (data["id"] ?? "").toString(),
    tableId: (data["tableId"] ?? "").toString(),
    productId: (data["productId"] ?? "").toString(),
    sku: (data["sku"] ?? "").toString(),
    qty: saleCount(data["qty"]),
    status: (data["status"] ?? "").toString(),
    expiresAt: saleDate(data["expiresAt"]),
    createdAt: saleDate(data["createdAt"])
  );
}

/// A nested object with its keys read as strings. `jsonDecode` hands back
/// `Map<String, dynamic>` already, but a `Map` read out of another map is
/// `dynamic` to the analyzer, and every model here takes the typed one.
Map<String, dynamic> saleFields(Map data) =>
  data.map((key, value) => MapEntry(key.toString(), value));
