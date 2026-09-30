import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// SERVICES
import 'package:app/services/money/money_currency_model.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/services/money/sources/money_source.dart';
import 'package:app/toolkit/deployment.dart';

enum MoneyCurrenciesStatus { idle, loading, ready, error }

/// The company's currencies (`/money/currencies`): the main one its catalog is
/// priced in, and the exchange currencies it also takes, each with its rate.
/// Contract: `currencies_contract.md`.
///
/// There is no `empty` status, unlike the accounts: a company always has a
/// main currency, so an answer with no exchanges is still a block with
/// something to show.
///
/// It is ephemeral, like every money service: owned by the finance section and
/// dropped when leaving it. A business switch remounts the section.
class MoneyCurrenciesService extends ChangeNotifier {
  MoneyCurrenciesService({MoneySource? source}) : _injected = source;

  final MoneySource? _injected;

  MoneySource get _source => _injected ?? Sources.money;

  MoneyCurrenciesStatus _status = MoneyCurrenciesStatus.idle;

  MoneyCurrencies _currencies = const MoneyCurrencies(main: "");

  /// `true` while a write is in flight, so two edits of the same row cannot
  /// overlap.
  bool _writing = false;

  MoneyCurrenciesStatus get status => _status;
  MoneyCurrencies get currencies => _currencies;
  bool get isWriting => _writing;

  /// Reads the setup. Without [force] it does not ask again once it is read.
  Future<void> load({bool force = false}) async {
    if (_status == MoneyCurrenciesStatus.loading) return;
    if (!force && _status != MoneyCurrenciesStatus.idle) return;

    _status = MoneyCurrenciesStatus.loading;
    notifyListeners();

    try {
      _currencies = await _source.currencies();
      _status = MoneyCurrenciesStatus.ready;
    } catch (error) {
      if (kDebugMode) print("loadMoneyCurrencies failed: $error");

      _status = MoneyCurrenciesStatus.error;
    }

    notifyListeners();
  }

  Future<void> retry() => load(force: true);

  /// Adds an exchange currency or changes its rate. Returns `false` if it did
  /// not go in; the reason was already shown in the floating flag.
  ///
  /// The setup is reread and not patched: the effective rate is the backend's
  /// answer (a custom figure, or the feed's today), and this app does not
  /// have the feed.
  Future<bool> save(
    BuildContext context, {
    required Map<String, dynamic> request
  }) => _write(context, () => _source.saveCurrency(request));

  /// Takes an exchange currency off.
  Future<bool> remove(BuildContext context, String currency) => _write(
    context,
    () => _source.removeCurrency(currency)
  );

  Future<bool> _write(
    BuildContext context,
    Future<dynamic> Function() call
  ) async {
    if (_writing) return false;

    _writing = true;
    notifyListeners();

    try {
      await call();
    } catch (error) {
      if (kDebugMode) print("moneyCurrencyWrite failed: $error");

      _writing = false;
      notifyListeners();

      if (context.mounted) {
        FloatFlag.of(context).fromError(
          error is Map && error.isNotEmpty
            ? error
            : {"message": error.toString()}
        );
      }

      return false;
    }

    _writing = false;

    await load(force: true);

    return true;
  }
}
