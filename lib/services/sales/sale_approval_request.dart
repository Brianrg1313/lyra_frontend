/// Body of the sales board's second write: **approving a sale whose payment
/// nobody had checked** (`PUT /v1/chats/stage/`).
///
/// It lives apart from the screen for the same reason `fulfilSaleRequest` does:
/// it is the contract with the backend, and a contract is easier to check when
/// it is one readable file.
///
/// **The bot never closes a sale.** It holds stock and it hands over an
/// account; whether the money arrived is a fact that lives in a bank statement,
/// and nothing in this platform can see one. So a sale standing at "Pago por
/// verificar" is waiting on a person, and this is that person saying it: the
/// mark also settles the payment marker and takes the conversation off the
/// worklist, which is what makes it an approval and not only a label.
///
/// **Approving is not closing** (backend, 13/10/2026): `paid` leaves the sale
/// «Por cerrar» —the handover is still ahead, and the customer may cancel— and
/// `sold` is a separate, later word, said from the conversation.
///
/// ```json
/// { "ID": "665f...", "STAGE": "paid", "AMOUNT": 30000, "CURRENCY": "VES" }
/// ```
///
/// The owning business does not go in the body: it travels in the
/// `business_id` header of every request (see `useBusiness` in
/// `toolkit/backend/api.dart`).
library;

/// The stage a person sets to say the money arrived.
///
/// It is spelled here rather than read off a catalog because it is the
/// *action* this screen offers and not a value it draws.
const String kSaleApprovedStage = "paid";

/// Builds the body that approves [id], which is **the conversation behind the
/// sale and never the row's own id** — the endpoint reads it as a chat
/// (`Chat.one`) and a sale that is standing at "Pago por verificar" is very
/// often an invoice the register opened for that conversation, whose id names a
/// document no chat collection has ever heard of. `SaleModel.conversation` is
/// the value to pass; passing the row's id is `404 chat_not_found`.
///
/// [amount] is the one figure a person states: **only part of the money
/// arrived**. Short of the total, what came stays on the same ticket and the
/// customer is asked for the rest; without it, approving is "all of it came".
/// [currency] defaults to the ticket's (bolívares convert at the comprobante's
/// rate), so it only travels with an amount.
Map<String, dynamic> approveSaleRequest({
  required String id,
  double? amount,
  String? currency
}) => {
  "ID": id,
  "STAGE": kSaleApprovedStage,
  "AMOUNT": ?amount,
  if (amount != null && currency != null && currency.isNotEmpty) "CURRENCY": currency
};
