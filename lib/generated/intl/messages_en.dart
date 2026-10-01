// DO NOT EDIT. This is code generated via package:intl/generate_localized.dart
// This is a library that provides messages for a en locale. All the
// messages from the main program should be duplicated here with the same
// function name.

// Ignore issues from commonly used lints in this file.
// ignore_for_file:unnecessary_brace_in_string_interps, unnecessary_new
// ignore_for_file:prefer_single_quotes,comment_references, directives_ordering
// ignore_for_file:annotate_overrides,prefer_generic_function_type_aliases
// ignore_for_file:unused_import, file_names, avoid_escaping_inner_quotes
// ignore_for_file:unnecessary_string_interpolations, unnecessary_string_escapes

import 'package:intl/intl.dart';
import 'package:intl/message_lookup_by_library.dart';

final messages = new MessageLookup();

typedef String MessageIfAbsent(String messageStr, List<dynamic> args);

class MessageLookup extends MessageLookupByLibrary {
  String get localeName => 'en';

  static String m0(year) => "© ${year} Lyra. All rights reserved.";

  static String m1(error) => "Couldn\'t link WhatsApp: ${error}";

  static String m2(days) => "in ${days} days";

  static String m3(days) => "Every ${days} days";

  static String m4(day) => "Day ${day}";

  static String m5(name) =>
      "${name} and everything tied to it start the 60 days: 30 before the deletion period begins, and 30 more until nothing of it is left.";

  static String m6(coverage) => "${coverage}, unless you pick another";

  static String m7(count) =>
      "${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m8(time) => "From ${time}";

  static String m9(count) => "${count} h";

  static String m10(count) => "${count} min";

  static String m11(from, to) => "${from}–${to} days";

  static String m12(from, to) => "${from}–${to} h";

  static String m13(from, to) => "${from}–${to} min";

  static String m14(time) => "Up to ${time}";

  static String m15(currency) =>
      "In ${currency}. Empty if it varies, 0 if it\'s free";

  static String m16(amount) => "Free from ${amount}";

  static String m17(km) => "Within ${km} km";

  static String m18(name) =>
      "${name} stops being offered to your customers. Removing the last one doesn\'t change whether your business says it delivers.";

  static String m19(count) => "+${count} more";

  static String m20(email) =>
      "${email} stops being one of the addresses this business can be written to. If it\'s the primary one, the oldest of the rest takes its place.";

  static String m21(field) => "Add ${field}";

  static String m22(field) => "Edit ${field}";

  static String m23(provider) =>
      "What ${provider} needs to connect. You can save the channel without them and paste them later";

  static String m24(name) =>
      "Disconnecting ${name} deletes the tokens stored for it. The account can be connected again, but you\'ll have to set it up from scratch.";

  static String m25(count) =>
      "${Intl.plural(count, zero: 'No bots', one: '1 bot', other: '${count} bots')}";

  static String m26(provider) =>
      "What ${provider} needs to connect. You can save the account without them and paste them later";

  static String m27(count) =>
      "${Intl.plural(count, one: 'The bot answering through it is deleted too — pause the account instead to keep it.', other: 'The ${count} bots answering through it are deleted too — pause the account instead to keep them.')}";

  static String m28(name) =>
      "Disconnecting ${name} deletes the credentials stored for it. The account can be connected again, but you\'ll have to set it up from scratch.";

  static String m29(number) => "Area ${number}";

  static String m30(currency) =>
      "In ${currency}. Empty to use the delivery option\'s, 0 if it\'s free";

  static String m31(km) => "${km} km";

  static String m32(count) => "You can have up to ${count} areas.";

  static String m33(amount) => "Min. order ${amount}";

  static String m34(count) =>
      "${Intl.plural(count, one: '1 point', other: '${count} points')} · 3 at least";

  static String m35(name) =>
      "${name} stops being part of where you deliver. To stop delivering there for a while, pause it instead.";

  static String m36(km) => "${km} km²";

  static String m37(label) => "${label} copied";

  static String m38(count) =>
      "${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m39(years) => "They must be at least ${years} years old";

  static String m40(label) => "New ${label}, then Enter";

  static String m41(label) => "Click to edit ${label}";

  static String m42(label) =>
      "${label} takes only letters, spaces, hyphens and apostrophes";

  static String m43(dial, count) =>
      "Numbers from ${dial} have ${count} digits after the code";

  static String m44(dial, min, max) =>
      "Numbers from ${dial} have ${min} to ${max} digits after the code";

  static String m45(label) => "${label} can\'t be empty";

  static String m46(count) =>
      "${Intl.plural(count, one: '1 day', other: '${count} days')}";

  static String m47(count) =>
      "${Intl.plural(count, one: '1 month', other: '${count} months')}";

  static String m48(date) => "In the company, since ${date}";

  static String m49(count) =>
      "${Intl.plural(count, one: '1 year', other: '${count} years')}";

  static String m50(count) =>
      "${Intl.plural(count, zero: 'Nobody active', one: '1 active', other: '${count} active')}";

  static String m51(count) =>
      "${Intl.plural(count, one: '1 invitation pending', other: '${count} invitations pending')}";

  static String m52(conversations, messages) =>
      "${conversations} conversations · ${messages} replies";

  static String m53(currency) =>
      "What Lyra, the bot that answers your customers, cost to run — billed in ${currency}. It is measured and not recorded, so it is not part of the money above.";

  static String m54(count) => "${count} runs";

  static String m55(main) =>
      "A currency you also charge in. Its rate says how much of it one ${main} is worth.";

  static String m56(rate) => "Official rate: ${rate}";

  static String m57(main, currency) => "1 ${main} in ${currency}";

  static String m58(currency) =>
      "${currency} stops being offered. Payment methods in ${currency} stay, with no rate to convert their charge.";

  static String m59(date) => "Updated ${date}";

  static String m60(currency) => "This method only moves ${currency}.";

  static String m61(currency) =>
      "${currency} has no exchange rate. Add it under Currencies so the charge can be converted into it.";

  static String m62(currency) => "Fixed amount in ${currency}";

  static String m63(value) => "${value}%";

  static String m64(name) =>
      "${name} stops being offered. The payments already recorded through it stay in the history.";

  static String m65(count) => "Load ${count} more";

  static String m66(count) => "${count} movements";

  static String m67(amount) =>
      "The payment of ${amount} stops counting, but stays in the history. It cannot be undone: a mistake is voided and recorded again.";

  static String m68(from, to) => "From ${from} to ${to}";

  static String m69(email) => "The ${email} is empty";

  static String m70(email) => "The ${email} is incomplete";

  static String m71(email) => "The ${email} is invalid";

  static String m72(email) => "The ${email} is very long";

  static String m73(address) => "Then open ${address} in the browser.";

  static String m74(code) => "This device: ${code}";

  static String m75(name) => "Remove ${name}?";

  static String m76(code) => "Code: ${code}";

  static String m77(address) =>
      "This browser will pair with the server at ${address}.";

  static String m78(count) =>
      "${count} other devices are connected. Every device stops working until the server starts again.";

  static String m79(name) => "Assigned to ${name}";

  static String m80(count) => "+${count} more";

  static String m81(name) => "Attended by ${name}";

  static String m82(date) => "until ${date}";

  static String m83(count) => "${count} conversations";

  static String m84(name) => "${name} was assigned to you";

  static String m85(name) => "${name} is waiting for an answer";

  static String m86(count) => "${count} new movements, refresh";

  static String m87(date) => "Since ${date}";

  static String m88(codes) => "Tickets: ${codes}";

  static String m89(requests, input, output) =>
      "${requests} calls · ${input} in · ${output} out";

  static String m90(count) => "${count} d";

  static String m91(count) => "${count} h";

  static String m92(count) => "${count} min";

  static String m93(time) => "Waiting ${time}";

  static String m94(access, area) => "${access}: ${area}";

  static String m95(business) =>
      "You already requested access to this section in ${business}. You\'ll be able to open it as soon as it\'s granted.";

  static String m96(business) =>
      "Your role in ${business} doesn\'t include this section. Request access and whoever manages the business will review it.";

  static String m97(section) => "You don\'t have access to ${section}";

  static String m98(granted, total) => "${granted} of ${total} open";

  static String m99(max) => "The note can\'t be longer than ${max} characters.";

  static String m100(section) =>
      "Request sent. You\'ll be able to open ${section} once it\'s granted.";

  static String m101(section, business) =>
      "You\'re asking for access to ${section} in ${business}. You can add a note to explain why you need it.";

  static String m102(ticket) => "Ticket ${ticket} charged";

  static String m103(count) =>
      "${Intl.plural(count, zero: 'Out of stock', one: '1 left', other: '${count} left')}";

  static String m104(count) =>
      "${Intl.plural(count, zero: 'No sales today', one: '1 sale today', other: '${count} sales today')}";

  static String m105(price) => "${price} each";

  static String m106(number) => "Ticket #${number}";

  static String m107(product) =>
      "The units of ${product} were released from the stock screen and are no longer set aside for this ticket";

  static String m108(rate) => "VAT ${rate}%";

  static String m109(count) =>
      "${Intl.plural(count, zero: 'Nothing on it yet', one: '1 product', other: '${count} products')}";

  static String m110(page) => "Page ${page}";

  static String m111(count) =>
      "${Intl.plural(count, zero: 'No rows match your search', one: '1 row matches', other: '${count} rows match')}";

  static String m112(time) => "Resend code in ${time}";

  static String m113(count) => "${count} sales";

  static String m114(count) => "${count} units";

  static String m115(count) => "${count} left";

  static String m116(count) => "${count} held";

  static String m117(price) => "was ${price}";

  static String m118(count) => "${count} no longer sold";

  static String m119(count) => "${count} said to be held, and nothing is";

  static String m120(count) => "${count} sent in all";

  static String m121(rate, base) => "${rate}% on ${base}";

  static String m122(count) => "${count} moved";

  static String m123(count) => "${count} d";

  static String m124(count) => "${count} h";

  static String m125(count) => "${count} min";

  static String m126(email) =>
      "We sent a code to ${email}. Enter it with your name and your account is ready.";

  static String m127(count) =>
      "${Intl.plural(count, zero: 'Nothing available right now', one: '1 unit available', other: '${count} units available')}";

  static String m128(max) => "Enter a whole number between 1 and ${max}";

  static String m129(count) =>
      "${Intl.plural(count, zero: 'Nothing reserved right now', one: '1 unit reserved', other: '${count} units reserved')}";

  static String m130(count) =>
      "${Intl.plural(count, one: 'One less', other: '${count} less')}";

  static String m131(count) =>
      "${Intl.plural(count, one: 'One more', other: '${count} more')}";

  static String m132(count) =>
      "${Intl.plural(count, zero: 'No products', one: '1 product', other: '${count} products')}";

  static String m133(name) =>
      "Deleting ${name} removes its fields and everything stored in it. This can\'t be undone.";

  static String m134(count) =>
      "${Intl.plural(count, zero: 'No fields', one: '1 field', other: '${count} fields')}";

  static String m135(name) =>
      "Leaving the name empty deletes ${name} and everything stored in it. This can\'t be undone.";

  static String m136(count) =>
      "${Intl.plural(count, one: 'visibility set on 1 column', other: 'visibility set on ${count} columns')}";

  static String m137(count) =>
      "${Intl.plural(count, one: '1 column renamed', other: '${count} columns renamed')}";

  static String m138(count) =>
      "${Intl.plural(count, one: '1 column retyped', other: '${count} columns retyped')}";

  static String m139(count) =>
      "${Intl.plural(count, one: '1 column added to the summary', other: '${count} columns added to the summary')}";

  static String m140(count) =>
      "${Intl.plural(count, zero: 'No records', one: '1 record', other: '${count} records')}";

  static String m141(field) => "Add ${field}";

  static String m142(count) =>
      "${Intl.plural(count, zero: 'No columns', one: '1 column', other: '${count} columns')}";

  static String m143(count, total) =>
      "Inventory summary: ${count} of ${total} columns";

  static String m144(field) => "Edit ${field}";

  static String m145(count) =>
      "${Intl.plural(count, one: '1 option', other: '${count} options')}";

  static String m146(type, count) => "${type} · ${count}";

  static String m147(count) =>
      "${Intl.plural(count, one: '1 column is still plain text', other: '${count} columns are still plain text')}";

  static String m148(length) => "Enter the ${length}-digit code we sent to";

  static String m149(time) => "Resend in ${time}";

  static String m150(company) =>
      "Once you accept, you join ${company}\'s team and they can see your profile.";

  static String m151(job, company) => "${job} at ${company}";

  static String m152(company) => "${company} invited you";

  static String m153(name) => "Welcome, ${name}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
    "a": MessageLookupByLibrary.simpleMessage("a"),
    "account": MessageLookupByLibrary.simpleMessage("Account"),
    "add": MessageLookupByLibrary.simpleMessage("Add"),
    "add_field": MessageLookupByLibrary.simpleMessage("Add field"),
    "add_field_subtitle": MessageLookupByLibrary.simpleMessage(
      "Add a column and choose the kind of information it holds",
    ),
    "add_new_subscription": MessageLookupByLibrary.simpleMessage(
      "Add new subscription",
    ),
    "add_subscription": MessageLookupByLibrary.simpleMessage(
      "Add subscription",
    ),
    "amount": MessageLookupByLibrary.simpleMessage("Amount"),
    "annual": MessageLookupByLibrary.simpleMessage("Annual"),
    "auth_brand": MessageLookupByLibrary.simpleMessage("Lyra"),
    "auth_continue": MessageLookupByLibrary.simpleMessage("Continue"),
    "auth_footer_copyright": m0,
    "auth_footer_language": MessageLookupByLibrary.simpleMessage("Language"),
    "auth_footer_privacy": MessageLookupByLibrary.simpleMessage(
      "Privacy policy",
    ),
    "auth_footer_terms": MessageLookupByLibrary.simpleMessage(
      "Terms and conditions",
    ),
    "auth_offline_message": MessageLookupByLibrary.simpleMessage(
      "This device can\'t reach Lyra\'s servers right now. Check the internet connection and try again.",
    ),
    "auth_offline_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "auth_offline_title": MessageLookupByLibrary.simpleMessage(
      "No connection to Lyra",
    ),
    "auth_or_with": MessageLookupByLibrary.simpleMessage("or continue with"),
    "auth_subtitle": MessageLookupByLibrary.simpleMessage(
      "Enter your email. If it\'s new to Lyra, we\'ll create your account with it.",
    ),
    "auth_terms_prefix": MessageLookupByLibrary.simpleMessage(
      "By continuing, you agree to our ",
    ),
    "auth_title": MessageLookupByLibrary.simpleMessage(
      "Sign in or create your account",
    ),
    "back": MessageLookupByLibrary.simpleMessage("Back"),
    "baileys_pairing_connected": MessageLookupByLibrary.simpleMessage(
      "WhatsApp linked",
    ),
    "baileys_pairing_error": m1,
    "baileys_pairing_instructions": MessageLookupByLibrary.simpleMessage(
      "Open WhatsApp on your phone, go to Linked Devices and scan this code",
    ),
    "baileys_pairing_title": MessageLookupByLibrary.simpleMessage(
      "Link WhatsApp",
    ),
    "baileys_pairing_waiting": MessageLookupByLibrary.simpleMessage(
      "Preparing the QR code…",
    ),
    "baileys_start_error": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t start the WhatsApp service",
    ),
    "baileys_status_connected": MessageLookupByLibrary.simpleMessage(
      "Connected",
    ),
    "baileys_status_error": MessageLookupByLibrary.simpleMessage(
      "Connection error",
    ),
    "baileys_status_logged_out": MessageLookupByLibrary.simpleMessage(
      "Unlinked — scan a new QR",
    ),
    "baileys_status_qr_pending": MessageLookupByLibrary.simpleMessage(
      "Scan the QR to link",
    ),
    "baileys_status_reconnecting": MessageLookupByLibrary.simpleMessage(
      "Reconnecting…",
    ),
    "baileys_status_starting": MessageLookupByLibrary.simpleMessage(
      "Starting…",
    ),
    "baileys_status_stopped": MessageLookupByLibrary.simpleMessage("Off"),
    "baileys_status_unknown": MessageLookupByLibrary.simpleMessage("Off"),
    "baileys_stop_error": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t stop the WhatsApp service",
    ),
    "baileys_unlink_action": MessageLookupByLibrary.simpleMessage(
      "Unlink WhatsApp",
    ),
    "baileys_unlink_error": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t unlink WhatsApp",
    ),
    "baileys_unlink_explanation": MessageLookupByLibrary.simpleMessage(
      "Unlinking drops this computer\'s link to your phone. The channel stays exactly as it is — its role, its data and its place here — and turning it back on asks for a new QR code.",
    ),
    "baileys_unlink_message": MessageLookupByLibrary.simpleMessage(
      "This channel stops answering on WhatsApp until you scan a new QR code. Nothing you set up on it is lost.",
    ),
    "baileys_unlink_title": MessageLookupByLibrary.simpleMessage(
      "Unlink this WhatsApp?",
    ),
    "baileys_unlinked": MessageLookupByLibrary.simpleMessage(
      "WhatsApp unlinked",
    ),
    "billing_date_custom_label": MessageLookupByLibrary.simpleMessage(
      "Date of first charge",
    ),
    "billing_date_month_label": MessageLookupByLibrary.simpleMessage("Month"),
    "billing_date_monthday_label": MessageLookupByLibrary.simpleMessage(
      "Day of the month",
    ),
    "billing_date_title": MessageLookupByLibrary.simpleMessage(
      "When do you get charged?",
    ),
    "billing_date_weekday_label": MessageLookupByLibrary.simpleMessage(
      "Day of the week",
    ),
    "billing_day": MessageLookupByLibrary.simpleMessage("Day"),
    "billing_days_left": m2,
    "billing_label_custom": m3,
    "billing_label_monthly": m4,
    "billing_period": MessageLookupByLibrary.simpleMessage("Billing period"),
    "billing_today": MessageLookupByLibrary.simpleMessage("Today"),
    "business": MessageLookupByLibrary.simpleMessage("Business"),
    "business_branch_create_subtitle": MessageLookupByLibrary.simpleMessage(
      "Every branch is in the country of the business: its phone code and the address search come from it.",
    ),
    "business_branch_create_title": MessageLookupByLibrary.simpleMessage(
      "New branch",
    ),
    "business_branch_edit_title": MessageLookupByLibrary.simpleMessage(
      "Edit branch",
    ),
    "business_branch_invoicing_note": MessageLookupByLibrary.simpleMessage(
      "Leave them empty if this branch invoices as the business itself.",
    ),
    "business_branch_kind": MessageLookupByLibrary.simpleMessage("Type"),
    "business_branch_kind_store": MessageLookupByLibrary.simpleMessage("Store"),
    "business_branch_kind_store_note": MessageLookupByLibrary.simpleMessage(
      "Customers can come to it",
    ),
    "business_branch_kind_warehouse": MessageLookupByLibrary.simpleMessage(
      "Warehouse",
    ),
    "business_branch_kind_warehouse_note": MessageLookupByLibrary.simpleMessage(
      "Stock only, customers don\'t visit it",
    ),
    "business_branch_legal_name": MessageLookupByLibrary.simpleMessage(
      "Legal name",
    ),
    "business_branch_legal_name_hint": MessageLookupByLibrary.simpleMessage(
      "Inversiones Sol C.A.",
    ),
    "business_branch_main": MessageLookupByLibrary.simpleMessage("Main"),
    "business_branch_main_note": MessageLookupByLibrary.simpleMessage(
      "The branch a customer is given when they don\'t ask for one. Only one branch is the main one.",
    ),
    "business_branch_main_toggle": MessageLookupByLibrary.simpleMessage(
      "Main branch",
    ),
    "business_branch_name": MessageLookupByLibrary.simpleMessage("Name"),
    "business_branch_name_hint": MessageLookupByLibrary.simpleMessage(
      "Downtown store",
    ),
    "business_branch_no_address": MessageLookupByLibrary.simpleMessage(
      "No address yet",
    ),
    "business_branch_online": MessageLookupByLibrary.simpleMessage(
      "Bot orders",
    ),
    "business_branch_online_note": MessageLookupByLibrary.simpleMessage(
      "Orders that arrive through your channels can be fulfilled from this branch",
    ),
    "business_branch_online_off": MessageLookupByLibrary.simpleMessage(
      "Doesn\'t take orders from the bot",
    ),
    "business_branch_online_on": MessageLookupByLibrary.simpleMessage(
      "Takes orders from the bot",
    ),
    "business_branch_phone": MessageLookupByLibrary.simpleMessage("Phone"),
    "business_branch_phone_full_hint": MessageLookupByLibrary.simpleMessage(
      "+584121234567",
    ),
    "business_branch_phone_hint": MessageLookupByLibrary.simpleMessage(
      "4121234567",
    ),
    "business_branch_point": MessageLookupByLibrary.simpleMessage(
      "Point on the map",
    ),
    "business_branch_point_clear": MessageLookupByLibrary.simpleMessage(
      "Remove point",
    ),
    "business_branch_point_help": MessageLookupByLibrary.simpleMessage(
      "Search the address over the map, or tap the map where the branch is. It\'s optional.",
    ),
    "business_branch_save": MessageLookupByLibrary.simpleMessage(
      "Save changes",
    ),
    "business_branch_section_address": MessageLookupByLibrary.simpleMessage(
      "Address",
    ),
    "business_branch_section_contact": MessageLookupByLibrary.simpleMessage(
      "Contact",
    ),
    "business_branch_section_invoicing": MessageLookupByLibrary.simpleMessage(
      "Invoicing",
    ),
    "business_branch_tax_id": MessageLookupByLibrary.simpleMessage("Tax ID"),
    "business_branch_tax_id_hint": MessageLookupByLibrary.simpleMessage(
      "J-12345678-9",
    ),
    "business_branches_add": MessageLookupByLibrary.simpleMessage("Add branch"),
    "business_branches_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Add the places this business works from.",
    ),
    "business_branches_empty_title": MessageLookupByLibrary.simpleMessage(
      "No branches yet",
    ),
    "business_branches_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "business_branches_error_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load the branches",
    ),
    "business_branches_subtitle": MessageLookupByLibrary.simpleMessage(
      "The places this business works from: stores, offices and warehouses.",
    ),
    "business_branches_title": MessageLookupByLibrary.simpleMessage("Branches"),
    "business_clients_soon": MessageLookupByLibrary.simpleMessage(
      "The customers of this business and what they bought will be listed here.",
    ),
    "business_delete_action": MessageLookupByLibrary.simpleMessage(
      "Delete business",
    ),
    "business_delete_confirm_message": m5,
    "business_delete_confirm_title": MessageLookupByLibrary.simpleMessage(
      "Delete this business?",
    ),
    "business_delete_schedule": MessageLookupByLibrary.simpleMessage(
      "It doesn\'t happen right away. The business waits 30 days before it enters the deletion period, and 30 more while it\'s being deleted.",
    ),
    "business_delete_section": MessageLookupByLibrary.simpleMessage(
      "Delete business",
    ),
    "business_delete_warning": MessageLookupByLibrary.simpleMessage(
      "Deleting this business erases everything tied to it: its profile, its people, its branches, its catalog, its customers and its history. None of it is kept.",
    ),
    "business_delivery_add": MessageLookupByLibrary.simpleMessage(
      "Add a way to deliver",
    ),
    "business_delivery_amount_invalid": MessageLookupByLibrary.simpleMessage(
      "Write amounts with digits and up to two decimals, without thousands separators.",
    ),
    "business_delivery_carrier_required": MessageLookupByLibrary.simpleMessage(
      "Pick the company that carries it, or write its name.",
    ),
    "business_delivery_choose": MessageLookupByLibrary.simpleMessage(
      "Change the answer",
    ),
    "business_delivery_coverage": MessageLookupByLibrary.simpleMessage(
      "How far it reaches",
    ),
    "business_delivery_coverage_default": m6,
    "business_delivery_coverage_international":
        MessageLookupByLibrary.simpleMessage("International"),
    "business_delivery_coverage_international_note":
        MessageLookupByLibrary.simpleMessage("To other countries too"),
    "business_delivery_coverage_local": MessageLookupByLibrary.simpleMessage(
      "Local",
    ),
    "business_delivery_coverage_local_note":
        MessageLookupByLibrary.simpleMessage(
          "Some areas, or a radius around your location",
        ),
    "business_delivery_coverage_national": MessageLookupByLibrary.simpleMessage(
      "National",
    ),
    "business_delivery_coverage_national_note":
        MessageLookupByLibrary.simpleMessage("Anywhere in the country"),
    "business_delivery_coverage_placeholder":
        MessageLookupByLibrary.simpleMessage("Pick how far it reaches"),
    "business_delivery_create_title": MessageLookupByLibrary.simpleMessage(
      "New way to deliver",
    ),
    "business_delivery_delivers": MessageLookupByLibrary.simpleMessage(
      "Delivers to customers",
    ),
    "business_delivery_delivers_note": MessageLookupByLibrary.simpleMessage(
      "What your assistant answers when someone asks if you deliver. While it isn\'t set, it never tells a customer no.",
    ),
    "business_delivery_edit_title": MessageLookupByLibrary.simpleMessage(
      "Edit way to deliver",
    ),
    "business_delivery_empty": MessageLookupByLibrary.simpleMessage(
      "Way to deliver",
    ),
    "business_delivery_empty_note": MessageLookupByLibrary.simpleMessage(
      "Nothing yet. Add your own riders, a delivery app or a parcel carrier.",
    ),
    "business_delivery_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "business_delivery_error_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load delivery",
    ),
    "business_delivery_eta": MessageLookupByLibrary.simpleMessage(
      "Delivery time",
    ),
    "business_delivery_eta_days": m7,
    "business_delivery_eta_from": m8,
    "business_delivery_eta_hours": m9,
    "business_delivery_eta_invalid": MessageLookupByLibrary.simpleMessage(
      "The delivery time goes from 1 minute to 30 days, and the first figure can\'t be larger than the second.",
    ),
    "business_delivery_eta_max": MessageLookupByLibrary.simpleMessage("To"),
    "business_delivery_eta_min": MessageLookupByLibrary.simpleMessage("From"),
    "business_delivery_eta_minutes": m10,
    "business_delivery_eta_range_days": m11,
    "business_delivery_eta_range_hours": m12,
    "business_delivery_eta_range_minutes": m13,
    "business_delivery_eta_unit": MessageLookupByLibrary.simpleMessage("Unit"),
    "business_delivery_eta_up_to": m14,
    "business_delivery_fee": MessageLookupByLibrary.simpleMessage("Price"),
    "business_delivery_fee_free": MessageLookupByLibrary.simpleMessage("Free"),
    "business_delivery_fee_hint": m15,
    "business_delivery_fee_varies": MessageLookupByLibrary.simpleMessage(
      "Price varies",
    ),
    "business_delivery_form_subtitle": MessageLookupByLibrary.simpleMessage(
      "Who carries the order, how far it goes, what it costs and how long it takes. It\'s what your customers are told when they ask.",
    ),
    "business_delivery_free_from": m16,
    "business_delivery_free_from_hint": MessageLookupByLibrary.simpleMessage(
      "Order total from which it\'s free",
    ),
    "business_delivery_free_from_title": MessageLookupByLibrary.simpleMessage(
      "Free from",
    ),
    "business_delivery_label": MessageLookupByLibrary.simpleMessage("Name"),
    "business_delivery_label_carrier": MessageLookupByLibrary.simpleMessage(
      "Company name",
    ),
    "business_delivery_label_hint": MessageLookupByLibrary.simpleMessage(
      "Downtown riders",
    ),
    "business_delivery_meeting": MessageLookupByLibrary.simpleMessage(
      "Delivery areas",
    ),
    "business_delivery_meeting_fixed": MessageLookupByLibrary.simpleMessage(
      "Fixed",
    ),
    "business_delivery_meeting_fixed_note":
        MessageLookupByLibrary.simpleMessage("Only delivers inside your areas"),
    "business_delivery_meeting_flexible": MessageLookupByLibrary.simpleMessage(
      "Flexible",
    ),
    "business_delivery_meeting_flexible_note": MessageLookupByLibrary.simpleMessage(
      "Agrees with the customer on a meeting spot, the nearest one your areas reach",
    ),
    "business_delivery_meeting_note": MessageLookupByLibrary.simpleMessage(
      "What your assistant does when a customer is outside every area you drew.",
    ),
    "business_delivery_mode": MessageLookupByLibrary.simpleMessage(
      "Who carries it",
    ),
    "business_delivery_mode_courier": MessageLookupByLibrary.simpleMessage(
      "Parcel carrier",
    ),
    "business_delivery_mode_courier_note": MessageLookupByLibrary.simpleMessage(
      "A shipping company like Zoom, MRW or DHL sends it",
    ),
    "business_delivery_mode_own": MessageLookupByLibrary.simpleMessage(
      "Own riders",
    ),
    "business_delivery_mode_own_note": MessageLookupByLibrary.simpleMessage(
      "Your business\'s own couriers carry the order",
    ),
    "business_delivery_mode_placeholder": MessageLookupByLibrary.simpleMessage(
      "Pick who carries the order",
    ),
    "business_delivery_mode_platform": MessageLookupByLibrary.simpleMessage(
      "Delivery app",
    ),
    "business_delivery_mode_platform_note":
        MessageLookupByLibrary.simpleMessage(
          "An app like PedidosYa, Yummy or Rappi carries it",
        ),
    "business_delivery_no": MessageLookupByLibrary.simpleMessage("No"),
    "business_delivery_no_catalog": MessageLookupByLibrary.simpleMessage(
      "The list of apps and carriers couldn\'t be loaded. You can still write the name of yours.",
    ),
    "business_delivery_no_country": MessageLookupByLibrary.simpleMessage(
      "Your business has no country set, so only carriers that work everywhere are listed. Set it in Settings.",
    ),
    "business_delivery_notes": MessageLookupByLibrary.simpleMessage(
      "Delivery note",
    ),
    "business_delivery_notes_hint": MessageLookupByLibrary.simpleMessage(
      "Orders placed before 2 pm leave the same day",
    ),
    "business_delivery_notes_note": MessageLookupByLibrary.simpleMessage(
      "One sentence about delivery in general, in your own words.",
    ),
    "business_delivery_off_note": MessageLookupByLibrary.simpleMessage(
      "Delivery is turned off, so none of these is offered. They stay saved for when you turn it back on.",
    ),
    "business_delivery_option_notes": MessageLookupByLibrary.simpleMessage(
      "Notes",
    ),
    "business_delivery_option_notes_hint": MessageLookupByLibrary.simpleMessage(
      "Cash on delivery",
    ),
    "business_delivery_optional": MessageLookupByLibrary.simpleMessage(
      "optional",
    ),
    "business_delivery_own_default": MessageLookupByLibrary.simpleMessage(
      "Own riders",
    ),
    "business_delivery_pickup": MessageLookupByLibrary.simpleMessage(
      "Pickup at the business",
    ),
    "business_delivery_pickup_note": MessageLookupByLibrary.simpleMessage(
      "Whether a customer can collect the order at your location.",
    ),
    "business_delivery_provider": MessageLookupByLibrary.simpleMessage(
      "Company",
    ),
    "business_delivery_provider_global": MessageLookupByLibrary.simpleMessage(
      "Works everywhere",
    ),
    "business_delivery_provider_other": MessageLookupByLibrary.simpleMessage(
      "Another one",
    ),
    "business_delivery_provider_other_note":
        MessageLookupByLibrary.simpleMessage(
          "Not in the list: write its name below",
        ),
    "business_delivery_provider_placeholder":
        MessageLookupByLibrary.simpleMessage("Pick the app or the carrier"),
    "business_delivery_radius": m17,
    "business_delivery_radius_hint": MessageLookupByLibrary.simpleMessage("5"),
    "business_delivery_radius_invalid": MessageLookupByLibrary.simpleMessage(
      "The radius goes in kilometres, above 0 and up to 1000.",
    ),
    "business_delivery_radius_title": MessageLookupByLibrary.simpleMessage(
      "Radius in km",
    ),
    "business_delivery_remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "business_delivery_remove_message": m18,
    "business_delivery_remove_title": MessageLookupByLibrary.simpleMessage(
      "Remove this way to deliver?",
    ),
    "business_delivery_section_general": MessageLookupByLibrary.simpleMessage(
      "Delivery",
    ),
    "business_delivery_section_options": MessageLookupByLibrary.simpleMessage(
      "Ways you deliver",
    ),
    "business_delivery_select_empty": MessageLookupByLibrary.simpleMessage(
      "No option matches your search",
    ),
    "business_delivery_unit_days": MessageLookupByLibrary.simpleMessage("Days"),
    "business_delivery_unit_hours": MessageLookupByLibrary.simpleMessage(
      "Hours",
    ),
    "business_delivery_unit_minutes": MessageLookupByLibrary.simpleMessage(
      "Minutes",
    ),
    "business_delivery_unset": MessageLookupByLibrary.simpleMessage(
      "Not set yet",
    ),
    "business_delivery_unset_note": MessageLookupByLibrary.simpleMessage(
      "Listing a way to deliver already counts as yes",
    ),
    "business_delivery_yes": MessageLookupByLibrary.simpleMessage("Yes"),
    "business_delivery_zone_add": MessageLookupByLibrary.simpleMessage(
      "Add zone",
    ),
    "business_delivery_zone_fee": MessageLookupByLibrary.simpleMessage(
      "Own price",
    ),
    "business_delivery_zone_invalid": MessageLookupByLibrary.simpleMessage(
      "Every zone needs a name of up to 80 characters, and its own price has to be an amount.",
    ),
    "business_delivery_zone_name": MessageLookupByLibrary.simpleMessage("Zone"),
    "business_delivery_zone_remove": MessageLookupByLibrary.simpleMessage(
      "Remove zone",
    ),
    "business_delivery_zones": MessageLookupByLibrary.simpleMessage("Zones"),
    "business_delivery_zones_more": m19,
    "business_delivery_zones_note": MessageLookupByLibrary.simpleMessage(
      "The areas it reaches, as your customers call them. A zone can have a price of its own.",
    ),
    "business_email_add": MessageLookupByLibrary.simpleMessage("Add address"),
    "business_email_address": MessageLookupByLibrary.simpleMessage(
      "Email address",
    ),
    "business_email_address_hint": MessageLookupByLibrary.simpleMessage(
      "name@business.com",
    ),
    "business_email_delete_message": m20,
    "business_email_delete_title": MessageLookupByLibrary.simpleMessage(
      "Delete this address?",
    ),
    "business_email_deleted": MessageLookupByLibrary.simpleMessage(
      "Address deleted",
    ),
    "business_email_edit_title": MessageLookupByLibrary.simpleMessage(
      "Edit address",
    ),
    "business_email_empty": MessageLookupByLibrary.simpleMessage(
      "This business has no email addresses yet.",
    ),
    "business_email_label": MessageLookupByLibrary.simpleMessage("Name"),
    "business_email_label_hint": MessageLookupByLibrary.simpleMessage(
      "Billing Colombia",
    ),
    "business_email_main": MessageLookupByLibrary.simpleMessage("Primary"),
    "business_email_promote": MessageLookupByLibrary.simpleMessage(
      "Make primary",
    ),
    "business_email_promoted": MessageLookupByLibrary.simpleMessage(
      "Primary address updated",
    ),
    "business_email_purpose": MessageLookupByLibrary.simpleMessage("Used for"),
    "business_email_purpose_billing": MessageLookupByLibrary.simpleMessage(
      "Billing",
    ),
    "business_email_purpose_billing_note": MessageLookupByLibrary.simpleMessage(
      "Where invoices, receipts and anything about a payment are sent.",
    ),
    "business_email_purpose_general": MessageLookupByLibrary.simpleMessage(
      "General",
    ),
    "business_email_purpose_general_note": MessageLookupByLibrary.simpleMessage(
      "The everyday address. Anything that doesn\'t belong to another one lands here.",
    ),
    "business_email_purpose_hr": MessageLookupByLibrary.simpleMessage("People"),
    "business_email_purpose_hr_note": MessageLookupByLibrary.simpleMessage(
      "Where job applications and anything about the people who work here arrive.",
    ),
    "business_email_purpose_legal": MessageLookupByLibrary.simpleMessage(
      "Legal",
    ),
    "business_email_purpose_legal_note": MessageLookupByLibrary.simpleMessage(
      "Where contracts, claims and formal notices are received.",
    ),
    "business_email_purpose_other": MessageLookupByLibrary.simpleMessage(
      "Other",
    ),
    "business_email_purpose_press": MessageLookupByLibrary.simpleMessage(
      "Press",
    ),
    "business_email_purpose_press_note": MessageLookupByLibrary.simpleMessage(
      "Where media and partners write about the business itself.",
    ),
    "business_email_purpose_sales": MessageLookupByLibrary.simpleMessage(
      "Sales",
    ),
    "business_email_purpose_sales_note": MessageLookupByLibrary.simpleMessage(
      "Where someone writes to buy, ask for a quote or start a deal.",
    ),
    "business_email_purpose_support": MessageLookupByLibrary.simpleMessage(
      "Support",
    ),
    "business_email_purpose_support_note": MessageLookupByLibrary.simpleMessage(
      "Where a customer writes when something doesn\'t work or they need help with a product or service.",
    ),
    "business_email_unverified": MessageLookupByLibrary.simpleMessage(
      "Unverified",
    ),
    "business_email_verified": MessageLookupByLibrary.simpleMessage("Verified"),
    "business_email_verified_done": MessageLookupByLibrary.simpleMessage(
      "Address verified",
    ),
    "business_email_verify": MessageLookupByLibrary.simpleMessage("Verify"),
    "business_email_verify_sent": MessageLookupByLibrary.simpleMessage(
      "We mailed a 6-digit code to this address. Type it in to prove the business reads it.",
    ),
    "business_email_verify_title": MessageLookupByLibrary.simpleMessage(
      "Verify address",
    ),
    "business_employees_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "business_employees_error_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load the people",
    ),
    "business_legal_name_input": MessageLookupByLibrary.simpleMessage(
      "Legal name",
    ),
    "business_list_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Create your first business to start managing it here.",
    ),
    "business_list_empty_title": MessageLookupByLibrary.simpleMessage(
      "No businesses yet",
    ),
    "business_list_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "business_list_error_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load your businesses",
    ),
    "business_list_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "business_list_search_empty": MessageLookupByLibrary.simpleMessage(
      "No businesses match your search",
    ),
    "business_location_address": MessageLookupByLibrary.simpleMessage(
      "Street address",
    ),
    "business_location_address_hint": MessageLookupByLibrary.simpleMessage(
      "Av. Francisco de Miranda, Torre Sol, floor 3",
    ),
    "business_location_city": MessageLookupByLibrary.simpleMessage("City"),
    "business_location_city_hint": MessageLookupByLibrary.simpleMessage(
      "Caracas",
    ),
    "business_location_country": MessageLookupByLibrary.simpleMessage(
      "Country",
    ),
    "business_location_country_note": MessageLookupByLibrary.simpleMessage(
      "Where the business is registered. It also sets its clock, the payment methods it\'s offered and the carriers it can deliver with.",
    ),
    "business_location_landmark": MessageLookupByLibrary.simpleMessage(
      "Landmark",
    ),
    "business_location_landmark_hint": MessageLookupByLibrary.simpleMessage(
      "Across from Altamira square",
    ),
    "business_location_postal_code": MessageLookupByLibrary.simpleMessage(
      "Postal code",
    ),
    "business_location_postal_code_hint": MessageLookupByLibrary.simpleMessage(
      "1060",
    ),
    "business_location_region": MessageLookupByLibrary.simpleMessage(
      "State or region",
    ),
    "business_location_region_hint": MessageLookupByLibrary.simpleMessage(
      "Miranda",
    ),
    "business_location_search_empty": MessageLookupByLibrary.simpleMessage(
      "No place matches that search. Write the address in the form.",
    ),
    "business_location_search_failed": MessageLookupByLibrary.simpleMessage(
      "The address search isn\'t answering right now. Write the address in the form.",
    ),
    "business_location_search_hint": MessageLookupByLibrary.simpleMessage(
      "Street, building or the name of your business",
    ),
    "business_logo_add": MessageLookupByLibrary.simpleMessage("Add logo"),
    "business_logo_change": MessageLookupByLibrary.simpleMessage("Change logo"),
    "business_logo_files": MessageLookupByLibrary.simpleMessage("Images"),
    "business_logo_large": MessageLookupByLibrary.simpleMessage(
      "That image is over 10 MB. Pick a lighter one.",
    ),
    "business_logo_saved": MessageLookupByLibrary.simpleMessage("Logo updated"),
    "business_notice_documents": MessageLookupByLibrary.simpleMessage(
      "Legal documents may be requested at any time. Failing to provide them can restrict the business, the profile that created it and everyone who administers it.",
    ),
    "business_notice_real": MessageLookupByLibrary.simpleMessage(
      "The legal name and the type of activity must match the real business. Businesses whose activity looks suspicious can be restricted.",
    ),
    "business_notice_title": MessageLookupByLibrary.simpleMessage(
      "Before you continue",
    ),
    "business_notice_unverified": MessageLookupByLibrary.simpleMessage(
      "Unverified businesses have significant limitations until their information is confirmed.",
    ),
    "business_profile_active": MessageLookupByLibrary.simpleMessage(
      "Go to your business",
    ),
    "business_profile_activity": MessageLookupByLibrary.simpleMessage(
      "Activity",
    ),
    "business_profile_activity_note": MessageLookupByLibrary.simpleMessage(
      "What this business sells or does. It\'s what places it in searches and reports.",
    ),
    "business_profile_add": m21,
    "business_profile_caption": MessageLookupByLibrary.simpleMessage("Tagline"),
    "business_profile_caption_note": MessageLookupByLibrary.simpleMessage(
      "One line about what this business does. It reads under its name, so it\'s what someone who doesn\'t know it yet reads first.",
    ),
    "business_profile_created": MessageLookupByLibrary.simpleMessage(
      "Registered on",
    ),
    "business_profile_edit": m22,
    "business_profile_empty": MessageLookupByLibrary.simpleMessage("Not set"),
    "business_profile_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "business_profile_error_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load this business",
    ),
    "business_profile_id": MessageLookupByLibrary.simpleMessage("Identifier"),
    "business_profile_id_copied": MessageLookupByLibrary.simpleMessage(
      "Identifier copied",
    ),
    "business_profile_id_copy": MessageLookupByLibrary.simpleMessage(
      "Copy identifier",
    ),
    "business_profile_id_hide": MessageLookupByLibrary.simpleMessage(
      "Hide identifier",
    ),
    "business_profile_id_note": MessageLookupByLibrary.simpleMessage(
      "How this business is named outside the app: paste it when you write to support or wire an integration.",
    ),
    "business_profile_id_show": MessageLookupByLibrary.simpleMessage(
      "Show identifier",
    ),
    "business_profile_incorporation": MessageLookupByLibrary.simpleMessage(
      "Incorporated on",
    ),
    "business_profile_incorporation_day": MessageLookupByLibrary.simpleMessage(
      "Day",
    ),
    "business_profile_incorporation_month":
        MessageLookupByLibrary.simpleMessage("Month"),
    "business_profile_incorporation_year": MessageLookupByLibrary.simpleMessage(
      "Year",
    ),
    "business_profile_language": MessageLookupByLibrary.simpleMessage(
      "Language",
    ),
    "business_profile_language_note": MessageLookupByLibrary.simpleMessage(
      "The language this business writes in: the one used in what it sends to its customers.",
    ),
    "business_profile_legal_name": MessageLookupByLibrary.simpleMessage(
      "Legal name",
    ),
    "business_profile_legal_name_note": MessageLookupByLibrary.simpleMessage(
      "The name this business is registered under. It\'s the one that goes on invoices, contracts and anything legal.",
    ),
    "business_profile_name": MessageLookupByLibrary.simpleMessage("Name"),
    "business_profile_name_note": MessageLookupByLibrary.simpleMessage(
      "What this business is called day to day: the name in your list, in the selector and on every screen of the app.",
    ),
    "business_profile_nickname": MessageLookupByLibrary.simpleMessage("Handle"),
    "business_profile_nickname_note": MessageLookupByLibrary.simpleMessage(
      "The short public handle this business is found and linked by. No spaces, no accents.",
    ),
    "business_profile_not_found_subtitle": MessageLookupByLibrary.simpleMessage(
      "This business is no longer in your list.",
    ),
    "business_profile_not_found_title": MessageLookupByLibrary.simpleMessage(
      "Business not found",
    ),
    "business_profile_owner": MessageLookupByLibrary.simpleMessage("Owner"),
    "business_profile_phone": MessageLookupByLibrary.simpleMessage("Phone"),
    "business_profile_phone_code": MessageLookupByLibrary.simpleMessage("Code"),
    "business_profile_phone_hint": MessageLookupByLibrary.simpleMessage(
      "Digits, with the country code (+584121234567)",
    ),
    "business_profile_phone_note": MessageLookupByLibrary.simpleMessage(
      "The number a customer calls when they\'d rather talk to someone than write.",
    ),
    "business_profile_phone_number": MessageLookupByLibrary.simpleMessage(
      "Number",
    ),
    "business_profile_saved": MessageLookupByLibrary.simpleMessage(
      "Business updated",
    ),
    "business_profile_section_account": MessageLookupByLibrary.simpleMessage(
      "Account",
    ),
    "business_profile_section_contact": MessageLookupByLibrary.simpleMessage(
      "Contact",
    ),
    "business_profile_section_emails": MessageLookupByLibrary.simpleMessage(
      "Email addresses",
    ),
    "business_profile_section_identity": MessageLookupByLibrary.simpleMessage(
      "Identity",
    ),
    "business_profile_section_operation": MessageLookupByLibrary.simpleMessage(
      "Operation",
    ),
    "business_profile_select": MessageLookupByLibrary.simpleMessage(
      "Select an option",
    ),
    "business_profile_select_empty": MessageLookupByLibrary.simpleMessage(
      "No option matches your search",
    ),
    "business_profile_tax_id": MessageLookupByLibrary.simpleMessage("Tax ID"),
    "business_profile_tax_id_note": MessageLookupByLibrary.simpleMessage(
      "The number the tax authority identifies this business by, printed on every invoice it issues.",
    ),
    "business_profile_verified_date": MessageLookupByLibrary.simpleMessage(
      "Verified on",
    ),
    "business_profile_verified_date_note": MessageLookupByLibrary.simpleMessage(
      "The day the platform checked these details. It\'s granted by verification, so it can\'t be edited here.",
    ),
    "business_profile_website": MessageLookupByLibrary.simpleMessage("Website"),
    "business_profile_website_failed": MessageLookupByLibrary.simpleMessage(
      "That address couldn\'t be opened. Check that it\'s written correctly.",
    ),
    "business_profile_website_hint": MessageLookupByLibrary.simpleMessage(
      "ryzer.com",
    ),
    "business_profile_website_note": MessageLookupByLibrary.simpleMessage(
      "Where a customer finds the business on its own: its site, its store or its page.",
    ),
    "business_profile_website_open": MessageLookupByLibrary.simpleMessage(
      "Open website",
    ),
    "business_rank_administrator": MessageLookupByLibrary.simpleMessage(
      "Administrator",
    ),
    "business_rank_advertiser": MessageLookupByLibrary.simpleMessage(
      "Advertiser",
    ),
    "business_rank_manager": MessageLookupByLibrary.simpleMessage("Manager"),
    "business_rank_seller": MessageLookupByLibrary.simpleMessage("Seller"),
    "business_rank_unknown": MessageLookupByLibrary.simpleMessage("Member"),
    "business_state_closed": MessageLookupByLibrary.simpleMessage("Closed"),
    "business_state_inquiries": MessageLookupByLibrary.simpleMessage(
      "Inquiries only",
    ),
    "business_state_open": MessageLookupByLibrary.simpleMessage("Open"),
    "business_state_orders": MessageLookupByLibrary.simpleMessage(
      "Online orders only",
    ),
    "business_state_unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "business_statistics_soon": MessageLookupByLibrary.simpleMessage(
      "How this business is doing —sales, activity and growth— will be shown here.",
    ),
    "business_status_active": MessageLookupByLibrary.simpleMessage("Active"),
    "business_status_pending": MessageLookupByLibrary.simpleMessage("Pending"),
    "business_status_restricted": MessageLookupByLibrary.simpleMessage(
      "Restricted",
    ),
    "business_status_unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "business_tab_branches": MessageLookupByLibrary.simpleMessage("Branches"),
    "business_tab_clients": MessageLookupByLibrary.simpleMessage("Clients"),
    "business_tab_employees": MessageLookupByLibrary.simpleMessage("Employees"),
    "business_tab_settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "business_tab_statistics": MessageLookupByLibrary.simpleMessage(
      "Statistics",
    ),
    "business_type_agriculture": MessageLookupByLibrary.simpleMessage(
      "Agriculture and livestock",
    ),
    "business_type_automotive": MessageLookupByLibrary.simpleMessage(
      "Automotive",
    ),
    "business_type_beauty": MessageLookupByLibrary.simpleMessage(
      "Beauty and personal care",
    ),
    "business_type_construction": MessageLookupByLibrary.simpleMessage(
      "Construction",
    ),
    "business_type_education": MessageLookupByLibrary.simpleMessage(
      "Education",
    ),
    "business_type_empty": MessageLookupByLibrary.simpleMessage(
      "No activity matches your search",
    ),
    "business_type_entertainment": MessageLookupByLibrary.simpleMessage(
      "Entertainment",
    ),
    "business_type_finance": MessageLookupByLibrary.simpleMessage("Finance"),
    "business_type_food": MessageLookupByLibrary.simpleMessage(
      "Food and beverage",
    ),
    "business_type_health": MessageLookupByLibrary.simpleMessage(
      "Health and wellness",
    ),
    "business_type_hospitality": MessageLookupByLibrary.simpleMessage(
      "Hospitality and tourism",
    ),
    "business_type_input": MessageLookupByLibrary.simpleMessage(
      "Type of activity",
    ),
    "business_type_legal": MessageLookupByLibrary.simpleMessage("Legal"),
    "business_type_manufacturing": MessageLookupByLibrary.simpleMessage(
      "Manufacturing",
    ),
    "business_type_nonprofit": MessageLookupByLibrary.simpleMessage(
      "Nonprofit",
    ),
    "business_type_other": MessageLookupByLibrary.simpleMessage("Other"),
    "business_type_placeholder": MessageLookupByLibrary.simpleMessage(
      "Select the main activity",
    ),
    "business_type_real_estate": MessageLookupByLibrary.simpleMessage(
      "Real estate",
    ),
    "business_type_retail": MessageLookupByLibrary.simpleMessage("Retail"),
    "business_type_services": MessageLookupByLibrary.simpleMessage(
      "Professional services",
    ),
    "business_type_technology": MessageLookupByLibrary.simpleMessage(
      "Technology",
    ),
    "business_type_transport": MessageLookupByLibrary.simpleMessage(
      "Transport and logistics",
    ),
    "business_type_wholesale": MessageLookupByLibrary.simpleMessage(
      "Wholesale",
    ),
    "business_verification_pending": MessageLookupByLibrary.simpleMessage(
      "Under review",
    ),
    "business_verification_rejected": MessageLookupByLibrary.simpleMessage(
      "Rejected",
    ),
    "business_verification_trusted": MessageLookupByLibrary.simpleMessage(
      "Trusted",
    ),
    "business_verification_untrusted": MessageLookupByLibrary.simpleMessage(
      "Not verified",
    ),
    "business_verification_verified": MessageLookupByLibrary.simpleMessage(
      "Verified",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "channel_account_id": MessageLookupByLibrary.simpleMessage(
      "On the network",
    ),
    "channel_account_title": MessageLookupByLibrary.simpleMessage("Account"),
    "channel_capability_calls": MessageLookupByLibrary.simpleMessage("Calls"),
    "channel_capability_comments": MessageLookupByLibrary.simpleMessage(
      "Comments",
    ),
    "channel_capability_mentions": MessageLookupByLibrary.simpleMessage(
      "Mentions",
    ),
    "channel_capability_messages": MessageLookupByLibrary.simpleMessage(
      "Messages",
    ),
    "channel_capability_posts": MessageLookupByLibrary.simpleMessage("Posts"),
    "channel_catalog_error": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t load the available networks",
    ),
    "channel_changes_pending": MessageLookupByLibrary.simpleMessage(
      "You have unsaved changes on this channel",
    ),
    "channel_created": MessageLookupByLibrary.simpleMessage(
      "Channel connected",
    ),
    "channel_credentials_subtitle": m23,
    "channel_credentials_title": MessageLookupByLibrary.simpleMessage(
      "Credentials",
    ),
    "channel_danger_section": MessageLookupByLibrary.simpleMessage(
      "Undoing this channel",
    ),
    "channel_delete_explanation": MessageLookupByLibrary.simpleMessage(
      "Disconnecting deletes the credentials stored for this channel and takes it off the list. The account can be connected again, but you\'ll have to set it up from scratch.",
    ),
    "channel_delete_message": m24,
    "channel_delete_title": MessageLookupByLibrary.simpleMessage(
      "Disconnect this channel?",
    ),
    "channel_deleted": MessageLookupByLibrary.simpleMessage(
      "Channel disconnected",
    ),
    "channel_field_required": MessageLookupByLibrary.simpleMessage(
      "required to run",
    ),
    "channel_missing_title": MessageLookupByLibrary.simpleMessage(
      "This channel isn\'t running yet",
    ),
    "channel_open_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "It may have been disconnected, or it belongs to another business",
    ),
    "channel_open_error_title": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t open this channel",
    ),
    "channel_own_id": MessageLookupByLibrary.simpleMessage("Channel id"),
    "channel_pause": MessageLookupByLibrary.simpleMessage("Pause channel"),
    "channel_paused": MessageLookupByLibrary.simpleMessage("Channel paused"),
    "channel_payments_empty": MessageLookupByLibrary.simpleMessage(
      "This business has no payment accounts yet. Add one in Finance and come back",
    ),
    "channel_payments_error": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t load your payment accounts",
    ),
    "channel_payments_subtitle": MessageLookupByLibrary.simpleMessage(
      "Which of your accounts the agent may give a customer to pay into. It offers these and no others",
    ),
    "channel_payments_title": MessageLookupByLibrary.simpleMessage(
      "Payment methods",
    ),
    "channel_resume": MessageLookupByLibrary.simpleMessage("Resume channel"),
    "channel_resumed": MessageLookupByLibrary.simpleMessage("Channel resumed"),
    "channel_role_agent": MessageLookupByLibrary.simpleMessage("Agent"),
    "channel_role_agent_hint": MessageLookupByLibrary.simpleMessage(
      "Answers whatever comes, without pushing towards a sale",
    ),
    "channel_role_seller": MessageLookupByLibrary.simpleMessage("Seller"),
    "channel_role_seller_hint": MessageLookupByLibrary.simpleMessage(
      "Presents products, answers prices and stock, and closes the order",
    ),
    "channel_role_subtitle": MessageLookupByLibrary.simpleMessage(
      "What the agent does when it answers on this channel",
    ),
    "channel_role_support": MessageLookupByLibrary.simpleMessage("Support"),
    "channel_role_support_hint": MessageLookupByLibrary.simpleMessage(
      "Solves problems with something the customer already bought",
    ),
    "channel_role_title": MessageLookupByLibrary.simpleMessage("Agent role"),
    "channel_saved": MessageLookupByLibrary.simpleMessage("Channel updated"),
    "channel_secret_stored": MessageLookupByLibrary.simpleMessage(
      "Already set — write to replace it",
    ),
    "channel_source_calendar": MessageLookupByLibrary.simpleMessage(
      "Service calendar",
    ),
    "channel_source_calendar_hint": MessageLookupByLibrary.simpleMessage(
      "Books appointments on a calendar of services",
    ),
    "channel_source_knowledge": MessageLookupByLibrary.simpleMessage(
      "Knowledge base",
    ),
    "channel_source_knowledge_hint": MessageLookupByLibrary.simpleMessage(
      "Answers questions and spreads marketing from information you write",
    ),
    "channel_source_missing": MessageLookupByLibrary.simpleMessage(
      "Choose which product table the agent reads from",
    ),
    "channel_source_no_tables": MessageLookupByLibrary.simpleMessage(
      "This business has no product tables yet. Create one in Products and come back",
    ),
    "channel_source_none": MessageLookupByLibrary.simpleMessage(
      "No data source",
    ),
    "channel_source_soon": MessageLookupByLibrary.simpleMessage("Soon"),
    "channel_source_subtitle": MessageLookupByLibrary.simpleMessage(
      "Where the agent reads from. Without a source it answers from memory, which means it makes prices up",
    ),
    "channel_source_table": MessageLookupByLibrary.simpleMessage(
      "Product table",
    ),
    "channel_source_table_empty": MessageLookupByLibrary.simpleMessage(
      "No table matches your search",
    ),
    "channel_source_table_hint": MessageLookupByLibrary.simpleMessage(
      "Answers prices, stock and product details from one of your tables",
    ),
    "channel_source_table_placeholder": MessageLookupByLibrary.simpleMessage(
      "Choose a product table",
    ),
    "channel_source_table_select": MessageLookupByLibrary.simpleMessage(
      "Which table",
    ),
    "channel_source_title": MessageLookupByLibrary.simpleMessage("Data"),
    "channel_state_paused": MessageLookupByLibrary.simpleMessage("Paused"),
    "channel_state_pending": MessageLookupByLibrary.simpleMessage(
      "Needs setup",
    ),
    "channel_state_ready": MessageLookupByLibrary.simpleMessage("Connected"),
    "channel_tool_documents": MessageLookupByLibrary.simpleMessage("Documents"),
    "channel_tool_documents_hint": MessageLookupByLibrary.simpleMessage(
      "Reads attached files",
    ),
    "channel_tool_images": MessageLookupByLibrary.simpleMessage("Images"),
    "channel_tool_images_hint": MessageLookupByLibrary.simpleMessage(
      "Reads the pictures customers send, and generates its own",
    ),
    "channel_tool_video": MessageLookupByLibrary.simpleMessage("Video"),
    "channel_tool_video_hint": MessageLookupByLibrary.simpleMessage(
      "Watches videos customers send",
    ),
    "channel_tool_voice": MessageLookupByLibrary.simpleMessage("Voice"),
    "channel_tool_voice_hint": MessageLookupByLibrary.simpleMessage(
      "Transcribes voice notes and answers out loud",
    ),
    "channel_tools_cost": MessageLookupByLibrary.simpleMessage(
      "Each tool you turn on raises the processing cost of this channel, charged per conversation answered. Audio and video cost noticeably more than text.",
    ),
    "channel_tools_subtitle": MessageLookupByLibrary.simpleMessage(
      "What the agent can process and produce besides text",
    ),
    "channel_tools_title": MessageLookupByLibrary.simpleMessage("Tools"),
    "channel_type_locked": MessageLookupByLibrary.simpleMessage(
      "The network can\'t be changed: its stored credentials belong to it. To use another one, connect a new channel",
    ),
    "channel_type_missing": MessageLookupByLibrary.simpleMessage(
      "Choose the type of channel you want to connect",
    ),
    "channel_type_soon": MessageLookupByLibrary.simpleMessage("Soon"),
    "channel_type_subtitle": MessageLookupByLibrary.simpleMessage(
      "Which network this channel connects to. It decides which credentials you\'ll need below",
    ),
    "channel_type_title": MessageLookupByLibrary.simpleMessage("Channel type"),
    "channel_type_whatsapp_personal": MessageLookupByLibrary.simpleMessage(
      "WhatsApp Personal",
    ),
    "channel_type_whatsapp_personal_hint": MessageLookupByLibrary.simpleMessage(
      "A personal number, without a Meta business account",
    ),
    "channel_whatsapp_personal_notice_subtitle":
        MessageLookupByLibrary.simpleMessage(
          "There are no tokens to paste. Once this channel is created, turn it on from the channels list to scan a QR code and link your WhatsApp",
        ),
    "channel_whatsapp_personal_notice_title":
        MessageLookupByLibrary.simpleMessage("Link your number"),
    "channels": MessageLookupByLibrary.simpleMessage("Channels"),
    "channels_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Connect a WhatsApp number, a Facebook page or an Instagram account and let an agent answer for you",
    ),
    "channels_empty_title": MessageLookupByLibrary.simpleMessage(
      "No channels connected yet",
    ),
    "channels_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Check your connection and try again",
    ),
    "channels_error_title": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t load your channels",
    ),
    "channels_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "code_input": MessageLookupByLibrary.simpleMessage("Code"),
    "collapse": MessageLookupByLibrary.simpleMessage("Collapse"),
    "coming_soon": MessageLookupByLibrary.simpleMessage("Coming soon"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirm_password_input": MessageLookupByLibrary.simpleMessage(
      "Confirm password",
    ),
    "connectionError": MessageLookupByLibrary.simpleMessage(
      "Sorry, there was a connection error, please try again later",
    ),
    "connection_bot_count": m25,
    "connection_catalog_error": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t load the available services",
    ),
    "connection_created": MessageLookupByLibrary.simpleMessage(
      "Account connected",
    ),
    "connection_credentials_subtitle": m26,
    "connection_credentials_title": MessageLookupByLibrary.simpleMessage(
      "Credentials",
    ),
    "connection_delete_bots": m27,
    "connection_delete_message": m28,
    "connection_delete_title": MessageLookupByLibrary.simpleMessage(
      "Disconnect this account?",
    ),
    "connection_deleted": MessageLookupByLibrary.simpleMessage(
      "Account disconnected",
    ),
    "connection_description_input": MessageLookupByLibrary.simpleMessage(
      "Description",
    ),
    "connection_description_placeholder": MessageLookupByLibrary.simpleMessage(
      "Optional description...",
    ),
    "connection_field_required": MessageLookupByLibrary.simpleMessage(
      "required to run",
    ),
    "connection_identity_subtitle": MessageLookupByLibrary.simpleMessage(
      "How you\'ll recognize this account in your list",
    ),
    "connection_identity_title": MessageLookupByLibrary.simpleMessage(
      "Account",
    ),
    "connection_missing_title": MessageLookupByLibrary.simpleMessage(
      "This account isn\'t ready yet",
    ),
    "connection_name_input": MessageLookupByLibrary.simpleMessage("Name"),
    "connection_name_placeholder": MessageLookupByLibrary.simpleMessage(
      "Main account, Sales...",
    ),
    "connection_open_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "It may have been disconnected, or it belongs to another business",
    ),
    "connection_open_error_title": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t open this connection",
    ),
    "connection_options": MessageLookupByLibrary.simpleMessage(
      "Connection options",
    ),
    "connection_pause": MessageLookupByLibrary.simpleMessage("Pause account"),
    "connection_paused": MessageLookupByLibrary.simpleMessage("Account paused"),
    "connection_provider_locked": MessageLookupByLibrary.simpleMessage(
      "The service can\'t be changed: the stored credentials belong to it. To use another one, connect a new account",
    ),
    "connection_provider_missing": MessageLookupByLibrary.simpleMessage(
      "Choose which service you want to connect",
    ),
    "connection_provider_soon": MessageLookupByLibrary.simpleMessage("Soon"),
    "connection_provider_subtitle": MessageLookupByLibrary.simpleMessage(
      "Which service this account belongs to. It decides which credentials you\'ll need below",
    ),
    "connection_provider_title": MessageLookupByLibrary.simpleMessage(
      "Service",
    ),
    "connection_resume": MessageLookupByLibrary.simpleMessage("Resume account"),
    "connection_resumed": MessageLookupByLibrary.simpleMessage(
      "Account resumed",
    ),
    "connection_saved": MessageLookupByLibrary.simpleMessage(
      "Connection updated",
    ),
    "connection_scope_ad_comments": MessageLookupByLibrary.simpleMessage(
      "Comments on ads",
    ),
    "connection_scope_calls": MessageLookupByLibrary.simpleMessage("Calls"),
    "connection_scope_comments": MessageLookupByLibrary.simpleMessage(
      "Comments on posts",
    ),
    "connection_scope_mentions": MessageLookupByLibrary.simpleMessage(
      "Mentions and tags",
    ),
    "connection_scope_messages": MessageLookupByLibrary.simpleMessage(
      "Direct messages",
    ),
    "connection_scope_posts": MessageLookupByLibrary.simpleMessage("Posts"),
    "connection_secret_stored": MessageLookupByLibrary.simpleMessage(
      "Already set — write to replace it",
    ),
    "connection_state_paused": MessageLookupByLibrary.simpleMessage("Paused"),
    "connection_state_pending": MessageLookupByLibrary.simpleMessage(
      "Needs setup",
    ),
    "connection_state_ready": MessageLookupByLibrary.simpleMessage("Connected"),
    "connections": MessageLookupByLibrary.simpleMessage("Connections"),
    "connections_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Connect a WhatsApp number, a Facebook page or an Instagram account. Once connected, you can put bots to work on it",
    ),
    "connections_empty_title": MessageLookupByLibrary.simpleMessage(
      "No accounts connected yet",
    ),
    "connections_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Check your connection and try again",
    ),
    "connections_error_title": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t load your connections",
    ),
    "connections_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "connections_search_empty": MessageLookupByLibrary.simpleMessage(
      "No connection matches your search",
    ),
    "create_business": MessageLookupByLibrary.simpleMessage("Create business"),
    "create_business_subtitle": MessageLookupByLibrary.simpleMessage(
      "Tell us about the business you want to manage",
    ),
    "create_channel": MessageLookupByLibrary.simpleMessage("Connect channel"),
    "create_connection": MessageLookupByLibrary.simpleMessage(
      "Connect account",
    ),
    "create_table": MessageLookupByLibrary.simpleMessage("Create table"),
    "create_table_subtitle": MessageLookupByLibrary.simpleMessage(
      "Define the table where your products will live",
    ),
    "currency": MessageLookupByLibrary.simpleMessage("Currency"),
    "currency_eur": MessageLookupByLibrary.simpleMessage("EUR"),
    "currency_local": MessageLookupByLibrary.simpleMessage("Local"),
    "currency_usd": MessageLookupByLibrary.simpleMessage("USD"),
    "custom": MessageLookupByLibrary.simpleMessage("Custom"),
    "custom_days": MessageLookupByLibrary.simpleMessage("Days"),
    "delete_business_email": MessageLookupByLibrary.simpleMessage(
      "Delete address",
    ),
    "delete_channel": MessageLookupByLibrary.simpleMessage(
      "Disconnect channel",
    ),
    "delete_connection": MessageLookupByLibrary.simpleMessage("Disconnect"),
    "delete_table": MessageLookupByLibrary.simpleMessage("Delete table"),
    "deliveries": MessageLookupByLibrary.simpleMessage("Deliveries"),
    "deliveries_area": MessageLookupByLibrary.simpleMessage(
      "Select delivery area",
    ),
    "deliveries_area_add": MessageLookupByLibrary.simpleMessage("Add area"),
    "deliveries_area_clear": MessageLookupByLibrary.simpleMessage("Clear"),
    "deliveries_area_default_name": m29,
    "deliveries_area_draw_note": MessageLookupByLibrary.simpleMessage(
      "Tap the map to add points. Drag a point to move it, tap the ring in the middle of a side to add one there, or tap a point and remove it.",
    ),
    "deliveries_area_drawn": MessageLookupByLibrary.simpleMessage(
      "Drawn on the map",
    ),
    "deliveries_area_edit": MessageLookupByLibrary.simpleMessage("Edit area"),
    "deliveries_area_edit_title": MessageLookupByLibrary.simpleMessage(
      "Edit area",
    ),
    "deliveries_area_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Add one from the top: a radius around your business, a shape drawn on the map, or how far a courier gets in some minutes.",
    ),
    "deliveries_area_empty_title": MessageLookupByLibrary.simpleMessage(
      "No areas yet",
    ),
    "deliveries_area_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "deliveries_area_error_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load your delivery areas",
    ),
    "deliveries_area_fee": MessageLookupByLibrary.simpleMessage(
      "Delivery price here",
    ),
    "deliveries_area_fee_hint": m30,
    "deliveries_area_fee_option": MessageLookupByLibrary.simpleMessage(
      "Price of the delivery option",
    ),
    "deliveries_area_focus": MessageLookupByLibrary.simpleMessage(
      "Show on the map",
    ),
    "deliveries_area_km": m31,
    "deliveries_area_limit": m32,
    "deliveries_area_method_draw": MessageLookupByLibrary.simpleMessage(
      "Draw on the map",
    ),
    "deliveries_area_method_draw_note": MessageLookupByLibrary.simpleMessage(
      "Any shape: a whole city, or only some neighbourhoods",
    ),
    "deliveries_area_method_radius": MessageLookupByLibrary.simpleMessage(
      "Radius around your business",
    ),
    "deliveries_area_method_radius_note": MessageLookupByLibrary.simpleMessage(
      "Everything within some kilometres of your location",
    ),
    "deliveries_area_method_travel": MessageLookupByLibrary.simpleMessage(
      "By travel time",
    ),
    "deliveries_area_method_travel_note": MessageLookupByLibrary.simpleMessage(
      "As far as a courier gets in some minutes, then adjust it",
    ),
    "deliveries_area_minimum": MessageLookupByLibrary.simpleMessage(
      "Minimum order",
    ),
    "deliveries_area_minimum_hint": MessageLookupByLibrary.simpleMessage(
      "Order total below which you don\'t deliver here",
    ),
    "deliveries_area_minimum_tag": m33,
    "deliveries_area_mode_bicycle": MessageLookupByLibrary.simpleMessage(
      "Bicycle",
    ),
    "deliveries_area_mode_car": MessageLookupByLibrary.simpleMessage("Car"),
    "deliveries_area_mode_foot": MessageLookupByLibrary.simpleMessage(
      "On foot",
    ),
    "deliveries_area_mode_motorcycle": MessageLookupByLibrary.simpleMessage(
      "Motorcycle",
    ),
    "deliveries_area_name": MessageLookupByLibrary.simpleMessage("Name"),
    "deliveries_area_name_hint": MessageLookupByLibrary.simpleMessage(
      "All of Caracas",
    ),
    "deliveries_area_new_title": MessageLookupByLibrary.simpleMessage(
      "New area",
    ),
    "deliveries_area_not_ready": MessageLookupByLibrary.simpleMessage(
      "Wait for your areas to load before adding one.",
    ),
    "deliveries_area_pause": MessageLookupByLibrary.simpleMessage("Pause area"),
    "deliveries_area_paused": MessageLookupByLibrary.simpleMessage("Paused"),
    "deliveries_area_points": m34,
    "deliveries_area_probe_clear": MessageLookupByLibrary.simpleMessage(
      "Clear the point",
    ),
    "deliveries_area_probe_hint": MessageLookupByLibrary.simpleMessage(
      "Tap the map to check whether a point is inside your areas.",
    ),
    "deliveries_area_probe_in": MessageLookupByLibrary.simpleMessage(
      "Inside your areas",
    ),
    "deliveries_area_probe_out": MessageLookupByLibrary.simpleMessage(
      "Outside your areas",
    ),
    "deliveries_area_probe_out_note": MessageLookupByLibrary.simpleMessage(
      "No active area reaches this point.",
    ),
    "deliveries_area_probe_overlap": MessageLookupByLibrary.simpleMessage(
      "Several areas reach it. The cheapest is listed first, which is the one a customer pays.",
    ),
    "deliveries_area_radius_note": MessageLookupByLibrary.simpleMessage(
      "Tap the map or drag the center to move it, and type the kilometres or pick them.",
    ),
    "deliveries_area_remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "deliveries_area_remove_message": m35,
    "deliveries_area_remove_point": MessageLookupByLibrary.simpleMessage(
      "Remove point",
    ),
    "deliveries_area_remove_title": MessageLookupByLibrary.simpleMessage(
      "Remove this area?",
    ),
    "deliveries_area_resume": MessageLookupByLibrary.simpleMessage(
      "Resume area",
    ),
    "deliveries_area_shape_missing": MessageLookupByLibrary.simpleMessage(
      "Put at least 3 points on the map.",
    ),
    "deliveries_area_size": m36,
    "deliveries_area_title": MessageLookupByLibrary.simpleMessage(
      "Delivery area",
    ),
    "deliveries_area_travel": MessageLookupByLibrary.simpleMessage(
      "Travel time",
    ),
    "deliveries_area_travel_again": MessageLookupByLibrary.simpleMessage(
      "Calculate again",
    ),
    "deliveries_area_travel_compute": MessageLookupByLibrary.simpleMessage(
      "Calculate area",
    ),
    "deliveries_area_travel_failed": MessageLookupByLibrary.simpleMessage(
      "The area couldn\'t be calculated: the route service may be down, or no road leaves that point. You can still draw it by hand.",
    ),
    "deliveries_area_travel_invalid": MessageLookupByLibrary.simpleMessage(
      "Write the minutes, from 1 to 120.",
    ),
    "deliveries_area_travel_minutes": MessageLookupByLibrary.simpleMessage(
      "Minutes",
    ),
    "deliveries_area_travel_mode": MessageLookupByLibrary.simpleMessage("How"),
    "deliveries_area_travel_note": MessageLookupByLibrary.simpleMessage(
      "Tap the map or drag the center to choose where the courier leaves from, then pick how they travel and for how many minutes.",
    ),
    "deliveries_area_undo": MessageLookupByLibrary.simpleMessage("Undo"),
    "deliveries_center": MessageLookupByLibrary.simpleMessage("Center"),
    "deliveries_create": MessageLookupByLibrary.simpleMessage("New delivery"),
    "deliveries_map_attribution": MessageLookupByLibrary.simpleMessage(
      "© OpenStreetMap contributors",
    ),
    "deliveries_map_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Check your connection and try again.",
    ),
    "deliveries_map_error_title": MessageLookupByLibrary.simpleMessage(
      "The map did not load",
    ),
    "deliveries_map_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "deliveries_map_soon": MessageLookupByLibrary.simpleMessage(
      "Here you will see your deliveries on the map.",
    ),
    "deliveries_map_zoom_in": MessageLookupByLibrary.simpleMessage("Zoom in"),
    "deliveries_map_zoom_out": MessageLookupByLibrary.simpleMessage("Zoom out"),
    "deliveries_pending_soon": MessageLookupByLibrary.simpleMessage(
      "Here you will see every order still on its way to the customer.",
    ),
    "deliveries_refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "deliveries_settings": MessageLookupByLibrary.simpleMessage("Settings"),
    "deliveries_settings_title": MessageLookupByLibrary.simpleMessage(
      "Delivery settings",
    ),
    "description": MessageLookupByLibrary.simpleMessage("Description"),
    "edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "edit_about_title": MessageLookupByLibrary.simpleMessage(
      "Title and description",
    ),
    "edit_billing_title": MessageLookupByLibrary.simpleMessage(
      "Billing period",
    ),
    "edit_channel": MessageLookupByLibrary.simpleMessage("Configure channel"),
    "edit_currency_title": MessageLookupByLibrary.simpleMessage(
      "Edit currency",
    ),
    "edit_price_title": MessageLookupByLibrary.simpleMessage("Edit price"),
    "email_input": MessageLookupByLibrary.simpleMessage("Email"),
    "employee_action_activity": MessageLookupByLibrary.simpleMessage(
      "Activity",
    ),
    "employee_action_activity_description":
        MessageLookupByLibrary.simpleMessage(
          "What this person did lately, newest first.",
        ),
    "employee_action_permissions": MessageLookupByLibrary.simpleMessage(
      "Permissions",
    ),
    "employee_action_permissions_description":
        MessageLookupByLibrary.simpleMessage(
          "What this person can see and do in the business.",
        ),
    "employee_action_sales": MessageLookupByLibrary.simpleMessage("Sales"),
    "employee_action_sales_description": MessageLookupByLibrary.simpleMessage(
      "The sales this person handled and how they went.",
    ),
    "employee_action_settings": MessageLookupByLibrary.simpleMessage(
      "Settings",
    ),
    "employee_action_settings_description":
        MessageLookupByLibrary.simpleMessage(
          "How this person works here: schedule, notices and preferences.",
        ),
    "employee_action_soon_title": MessageLookupByLibrary.simpleMessage(
      "Coming soon",
    ),
    "employee_contract_expired": MessageLookupByLibrary.simpleMessage(
      "Contract expired",
    ),
    "employee_contract_expiring": MessageLookupByLibrary.simpleMessage(
      "Contract ending soon",
    ),
    "employee_contract_fixed_term": MessageLookupByLibrary.simpleMessage(
      "Fixed term",
    ),
    "employee_contract_freelance": MessageLookupByLibrary.simpleMessage(
      "Freelance",
    ),
    "employee_contract_internship": MessageLookupByLibrary.simpleMessage(
      "Internship",
    ),
    "employee_contract_permanent": MessageLookupByLibrary.simpleMessage(
      "Permanent",
    ),
    "employee_contract_probation": MessageLookupByLibrary.simpleMessage(
      "Probation",
    ),
    "employee_contract_temporary": MessageLookupByLibrary.simpleMessage(
      "Temporary",
    ),
    "employee_copied": m37,
    "employee_copy": MessageLookupByLibrary.simpleMessage("Click to copy"),
    "employee_days": m38,
    "employee_detail_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "employee_detail_error_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load this person",
    ),
    "employee_document_foreign_id": MessageLookupByLibrary.simpleMessage(
      "Foreigner ID",
    ),
    "employee_document_national_id": MessageLookupByLibrary.simpleMessage(
      "National ID",
    ),
    "employee_document_passport": MessageLookupByLibrary.simpleMessage(
      "Passport",
    ),
    "employee_document_tax_id": MessageLookupByLibrary.simpleMessage("Tax ID"),
    "employee_edit_address_hint": MessageLookupByLibrary.simpleMessage(
      "Search the address or type it",
    ),
    "employee_edit_birthday_future": MessageLookupByLibrary.simpleMessage(
      "A birthday can\'t be today or later",
    ),
    "employee_edit_birthday_young": m39,
    "employee_edit_confirm": MessageLookupByLibrary.simpleMessage("Save"),
    "employee_edit_create": MessageLookupByLibrary.simpleMessage(
      "Add a new one",
    ),
    "employee_edit_create_hint": m40,
    "employee_edit_day": MessageLookupByLibrary.simpleMessage("Day"),
    "employee_edit_end_before_start": MessageLookupByLibrary.simpleMessage(
      "The contract can\'t end before it starts",
    ),
    "employee_edit_hint": m41,
    "employee_edit_invalid_amount": MessageLookupByLibrary.simpleMessage(
      "Write an amount, like 1200.50",
    ),
    "employee_edit_invalid_day": MessageLookupByLibrary.simpleMessage(
      "That date doesn\'t exist: check the day, month and year",
    ),
    "employee_edit_invalid_email": MessageLookupByLibrary.simpleMessage(
      "That isn\'t an email, like name@company.com",
    ),
    "employee_edit_invalid_name": m42,
    "employee_edit_month": MessageLookupByLibrary.simpleMessage("Month"),
    "employee_edit_no_match": MessageLookupByLibrary.simpleMessage(
      "No matches",
    ),
    "employee_edit_phone_code": MessageLookupByLibrary.simpleMessage("Code"),
    "employee_edit_phone_digits": m43,
    "employee_edit_phone_digits_range": m44,
    "employee_edit_phone_no_code": MessageLookupByLibrary.simpleMessage(
      "Choose the country code first",
    ),
    "employee_edit_phone_number": MessageLookupByLibrary.simpleMessage(
      "Number",
    ),
    "employee_edit_place_failed": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t read that place. Type the address instead.",
    ),
    "employee_edit_required": m45,
    "employee_edit_start_after_end": MessageLookupByLibrary.simpleMessage(
      "The job can\'t start after the contract ends",
    ),
    "employee_edit_year": MessageLookupByLibrary.simpleMessage("Year"),
    "employee_emergency_title": MessageLookupByLibrary.simpleMessage(
      "Emergency contact",
    ),
    "employee_end_contract_end": MessageLookupByLibrary.simpleMessage(
      "End of contract",
    ),
    "employee_end_dismissal": MessageLookupByLibrary.simpleMessage("Dismissal"),
    "employee_end_mutual": MessageLookupByLibrary.simpleMessage(
      "Mutual agreement",
    ),
    "employee_end_other": MessageLookupByLibrary.simpleMessage("Other"),
    "employee_end_resignation": MessageLookupByLibrary.simpleMessage(
      "Resignation",
    ),
    "employee_ending_title": MessageLookupByLibrary.simpleMessage(
      "How it ended",
    ),
    "employee_field_about": MessageLookupByLibrary.simpleMessage("About"),
    "employee_field_address": MessageLookupByLibrary.simpleMessage("Address"),
    "employee_field_birthday": MessageLookupByLibrary.simpleMessage("Birthday"),
    "employee_field_branch": MessageLookupByLibrary.simpleMessage("Branch"),
    "employee_field_city": MessageLookupByLibrary.simpleMessage("City"),
    "employee_field_code": MessageLookupByLibrary.simpleMessage(
      "Employee code",
    ),
    "employee_field_contract": MessageLookupByLibrary.simpleMessage("Contract"),
    "employee_field_contract_end": MessageLookupByLibrary.simpleMessage(
      "Contract ends",
    ),
    "employee_field_country": MessageLookupByLibrary.simpleMessage("Country"),
    "employee_field_currency": MessageLookupByLibrary.simpleMessage(
      "Salary currency",
    ),
    "employee_field_department": MessageLookupByLibrary.simpleMessage(
      "Department",
    ),
    "employee_field_document": MessageLookupByLibrary.simpleMessage(
      "Identity document",
    ),
    "employee_field_document_number": MessageLookupByLibrary.simpleMessage(
      "Document number",
    ),
    "employee_field_document_type": MessageLookupByLibrary.simpleMessage(
      "Document type",
    ),
    "employee_field_email": MessageLookupByLibrary.simpleMessage("Email"),
    "employee_field_emergency_name": MessageLookupByLibrary.simpleMessage(
      "Name",
    ),
    "employee_field_emergency_relation": MessageLookupByLibrary.simpleMessage(
      "Relation",
    ),
    "employee_field_end_reason": MessageLookupByLibrary.simpleMessage("Reason"),
    "employee_field_ended": MessageLookupByLibrary.simpleMessage("Last day"),
    "employee_field_first_name": MessageLookupByLibrary.simpleMessage(
      "First name",
    ),
    "employee_field_invited": MessageLookupByLibrary.simpleMessage("Filed"),
    "employee_field_job_title": MessageLookupByLibrary.simpleMessage(
      "Job title",
    ),
    "employee_field_last_name": MessageLookupByLibrary.simpleMessage(
      "Last name",
    ),
    "employee_field_manager": MessageLookupByLibrary.simpleMessage(
      "Reports to",
    ),
    "employee_field_nationality": MessageLookupByLibrary.simpleMessage(
      "Nationality",
    ),
    "employee_field_note": MessageLookupByLibrary.simpleMessage("Note"),
    "employee_field_pay_period": MessageLookupByLibrary.simpleMessage(
      "Paid per",
    ),
    "employee_field_phone": MessageLookupByLibrary.simpleMessage("Phone"),
    "employee_field_postal_code": MessageLookupByLibrary.simpleMessage(
      "Postal code",
    ),
    "employee_field_region": MessageLookupByLibrary.simpleMessage(
      "State or region",
    ),
    "employee_field_responded": MessageLookupByLibrary.simpleMessage(
      "Answered",
    ),
    "employee_field_salary": MessageLookupByLibrary.simpleMessage("Salary"),
    "employee_field_sex": MessageLookupByLibrary.simpleMessage("Sex"),
    "employee_field_start": MessageLookupByLibrary.simpleMessage("Start date"),
    "employee_field_workday": MessageLookupByLibrary.simpleMessage("Workday"),
    "employee_job_title": MessageLookupByLibrary.simpleMessage("Job"),
    "employee_leave_days": m46,
    "employee_leave_maternity": MessageLookupByLibrary.simpleMessage(
      "Maternity leave",
    ),
    "employee_leave_now_title": MessageLookupByLibrary.simpleMessage(
      "Away today",
    ),
    "employee_leave_other": MessageLookupByLibrary.simpleMessage("Away"),
    "employee_leave_paternity": MessageLookupByLibrary.simpleMessage(
      "Paternity leave",
    ),
    "employee_leave_personal": MessageLookupByLibrary.simpleMessage(
      "Personal leave",
    ),
    "employee_leave_sick": MessageLookupByLibrary.simpleMessage("Sick leave"),
    "employee_leave_suspension": MessageLookupByLibrary.simpleMessage(
      "Suspended",
    ),
    "employee_leave_unpaid": MessageLookupByLibrary.simpleMessage(
      "Unpaid leave",
    ),
    "employee_leave_vacation": MessageLookupByLibrary.simpleMessage(
      "On vacation",
    ),
    "employee_months": m47,
    "employee_notes_subtitle": MessageLookupByLibrary.simpleMessage(
      "The business\'s own notes. The person does not see them.",
    ),
    "employee_notes_title": MessageLookupByLibrary.simpleMessage("Notes"),
    "employee_period_day": MessageLookupByLibrary.simpleMessage("day"),
    "employee_period_fortnight": MessageLookupByLibrary.simpleMessage(
      "fortnight",
    ),
    "employee_period_hour": MessageLookupByLibrary.simpleMessage("hour"),
    "employee_period_month": MessageLookupByLibrary.simpleMessage("month"),
    "employee_period_week": MessageLookupByLibrary.simpleMessage("week"),
    "employee_period_year": MessageLookupByLibrary.simpleMessage("year"),
    "employee_person_editable": MessageLookupByLibrary.simpleMessage(
      "These are the person\'s own details: what you change here changes in their account too.",
    ),
    "employee_person_hidden": MessageLookupByLibrary.simpleMessage(
      "A person\'s own profile is visible to the company only while they work here.",
    ),
    "employee_person_owned": MessageLookupByLibrary.simpleMessage(
      "The person\'s own profile: only they can change it.",
    ),
    "employee_person_title": MessageLookupByLibrary.simpleMessage(
      "Personal data",
    ),
    "employee_record_title": MessageLookupByLibrary.simpleMessage("Record"),
    "employee_search_hint": MessageLookupByLibrary.simpleMessage(
      "Search a detail: phone, address, salary...",
    ),
    "employee_sex_female": MessageLookupByLibrary.simpleMessage("Female"),
    "employee_sex_male": MessageLookupByLibrary.simpleMessage("Male"),
    "employee_sex_other": MessageLookupByLibrary.simpleMessage("Other"),
    "employee_span_none": MessageLookupByLibrary.simpleMessage(
      "Less than a day",
    ),
    "employee_state_cancelled": MessageLookupByLibrary.simpleMessage(
      "Invitation withdrawn",
    ),
    "employee_state_declined": MessageLookupByLibrary.simpleMessage("Declined"),
    "employee_state_ended": MessageLookupByLibrary.simpleMessage("Former"),
    "employee_state_invited": MessageLookupByLibrary.simpleMessage(
      "Invitation pending",
    ),
    "employee_state_unfiled": MessageLookupByLibrary.simpleMessage(
      "No job filed",
    ),
    "employee_tenure_company": MessageLookupByLibrary.simpleMessage(
      "In the company",
    ),
    "employee_tenure_company_since": m48,
    "employee_tenure_job": MessageLookupByLibrary.simpleMessage("In this job"),
    "employee_tenure_title": MessageLookupByLibrary.simpleMessage("Time here"),
    "employee_unfiled_subtitle": MessageLookupByLibrary.simpleMessage(
      "Your card is listed so the team shows complete, but this business has no job on record for you yet.",
    ),
    "employee_unfiled_title": MessageLookupByLibrary.simpleMessage(
      "You have no job filed here",
    ),
    "employee_upcoming_title": MessageLookupByLibrary.simpleMessage(
      "Upcoming absences",
    ),
    "employee_value_none": MessageLookupByLibrary.simpleMessage("Not set"),
    "employee_value_not_filed": MessageLookupByLibrary.simpleMessage(
      "Not filed",
    ),
    "employee_value_waiting": MessageLookupByLibrary.simpleMessage(
      "No answer yet",
    ),
    "employee_work_contact_title": MessageLookupByLibrary.simpleMessage(
      "Work contact",
    ),
    "employee_work_not_started": MessageLookupByLibrary.simpleMessage(
      "Not started yet",
    ),
    "employee_work_working": MessageLookupByLibrary.simpleMessage("Working"),
    "employee_workday_full_time": MessageLookupByLibrary.simpleMessage(
      "Full time",
    ),
    "employee_workday_hourly": MessageLookupByLibrary.simpleMessage(
      "By the hour",
    ),
    "employee_workday_part_time": MessageLookupByLibrary.simpleMessage(
      "Part time",
    ),
    "employee_workday_shifts": MessageLookupByLibrary.simpleMessage("Shifts"),
    "employee_years": m49,
    "employees_active_count": m50,
    "employees_column_contract": MessageLookupByLibrary.simpleMessage(
      "Contract",
    ),
    "employees_column_person": MessageLookupByLibrary.simpleMessage("Person"),
    "employees_column_since": MessageLookupByLibrary.simpleMessage("Since"),
    "employees_column_status": MessageLookupByLibrary.simpleMessage("Status"),
    "employees_former_title": MessageLookupByLibrary.simpleMessage(
      "Former employees",
    ),
    "employees_group_away": MessageLookupByLibrary.simpleMessage("Away today"),
    "employees_group_invited": MessageLookupByLibrary.simpleMessage(
      "Waiting to accept",
    ),
    "employees_group_not_started": MessageLookupByLibrary.simpleMessage(
      "Starting later",
    ),
    "employees_group_working": MessageLookupByLibrary.simpleMessage(
      "Working today",
    ),
    "employees_invite": MessageLookupByLibrary.simpleMessage("Invite"),
    "employees_invite_email": MessageLookupByLibrary.simpleMessage("Email"),
    "employees_invite_email_hint": MessageLookupByLibrary.simpleMessage(
      "name@example.com",
    ),
    "employees_invite_job": MessageLookupByLibrary.simpleMessage("Job title"),
    "employees_invite_job_hint": MessageLookupByLibrary.simpleMessage(
      "Cashier, accountant, driver…",
    ),
    "employees_invite_send": MessageLookupByLibrary.simpleMessage(
      "Send invitation",
    ),
    "employees_invite_subtitle": MessageLookupByLibrary.simpleMessage(
      "They don\'t need an account: when they sign up with this email, the invitation will be waiting for them.",
    ),
    "employees_invite_title": MessageLookupByLibrary.simpleMessage(
      "Invite someone",
    ),
    "employees_invited_count": m51,
    "employees_select_subtitle": MessageLookupByLibrary.simpleMessage(
      "Select a person on the list to see everything about them here.",
    ),
    "employees_select_title": MessageLookupByLibrary.simpleMessage(
      "Pick someone",
    ),
    "employees_title": MessageLookupByLibrary.simpleMessage("People"),
    "employees_you": MessageLookupByLibrary.simpleMessage("You"),
    "enter_days": MessageLookupByLibrary.simpleMessage("Number of days"),
    "expand": MessageLookupByLibrary.simpleMessage("Expand"),
    "external_services": MessageLookupByLibrary.simpleMessage(
      "External Services",
    ),
    "field_added": MessageLookupByLibrary.simpleMessage("Field added"),
    "field_type_barcode": MessageLookupByLibrary.simpleMessage("Barcode"),
    "field_type_barcode_hint": MessageLookupByLibrary.simpleMessage(
      "The code printed on the product: EAN, UPC, ISBN",
    ),
    "field_type_boolean": MessageLookupByLibrary.simpleMessage("Yes / No"),
    "field_type_boolean_hint": MessageLookupByLibrary.simpleMessage(
      "Something that is either on or off",
    ),
    "field_type_categories": MessageLookupByLibrary.simpleMessage("Categories"),
    "field_type_categories_hint": MessageLookupByLibrary.simpleMessage(
      "A closed list of labels, several per product",
    ),
    "field_type_counter": MessageLookupByLibrary.simpleMessage("Counter"),
    "field_type_counter_hint": MessageLookupByLibrary.simpleMessage(
      "A number that goes up on its own",
    ),
    "field_type_currency": MessageLookupByLibrary.simpleMessage("Other amount"),
    "field_type_currency_hint": MessageLookupByLibrary.simpleMessage(
      "Money that is not the selling price: cost, wholesale, margin",
    ),
    "field_type_date": MessageLookupByLibrary.simpleMessage("Date"),
    "field_type_date_hint": MessageLookupByLibrary.simpleMessage(
      "A day: expiry, arrival or release",
    ),
    "field_type_datetime": MessageLookupByLibrary.simpleMessage(
      "Date and time",
    ),
    "field_type_datetime_hint": MessageLookupByLibrary.simpleMessage(
      "A day and the time of day",
    ),
    "field_type_decimal": MessageLookupByLibrary.simpleMessage("Decimal"),
    "field_type_decimal_hint": MessageLookupByLibrary.simpleMessage(
      "Numbers with decimals",
    ),
    "field_type_description": MessageLookupByLibrary.simpleMessage(
      "Description",
    ),
    "field_type_description_hint": MessageLookupByLibrary.simpleMessage(
      "What the product is, in words. The AI reads it and searches by meaning",
    ),
    "field_type_discount": MessageLookupByLibrary.simpleMessage("Discount"),
    "field_type_discount_hint": MessageLookupByLibrary.simpleMessage(
      "The percent taken off the price at checkout, from 0 to 100",
    ),
    "field_type_email": MessageLookupByLibrary.simpleMessage("Email"),
    "field_type_email_hint": MessageLookupByLibrary.simpleMessage(
      "An email address",
    ),
    "field_type_image": MessageLookupByLibrary.simpleMessage("Image"),
    "field_type_image_hint": MessageLookupByLibrary.simpleMessage(
      "Photos of the product",
    ),
    "field_type_measure": MessageLookupByLibrary.simpleMessage("Measure"),
    "field_type_measure_hint": MessageLookupByLibrary.simpleMessage(
      "A magnitude with a unit: weight, volume, length",
    ),
    "field_type_number": MessageLookupByLibrary.simpleMessage("Number"),
    "field_type_number_hint": MessageLookupByLibrary.simpleMessage(
      "Whole numbers: units, sizes, quantities",
    ),
    "field_type_options": MessageLookupByLibrary.simpleMessage("Options list"),
    "field_type_options_hint": MessageLookupByLibrary.simpleMessage(
      "A closed list of labels, one per product: size, colour, condition",
    ),
    "field_type_percentage": MessageLookupByLibrary.simpleMessage("Percentage"),
    "field_type_percentage_hint": MessageLookupByLibrary.simpleMessage(
      "A rate written as 16, not as 0.16: tax, margin, commission",
    ),
    "field_type_phone": MessageLookupByLibrary.simpleMessage("Phone"),
    "field_type_phone_hint": MessageLookupByLibrary.simpleMessage(
      "A phone number",
    ),
    "field_type_price": MessageLookupByLibrary.simpleMessage("Price"),
    "field_type_price_hint": MessageLookupByLibrary.simpleMessage(
      "The selling price: what a customer pays",
    ),
    "field_type_sku": MessageLookupByLibrary.simpleMessage("SKU"),
    "field_type_sku_hint": MessageLookupByLibrary.simpleMessage(
      "Your own reference or part number",
    ),
    "field_type_stock": MessageLookupByLibrary.simpleMessage("Stock"),
    "field_type_stock_hint": MessageLookupByLibrary.simpleMessage(
      "Units on hand, kept by the inventory engine",
    ),
    "field_type_text": MessageLookupByLibrary.simpleMessage("Text"),
    "field_type_text_hint": MessageLookupByLibrary.simpleMessage(
      "Short one-line text: names, brands, references",
    ),
    "field_type_textarea": MessageLookupByLibrary.simpleMessage("Long text"),
    "field_type_textarea_hint": MessageLookupByLibrary.simpleMessage(
      "Multiline text customers don\'t search by",
    ),
    "field_type_title": MessageLookupByLibrary.simpleMessage("Product name"),
    "field_type_title_hint": MessageLookupByLibrary.simpleMessage(
      "What the product is called. The AI searches by it and names the product with it",
    ),
    "field_type_url": MessageLookupByLibrary.simpleMessage("Link"),
    "field_type_url_hint": MessageLookupByLibrary.simpleMessage(
      "A web address",
    ),
    "field_visibility_declared": MessageLookupByLibrary.simpleMessage(
      "Declared",
    ),
    "field_visibility_declared_hint": MessageLookupByLibrary.simpleMessage(
      "The AI knows the column exists and can filter by it, but never says what it holds. This is where a cost price belongs",
    ),
    "field_visibility_hidden": MessageLookupByLibrary.simpleMessage("Hidden"),
    "field_visibility_hidden_hint": MessageLookupByLibrary.simpleMessage(
      "The AI doesn\'t know this column exists",
    ),
    "field_visibility_visible": MessageLookupByLibrary.simpleMessage("Visible"),
    "field_visibility_visible_hint": MessageLookupByLibrary.simpleMessage(
      "The AI reads this column and can quote what it says",
    ),
    "finance": MessageLookupByLibrary.simpleMessage("Finance"),
    "finance_bot_activity": m52,
    "finance_bot_answers": MessageLookupByLibrary.simpleMessage(
      "Answering messages",
    ),
    "finance_bot_catalog": MessageLookupByLibrary.simpleMessage("Catalog"),
    "finance_bot_empty": MessageLookupByLibrary.simpleMessage(
      "Lyra cost nothing in this period",
    ),
    "finance_bot_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "The figures behind the bot could not be measured, which is not the same as it having cost nothing. Try again in a moment.",
    ),
    "finance_bot_error_title": MessageLookupByLibrary.simpleMessage(
      "What Lyra cost could not be read",
    ),
    "finance_bot_hint": m53,
    "finance_bot_media": MessageLookupByLibrary.simpleMessage(
      "Images and audio",
    ),
    "finance_bot_other": MessageLookupByLibrary.simpleMessage("Unattributed"),
    "finance_bot_other_hint": MessageLookupByLibrary.simpleMessage(
      "Spend of no known area",
    ),
    "finance_bot_queries": MessageLookupByLibrary.simpleMessage("Searches"),
    "finance_bot_research": MessageLookupByLibrary.simpleMessage("Web lookups"),
    "finance_bot_tables": MessageLookupByLibrary.simpleMessage(
      "Reading your tables",
    ),
    "finance_bot_tables_hint": m54,
    "finance_bot_text": MessageLookupByLibrary.simpleMessage("Replies"),
    "finance_bot_title": MessageLookupByLibrary.simpleMessage("Lyra spend"),
    "finance_bot_vectors": MessageLookupByLibrary.simpleMessage("Search index"),
    "finance_breakdown_empty": MessageLookupByLibrary.simpleMessage(
      "Nothing moved in this period",
    ),
    "finance_by_concept": MessageLookupByLibrary.simpleMessage("By concept"),
    "finance_by_method": MessageLookupByLibrary.simpleMessage("By method"),
    "finance_credit": MessageLookupByLibrary.simpleMessage("Sold on credit"),
    "finance_credit_hint": MessageLookupByLibrary.simpleMessage(
      "Not collected yet, so it is not income",
    ),
    "finance_currencies_add": MessageLookupByLibrary.simpleMessage(
      "Add currency",
    ),
    "finance_currencies_empty": MessageLookupByLibrary.simpleMessage(
      "You only take your main currency. Add an exchange currency to charge in another one.",
    ),
    "finance_currencies_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "The currencies of this company could not be read. Try again in a moment.",
    ),
    "finance_currencies_error_title": MessageLookupByLibrary.simpleMessage(
      "The currencies could not be loaded",
    ),
    "finance_currencies_subtitle": MessageLookupByLibrary.simpleMessage(
      "The main currency your catalog is priced in, and the exchange currencies you also take.",
    ),
    "finance_currencies_title": MessageLookupByLibrary.simpleMessage(
      "Currencies",
    ),
    "finance_currency": MessageLookupByLibrary.simpleMessage("Currency"),
    "finance_currency_create_title": MessageLookupByLibrary.simpleMessage(
      "Add an exchange currency",
    ),
    "finance_currency_custom_disclaimer": MessageLookupByLibrary.simpleMessage(
      "A custom rate is set by your business alone. You are solely responsible for the rate you assign and for the prices and charges that come from it.",
    ),
    "finance_currency_edit_title": MessageLookupByLibrary.simpleMessage(
      "Edit exchange rate",
    ),
    "finance_currency_form_subtitle": m55,
    "finance_currency_main": MessageLookupByLibrary.simpleMessage(
      "Main currency",
    ),
    "finance_currency_main_hint": MessageLookupByLibrary.simpleMessage(
      "Your stock, services and prices are in this currency. It cannot be changed here: changing it would relabel your prices without converting them.",
    ),
    "finance_currency_mode": MessageLookupByLibrary.simpleMessage(
      "Exchange rate",
    ),
    "finance_currency_mode_custom": MessageLookupByLibrary.simpleMessage(
      "Custom rate",
    ),
    "finance_currency_mode_custom_hint": MessageLookupByLibrary.simpleMessage(
      "A rate you set, until you change it",
    ),
    "finance_currency_mode_official": MessageLookupByLibrary.simpleMessage(
      "Official rate",
    ),
    "finance_currency_mode_official_hint": MessageLookupByLibrary.simpleMessage(
      "Updated on its own from the published rate",
    ),
    "finance_currency_no_rate": MessageLookupByLibrary.simpleMessage(
      "No rate available right now",
    ),
    "finance_currency_official_pending": MessageLookupByLibrary.simpleMessage(
      "The official rate appears once the currency is saved.",
    ),
    "finance_currency_official_today": m56,
    "finance_currency_placeholder": MessageLookupByLibrary.simpleMessage(
      "Which currency do you also take?",
    ),
    "finance_currency_rate": m57,
    "finance_currency_rate_error": MessageLookupByLibrary.simpleMessage(
      "Write a rate above zero",
    ),
    "finance_currency_remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "finance_currency_remove_message": m58,
    "finance_currency_remove_title": MessageLookupByLibrary.simpleMessage(
      "Remove this currency?",
    ),
    "finance_currency_updated": m59,
    "finance_expenses": MessageLookupByLibrary.simpleMessage("Paid"),
    "finance_export": MessageLookupByLibrary.simpleMessage("Export"),
    "finance_export_csv": MessageLookupByLibrary.simpleMessage("CSV (.zip)"),
    "finance_export_csv_hint": MessageLookupByLibrary.simpleMessage(
      "One file per dataset, for importing",
    ),
    "finance_export_datasets": MessageLookupByLibrary.simpleMessage(
      "What to include",
    ),
    "finance_export_datasets_empty": MessageLookupByLibrary.simpleMessage(
      "Pick at least one.",
    ),
    "finance_export_format": MessageLookupByLibrary.simpleMessage("Format"),
    "finance_export_last_month": MessageLookupByLibrary.simpleMessage(
      "Last month",
    ),
    "finance_export_last_year": MessageLookupByLibrary.simpleMessage(
      "Last year",
    ),
    "finance_export_payments": MessageLookupByLibrary.simpleMessage("Payments"),
    "finance_export_period": MessageLookupByLibrary.simpleMessage("Period"),
    "finance_export_receivables": MessageLookupByLibrary.simpleMessage(
      "Receivables",
    ),
    "finance_export_sale_lines": MessageLookupByLibrary.simpleMessage(
      "Sale lines",
    ),
    "finance_export_sales": MessageLookupByLibrary.simpleMessage("Sales"),
    "finance_export_saved": MessageLookupByLibrary.simpleMessage(
      "Export saved",
    ),
    "finance_export_stock_movements": MessageLookupByLibrary.simpleMessage(
      "Stock movements",
    ),
    "finance_export_subtitle": MessageLookupByLibrary.simpleMessage(
      "Sales, payments and stock movements for your accounting software. Every row carries its Lyra ID, so exporting a period again matches what was already imported.",
    ),
    "finance_export_this_month": MessageLookupByLibrary.simpleMessage(
      "This month",
    ),
    "finance_export_this_year": MessageLookupByLibrary.simpleMessage(
      "This year",
    ),
    "finance_export_title": MessageLookupByLibrary.simpleMessage(
      "Accounting export",
    ),
    "finance_export_xlsx": MessageLookupByLibrary.simpleMessage(
      "Excel (.xlsx)",
    ),
    "finance_export_xlsx_hint": MessageLookupByLibrary.simpleMessage(
      "One sheet per dataset",
    ),
    "finance_income": MessageLookupByLibrary.simpleMessage("Received"),
    "finance_income_payments": MessageLookupByLibrary.simpleMessage(
      "Other income",
    ),
    "finance_income_sales": MessageLookupByLibrary.simpleMessage("Sales"),
    "finance_method_account": MessageLookupByLibrary.simpleMessage("Account"),
    "finance_method_account_placeholder": MessageLookupByLibrary.simpleMessage(
      "Number, phone, email or address",
    ),
    "finance_method_create_title": MessageLookupByLibrary.simpleMessage(
      "Add a payment method",
    ),
    "finance_method_currency": MessageLookupByLibrary.simpleMessage("Currency"),
    "finance_method_currency_fixed": m60,
    "finance_method_currency_missing": m61,
    "finance_method_currency_placeholder": MessageLookupByLibrary.simpleMessage(
      "Which currency does it receive?",
    ),
    "finance_method_document": MessageLookupByLibrary.simpleMessage(
      "Id number",
    ),
    "finance_method_document_placeholder": MessageLookupByLibrary.simpleMessage(
      "Tax or personal id",
    ),
    "finance_method_document_type": MessageLookupByLibrary.simpleMessage(
      "Type",
    ),
    "finance_method_edit_title": MessageLookupByLibrary.simpleMessage(
      "Edit payment method",
    ),
    "finance_method_fee": MessageLookupByLibrary.simpleMessage("Commission"),
    "finance_method_fee_error": MessageLookupByLibrary.simpleMessage(
      "Write a commission above zero (a percentage below 100)",
    ),
    "finance_method_fee_fixed": MessageLookupByLibrary.simpleMessage(
      "Fixed amount",
    ),
    "finance_method_fee_fixed_in": m62,
    "finance_method_fee_none": MessageLookupByLibrary.simpleMessage(
      "No commission",
    ),
    "finance_method_fee_percent": MessageLookupByLibrary.simpleMessage(
      "Percentage",
    ),
    "finance_method_fee_percent_value": m63,
    "finance_method_holder": MessageLookupByLibrary.simpleMessage("Holder"),
    "finance_method_holder_placeholder": MessageLookupByLibrary.simpleMessage(
      "Name the account is under",
    ),
    "finance_method_institution": MessageLookupByLibrary.simpleMessage(
      "Institution",
    ),
    "finance_method_institution_placeholder":
        MessageLookupByLibrary.simpleMessage("Bank, wallet or network"),
    "finance_method_instructions": MessageLookupByLibrary.simpleMessage(
      "Instructions",
    ),
    "finance_method_instructions_placeholder":
        MessageLookupByLibrary.simpleMessage(
          "What the customer has to do besides sending it",
        ),
    "finance_method_label": MessageLookupByLibrary.simpleMessage("Name"),
    "finance_method_label_placeholder": MessageLookupByLibrary.simpleMessage(
      "How you call this account",
    ),
    "finance_method_no_rails": MessageLookupByLibrary.simpleMessage(
      "The available methods could not be read. Go back to the tab and try again.",
    ),
    "finance_method_nothing": MessageLookupByLibrary.simpleMessage(
      "This method needs no account details: name it if you want and save it.",
    ),
    "finance_method_optional": MessageLookupByLibrary.simpleMessage("optional"),
    "finance_method_rail": MessageLookupByLibrary.simpleMessage("Method"),
    "finance_method_rail_fixed": MessageLookupByLibrary.simpleMessage(
      "Cannot be changed",
    ),
    "finance_method_rail_placeholder": MessageLookupByLibrary.simpleMessage(
      "Which one do you accept?",
    ),
    "finance_method_remove": MessageLookupByLibrary.simpleMessage("Turn off"),
    "finance_method_remove_message": m64,
    "finance_method_remove_title": MessageLookupByLibrary.simpleMessage(
      "Turn this method off?",
    ),
    "finance_method_subtitle": MessageLookupByLibrary.simpleMessage(
      "What a customer is told when they ask how to pay. Each method asks only for what it needs to receive money.",
    ),
    "finance_methods_add": MessageLookupByLibrary.simpleMessage("Add method"),
    "finance_methods_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Add the account a customer is told to send money to.",
    ),
    "finance_methods_empty_title": MessageLookupByLibrary.simpleMessage(
      "No payment method yet",
    ),
    "finance_methods_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "The accounts of this company could not be read. Try again in a moment.",
    ),
    "finance_methods_error_title": MessageLookupByLibrary.simpleMessage(
      "The payment methods could not be loaded",
    ),
    "finance_methods_locked_subtitle": MessageLookupByLibrary.simpleMessage(
      "Sign out and sign in again with your password to see the payment accounts.",
    ),
    "finance_methods_locked_title": MessageLookupByLibrary.simpleMessage(
      "Account details are protected",
    ),
    "finance_methods_subtitle": MessageLookupByLibrary.simpleMessage(
      "Each method takes money in one currency and can add its own commission to the charge.",
    ),
    "finance_methods_title": MessageLookupByLibrary.simpleMessage(
      "Payment methods",
    ),
    "finance_more": m65,
    "finance_movements": m66,
    "finance_net": MessageLookupByLibrary.simpleMessage("Net"),
    "finance_net_hint": MessageLookupByLibrary.simpleMessage(
      "Received minus paid",
    ),
    "finance_payment_amount": MessageLookupByLibrary.simpleMessage("Amount"),
    "finance_payment_concept": MessageLookupByLibrary.simpleMessage("Concept"),
    "finance_payment_counterpart": MessageLookupByLibrary.simpleMessage(
      "Counterpart",
    ),
    "finance_payment_date": MessageLookupByLibrary.simpleMessage("Date"),
    "finance_payment_method": MessageLookupByLibrary.simpleMessage("Method"),
    "finance_payment_note": MessageLookupByLibrary.simpleMessage("Note"),
    "finance_payment_reference": MessageLookupByLibrary.simpleMessage(
      "Reference",
    ),
    "finance_payment_ticket": MessageLookupByLibrary.simpleMessage("Ticket"),
    "finance_payment_void": MessageLookupByLibrary.simpleMessage("Void"),
    "finance_payment_void_message": m67,
    "finance_payment_void_title": MessageLookupByLibrary.simpleMessage(
      "Void this payment?",
    ),
    "finance_payments_all": MessageLookupByLibrary.simpleMessage("All"),
    "finance_payments_any": MessageLookupByLibrary.simpleMessage("Any"),
    "finance_payments_any_state": MessageLookupByLibrary.simpleMessage(
      "Recorded and voided",
    ),
    "finance_payments_clear": MessageLookupByLibrary.simpleMessage(
      "Clear filters",
    ),
    "finance_payments_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Money paid to a supplier or collected outside the counter is recorded here.",
    ),
    "finance_payments_empty_title": MessageLookupByLibrary.simpleMessage(
      "No payments recorded yet",
    ),
    "finance_payments_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "The movements of this company could not be read. Try again in a moment.",
    ),
    "finance_payments_error_title": MessageLookupByLibrary.simpleMessage(
      "The history could not be loaded",
    ),
    "finance_payments_in": MessageLookupByLibrary.simpleMessage("Received"),
    "finance_payments_none_subtitle": MessageLookupByLibrary.simpleMessage(
      "Nothing was received or paid under these filters.",
    ),
    "finance_payments_none_title": MessageLookupByLibrary.simpleMessage(
      "No movement matches",
    ),
    "finance_payments_out": MessageLookupByLibrary.simpleMessage("Paid"),
    "finance_payments_record": MessageLookupByLibrary.simpleMessage(
      "Record payment",
    ),
    "finance_payments_recorded": MessageLookupByLibrary.simpleMessage(
      "Recorded",
    ),
    "finance_payments_voided": MessageLookupByLibrary.simpleMessage("Voided"),
    "finance_range_month": MessageLookupByLibrary.simpleMessage("Last 30 days"),
    "finance_range_today": MessageLookupByLibrary.simpleMessage("Today"),
    "finance_range_week": MessageLookupByLibrary.simpleMessage("Last 7 days"),
    "finance_range_year": MessageLookupByLibrary.simpleMessage(
      "Last 12 months",
    ),
    "finance_receivable_collect": MessageLookupByLibrary.simpleMessage(
      "Record collection",
    ),
    "finance_receivable_collected": MessageLookupByLibrary.simpleMessage(
      "Collected",
    ),
    "finance_receivable_customer": MessageLookupByLibrary.simpleMessage(
      "Customer",
    ),
    "finance_receivable_date": MessageLookupByLibrary.simpleMessage("Sold on"),
    "finance_receivable_outstanding": MessageLookupByLibrary.simpleMessage(
      "Outstanding",
    ),
    "finance_receivable_ticket": MessageLookupByLibrary.simpleMessage("Ticket"),
    "finance_receivable_total": MessageLookupByLibrary.simpleMessage("Total"),
    "finance_receivables_collected": MessageLookupByLibrary.simpleMessage(
      "Collected",
    ),
    "finance_receivables_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Every credit sale has been collected.",
    ),
    "finance_receivables_empty_title": MessageLookupByLibrary.simpleMessage(
      "Nobody owes anything",
    ),
    "finance_receivables_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "The credit sales of this company could not be read. Try again in a moment.",
    ),
    "finance_receivables_error_title": MessageLookupByLibrary.simpleMessage(
      "The debts could not be loaded",
    ),
    "finance_receivables_open_only": MessageLookupByLibrary.simpleMessage(
      "Only unpaid",
    ),
    "finance_receivables_outstanding": MessageLookupByLibrary.simpleMessage(
      "Outstanding",
    ),
    "finance_receivables_sold": MessageLookupByLibrary.simpleMessage(
      "Sold on credit",
    ),
    "finance_record_account": MessageLookupByLibrary.simpleMessage("Account"),
    "finance_record_account_placeholder": MessageLookupByLibrary.simpleMessage(
      "Where did the money land?",
    ),
    "finance_record_amount_error": MessageLookupByLibrary.simpleMessage(
      "Write how much money moved",
    ),
    "finance_record_concept_placeholder": MessageLookupByLibrary.simpleMessage(
      "What was it for?",
    ),
    "finance_record_counterpart_placeholder":
        MessageLookupByLibrary.simpleMessage("Who paid, or who was paid"),
    "finance_record_method_placeholder": MessageLookupByLibrary.simpleMessage(
      "How did it move?",
    ),
    "finance_record_no_account": MessageLookupByLibrary.simpleMessage(
      "No account",
    ),
    "finance_record_note_placeholder": MessageLookupByLibrary.simpleMessage(
      "What should be remembered about it",
    ),
    "finance_record_reference_placeholder":
        MessageLookupByLibrary.simpleMessage("Confirmation number"),
    "finance_record_save": MessageLookupByLibrary.simpleMessage("Record"),
    "finance_record_subtitle": MessageLookupByLibrary.simpleMessage(
      "Money the company received or paid outside the counter. A sale\'s own payment is already on its ticket.",
    ),
    "finance_record_ticket_placeholder": MessageLookupByLibrary.simpleMessage(
      "Ticket code",
    ),
    "finance_record_title": MessageLookupByLibrary.simpleMessage(
      "Record a payment",
    ),
    "finance_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "finance_select_empty": MessageLookupByLibrary.simpleMessage(
      "No option matches your search",
    ),
    "finance_summary_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Nothing came in and nothing went out in this period.",
    ),
    "finance_summary_empty_title": MessageLookupByLibrary.simpleMessage(
      "No money moved",
    ),
    "finance_summary_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "The money of this period could not be read. Try again in a moment.",
    ),
    "finance_summary_error_title": MessageLookupByLibrary.simpleMessage(
      "The figures could not be loaded",
    ),
    "finance_tab_methods": MessageLookupByLibrary.simpleMessage(
      "Payment methods",
    ),
    "finance_tab_overview": MessageLookupByLibrary.simpleMessage("Overview"),
    "finance_tab_payments": MessageLookupByLibrary.simpleMessage("Payments"),
    "finance_tab_receivables": MessageLookupByLibrary.simpleMessage(
      "Receivables",
    ),
    "finance_window": m68,
    "first_name_input": MessageLookupByLibrary.simpleMessage("First name"),
    "form_empty_ma": m69,
    "form_incomplete_ma": m70,
    "form_invalid_ma": m71,
    "form_long_ma": m72,
    "hide_keyboard": MessageLookupByLibrary.simpleMessage("Hide keyboard"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "how_often_pay": MessageLookupByLibrary.simpleMessage(
      "How often do you pay?",
    ),
    "image_crop_failed": MessageLookupByLibrary.simpleMessage(
      "That image couldn\'t be prepared. Try another one.",
    ),
    "image_crop_hint": MessageLookupByLibrary.simpleMessage(
      "Drag the image to move it and zoom in to leave out what you don\'t want.",
    ),
    "image_crop_title": MessageLookupByLibrary.simpleMessage("Frame the image"),
    "image_viewer_close": MessageLookupByLibrary.simpleMessage("Close image"),
    "import_source_airtable": MessageLookupByLibrary.simpleMessage("Airtable"),
    "import_source_airtable_hint": MessageLookupByLibrary.simpleMessage(
      "A table from one of your bases",
    ),
    "import_source_apps": MessageLookupByLibrary.simpleMessage(
      "Apps and stores",
    ),
    "import_source_device": MessageLookupByLibrary.simpleMessage(
      "From this device",
    ),
    "import_source_formats": MessageLookupByLibrary.simpleMessage(
      "Other formats",
    ),
    "import_source_google_sheets": MessageLookupByLibrary.simpleMessage(
      "Google Sheets",
    ),
    "import_source_google_sheets_hint": MessageLookupByLibrary.simpleMessage(
      "A sheet from your Google Drive",
    ),
    "import_source_json": MessageLookupByLibrary.simpleMessage("JSON"),
    "import_source_json_hint": MessageLookupByLibrary.simpleMessage(
      "A products file exported as JSON",
    ),
    "import_source_magento": MessageLookupByLibrary.simpleMessage("Magento"),
    "import_source_magento_hint": MessageLookupByLibrary.simpleMessage(
      "The catalog of your store",
    ),
    "import_source_notion": MessageLookupByLibrary.simpleMessage("Notion"),
    "import_source_notion_hint": MessageLookupByLibrary.simpleMessage(
      "A database from your workspace",
    ),
    "import_source_ods": MessageLookupByLibrary.simpleMessage("OpenDocument"),
    "import_source_ods_hint": MessageLookupByLibrary.simpleMessage(
      "A sheet from LibreOffice or OpenOffice",
    ),
    "import_source_search": MessageLookupByLibrary.simpleMessage(
      "Search a source",
    ),
    "import_source_search_empty": MessageLookupByLibrary.simpleMessage(
      "No source matches your search",
    ),
    "import_source_shopify": MessageLookupByLibrary.simpleMessage("Shopify"),
    "import_source_shopify_hint": MessageLookupByLibrary.simpleMessage(
      "The catalog of your store",
    ),
    "import_source_smartsheet": MessageLookupByLibrary.simpleMessage(
      "Smartsheet",
    ),
    "import_source_smartsheet_hint": MessageLookupByLibrary.simpleMessage(
      "A sheet from your workspace",
    ),
    "import_source_soon": MessageLookupByLibrary.simpleMessage("Soon"),
    "import_source_spreadsheet": MessageLookupByLibrary.simpleMessage(
      "Upload spreadsheet",
    ),
    "import_source_spreadsheet_hint": MessageLookupByLibrary.simpleMessage(
      "An Excel, CSV or ODS file from this device",
    ),
    "import_source_subtitle": MessageLookupByLibrary.simpleMessage(
      "Choose where this table\'s products come from",
    ),
    "import_source_trello": MessageLookupByLibrary.simpleMessage("Trello"),
    "import_source_trello_hint": MessageLookupByLibrary.simpleMessage(
      "The cards of one of your boards",
    ),
    "import_source_woocommerce": MessageLookupByLibrary.simpleMessage(
      "WooCommerce",
    ),
    "import_source_woocommerce_hint": MessageLookupByLibrary.simpleMessage(
      "The catalog of your store",
    ),
    "import_source_xml": MessageLookupByLibrary.simpleMessage("XML"),
    "import_source_xml_hint": MessageLookupByLibrary.simpleMessage(
      "A products feed in XML",
    ),
    "import_table": MessageLookupByLibrary.simpleMessage("Import table"),
    "import_table_busy": MessageLookupByLibrary.simpleMessage(
      "This table is still being imported. It opens once its columns and rows are in",
    ),
    "import_table_done": MessageLookupByLibrary.simpleMessage("Table imported"),
    "import_table_file_type": MessageLookupByLibrary.simpleMessage(
      "Spreadsheets and CSV",
    ),
    "import_table_loading": MessageLookupByLibrary.simpleMessage(
      "Loading rows",
    ),
    "import_table_partial": MessageLookupByLibrary.simpleMessage(
      "The table was created, but its rows could not be imported",
    ),
    "import_table_preparing": MessageLookupByLibrary.simpleMessage(
      "Setting up columns",
    ),
    "import_table_started": MessageLookupByLibrary.simpleMessage(
      "Table created. Its columns and rows are still loading",
    ),
    "import_table_unsupported": MessageLookupByLibrary.simpleMessage(
      "Only spreadsheet and CSV files can be imported",
    ),
    "inbox": MessageLookupByLibrary.simpleMessage("Inbox"),
    "inventory": MessageLookupByLibrary.simpleMessage("Inventory"),
    "lan_add_device": MessageLookupByLibrary.simpleMessage("Add device"),
    "lan_browsers_fingerprint": MessageLookupByLibrary.simpleMessage(
      "Certificate fingerprint (SHA-256)",
    ),
    "lan_browsers_install": MessageLookupByLibrary.simpleMessage(
      "Install on this computer",
    ),
    "lan_browsers_installed": MessageLookupByLibrary.simpleMessage(
      "Installed. Browsers on this computer now trust the server; restart any that were open.",
    ),
    "lan_browsers_not_installed": MessageLookupByLibrary.simpleMessage(
      "It wasn\'t installed. You can save it and install it by hand.",
    ),
    "lan_browsers_open": m73,
    "lan_browsers_save": MessageLookupByLibrary.simpleMessage(
      "Save the certificate",
    ),
    "lan_browsers_saved": MessageLookupByLibrary.simpleMessage(
      "Saved. When installing it on the other computer, check that the fingerprint it shows is the one above.",
    ),
    "lan_browsers_subtitle": MessageLookupByLibrary.simpleMessage(
      "A browser opens Lyra from the server only on a computer that trusts this server\'s certificate. Install it here, or save it and install it on the other computer.",
    ),
    "lan_browsers_thumbprint": MessageLookupByLibrary.simpleMessage(
      "Windows shows it as its thumbprint (SHA-1)",
    ),
    "lan_browsers_title": MessageLookupByLibrary.simpleMessage("Web browsers"),
    "lan_connecting": MessageLookupByLibrary.simpleMessage(
      "Connecting to the server…",
    ),
    "lan_device_code": m74,
    "lan_devices": MessageLookupByLibrary.simpleMessage("Devices"),
    "lan_devices_master": MessageLookupByLibrary.simpleMessage("server"),
    "lan_devices_online": MessageLookupByLibrary.simpleMessage("online"),
    "lan_devices_remove": MessageLookupByLibrary.simpleMessage("Remove"),
    "lan_devices_remove_message": MessageLookupByLibrary.simpleMessage(
      "Its sessions end now, and it can\'t connect again until it\'s paired again.",
    ),
    "lan_devices_remove_title": m75,
    "lan_devices_revoked": MessageLookupByLibrary.simpleMessage("removed"),
    "lan_enroll": MessageLookupByLibrary.simpleMessage("Connect"),
    "lan_enroll_subtitle": MessageLookupByLibrary.simpleMessage(
      "This computer is the server, but this app lost its key. It gets a new one now. If the server asks for a passphrase when it starts, type it; otherwise leave it empty.",
    ),
    "lan_enroll_title": MessageLookupByLibrary.simpleMessage(
      "Connect this app to the server",
    ),
    "lan_enter_failed": MessageLookupByLibrary.simpleMessage(
      "The server answered, but the business couldn\'t be opened. Update Lyra on the server computer, then try again.",
    ),
    "lan_entering": MessageLookupByLibrary.simpleMessage("Opening Lyra…"),
    "lan_error_code": m76,
    "lan_error_title": MessageLookupByLibrary.simpleMessage(
      "The server couldn\'t start",
    ),
    "lan_eula_accept": MessageLookupByLibrary.simpleMessage(
      "I accept the Lyra licence agreement",
    ),
    "lan_fingerprint": MessageLookupByLibrary.simpleMessage(
      "Server fingerprint",
    ),
    "lan_leave": MessageLookupByLibrary.simpleMessage("Use Lyra another way"),
    "lan_leave_message": MessageLookupByLibrary.simpleMessage(
      "This device forgets its pairing and goes back to the sign in. The server and its data stay as they are.",
    ),
    "lan_leave_title": MessageLookupByLibrary.simpleMessage(
      "Stop using this server here?",
    ),
    "lan_locked_client": MessageLookupByLibrary.simpleMessage(
      "Ask someone to unlock it on the server computer.",
    ),
    "lan_locked_master": MessageLookupByLibrary.simpleMessage(
      "Type the passphrase to unlock the data.",
    ),
    "lan_locked_title": MessageLookupByLibrary.simpleMessage(
      "The server is locked",
    ),
    "lan_master_company": MessageLookupByLibrary.simpleMessage("Your business"),
    "lan_master_company_name": MessageLookupByLibrary.simpleMessage(
      "Business name",
    ),
    "lan_master_country": MessageLookupByLibrary.simpleMessage("Country"),
    "lan_master_create": MessageLookupByLibrary.simpleMessage(
      "Create the server",
    ),
    "lan_master_currency": MessageLookupByLibrary.simpleMessage(
      "Main currency",
    ),
    "lan_master_currency_note": MessageLookupByLibrary.simpleMessage(
      "Prices are written in the main currency. It can\'t be changed later.",
    ),
    "lan_master_eula_required": MessageLookupByLibrary.simpleMessage(
      "Accept the licence agreement to continue.",
    ),
    "lan_master_exists": MessageLookupByLibrary.simpleMessage(
      "This computer is already a server. Go back and choose it again to open it.",
    ),
    "lan_master_invalid_username": MessageLookupByLibrary.simpleMessage(
      "The username must be 3 to 32 letters, digits, dots, dashes or underscores, starting with a letter.",
    ),
    "lan_master_language": MessageLookupByLibrary.simpleMessage("Language"),
    "lan_master_no_match": MessageLookupByLibrary.simpleMessage(
      "Nothing matches",
    ),
    "lan_master_owner": MessageLookupByLibrary.simpleMessage("Your account"),
    "lan_master_subtitle": MessageLookupByLibrary.simpleMessage(
      "You\'ll be the owner. Other people join later with invitations.",
    ),
    "lan_master_title": MessageLookupByLibrary.simpleMessage(
      "Set up this computer as the server",
    ),
    "lan_master_weak_password": MessageLookupByLibrary.simpleMessage(
      "The password must have at least 10 characters.",
    ),
    "lan_other_mode": MessageLookupByLibrary.simpleMessage(
      "Use Lyra another way",
    ),
    "lan_pair_address_input": MessageLookupByLibrary.simpleMessage(
      "Server address",
    ),
    "lan_pair_again": MessageLookupByLibrary.simpleMessage("Pair again"),
    "lan_pair_browser": m77,
    "lan_pair_code": MessageLookupByLibrary.simpleMessage("Pairing code"),
    "lan_pair_found": MessageLookupByLibrary.simpleMessage(
      "Servers on this network",
    ),
    "lan_pair_name_input": MessageLookupByLibrary.simpleMessage(
      "Name of this device",
    ),
    "lan_pair_none": MessageLookupByLibrary.simpleMessage(
      "No server found. Type its address instead.",
    ),
    "lan_pair_or_code": MessageLookupByLibrary.simpleMessage(
      "Or type the code it shows",
    ),
    "lan_pair_port_input": MessageLookupByLibrary.simpleMessage("Port"),
    "lan_pair_searching": MessageLookupByLibrary.simpleMessage(
      "Looking for servers on this network…",
    ),
    "lan_pair_submit": MessageLookupByLibrary.simpleMessage("Pair"),
    "lan_pair_subtitle": MessageLookupByLibrary.simpleMessage(
      "On the server, open Lyra and choose Add device. Then type here the code it shows.",
    ),
    "lan_pair_title": MessageLookupByLibrary.simpleMessage(
      "Pair with the server",
    ),
    "lan_pair_unreachable": MessageLookupByLibrary.simpleMessage(
      "No Lyra server answered at that address.",
    ),
    "lan_pair_wrong_code": MessageLookupByLibrary.simpleMessage(
      "That code didn\'t work. Check it, or add the device again on the server for a new one.",
    ),
    "lan_pair_wrong_master": MessageLookupByLibrary.simpleMessage(
      "Something on this network answered in place of the server, so pairing was stopped to protect you. Check the address, and that you\'re on the right network.",
    ),
    "lan_pairing_code": MessageLookupByLibrary.simpleMessage(
      "Type this code on the new device",
    ),
    "lan_pairing_expires": MessageLookupByLibrary.simpleMessage(
      "It works for 5 minutes and for one device.",
    ),
    "lan_pairing_scan": MessageLookupByLibrary.simpleMessage(
      "Or, on a phone, scan this QR with Lyra.",
    ),
    "lan_passphrase_hint": MessageLookupByLibrary.simpleMessage(
      "Without one, this computer\'s own sign-in protects the data. With one, nobody can open the data without it: if you forget it, only the recovery key gets the data back.",
    ),
    "lan_passphrase_input": MessageLookupByLibrary.simpleMessage("Passphrase"),
    "lan_passphrase_toggle": MessageLookupByLibrary.simpleMessage(
      "Ask for a passphrase every time the server starts",
    ),
    "lan_ready_subtitle": MessageLookupByLibrary.simpleMessage(
      "The devices that use this server: who is connected, adding one, removing one.",
    ),
    "lan_ready_title": MessageLookupByLibrary.simpleMessage(
      "Connected to the server",
    ),
    "lan_recovery_confirm": MessageLookupByLibrary.simpleMessage(
      "I wrote the 24 words down and keep them somewhere safe",
    ),
    "lan_recovery_continue": MessageLookupByLibrary.simpleMessage(
      "Start the server",
    ),
    "lan_recovery_required": MessageLookupByLibrary.simpleMessage(
      "Confirm you wrote the words down first. They won\'t be shown again.",
    ),
    "lan_recovery_subtitle": MessageLookupByLibrary.simpleMessage(
      "These 24 words are the only way to get the data back if this computer\'s keys are lost. Lyra keeps no copy: without them the data is gone for good.",
    ),
    "lan_recovery_title": MessageLookupByLibrary.simpleMessage(
      "Write down your recovery key",
    ),
    "lan_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "lan_revoked_subtitle": MessageLookupByLibrary.simpleMessage(
      "An admin removed it from the server. Pair it again to keep using it.",
    ),
    "lan_revoked_title": MessageLookupByLibrary.simpleMessage(
      "This device was removed",
    ),
    "lan_scan_button": MessageLookupByLibrary.simpleMessage(
      "Scan the QR on the server",
    ),
    "lan_scan_foreign": MessageLookupByLibrary.simpleMessage(
      "That QR isn\'t a Lyra pairing code. Scan the one on the server\'s screen.",
    ),
    "lan_scan_hint": MessageLookupByLibrary.simpleMessage(
      "Point the camera at the QR on the server\'s screen.",
    ),
    "lan_scan_no_camera": MessageLookupByLibrary.simpleMessage(
      "The camera isn\'t available. Allow Lyra to use it, or type the code instead.",
    ),
    "lan_scan_title": MessageLookupByLibrary.simpleMessage(
      "Scan the server\'s QR",
    ),
    "lan_search_again": MessageLookupByLibrary.simpleMessage("Search again"),
    "lan_sign_in_subtitle": MessageLookupByLibrary.simpleMessage(
      "Use the username and password of your account on this server.",
    ),
    "lan_sign_in_title": MessageLookupByLibrary.simpleMessage("Sign in"),
    "lan_sign_out": MessageLookupByLibrary.simpleMessage("Sign out"),
    "lan_start_server": MessageLookupByLibrary.simpleMessage(
      "Start the server",
    ),
    "lan_stop_server": MessageLookupByLibrary.simpleMessage("Stop the server"),
    "lan_stop_server_message": m78,
    "lan_stop_server_title": MessageLookupByLibrary.simpleMessage(
      "Stop the server?",
    ),
    "lan_unlock": MessageLookupByLibrary.simpleMessage("Unlock"),
    "lan_unpaired_subtitle": MessageLookupByLibrary.simpleMessage(
      "Pair it with the server, or use Lyra another way.",
    ),
    "lan_unpaired_title": MessageLookupByLibrary.simpleMessage(
      "This device isn\'t paired",
    ),
    "lan_unreachable_client": MessageLookupByLibrary.simpleMessage(
      "Ask someone to open Lyra on the server computer, and check this device is on the same network.",
    ),
    "lan_unreachable_master": MessageLookupByLibrary.simpleMessage(
      "The server on this computer is stopped.",
    ),
    "lan_unreachable_title": MessageLookupByLibrary.simpleMessage(
      "The server isn\'t answering",
    ),
    "lan_update_subtitle": MessageLookupByLibrary.simpleMessage(
      "This app and the server don\'t speak the same version. Update Lyra on both.",
    ),
    "lan_update_title": MessageLookupByLibrary.simpleMessage("Update Lyra"),
    "lan_username_input": MessageLookupByLibrary.simpleMessage("Username"),
    "last_name_input": MessageLookupByLibrary.simpleMessage("Last name"),
    "local_server": MessageLookupByLibrary.simpleMessage("Server"),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "marketing": MessageLookupByLibrary.simpleMessage("Marketing"),
    "messages": MessageLookupByLibrary.simpleMessage("Messages"),
    "messages_all_sessions": MessageLookupByLibrary.simpleMessage(
      "Show earlier conversations",
    ),
    "messages_assign": MessageLookupByLibrary.simpleMessage("Assign"),
    "messages_assigned_to": m79,
    "messages_attention_confirmation": MessageLookupByLibrary.simpleMessage(
      "The customer could not be told their sale was approved",
    ),
    "messages_attention_failure": MessageLookupByLibrary.simpleMessage(
      "The assistant failed to answer",
    ),
    "messages_attention_more": m80,
    "messages_attention_partial": MessageLookupByLibrary.simpleMessage(
      "The customer received a cut-off message",
    ),
    "messages_attention_payment": MessageLookupByLibrary.simpleMessage(
      "The customer wants to pay and the channel has no account set up",
    ),
    "messages_attention_pending": MessageLookupByLibrary.simpleMessage(
      "Work for a person",
    ),
    "messages_attention_question": MessageLookupByLibrary.simpleMessage(
      "The assistant promised to confirm something",
    ),
    "messages_audio": MessageLookupByLibrary.simpleMessage("Audio"),
    "messages_author_bot": MessageLookupByLibrary.simpleMessage("Assistant"),
    "messages_author_system": MessageLookupByLibrary.simpleMessage(
      "Automatic message",
    ),
    "messages_author_team": MessageLookupByLibrary.simpleMessage("Team"),
    "messages_bot_active": MessageLookupByLibrary.simpleMessage(
      "The assistant is answering",
    ),
    "messages_bot_disabled": MessageLookupByLibrary.simpleMessage(
      "The assistant is off on this number. Turn it on in the channel settings.",
    ),
    "messages_bot_paused": MessageLookupByLibrary.simpleMessage(
      "Attended by a person",
    ),
    "messages_bot_paused_by": m81,
    "messages_bot_until": m82,
    "messages_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "messages_composer_hint": MessageLookupByLibrary.simpleMessage(
      "Replying takes the conversation from the assistant for 24 hours.",
    ),
    "messages_composer_placeholder": MessageLookupByLibrary.simpleMessage(
      "Write a reply",
    ),
    "messages_confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "messages_count": m83,
    "messages_empty_filter_subtitle": MessageLookupByLibrary.simpleMessage(
      "No conversation matches this tab or the search.",
    ),
    "messages_empty_filter_title": MessageLookupByLibrary.simpleMessage(
      "Nothing here",
    ),
    "messages_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "When a customer writes to one of your numbers, the conversation shows up here.",
    ),
    "messages_empty_title": MessageLookupByLibrary.simpleMessage(
      "No conversations yet",
    ),
    "messages_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Check the connection and try again.",
    ),
    "messages_error_title": MessageLookupByLibrary.simpleMessage(
      "The conversations could not be read",
    ),
    "messages_filter_all": MessageLookupByLibrary.simpleMessage("All"),
    "messages_filter_attention": MessageLookupByLibrary.simpleMessage(
      "Attention",
    ),
    "messages_filter_mine": MessageLookupByLibrary.simpleMessage("Mine"),
    "messages_filter_paused": MessageLookupByLibrary.simpleMessage(
      "With a person",
    ),
    "messages_filter_unanswered": MessageLookupByLibrary.simpleMessage(
      "Unanswered",
    ),
    "messages_image": MessageLookupByLibrary.simpleMessage("Image"),
    "messages_mark_ended": MessageLookupByLibrary.simpleMessage(
      "Mark as ended",
    ),
    "messages_mark_read": MessageLookupByLibrary.simpleMessage("Mark as read"),
    "messages_mark_sold": MessageLookupByLibrary.simpleMessage("Mark as sold"),
    "messages_marked_read": MessageLookupByLibrary.simpleMessage(
      "Marked as read",
    ),
    "messages_more_failed": MessageLookupByLibrary.simpleMessage(
      "More conversations could not be read. Try again",
    ),
    "messages_notice_assigned": m84,
    "messages_notice_failure_title": MessageLookupByLibrary.simpleMessage(
      "The assistant could not answer a customer",
    ),
    "messages_notice_pending_title": MessageLookupByLibrary.simpleMessage(
      "A conversation needs a person",
    ),
    "messages_notice_waiting_title": m85,
    "messages_older": MessageLookupByLibrary.simpleMessage(
      "Load older messages",
    ),
    "messages_options": MessageLookupByLibrary.simpleMessage("More options"),
    "messages_pending": m86,
    "messages_queued_subtitle": MessageLookupByLibrary.simpleMessage(
      "The phone of this number is offline: the message leaves when it reconnects.",
    ),
    "messages_queued_title": MessageLookupByLibrary.simpleMessage(
      "Message queued",
    ),
    "messages_resolve": MessageLookupByLibrary.simpleMessage(
      "Mark as resolved",
    ),
    "messages_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "messages_return": MessageLookupByLibrary.simpleMessage(
      "Return to the assistant",
    ),
    "messages_select_subtitle": MessageLookupByLibrary.simpleMessage(
      "Its messages open on this side.",
    ),
    "messages_select_title": MessageLookupByLibrary.simpleMessage(
      "Choose a conversation",
    ),
    "messages_send": MessageLookupByLibrary.simpleMessage("Send"),
    "messages_sold_confirm_message": MessageLookupByLibrary.simpleMessage(
      "It confirms the payment and sends the customer the confirmation of their purchase.",
    ),
    "messages_sold_confirm_title": MessageLookupByLibrary.simpleMessage(
      "Mark this conversation as sold?",
    ),
    "messages_status_failed": MessageLookupByLibrary.simpleMessage("Not sent"),
    "messages_status_queued": MessageLookupByLibrary.simpleMessage("Queued"),
    "messages_tag_since": m87,
    "messages_tag_tickets": m88,
    "messages_take": MessageLookupByLibrary.simpleMessage("Take over"),
    "messages_take_24h": MessageLookupByLibrary.simpleMessage("For 24 hours"),
    "messages_take_2h": MessageLookupByLibrary.simpleMessage("For 2 hours"),
    "messages_take_30m": MessageLookupByLibrary.simpleMessage("For 30 minutes"),
    "messages_take_manual": MessageLookupByLibrary.simpleMessage(
      "Until I return it",
    ),
    "messages_this_session": MessageLookupByLibrary.simpleMessage(
      "Show only this conversation",
    ),
    "messages_thread_empty": MessageLookupByLibrary.simpleMessage(
      "No messages in this conversation yet",
    ),
    "messages_thread_error_title": MessageLookupByLibrary.simpleMessage(
      "The conversation could not be read",
    ),
    "messages_unassign": MessageLookupByLibrary.simpleMessage(
      "Remove the assignment",
    ),
    "messages_unassigned": MessageLookupByLibrary.simpleMessage(
      "Nobody assigned",
    ),
    "messages_undo_stage": MessageLookupByLibrary.simpleMessage(
      "Undo the manual state",
    ),
    "messages_usage": MessageLookupByLibrary.simpleMessage("AI cost"),
    "messages_usage_area_embeddings": MessageLookupByLibrary.simpleMessage(
      "Catalog searches",
    ),
    "messages_usage_area_line": m89,
    "messages_usage_area_media": MessageLookupByLibrary.simpleMessage(
      "Images and voice notes",
    ),
    "messages_usage_area_replies": MessageLookupByLibrary.simpleMessage(
      "Replies",
    ),
    "messages_usage_area_research": MessageLookupByLibrary.simpleMessage(
      "Web research",
    ),
    "messages_usage_area_routing": MessageLookupByLibrary.simpleMessage(
      "Routing and summaries",
    ),
    "messages_usage_areas_title": MessageLookupByLibrary.simpleMessage(
      "Where it went",
    ),
    "messages_usage_cached": MessageLookupByLibrary.simpleMessage(
      "From the provider\'s cache",
    ),
    "messages_usage_cached_hint": MessageLookupByLibrary.simpleMessage(
      "Part of the input, charged at the full rate",
    ),
    "messages_usage_cost": MessageLookupByLibrary.simpleMessage("Spent"),
    "messages_usage_input": MessageLookupByLibrary.simpleMessage("Input"),
    "messages_usage_input_hint": MessageLookupByLibrary.simpleMessage(
      "Includes the instructions, tools and history resent on every round",
    ),
    "messages_usage_none": MessageLookupByLibrary.simpleMessage(
      "No model ran in this session: people answered it.",
    ),
    "messages_usage_note": MessageLookupByLibrary.simpleMessage(
      "In USD, as the providers billed every model that ran for this session. The safety check before each burst is billed to the company\'s day, not here.",
    ),
    "messages_usage_output": MessageLookupByLibrary.simpleMessage("Output"),
    "messages_usage_output_hint": MessageLookupByLibrary.simpleMessage(
      "Includes the reasoning the model spent",
    ),
    "messages_usage_requests": MessageLookupByLibrary.simpleMessage(
      "Model calls",
    ),
    "messages_usage_title": MessageLookupByLibrary.simpleMessage(
      "AI cost of this session",
    ),
    "messages_usage_tokens": MessageLookupByLibrary.simpleMessage("Tokens"),
    "messages_usage_tokens_title": MessageLookupByLibrary.simpleMessage(
      "Tokens",
    ),
    "messages_usage_unavailable": MessageLookupByLibrary.simpleMessage(
      "The cost of this session could not be read.",
    ),
    "messages_wait_days": m90,
    "messages_wait_hours": m91,
    "messages_wait_minutes": m92,
    "messages_wait_now": MessageLookupByLibrary.simpleMessage("just now"),
    "messages_waiting": m93,
    "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
    "new_service": MessageLookupByLibrary.simpleMessage("New service"),
    "next": MessageLookupByLibrary.simpleMessage("Next"),
    "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
    "once_a_year": MessageLookupByLibrary.simpleMessage("Once a year"),
    "password_input": MessageLookupByLibrary.simpleMessage("Password"),
    "password_mismatch": MessageLookupByLibrary.simpleMessage(
      "Passwords don\'t match",
    ),
    "past_due": MessageLookupByLibrary.simpleMessage("Past"),
    "pending_funds": MessageLookupByLibrary.simpleMessage("Pending Payments"),
    "permission_access_cell": m94,
    "permission_access_create": MessageLookupByLibrary.simpleMessage("Create"),
    "permission_access_delete": MessageLookupByLibrary.simpleMessage("Delete"),
    "permission_access_edit": MessageLookupByLibrary.simpleMessage("Edit"),
    "permission_access_unavailable": MessageLookupByLibrary.simpleMessage(
      "This area has no such action",
    ),
    "permission_access_view": MessageLookupByLibrary.simpleMessage("View"),
    "permission_business_branches_description":
        MessageLookupByLibrary.simpleMessage(
          "The company\'s branches: add new ones and edit their address, contact and map point.",
        ),
    "permission_business_branches_title": MessageLookupByLibrary.simpleMessage(
      "Branches",
    ),
    "permission_business_clients_description":
        MessageLookupByLibrary.simpleMessage(
          "The list of the company\'s clients.",
        ),
    "permission_business_clients_title": MessageLookupByLibrary.simpleMessage(
      "Clients",
    ),
    "permission_business_description": MessageLookupByLibrary.simpleMessage(
      "Open the business page. Delete removes the whole company from its settings.",
    ),
    "permission_business_employees_description":
        MessageLookupByLibrary.simpleMessage(
          "The team: see who works here, invite people by email and edit their job and profile.",
        ),
    "permission_business_employees_title": MessageLookupByLibrary.simpleMessage(
      "Employees",
    ),
    "permission_business_settings_description":
        MessageLookupByLibrary.simpleMessage(
          "The company profile: legal name, handle, activity, fiscal id, phone, website, country and logo.",
        ),
    "permission_business_settings_title": MessageLookupByLibrary.simpleMessage(
      "Business settings",
    ),
    "permission_business_statistics_description":
        MessageLookupByLibrary.simpleMessage(
          "The business statistics tab: sales, clients and activity over time.",
        ),
    "permission_business_statistics_title":
        MessageLookupByLibrary.simpleMessage("Statistics"),
    "permission_business_title": MessageLookupByLibrary.simpleMessage(
      "Business",
    ),
    "permission_channels_description": MessageLookupByLibrary.simpleMessage(
      "The AI channels: create them, edit their role, data and credentials, turn them on or off and disconnect them.",
    ),
    "permission_channels_title": MessageLookupByLibrary.simpleMessage(
      "Channels",
    ),
    "permission_connections_description": MessageLookupByLibrary.simpleMessage(
      "Third-party accounts linked to the company.",
    ),
    "permission_connections_title": MessageLookupByLibrary.simpleMessage(
      "Connections",
    ),
    "permission_deliveries_areas_description":
        MessageLookupByLibrary.simpleMessage(
          "The zones the company delivers to, with their fee and minimum order.",
        ),
    "permission_deliveries_areas_title": MessageLookupByLibrary.simpleMessage(
      "Delivery areas",
    ),
    "permission_deliveries_description": MessageLookupByLibrary.simpleMessage(
      "The deliveries desk and its map. Create opens new deliveries.",
    ),
    "permission_deliveries_settings_description":
        MessageLookupByLibrary.simpleMessage(
          "Whether the company delivers or offers pickup, the delivery note and the delivery options.",
        ),
    "permission_deliveries_settings_title":
        MessageLookupByLibrary.simpleMessage("Delivery settings"),
    "permission_deliveries_title": MessageLookupByLibrary.simpleMessage(
      "Deliveries",
    ),
    "permission_denied_pending": m95,
    "permission_denied_subtitle": m96,
    "permission_denied_title": m97,
    "permission_finance_description": MessageLookupByLibrary.simpleMessage(
      "Open the finance section. Each of its tabs has its own permission below.",
    ),
    "permission_finance_methods_description": MessageLookupByLibrary.simpleMessage(
      "The accounts clients pay into, plus exchange currencies and their rates.",
    ),
    "permission_finance_methods_title": MessageLookupByLibrary.simpleMessage(
      "Payment methods",
    ),
    "permission_finance_overview_description":
        MessageLookupByLibrary.simpleMessage(
          "The summary of the company\'s money and the assistant\'s cost.",
        ),
    "permission_finance_overview_title": MessageLookupByLibrary.simpleMessage(
      "Overview",
    ),
    "permission_finance_payments_description":
        MessageLookupByLibrary.simpleMessage(
          "Payments received. Create records a payment, delete voids one.",
        ),
    "permission_finance_payments_title": MessageLookupByLibrary.simpleMessage(
      "Payments",
    ),
    "permission_finance_receivables_description":
        MessageLookupByLibrary.simpleMessage(
          "What clients still owe. Edit marks an amount as collected.",
        ),
    "permission_finance_receivables_title":
        MessageLookupByLibrary.simpleMessage("Receivables"),
    "permission_finance_title": MessageLookupByLibrary.simpleMessage("Finance"),
    "permission_group_count": m98,
    "permission_inventory_description": MessageLookupByLibrary.simpleMessage(
      "Product tables: create, import, edit fields and records, move stock and delete tables.",
    ),
    "permission_inventory_title": MessageLookupByLibrary.simpleMessage(
      "Inventory",
    ),
    "permission_messages_description": MessageLookupByLibrary.simpleMessage(
      "The conversation desk. Edit covers replying, taking over from the assistant, assigning, tags and stages.",
    ),
    "permission_messages_title": MessageLookupByLibrary.simpleMessage(
      "Messages",
    ),
    "permission_own_read_only": MessageLookupByLibrary.simpleMessage(
      "These are your permissions in this business. Only someone who manages the team can change them.",
    ),
    "permission_pos_description": MessageLookupByLibrary.simpleMessage(
      "The point of sale mode. Create adds products to a ticket and charges it, delete discards a ticket.",
    ),
    "permission_pos_title": MessageLookupByLibrary.simpleMessage(
      "Point of sale",
    ),
    "permission_request_action": MessageLookupByLibrary.simpleMessage(
      "Request access",
    ),
    "permission_request_reason": MessageLookupByLibrary.simpleMessage(
      "Note (optional)",
    ),
    "permission_request_reason_hint": MessageLookupByLibrary.simpleMessage(
      "E.g. I handle the night shift\'s sales",
    ),
    "permission_request_reason_long": m99,
    "permission_request_send": MessageLookupByLibrary.simpleMessage(
      "Send request",
    ),
    "permission_request_sent": m100,
    "permission_request_subtitle": m101,
    "permission_request_title": MessageLookupByLibrary.simpleMessage(
      "Request access",
    ),
    "permission_sales_description": MessageLookupByLibrary.simpleMessage(
      "The live sales board. Edit covers the handover of an order and confirming a payment.",
    ),
    "permission_sales_done_description": MessageLookupByLibrary.simpleMessage(
      "The tab of sales already closed.",
    ),
    "permission_sales_done_title": MessageLookupByLibrary.simpleMessage(
      "Finished sales",
    ),
    "permission_sales_process_description":
        MessageLookupByLibrary.simpleMessage(
          "The tab of sales that are still open.",
        ),
    "permission_sales_process_title": MessageLookupByLibrary.simpleMessage(
      "Sales in process",
    ),
    "permission_sales_title": MessageLookupByLibrary.simpleMessage("Sales"),
    "permission_search_empty": MessageLookupByLibrary.simpleMessage(
      "No permission matches the search.",
    ),
    "permission_search_hint": MessageLookupByLibrary.simpleMessage(
      "Search a permission: sales, inventory, payments...",
    ),
    "plan_basic": MessageLookupByLibrary.simpleMessage("Basic"),
    "plan_duo": MessageLookupByLibrary.simpleMessage("Duo"),
    "plan_family": MessageLookupByLibrary.simpleMessage("Family"),
    "plan_freemium": MessageLookupByLibrary.simpleMessage("Freemium"),
    "plan_normal": MessageLookupByLibrary.simpleMessage("Normal"),
    "plan_plus": MessageLookupByLibrary.simpleMessage("Plus"),
    "plan_pro": MessageLookupByLibrary.simpleMessage("Pro"),
    "plan_simple": MessageLookupByLibrary.simpleMessage("Simple"),
    "plan_suggestions": MessageLookupByLibrary.simpleMessage(
      "Description suggestions",
    ),
    "pos": MessageLookupByLibrary.simpleMessage("POS"),
    "pos_amount_add": MessageLookupByLibrary.simpleMessage("Add to ticket"),
    "pos_amount_concept": MessageLookupByLibrary.simpleMessage("Concept"),
    "pos_amount_concept_placeholder": MessageLookupByLibrary.simpleMessage(
      "What is being charged",
    ),
    "pos_amount_price": MessageLookupByLibrary.simpleMessage("Price"),
    "pos_amount_price_error": MessageLookupByLibrary.simpleMessage(
      "Write the price as a number, zero or more",
    ),
    "pos_amount_price_placeholder": MessageLookupByLibrary.simpleMessage("0"),
    "pos_amount_subtitle": MessageLookupByLibrary.simpleMessage(
      "For something the catalog does not have: a delivery, a repair, a fee.",
    ),
    "pos_amount_title": MessageLookupByLibrary.simpleMessage(
      "Charge an amount",
    ),
    "pos_catalog_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Import a price list from the inventory section and it will be sold from here",
    ),
    "pos_catalog_empty_title": MessageLookupByLibrary.simpleMessage(
      "There are no products yet",
    ),
    "pos_catalog_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "The products did not arrive. Try again.",
    ),
    "pos_catalog_error_title": MessageLookupByLibrary.simpleMessage(
      "The catalog could not be loaded",
    ),
    "pos_catalog_missing_subtitle": MessageLookupByLibrary.simpleMessage(
      "This business has no products table yet, so there is nothing to ring up",
    ),
    "pos_catalog_missing_title": MessageLookupByLibrary.simpleMessage(
      "There is no catalog to sell from",
    ),
    "pos_catalog_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "pos_catalog_search_empty": MessageLookupByLibrary.simpleMessage(
      "No product matches",
    ),
    "pos_category_all": MessageLookupByLibrary.simpleMessage("All"),
    "pos_checkout_confirm": MessageLookupByLibrary.simpleMessage("Charge"),
    "pos_checkout_done": m102,
    "pos_checkout_method": MessageLookupByLibrary.simpleMessage(
      "Payment method",
    ),
    "pos_checkout_method_empty": MessageLookupByLibrary.simpleMessage(
      "No payment method",
    ),
    "pos_checkout_method_placeholder": MessageLookupByLibrary.simpleMessage(
      "How it is being paid",
    ),
    "pos_checkout_methods_error": MessageLookupByLibrary.simpleMessage(
      "The payment methods have not been loaded, so nothing can be charged yet",
    ),
    "pos_checkout_reference": MessageLookupByLibrary.simpleMessage("Reference"),
    "pos_checkout_reference_error": MessageLookupByLibrary.simpleMessage(
      "Write the payment\'s reference so it can be reconciled",
    ),
    "pos_checkout_reference_placeholder": MessageLookupByLibrary.simpleMessage(
      "Confirmation or authorization number",
    ),
    "pos_checkout_title": MessageLookupByLibrary.simpleMessage(
      "Charge the ticket",
    ),
    "pos_checkout_total": MessageLookupByLibrary.simpleMessage("To charge"),
    "pos_close": MessageLookupByLibrary.simpleMessage("Close POS"),
    "pos_mode": MessageLookupByLibrary.simpleMessage("POS mode"),
    "pos_product_no_price": MessageLookupByLibrary.simpleMessage("No price"),
    "pos_product_no_price_flag": MessageLookupByLibrary.simpleMessage(
      "That product has no price, so it cannot be rung up",
    ),
    "pos_product_stock": m103,
    "pos_product_unnamed": MessageLookupByLibrary.simpleMessage(
      "Unnamed product",
    ),
    "pos_sales_today": m104,
    "pos_search_product": MessageLookupByLibrary.simpleMessage(
      "Search products",
    ),
    "pos_tax_error": MessageLookupByLibrary.simpleMessage(
      "A rate between 0 and 100",
    ),
    "pos_tax_input": MessageLookupByLibrary.simpleMessage("Percentage"),
    "pos_tax_placeholder": MessageLookupByLibrary.simpleMessage("0"),
    "pos_tax_subtitle": MessageLookupByLibrary.simpleMessage(
      "The percentage charged on this ticket. Written as 16, not as 0.16.",
    ),
    "pos_tax_title": MessageLookupByLibrary.simpleMessage("VAT rate"),
    "pos_ticket_add_amount": MessageLookupByLibrary.simpleMessage(
      "Charge an amount",
    ),
    "pos_ticket_checkout": MessageLookupByLibrary.simpleMessage(
      "Complete purchase",
    ),
    "pos_ticket_clear": MessageLookupByLibrary.simpleMessage("Delete ticket"),
    "pos_ticket_clear_confirm": MessageLookupByLibrary.simpleMessage(
      "Delete it",
    ),
    "pos_ticket_clear_message": MessageLookupByLibrary.simpleMessage(
      "Everything on it comes off, the units it was holding go back on sale and nothing is charged.",
    ),
    "pos_ticket_clear_title": MessageLookupByLibrary.simpleMessage(
      "Delete this ticket?",
    ),
    "pos_ticket_cleared": MessageLookupByLibrary.simpleMessage(
      "Ticket deleted",
    ),
    "pos_ticket_dropped": MessageLookupByLibrary.simpleMessage(
      "This ticket was just cancelled from another screen",
    ),
    "pos_ticket_each": m105,
    "pos_ticket_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Pick a product from the catalog and it lands here",
    ),
    "pos_ticket_empty_title": MessageLookupByLibrary.simpleMessage(
      "The ticket is empty",
    ),
    "pos_ticket_less": MessageLookupByLibrary.simpleMessage("One less"),
    "pos_ticket_more": MessageLookupByLibrary.simpleMessage("One more"),
    "pos_ticket_number": m106,
    "pos_ticket_released": m107,
    "pos_ticket_remove": MessageLookupByLibrary.simpleMessage(
      "Take it off the ticket",
    ),
    "pos_ticket_subtotal": MessageLookupByLibrary.simpleMessage("Subtotal"),
    "pos_ticket_taken": MessageLookupByLibrary.simpleMessage(
      "This ticket was just charged from another register",
    ),
    "pos_ticket_tax": m108,
    "pos_ticket_tax_edit": MessageLookupByLibrary.simpleMessage(
      "Change the rate charged on this ticket",
    ),
    "pos_ticket_total": MessageLookupByLibrary.simpleMessage("Total"),
    "pos_ticket_unheld": MessageLookupByLibrary.simpleMessage(
      "No longer set aside",
    ),
    "pos_ticket_units": m109,
    "price_title": MessageLookupByLibrary.simpleMessage("What\'s the price?"),
    "product_table_view_add_item": MessageLookupByLibrary.simpleMessage(
      "Add item",
    ),
    "product_table_view_date_full": MessageLookupByLibrary.simpleMessage(
      "Full date",
    ),
    "product_table_view_date_full_hint": MessageLookupByLibrary.simpleMessage(
      "Show this column with its numbers and its time",
    ),
    "product_table_view_date_short": MessageLookupByLibrary.simpleMessage(
      "Written date",
    ),
    "product_table_view_date_short_hint": MessageLookupByLibrary.simpleMessage(
      "Show this column written out, as Feb 12, 2026",
    ),
    "product_table_view_empty_row": MessageLookupByLibrary.simpleMessage(
      "Fill in at least one field to add an item",
    ),
    "product_table_view_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Add stock to see its rows here.",
    ),
    "product_table_view_empty_title": MessageLookupByLibrary.simpleMessage(
      "This table is empty",
    ),
    "product_table_view_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "product_table_view_error_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load this table",
    ),
    "product_table_view_image_files": MessageLookupByLibrary.simpleMessage(
      "Images",
    ),
    "product_table_view_image_large": MessageLookupByLibrary.simpleMessage(
      "That image is over 10 MB. Pick a lighter one.",
    ),
    "product_table_view_image_library": MessageLookupByLibrary.simpleMessage(
      "Pick an image",
    ),
    "product_table_view_image_remove": MessageLookupByLibrary.simpleMessage(
      "Remove image",
    ),
    "product_table_view_image_unsaved": MessageLookupByLibrary.simpleMessage(
      "Save this item first to add a picture to it",
    ),
    "product_table_view_image_upload": MessageLookupByLibrary.simpleMessage(
      "Upload image",
    ),
    "product_table_view_image_view": MessageLookupByLibrary.simpleMessage(
      "View image",
    ),
    "product_table_view_item_added": MessageLookupByLibrary.simpleMessage(
      "Item added",
    ),
    "product_table_view_next": MessageLookupByLibrary.simpleMessage(
      "Next page",
    ),
    "product_table_view_page": m110,
    "product_table_view_previous": MessageLookupByLibrary.simpleMessage(
      "Previous page",
    ),
    "product_table_view_search_count": m111,
    "product_table_view_sku_generate": MessageLookupByLibrary.simpleMessage(
      "Generate SKU",
    ),
    "product_table_view_sku_generate_hint":
        MessageLookupByLibrary.simpleMessage(
          "Create a new random code for this item",
        ),
    "product_table_view_title": MessageLookupByLibrary.simpleMessage("Table"),
    "product_tables_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Create your first table to organize your products here.",
    ),
    "product_tables_empty_title": MessageLookupByLibrary.simpleMessage(
      "No tables yet",
    ),
    "product_tables_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "product_tables_error_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load your tables",
    ),
    "product_tables_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "product_tables_search_empty": MessageLookupByLibrary.simpleMessage(
      "No tables match your search",
    ),
    "products": MessageLookupByLibrary.simpleMessage("Products"),
    "rename_table": MessageLookupByLibrary.simpleMessage("Rename table"),
    "rename_table_subtitle": MessageLookupByLibrary.simpleMessage(
      "Change what this table is called. Everything else about it lives in its settings",
    ),
    "report": MessageLookupByLibrary.simpleMessage("Report"),
    "resend_code": MessageLookupByLibrary.simpleMessage("Resend code"),
    "resend_code_timer": m112,
    "sales": MessageLookupByLibrary.simpleMessage("Sales"),
    "sales_all_stages": MessageLookupByLibrary.simpleMessage("Every state"),
    "sales_any_channel": MessageLookupByLibrary.simpleMessage("Every channel"),
    "sales_approve_action": MessageLookupByLibrary.simpleMessage(
      "Approve the sale",
    ),
    "sales_approve_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "sales_approve_confirm": MessageLookupByLibrary.simpleMessage("Approve"),
    "sales_approve_done": MessageLookupByLibrary.simpleMessage("Sale approved"),
    "sales_approve_message": MessageLookupByLibrary.simpleMessage(
      "It says the money arrived and closes the sale. Nothing here can see a bank, so this is your word on it: look at the payment proof first.",
    ),
    "sales_approve_title": MessageLookupByLibrary.simpleMessage(
      "Approve this payment?",
    ),
    "sales_catalog_error": MessageLookupByLibrary.simpleMessage(
      "The states could not be read",
    ),
    "sales_channel": MessageLookupByLibrary.simpleMessage("Channel"),
    "sales_clear": MessageLookupByLibrary.simpleMessage("Clear filters"),
    "sales_column_channel": MessageLookupByLibrary.simpleMessage(
      "Came in through",
    ),
    "sales_column_customer": MessageLookupByLibrary.simpleMessage("Customer"),
    "sales_column_outstanding": MessageLookupByLibrary.simpleMessage(
      "Outstanding",
    ),
    "sales_column_seller": MessageLookupByLibrary.simpleMessage("Sold by"),
    "sales_column_stage": MessageLookupByLibrary.simpleMessage("State"),
    "sales_column_ticket": MessageLookupByLibrary.simpleMessage("Ticket"),
    "sales_column_total": MessageLookupByLibrary.simpleMessage("Total"),
    "sales_column_units": MessageLookupByLibrary.simpleMessage("Units"),
    "sales_column_wait": MessageLookupByLibrary.simpleMessage("Waiting"),
    "sales_count": m113,
    "sales_detail_address": MessageLookupByLibrary.simpleMessage(
      "On the number",
    ),
    "sales_detail_attention": MessageLookupByLibrary.simpleMessage(
      "Waiting on you",
    ),
    "sales_detail_bot": MessageLookupByLibrary.simpleMessage("Answered by"),
    "sales_detail_channel": MessageLookupByLibrary.simpleMessage(
      "Came in through",
    ),
    "sales_detail_chat": MessageLookupByLibrary.simpleMessage("Conversation"),
    "sales_detail_closed": MessageLookupByLibrary.simpleMessage("Charged"),
    "sales_detail_collected": MessageLookupByLibrary.simpleMessage("Collected"),
    "sales_detail_contact": MessageLookupByLibrary.simpleMessage("Contact"),
    "sales_detail_credit": MessageLookupByLibrary.simpleMessage(
      "Sold on credit",
    ),
    "sales_detail_customer_unknown": MessageLookupByLibrary.simpleMessage(
      "No name given",
    ),
    "sales_detail_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Check the connection and try again.",
    ),
    "sales_detail_error_title": MessageLookupByLibrary.simpleMessage(
      "The sale could not be read",
    ),
    "sales_detail_handover": MessageLookupByLibrary.simpleMessage(
      "The handover",
    ),
    "sales_detail_handover_at": MessageLookupByLibrary.simpleMessage(
      "Recorded",
    ),
    "sales_detail_handover_by": MessageLookupByLibrary.simpleMessage(
      "Recorded by",
    ),
    "sales_detail_handover_mode": MessageLookupByLibrary.simpleMessage(
      "How they get it",
    ),
    "sales_detail_handover_none": MessageLookupByLibrary.simpleMessage(
      "There is nothing to hand over yet",
    ),
    "sales_detail_handover_none_deal": MessageLookupByLibrary.simpleMessage(
      "Nobody has rung this up: there is no document to hand over.",
    ),
    "sales_detail_handover_none_open": MessageLookupByLibrary.simpleMessage(
      "The ticket has not been charged, so nothing has left the shelf for good.",
    ),
    "sales_detail_handover_note": MessageLookupByLibrary.simpleMessage("Note"),
    "sales_detail_handover_state": MessageLookupByLibrary.simpleMessage(
      "Where it got to",
    ),
    "sales_detail_handover_unstored": MessageLookupByLibrary.simpleMessage(
      "Nobody has recorded this: it is how the sale reads, not what somebody said.",
    ),
    "sales_detail_held": MessageLookupByLibrary.simpleMessage("Units held"),
    "sales_detail_hold_expires": MessageLookupByLibrary.simpleMessage("Lapses"),
    "sales_detail_hold_units": m114,
    "sales_detail_holds": MessageLookupByLibrary.simpleMessage(
      "What the shelf is keeping",
    ),
    "sales_detail_holds_empty": MessageLookupByLibrary.simpleMessage(
      "Nothing is set aside for this customer.",
    ),
    "sales_detail_id": MessageLookupByLibrary.simpleMessage("Sale id"),
    "sales_detail_item_available": m115,
    "sales_detail_item_concept": MessageLookupByLibrary.simpleMessage(
      "Not a product",
    ),
    "sales_detail_item_gone": MessageLookupByLibrary.simpleMessage(
      "No longer sold",
    ),
    "sales_detail_item_held": m116,
    "sales_detail_item_list": m117,
    "sales_detail_item_price": MessageLookupByLibrary.simpleMessage("Price"),
    "sales_detail_item_product": MessageLookupByLibrary.simpleMessage(
      "Product",
    ),
    "sales_detail_item_qty": MessageLookupByLibrary.simpleMessage("Qty"),
    "sales_detail_item_total": MessageLookupByLibrary.simpleMessage("Total"),
    "sales_detail_item_unheld": MessageLookupByLibrary.simpleMessage(
      "Said to be held, and nothing is",
    ),
    "sales_detail_items": MessageLookupByLibrary.simpleMessage("What is on it"),
    "sales_detail_items_empty": MessageLookupByLibrary.simpleMessage(
      "Nothing on it yet",
    ),
    "sales_detail_items_flags": MessageLookupByLibrary.simpleMessage(
      "Worth checking",
    ),
    "sales_detail_items_gone_count": m118,
    "sales_detail_items_lines": MessageLookupByLibrary.simpleMessage("Lines"),
    "sales_detail_items_no_match": MessageLookupByLibrary.simpleMessage(
      "No line matches the search",
    ),
    "sales_detail_items_open": MessageLookupByLibrary.simpleMessage(
      "See the products",
    ),
    "sales_detail_items_search": MessageLookupByLibrary.simpleMessage(
      "Search a product or its code",
    ),
    "sales_detail_items_unheld_count": m119,
    "sales_detail_method": MessageLookupByLibrary.simpleMessage("Paid with"),
    "sales_detail_method_offered": MessageLookupByLibrary.simpleMessage(
      "Offered to pay with",
    ),
    "sales_detail_missing_subtitle": MessageLookupByLibrary.simpleMessage(
      "Nothing is held for it and nothing was agreed on the money, or it was rung up under another record. Refresh the board to see where it went.",
    ),
    "sales_detail_missing_title": MessageLookupByLibrary.simpleMessage(
      "This is no longer a sale",
    ),
    "sales_detail_money": MessageLookupByLibrary.simpleMessage("The money"),
    "sales_detail_none": MessageLookupByLibrary.simpleMessage("Not said"),
    "sales_detail_note": MessageLookupByLibrary.simpleMessage(
      "Note on the ticket",
    ),
    "sales_detail_open": MessageLookupByLibrary.simpleMessage("Open the sale"),
    "sales_detail_opened": MessageLookupByLibrary.simpleMessage("Opened"),
    "sales_detail_outstanding": MessageLookupByLibrary.simpleMessage(
      "Still owed",
    ),
    "sales_detail_proof": MessageLookupByLibrary.simpleMessage("Payment proof"),
    "sales_detail_proof_at": MessageLookupByLibrary.simpleMessage("Sent"),
    "sales_detail_proof_count": m120,
    "sales_detail_proof_empty": MessageLookupByLibrary.simpleMessage(
      "Nothing has been sent for this sale yet.",
    ),
    "sales_detail_proof_file": MessageLookupByLibrary.simpleMessage(
      "File sent",
    ),
    "sales_detail_proof_file_failed": MessageLookupByLibrary.simpleMessage(
      "The file could not be opened",
    ),
    "sales_detail_proof_file_open": MessageLookupByLibrary.simpleMessage(
      "Open the file",
    ),
    "sales_detail_proof_image": MessageLookupByLibrary.simpleMessage(
      "Picture sent",
    ),
    "sales_detail_proof_lost": MessageLookupByLibrary.simpleMessage(
      "A picture came and could not be stored. This is what came with it.",
    ),
    "sales_detail_proof_open": MessageLookupByLibrary.simpleMessage(
      "See it full size",
    ),
    "sales_detail_proof_reference": MessageLookupByLibrary.simpleMessage(
      "Reference given",
    ),
    "sales_detail_proof_said": MessageLookupByLibrary.simpleMessage(
      "What they wrote",
    ),
    "sales_detail_proof_subtitle": MessageLookupByLibrary.simpleMessage(
      "What the customer sent to show the money went out. It is what they said and showed, not something anybody here checked.",
    ),
    "sales_detail_reference": MessageLookupByLibrary.simpleMessage("Reference"),
    "sales_detail_seller": MessageLookupByLibrary.simpleMessage("Sold by"),
    "sales_detail_settled": MessageLookupByLibrary.simpleMessage(
      "Nothing owed",
    ),
    "sales_detail_source_chat": MessageLookupByLibrary.simpleMessage(
      "Being arranged",
    ),
    "sales_detail_source_invoice": MessageLookupByLibrary.simpleMessage(
      "Open at the till",
    ),
    "sales_detail_source_ticket": MessageLookupByLibrary.simpleMessage(
      "Charged",
    ),
    "sales_detail_stage_since": MessageLookupByLibrary.simpleMessage(
      "At this state since",
    ),
    "sales_detail_status_cancelled": MessageLookupByLibrary.simpleMessage(
      "Cancelled",
    ),
    "sales_detail_status_completed": MessageLookupByLibrary.simpleMessage(
      "Charged",
    ),
    "sales_detail_status_failed": MessageLookupByLibrary.simpleMessage(
      "Failed",
    ),
    "sales_detail_status_open": MessageLookupByLibrary.simpleMessage("Open"),
    "sales_detail_subtotal": MessageLookupByLibrary.simpleMessage("Subtotal"),
    "sales_detail_tax": MessageLookupByLibrary.simpleMessage("Tax"),
    "sales_detail_tax_rate": m121,
    "sales_detail_terminal": MessageLookupByLibrary.simpleMessage("Till"),
    "sales_detail_title": MessageLookupByLibrary.simpleMessage("Sale"),
    "sales_detail_total": MessageLookupByLibrary.simpleMessage("Total"),
    "sales_detail_trace": MessageLookupByLibrary.simpleMessage(
      "Where it comes from",
    ),
    "sales_detail_units": MessageLookupByLibrary.simpleMessage("Units"),
    "sales_detail_unpriced": MessageLookupByLibrary.simpleMessage(
      "Nobody has priced it",
    ),
    "sales_detail_untaxed": MessageLookupByLibrary.simpleMessage(
      "Nothing has been rung up",
    ),
    "sales_detail_updated": MessageLookupByLibrary.simpleMessage(
      "Last movement",
    ),
    "sales_empty_done_subtitle": MessageLookupByLibrary.simpleMessage(
      "A sale lands here once the money has arrived and the customer has the goods.",
    ),
    "sales_empty_done_title": MessageLookupByLibrary.simpleMessage(
      "No sale finished yet",
    ),
    "sales_empty_filter_subtitle": MessageLookupByLibrary.simpleMessage(
      "Nothing is at that state, or came in through that channel.",
    ),
    "sales_empty_filter_title": MessageLookupByLibrary.simpleMessage(
      "No sale matches",
    ),
    "sales_empty_process_subtitle": MessageLookupByLibrary.simpleMessage(
      "No sale is waiting on anybody: nothing to charge, nothing to verify, nothing to hand over.",
    ),
    "sales_empty_process_title": MessageLookupByLibrary.simpleMessage(
      "Nothing pending",
    ),
    "sales_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Check the connection and try again.",
    ),
    "sales_error_title": MessageLookupByLibrary.simpleMessage(
      "The sales could not be read",
    ),
    "sales_handover_action": MessageLookupByLibrary.simpleMessage(
      "Record the handover",
    ),
    "sales_handover_mode": MessageLookupByLibrary.simpleMessage(
      "How they get it",
    ),
    "sales_handover_mode_error": MessageLookupByLibrary.simpleMessage(
      "Choose how the customer gets it",
    ),
    "sales_handover_mode_placeholder": MessageLookupByLibrary.simpleMessage(
      "Handed over, collected or delivered",
    ),
    "sales_handover_note": MessageLookupByLibrary.simpleMessage("Note"),
    "sales_handover_note_placeholder": MessageLookupByLibrary.simpleMessage(
      "A tracking number, who collected it",
    ),
    "sales_handover_same_error": MessageLookupByLibrary.simpleMessage(
      "That is what the sale already says",
    ),
    "sales_handover_save": MessageLookupByLibrary.simpleMessage("Record"),
    "sales_handover_saved": MessageLookupByLibrary.simpleMessage(
      "Handover recorded",
    ),
    "sales_handover_state": MessageLookupByLibrary.simpleMessage(
      "Where it got to",
    ),
    "sales_handover_state_placeholder": MessageLookupByLibrary.simpleMessage(
      "Not sent, dispatched or delivered",
    ),
    "sales_handover_subtitle": MessageLookupByLibrary.simpleMessage(
      "Say how the customer gets this sale and how far that got. Nobody else can: the shelf knows the units left and the ticket knows the money arrived, but only a person knows whether the delivery went out or the customer came for it.",
    ),
    "sales_handover_title": MessageLookupByLibrary.simpleMessage("Handover"),
    "sales_mine": MessageLookupByLibrary.simpleMessage("Sold by me"),
    "sales_more": MessageLookupByLibrary.simpleMessage("Load more"),
    "sales_pending": m122,
    "sales_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "sales_search_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Nothing read so far carries that ticket code, customer or seller. The sale may be further down: load more and search again.",
    ),
    "sales_search_empty_title": MessageLookupByLibrary.simpleMessage(
      "No sale matches the search",
    ),
    "sales_search_scope": MessageLookupByLibrary.simpleMessage(
      "The search narrows the sales already read, by ticket code, customer and seller.",
    ),
    "sales_select_empty": MessageLookupByLibrary.simpleMessage(
      "Nothing to choose from",
    ),
    "sales_tab_done": MessageLookupByLibrary.simpleMessage("Completed"),
    "sales_tab_process": MessageLookupByLibrary.simpleMessage("In progress"),
    "sales_tickets_only": MessageLookupByLibrary.simpleMessage(
      "Filtering by channel or by seller answers with tickets only: a conversation the assistant is still holding has neither.",
    ),
    "sales_wait_days": m123,
    "sales_wait_hours": m124,
    "sales_wait_minutes": m125,
    "sales_wait_now": MessageLookupByLibrary.simpleMessage("just now"),
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "search_in_app": MessageLookupByLibrary.simpleMessage("Search in the app"),
    "search_subscription": MessageLookupByLibrary.simpleMessage(
      "Search for a subscription",
    ),
    "section_connections": MessageLookupByLibrary.simpleMessage("Connections"),
    "section_needs_internet_subtitle": MessageLookupByLibrary.simpleMessage(
      "This section works through the cloud. It comes back as soon as the connection does.",
    ),
    "section_needs_internet_title": MessageLookupByLibrary.simpleMessage(
      "Needs the internet",
    ),
    "section_no_business_subtitle": MessageLookupByLibrary.simpleMessage(
      "Create your business to start using this section.",
    ),
    "section_no_business_title": MessageLookupByLibrary.simpleMessage(
      "No business yet",
    ),
    "section_no_permission": MessageLookupByLibrary.simpleMessage(
      "You don\'t have access to this section in this business.",
    ),
    "section_products": MessageLookupByLibrary.simpleMessage("Products"),
    "section_reports": MessageLookupByLibrary.simpleMessage("Reports"),
    "section_transactions": MessageLookupByLibrary.simpleMessage(
      "Transactions",
    ),
    "section_unavailable_subtitle": MessageLookupByLibrary.simpleMessage(
      "This section is not part of Lyra on a local network.",
    ),
    "section_unavailable_title": MessageLookupByLibrary.simpleMessage(
      "Not available here",
    ),
    "select_a_service": MessageLookupByLibrary.simpleMessage(
      "Select a service",
    ),
    "services": MessageLookupByLibrary.simpleMessage("Services"),
    "session_expired": MessageLookupByLibrary.simpleMessage(
      "Your session ended. Sign in again to continue.",
    ),
    "shop": MessageLookupByLibrary.simpleMessage("Shop"),
    "sign_out": MessageLookupByLibrary.simpleMessage("Sign out"),
    "sign_out_failed": MessageLookupByLibrary.simpleMessage(
      "Could not sign out. Check your connection and try again.",
    ),
    "sign_up_code_subtitle": m126,
    "sign_up_code_title": MessageLookupByLibrary.simpleMessage(
      "Create your account",
    ),
    "sign_up_email_title": MessageLookupByLibrary.simpleMessage(
      "Email address",
    ),
    "sign_up_first_name_title": MessageLookupByLibrary.simpleMessage(
      "First name",
    ),
    "sign_up_last_name_title": MessageLookupByLibrary.simpleMessage(
      "Last name",
    ),
    "sign_up_password_title": MessageLookupByLibrary.simpleMessage(
      "Create a new password",
    ),
    "sign_up_step_code": MessageLookupByLibrary.simpleMessage(
      "Code from your email",
    ),
    "sign_up_step_code_hint": MessageLookupByLibrary.simpleMessage(
      "Not there? Check your spam folder.",
    ),
    "sign_up_step_name": MessageLookupByLibrary.simpleMessage("Your name"),
    "sign_up_step_name_hint": MessageLookupByLibrary.simpleMessage(
      "Your team sees it next to everything you do.",
    ),
    "sign_up_terms_link": MessageLookupByLibrary.simpleMessage(
      "Terms and Conditions",
    ),
    "stock_move_add_action": MessageLookupByLibrary.simpleMessage("Add"),
    "stock_move_add_hint": MessageLookupByLibrary.simpleMessage("Add units"),
    "stock_move_add_reserved": MessageLookupByLibrary.simpleMessage(
      "Reserve units",
    ),
    "stock_move_add_stock": MessageLookupByLibrary.simpleMessage(
      "Add to stock",
    ),
    "stock_move_available": m127,
    "stock_move_dest_leave": MessageLookupByLibrary.simpleMessage("They leave"),
    "stock_move_dest_leave_hint": MessageLookupByLibrary.simpleMessage(
      "Sold, damaged, lost or miscounted: they are not coming back.",
    ),
    "stock_move_dest_reserve": MessageLookupByLibrary.simpleMessage(
      "To reservations",
    ),
    "stock_move_dest_reserve_hint": MessageLookupByLibrary.simpleMessage(
      "Held for someone. They stop being available to sell.",
    ),
    "stock_move_dest_returns": MessageLookupByLibrary.simpleMessage(
      "To returns",
    ),
    "stock_move_dest_returns_hint": MessageLookupByLibrary.simpleMessage(
      "Units a customer brought back. They wait there until somebody checks them.",
    ),
    "stock_move_destination": MessageLookupByLibrary.simpleMessage(
      "What happens with them",
    ),
    "stock_move_note": MessageLookupByLibrary.simpleMessage("Note"),
    "stock_move_note_placeholder": MessageLookupByLibrary.simpleMessage(
      "Explain the movement for whoever audits it later",
    ),
    "stock_move_quantity": MessageLookupByLibrary.simpleMessage("Quantity"),
    "stock_move_quantity_error": m128,
    "stock_move_quantity_error_free": MessageLookupByLibrary.simpleMessage(
      "Enter a whole number greater than zero",
    ),
    "stock_move_quantity_placeholder": MessageLookupByLibrary.simpleMessage(
      "How many units",
    ),
    "stock_move_reason": MessageLookupByLibrary.simpleMessage("Reason"),
    "stock_move_reason_empty": MessageLookupByLibrary.simpleMessage(
      "No reasons",
    ),
    "stock_move_reason_placeholder": MessageLookupByLibrary.simpleMessage(
      "Pick one",
    ),
    "stock_move_release_hint": MessageLookupByLibrary.simpleMessage(
      "They go back on sale.",
    ),
    "stock_move_reserved": m129,
    "stock_move_saved": MessageLookupByLibrary.simpleMessage("Stock updated"),
    "stock_move_step_less": m130,
    "stock_move_step_more": m131,
    "stock_move_take_action": MessageLookupByLibrary.simpleMessage("Take out"),
    "stock_move_take_hint": MessageLookupByLibrary.simpleMessage(
      "Take units out",
    ),
    "stock_move_take_reserved": MessageLookupByLibrary.simpleMessage(
      "Release reservations",
    ),
    "stock_move_take_stock": MessageLookupByLibrary.simpleMessage(
      "Take out of stock",
    ),
    "stock_reason_cancelled": MessageLookupByLibrary.simpleMessage(
      "Customer cancelled",
    ),
    "stock_reason_correction": MessageLookupByLibrary.simpleMessage(
      "Count correction",
    ),
    "stock_reason_customer": MessageLookupByLibrary.simpleMessage(
      "Customer return",
    ),
    "stock_reason_damage": MessageLookupByLibrary.simpleMessage("Damaged"),
    "stock_reason_defective": MessageLookupByLibrary.simpleMessage("Defective"),
    "stock_reason_expiration": MessageLookupByLibrary.simpleMessage("Expired"),
    "stock_reason_hold_expired": MessageLookupByLibrary.simpleMessage(
      "The hold ran out",
    ),
    "stock_reason_loss": MessageLookupByLibrary.simpleMessage("Lost"),
    "stock_reason_reintegration": MessageLookupByLibrary.simpleMessage(
      "Back on sale",
    ),
    "stock_reason_restock": MessageLookupByLibrary.simpleMessage("Restock"),
    "stock_reason_return_approved": MessageLookupByLibrary.simpleMessage(
      "Approved return",
    ),
    "stock_reason_sale": MessageLookupByLibrary.simpleMessage("Sale"),
    "stock_reason_theft": MessageLookupByLibrary.simpleMessage("Theft"),
    "stock_reason_warranty": MessageLookupByLibrary.simpleMessage("Warranty"),
    "stock_reason_wrong_item": MessageLookupByLibrary.simpleMessage(
      "Wrong item",
    ),
    "stock_summary_count": m132,
    "stock_summary_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "The products of your main table show up here, with what\'s left of each one.",
    ),
    "stock_summary_empty_title": MessageLookupByLibrary.simpleMessage(
      "Nothing to count yet",
    ),
    "stock_summary_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "Something went wrong. Please try again.",
    ),
    "stock_summary_error_title": MessageLookupByLibrary.simpleMessage(
      "Couldn\'t load your stock",
    ),
    "stock_summary_performance": MessageLookupByLibrary.simpleMessage(
      "Performance",
    ),
    "stock_summary_reserved": MessageLookupByLibrary.simpleMessage("Reserved"),
    "stock_summary_retry": MessageLookupByLibrary.simpleMessage("Try again"),
    "stock_summary_search_empty": MessageLookupByLibrary.simpleMessage(
      "No products match your search",
    ),
    "stock_summary_stock": MessageLookupByLibrary.simpleMessage("Stock"),
    "stock_summary_title": MessageLookupByLibrary.simpleMessage(
      "Stock summary",
    ),
    "subscription_details_delete": MessageLookupByLibrary.simpleMessage(
      "Delete subscription",
    ),
    "subscription_details_domain": MessageLookupByLibrary.simpleMessage(
      "Domain",
    ),
    "subscription_details_next_billing": MessageLookupByLibrary.simpleMessage(
      "Next billing",
    ),
    "subscription_details_no": MessageLookupByLibrary.simpleMessage("No"),
    "subscription_details_overdue": MessageLookupByLibrary.simpleMessage(
      "Overdue",
    ),
    "subscription_details_section_about": MessageLookupByLibrary.simpleMessage(
      "About",
    ),
    "subscription_details_section_billing":
        MessageLookupByLibrary.simpleMessage("Billing"),
    "subscription_details_section_details":
        MessageLookupByLibrary.simpleMessage("Details"),
    "subscription_details_service_id": MessageLookupByLibrary.simpleMessage(
      "Service ID",
    ),
    "subscription_details_synced": MessageLookupByLibrary.simpleMessage(
      "Synced",
    ),
    "subscription_details_yes": MessageLookupByLibrary.simpleMessage("Yes"),
    "summary_date": MessageLookupByLibrary.simpleMessage("Billing date"),
    "summary_period": MessageLookupByLibrary.simpleMessage("Period"),
    "summary_price": MessageLookupByLibrary.simpleMessage("Price"),
    "summary_service": MessageLookupByLibrary.simpleMessage("Service"),
    "summary_title": MessageLookupByLibrary.simpleMessage("All set!"),
    "table_color_title": MessageLookupByLibrary.simpleMessage("Color"),
    "table_created": MessageLookupByLibrary.simpleMessage("Table created"),
    "table_delete_message": m133,
    "table_delete_title": MessageLookupByLibrary.simpleMessage(
      "Delete this table?",
    ),
    "table_deleted": MessageLookupByLibrary.simpleMessage("Table deleted"),
    "table_description_placeholder": MessageLookupByLibrary.simpleMessage(
      "What does this table contain?",
    ),
    "table_description_title": MessageLookupByLibrary.simpleMessage(
      "Description (optional)",
    ),
    "table_field_count": m134,
    "table_field_delete_confirm": MessageLookupByLibrary.simpleMessage(
      "Delete field",
    ),
    "table_field_delete_message": m135,
    "table_field_delete_title": MessageLookupByLibrary.simpleMessage(
      "Delete this field?",
    ),
    "table_field_name_placeholder": MessageLookupByLibrary.simpleMessage(
      "Name of the field",
    ),
    "table_field_name_title": MessageLookupByLibrary.simpleMessage(
      "Field name",
    ),
    "table_field_option_create": MessageLookupByLibrary.simpleMessage(
      "New option",
    ),
    "table_field_option_empty": MessageLookupByLibrary.simpleMessage(
      "No option matches your search",
    ),
    "table_field_option_none": MessageLookupByLibrary.simpleMessage("No value"),
    "table_field_option_placeholder": MessageLookupByLibrary.simpleMessage(
      "Name of the option",
    ),
    "table_field_option_search": MessageLookupByLibrary.simpleMessage(
      "Search options",
    ),
    "table_field_remove": MessageLookupByLibrary.simpleMessage("Remove field"),
    "table_field_reorder": MessageLookupByLibrary.simpleMessage(
      "Drag to reorder",
    ),
    "table_field_type_empty": MessageLookupByLibrary.simpleMessage(
      "No type matches your search",
    ),
    "table_field_type_placeholder": MessageLookupByLibrary.simpleMessage(
      "Type of information",
    ),
    "table_field_type_title": MessageLookupByLibrary.simpleMessage(
      "Field type",
    ),
    "table_fields_empty": MessageLookupByLibrary.simpleMessage(
      "No fields yet. Add the first one to define what each product stores.",
    ),
    "table_fields_required": MessageLookupByLibrary.simpleMessage(
      "Add at least one field before creating the table",
    ),
    "table_fields_subtitle": MessageLookupByLibrary.simpleMessage(
      "Each field is a column of the table. Its type tells the AI what information it holds and shapes how it is filled in when adding stock.",
    ),
    "table_fields_title": MessageLookupByLibrary.simpleMessage("Fields"),
    "table_normalize": MessageLookupByLibrary.simpleMessage(
      "Normalize columns",
    ),
    "table_normalize_confirm": MessageLookupByLibrary.simpleMessage(
      "Normalize",
    ),
    "table_normalize_message": MessageLookupByLibrary.simpleMessage(
      "We read a sample of every column and give it the type it should have — a price that compares as a number, a date that sorts, a description the AI can search by meaning — and set how much of each one a bot may see. Columns you already typed or marked yourself are left alone.",
    ),
    "table_normalize_narrowed": m136,
    "table_normalize_none": MessageLookupByLibrary.simpleMessage(
      "Every column was already right",
    ),
    "table_normalize_renamed": m137,
    "table_normalize_retyped": m138,
    "table_normalize_running": MessageLookupByLibrary.simpleMessage(
      "Normalizing this table",
    ),
    "table_normalize_summarized": m139,
    "table_normalize_title": MessageLookupByLibrary.simpleMessage(
      "Normalize this table?",
    ),
    "table_options": MessageLookupByLibrary.simpleMessage("Table options"),
    "table_primary": MessageLookupByLibrary.simpleMessage("Primary"),
    "table_primary_hint": MessageLookupByLibrary.simpleMessage(
      "Your main table. The stock summary always reads this one, so it\'s the table whose columns show up below.",
    ),
    "table_record_count": m140,
    "table_renamed": MessageLookupByLibrary.simpleMessage("Table renamed"),
    "table_settings_add": m141,
    "table_settings_agent_filterable": MessageLookupByLibrary.simpleMessage(
      "Filterable columns",
    ),
    "table_settings_agent_filterable_hint":
        MessageLookupByLibrary.simpleMessage(
          "What the AI can filter and sort by: every column it\'s told exists",
        ),
    "table_settings_agent_image": MessageLookupByLibrary.simpleMessage(
      "Images",
    ),
    "table_settings_agent_image_off": MessageLookupByLibrary.simpleMessage(
      "No image column",
    ),
    "table_settings_agent_image_on": MessageLookupByLibrary.simpleMessage(
      "The AI can send pictures of these records",
    ),
    "table_settings_agent_searchable": MessageLookupByLibrary.simpleMessage(
      "Search by meaning",
    ),
    "table_settings_agent_searchable_off": MessageLookupByLibrary.simpleMessage(
      "No column is indexed by meaning: the AI can filter this table, but it can\'t be asked for something described in words",
    ),
    "table_settings_agent_searchable_on": MessageLookupByLibrary.simpleMessage(
      "A column is indexed by meaning, so the AI can be asked for something described in words",
    ),
    "table_settings_agent_stock": MessageLookupByLibrary.simpleMessage("Stock"),
    "table_settings_agent_stock_off": MessageLookupByLibrary.simpleMessage(
      "No stock column, so nothing here is counted against inventory",
    ),
    "table_settings_agent_stock_on": MessageLookupByLibrary.simpleMessage(
      "A stock column ties this table to the inventory ledger, so the AI can also reserve products",
    ),
    "table_settings_agent_subtitle": MessageLookupByLibrary.simpleMessage(
      "How much of this table a bot reading it can use",
    ),
    "table_settings_agent_title": MessageLookupByLibrary.simpleMessage(
      "What the AI sees",
    ),
    "table_settings_agent_visibility": MessageLookupByLibrary.simpleMessage(
      "Visibility",
    ),
    "table_settings_agent_visibility_hint": MessageLookupByLibrary.simpleMessage(
      "How many columns the AI can quote, use without saying, or doesn\'t know about",
    ),
    "table_settings_available": MessageLookupByLibrary.simpleMessage(
      "Available",
    ),
    "table_settings_channels_linked": MessageLookupByLibrary.simpleMessage(
      "Chose this table",
    ),
    "table_settings_channels_none": MessageLookupByLibrary.simpleMessage(
      "No bot reads this table",
    ),
    "table_settings_channels_none_hint": MessageLookupByLibrary.simpleMessage(
      "Pick it as a channel\'s data source to have that bot answer with it",
    ),
    "table_settings_channels_open": MessageLookupByLibrary.simpleMessage(
      "Read every table",
    ),
    "table_settings_channels_open_hint": MessageLookupByLibrary.simpleMessage(
      "These bots have no data source configured, so they read every table this business has — including this one, without anybody having chosen it",
    ),
    "table_settings_channels_subtitle": MessageLookupByLibrary.simpleMessage(
      "The bots answering with this table",
    ),
    "table_settings_channels_title": MessageLookupByLibrary.simpleMessage(
      "Connected channels",
    ),
    "table_settings_column_count": m142,
    "table_settings_column_field": MessageLookupByLibrary.simpleMessage(
      "Column",
    ),
    "table_settings_column_options": MessageLookupByLibrary.simpleMessage(
      "Options",
    ),
    "table_settings_column_summary": MessageLookupByLibrary.simpleMessage(
      "Inventory summary",
    ),
    "table_settings_column_summary_hide": MessageLookupByLibrary.simpleMessage(
      "Leave this column out of the inventory summary",
    ),
    "table_settings_column_summary_off": MessageLookupByLibrary.simpleMessage(
      "Excluded",
    ),
    "table_settings_column_summary_on": MessageLookupByLibrary.simpleMessage(
      "Shown",
    ),
    "table_settings_column_summary_show": MessageLookupByLibrary.simpleMessage(
      "Show this column in the inventory summary",
    ),
    "table_settings_column_type": MessageLookupByLibrary.simpleMessage("Type"),
    "table_settings_column_unit": MessageLookupByLibrary.simpleMessage("Unit"),
    "table_settings_column_visibility": MessageLookupByLibrary.simpleMessage(
      "Visibility",
    ),
    "table_settings_columns_empty": MessageLookupByLibrary.simpleMessage(
      "This table has no columns yet. Write a title in the first free column of the sheet to create one",
    ),
    "table_settings_columns_subtitle": MessageLookupByLibrary.simpleMessage(
      "What each one holds, how much of it the AI sees and which ones the inventory summary shows. All of it is changed right here",
    ),
    "table_settings_columns_summary_count": m143,
    "table_settings_columns_title": MessageLookupByLibrary.simpleMessage(
      "Columns",
    ),
    "table_settings_created": MessageLookupByLibrary.simpleMessage("Created"),
    "table_settings_dates_subtitle": MessageLookupByLibrary.simpleMessage(
      "A table has two: when its structure last changed and when data last arrived",
    ),
    "table_settings_dates_title": MessageLookupByLibrary.simpleMessage("Dates"),
    "table_settings_description": MessageLookupByLibrary.simpleMessage(
      "Description",
    ),
    "table_settings_description_empty": MessageLookupByLibrary.simpleMessage(
      "No description",
    ),
    "table_settings_edit": m144,
    "table_settings_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "It may have been deleted, or it belongs to another business",
    ),
    "table_settings_error_title": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t open this table",
    ),
    "table_settings_id": MessageLookupByLibrary.simpleMessage("Identifier"),
    "table_settings_id_copied": MessageLookupByLibrary.simpleMessage(
      "Identifier copied",
    ),
    "table_settings_id_copy": MessageLookupByLibrary.simpleMessage(
      "Copy identifier",
    ),
    "table_settings_id_hide": MessageLookupByLibrary.simpleMessage(
      "Hide identifier",
    ),
    "table_settings_id_hint": MessageLookupByLibrary.simpleMessage(
      "The id this table travels under. You\'ll need it to point anything outside the app at it",
    ),
    "table_settings_id_show": MessageLookupByLibrary.simpleMessage(
      "Show identifier",
    ),
    "table_settings_last_record": MessageLookupByLibrary.simpleMessage(
      "Last record",
    ),
    "table_settings_last_record_hint": MessageLookupByLibrary.simpleMessage(
      "When a row was last stored. Editing an existing row doesn\'t move it",
    ),
    "table_settings_name": MessageLookupByLibrary.simpleMessage("Title"),
    "table_settings_name_hint": MessageLookupByLibrary.simpleMessage(
      "What this table is called everywhere it shows up: the listing, the sheet header and whatever a bot says about it",
    ),
    "table_settings_no_records": MessageLookupByLibrary.simpleMessage(
      "No records yet",
    ),
    "table_settings_options": m145,
    "table_settings_options_empty": MessageLookupByLibrary.simpleMessage(
      "No options yet",
    ),
    "table_settings_pick_options": MessageLookupByLibrary.simpleMessage(
      "The options this column offers",
    ),
    "table_settings_pick_type": MessageLookupByLibrary.simpleMessage(
      "Change what this column holds",
    ),
    "table_settings_pick_unit": MessageLookupByLibrary.simpleMessage(
      "The symbol this column\'s numbers are written in",
    ),
    "table_settings_pick_visibility": MessageLookupByLibrary.simpleMessage(
      "Change how much the AI sees of this column",
    ),
    "table_settings_records_unknown_hint": MessageLookupByLibrary.simpleMessage(
      "The rows live in a different database than the columns, so the count can fail on its own. It doesn\'t mean the table is empty",
    ),
    "table_settings_refresh": MessageLookupByLibrary.simpleMessage("Refresh"),
    "table_settings_stat_channels": MessageLookupByLibrary.simpleMessage(
      "Channels",
    ),
    "table_settings_stat_columns": MessageLookupByLibrary.simpleMessage(
      "Columns",
    ),
    "table_settings_stat_records": MessageLookupByLibrary.simpleMessage(
      "Records",
    ),
    "table_settings_summary_subtitle": MessageLookupByLibrary.simpleMessage(
      "What this table holds and how big it is",
    ),
    "table_settings_summary_title": MessageLookupByLibrary.simpleMessage(
      "Table",
    ),
    "table_settings_title": MessageLookupByLibrary.simpleMessage(
      "Table settings",
    ),
    "table_settings_type_count": m146,
    "table_settings_types": MessageLookupByLibrary.simpleMessage("Types"),
    "table_settings_unavailable": MessageLookupByLibrary.simpleMessage(
      "Not available",
    ),
    "table_settings_unit_create": MessageLookupByLibrary.simpleMessage(
      "Set unit",
    ),
    "table_settings_unit_empty": MessageLookupByLibrary.simpleMessage(
      "No unit",
    ),
    "table_settings_unit_none": MessageLookupByLibrary.simpleMessage(
      "Without unit",
    ),
    "table_settings_unit_placeholder": MessageLookupByLibrary.simpleMessage(
      "USD, Bs., kg",
    ),
    "table_settings_unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "table_settings_untyped": m147,
    "table_settings_untyped_hint": MessageLookupByLibrary.simpleMessage(
      "A column imported from a file is born as text. Giving it its real type is what lets the AI compare it, filter by it and quote it properly. You can change it in the Type column below",
    ),
    "table_settings_updated": MessageLookupByLibrary.simpleMessage(
      "Structure updated",
    ),
    "table_settings_updated_hint": MessageLookupByLibrary.simpleMessage(
      "The last change to the table or to any of its columns. Renaming a column or changing its type counts, and neither touches the rows",
    ),
    "table_template_accessories": MessageLookupByLibrary.simpleMessage(
      "Accessories",
    ),
    "table_template_appliances": MessageLookupByLibrary.simpleMessage(
      "Home appliances",
    ),
    "table_template_beauty": MessageLookupByLibrary.simpleMessage(
      "Beauty & personal care",
    ),
    "table_template_blank": MessageLookupByLibrary.simpleMessage(
      "Blank template",
    ),
    "table_template_clothing": MessageLookupByLibrary.simpleMessage("Clothing"),
    "table_template_electronics": MessageLookupByLibrary.simpleMessage(
      "Smartphones & electronics",
    ),
    "table_template_empty": MessageLookupByLibrary.simpleMessage(
      "No template matches your search",
    ),
    "table_template_food": MessageLookupByLibrary.simpleMessage(
      "Food & beverages",
    ),
    "table_template_health": MessageLookupByLibrary.simpleMessage("Health"),
    "table_template_home": MessageLookupByLibrary.simpleMessage("Home & decor"),
    "table_template_placeholder": MessageLookupByLibrary.simpleMessage(
      "Choose a template",
    ),
    "table_template_shoes": MessageLookupByLibrary.simpleMessage("Shoes"),
    "table_template_title": MessageLookupByLibrary.simpleMessage("Template"),
    "table_title_input": MessageLookupByLibrary.simpleMessage("Title"),
    "table_title_placeholder": MessageLookupByLibrary.simpleMessage(
      "Name of the table",
    ),
    "title": MessageLookupByLibrary.simpleMessage("Title"),
    "title_of_subscription": MessageLookupByLibrary.simpleMessage(
      "Title of subscription",
    ),
    "total_expenses": MessageLookupByLibrary.simpleMessage("Total Expenses"),
    "trial_duration": MessageLookupByLibrary.simpleMessage("Duration"),
    "trial_period": MessageLookupByLibrary.simpleMessage("Trial period"),
    "trial_price": MessageLookupByLibrary.simpleMessage("Trial price"),
    "upcoming": MessageLookupByLibrary.simpleMessage("Upcoming"),
    "verify_code_change_email": MessageLookupByLibrary.simpleMessage("Change"),
    "verify_code_continue": MessageLookupByLibrary.simpleMessage("Continue"),
    "verify_code_continue_with_password": MessageLookupByLibrary.simpleMessage(
      "Continue and create a password",
    ),
    "verify_code_inbox_subtitle": m148,
    "verify_code_inbox_title": MessageLookupByLibrary.simpleMessage(
      "Check your inbox",
    ),
    "verify_code_not_received": MessageLookupByLibrary.simpleMessage(
      "Didn\'t get it?",
    ),
    "verify_code_password_notice": MessageLookupByLibrary.simpleMessage(
      "A password isn\'t required, but we recommend creating one. Your account will be as secure as you want it to be: we offer several ways to protect it, and you decide how far to go.",
    ),
    "verify_code_resend_in": m149,
    "verify_code_signing_in": MessageLookupByLibrary.simpleMessage(
      "Signing you in…",
    ),
    "verify_code_subtitle": MessageLookupByLibrary.simpleMessage(
      "Enter the code we sent to your email address",
    ),
    "version": MessageLookupByLibrary.simpleMessage("Version"),
    "wallet": MessageLookupByLibrary.simpleMessage("Wallet"),
    "weekly": MessageLookupByLibrary.simpleMessage("Weekly"),
    "welcome_awaiting_body": MessageLookupByLibrary.simpleMessage(
      "Ask the company to invite you with this email. The invitation will show up on this page as soon as they send it.",
    ),
    "welcome_awaiting_modal_title": MessageLookupByLibrary.simpleMessage(
      "Waiting for an invitation",
    ),
    "welcome_awaiting_subtitle": MessageLookupByLibrary.simpleMessage(
      "Your company already uses Lyra. See how to ask them to add you.",
    ),
    "welcome_awaiting_title": MessageLookupByLibrary.simpleMessage(
      "Join my company\'s team",
    ),
    "welcome_create_action": MessageLookupByLibrary.simpleMessage(
      "Create company",
    ),
    "welcome_create_subtitle": MessageLookupByLibrary.simpleMessage(
      "Register your first company and manage it from here.",
    ),
    "welcome_create_title": MessageLookupByLibrary.simpleMessage(
      "Create a company",
    ),
    "welcome_invitation_accept": MessageLookupByLibrary.simpleMessage(
      "Accept invitation",
    ),
    "welcome_invitation_accept_notice": m150,
    "welcome_invitation_action": MessageLookupByLibrary.simpleMessage("Review"),
    "welcome_invitation_branch": MessageLookupByLibrary.simpleMessage("Branch"),
    "welcome_invitation_company": MessageLookupByLibrary.simpleMessage(
      "Company",
    ),
    "welcome_invitation_date": MessageLookupByLibrary.simpleMessage(
      "Invited on",
    ),
    "welcome_invitation_department": MessageLookupByLibrary.simpleMessage(
      "Department",
    ),
    "welcome_invitation_job": m151,
    "welcome_invitation_modal_title": MessageLookupByLibrary.simpleMessage(
      "Invitation",
    ),
    "welcome_invitation_role": MessageLookupByLibrary.simpleMessage("Position"),
    "welcome_invitation_subtitle": MessageLookupByLibrary.simpleMessage(
      "Review the invitation to join their team.",
    ),
    "welcome_invitation_title": m152,
    "welcome_jobs_body": MessageLookupByLibrary.simpleMessage(
      "Job openings are coming soon. You will be able to browse them and apply from here.",
    ),
    "welcome_jobs_modal_title": MessageLookupByLibrary.simpleMessage(
      "Open jobs",
    ),
    "welcome_jobs_soon": MessageLookupByLibrary.simpleMessage("Coming soon"),
    "welcome_jobs_subtitle": MessageLookupByLibrary.simpleMessage(
      "See the positions companies have open and apply to one.",
    ),
    "welcome_jobs_title": MessageLookupByLibrary.simpleMessage(
      "Browse open jobs",
    ),
    "welcome_other_ways": MessageLookupByLibrary.simpleMessage(
      "Or start another way",
    ),
    "welcome_subtitle": MessageLookupByLibrary.simpleMessage(
      "Lyra works around a company. Tell us how you want to start: you can change your mind later.",
    ),
    "welcome_title": m153,
    "write_a_description": MessageLookupByLibrary.simpleMessage(
      "Optional description...",
    ),
    "write_a_name": MessageLookupByLibrary.simpleMessage("Write a name"),
    "write_here": MessageLookupByLibrary.simpleMessage("Write here..."),
    "you_decide": MessageLookupByLibrary.simpleMessage("You decide"),
  };
}
