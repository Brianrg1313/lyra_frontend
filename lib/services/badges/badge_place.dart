/// **Every place in the app that draws a badge**, and which of the backend's anchors it shows.
///
/// The anchor names are a convention the two sides agree on (`model:/badges/catalog.js`), but
/// the backend names places by what they are about (`business.payments`) and this app keeps some
/// of them elsewhere: the payment methods are a finance tab here, not a business one. So the
/// translation lives in this one table instead of at each widget, and moving a dot is one line.
///
/// A place reads its anchors as **one** (`BadgeState.union`): a badge anchored to two of them is
/// counted once.
///
/// `sidebar.business` is deliberately not read: it carries `setup.payments`, which this app fixes
/// in finance, and a dot on a section that has nothing to fix inside it is a dot nobody can clear.
/// The business entry shows what its own tabs show.
///
/// `topbar.account` has no place: the side bar's picture shows the connection instead, and what
/// is the person's own (the terms) is listed in the pending panel.
///
/// A field finer than any anchor (one row of the profile) names its badges by key instead: the
/// settings tab says *which* datum is missing, not only that one is.
enum BadgePlace {
  // Side bar entries, by `HomeSection.key`.
  business(["business.profile"]),
  messages(["sidebar.chats"]),
  sales(["sidebar.sales"]),
  knowledge(["sidebar.knowledge"]),
  inventory(["sidebar.inventory"]),
  channels(["sidebar.channels"]),
  finance(["sidebar.money", "business.payments"]),

  // Tabs.
  businessSettings(["business.profile"]),
  financeReceivables(["money.receivables"]),
  financeMethods(["business.payments"]),
  salesProcess(["sales.process"]),

  // Inventory: the shipments other branches sent here (`inventory.incoming`).
  inventoryTransfers(["inventory.transfers"]),

  // Header.
  pos(["sidebar.pos"]),
  bell(["topbar.notifications"]),

  // Inputs that cannot be answered while the badge stands.
  paymentMethodField(["field.payment_method"]),
  tableField(["field.table"]),

  // Rows of the business profile, by badge key.
  countryField([], ["setup.country"]),
  logoField([], ["setup.logo"]);

  const BadgePlace(this.anchors, [this.keys = const []]);

  final List<String> anchors;

  /// Badges read by their own key, besides those on [anchors].
  final List<String> keys;

  /// The side bar entry of a home section, or `null` for one that draws none.
  static BadgePlace? section(String key) => switch (key) {
    "business" => business,
    "messages" => messages,
    "sales" => sales,
    "knowledge" => knowledge,
    "inventory" => inventory,
    "channels" => channels,
    "finance" => finance,
    _ => null
  };
}
