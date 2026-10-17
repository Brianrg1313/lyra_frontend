import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/permissions/permissions_service.dart';

// WIDGETS
import 'package:app/screens/modals/supply_chain/recipe/recipe_editor.dart';
import 'package:app/screens/modals/supply_chain/shared/kitchen_product_picker.dart';

/// Asks what a made product being created consumes, and answers it (or `null` when closed):
/// the sheet sends it with the row's columns in the same call (`cocina-frontend.md` §3, all or
/// nothing), so a made row is never saved without it. [product] is the row's name, or empty.
Future<RecipeDraft?> showMadeConsumes(BuildContext context, {required String product}) async {
  final s = S.of(context);
  RecipeDraft? answer;

  await showSideModal(
    context: context,
    title: product.isEmpty ? s.made_consumes_open : s.made_consumes_title(product),
    builder: (context) => ConstrainedBox(
      constraints: const BoxConstraints(minWidth: 620, maxWidth: 620),
      child: ScrollableWidget(
        padding: EdgeInsets.only(bottom: AppSize.padding),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KitchenNote(text: s.made_consumes_note),
          RecipeEditor(
            recipe: null,
            supplies: false,
            canEdit: PermissionsService().can("supply_chain.recipes.edit"),
            saveLabel: s.made_consumes_save,
            onSave: (draft) async {
              answer = draft;
              Navigator.pop(context);
              return true;
            },
            onCancel: () => Navigator.pop(context)
          )
        ]
      )
    )
  );

  return answer;
}
