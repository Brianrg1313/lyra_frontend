import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:core/core.dart';
import 'package:app/generated/l10n.dart';
import 'package:app/services/files/cdn_service.dart';
import 'package:app/services/sales/sale_detail_model.dart';
import 'package:app/services/sales/sale_model.dart';
import 'package:app/screens/modals/sales/sale_detail/detail_proof.dart';

/// **El comprobante**, which is the block a sale standing at "Pago por
/// verificar" is opened for.
///
/// What is pinned here is the parse and the three shapes, because both are
/// places a careless reading turns evidence into something else:
///
/// - The list travels **and** its newest entry travels beside it
///   (`payment.proofs` and `payment.proof` are the same rows), so a parse that
///   took both would draw the newest one twice — on the very sale where a
///   second comprobante means the customer paid in two transfers.
/// - What is drawn is decided by the **file**, not by the word: an entry that
///   says `image` and carries none is a picture the pipeline could not store,
///   and the description that came with it is then all a person has. Drawn as
///   an empty picture it would read as a customer who sent nothing.
/// - A sale with no conversation behind it cannot have one at all, and a
///   heading over a question that cannot be asked reads as a gap.
///
/// No test may hit the network: the addresses are built from the `cdn` bases
/// `/init` hands over, so [CdnService] is seeded and the picture's own download
/// is the test binding's 400.
void main() {
  setUpAll(() {
    ThemeColor.dark = SchemeColor.dark(primary: const Color(0xFFFFFFFF));
    ThemeColor.light = SchemeColor.light(primary: const Color(0xFF000000));

    CdnService().seed({
      "media": "https://cdn.test/media",
      "assets": "https://cdn.test/assets"
    });
  });

  tearDownAll(() => CdnService().clear());

  test('the newest comprobante is the last of the list and not a second read',
    () {
      final payment = SaleDetailModel.fromJson(_deal(_two)).payment;

      expect(payment.proofs.length, 2);
      // `proof` is that same entry: the backend hands it over already picked
      // out, and taking it as one more would be a customer who sent two
      // transfers showing three.
      expect(payment.proof?.reference, "004512338");
      expect(payment.proofs.first.isImage, isTrue);
    }
  );

  test('a picture the pipeline could not store is still a comprobante', () {
    final proof = SaleDetailModel.fromJson(_deal(_lost)).payment.proof!;

    expect(proof.file, isNull);
    expect(proof.isImage, isFalse);
    expect(proof.isFile, isFalse);
    // The entry is kept and says why: something arrived, and the line that came
    // with it is what a person reads instead.
    expect(proof.isLostImage, isTrue);
    expect(proof.isEmpty, isFalse);
  });

  test('the block belongs to the sales a comprobante can reach', () {
    // A conversation, and a ticket rung up out of one: both have somewhere for
    // a comprobante to have come from.
    expect(SaleDetailProof.belongsTo(SaleDetailModel.fromJson(_deal(_two))),
      isTrue);
    expect(
      SaleDetailProof.belongsTo(const SaleDetailModel(
        id: "s1",
        source: SaleSource.ticket,
        chat: "c9"
      )),
      isTrue
    );
    // A sale rung up at the counter has no conversation and never will.
    expect(
      SaleDetailProof.belongsTo(const SaleDetailModel(
        id: "s2",
        source: SaleSource.ticket
      )),
      isFalse
    );
  });

  testWidgets('it draws every comprobante, newest first', (tester) async {
    await _pump(tester, SaleDetailModel.fromJson(_deal(_two)));

    // The picture came last, so it is drawn first — with the line the pipeline
    // wrote about it, which is what says the description is not the customer's.
    expect(find.text("[imagen adjunta: captura de transferencia]"),
      findsOneWidget);
    // And the reference they typed, which is what gets pasted into a bank's own
    // search.
    expect(find.text("004512338"), findsOneWidget);
    expect(find.text(S.current.sales_detail_proof_count(2)), findsOneWidget);
  });

  testWidgets('a lost picture says so instead of showing nothing',
    (tester) async {
      await _pump(tester, SaleDetailModel.fromJson(_deal(_lost)));

      expect(find.text(S.current.sales_detail_proof_lost), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  );

  testWidgets('nothing sent is said in words', (tester) async {
    await _pump(tester, SaleDetailModel.fromJson(_deal(const [])));

    // It is the answer somebody verifying a payment needs — they are about to
    // go and look for it in the conversation — and not an empty block.
    expect(find.text(S.current.sales_detail_proof_empty), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

/// The block at the width the panel opens at.
Future<void> _pump(WidgetTester tester, SaleDetailModel sale) async {
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
        child: SingleChildScrollView(child: SaleDetailProof(sale: sale))
      ));
    })
  ));

  await tester.pump();
}

/// A purchase being arranged over a channel, carrying [proofs].
Map<String, dynamic> _deal(List<Map<String, dynamic>> proofs) => {
  "id": "c9",
  "source": "chat",
  "stage": "verifying",
  "label": "Pago por verificar",
  "section": "process",
  "level": "warning",
  "attention": true,
  "channel": "whatsapp",
  "customer": {"name": "Marta", "contact": "584140000000"},
  "chat": "c9",
  "units": 1,
  "payment": {
    "method": "pago_movil",
    "name": "Pago Movil",
    "credit": false,
    "proofs": proofs,
    // Exactly what the backend sends beside the list: its last entry.
    "proof": proofs.isEmpty ? null : proofs.last
  },
  "items": const []
};

/// Two transfers: the reference they typed, and then the screenshot.
const List<Map<String, dynamic>> _two = [
  {
    "kind": "image",
    "file": {
      "id": "f1",
      "scope": "media",
      "mime": "image/jpeg",
      "bytes": 102400,
      "width": 900,
      "height": 1600,
      "variants": []
    },
    "text": "[imagen adjunta: captura de transferencia]",
    "reference": null,
    "at": "2026-09-09T10:00:00.000Z"
  },
  {
    "kind": "text",
    "file": null,
    "text": "Ya te pague, ref 004512338",
    "reference": "004512338",
    "at": "2026-09-09T10:05:00.000Z"
  }
];

/// A picture that arrived and whose bytes could not be stored.
const List<Map<String, dynamic>> _lost = [
  {
    "kind": "image",
    "file": null,
    "text": "[imagen adjunta: no se pudo guardar]",
    "reference": null,
    "at": "2026-09-09T10:00:00.000Z"
  }
];
