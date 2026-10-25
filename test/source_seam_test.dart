import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/pos/pos_service.dart';
import 'package:app/services/pos/sources/pos_source.dart';
import 'package:app/toolkit/backend/deployment.dart';

/// The data-source seam (`docs/plan-offline-lan.md` §7.1): a service reads models from its
/// source and knows nothing of where they came from. It is what lets the LAN source replace
/// the cloud one without touching a screen, and what the per-domain contract tests plug into.
void main() {
  test('a service shows what its source answers', () async {
    final service = PosService(source: _Pos(() async => (mineSales: 7, categories: ["Drinks"])));

    await service.load();

    expect(service.status, PosSummaryStatus.ready);
    expect(service.mineSales, 7);
    expect(service.categories, ["Drinks"]);
  });

  test('a refusal and an unreadable answer are the same failed read', () async {
    for (final failure in <Object>[{"message": "forbidden"}, const UnreadableAnswer("pos")]) {
      final service = PosService(source: _Pos(() async => throw failure));

      await service.load();

      expect(service.status, PosSummaryStatus.error, reason: "$failure");
    }
  });
}

class _Pos implements PosSource {
  _Pos(this._summary);

  final Future<({int mineSales, List<String> categories})> Function() _summary;

  @override
  Future<({int mineSales, List<String> categories})> summary() => _summary();

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
