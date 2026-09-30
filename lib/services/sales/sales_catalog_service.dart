import 'package:flutter/foundation.dart';

// SERVICES
import 'package:app/services/sales/sale_channel_model.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sale_stage_model.dart';
import 'package:app/services/sales/sources/sales_source.dart';
import 'package:app/toolkit/deployment.dart';

enum SalesCatalogStatus { idle, loading, ready, error }

/// The two closed vocabularies the sales screen is built from: **where a sale
/// can stand** and **how it can reach its customer**, plus **where it came in
/// through**.
///
/// None of them is written in this app. The stages and the handover come from
/// `GET /sales/stages` (`model:/sales/progress.js`), which is the one place
/// that decides what a state is called, which of the two lists it belongs to,
/// what colour it draws and whether somebody here has to act — the same shape
/// the payment concepts and the stock reasons already have. Hard-coding that
/// list here is how a screen stops rendering the day a stage is added.
///
/// The channels come from `GET /pos/methods`, which answers them beside the
/// payment methods. It is a second read and it is the right one: the backend
/// deliberately answers the checkout's channel picker and the sales list's
/// channel filter from the same catalog, so a sale over a channel and the
/// channel that produced it can never be two spellings of one thing.
///
/// The endpoint's `sections` are **not** read. The two lists are tabs of this
/// app, each one a route with a title of its own (see `SalesTab`), so their
/// wording belongs to `S` and not to a payload; what the backend decides is
/// which section a *stage* belongs to, and that is [SaleStage.section].
///
/// Both reads are descriptions and depend on nothing the company holds, so they
/// are asked for once when the section opens and never again while somebody
/// works. A failure is reported and not retried on its own: the list still
/// draws —every row carries its own label and colour— and what is lost is the
/// filter, which is what [status] says.
class SalesCatalogService extends ChangeNotifier {
  SalesCatalogService({SalesSource? source}) : _injected = source;

  final SalesSource? _injected;

  SalesSource get _source => _injected ?? Sources.sales;

  SalesCatalogStatus _status = SalesCatalogStatus.idle;

  SaleStagesCatalog _catalog = const SaleStagesCatalog();
  List<SaleChannel> _channels = const [];

  SalesCatalogStatus get status => _status;

  /// Every stage, in the precedence order the backend reads them in.
  List<SaleStage> get stages => _catalog.stages;

  /// The ways a sale can reach a customer, for the handover form's picker.
  List<SaleHandoverMode> get handover => _catalog.handover;

  /// Where a sale can have come in through.
  List<SaleChannel> get channels => _channels;

  /// The stages of one of the two lists, which is what its state filter offers:
  /// a tab must not be able to filter itself down to a stage that belongs to
  /// the other one.
  List<SaleStage> of(SaleSection section) => [
    for (final stage in stages)
      if (stage.section == section) stage
  ];

  /// The stage [code] names, or null when it is not one of them (an older app
  /// reading a stage that did not exist when it shipped).
  SaleStage? stage(String code) {
    if (code.isEmpty) return null;

    for (final stage in stages) {
      if (stage.stage == code) return stage;
    }

    return null;
  }

  /// The channel [code] names, or null.
  SaleChannel? channel(String code) {
    if (code.isEmpty) return null;

    for (final channel in _channels) {
      if (channel.channel == code) return channel;
    }

    return null;
  }

  /// The handover mode [code] names, or null when nobody has said which kind of
  /// handover a sale is — which is a real value and not a missing one.
  SaleHandoverMode? mode(String code) {
    if (code.isEmpty) return null;

    for (final mode in handover) {
      if (mode.mode == code) return mode;
    }

    return null;
  }

  /// What a stage is called. It falls back to the code rather than to a blank:
  /// a filter chip with no text is a control nobody can use, and the code at
  /// least names the thing.
  String stageName(String code) => stage(code)?.name ?? code;

  /// What a channel is called, under the same rule.
  String channelName(String code) => channel(code)?.name ?? code;

  /// Reads both catalogs. Without [force] it does not ask again once they are
  /// in: neither answer depends on the company or changes while the screen is
  /// open.
  Future<void> load({bool force = false}) async {
    if (_status == SalesCatalogStatus.loading) return;
    if (!force && _status == SalesCatalogStatus.ready) return;

    _status = SalesCatalogStatus.loading;
    notifyListeners();

    // Together, because the screen needs both before its filter bar means
    // anything and neither depends on the other.
    final (catalog, channels) = await (
      _read("stages", _source.stages),
      _read("channels", _source.channels)
    ).wait;

    // The stages are what the screen is built from; the channels are one filter
    // of it. So a missing channel list is not a failed catalog — the strip
    // simply has nothing to offer — while missing stages are.
    if (catalog == null || !catalog.isLoaded || catalog.stages.isEmpty) {
      _status = SalesCatalogStatus.error;
      notifyListeners();

      return;
    }

    _catalog = catalog;
    _channels = channels ?? const [];
    _status = SalesCatalogStatus.ready;

    notifyListeners();
  }

  Future<void> retry() => load(force: true);

  /// One of the two reads. It answers `null` instead of throwing so that the
  /// pair can be awaited together and each half judged on its own.
  Future<T?> _read<T>(String label, Future<T> Function() read) async {
    try {
      return await read();
    } catch (error) {
      if (kDebugMode) print("loadSalesCatalog($label) failed: $error");

      return null;
    }
  }
}
