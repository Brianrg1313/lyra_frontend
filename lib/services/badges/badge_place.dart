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
enum BadgePlace {
  // Side bar entries, by `HomeSection.key`.
  business(["business.profile"]),
  messages(["sidebar.chats"]),
  inventory(["sidebar.inventory"]),
  channels(["sidebar.channels"]),
  finance(["sidebar.money", "business.payments"]),

  // Tabs.
  businessSettings(["business.profile"]),
  financeReceivables(["money.receivables"]),
  financeMethods(["business.payments"]),

  // Header and account.
  pos(["sidebar.pos"]),
  bell(["topbar.notifications"]),
  account(["topbar.account"]),

  // Inputs that cannot be answered while the badge stands.
  paymentMethodField(["field.payment_method"]),
  tableField(["field.table"]);

  const BadgePlace(this.anchors);

  final List<String> anchors;

  /// The side bar entry of a home section, or `null` for one that draws none.
  static BadgePlace? section(String key) => switch (key) {
    "business" => business,
    "messages" => messages,
    "inventory" => inventory,
    "channels" => channels,
    "finance" => finance,
    _ => null
  };
}
