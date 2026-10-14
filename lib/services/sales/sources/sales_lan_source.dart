// PACKAGES
import 'package:lyra_protocol/lyra_protocol.dart';

// SERVICES
import 'package:app/services/lan/lan_service.dart';
import 'package:app/services/pos/sources/pos_lan_source.dart';
import 'package:app/services/sales/sale_channel_model.dart';
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sale_stage_model.dart';
import 'package:app/services/sales/sources/sales_source.dart';
import 'package:app/toolkit/deployment.dart';

/// [SalesSource] over the master (`docs/offline/specs/sales.md`).
///
/// The master answers the cloud's row and detail shapes with its money in minor units of each
/// sale's `currency` (README, money), which this source turns into the amounts the models hold, as
/// `PosLanSource` does for the ticket. `sale/progress` carries no money, so it needs nothing here.
class SalesLanSource implements SalesSource {
  const SalesLanSource(this._lan);

  final LanService _lan;

  @override
  Future<SalesPage> page({
    required SaleSection section,
    String stage = "",
    String channel = "",
    bool mine = false,
    required int page,
    required int size
  }) async {
    final answer = await _lan.call(Ops.salesList, args: {
      "section": section.value,
      if (stage.isNotEmpty) "stage": stage,
      if (channel.isNotEmpty) "channel": channel,
      if (mine) "mine": true,
      "page": page,
      "size": size
    });
    final rows = answer is Map ? answer["sales"] : null;
    if (rows is! List) throw const UnreadableAnswer("sales.list");

    return SalesPage.fromResponse({
      ...answer as Map,
      "sales": [for (final row in rows) if (row is Map) _row(row)]
    });
  }

  /// The service's body is the cloud's (`ID`, `MODE`, `STATE`, `NOTE`).
  @override
  Future<SaleModel?> fulfil(Map<String, dynamic> request) async {
    final answer = await _lan.call(Ops.salesFulfil, args: {
      "id": request["ID"],
      if (request["MODE"] != null) "mode": request["MODE"],
      if (request["STATE"] != null) "state": request["STATE"],
      if (request["NOTE"] != null) "note": request["NOTE"]
    });

    return answer is Map ? SaleModel.fromJson(saleFields(_row(answer))) : null;
  }

  /// Approving a payment is about conversations, which are cloud only (SA-25).
  @override
  Future<void> approve(String chat, {double? amount, String? currency}) => throw UnsupportedError("sales.approve is cloud only");

  @override
  Future<SaleDetailModel> detail(String reference) async {
    final answer = await _lan.call(Ops.salesDetail, args: {"reference": reference});
    if (answer is! Map) return const SaleDetailModel();

    final digits = PosLanSource.decimalsOf(answer["currency"]);
    final payment = answer["payment"];

    return SaleDetailModel.fromJson(saleFields({
      ...answer,
      ..._amounts(answer, const ["subtotal", "tax", "total"], digits),
      "taxes": [
        for (final entry in answer["taxes"] as List? ?? const [])
          if (entry is Map) {...entry, ..._amounts(entry, const ["base", "amount"], digits)}
      ],
      "items": [
        for (final line in answer["items"] as List? ?? const [])
          if (line is Map) {...line, ..._amounts(line, const ["price", "list", "subtotal", "tax", "total"], digits)}
      ],
      if (payment is Map) "payment": {...payment, ..._amounts(payment, const ["collected", "outstanding"], digits)}
    }));
  }

  @override
  Future<SaleStagesCatalog> stages() async => SaleStagesCatalog.fromResponse(await _catalog());

  @override
  Future<List<SaleChannel>> channels() async => [
    for (final row in (await _catalog())["channels"] as List? ?? const [])
      if (row is Map) SaleChannel.fromJson(saleFields(row))
  ];

  Future<Map> _catalog() async {
    final answer = await _lan.call(Ops.salesCatalog);
    if (answer is! Map) throw const UnreadableAnswer("sales.catalog");

    return answer;
  }

  /// A row with its money as the model reads it.
  static Map _row(Map row) =>
    {...row, ..._amounts(row, const ["total", "collected", "outstanding"], PosLanSource.decimalsOf(row["currency"]))};

  /// [keys] of [data] from minor units to amounts; null stays null.
  static Map<String, double?> _amounts(Map data, List<String> keys, int digits) =>
    {for (final key in keys) if (data.containsKey(key)) key: PosLanSource.major(data[key], digits)};
}
