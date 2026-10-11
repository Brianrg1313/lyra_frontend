/// Bodies of the writes for one of the company's ways of charging: creation
/// (`POST /v1/money/methods/`), editing (`PUT /v1/money/methods/`) and turning
/// one off (`DELETE /v1/money/methods/`).
///
/// The owning business does not go in the body: it travels in the
/// `business_id` header of every request.
///
/// **The settlement kind is not in the request.** It comes from the rail
/// (`mobile` for a Pago Movil, `transfer` for a Zelle) and is what every figure
/// on the money screen is grouped by: a client that could name it could file
/// its transfers as cash.
///
/// **Neither is which fields the account has.** That is the rail's own sheet
/// (`MoneyMethodField`, `model:/money/requirements.js`), which is why the
/// account travels here as a map keyed by column and not as six named
/// arguments: a Pago Movil sends a bank, an id and a phone, a Zelle a name and
/// an address, and cash nothing at all. The keys are the column names
/// uppercased, which is what the backend reads.
///
/// Shape of the creation body:
///
/// ```json
/// {
///   "CODE": "pago_movil",
///   "LABEL": "Pago Movil Banesco",
///   "INSTITUTION": "0134",
///   "DOCUMENT": "J-12345678",
///   "ACCOUNT": "0414 1234567",
///   "INSTRUCTIONS": "Pon el numero del pedido en el concepto",
///   "CURRENCY": "VES",
///   "FEE_TYPE": "percent",
///   "FEE": 3
/// }
/// ```
///
/// **Branch** (`BRANCH`): the branch the account is of; left out (or null) it is the whole
/// company's. A branch of another company is `404 branch_not_found`.
///
/// **Currency and commission** (`CURRENCY`, `FEE_TYPE`, `FEE`) are the
/// company's and not the rail's, with one exception: a rail that moves a single
/// currency (`MoneyRail.currency`) is saved in it whatever is sent. Contract:
/// `currencies_contract.md`.
library;

import 'package:app/services/money/money_method_model.dart';

/// Builds the creation body.
///
/// [fields] is the account itself, by column name (`holder`, `document`,
/// `institution`, `account`) — whatever the rail's sheet asked for. The empty
/// ones are stripped instead of being sent blank, so what was never filled in
/// does not read as filled in with nothing; what the rail actually requires is
/// checked on the other side, where the sheet lives.
Map<String, dynamic> createMoneyMethodRequest({
  required String code,
  String label = "",
  String instructions = "",
  Map<String, String> fields = const {},
  String currency = "",
  MoneyFee fee = const MoneyFee(),
  String? branch,
  int? position
}) => {
  "CODE": code,
  "BRANCH": ?branch,
  if (label.trim().isNotEmpty) "LABEL": label.trim(),
  for (final entry in fields.entries)
    if (entry.value.trim().isNotEmpty) entry.key.toUpperCase(): entry.value.trim(),
  if (instructions.trim().isNotEmpty) "INSTRUCTIONS": instructions.trim(),
  if (currency.trim().isNotEmpty) "CURRENCY": currency.trim().toUpperCase(),
  // Only a commission that exists: a new account with none is the default on
  // the other side, and sending `none` would be one more key to agree on.
  if (!fee.isNone) ..._fee(fee),
  "POSITION": ?position
};

/// Builds the edit body.
///
/// **The rail is not in it**: "this Pago Movil is now a Zelle" is not an edit
/// of an account but another account, and the payments already recorded against
/// this row would silently change what they say they came in through.
///
/// The empty values travel here as `null` and are **not** stripped, which is
/// the opposite of the creation: on an edit the backend writes only the keys it
/// receives, so a missing key is "leave it" and `null` is "clear it", and a
/// stripped empty field would be a value the form cannot erase. Only what the
/// form drew travels: the account is read against the rail's sheet on the other
/// side, and a column that sheet does not name ends up empty whoever sent it —
/// the row is what the rail says it is, and a holder left over on a Pago Movil
/// from before the sheet existed is cleaned by the first edit.
///
/// [fee] travels whole when given, `none` included: on an edit that is how a
/// commission is taken off (`FEE_TYPE: "none"`, `FEE: null`).
///
/// [branch] travels only when given: `(id: null)` moves the account to the whole company.
Map<String, dynamic> updateMoneyMethodRequest({
  required String id,
  String? label,
  String? instructions,
  Map<String, String> fields = const {},
  String? currency,
  MoneyFee? fee,
  ({String? id})? branch,
  int? position
}) => {
  "ID": id,
  if (branch != null) "BRANCH": branch.id,
  if (label != null) "LABEL": _orNull(label),
  for (final entry in fields.entries) entry.key.toUpperCase(): _orNull(entry.value),
  if (instructions != null) "INSTRUCTIONS": _orNull(instructions),
  if (currency != null) "CURRENCY": _orNull(currency.toUpperCase()),
  if (fee != null) ..._fee(fee),
  "POSITION": ?position
};

/// A commission as it travels: its type, and its value only when there is one.
Map<String, dynamic> _fee(MoneyFee fee) => {
  "FEE_TYPE": fee.type.value,
  "FEE": fee.isNone ? null : fee.value
};

/// Builds the body that turns an account off. The row is soft-deleted on the
/// other side: payments were recorded against it, and a history that cannot say
/// which account money came into is one nobody can reconcile.
Map<String, dynamic> removeMoneyMethodRequest(String id) => {"ID": id};

/// What a cleared field travels as: `null`, never `""`. An empty string is a
/// value and would leave the row saying the holder is called nothing.
String? _orNull(String value) => value.trim().isEmpty ? null : value.trim();
