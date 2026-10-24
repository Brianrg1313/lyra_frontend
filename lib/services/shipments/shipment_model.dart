// SERVICES
import 'package:app/services/catalog/catalog_table.dart';

/// Where a shipment stands (`envios-frontend.md` §2). The backend's catalog
/// (`GET /shipments/states`) names each one and says where it may go; this enum
/// only knows the codes, so a row in a state this app has never seen is dropped
/// rather than drawn as a guess.
enum ShipmentState {
  /// An order the customer pays at the door that nobody of the company has
  /// confirmed yet: on the board with its window held, but it takes no carrier
  /// and no move (`409 shipment_unconfirmed`) until it is confirmed from its
  /// conversation, which makes it [unassigned].
  confirming("confirming"),
  unassigned("unassigned"),
  assigned("assigned"),
  picked("picked"),
  enRoute("en_route"),
  delivered("delivered"),
  failed("failed"),
  returned("returned");

  const ShipmentState(this.code);

  /// What the backend calls it (`STATE`).
  final String code;

  /// Every state the board shows by default: all but `delivered`.
  static List<ShipmentState> get going => [for (final state in values) if (state != delivered) state];

  static ShipmentState? from(dynamic code) {
    final text = code?.toString().trim().toLowerCase();

    for (final state in values) {
      if (state.code == text) return state;
    }

    return null;
  }
}

/// One state of the catalog: its name, whether it waits on somebody of the
/// company, and the states it may move to.
class ShipmentStateInfo {
  const ShipmentStateInfo({
    required this.state,
    required this.name,
    this.attention = false,
    this.next = const []
  });

  final ShipmentState state;
  final String name;
  final bool attention;
  final List<ShipmentState> next;

  /// The catalog of `GET /shipments/states`, by state.
  static Map<ShipmentState, ShipmentStateInfo> catalog(dynamic data) {
    final rows = catalogRows(data is Map && data.containsKey("states") ? data["states"] : data);

    return {
      for (final row in rows)
        if (ShipmentState.from(row["state"]) case final ShipmentState state) state: ShipmentStateInfo(
          state: state,
          name: _text(row["name"]),
          attention: row["attention"] == true,
          next: [
            if (row["next"] is List)
              for (final code in row["next"] as List) ?ShipmentState.from(code)
          ]
        )
    };
  }
}

/// How a shipment is carried: one of the branch's riders (`own`) or a
/// platform or courier with its order or tracking number.
class ShipmentCarrier {
  const ShipmentCarrier({
    required this.mode,
    this.employment,
    this.provider,
    this.reference = "",
    this.name = ""
  });

  /// `own`, `platform` or `courier`.
  final String mode;

  /// The rider's job id (`EMPLOYMENT`), for `own`.
  final String? employment;

  /// The carrier's code (`PROVIDER`), otherwise.
  final String? provider;

  final String reference;

  /// The rider's or the carrier's name, as the backend read it.
  final String name;

  bool get isRider => employment != null;

  static ShipmentCarrier? read(dynamic data) {
    if (data is! Map) return null;

    final employment = _text(data["employment"]);
    final provider = _text(data["provider"]);

    if (employment.isEmpty && provider.isEmpty) return null;

    return ShipmentCarrier(
      mode: _text(data["mode"]),
      employment: employment.isEmpty ? null : employment,
      provider: provider.isEmpty ? null : provider,
      reference: _text(data["reference"]),
      name: _text(data["name"])
    );
  }
}

/// Where a shipment goes: the area and place the conversation settled, and the
/// point (what a person wrote, the meeting point agreed, or the customer's
/// newest pin, measured by the backend on every read).
class ShipmentDestination {
  const ShipmentDestination({
    this.area = "",
    this.place = "",
    this.address = "",
    this.latitude,
    this.longitude,
    this.maps = ""
  });

  final String area;
  final String place;
  final String address;
  final double? latitude;
  final double? longitude;

  /// A link that opens the point in any map, built by the backend.
  final String maps;

  /// Half a point is no point.
  bool get hasPoint => latitude != null && longitude != null;

  bool get isEmpty => address.isEmpty && place.isEmpty && area.isEmpty && !hasPoint;

  static ShipmentDestination read(dynamic data) {
    if (data is! Map) return const ShipmentDestination();

    final latitude = _double(data["latitude"]);
    final longitude = _double(data["longitude"]);
    final paired = latitude != null && longitude != null;

    return ShipmentDestination(
      area: _text(data["area"]),
      place: _text(data["place"]),
      address: _text(data["address"]),
      latitude: paired ? latitude : null,
      longitude: paired ? longitude : null,
      maps: _text(data["maps"])
    );
  }
}

/// A span of time: a shipment's agreed window, or a franja the branch offers.
class ShipmentWindow {
  const ShipmentWindow({required this.from, required this.to});

  final DateTime from;
  final DateTime to;

  static ShipmentWindow? read(dynamic data) {
    if (data is! Map) return null;

    final from = _date(data["from"]);
    final to = _date(data["to"]);

    return from == null || to == null ? null : ShipmentWindow(from: from, to: to);
  }

  @override
  bool operator ==(Object other) =>
    other is ShipmentWindow && other.from == from && other.to == to;

  @override
  int get hashCode => Object.hash(from, to);
}

/// What the rider takes at the door of an order paid when it arrives: the
/// payment account the customer chose, its kind (`cash`, `mobile`…; null
/// while the order waits to be confirmed) and the amount, in the sale's
/// currency.
class ShipmentCollect {
  const ShipmentCollect({this.method = "", this.kind, this.amount, this.currency = ""});

  final String method;
  final String? kind;
  final double? amount;
  final String currency;

  static ShipmentCollect? read(dynamic data) {
    if (data is! Map) return null;

    final kind = _text(data["kind"]);

    return ShipmentCollect(
      method: _text(data["method"]),
      kind: kind.isEmpty ? null : kind,
      amount: _double(data["amount"]),
      currency: _text(data["currency"]).toUpperCase()
    );
  }
}

/// The bills a cash order is paid with: [amount] in that account's
/// [currency], what was owed then, and the [change] the rider takes along.
class ShipmentTender {
  const ShipmentTender({
    this.method = "",
    required this.amount,
    this.currency = "",
    this.owed = 0,
    this.change = 0
  });

  final String method;
  final double amount;
  final String currency;
  final double owed;
  final double change;

  static ShipmentTender? read(dynamic data) {
    if (data is! Map) return null;

    final amount = _double(data["amount"]);
    if (amount == null) return null;

    return ShipmentTender(
      method: _text(data["method"]),
      amount: amount,
      currency: _text(data["currency"]).toUpperCase(),
      owed: _double(data["owed"]) ?? 0,
      change: _double(data["change"]) ?? 0
    );
  }
}

/// One step of a shipment's history.
class ShipmentStep {
  const ShipmentStep({required this.state, required this.label, this.at});

  final ShipmentState state;
  final String label;
  final DateTime? at;
}

/// **One delivery of the branch's board** (`GET /shipments`): the sale it
/// belongs to, who carries it, when and where it goes, and how far it got.
///
/// Its [id] is the sale's, which is what every write names it by. A shipment
/// nobody touched yet ([stored] false) is the backend's measure of a paid sale
/// whose customer chose delivery: it is on the board as `unassigned` with
/// nothing written, and the first assignment, window or move stores it.
class Shipment {
  const Shipment({
    required this.id,
    required this.state,
    this.ticket = "",
    this.number = "",
    this.label = "",
    this.attention = false,
    this.charged = true,
    this.collect,
    this.tender,
    this.customer = "",
    this.contact = "",
    this.chat,
    this.total,
    this.fee,
    this.cost,
    this.currency = "",
    this.window,
    this.carrier,
    this.destination = const ShipmentDestination(),
    this.note = "",
    this.receiver = "",
    this.history = const [],
    this.opened,
    this.updated,
    this.stored = false
  });

  final String id;
  final ShipmentState state;

  /// The sale's short code, what the customer says.
  final String ticket;

  /// The branch's internal number of the sale (`A-000123`), empty while open.
  final String number;

  /// The state's name, as the backend says it.
  final String label;

  /// Whether it waits on somebody of the company.
  final bool attention;

  /// Whether the sale is paid (`charged`), or is charged on delivery (`open`).
  final bool charged;

  /// What the rider collects on an order paid when it arrives, else null.
  final ShipmentCollect? collect;

  /// The bills a cash order is paid with and its change, else null.
  final ShipmentTender? tender;

  final String customer;
  final String contact;

  /// The customer's conversation, when the sale came from one.
  final String? chat;

  final double? total;

  /// What the customer paid for the delivery.
  final double? fee;

  /// What carrying it cost the company.
  final double? cost;

  final String currency;
  final ShipmentWindow? window;
  final ShipmentCarrier? carrier;
  final ShipmentDestination destination;
  final String note;
  final String receiver;
  final List<ShipmentStep> history;
  final DateTime? opened;
  final DateTime? updated;
  final bool stored;

  /// What it is called on screen: the internal number, else the ticket's code.
  String get name => number.isNotEmpty ? number : ticket;

  /// Waiting for somebody to confirm an order paid at the door.
  bool get confirming => state == ShipmentState.confirming;

  /// The row in an answer or an event, or null when it can't be one (no id, a
  /// state this app doesn't know). `state: null` in an event is a shipment that
  /// left the board, read by [leftBoard].
  static Shipment? read(dynamic data) {
    if (data is! Map) return null;

    final id = _text(data["id"]);
    final state = ShipmentState.from(data["state"]);

    if (id.isEmpty || state == null) return null;

    return Shipment(
      id: id,
      state: state,
      ticket: _text(data["ticket"]),
      number: _text(data["number"]),
      label: _text(data["label"]),
      attention: data["attention"] == true,
      charged: _text(data["sale"]) != "open",
      collect: ShipmentCollect.read(data["collect"]),
      tender: ShipmentTender.read(data["tender"]),
      customer: _text(data["customer"]),
      contact: _text(data["contact"]),
      chat: _text(data["chat"]).isEmpty ? null : _text(data["chat"]),
      total: _double(data["total"]),
      fee: _double(data["fee"]),
      cost: _double(data["cost"]),
      currency: _text(data["currency"]),
      window: ShipmentWindow.read(data["window"]),
      carrier: ShipmentCarrier.read(data["carrier"]),
      destination: ShipmentDestination.read(data["destination"]),
      note: _text(data["note"]),
      receiver: _text(data["receiver"]),
      history: [
        if (data["history"] is List)
          for (final step in data["history"] as List)
            if (step is Map)
              if (ShipmentState.from(step["state"]) case final ShipmentState state)
                ShipmentStep(state: state, label: _text(step["label"]), at: _date(step["at"]))
      ],
      opened: _date(data["opened"]),
      updated: _date(data["updated"]),
      stored: data["stored"] == true
    );
  }

  /// The id of a `shipment/changed` that took the shipment off the board
  /// (`state: null`: it became a pickup), or null.
  static String? leftBoard(dynamic data) {
    if (data is! Map || data["state"] != null) return null;

    final id = _text(data["id"]);

    return id.isEmpty ? null : id;
  }

  /// The rows of `GET /shipments` (compressed).
  static List<Shipment> list(dynamic data) => [
    for (final row in catalogRows(data is Map && data.containsKey("shipments") ? data["shipments"] : data))
      ?Shipment.read(row)
  ];
}

/// How the branch schedules its deliveries (`GET /shipments/settings`).
class ShippingSettings {
  const ShippingSettings({
    this.span = 120,
    this.capacity,
    this.lead = 60,
    this.days = 3,
    this.width = 180
  });

  /// Minutes each franja lasts.
  final int span;

  /// Shipments per franja; null is no limit.
  final int? capacity;

  /// Minutes to prepare before the first franja.
  final int lead;

  /// Days ahead it offers.
  final int days;

  /// Minutes of each window offered to a customer on a day filling up.
  final int width;

  /// The backend's ranges (`Shipments.input`): a value outside is refused.
  static const ({int min, int max}) spanRange = (min: 15, max: 720);
  static const ({int min, int max}) capacityRange = (min: 1, max: 999);
  static const ({int min, int max}) leadRange = (min: 0, max: 2880);
  static const ({int min, int max}) daysRange = (min: 1, max: 14);
  static const ({int min, int max}) widthRange = (min: 60, max: 720);

  static ShippingSettings read(dynamic data) {
    if (data is! Map) return const ShippingSettings();

    const fallback = ShippingSettings();

    return ShippingSettings(
      span: _int(data["span"]) ?? fallback.span,
      capacity: _int(data["capacity"]),
      lead: _int(data["lead"]) ?? fallback.lead,
      days: _int(data["days"]) ?? fallback.days,
      width: _int(data["width"]) ?? fallback.width
    );
  }
}

/// A franja the branch can deliver in (`GET /shipments/windows`): its moments
/// and, in the company's own time, its day and hours, with what is already
/// promised in it.
class DeliverySlot {
  const DeliverySlot({
    required this.window,
    required this.day,
    required this.opens,
    required this.closes,
    this.taken = 0,
    this.load = 0,
    this.seats
  });

  final ShipmentWindow window;

  /// `YYYY-MM-DD`, `HH:MM`, `HH:MM`: shown as they come.
  final String day;
  final String opens;
  final String closes;

  /// Shipments whose window touches it.
  final int taken;

  /// How much of them falls in it.
  final double load;

  /// Room left; null with no limit.
  final int? seats;

  bool get full => seats != null && seats! <= 0;

  static List<DeliverySlot> list(dynamic data) => [
    for (final row in catalogRows(data is Map && data.containsKey("windows") ? data["windows"] : data))
      if (ShipmentWindow.read(row) case final ShipmentWindow window) DeliverySlot(
        window: window,
        day: _text(row["day"]),
        opens: _text(row["opens"]),
        closes: _text(row["closes"]),
        taken: _int(row["taken"]) ?? 0,
        load: _double(row["load"]) ?? 0,
        seats: _int(row["seats"])
      )
  ];
}

/// One option of what the bot would offer a customer today
/// (`GET /shipments/offer`): an open stretch where the customer names the hour
/// (`range`), or a wide window taken whole (`window`).
class DeliveryOffer {
  const DeliveryOffer({
    required this.kind,
    required this.label,
    required this.opens,
    required this.closes
  });

  final String kind;

  /// The day as the customer reads it ("tomorrow").
  final String label;

  /// The hours as the customer reads them (`9am`, `18:00`).
  final String opens;
  final String closes;

  bool get isRange => kind == "range";

  static List<DeliveryOffer> list(dynamic data) => [
    for (final row in catalogRows(data is Map && data.containsKey("options") ? data["options"] : data))
      DeliveryOffer(
        kind: _text(row["kind"]),
        label: _text(row["label"]),
        opens: row["said"] is Map ? _text(row["said"]["opens"]) : _text(row["opens"]),
        closes: row["said"] is Map ? _text(row["said"]["closes"]) : _text(row["closes"])
      )
  ];
}

/// Who can carry the branch's shipments (`GET /shipments/carriers`).
class ShipmentCarriers {
  const ShipmentCarriers({this.riders = const [], this.providers = const []});

  /// The branch's active people: `id` is the job (`EMPLOYMENT`).
  final List<({String id, String name, String title})> riders;

  /// The platforms and couriers of the company's country: `code` is `PROVIDER`.
  final List<({String code, String name, String kind})> providers;

  static ShipmentCarriers read(dynamic data) {
    if (data is! Map) return const ShipmentCarriers();

    return ShipmentCarriers(
      riders: [
        for (final row in catalogRows(data["riders"]))
          if (_text(row["employment"]).isNotEmpty)
            (id: _text(row["employment"]), name: _text(row["name"]), title: _text(row["title"]))
      ],
      providers: [
        for (final row in catalogRows(data["providers"]))
          if (_text(row["code"]).isNotEmpty)
            (code: _text(row["code"]), name: _text(row["name"]), kind: _text(row["kind"]))
      ]
    );
  }
}

String _text(dynamic value) => value?.toString().trim() ?? "";

int? _int(dynamic value) => switch (value) {
  final num number => number.toInt(),
  final String text => int.tryParse(text.trim()),
  _ => null
};

double? _double(dynamic value) => switch (value) {
  final num number => number.toDouble(),
  final String text => double.tryParse(text.trim()),
  _ => null
};

DateTime? _date(dynamic value) =>
  value == null ? null : DateTime.tryParse(value.toString())?.toLocal();
