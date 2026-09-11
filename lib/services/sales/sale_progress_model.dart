// SERVICES
import 'package:app/services/sales/sale_model.dart';

/// The `sale/progress` notice: a sale moved, and every screen of the company is
/// being told as it happens.
///
/// **This is what makes the sales screen a live one.** The two lists are not
/// two queries somebody refreshes, they are one board whose rows cross between
/// them: a ticket is charged and leaves `open`, a driver goes out and a row
/// moves from `shipping` to `transit`, a customer settles their tab and a row
/// finally lands in `done`. A list that only re-sorts itself on reload is a list
/// two people work the same delivery from.
///
/// The value travels, unlike the badge counters: a stage is the same fact for
/// everybody who can read the sale at all, so there is nothing per-member to
/// leak. And it is fire and forget on the other side — the stage is measured on
/// read, so a dropped notice costs a redraw and never a fact.
///
/// **It is shaped like the row it updates**, column for column: a notice is
/// merged into a row the board is already drawing, so a key the list does not
/// use updates nothing and a key it uses for something else corrupts it. It
/// carries what the sale is worth too — a row drawn from a bare stage is a sale
/// with no customer, no units and no total.
///
/// **Every field is always present, `null` included.** A notice with no
/// [section] is the row *leaving both lists* —an invoice somebody cancelled, a
/// checkout that failed and put its units back— and a client that had to tell
/// "no stage" from "the field is absent" is one that leaves a cancelled ticket
/// on the screen forever. That is why [section] is nullable here and why
/// [isGone] is the reading of a null one.
class SaleProgressModel {
  /// Name of the event on the socket. A contract handwritten on both sides, so
  /// it lives in one constant: a misspelled event does not fail, it just never
  /// arrives.
  static const String event = "sale/progress";

  const SaleProgressModel({
    this.id = "",
    this.source = SaleSource.ticket,
    this.ticket = "",
    this.chat = "",
    this.stage = "",
    this.label = "",
    this.section,
    this.level = SaleLevel.info,
    this.attention = false,
    this.since
  });

  /// The sale that moved — the conversation's id when the row is a deal, the
  /// same value the list identifies its rows by.
  final String id;

  final SaleSource source;

  final String ticket;
  final String chat;

  /// Where it stands now. Empty when it stands nowhere any more, which is the
  /// same case as a null [section].
  final String stage;

  /// What that stage is called, as the backend wrote it — so a row can be
  /// relabelled from a notice without a reread.
  ///
  /// It travels under the **same key the list uses** (`label`), and that is not
  /// cosmetic. The notice used to call it `name`, which a row of `GET /sales`
  /// does not have at all, so merging one into the other moved `stage` and left
  /// the word a person actually reads saying what the sale used to be. Worse
  /// next door: in a row of `GET /chats`, `name` is the *customer's* own name.
  final String label;

  /// Which list it belongs to now, or **null when it belongs to neither**.
  final SaleSection? section;

  final SaleLevel level;
  final bool attention;

  /// When it reached this stage, which the backend stamps as it announces it.
  final DateTime? since;

  /// Whether the notice names a sale at all. It is the only way one is
  /// discarded.
  bool get isEmpty => id.isEmpty;

  /// Whether the sale left both lists: it was cancelled, or its checkout
  /// failed. The row is dropped rather than relabelled — there is no stage to
  /// relabel it to.
  bool get isGone => section == null;

  factory SaleProgressModel.fromEvent(dynamic data) {
    if (data is! Map) return const SaleProgressModel(id: "");

    return SaleProgressModel(
      id: (data["id"] ?? "").toString(),
      source: SaleSource.from(data["source"]),
      ticket: (data["ticket"] ?? "").toString(),
      chat: (data["chat"] ?? "").toString(),
      stage: (data["stage"] ?? "").toString(),
      label: (data["label"] ?? "").toString(),
      section: SaleSection.from(data["section"]),
      level: SaleLevel.from(data["level"]),
      attention: data["attention"] == true,
      since: saleDate(data["since"])
    );
  }
}
