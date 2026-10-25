/// Bodies of the money writes: recording a payment
/// (`POST /v1/money/payments/`) and voiding one
/// (`POST /v1/money/payments/void/`).
///
/// They live apart from the screens because they are the contract with the
/// backend, just like those of the connections and the product tables.
///
/// The owning business does not go in the body: it travels in the
/// `business_id` header of every request (see `useBusiness` in
/// `toolkit/backend/api.dart`).
///
/// **There is no `DIRECTION`.** Which way the money went is decided by the
/// concept —`supplier` is money out, `settlement` is money in— so a request
/// that could name both would be able to contradict itself. And there is no
/// currency either: the amount is stamped from the company's pricing, the same
/// rule the ticket follows.
///
/// Shape of the record body:
///
/// ```json
/// {
///   "CONCEPT": "supplier",
///   "AMOUNT": 250.5,
///   "METHOD": "transfer",
///   "ACCOUNT_ID": "9f1c...",
///   "REFERENCE": "004512",
///   "COUNTERPART": { "NAME": "Distribuidora Lara", "CONTACT": "+58412..." },
///   "NOTE": "Pedido de marzo",
///   "DATE": "2026-09-01T12:00:00.000Z"
/// }
/// ```
library;

/// Builds the body that records a payment.
///
/// Everything but the concept and the amount is optional, and the empty values
/// are stripped rather than sent blank: a reference that was not typed is a
/// payment that carries none, and writing `""` into it would make the history
/// say the bank printed an empty number.
///
/// [ticket] only travels on the concepts that allow one (`settlement`,
/// `customer_refund`); the form does not offer it on the rest, and the backend
/// refuses it there.
///
/// [date] is when the **money moved**, sent only when that is not now — a
/// supplier paid on Friday and typed in on Monday. It travels in ISO, in UTC,
/// which is what the backend reads and what every date in this app is written
/// as on the wire.
Map<String, dynamic> recordPaymentRequest({
  required String concept,
  required double amount,
  String method = "",
  String accountId = "",
  String reference = "",
  String counterpartName = "",
  String counterpartContact = "",
  String note = "",
  String ticket = "",
  DateTime? date
}) {
  final counterpart = <String, dynamic>{
    if (counterpartName.trim().isNotEmpty) "NAME": counterpartName.trim(),
    if (counterpartContact.trim().isNotEmpty) "CONTACT": counterpartContact.trim()
  };

  return {
    "CONCEPT": concept,
    "AMOUNT": amount,
    if (method.isNotEmpty) "METHOD": method,
    if (accountId.isNotEmpty) "ACCOUNT_ID": accountId,
    if (reference.trim().isNotEmpty) "REFERENCE": reference.trim(),
    if (counterpart.isNotEmpty) "COUNTERPART": counterpart,
    if (note.trim().isNotEmpty) "NOTE": note.trim(),
    if (ticket.trim().isNotEmpty) "TICKET": ticket.trim(),
    if (date != null) "DATE": date.toUtc().toIso8601String()
  };
}

/// Builds the body that annuls a payment.
///
/// [reason] is the sentence somebody reads a month later —a wrong amount, a
/// transfer that bounced, a payment recorded twice— and it is optional because
/// a void without one is still better than an edit: the row stops counting and
/// stays.
Map<String, dynamic> voidPaymentRequest({
  required String id,
  String reason = ""
}) => {
  "ID": id,
  if (reason.trim().isNotEmpty) "REASON": reason.trim()
};
