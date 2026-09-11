import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/button.dart';
import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/sales/sale_approval_request.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/screens/modals/sales/sale_detail/detail_identity.dart';

/// **Approving a sale whose payment nobody had checked**, which is the second
/// write this screen makes.
///
/// Four things are pinned, and every one of them is a claim about money:
///
/// - **Which sale is offered the button.** Only one standing at "Pago por
///   verificar": that is the point of the pipeline where the customer says the
///   money is sent and nobody has looked, and it is the only place a person is
///   in a position to say it arrived. Offered a stage earlier it would be a
///   payment approved before anybody claimed to have made one.
/// - **What it is addressed by.** The conversation behind the sale and never
///   the row's own id: a sale standing there is usually the ticket the register
///   opened for that conversation, and its id is a document no chat collection
///   has heard of — which the backend answers 404 to, leaving the money
///   unverified and the person told the sale does not exist.
/// - **What travels.** The endpoint takes a stage a person may set and nothing
///   about the money — a client that restated how much arrived would be a
///   second opinion on a figure nobody here counted.
/// - **That the card draws what it is handed.** The action is built by the
///   panel, which reads on its first frame and therefore is not mounted here
///   (**no test may hit the network**); what the card owes is a slot, and a
///   sale with nothing to move has no button rather than a disabled one.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));
  });

  test('only a sale waiting to be verified can be approved', () {
    expect(_sale(stage: "verifying").canApprove, isTrue);

    // Everything a step earlier is the customer's move, not ours: they were
    // handed an account, or the assistant is still holding units for them.
    expect(_sale(stage: "paying").canApprove, isFalse);
    expect(_sale(stage: "reserving").canApprove, isFalse);
    // And a charged ticket's own stages are never this one.
    expect(
      _sale(stage: "shipping", source: SaleSource.ticket).canApprove,
      isFalse
    );
  });

  test('a sale is approved against its conversation and never its row', () {
    // Every sale gets a ticket now, so the row standing at "Pago por verificar"
    // is usually the register's document drawn at the stage of the conversation
    // it was opened for. Its id is not a chat, and the endpoint reads a chat.
    final invoice = _sale(
      stage: "verifying",
      source: SaleSource.invoice,
      id: "inv7"
    );

    expect(invoice.canApprove, isTrue);
    expect(invoice.conversation, "c9");
    expect(invoice.conversation, isNot(invoice.id));
  });

  test('a sale with no conversation is not offered the button', () {
    // A deal whose chat session expired keeps its state and is still a sale,
    // but its id fell back to the customer's contact — and a contact cannot be
    // marked either. There is nothing to address the write with, so there is no
    // button rather than one that answers 404.
    expect(_sale(stage: "verifying", chat: "").canApprove, isFalse);
  });

  test('the approval says the sale closed and nothing about the money', () {
    expect(approveSaleRequest(id: "c9"), {"ID": "c9", "STAGE": "sold"});
  });

  testWidgets('the card carries the action it is handed, and none otherwise',
    (tester) async {
      await _pump(tester, _sale(stage: "verifying"), withAction: true);

      expect(find.text(S.current.sales_approve_action), findsOneWidget);

      await _pump(tester, _sale(stage: "paying"), withAction: false);

      // No slot is kept for it: a panel of buttons that do nothing promises
      // actions this sale does not have.
      expect(find.byType(Button), findsNothing);
      expect(tester.takeException(), isNull);
    }
  );
}

SaleModel _sale({
  required String stage,
  SaleSource source = SaleSource.chat,
  String id = "c9",
  String chat = "c9"
}) => SaleModel(
  id: id,
  source: source,
  chat: chat,
  stage: stage,
  label: "Pago por verificar",
  level: SaleLevel.warning,
  attention: true,
  customer: "Marta",
  // What tells a charged ticket with a handover left from one the customer
  // already has; a conversation carries neither.
  state: source == SaleSource.ticket ? "pending" : ""
);

Future<void> _pump(
  WidgetTester tester,
  SaleModel sale, {
  required bool withAction
}) async {
  await tester.pumpWidget(MaterialApp(
    localizationsDelegates: const [
      S.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalMaterialLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate
    ],
    supportedLocales: S.delegate.supportedLocales,
    home: Builder(builder: (context) {
      AppSize.instance(context);

      return Scaffold(body: SizedBox(
        width: 460,
        child: SaleDetailIdentity(
          sale: sale,
          action: withAction
            ? Button(
                title: S.of(context).sales_approve_action,
                action: () {}
              )
            : null
        )
      ));
    })
  ));

  await tester.pump();
}
