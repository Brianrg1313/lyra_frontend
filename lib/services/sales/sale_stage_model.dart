// SERVICES
import 'package:app/services/catalog/catalog_table.dart';
import 'package:app/services/sales/sale_model.dart';

/// The vocabulary of the sales screen, as `GET /lyra/v1/sales/stages` hands it
/// over: every state a sale can be in, and the two halves of a handover.
///
/// It is a **read catalog and never a list written here**. Where a sale can
/// stand, what each state is called, which of the two sections it belongs to,
/// what colour it draws and whether somebody here has to act are all declared
/// in one place on the backend (`model:/sales/progress.js`), the same way the
/// payment concepts, the stock reasons and the conversation stages are. A
/// client that builds its own list of states is a client that stops rendering
/// the day a new one exists.

/// One state a sale can be in.
class SaleStage {
  const SaleStage({
    required this.stage,
    this.name = "",
    this.section = SaleSection.process,
    this.level = SaleLevel.info,
    this.attention = false
  });

  /// The code, which is what travels as `STAGE` and what a row is matched by.
  final String stage;

  /// What it is called. Shown as received — see [SaleModel.label].
  final String name;

  /// Which of the two lists a sale at this stage belongs to. It is a property
  /// of the stage and not of the query, which is what keeps a filtered row from
  /// ever landing in the wrong tab.
  final SaleSection section;

  final SaleLevel level;

  /// Whether a sale here is waiting on somebody in the company rather than on
  /// the customer. It is the column a person reads when they ask what is on
  /// their plate, and it is the backend's answer and not a list written in this
  /// app: a stage added there is marked without a new version.
  ///
  /// It is drawn on the **rows** — the weight of the stage tag and of the wait
  /// — and not on the filter, which is a dropdown that says which state is on
  /// and not which ones are urgent.
  final bool attention;

  factory SaleStage.fromJson(Map<String, dynamic> data) => SaleStage(
    stage: (data["stage"] ?? "").toString(),
    name: (data["name"] ?? "").toString(),
    section: SaleSection.from(data["section"]) ?? SaleSection.process,
    level: SaleLevel.from(data["level"]),
    attention: data["attention"] == true
  );
}

/// How a sale reaches its customer, and which states that way of reaching them
/// can be in.
///
/// The two words answer two questions and neither can be folded into the other:
/// the **mode** is who moves next (the shop or the customer), the **state** is
/// how far that got. A single `shipping` says nothing about whether a pickup is
/// outstanding, and a single `pending` says nothing about who is supposed to
/// move.
class SaleHandoverMode {
  const SaleHandoverMode({
    required this.mode,
    this.name = "",
    this.states = const []
  });

  /// `immediate` · `pickup` · `delivery`.
  final String mode;

  final String name;

  /// The states this mode can be in, already narrowed by the backend:
  /// `dispatched` belongs to a delivery and to nothing else (a pickup has no
  /// middle, the customer either came or did not), and a counter handover is
  /// over by definition.
  final List<SaleHandoverState> states;

  factory SaleHandoverMode.fromJson(Map<String, dynamic> data) =>
    SaleHandoverMode(
      mode: (data["mode"] ?? "").toString(),
      name: (data["name"] ?? "").toString(),
      states: [
        for (final row in data["states"] ?? const [])
          if (row is Map)
            SaleHandoverState.fromJson(
              row.map((key, value) => MapEntry(key.toString(), value))
            )
      ]
    );

  /// The state [code] names inside this mode, or null when it is not one of
  /// them.
  SaleHandoverState? find(String code) {
    for (final state in states) {
      if (state.state == code) return state;
    }

    return null;
  }
}

/// How far a handover got: `pending`, `dispatched`, `done`.
class SaleHandoverState {
  const SaleHandoverState({required this.state, this.name = ""});

  final String state;
  final String name;

  factory SaleHandoverState.fromJson(Map<String, dynamic> data) =>
    SaleHandoverState(
      state: (data["state"] ?? "").toString(),
      name: (data["name"] ?? "").toString()
    );
}

/// The whole answer of `GET /lyra/v1/sales/stages`.
///
/// The handover rides along with the stages because both are read once when the
/// screen opens and neither changes while somebody works.
class SaleStagesCatalog {
  const SaleStagesCatalog({
    this.stages = const [],
    this.handover = const [],
    this.isLoaded = false
  });

  /// Every stage, **in precedence order** — the order the backend reads them
  /// in, which is also the order they are worth drawing in: what has to happen
  /// next comes first.
  final List<SaleStage> stages;

  /// The ways a sale can reach a customer, for the picker the handover form
  /// draws.
  final List<SaleHandoverMode> handover;

  final bool isLoaded;

  factory SaleStagesCatalog.fromResponse(dynamic data) {
    if (data is! Map) return const SaleStagesCatalog();

    return SaleStagesCatalog(
      stages: [
        for (final row in catalogRows(data["stages"])) SaleStage.fromJson(row)
      ],
      handover: [
        for (final row in data["handover"] ?? const [])
          if (row is Map)
            SaleHandoverMode.fromJson(
              row.map((key, value) => MapEntry(key.toString(), value))
            )
      ],
      isLoaded: true
    );
  }
}
