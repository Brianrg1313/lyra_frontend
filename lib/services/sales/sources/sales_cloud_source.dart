// SERVICES
import 'package:app/services/sales/sale_approval_request.dart';
import 'package:app/services/sales/sale_channel_model.dart';
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/services/sales/sale_stage_model.dart';
import 'package:app/services/sales/sources/sales_source.dart';
import 'package:app/toolkit/backend/api.dart';

/// [SalesSource] over the backend's REST api.
class SalesCloudSource implements SalesSource {
  const SalesCloudSource();

  @override
  Future<SalesPage> page({
    required SaleSection section,
    String stage = "",
    String channel = "",
    bool mine = false,
    required int page,
    required int size
  }) async => SalesPage.fromResponse(await api.get(
    path: "/sales/",
    version: "v1",
    query: {
      "SECTION": section.value,
      if (stage.isNotEmpty) "STAGE": stage,
      if (channel.isNotEmpty) "CHANNEL": channel,
      if (mine) "MINE": 1,
      "PAGE": page,
      "SIZE": size
    }
  ));

  @override
  Future<SaleModel?> fulfil(Map<String, dynamic> request) async {
    final data = await api.put(path: "/sales/fulfillment/", version: "v1", data: request);

    return data is Map
      ? SaleModel.fromJson(data.map((key, value) => MapEntry(key.toString(), value)))
      : null;
  }

  /// A mark on the conversation (`PUT /chats/stage`, `STAGE: paid`).
  @override
  Future<void> approve(String chat, {double? amount, String? currency}) => api.put(
    path: "/chats/stage/",
    version: "v1",
    data: approveSaleRequest(id: chat, amount: amount, currency: currency)
  );

  /// No trailing slash: the reference is a path segment (`params: ["ID"]`),
  /// and an extra one would leave it empty on the other side.
  @override
  Future<SaleDetailModel> detail(String reference) async {
    final data = await api.get(path: "/sales/detail/$reference", version: "v1");

    return data is Map
      ? SaleDetailModel.fromJson(saleFields(data))
      : const SaleDetailModel();
  }

  @override
  Future<SaleStagesCatalog> stages() async =>
    SaleStagesCatalog.fromResponse(await api.get(path: "/sales/stages/", version: "v1"));

  /// The channels half of `GET /pos/methods`, ignoring everything else it
  /// answers: the payment methods are the counter's business, not this list's.
  @override
  Future<List<SaleChannel>> channels() async {
    final data = await api.get(path: "/pos/methods/", version: "v1");
    if (data is! Map) return const [];

    return [
      for (final row in data["channels"] ?? const [])
        if (row is Map)
          SaleChannel.fromJson(
            row.map((key, value) => MapEntry(key.toString(), value))
          )
    ];
  }
}
