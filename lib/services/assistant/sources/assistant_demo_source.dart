import 'dart:convert';

// SERVICES
import 'package:app/generated/l10n.dart';
import '../assistant_line.dart';
import './assistant_source.dart';

/// **Preview** answers with no backend: canned replies picked by keyword,
/// each with an A2UI surface built from the Lyra catalog
/// (`screens/home/sections/dashboard/assistant/catalog/lyra_catalog.dart`),
/// kept in memory like the server keeps its conversation.
///
/// What the tests drive the chat with, and what a debug build run with
/// `--dart-define=LYRA_ASSISTANT_DEMO=true` answers with: the catalog can be
/// worked on without a model run (each one is billed). Every figure is an
/// example. "Draft purchase order" leaves a pending, to exercise the yes/no.
class AssistantDemoSource implements AssistantSource {
  AssistantDemoSource({this.pace = const Duration(milliseconds: 600)});

  /// How long an answer takes. Zero in tests.
  final Duration pace;

  /// The catalog the surfaces are drawn from (`LyraCatalog.id`).
  static const String catalogId = "lyra.catalog.v1";

  int _surfaces = 0;
  int _ids = 0;
  String? _thread;
  final List<AssistantLine> _lines = [];
  final Map<String, AssistantPending> _pending = {};

  @override
  Future<AssistantBatch> read() async =>
    AssistantBatch(thread: _thread, lines: List.of(_lines), pending: _pending.values.toList());

  @override
  Future<AssistantBatch> send(String message) async {
    if (pace > Duration.zero) await Future<void>.delayed(pace);

    _thread ??= "demo_thread";

    final s = S.current;
    final person = _line(AssistantLineRole.person, message);
    final pending = <AssistantPending>[];
    final AssistantLine answer;

    if (message == s.assistant_demo_order) {
      final held = AssistantPending(
        id: "demo_pending_${_ids++}",
        summary: s.assistant_demo_order_summary,
        operation: "purchases.create",
        expires: DateTime.now().add(const Duration(minutes: 5))
      );
      _pending[held.id] = held;
      pending.add(held);
      answer = _line(AssistantLineRole.assistant, s.assistant_demo_order_ask, calls: const [
        AssistantCall(operation: "stock.summary", status: "done", effect: "read"),
        AssistantCall(operation: "purchases.create", status: "confirm", effect: "write")
      ]);
    } else {
      answer = _line(AssistantLineRole.assistant, _reply(s, message.toLowerCase()), calls: const [
        AssistantCall(operation: "sales.list", status: "done", effect: "read")
      ]);
    }

    return AssistantBatch(thread: _thread, lines: [person, answer], pending: pending);
  }

  @override
  Future<AssistantBatch> confirm(String id, {required bool yes}) async {
    final held = _pending.remove(id);
    if (held == null) throw {"message": "harness_confirmation_not_found"};

    final event = _line(AssistantLineRole.event, held.summary, operation: held.operation, outcome: yes ? "done" : "declined");
    return AssistantBatch(thread: _thread, lines: [event]);
  }

  @override
  Future<void> close() async {
    _thread = null;
    _lines.clear();
    _pending.clear();
  }

  AssistantLine _line(AssistantLineRole role, String text, {List<AssistantCall> calls = const [], String? operation, String? outcome}) {
    final line = AssistantLine(
      id: "demo_${_ids++}",
      role: role,
      text: text,
      date: DateTime.now(),
      calls: calls,
      operation: operation,
      outcome: outcome
    );
    _lines.add(line);
    return line;
  }

  String _reply(S s, String prompt) {
    if (prompt == s.assistant_demo_compare.toLowerCase()) return s.assistant_demo_done(s.assistant_demo_compare);

    if (_has(prompt, const ["sale", "sold", "revenue", "venta", "vend"])) {
      return [s.assistant_demo_sales_intro, _surface(_sales(s)), s.assistant_demo_sales_outro].join("\n");
    }
    if (_has(prompt, const ["stock", "low", "inventor", "run", "agot"])) {
      return [s.assistant_demo_stock_intro, _surface(_stock(s)), s.assistant_demo_stock_outro].join("\n");
    }
    if (_has(prompt, const ["team", "employee", "working", "who", "emplead", "equipo"])) {
      return [s.assistant_demo_team_intro, _surface(_team(s))].join("\n");
    }
    if (_has(prompt, const ["what can", "help", "puedes", "ayuda"])) {
      return [s.assistant_demo_help_intro, _surface(_suggestions(s))].join("\n");
    }
    return [s.assistant_demo_generic, _surface(_suggestions(s))].join("\n");
  }

  bool _has(String prompt, List<String> words) => words.any(prompt.contains);

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
