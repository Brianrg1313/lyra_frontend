/// Bodies of the write operations for a table: creation
/// (`POST /v1/inventory/products/builder/structure/`), editing (`PUT /v1/inventory/products/builder/structure/`),
/// deletion (`DELETE /v1/inventory/products/builder/structure/`) and the partial edit from the
/// settings screen (`PUT /v1/inventory/products/builder/details/`).
///
/// They live apart from the screen because they are the contract with the backend: what is
/// built here is what is documented on the other side, and thus it can be tested without
/// mounting the form.
///
/// The owning company does not go in the body: it travels in the `business_id` header of
/// all requests (see `useBusiness` in `toolkit/api.dart`).
///
/// The table is created with its header (title, description and color) and, if a
/// template category was chosen, with that category. The columns are never built by the
/// front: when [template] travels it is the backend who creates them on the other side,
/// in the same creation and without a second request.
///
/// Creation shape:
///
/// ```json
/// {
///   "TITLE": "Vinos",
///   "DESCRIPTION": "Catalogo de la bodega",
///   "COLOR": "0xFF60A5FA",
///   "TEMPLATE": "FOOD"
/// }
/// ```
///
/// Editing shape:
///
/// ```json
/// { "ID": "a1b2c3", "NAME": "Vinos", "DESCRIPTION": "Catalogo de la bodega" }
/// ```
///
/// Deletion shape:
///
/// ```json
/// { "ID": "a1b2c3" }
/// ```
///
/// Partial edit shape:
///
/// ```json
/// { "ID": "a1b2c3", "DESCRIPTION": "Catalogo de la bodega" }
/// ```
library;

// SERVICES
import 'package:app/services/stock/tables/table_lite_model.dart';

/// Builds the creation body.
///
/// Trims the texts and omits the description when it ends up empty, instead of
/// sending it blank: the rest of the optional api fields behave the same and
/// thus the backend distinguishes "no description" from "description deleted".
///
/// The [color] is the string that visually identifies the table (a Flutter
/// ARGB literal like `0xFF60A5FA`); it always travels, because the form
/// starts with one chosen.
///
/// The [template] is the code of the chosen category (for example `"FOOD"`); it is
/// omitted when none was chosen, so the backend creates the table without
/// columns just as before.
///
/// [kind] is what the table holds (`KIND`, `cocina-frontend.md` §2): `made` or `supplies`. It
/// can't change afterwards, so it only travels when it is not a catalog: that is the backend's
/// default, and a master knows no other kind.
Map<String, dynamic> createTableRequest({
  required String title,
  required String description,
  required String color,
  String? template,
  TableKind kind = TableKind.catalog
}) {
  final trimmed = description.trim();

  return {
    "TITLE": title.trim(),
    if (trimmed.isNotEmpty) "DESCRIPTION": trimmed,
    "COLOR": color,
    if (template != null && template.isNotEmpty) "TEMPLATE": template,
    if (kind != TableKind.catalog) "KIND": kind.name
  };
}

/// Builds the body of a table edit.
///
/// The title travels in `NAME` and not in `TITLE` as in creation: it is the key that
/// the edit asks for on the other side. It is required even when it is not being
/// changed, so whoever edits only the description sends the one the table already
/// had.
///
/// The description **always travels**, even empty, and there lies the difference
/// with creation: in a table that already exists, emptying it deletes the one it had. Not
/// sending it would leave it as it was and a description set by mistake would have
/// no way back.
Map<String, dynamic> editTableRequest({
  required String id,
  required String title,
  required String description
}) => {
  "ID": id,
  "NAME": title.trim(),
  "DESCRIPTION": description.trim()
};

/// Builds the body of a table deletion.
///
/// It is only the id: the table already knows which company it belongs to, and the backend gives
/// a logical deletion (`status = 0`) to it and its columns. It has its function just like
/// the other two, so the three write operations are read —and tested— in the
/// same place.
Map<String, dynamic> deleteTableRequest({required String id}) => {"ID": id};

/// Builds the body of a table **partial** edit
/// (`PUT /v1/inventory/products/builder/details/`).
///
/// It is the write for the settings screen and not the spreadsheet one: only what was
/// touched travels, so changing the description does not rewrite the name
/// —nor the other way around—. That is why both texts are optional and `null` means "not
/// changed", which on the other side means "leave it as it was".
///
/// The blank description **does travel**, and there lies the difference with `null`:
/// it is the only place where empty is a value and not the absence of one, and it is
/// what deletes a description set by mistake. `null` leaves it intact.
///
/// It is the same `NAME` key as [editTableRequest] because it is the same datum in
/// the same backend; what changes is that here it is not required.
///
/// [kind] switches an inventory table between products and supplies (whether it sells,
/// `cocina-frontend.md` §2): the backend carries its stock over or refuses the whole body.
Map<String, dynamic> editTableDetailsRequest({
  required String id,
  String? name,
  String? description,
  String? kind
}) => {
  "ID": id,
  if (name != null) "NAME": name.trim(),
  if (description != null) "DESCRIPTION": description.trim(),
  "KIND": ?kind
};
