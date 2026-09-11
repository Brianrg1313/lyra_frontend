import 'package:flutter/widgets.dart';
import 'package:app/toolkit/toolkit.dart';

/// One of the addresses the business can be written to.
///
/// A business doesn't have "an email": it has support@, sales@, hr@,
/// billing@, and each one means something different to whoever writes to it.
/// That's why they arrive as a list inside the profile and not as one more
/// field.
///
/// [purpose] is a closed list and not free text: that's what makes the list
/// legible —"where does a complaint go" has a single answer— while [label]
/// is the free half, for when the purpose isn't enough ("Colombia Billing")
/// or is `other`, where the name says it all.
class BusinessEmailModel {
  const BusinessEmailModel({
    required this.id,
    required this.email,
    this.purpose = BusinessEmailPurpose.general,
    this.label = "",
    this.main = false,
    this.verified = false,
    this.verifiedDate,
    this.date
  });

  /// Public identifier (uuid). It's what gets sent back to change it
  /// or delete it.
  final String id;

  final String email;

  /// What the address is for.
  final BusinessEmailPurpose purpose;

  /// Name the business gave it, or empty if it didn't give it one.
  final String label;

  /// Whether this is the main address: the one the profile also returns loose
  /// as `email` and the one seen by whoever just wants a single one. As long
  /// as the business has addresses there is exactly one main one.
  final bool main;

  /// Whether the business proved it reads the address: a code was sent to it
  /// and someone returned it (`POST` / `PUT /business/emails/verify/`).
  ///
  /// It says nothing about the business —that's [BusinessVerification], which
  /// is a different thing—: it says the mailbox exists and works. An
  /// unverified address is shown all the same, because it's still a loaded
  /// contact detail; what's shown next to it is that nobody confirmed it
  /// arrives.
  final bool verified;

  /// When it was verified, or `null` if not yet.
  final DateTime? verifiedDate;

  final DateTime? date;

  factory BusinessEmailModel.fromJson(Map json) => BusinessEmailModel(
    id: _text(json["id"]),
    email: _text(json["email"]),
    purpose: BusinessEmailPurpose.from(json["purpose"]),
    label: _text(json["label"]),
    main: json["main"] == true || json["main"] == 1,
    verified: json["verified"] == true || json["verified"] == 1,
    verifiedDate: DateTime.tryParse(_text(json["verified_date"])),
    date: DateTime.tryParse(_text(json["date"]))
  );

  /// The addresses that come inside the profile. A row without an address
  /// isn't built: there's nothing to show or write to.
  static List<BusinessEmailModel> fromList(dynamic value) {
    if (value is! List) return const [];

    return [
      for (final row in value)
        if (row is Map && _text(row["email"]).isNotEmpty)
          BusinessEmailModel.fromJson(row)
    ];
  }

  /// How the address is named on the card: the name the business gave it
  /// and, if it didn't give it one, what it's for.
  String title(BuildContext context) =>
    label.isNotEmpty ? label : purpose.label(context);

  /// How the address's status reads. It's named in the positive and the
  /// negative —"Verified" / "Unverified"— and not with a single text that
  /// appears and disappears: whoever looks at the list has to be able to
  /// tell the address that was confirmed apart from the one nobody confirmed
  /// yet, and a row without a label reads as a row that's missing something.
  String verificationLabel(BuildContext context) => verified
    ? S.of(context).business_email_verified
    : S.of(context).business_email_unverified;

  /// Color of the status label. Fixed and semantic, like the one for the
  /// business's legal status: green means it arrives, amber means nobody
  /// confirmed it. Unverified is not an error —the address may be
  /// perfect— so it isn't red.
  Color get verificationColor =>
    verified ? const Color(0xFF2E9E5B) : const Color(0xFFCF9A17);

  /// Icon for the label. The checkmark is only for the verified state, for
  /// the same reason as in the business's legal status: in the other state
  /// it would read as approved.
  IconData get verificationIcon => verified ? CI.chack_circle : CI.info;

  static String _text(dynamic value) => value?.toString().trim() ?? "";
}

/// What a business address is for.
///
/// These are the values of `company_emails`.`purpose` and they travel in
/// lowercase, exactly as named here.
enum BusinessEmailPurpose {
  general,
  support,
  sales,
  billing,
  hr,
  legal,
  press,
  other;

  /// Anything not recognized falls into [other], which is precisely the
  /// purpose for what a closed list has no name for: this way an address
  /// from a newer version still shows up, with its own name if it has one.
  static BusinessEmailPurpose from(dynamic code) => switch (
    code?.toString().trim().toLowerCase()
  ) {
    "general" => general,
    "support" => support,
    "sales" => sales,
    "billing" => billing,
    "hr" => hr,
    "legal" => legal,
    "press" => press,
    _ => other
  };

  /// Code that travels to the backend. Not translated.
  String get value => name;

  String label(BuildContext context) => switch (this) {
    general => S.of(context).business_email_purpose_general,
    support => S.of(context).business_email_purpose_support,
    sales => S.of(context).business_email_purpose_sales,
    billing => S.of(context).business_email_purpose_billing,
    hr => S.of(context).business_email_purpose_hr,
    legal => S.of(context).business_email_purpose_legal,
    press => S.of(context).business_email_purpose_press,
    other => S.of(context).business_email_purpose_other
  };

  /// What reaches an address of this purpose, written from the sender's
  /// side: "when a customer needs help" and not "support email". Naming the
  /// purpose again doesn't clarify which of the business's addresses each
  /// thing goes to, which is the only thing that needs deciding when
  /// loading them.
  ///
  /// [other] doesn't have one: it's precisely the purpose for what the list
  /// has no name for, so the only thing that can be said about that address
  /// is the name the business gave it.
  String? description(BuildContext context) => switch (this) {
    general => S.of(context).business_email_purpose_general_note,
    support => S.of(context).business_email_purpose_support_note,
    sales => S.of(context).business_email_purpose_sales_note,
    billing => S.of(context).business_email_purpose_billing_note,
    hr => S.of(context).business_email_purpose_hr_note,
    legal => S.of(context).business_email_purpose_legal_note,
    press => S.of(context).business_email_purpose_press_note,
    other => null
  };

  /// What the purpose is recognized by on the card without reading its
  /// name. They're all email addresses, so the envelope wouldn't tell any
  /// of them apart: the icon is about what it's used for.
  IconData get icon => switch (this) {
    general => CI.mail,
    support => CI.support,
    sales => CI.cart_shopping,
    billing => CI.wallet,
    hr => CI.employee,
    legal => CI.documents,
    press => CI.notification,
    other => CI.mail
  };
}
