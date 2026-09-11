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
/// ```json
/// { "ID": "665f...", "STAGE": "sold" }
/// ```
///
/// The owning business does not go in the body: it travels in the
/// `business_id` header of every request (see `useBusiness` in
/// `toolkit/api.dart`).
library;

/// The stage a person sets to say the sale happened.
///
/// It is one of the two the backend lets a client write (`Stages.manual`), and
/// the only one of those that is a sale — the other ends a conversation that
/// was never one. It is spelled here rather than read off a catalog because it
/// is the *action* this screen offers and not a value it draws.
const String kSaleClosedStage = "sold";

/// Builds the body that approves [id], which is **the conversation behind the
/// sale and never the row's own id** — the endpoint reads it as a chat
/// (`Chat.one`) and a sale that is standing at "Pago por verificar" is very
/// often an invoice the register opened for that conversation, whose id names a
/// document no chat collection has ever heard of. `SaleModel.conversation` is
/// the value to pass; passing the row's id is `404 chat_not_found`.
///
/// Nothing else travels. The endpoint takes a stage and not a payment: how much
/// arrived and through which account are the conversation's own facts, and a
/// client that could restate them here would be a second opinion about money
/// nobody here counted.
Map<String, dynamic> approveSaleRequest({required String id}) => {
  "ID": id,
  "STAGE": kSaleClosedStage
};
