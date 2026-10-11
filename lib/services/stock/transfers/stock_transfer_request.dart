/// Bodies of the transfer writes (`sedes-frontend.md` §6). Every one travels with the
/// `branch_id` header: the branch it is written from is the request's, never the body's.
library;

// SERVICES
import 'package:app/services/stock/transfers/stock_transfer_model.dart';

/// One product and how many units of it, as a draft lists it.
typedef StockTransferItem = ({String productId, int quantity});

/// `POST /inventory/stock/transfers`: a draft to [toBranch] from the header's branch, sent at
/// once with [send]. Lines with no units are not lines.
Map<String, dynamic> createTransferRequest({
  required String toBranch,
  required List<StockTransferItem> items,
  String tableId = "",
  String note = "",
  bool send = false
}) => {
  "TO_BRANCH": toBranch,
  "ITEMS": _items(items),
  if (tableId.isNotEmpty) "TABLE_ID": tableId,
  if (note.trim().isNotEmpty) "NOTE": note.trim(),
  if (send) "SEND": true
};

/// `PUT /inventory/stock/transfers` with `ACTION: edit`: a draft's destination, lines (they
/// replace the old ones) and note. What isn't given is kept.
Map<String, dynamic> editTransferRequest({
  required String id,
  String? toBranch,
  List<StockTransferItem>? items,
  String? note
}) => {
  "ID": id,
  "ACTION": "edit",
  "TO_BRANCH": ?toBranch,
  if (items != null) "ITEMS": _items(items),
  if (note != null) "NOTE": note.trim()
};

/// `PUT /inventory/stock/transfers` with `ACTION: send` or `cancel`. Sending takes every line
/// off the shelf or none (`409` naming the product short); cancelling a sent one puts it back.
Map<String, dynamic> transferActionRequest(String id, {required bool send}) =>
  {"ID": id, "ACTION": send ? "send" : "cancel"};

/// `POST /inventory/stock/transfers/receive`. A line not named arrived whole, so only the lines
/// counted short travel, with what arrived and what the rest is written off as.
Map<String, dynamic> receiveTransferRequest(
  StockTransfer transfer,
  Map<String, ({int received, StockShortage reason})> counted
) => {
  "ID": transfer.id,
  "ITEMS": [
    for (final line in transfer.lines)
      if (counted[line.productId] case final count? when count.received < line.quantity) {
        "PRODUCT_ID": line.productId,
        "RECEIVED": count.received,
        "REASON": count.reason.name
      }
  ]
};

/// `POST /inventory/stock/transfers/search`: [direction] `in` (coming here) or `out` (sent from
/// here), both without; one [status] or every one.
Map<String, dynamic> searchTransfersRequest({
  String? direction,
  StockTransferStatus? status,
  int page = 1,
  int size = 50
}) => {
  "DIRECTION": ?direction,
  "STATUS": ?status?.name,
  "PAGE": page,
  "SIZE": size
};

List<Map<String, dynamic>> _items(List<StockTransferItem> items) => [
  for (final item in items)
    if (item.quantity > 0) {"PRODUCT_ID": item.productId, "QUANTITY": item.quantity}
];
