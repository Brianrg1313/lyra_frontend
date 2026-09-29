/// Bodies of the writes for the company's exchange currencies: adding or
/// editing one (`PUT /v1/money/currencies/`) and taking one off
/// (`DELETE /v1/money/currencies/`). Full contract: `currencies_contract.md`.
///
/// **One write for adding and editing.** A currency is at most once per
/// company (`company_currencies` is unique by `bid` + `currency`), so the code
/// is the key and the write is an upsert: re-adding one that was taken off
/// brings the same row back instead of a second one.
///
/// **The main currency has no write here.** Changing it does not convert a
/// single stored price, it relabels every one of them, which is why it is not
/// a settings field anywhere in the app.
///
/// Shape of the body:
///
/// ```json
/// { "CURRENCY": "VES", "MODE": "custom", "RATE": 40.5 }
/// ```
library;

import 'package:app/services/money/money_currency_model.dart';

/// Builds the add/edit body.
///
/// [rate] travels only with a custom mode, and is required there: an official
/// rate is the feed's and a client that could send one could write any figure
/// as "official". Switching back to official leaves the stored custom figure
/// alone on the other side, so it is there if the company switches again.
Map<String, dynamic> saveMoneyExchangeRequest({
  required String currency,
  required MoneyRateMode mode,
  double? rate
}) => {
  "CURRENCY": currency.trim().toUpperCase(),
  "MODE": mode.value,
  if (mode == MoneyRateMode.custom) "RATE": ?rate
};

/// Builds the body that takes a currency off. Soft on the other side
/// (`status = 0`): payments already recorded in it keep saying what they were.
Map<String, dynamic> removeMoneyExchangeRequest(String currency) => {
  "CURRENCY": currency.trim().toUpperCase()
};
