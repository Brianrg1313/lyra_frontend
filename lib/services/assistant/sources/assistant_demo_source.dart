import 'dart:convert';

// SERVICES
import 'package:app/generated/l10n.dart';
import './assistant_source.dart';

/// **Placeholder** answers while the assistant has no backend: canned replies
/// picked by keyword, streamed word by word like a model would, each with an
/// A2UI surface built from the Lyra catalog
/// (`screens/home/sections/dashboard/assistant/catalog/lyra_catalog.dart`).
///
/// Every figure is an example. Replaced by the cloud's source once the
/// assistant's endpoint exists; the service does not change.
class AssistantDemoSource implements AssistantSource {
  AssistantDemoSource({this.pace = const Duration(milliseconds: 22)});

  /// Pause between words. Zero in tests.
  final Duration pace;

  /// The catalog the surfaces are drawn from (`LyraCatalog.id`).
  static const String catalogId = "lyra.catalog.v1";

  int _surfaces = 0;

  @override
  Stream<String> reply(AssistantRequest request) async* {
    final s = S.current;

    if (request.action case final action?) {
      switch (action) {
        case "ask":
          // A suggestion button: answered as if it had been typed.
          yield* reply(AssistantRequest(prompt: request.context["prompt"] as String? ?? request.prompt));
        default:
          yield* _words(s.assistant_demo_done(request.prompt));
      }
      return;
    }

    final prompt = request.prompt.toLowerCase();

    if (_has(prompt, const ["sale", "sold", "revenue", "venta", "vend"])) {
      yield* _words(s.assistant_demo_sales_intro);
      yield _surface(_sales(s));
      yield* _words(s.assistant_demo_sales_outro);
    } else if (_has(prompt, const ["stock", "low", "inventor", "run", "agot"])) {
      yield* _words(s.assistant_demo_stock_intro);
      yield _surface(_stock(s));
      yield* _words(s.assistant_demo_stock_outro);
    } else if (_has(prompt, const ["team", "employee", "working", "who", "emplead", "equipo"])) {
      yield* _words(s.assistant_demo_team_intro);
      yield _surface(_team(s));
    } else if (_has(prompt, const ["what can", "help", "puedes", "ayuda"])) {
      yield* _words(s.assistant_demo_help_intro);
      yield _surface(_suggestions(s));
    } else {
      yield* _words(s.assistant_demo_generic);
      yield _surface(_suggestions(s));
    }
  }

  bool _has(String prompt, List<String> words) => words.any(prompt.contains);

  Stream<String> _words(String text) async* {
    final parts = RegExp(r"\S+\s*|\s+").allMatches(text);

    for (final part in parts) {
      if (pace > Duration.zero) await Future<void>.delayed(pace);
      yield part.group(0)!;
    }

    yield "\n\n";
  }

  /// One A2UI surface as the model writes it: a fenced JSON list with its
  /// `createSurface` and its `updateComponents`.
  String _surface(List<Map<String, Object?>> components) {
    final id = "demo_${_surfaces++}";
    final messages = [
      {"version": "v0.9", "createSurface": {"surfaceId": id, "catalogId": catalogId}},
      {"version": "v0.9", "updateComponents": {"surfaceId": id, "components": components}}
    ];

    return "\n```json\n${jsonEncode(messages)}\n```\n";
  }

  Map<String, Object?> _button(String id, String label, String event, {bool primary = false, Map<String, Object?> context = const {}}) => {
    "id": id,
    "component": "Button",
    "label": label,
    "variant": primary ? "primary" : "secondary",
    "action": {"event": {"name": event, "context": {"label": label, ...context}}}
  };

  List<Map<String, Object?>> _sales(S s) => [
    {"id": "root", "component": "Card", "child": "body"},
    {"id": "body", "component": "Column", "children": ["title", "metrics", "actions"]},
    {"id": "title", "component": "Text", "text": s.dashboard_sales_today, "variant": "title"},
    {"id": "metrics", "component": "Row", "children": ["revenue", "orders", "ticket"]},
    {"id": "revenue", "component": "Metric", "label": s.assistant_demo_revenue, "value": 1284.5, "format": "currency", "delta": 12.4},
    {"id": "orders", "component": "Metric", "label": s.assistant_demo_orders, "value": 37, "format": "number", "delta": 5},
    {"id": "ticket", "component": "Metric", "label": s.assistant_demo_ticket, "value": 34.7, "format": "currency", "delta": -2.1},
    {"id": "actions", "component": "Row", "children": ["open", "compare"]},
    _button("open", s.assistant_demo_open_sales, "navigate", primary: true, context: {"path": "/home/sales"}),
    _button("compare", s.assistant_demo_compare, "compare_week")
  ];

  List<Map<String, Object?>> _stock(S s) => [
    {"id": "root", "component": "Card", "child": "body"},
    {"id": "body", "component": "Column", "children": ["title", "p1", "p2", "p3", "actions"]},
    {"id": "title", "component": "Text", "text": s.dashboard_low_stock_title, "variant": "title"},
    {"id": "p1", "component": "Progress", "label": s.dashboard_sample_product_1, "caption": s.dashboard_units_left(4), "value": 0.08},
    {"id": "p2", "component": "Progress", "label": s.dashboard_sample_product_2, "caption": s.dashboard_units_left(9), "value": 0.18},
    {"id": "p3", "component": "Progress", "label": s.dashboard_sample_product_3, "caption": s.dashboard_units_left(15), "value": 0.3},
    {"id": "actions", "component": "Row", "children": ["order", "open"]},
    _button("order", s.assistant_demo_order, "draft_purchase", primary: true),
    _button("open", s.assistant_demo_open_inventory, "navigate", context: {"path": "/home/inventory"})
  ];

  List<Map<String, Object?>> _team(S s) => [
    {"id": "root", "component": "Card", "child": "body"},
    {"id": "body", "component": "Column", "children": ["title", "a", "b", "c", "open"]},
    {"id": "title", "component": "Text", "text": s.dashboard_online_employees, "variant": "title"},
    {"id": "a", "component": "Item", "title": s.dashboard_sample_person_1, "subtitle": "08:02", "icon": "employee", "tone": "good"},
    {"id": "b", "component": "Item", "title": s.dashboard_sample_person_2, "subtitle": "08:45", "icon": "employee", "tone": "good"},
    {"id": "c", "component": "Item", "title": s.dashboard_sample_person_3, "subtitle": "09:10", "icon": "employee", "tone": "good"},
    _button("open", s.assistant_demo_open_team, "navigate", context: {"path": "/home/employees"})
  ];

  List<Map<String, Object?>> _suggestions(S s) => [
    {"id": "root", "component": "Column", "children": ["sales", "stock", "team"]},
    _button("sales", s.assistant_suggestion_sales_prompt, "ask", context: {"prompt": s.assistant_suggestion_sales_prompt}),
    _button("stock", s.assistant_suggestion_stock_prompt, "ask", context: {"prompt": s.assistant_suggestion_stock_prompt}),
    _button("team", s.assistant_suggestion_team_prompt, "ask", context: {"prompt": s.assistant_suggestion_team_prompt})
  ];
}
