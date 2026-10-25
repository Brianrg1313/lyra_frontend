/// Body of the one write the sales pipeline makes
/// (`PUT /v1/sales/fulfillment/`).
///
/// It lives apart from the screen for the same reason the money and the
/// connection bodies do: it is the contract with the backend, and a contract is
/// easier to check when it is one readable file.
///
/// **Everything else on this screen is measured, and this is the exception.**
/// The ledger knows the units left the shelf, the ticket knows the money
/// arrived, the conversation knows what was agreed — and not one of them knows
/// whether the driver went out, or whether the customer came in and picked
/// their box up. Somebody has to say it, so this is where they say it.
///
/// The write sets a **fact** and never a stage: the stage that follows from it
/// is computed on the other side and handed back. A client that could write
/// "esperando el retiro" directly could put a delivery in the queue for a
/// customer who is not coming.
///
/// ```json
/// { "ID": "665f...", "MODE": "delivery", "STATE": "dispatched", "NOTE": "TRK-99120" }
/// ```
///
/// The owning business does not go in the body: it travels in the
/// `business_id` header of every request (see `useBusiness` in
/// `toolkit/backend/api.dart`).
library;

/// Builds the body that records how a sale reaches its customer.
///
/// [mode] is **how** they get it and [state] is **where that got to**, and at
/// least one of the two has to travel — the backend refuses a body that names
/// neither rather than guessing at one. Naming only the mode moves the sale to
/// that mode's opening state, which is why a counter handover needs no state at
/// all: saying it was handed over at the till *is* saying it is finished.
///
/// Neither is defaulted here for the same reason it is not defaulted there: a
/// handover filed as a delivery because nothing was picked is a driver sent to
/// a customer who was coming to collect.
///
/// [note] is what a person wants written beside it — a tracking number, who
/// collected it. It is stripped when blank instead of travelling empty, which
/// would overwrite whatever note the sale already carries.
Map<String, dynamic> fulfilSaleRequest({
  required String id,
  String mode = "",
  String state = "",
  String note = ""
}) => {
  "ID": id,
  if (mode.isNotEmpty) "MODE": mode,
  if (state.isNotEmpty) "STATE": state,
  if (note.trim().isNotEmpty) "NOTE": note.trim()
};
