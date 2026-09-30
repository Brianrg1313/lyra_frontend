import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lyra_protocol/lyra_protocol.dart';

/// `lyra_protocol` is the code of `docs/offline/protocol-v1.md`: the app and the engine both
/// build on the package, and people read the doc. An op or a code in one and not the other is
/// a contract nobody agreed to.
void main() {
  final doc = File("docs/offline/protocol-v1.md").readAsStringSync();

  String section(String heading) {
    final start = doc.indexOf(heading);
    expect(start, isNonNegative, reason: "$heading is missing from protocol-v1.md");

    final end = doc.indexOf("\n## ", start + heading.length);

    return doc.substring(start, end < 0 ? doc.length : end);
  }

  Set<String> ticked(String text) =>
    {for (final match in RegExp(r"`([a-zA-Z_.]+)`").allMatches(text)) match.group(1)!};

  test('the op catalogue is the one in protocol-v1.md §9', () {
    final rows = section("## 9. Op catalogue").split("\n").where((line) => line.startsWith("| ") && line.contains("`"));
    final documented = {for (final row in rows) ...ticked(row.split("|")[2])};

    expect(Ops.all.map((op) => op.name).toSet(), documented);
  });

  test('every common error code of protocol-v1.md §8 is in ErrorCodes', () {
    final rows = section("## 8. Error codes").split("\n").where((line) => line.startsWith("| `"));
    final documented = {for (final row in rows) ...ticked(row.split("|")[1])};

    expect(ErrorCodes.all, containsAll(documented));
  });
}
