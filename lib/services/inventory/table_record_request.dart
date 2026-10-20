/// Bodies of the write operations for a **record** (a row) of a product
/// table: creation (`POST /v1/inventory/products/records/manage/`), editing
/// (`PUT /v1/inventory/products/records/manage/`) and deletion
/// (`DELETE /v1/inventory/products/records/manage/`).
///
/// They live apart from the screen for the same reason as the columns ones (see
/// `table_field_request.dart`): they are the contract with the backend, what is built
/// here is what is documented on the other side, and thus it can be tested without mounting the
/// spreadsheet.
///
/// The owning company does not go in the body: it travels in the `business_id` header of
/// all requests (see `useBusiness` in `toolkit/api.dart`).
///
/// `DATA` is indexed by FIELD_ID and **only carries what was touched**: the
/// spreadsheet edits one cell at a time, so sending the whole row would rewrite
/// fields nobody looked at (and would overwrite what someone else loaded in them in the
/// meantime).
///
/// Creation shape:
///
/// ```json
/// {
///   "TABLE_ID": "a1b2c3",
///   "DATA": {"d4e5f6": "Yerba 1kg", "a7b8c9": "22.50"}
/// }
/// ```
///
/// Editing shape:
///
/// ```json
/// {
///   "TABLE_ID": "a1b2c3",
///   "ID": "r1s2t3",
///   "DATA": {"a7b8c9": "24.90"}
/// }
/// ```
///
/// A record of a `made` table carries what it consumes in the same body (`CONSUMES`, and
/// `BATCH` for «made by the batch», `cocina-frontend.md` §3): all or nothing, the record is not
/// saved without them.
library;

// SERVICES
import 'package:app/services/kitchen/kitchen_request.dart';

/// The id a record creation answers: the cloud's bare id, the engine's `{id}`; empty when
/// neither says it.
String createdRecordId(dynamic answer) {
  if (answer is String) return answer;
  if (answer is Map && answer["id"] is String) return answer["id"] as String;
  return "";
}

/// Builds the creation body of a record; [consumes] (with what the customer picks, [choices])
/// and [batch] only on a made one.
Map<String, dynamic> createRecordRequest({
  required String tableId,
  required Map<String, dynamic> values,
  List<RecipeLineDraft>? consumes,
  List<RecipeChoiceDraft> choices = const [],
  bool? batch
}) => {
  "TABLE_ID": tableId,
  "DATA": values,
  if (consumes != null) "CONSUMES": recipeLinesRequest(consumes, choices),
  "BATCH": ?batch
};

/// Builds the editing body of a record.
///
/// [id] is the record identifier, the one that comes in the first column of
/// the data page and that the spreadsheet does not show. Without it there is no edit
/// possible: it is the only thing that says which row of the table is being written to.
///
/// On a made record [consumes] and [choices] replace the whole list (every line, not only the
/// one that changed) and [batch] only its mode; [values] may then be left out: one of the three goes.
Map<String, dynamic> editRecordRequest({
  required String tableId,
  required String id,
  Map<String, dynamic>? values,
  List<RecipeLineDraft>? consumes,
  List<RecipeChoiceDraft> choices = const [],
  bool? batch
}) => {
  "TABLE_ID": tableId,
  "ID": id,
  "DATA": ?values,
  if (consumes != null) "CONSUMES": recipeLinesRequest(consumes, choices),
  "BATCH": ?batch
};

/// Builds the deletion body of a record: the backend marks it deleted (it is never physically
/// removed) and the table scopes it to the company that owns it.
Map<String, dynamic> deleteRecordRequest({required String tableId, required String id}) => {
  "TABLE_ID": tableId,
  "ID": id
};
