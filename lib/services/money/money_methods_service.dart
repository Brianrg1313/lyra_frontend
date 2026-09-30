import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

// SERVICES
import 'package:app/services/money/money_method_model.dart';
import 'package:app/toolkit/api.dart';
import 'package:app/services/money/sources/money_source.dart';
import 'package:app/toolkit/deployment.dart';

enum MoneyMethodsStatus { idle, loading, ready, empty, error }

/// The ways this company charges (`GET /money/methods`) and the rails it may
/// turn on (`GET /business/payments`).
///
/// They are **two different questions and one screen**: the second is what is
/// available in the country the company operates in, and the first is what it
/// actually did with that, account number included. The form picks from one to
/// write into the other, which is why both live here instead of in two
/// services that would always be read together.
///
/// Several rows may be the same rail —a shop with two bank accounts has two
/// transfers— so what tells them apart on screen is the label the company gave
/// them, and what a payment names is the row's id.
///
/// A removal is a soft delete on the other side: payments were recorded against
/// the account, and a history that cannot say where money came in is one nobody
/// can reconcile against a bank statement. It simply stops being offered.
///
/// It is ephemeral: owned by the finance section and discarded when leaving it.
/// The shell remounts the section when the company changes, and the rails
/// depend on the company's country, so there is nothing to invalidate on its
/// own account.
class MoneyMethodsService extends ChangeNotifier {
  MoneyMethodsService({MoneySource? source}) : _injected = source;

  final MoneySource? _injected;

  MoneySource get _source => _injected ?? Sources.money;

  MoneyMethodsStatus _status = MoneyMethodsStatus.idle;

  List<MoneyMethod> _methods = const [];
  List<MoneyRail> _rails = const [];

  /// What each rail asks to be filled in, by rail code. Both reads answer it —
  /// the list for the rails it contains, the catalog for every rail the company
  /// may turn on — and both write into the same map: it is the same sheet, and
  /// a card and the form that edits it must not label a field differently.
  final Map<String, List<MoneyMethodField>> _fields = {};

  /// The lists the closed fields are filled from (`banks`, `documents`,
  /// `networks`), already narrowed to this company's country by the backend.
  /// Empty until [loadRails] answers: only the form needs them.
  Map<String, List<MoneyPaymentOption>> _options = const {};

  /// Country the rails were answered for, as the backend resolved it. Empty
  /// when the company never said where it operates, and then what came back are
  /// the global rails — which is exactly what it can still charge with.
  String _country = "";

  /// `true` while a write is in flight, so the form can hold its button down
  /// and two removals of the same row cannot overlap.
  bool _writing = false;

  MoneyMethodsStatus get status => _status;

  /// The company's accounts, in the order it arranged them.
  List<MoneyMethod> get methods => _methods;

  /// What it may turn on. Empty until [loadRails] answers.
  List<MoneyRail> get rails => _rails;

  /// The option catalogs, by name. See [_options].
  Map<String, List<MoneyPaymentOption>> get options => _options;

  /// What a rail asks to be filled in. Empty for a rail nothing has been read
  /// about yet —and for the ones that ask for nothing, such as cash—, and the
  /// two are the same answer here: there is nothing to draw.
  List<MoneyMethodField> fields(String code) => _fields[code] ?? const [];

  String get country => _country;
  bool get isWriting => _writing;

  /// The rail [code] names, or null when the catalog does not have it. It is
  /// what lets an account row say which rail it is even before the catalog
  /// arrives — it carries its own name too.
  MoneyRail? rail(String code) {
    for (final entry in _rails) {
      if (entry.code == code) return entry;
    }

    return null;
  }

  /// Reads the accounts. Without [force] it does not ask again once it is read:
  /// the section can be mounted more than once.
  Future<void> load({bool force = false}) async {
    if (_status == MoneyMethodsStatus.loading) return;
    if (!force && _status != MoneyMethodsStatus.idle) return;

    _status = MoneyMethodsStatus.loading;
    notifyListeners();

    final ({List<MoneyMethod> methods, MoneyRailFields fields}) data;

    try {
      data = await _source.methods();
    } catch (error) {
      if (kDebugMode) print("loadMoneyMethods failed: $error");

      _status = MoneyMethodsStatus.error;
      notifyListeners();

      return;
    }

    _methods = data.methods.where((method) => method.isValid).toList(growable: false);

    _fields.addAll(data.fields);

    // An empty list is not a failure here, unlike the concepts catalog: a
    // company that has not told anybody how to pay it is the normal state on
    // the first day, and the tab offers to add the first account.
    _status = _methods.isEmpty
      ? MoneyMethodsStatus.empty
      : MoneyMethodsStatus.ready;

    notifyListeners();
  }

  Future<void> retry() => load(force: true);

  /// Reads the rails the company may turn on.
  ///
  /// It is asked for by the form and not by the tab: the list of accounts draws
  /// itself from what it already has —each row carries its rail's name— and the
  /// catalog is only needed the moment somebody adds one.
  ///
  /// A failure is silent on purpose: it leaves the picker without options,
  /// which the form reports where it is being looked at, instead of taking the
  /// whole tab down for something the list does not need.
  Future<void> loadRails({bool force = false}) async {
    if (!force && _rails.isNotEmpty) return;

    final ({
      String country,
      List<MoneyRail> rails,
      MoneyRailFields fields,
      Map<String, List<MoneyPaymentOption>>? options
    }) data;

    try {
      data = await _source.rails();
    } catch (error) {
      if (kDebugMode) print("loadPaymentRails failed: $error");

      return;
    }

    _country = data.country;
    _rails = data.rails;

    // Merged and not replaced. The two reads see different sets —the list only
    // knows the rails the company turned on, the catalog only the ones it may—
    // and a rail that has since been withdrawn is in the first and not in the
    // second, so dropping what was already read would leave the card of an
    // account nobody can add again without labels.
    _fields.addAll(data.fields);

    // A catalogue that did not arrive leaves the ones already read.
    if (data.options != null) _options = data.options!;

    notifyListeners();
  }

  /// Turns a way of charging on. Returns `false` if it did not go in; the
  /// reason was already shown in the floating flag.
  ///
  /// The list is reread and not appended to: the backend answers an id and
  /// nothing else, and the row it created carries the rail's name, its
  /// settlement kind and the position it ended up in — three things this app
  /// would have to guess at.
  Future<bool> create(
    BuildContext context, {
    required Map<String, dynamic> request
  }) => _write(context, () => _source.createMethod(request));

  /// Edits one of them. Only the keys the body carries are written, so a form
  /// that draws three fields cannot blank the two it does not show.
  Future<bool> update(
    BuildContext context, {
    required Map<String, dynamic> request
  }) => _write(context, () => _source.updateMethod(request));

  /// Turns one off.
  Future<bool> remove(BuildContext context, String id) => _write(
    context,
    () => _source.removeMethod(id)
  );

  /// The three writes, which differ only in the call: they all hold the same
  /// lock, report the same way and finish by rereading the list, because what
  /// the row ended up as is the backend's answer and not this app's.
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
      if (kDebugMode) print("moneyMethodWrite failed: $error");

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
