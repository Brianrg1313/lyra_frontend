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

  static String m0(error) => "Couldn\'t link WhatsApp: ${error}";

  static String m1(days) => "in ${days} days";

  static String m2(days) => "Every ${days} days";

  static String m3(day) => "Day ${day}";

  static String m4(name) =>
      "${name} and everything tied to it start the 60 days: 30 before the deletion period begins, and 30 more until nothing of it is left.";

  static String m5(email) =>
      "${email} stops being one of the addresses this business can be written to. If it\'s the primary one, the oldest of the rest takes its place.";

  static String m6(field) => "Add ${field}";

  static String m7(field) => "Edit ${field}";

  static String m8(provider) =>
      "What ${provider} needs to connect. You can save the channel without them and paste them later";

  static String m9(name) =>
      "Disconnecting ${name} deletes the tokens stored for it. The account can be connected again, but you\'ll have to set it up from scratch.";

  static String m10(count) =>
      "${Intl.plural(count, zero: 'No bots', one: '1 bot', other: '${count} bots')}";

  static String m11(provider) =>
      "What ${provider} needs to connect. You can save the account without them and paste them later";

  static String m12(count) =>
      "${Intl.plural(count, one: 'The bot answering through it is deleted too — pause the account instead to keep it.', other: 'The ${count} bots answering through it are deleted too — pause the account instead to keep them.')}";

  static String m13(name) =>
      "Disconnecting ${name} deletes the credentials stored for it. The account can be connected again, but you\'ll have to set it up from scratch.";

  static String m14(conversations, messages) =>
      "${conversations} conversations · ${messages} replies";

  static String m15(currency) =>
      "What Lyra, the bot that answers your customers, cost to run — billed in ${currency}. It is measured and not recorded, so it is not part of the money above.";

  static String m16(count) => "${count} runs";

  static String m17(name) =>
      "${name} stops being offered. The payments already recorded through it stay in the history.";

  static String m18(count) => "Load ${count} more";

  static String m19(count) => "${count} movements";

  static String m20(amount) =>
      "The payment of ${amount} stops counting, but stays in the history. It cannot be undone: a mistake is voided and recorded again.";

  static String m21(from, to) => "From ${from} to ${to}";

  static String m22(email) => "The ${email} is empty";

  static String m23(email) => "The ${email} is incomplete";

  static String m24(email) => "The ${email} is invalid";

  static String m25(email) => "The ${email} is very long";

  static String m26(ticket) => "Ticket ${ticket} charged";

  static String m27(count) =>
      "${Intl.plural(count, zero: 'Out of stock', one: '1 left', other: '${count} left')}";

  static String m28(count) =>
      "${Intl.plural(count, zero: 'No sales today', one: '1 sale today', other: '${count} sales today')}";

  static String m29(price) => "${price} each";

  static String m30(number) => "Ticket #${number}";

  static String m31(product) =>
      "The units of ${product} were released from the stock screen and are no longer set aside for this ticket";

  static String m32(rate) => "VAT ${rate}%";

  static String m33(count) =>
      "${Intl.plural(count, zero: 'Nothing on it yet', one: '1 product', other: '${count} products')}";

  static String m34(page) => "Page ${page}";

  static String m35(count) =>
      "${Intl.plural(count, zero: 'No rows match your search', one: '1 row matches', other: '${count} rows match')}";

  static String m36(time) => "Resend code in ${time}";

  static String m37(count) => "${count} sales";

  static String m38(count) => "${count} units";

  static String m39(count) => "${count} left";

  static String m40(count) => "${count} held";

  static String m41(price) => "was ${price}";

  static String m42(count) => "${count} no longer sold";

  static String m43(count) => "${count} said to be held, and nothing is";

  static String m44(count) => "${count} sent in all";

  static String m45(rate, base) => "${rate}% on ${base}";

  static String m46(count) => "${count} moved";

  static String m47(count) => "${count} d";

  static String m48(count) => "${count} h";

  static String m49(count) => "${count} min";

  static String m50(count) =>
      "${Intl.plural(count, zero: 'Nothing available right now', one: '1 unit available', other: '${count} units available')}";

  static String m51(max) => "Enter a whole number between 1 and ${max}";

  static String m52(count) =>
      "${Intl.plural(count, zero: 'Nothing reserved right now', one: '1 unit reserved', other: '${count} units reserved')}";

  static String m53(count) =>
      "${Intl.plural(count, one: 'One less', other: '${count} less')}";

  static String m54(count) =>
      "${Intl.plural(count, one: 'One more', other: '${count} more')}";

  static String m55(count) =>
      "${Intl.plural(count, zero: 'No products', one: '1 product', other: '${count} products')}";

  static String m56(name) =>
      "Deleting ${name} removes its fields and everything stored in it. This can\'t be undone.";

  static String m57(count) =>
      "${Intl.plural(count, zero: 'No fields', one: '1 field', other: '${count} fields')}";

  static String m58(name) =>
      "Leaving the name empty deletes ${name} and everything stored in it. This can\'t be undone.";

  static String m59(count) =>
      "${Intl.plural(count, one: 'visibility set on 1 column', other: 'visibility set on ${count} columns')}";

  static String m60(count) =>
      "${Intl.plural(count, one: '1 column renamed', other: '${count} columns renamed')}";

  static String m61(count) =>
      "${Intl.plural(count, one: '1 column retyped', other: '${count} columns retyped')}";

  static String m62(count) =>
      "${Intl.plural(count, one: '1 column added to the summary', other: '${count} columns added to the summary')}";

  static String m63(count) =>
      "${Intl.plural(count, zero: 'No records', one: '1 record', other: '${count} records')}";

  static String m64(field) => "Add ${field}";

  static String m65(count) =>
      "${Intl.plural(count, zero: 'No columns', one: '1 column', other: '${count} columns')}";

  static String m66(count, total) =>
      "Inventory summary: ${count} of ${total} columns";

  static String m67(field) => "Edit ${field}";

  static String m68(count) =>
      "${Intl.plural(count, one: '1 option', other: '${count} options')}";

  static String m69(type, count) => "${type} · ${count}";

  static String m70(count) =>
      "${Intl.plural(count, one: '1 column is still plain text', other: '${count} columns are still plain text')}";

  final messages = _notInlinedMessages(_notInlinedMessages);
  static Map<String, Function> _notInlinedMessages(_) => <String, Function>{
        "a": MessageLookupByLibrary.simpleMessage("a"),
        "account": MessageLookupByLibrary.simpleMessage("Account"),
        "add": MessageLookupByLibrary.simpleMessage("Add"),
        "add_field": MessageLookupByLibrary.simpleMessage("Add field"),
        "add_field_subtitle": MessageLookupByLibrary.simpleMessage(
            "Add a column and choose the kind of information it holds"),
        "add_new_subscription":
            MessageLookupByLibrary.simpleMessage("Add new subscription"),
        "add_subscription":
            MessageLookupByLibrary.simpleMessage("Add subscription"),
        "already_have_account":
            MessageLookupByLibrary.simpleMessage("Already have an account?"),
        "amount": MessageLookupByLibrary.simpleMessage("Amount"),
        "annual": MessageLookupByLibrary.simpleMessage("Annual"),
        "back": MessageLookupByLibrary.simpleMessage("Back"),
        "baileys_pairing_connected":
            MessageLookupByLibrary.simpleMessage("WhatsApp linked"),
        "baileys_pairing_error": m0,
        "baileys_pairing_instructions": MessageLookupByLibrary.simpleMessage(
            "Open WhatsApp on your phone, go to Linked Devices and scan this code"),
        "baileys_pairing_title":
            MessageLookupByLibrary.simpleMessage("Link WhatsApp"),
        "baileys_pairing_waiting":
            MessageLookupByLibrary.simpleMessage("Preparing the QR code…"),
        "baileys_start_error": MessageLookupByLibrary.simpleMessage(
            "Couldn\'t start the WhatsApp service"),
        "baileys_status_connected":
            MessageLookupByLibrary.simpleMessage("Connected"),
        "baileys_status_error":
            MessageLookupByLibrary.simpleMessage("Connection error"),
        "baileys_status_logged_out":
            MessageLookupByLibrary.simpleMessage("Unlinked — scan a new QR"),
        "baileys_status_qr_pending":
            MessageLookupByLibrary.simpleMessage("Scan the QR to link"),
        "baileys_status_reconnecting":
            MessageLookupByLibrary.simpleMessage("Reconnecting…"),
        "baileys_status_starting":
            MessageLookupByLibrary.simpleMessage("Starting…"),
        "baileys_status_stopped": MessageLookupByLibrary.simpleMessage("Off"),
        "baileys_status_unknown": MessageLookupByLibrary.simpleMessage("Off"),
        "baileys_stop_error": MessageLookupByLibrary.simpleMessage(
            "Couldn\'t stop the WhatsApp service"),
        "baileys_unlink_action":
            MessageLookupByLibrary.simpleMessage("Unlink WhatsApp"),
        "baileys_unlink_error":
            MessageLookupByLibrary.simpleMessage("Couldn\'t unlink WhatsApp"),
        "baileys_unlink_explanation": MessageLookupByLibrary.simpleMessage(
            "Unlinking drops this computer\'s link to your phone. The channel stays exactly as it is — its role, its data and its place here — and turning it back on asks for a new QR code."),
        "baileys_unlink_message": MessageLookupByLibrary.simpleMessage(
            "This channel stops answering on WhatsApp until you scan a new QR code. Nothing you set up on it is lost."),
        "baileys_unlink_title":
            MessageLookupByLibrary.simpleMessage("Unlink this WhatsApp?"),
        "baileys_unlinked":
            MessageLookupByLibrary.simpleMessage("WhatsApp unlinked"),
        "billing_date_custom_label":
            MessageLookupByLibrary.simpleMessage("Date of first charge"),
        "billing_date_month_label":
            MessageLookupByLibrary.simpleMessage("Month"),
        "billing_date_monthday_label":
            MessageLookupByLibrary.simpleMessage("Day of the month"),
        "billing_date_title":
            MessageLookupByLibrary.simpleMessage("When do you get charged?"),
        "billing_date_weekday_label":
            MessageLookupByLibrary.simpleMessage("Day of the week"),
        "billing_day": MessageLookupByLibrary.simpleMessage("Day"),
        "billing_days_left": m1,
        "billing_label_custom": m2,
        "billing_label_monthly": m3,
        "billing_period":
            MessageLookupByLibrary.simpleMessage("Billing period"),
        "billing_today": MessageLookupByLibrary.simpleMessage("Today"),
        "business": MessageLookupByLibrary.simpleMessage("Business"),
        "business_branches_soon": MessageLookupByLibrary.simpleMessage(
            "The locations of this business, each with its address and what it handles, will be listed here."),
        "business_clients_soon": MessageLookupByLibrary.simpleMessage(
            "The customers of this business and what they bought will be listed here."),
        "business_delete_action":
            MessageLookupByLibrary.simpleMessage("Delete business"),
        "business_delete_confirm_message": m4,
        "business_delete_confirm_title":
            MessageLookupByLibrary.simpleMessage("Delete this business?"),
        "business_delete_schedule": MessageLookupByLibrary.simpleMessage(
            "It doesn\'t happen right away. The business waits 30 days before it enters the deletion period, and 30 more while it\'s being deleted."),
        "business_delete_section":
            MessageLookupByLibrary.simpleMessage("Delete business"),
        "business_delete_warning": MessageLookupByLibrary.simpleMessage(
            "Deleting this business erases everything tied to it: its profile, its people, its branches, its catalog, its customers and its history. None of it is kept."),
        "business_email_add":
            MessageLookupByLibrary.simpleMessage("Add address"),
        "business_email_address":
            MessageLookupByLibrary.simpleMessage("Email address"),
        "business_email_address_hint":
            MessageLookupByLibrary.simpleMessage("name@business.com"),
        "business_email_delete_message": m5,
        "business_email_delete_title":
            MessageLookupByLibrary.simpleMessage("Delete this address?"),
        "business_email_deleted":
            MessageLookupByLibrary.simpleMessage("Address deleted"),
        "business_email_edit_title":
            MessageLookupByLibrary.simpleMessage("Edit address"),
        "business_email_empty": MessageLookupByLibrary.simpleMessage(
            "This business has no email addresses yet."),
        "business_email_label": MessageLookupByLibrary.simpleMessage("Name"),
        "business_email_label_hint":
            MessageLookupByLibrary.simpleMessage("Billing Colombia"),
        "business_email_main": MessageLookupByLibrary.simpleMessage("Primary"),
        "business_email_promote":
            MessageLookupByLibrary.simpleMessage("Make primary"),
        "business_email_promoted":
            MessageLookupByLibrary.simpleMessage("Primary address updated"),
        "business_email_purpose":
            MessageLookupByLibrary.simpleMessage("Used for"),
        "business_email_purpose_billing":
            MessageLookupByLibrary.simpleMessage("Billing"),
        "business_email_purpose_billing_note":
            MessageLookupByLibrary.simpleMessage(
                "Where invoices, receipts and anything about a payment are sent."),
        "business_email_purpose_general":
            MessageLookupByLibrary.simpleMessage("General"),
        "business_email_purpose_general_note": MessageLookupByLibrary.simpleMessage(
            "The everyday address. Anything that doesn\'t belong to another one lands here."),
        "business_email_purpose_hr":
            MessageLookupByLibrary.simpleMessage("People"),
        "business_email_purpose_hr_note": MessageLookupByLibrary.simpleMessage(
            "Where job applications and anything about the people who work here arrive."),
        "business_email_purpose_legal":
            MessageLookupByLibrary.simpleMessage("Legal"),
        "business_email_purpose_legal_note":
            MessageLookupByLibrary.simpleMessage(
                "Where contracts, claims and formal notices are received."),
        "business_email_purpose_other":
            MessageLookupByLibrary.simpleMessage("Other"),
        "business_email_purpose_press":
            MessageLookupByLibrary.simpleMessage("Press"),
        "business_email_purpose_press_note":
            MessageLookupByLibrary.simpleMessage(
                "Where media and partners write about the business itself."),
        "business_email_purpose_sales":
            MessageLookupByLibrary.simpleMessage("Sales"),
        "business_email_purpose_sales_note":
            MessageLookupByLibrary.simpleMessage(
                "Where someone writes to buy, ask for a quote or start a deal."),
        "business_email_purpose_support":
            MessageLookupByLibrary.simpleMessage("Support"),
        "business_email_purpose_support_note": MessageLookupByLibrary.simpleMessage(
            "Where a customer writes when something doesn\'t work or they need help with a product or service."),
        "business_email_unverified":
            MessageLookupByLibrary.simpleMessage("Unverified"),
        "business_email_verified":
            MessageLookupByLibrary.simpleMessage("Verified"),
        "business_email_verified_done":
            MessageLookupByLibrary.simpleMessage("Address verified"),
        "business_email_verify": MessageLookupByLibrary.simpleMessage("Verify"),
        "business_email_verify_sent": MessageLookupByLibrary.simpleMessage(
            "We mailed a 6-digit code to this address. Type it in to prove the business reads it."),
        "business_email_verify_title":
            MessageLookupByLibrary.simpleMessage("Verify address"),
        "business_employees_error_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "Something went wrong. Please try again."),
        "business_employees_error_title":
            MessageLookupByLibrary.simpleMessage("Couldn\'t load the people"),
        "business_employees_soon": MessageLookupByLibrary.simpleMessage(
            "The people who work in this business, with their role and what each one can do, will be listed here."),
        "business_employees_total":
            MessageLookupByLibrary.simpleMessage("People with access"),
        "business_legal_name_input":
            MessageLookupByLibrary.simpleMessage("Legal name"),
        "business_list_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "Create your first business to start managing it here."),
        "business_list_empty_title":
            MessageLookupByLibrary.simpleMessage("No businesses yet"),
        "business_list_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "Something went wrong. Please try again."),
        "business_list_error_title": MessageLookupByLibrary.simpleMessage(
            "Couldn\'t load your businesses"),
        "business_list_retry":
            MessageLookupByLibrary.simpleMessage("Try again"),
        "business_list_search_empty": MessageLookupByLibrary.simpleMessage(
            "No businesses match your search"),
        "business_logo_add": MessageLookupByLibrary.simpleMessage("Add logo"),
        "business_logo_change":
            MessageLookupByLibrary.simpleMessage("Change logo"),
        "business_logo_files": MessageLookupByLibrary.simpleMessage("Images"),
        "business_logo_large": MessageLookupByLibrary.simpleMessage(
            "That image is over 10 MB. Pick a lighter one."),
        "business_logo_saved":
            MessageLookupByLibrary.simpleMessage("Logo updated"),
        "business_notice_documents": MessageLookupByLibrary.simpleMessage(
            "Legal documents may be requested at any time. Failing to provide them can restrict the business, the profile that created it and everyone who administers it."),
        "business_notice_real": MessageLookupByLibrary.simpleMessage(
            "The legal name and the type of activity must match the real business. Businesses whose activity looks suspicious can be restricted."),
        "business_notice_title":
            MessageLookupByLibrary.simpleMessage("Before you continue"),
        "business_notice_unverified": MessageLookupByLibrary.simpleMessage(
            "Unverified businesses have significant limitations until their information is confirmed."),
        "business_profile_active":
            MessageLookupByLibrary.simpleMessage("Go to your business"),
        "business_profile_activity":
            MessageLookupByLibrary.simpleMessage("Activity"),
        "business_profile_activity_note": MessageLookupByLibrary.simpleMessage(
            "What this business sells or does. It\'s what places it in searches and reports."),
        "business_profile_add": m6,
        "business_profile_address":
            MessageLookupByLibrary.simpleMessage("Address"),
        "business_profile_caption":
            MessageLookupByLibrary.simpleMessage("Tagline"),
        "business_profile_caption_note": MessageLookupByLibrary.simpleMessage(
            "One line about what this business does. It reads under its name, so it\'s what someone who doesn\'t know it yet reads first."),
        "business_profile_country":
            MessageLookupByLibrary.simpleMessage("Country"),
        "business_profile_country_hint":
            MessageLookupByLibrary.simpleMessage("ISO code (US, ES, VE)"),
        "business_profile_country_note": MessageLookupByLibrary.simpleMessage(
            "Where the business is registered, as its two-letter code. It sets which rules and taxes apply."),
        "business_profile_created":
            MessageLookupByLibrary.simpleMessage("Registered on"),
        "business_profile_currencies":
            MessageLookupByLibrary.simpleMessage("Also quotes in"),
        "business_profile_currencies_note": MessageLookupByLibrary.simpleMessage(
            "Other currencies this business also quotes prices in. They\'re changed where its currencies are set up."),
        "business_profile_currency":
            MessageLookupByLibrary.simpleMessage("Currency"),
        "business_profile_currency_note": MessageLookupByLibrary.simpleMessage(
            "The currency this business writes its prices in. Changing it wouldn\'t convert a single price, it would relabel every one of them, so it isn\'t changed from here."),
        "business_profile_edit": m7,
        "business_profile_empty":
            MessageLookupByLibrary.simpleMessage("Not set"),
        "business_profile_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "Something went wrong. Please try again."),
        "business_profile_error_title": MessageLookupByLibrary.simpleMessage(
            "Couldn\'t load this business"),
        "business_profile_id":
            MessageLookupByLibrary.simpleMessage("Identifier"),
        "business_profile_id_copied":
            MessageLookupByLibrary.simpleMessage("Identifier copied"),
        "business_profile_id_copy":
            MessageLookupByLibrary.simpleMessage("Copy identifier"),
        "business_profile_id_hide":
            MessageLookupByLibrary.simpleMessage("Hide identifier"),
        "business_profile_id_note": MessageLookupByLibrary.simpleMessage(
            "How this business is named outside the app: paste it when you write to support or wire an integration."),
        "business_profile_id_show":
            MessageLookupByLibrary.simpleMessage("Show identifier"),
        "business_profile_incorporation":
            MessageLookupByLibrary.simpleMessage("Incorporated on"),
        "business_profile_incorporation_day":
            MessageLookupByLibrary.simpleMessage("Day"),
        "business_profile_incorporation_month":
            MessageLookupByLibrary.simpleMessage("Month"),
        "business_profile_incorporation_year":
            MessageLookupByLibrary.simpleMessage("Year"),
        "business_profile_language":
            MessageLookupByLibrary.simpleMessage("Language"),
        "business_profile_language_note": MessageLookupByLibrary.simpleMessage(
            "The language this business writes in: the one used in what it sends to its customers."),
        "business_profile_legal_name":
            MessageLookupByLibrary.simpleMessage("Legal name"),
        "business_profile_legal_name_note": MessageLookupByLibrary.simpleMessage(
            "The name this business is registered under. It\'s the one that goes on invoices, contracts and anything legal."),
        "business_profile_name": MessageLookupByLibrary.simpleMessage("Name"),
        "business_profile_name_note": MessageLookupByLibrary.simpleMessage(
            "What this business is called day to day: the name in your list, in the selector and on every screen of the app."),
        "business_profile_nickname":
            MessageLookupByLibrary.simpleMessage("Handle"),
        "business_profile_nickname_note": MessageLookupByLibrary.simpleMessage(
            "The short public handle this business is found and linked by. No spaces, no accents."),
        "business_profile_not_found_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "This business is no longer in your list."),
        "business_profile_not_found_title":
            MessageLookupByLibrary.simpleMessage("Business not found"),
        "business_profile_owner": MessageLookupByLibrary.simpleMessage("Owner"),
        "business_profile_phone": MessageLookupByLibrary.simpleMessage("Phone"),
        "business_profile_phone_code":
            MessageLookupByLibrary.simpleMessage("Code"),
        "business_profile_phone_hint": MessageLookupByLibrary.simpleMessage(
            "Digits, with the country code (+584121234567)"),
        "business_profile_phone_note": MessageLookupByLibrary.simpleMessage(
            "The number a customer calls when they\'d rather talk to someone than write."),
        "business_profile_phone_number":
            MessageLookupByLibrary.simpleMessage("Number"),
        "business_profile_saved":
            MessageLookupByLibrary.simpleMessage("Business updated"),
        "business_profile_section_account":
            MessageLookupByLibrary.simpleMessage("Account"),
        "business_profile_section_contact":
            MessageLookupByLibrary.simpleMessage("Contact"),
        "business_profile_section_emails":
            MessageLookupByLibrary.simpleMessage("Email addresses"),
        "business_profile_section_identity":
            MessageLookupByLibrary.simpleMessage("Identity"),
        "business_profile_section_operation":
            MessageLookupByLibrary.simpleMessage("Operation"),
        "business_profile_select":
            MessageLookupByLibrary.simpleMessage("Select an option"),
        "business_profile_select_empty": MessageLookupByLibrary.simpleMessage(
            "No option matches your search"),
        "business_profile_tax_id":
            MessageLookupByLibrary.simpleMessage("Tax ID"),
        "business_profile_tax_id_note": MessageLookupByLibrary.simpleMessage(
            "The number the tax authority identifies this business by, printed on every invoice it issues."),
        "business_profile_verified_date":
            MessageLookupByLibrary.simpleMessage("Verified on"),
        "business_profile_verified_date_note": MessageLookupByLibrary.simpleMessage(
            "The day the platform checked these details. It\'s granted by verification, so it can\'t be edited here."),
        "business_profile_website":
            MessageLookupByLibrary.simpleMessage("Website"),
        "business_profile_website_failed": MessageLookupByLibrary.simpleMessage(
            "That address couldn\'t be opened. Check that it\'s written correctly."),
        "business_profile_website_hint":
            MessageLookupByLibrary.simpleMessage("ryzer.com"),
        "business_profile_website_note": MessageLookupByLibrary.simpleMessage(
            "Where a customer finds the business on its own: its site, its store or its page."),
        "business_profile_website_open":
            MessageLookupByLibrary.simpleMessage("Open website"),
        "business_rank_administrator":
            MessageLookupByLibrary.simpleMessage("Administrator"),
        "business_rank_advertiser":
            MessageLookupByLibrary.simpleMessage("Advertiser"),
        "business_rank_manager":
            MessageLookupByLibrary.simpleMessage("Manager"),
        "business_rank_seller": MessageLookupByLibrary.simpleMessage("Seller"),
        "business_rank_unknown": MessageLookupByLibrary.simpleMessage("Member"),
        "business_state_closed": MessageLookupByLibrary.simpleMessage("Closed"),
        "business_state_inquiries":
            MessageLookupByLibrary.simpleMessage("Inquiries only"),
        "business_state_open": MessageLookupByLibrary.simpleMessage("Open"),
        "business_state_orders":
            MessageLookupByLibrary.simpleMessage("Online orders only"),
        "business_state_unknown":
            MessageLookupByLibrary.simpleMessage("Unknown"),
        "business_statistics_soon": MessageLookupByLibrary.simpleMessage(
            "How this business is doing —sales, activity and growth— will be shown here."),
        "business_status_active":
            MessageLookupByLibrary.simpleMessage("Active"),
        "business_status_pending":
            MessageLookupByLibrary.simpleMessage("Pending"),
        "business_status_restricted":
            MessageLookupByLibrary.simpleMessage("Restricted"),
        "business_status_unknown":
            MessageLookupByLibrary.simpleMessage("Unknown"),
        "business_tab_branches":
            MessageLookupByLibrary.simpleMessage("Branches"),
        "business_tab_clients": MessageLookupByLibrary.simpleMessage("Clients"),
        "business_tab_employees":
            MessageLookupByLibrary.simpleMessage("Employees"),
        "business_tab_settings":
            MessageLookupByLibrary.simpleMessage("Settings"),
        "business_tab_statistics":
            MessageLookupByLibrary.simpleMessage("Statistics"),
        "business_type_agriculture":
            MessageLookupByLibrary.simpleMessage("Agriculture and livestock"),
        "business_type_automotive":
            MessageLookupByLibrary.simpleMessage("Automotive"),
        "business_type_beauty":
            MessageLookupByLibrary.simpleMessage("Beauty and personal care"),
        "business_type_construction":
            MessageLookupByLibrary.simpleMessage("Construction"),
        "business_type_education":
            MessageLookupByLibrary.simpleMessage("Education"),
        "business_type_empty": MessageLookupByLibrary.simpleMessage(
            "No activity matches your search"),
        "business_type_entertainment":
            MessageLookupByLibrary.simpleMessage("Entertainment"),
        "business_type_finance":
            MessageLookupByLibrary.simpleMessage("Finance"),
        "business_type_food":
            MessageLookupByLibrary.simpleMessage("Food and beverage"),
        "business_type_health":
            MessageLookupByLibrary.simpleMessage("Health and wellness"),
        "business_type_hospitality":
            MessageLookupByLibrary.simpleMessage("Hospitality and tourism"),
        "business_type_input":
            MessageLookupByLibrary.simpleMessage("Type of activity"),
        "business_type_legal": MessageLookupByLibrary.simpleMessage("Legal"),
        "business_type_manufacturing":
            MessageLookupByLibrary.simpleMessage("Manufacturing"),
        "business_type_nonprofit":
            MessageLookupByLibrary.simpleMessage("Nonprofit"),
        "business_type_other": MessageLookupByLibrary.simpleMessage("Other"),
        "business_type_placeholder":
            MessageLookupByLibrary.simpleMessage("Select the main activity"),
        "business_type_real_estate":
            MessageLookupByLibrary.simpleMessage("Real estate"),
        "business_type_retail": MessageLookupByLibrary.simpleMessage("Retail"),
        "business_type_services":
            MessageLookupByLibrary.simpleMessage("Professional services"),
        "business_type_technology":
            MessageLookupByLibrary.simpleMessage("Technology"),
        "business_type_transport":
            MessageLookupByLibrary.simpleMessage("Transport and logistics"),
        "business_type_wholesale":
            MessageLookupByLibrary.simpleMessage("Wholesale"),
        "business_verification_pending":
            MessageLookupByLibrary.simpleMessage("Under review"),
        "business_verification_rejected":
            MessageLookupByLibrary.simpleMessage("Rejected"),
        "business_verification_trusted":
            MessageLookupByLibrary.simpleMessage("Trusted"),
        "business_verification_untrusted":
            MessageLookupByLibrary.simpleMessage("Not verified"),
        "business_verification_verified":
            MessageLookupByLibrary.simpleMessage("Verified"),
        "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "channel_account_id":
            MessageLookupByLibrary.simpleMessage("On the network"),
        "channel_account_title":
            MessageLookupByLibrary.simpleMessage("Account"),
        "channel_capability_calls":
            MessageLookupByLibrary.simpleMessage("Calls"),
        "channel_capability_comments":
            MessageLookupByLibrary.simpleMessage("Comments"),
        "channel_capability_mentions":
            MessageLookupByLibrary.simpleMessage("Mentions"),
        "channel_capability_messages":
            MessageLookupByLibrary.simpleMessage("Messages"),
        "channel_capability_posts":
            MessageLookupByLibrary.simpleMessage("Posts"),
        "channel_catalog_error": MessageLookupByLibrary.simpleMessage(
            "We couldn\'t load the available networks"),
        "channel_changes_pending": MessageLookupByLibrary.simpleMessage(
            "You have unsaved changes on this channel"),
        "channel_created":
            MessageLookupByLibrary.simpleMessage("Channel connected"),
        "channel_credentials_subtitle": m8,
        "channel_credentials_title":
            MessageLookupByLibrary.simpleMessage("Credentials"),
        "channel_danger_section":
            MessageLookupByLibrary.simpleMessage("Undoing this channel"),
        "channel_delete_explanation": MessageLookupByLibrary.simpleMessage(
            "Disconnecting deletes the credentials stored for this channel and takes it off the list. The account can be connected again, but you\'ll have to set it up from scratch."),
        "channel_delete_message": m9,
        "channel_delete_title":
            MessageLookupByLibrary.simpleMessage("Disconnect this channel?"),
        "channel_deleted":
            MessageLookupByLibrary.simpleMessage("Channel disconnected"),
        "channel_field_required":
            MessageLookupByLibrary.simpleMessage("required to run"),
        "channel_missing_title": MessageLookupByLibrary.simpleMessage(
            "This channel isn\'t running yet"),
        "channel_open_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "It may have been disconnected, or it belongs to another business"),
        "channel_open_error_title": MessageLookupByLibrary.simpleMessage(
            "We couldn\'t open this channel"),
        "channel_own_id": MessageLookupByLibrary.simpleMessage("Channel id"),
        "channel_pause": MessageLookupByLibrary.simpleMessage("Pause channel"),
        "channel_paused":
            MessageLookupByLibrary.simpleMessage("Channel paused"),
        "channel_payments_empty": MessageLookupByLibrary.simpleMessage(
            "This business has no payment accounts yet. Add one in Finance and come back"),
        "channel_payments_error": MessageLookupByLibrary.simpleMessage(
            "We couldn\'t load your payment accounts"),
        "channel_payments_subtitle": MessageLookupByLibrary.simpleMessage(
            "Which of your accounts the agent may give a customer to pay into. It offers these and no others"),
        "channel_payments_title":
            MessageLookupByLibrary.simpleMessage("Payment methods"),
        "channel_resume":
            MessageLookupByLibrary.simpleMessage("Resume channel"),
        "channel_resumed":
            MessageLookupByLibrary.simpleMessage("Channel resumed"),
        "channel_role_agent": MessageLookupByLibrary.simpleMessage("Agent"),
        "channel_role_agent_hint": MessageLookupByLibrary.simpleMessage(
            "Answers whatever comes, without pushing towards a sale"),
        "channel_role_seller": MessageLookupByLibrary.simpleMessage("Seller"),
        "channel_role_seller_hint": MessageLookupByLibrary.simpleMessage(
            "Presents products, answers prices and stock, and closes the order"),
        "channel_role_subtitle": MessageLookupByLibrary.simpleMessage(
            "What the agent does when it answers on this channel"),
        "channel_role_support": MessageLookupByLibrary.simpleMessage("Support"),
        "channel_role_support_hint": MessageLookupByLibrary.simpleMessage(
            "Solves problems with something the customer already bought"),
        "channel_role_title":
            MessageLookupByLibrary.simpleMessage("Agent role"),
        "channel_saved":
            MessageLookupByLibrary.simpleMessage("Channel updated"),
        "channel_secret_stored": MessageLookupByLibrary.simpleMessage(
            "Already set — write to replace it"),
        "channel_source_calendar":
            MessageLookupByLibrary.simpleMessage("Service calendar"),
        "channel_source_calendar_hint": MessageLookupByLibrary.simpleMessage(
            "Books appointments on a calendar of services"),
        "channel_source_knowledge":
            MessageLookupByLibrary.simpleMessage("Knowledge base"),
        "channel_source_knowledge_hint": MessageLookupByLibrary.simpleMessage(
            "Answers questions and spreads marketing from information you write"),
        "channel_source_missing": MessageLookupByLibrary.simpleMessage(
            "Choose which product table the agent reads from"),
        "channel_source_no_tables": MessageLookupByLibrary.simpleMessage(
            "This business has no product tables yet. Create one in Products and come back"),
        "channel_source_none":
            MessageLookupByLibrary.simpleMessage("No data source"),
        "channel_source_soon": MessageLookupByLibrary.simpleMessage("Soon"),
        "channel_source_subtitle": MessageLookupByLibrary.simpleMessage(
            "Where the agent reads from. Without a source it answers from memory, which means it makes prices up"),
        "channel_source_table":
            MessageLookupByLibrary.simpleMessage("Product table"),
        "channel_source_table_empty": MessageLookupByLibrary.simpleMessage(
            "No table matches your search"),
        "channel_source_table_hint": MessageLookupByLibrary.simpleMessage(
            "Answers prices, stock and product details from one of your tables"),
        "channel_source_table_placeholder":
            MessageLookupByLibrary.simpleMessage("Choose a product table"),
        "channel_source_table_select":
            MessageLookupByLibrary.simpleMessage("Which table"),
        "channel_source_title": MessageLookupByLibrary.simpleMessage("Data"),
        "channel_state_paused": MessageLookupByLibrary.simpleMessage("Paused"),
        "channel_state_pending":
            MessageLookupByLibrary.simpleMessage("Needs setup"),
        "channel_state_ready":
            MessageLookupByLibrary.simpleMessage("Connected"),
        "channel_tool_documents":
            MessageLookupByLibrary.simpleMessage("Documents"),
        "channel_tool_documents_hint":
            MessageLookupByLibrary.simpleMessage("Reads attached files"),
        "channel_tool_images": MessageLookupByLibrary.simpleMessage("Images"),
        "channel_tool_images_hint": MessageLookupByLibrary.simpleMessage(
            "Reads the pictures customers send, and generates its own"),
        "channel_tool_video": MessageLookupByLibrary.simpleMessage("Video"),
        "channel_tool_video_hint": MessageLookupByLibrary.simpleMessage(
            "Watches videos customers send"),
        "channel_tool_voice": MessageLookupByLibrary.simpleMessage("Voice"),
        "channel_tool_voice_hint": MessageLookupByLibrary.simpleMessage(
            "Transcribes voice notes and answers out loud"),
        "channel_tools_cost": MessageLookupByLibrary.simpleMessage(
            "Each tool you turn on raises the processing cost of this channel, charged per conversation answered. Audio and video cost noticeably more than text."),
        "channel_tools_subtitle": MessageLookupByLibrary.simpleMessage(
            "What the agent can process and produce besides text"),
        "channel_tools_title": MessageLookupByLibrary.simpleMessage("Tools"),
        "channel_type_locked": MessageLookupByLibrary.simpleMessage(
            "The network can\'t be changed: its stored credentials belong to it. To use another one, connect a new channel"),
        "channel_type_missing": MessageLookupByLibrary.simpleMessage(
            "Choose the type of channel you want to connect"),
        "channel_type_soon": MessageLookupByLibrary.simpleMessage("Soon"),
        "channel_type_subtitle": MessageLookupByLibrary.simpleMessage(
            "Which network this channel connects to. It decides which credentials you\'ll need below"),
        "channel_type_title":
            MessageLookupByLibrary.simpleMessage("Channel type"),
        "channel_type_whatsapp_personal":
            MessageLookupByLibrary.simpleMessage("WhatsApp Personal"),
        "channel_type_whatsapp_personal_hint":
            MessageLookupByLibrary.simpleMessage(
                "A personal number, without a Meta business account"),
        "channel_whatsapp_personal_notice_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "There are no tokens to paste. Once this channel is created, turn it on from the channels list to scan a QR code and link your WhatsApp"),
        "channel_whatsapp_personal_notice_title":
            MessageLookupByLibrary.simpleMessage("Link your number"),
        "channels": MessageLookupByLibrary.simpleMessage("Channels"),
        "channels_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "Connect a WhatsApp number, a Facebook page or an Instagram account and let an agent answer for you"),
        "channels_empty_title":
            MessageLookupByLibrary.simpleMessage("No channels connected yet"),
        "channels_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "Check your connection and try again"),
        "channels_error_title": MessageLookupByLibrary.simpleMessage(
            "We couldn\'t load your channels"),
        "channels_retry": MessageLookupByLibrary.simpleMessage("Try again"),
        "code_input": MessageLookupByLibrary.simpleMessage("Code"),
        "collapse": MessageLookupByLibrary.simpleMessage("Collapse"),
        "coming_soon": MessageLookupByLibrary.simpleMessage("Coming soon"),
        "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
        "confirm_password_input":
            MessageLookupByLibrary.simpleMessage("Confirm password"),
        "connectionError": MessageLookupByLibrary.simpleMessage(
            "Sorry, there was a connection error, please try again later"),
        "connection_bot_count": m10,
        "connection_catalog_error": MessageLookupByLibrary.simpleMessage(
            "We couldn\'t load the available services"),
        "connection_created":
            MessageLookupByLibrary.simpleMessage("Account connected"),
        "connection_credentials_subtitle": m11,
        "connection_credentials_title":
            MessageLookupByLibrary.simpleMessage("Credentials"),
        "connection_delete_bots": m12,
        "connection_delete_message": m13,
        "connection_delete_title":
            MessageLookupByLibrary.simpleMessage("Disconnect this account?"),
        "connection_deleted":
            MessageLookupByLibrary.simpleMessage("Account disconnected"),
        "connection_description_input":
            MessageLookupByLibrary.simpleMessage("Description"),
        "connection_description_placeholder":
            MessageLookupByLibrary.simpleMessage("Optional description..."),
        "connection_field_required":
            MessageLookupByLibrary.simpleMessage("required to run"),
        "connection_identity_subtitle": MessageLookupByLibrary.simpleMessage(
            "How you\'ll recognize this account in your list"),
        "connection_identity_title":
            MessageLookupByLibrary.simpleMessage("Account"),
        "connection_missing_title": MessageLookupByLibrary.simpleMessage(
            "This account isn\'t ready yet"),
        "connection_name_input": MessageLookupByLibrary.simpleMessage("Name"),
        "connection_name_placeholder":
            MessageLookupByLibrary.simpleMessage("Main account, Sales..."),
        "connection_open_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "It may have been disconnected, or it belongs to another business"),
        "connection_open_error_title": MessageLookupByLibrary.simpleMessage(
            "We couldn\'t open this connection"),
        "connection_options":
            MessageLookupByLibrary.simpleMessage("Connection options"),
        "connection_pause":
            MessageLookupByLibrary.simpleMessage("Pause account"),
        "connection_paused":
            MessageLookupByLibrary.simpleMessage("Account paused"),
        "connection_provider_locked": MessageLookupByLibrary.simpleMessage(
            "The service can\'t be changed: the stored credentials belong to it. To use another one, connect a new account"),
        "connection_provider_missing": MessageLookupByLibrary.simpleMessage(
            "Choose which service you want to connect"),
        "connection_provider_soon":
            MessageLookupByLibrary.simpleMessage("Soon"),
        "connection_provider_subtitle": MessageLookupByLibrary.simpleMessage(
            "Which service this account belongs to. It decides which credentials you\'ll need below"),
        "connection_provider_title":
            MessageLookupByLibrary.simpleMessage("Service"),
        "connection_resume":
            MessageLookupByLibrary.simpleMessage("Resume account"),
        "connection_resumed":
            MessageLookupByLibrary.simpleMessage("Account resumed"),
        "connection_saved":
            MessageLookupByLibrary.simpleMessage("Connection updated"),
        "connection_scope_ad_comments":
            MessageLookupByLibrary.simpleMessage("Comments on ads"),
        "connection_scope_calls": MessageLookupByLibrary.simpleMessage("Calls"),
        "connection_scope_comments":
            MessageLookupByLibrary.simpleMessage("Comments on posts"),
        "connection_scope_mentions":
            MessageLookupByLibrary.simpleMessage("Mentions and tags"),
        "connection_scope_messages":
            MessageLookupByLibrary.simpleMessage("Direct messages"),
        "connection_scope_posts": MessageLookupByLibrary.simpleMessage("Posts"),
        "connection_secret_stored": MessageLookupByLibrary.simpleMessage(
            "Already set — write to replace it"),
        "connection_state_paused":
            MessageLookupByLibrary.simpleMessage("Paused"),
        "connection_state_pending":
            MessageLookupByLibrary.simpleMessage("Needs setup"),
        "connection_state_ready":
            MessageLookupByLibrary.simpleMessage("Connected"),
        "connections": MessageLookupByLibrary.simpleMessage("Connections"),
        "connections_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "Connect a WhatsApp number, a Facebook page or an Instagram account. Once connected, you can put bots to work on it"),
        "connections_empty_title":
            MessageLookupByLibrary.simpleMessage("No accounts connected yet"),
        "connections_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "Check your connection and try again"),
        "connections_error_title": MessageLookupByLibrary.simpleMessage(
            "We couldn\'t load your connections"),
        "connections_retry": MessageLookupByLibrary.simpleMessage("Try again"),
        "connections_search_empty": MessageLookupByLibrary.simpleMessage(
            "No connection matches your search"),
        "create_business":
            MessageLookupByLibrary.simpleMessage("Create business"),
        "create_business_subtitle": MessageLookupByLibrary.simpleMessage(
            "Tell us about the business you want to manage"),
        "create_channel":
            MessageLookupByLibrary.simpleMessage("Connect channel"),
        "create_connection":
            MessageLookupByLibrary.simpleMessage("Connect account"),
        "create_table": MessageLookupByLibrary.simpleMessage("Create table"),
        "create_table_subtitle": MessageLookupByLibrary.simpleMessage(
            "Define the table where your products will live"),
        "currency": MessageLookupByLibrary.simpleMessage("Currency"),
        "currency_eur": MessageLookupByLibrary.simpleMessage("EUR"),
        "currency_local": MessageLookupByLibrary.simpleMessage("Local"),
        "currency_usd": MessageLookupByLibrary.simpleMessage("USD"),
        "custom": MessageLookupByLibrary.simpleMessage("Custom"),
        "custom_days": MessageLookupByLibrary.simpleMessage("Days"),
        "delete_business_email":
            MessageLookupByLibrary.simpleMessage("Delete address"),
        "delete_channel":
            MessageLookupByLibrary.simpleMessage("Disconnect channel"),
        "delete_connection": MessageLookupByLibrary.simpleMessage("Disconnect"),
        "delete_table": MessageLookupByLibrary.simpleMessage("Delete table"),
        "description": MessageLookupByLibrary.simpleMessage("Description"),
        "dont_have_account":
            MessageLookupByLibrary.simpleMessage("Don\'t have an account yet?"),
        "edit": MessageLookupByLibrary.simpleMessage("Edit"),
        "edit_about_title":
            MessageLookupByLibrary.simpleMessage("Title and description"),
        "edit_billing_title":
            MessageLookupByLibrary.simpleMessage("Billing period"),
        "edit_channel":
            MessageLookupByLibrary.simpleMessage("Configure channel"),
        "edit_currency_title":
            MessageLookupByLibrary.simpleMessage("Edit currency"),
        "edit_price_title": MessageLookupByLibrary.simpleMessage("Edit price"),
        "email_input": MessageLookupByLibrary.simpleMessage("Email"),
        "enter_days": MessageLookupByLibrary.simpleMessage("Number of days"),
        "expand": MessageLookupByLibrary.simpleMessage("Expand"),
        "external_services":
            MessageLookupByLibrary.simpleMessage("External Services"),
        "field_added": MessageLookupByLibrary.simpleMessage("Field added"),
        "field_type_barcode": MessageLookupByLibrary.simpleMessage("Barcode"),
        "field_type_barcode_hint": MessageLookupByLibrary.simpleMessage(
            "The code printed on the product: EAN, UPC, ISBN"),
        "field_type_boolean": MessageLookupByLibrary.simpleMessage("Yes / No"),
        "field_type_boolean_hint": MessageLookupByLibrary.simpleMessage(
            "Something that is either on or off"),
        "field_type_categories":
            MessageLookupByLibrary.simpleMessage("Categories"),
        "field_type_categories_hint": MessageLookupByLibrary.simpleMessage(
            "A closed list of labels, several per product"),
        "field_type_counter": MessageLookupByLibrary.simpleMessage("Counter"),
        "field_type_counter_hint": MessageLookupByLibrary.simpleMessage(
            "A number that goes up on its own"),
        "field_type_currency":
            MessageLookupByLibrary.simpleMessage("Other amount"),
        "field_type_currency_hint": MessageLookupByLibrary.simpleMessage(
            "Money that is not the selling price: cost, wholesale, margin"),
        "field_type_date": MessageLookupByLibrary.simpleMessage("Date"),
        "field_type_date_hint": MessageLookupByLibrary.simpleMessage(
            "A day: expiry, arrival or release"),
        "field_type_datetime":
            MessageLookupByLibrary.simpleMessage("Date and time"),
        "field_type_datetime_hint":
            MessageLookupByLibrary.simpleMessage("A day and the time of day"),
        "field_type_decimal": MessageLookupByLibrary.simpleMessage("Decimal"),
        "field_type_decimal_hint":
            MessageLookupByLibrary.simpleMessage("Numbers with decimals"),
        "field_type_description":
            MessageLookupByLibrary.simpleMessage("Description"),
        "field_type_description_hint": MessageLookupByLibrary.simpleMessage(
            "What the product is, in words. The AI reads it and searches by meaning"),
        "field_type_email": MessageLookupByLibrary.simpleMessage("Email"),
        "field_type_email_hint":
            MessageLookupByLibrary.simpleMessage("An email address"),
        "field_type_image": MessageLookupByLibrary.simpleMessage("Image"),
        "field_type_image_hint":
            MessageLookupByLibrary.simpleMessage("Photos of the product"),
        "field_type_measure": MessageLookupByLibrary.simpleMessage("Measure"),
        "field_type_measure_hint": MessageLookupByLibrary.simpleMessage(
            "A magnitude with a unit: weight, volume, length"),
        "field_type_number": MessageLookupByLibrary.simpleMessage("Number"),
        "field_type_number_hint": MessageLookupByLibrary.simpleMessage(
            "Whole numbers: units, sizes, quantities"),
        "field_type_options":
            MessageLookupByLibrary.simpleMessage("Options list"),
        "field_type_options_hint": MessageLookupByLibrary.simpleMessage(
            "A closed list of labels, one per product: size, colour, condition"),
        "field_type_percentage":
            MessageLookupByLibrary.simpleMessage("Percentage"),
        "field_type_percentage_hint": MessageLookupByLibrary.simpleMessage(
            "A rate written as 16, not as 0.16: discount, tax, margin"),
        "field_type_phone": MessageLookupByLibrary.simpleMessage("Phone"),
        "field_type_phone_hint":
            MessageLookupByLibrary.simpleMessage("A phone number"),
        "field_type_price": MessageLookupByLibrary.simpleMessage("Price"),
        "field_type_price_hint": MessageLookupByLibrary.simpleMessage(
            "The selling price: what a customer pays"),
        "field_type_sku": MessageLookupByLibrary.simpleMessage("SKU"),
        "field_type_sku_hint": MessageLookupByLibrary.simpleMessage(
            "Your own reference or part number"),
        "field_type_stock": MessageLookupByLibrary.simpleMessage("Stock"),
        "field_type_stock_hint": MessageLookupByLibrary.simpleMessage(
            "Units on hand, kept by the inventory engine"),
        "field_type_text": MessageLookupByLibrary.simpleMessage("Text"),
        "field_type_text_hint": MessageLookupByLibrary.simpleMessage(
            "Short one-line text: names, brands, references"),
        "field_type_textarea":
            MessageLookupByLibrary.simpleMessage("Long text"),
        "field_type_textarea_hint": MessageLookupByLibrary.simpleMessage(
            "Multiline text customers don\'t search by"),
        "field_type_title":
            MessageLookupByLibrary.simpleMessage("Product name"),
        "field_type_title_hint": MessageLookupByLibrary.simpleMessage(
            "What the product is called. The AI searches by it and names the product with it"),
        "field_type_url": MessageLookupByLibrary.simpleMessage("Link"),
        "field_type_url_hint":
            MessageLookupByLibrary.simpleMessage("A web address"),
        "field_visibility_declared":
            MessageLookupByLibrary.simpleMessage("Declared"),
        "field_visibility_declared_hint": MessageLookupByLibrary.simpleMessage(
            "The AI knows the column exists and can filter by it, but never says what it holds. This is where a cost price belongs"),
        "field_visibility_hidden":
            MessageLookupByLibrary.simpleMessage("Hidden"),
        "field_visibility_hidden_hint": MessageLookupByLibrary.simpleMessage(
            "The AI doesn\'t know this column exists"),
        "field_visibility_visible":
            MessageLookupByLibrary.simpleMessage("Visible"),
        "field_visibility_visible_hint": MessageLookupByLibrary.simpleMessage(
            "The AI reads this column and can quote what it says"),
        "finance": MessageLookupByLibrary.simpleMessage("Finance"),
        "finance_bot_activity": m14,
        "finance_bot_answers":
            MessageLookupByLibrary.simpleMessage("Answering messages"),
        "finance_bot_catalog": MessageLookupByLibrary.simpleMessage("Catalog"),
        "finance_bot_empty": MessageLookupByLibrary.simpleMessage(
            "Lyra cost nothing in this period"),
        "finance_bot_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "The figures behind the bot could not be measured, which is not the same as it having cost nothing. Try again in a moment."),
        "finance_bot_error_title": MessageLookupByLibrary.simpleMessage(
            "What Lyra cost could not be read"),
        "finance_bot_hint": m15,
        "finance_bot_media":
            MessageLookupByLibrary.simpleMessage("Images and audio"),
        "finance_bot_other":
            MessageLookupByLibrary.simpleMessage("Unattributed"),
        "finance_bot_other_hint":
            MessageLookupByLibrary.simpleMessage("Spend of no known area"),
        "finance_bot_queries": MessageLookupByLibrary.simpleMessage("Searches"),
        "finance_bot_research":
            MessageLookupByLibrary.simpleMessage("Web lookups"),
        "finance_bot_tables":
            MessageLookupByLibrary.simpleMessage("Reading your tables"),
        "finance_bot_tables_hint": m16,
        "finance_bot_text": MessageLookupByLibrary.simpleMessage("Replies"),
        "finance_bot_title": MessageLookupByLibrary.simpleMessage("Lyra spend"),
        "finance_bot_vectors":
            MessageLookupByLibrary.simpleMessage("Search index"),
        "finance_breakdown_empty": MessageLookupByLibrary.simpleMessage(
            "Nothing moved in this period"),
        "finance_by_concept":
            MessageLookupByLibrary.simpleMessage("By concept"),
        "finance_by_method": MessageLookupByLibrary.simpleMessage("By method"),
        "finance_credit":
            MessageLookupByLibrary.simpleMessage("Sold on credit"),
        "finance_credit_hint": MessageLookupByLibrary.simpleMessage(
            "Not collected yet, so it is not income"),
        "finance_expenses": MessageLookupByLibrary.simpleMessage("Paid"),
        "finance_income": MessageLookupByLibrary.simpleMessage("Received"),
        "finance_income_payments":
            MessageLookupByLibrary.simpleMessage("Other income"),
        "finance_income_sales": MessageLookupByLibrary.simpleMessage("Sales"),
        "finance_method_account":
            MessageLookupByLibrary.simpleMessage("Account"),
        "finance_method_account_placeholder":
            MessageLookupByLibrary.simpleMessage(
                "Number, phone, email or address"),
        "finance_method_create_title":
            MessageLookupByLibrary.simpleMessage("Add a payment method"),
        "finance_method_document":
            MessageLookupByLibrary.simpleMessage("Id number"),
        "finance_method_document_placeholder":
            MessageLookupByLibrary.simpleMessage("Tax or personal id"),
        "finance_method_document_type":
            MessageLookupByLibrary.simpleMessage("Type"),
        "finance_method_edit_title":
            MessageLookupByLibrary.simpleMessage("Edit payment method"),
        "finance_method_holder": MessageLookupByLibrary.simpleMessage("Holder"),
        "finance_method_holder_placeholder":
            MessageLookupByLibrary.simpleMessage("Name the account is under"),
        "finance_method_institution":
            MessageLookupByLibrary.simpleMessage("Institution"),
        "finance_method_institution_placeholder":
            MessageLookupByLibrary.simpleMessage("Bank, wallet or network"),
        "finance_method_instructions":
            MessageLookupByLibrary.simpleMessage("Instructions"),
        "finance_method_instructions_placeholder":
            MessageLookupByLibrary.simpleMessage(
                "What the customer has to do besides sending it"),
        "finance_method_label": MessageLookupByLibrary.simpleMessage("Name"),
        "finance_method_label_placeholder":
            MessageLookupByLibrary.simpleMessage("How you call this account"),
        "finance_method_no_rails": MessageLookupByLibrary.simpleMessage(
            "The available methods could not be read. Go back to the tab and try again."),
        "finance_method_nothing": MessageLookupByLibrary.simpleMessage(
            "This method needs no account details: name it if you want and save it."),
        "finance_method_optional":
            MessageLookupByLibrary.simpleMessage("optional"),
        "finance_method_rail": MessageLookupByLibrary.simpleMessage("Method"),
        "finance_method_rail_fixed":
            MessageLookupByLibrary.simpleMessage("Cannot be changed"),
        "finance_method_rail_placeholder":
            MessageLookupByLibrary.simpleMessage("Which one do you accept?"),
        "finance_method_remove":
            MessageLookupByLibrary.simpleMessage("Turn off"),
        "finance_method_remove_message": m17,
        "finance_method_remove_title":
            MessageLookupByLibrary.simpleMessage("Turn this method off?"),
        "finance_method_subtitle": MessageLookupByLibrary.simpleMessage(
            "What a customer is told when they ask how to pay. Each method asks only for what it needs to receive money."),
        "finance_methods_add":
            MessageLookupByLibrary.simpleMessage("Add method"),
        "finance_methods_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "Add the account a customer is told to send money to."),
        "finance_methods_empty_title":
            MessageLookupByLibrary.simpleMessage("No payment method yet"),
        "finance_methods_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "The accounts of this company could not be read. Try again in a moment."),
        "finance_methods_error_title": MessageLookupByLibrary.simpleMessage(
            "The payment methods could not be loaded"),
        "finance_more": m18,
        "finance_movements": m19,
        "finance_net": MessageLookupByLibrary.simpleMessage("Net"),
        "finance_net_hint":
            MessageLookupByLibrary.simpleMessage("Received minus paid"),
        "finance_payment_amount":
            MessageLookupByLibrary.simpleMessage("Amount"),
        "finance_payment_concept":
            MessageLookupByLibrary.simpleMessage("Concept"),
        "finance_payment_counterpart":
            MessageLookupByLibrary.simpleMessage("Counterpart"),
        "finance_payment_date": MessageLookupByLibrary.simpleMessage("Date"),
        "finance_payment_method":
            MessageLookupByLibrary.simpleMessage("Method"),
        "finance_payment_note": MessageLookupByLibrary.simpleMessage("Note"),
        "finance_payment_reference":
            MessageLookupByLibrary.simpleMessage("Reference"),
        "finance_payment_ticket":
            MessageLookupByLibrary.simpleMessage("Ticket"),
        "finance_payment_void": MessageLookupByLibrary.simpleMessage("Void"),
        "finance_payment_void_message": m20,
        "finance_payment_void_title":
            MessageLookupByLibrary.simpleMessage("Void this payment?"),
        "finance_payments_all": MessageLookupByLibrary.simpleMessage("All"),
        "finance_payments_any": MessageLookupByLibrary.simpleMessage("Any"),
        "finance_payments_any_state":
            MessageLookupByLibrary.simpleMessage("Recorded and voided"),
        "finance_payments_clear":
            MessageLookupByLibrary.simpleMessage("Clear filters"),
        "finance_payments_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "Money paid to a supplier or collected outside the counter is recorded here."),
        "finance_payments_empty_title":
            MessageLookupByLibrary.simpleMessage("No payments recorded yet"),
        "finance_payments_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "The movements of this company could not be read. Try again in a moment."),
        "finance_payments_error_title": MessageLookupByLibrary.simpleMessage(
            "The history could not be loaded"),
        "finance_payments_in": MessageLookupByLibrary.simpleMessage("Received"),
        "finance_payments_none_subtitle": MessageLookupByLibrary.simpleMessage(
            "Nothing was received or paid under these filters."),
        "finance_payments_none_title":
            MessageLookupByLibrary.simpleMessage("No movement matches"),
        "finance_payments_out": MessageLookupByLibrary.simpleMessage("Paid"),
        "finance_payments_record":
            MessageLookupByLibrary.simpleMessage("Record payment"),
        "finance_payments_recorded":
            MessageLookupByLibrary.simpleMessage("Recorded"),
        "finance_payments_voided":
            MessageLookupByLibrary.simpleMessage("Voided"),
        "finance_range_month":
            MessageLookupByLibrary.simpleMessage("Last 30 days"),
        "finance_range_today": MessageLookupByLibrary.simpleMessage("Today"),
        "finance_range_week":
            MessageLookupByLibrary.simpleMessage("Last 7 days"),
        "finance_range_year":
            MessageLookupByLibrary.simpleMessage("Last 12 months"),
        "finance_receivable_collect":
            MessageLookupByLibrary.simpleMessage("Record collection"),
        "finance_receivable_collected":
            MessageLookupByLibrary.simpleMessage("Collected"),
        "finance_receivable_customer":
            MessageLookupByLibrary.simpleMessage("Customer"),
        "finance_receivable_date":
            MessageLookupByLibrary.simpleMessage("Sold on"),
        "finance_receivable_outstanding":
            MessageLookupByLibrary.simpleMessage("Outstanding"),
        "finance_receivable_ticket":
            MessageLookupByLibrary.simpleMessage("Ticket"),
        "finance_receivable_total":
            MessageLookupByLibrary.simpleMessage("Total"),
        "finance_receivables_collected":
            MessageLookupByLibrary.simpleMessage("Collected"),
        "finance_receivables_empty_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "Every credit sale has been collected."),
        "finance_receivables_empty_title":
            MessageLookupByLibrary.simpleMessage("Nobody owes anything"),
        "finance_receivables_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "The credit sales of this company could not be read. Try again in a moment."),
        "finance_receivables_error_title": MessageLookupByLibrary.simpleMessage(
            "The debts could not be loaded"),
        "finance_receivables_open_only":
            MessageLookupByLibrary.simpleMessage("Only unpaid"),
        "finance_receivables_outstanding":
            MessageLookupByLibrary.simpleMessage("Outstanding"),
        "finance_receivables_sold":
            MessageLookupByLibrary.simpleMessage("Sold on credit"),
        "finance_record_account":
            MessageLookupByLibrary.simpleMessage("Account"),
        "finance_record_account_placeholder":
            MessageLookupByLibrary.simpleMessage("Where did the money land?"),
        "finance_record_amount_error":
            MessageLookupByLibrary.simpleMessage("Write how much money moved"),
        "finance_record_concept_placeholder":
            MessageLookupByLibrary.simpleMessage("What was it for?"),
        "finance_record_counterpart_placeholder":
            MessageLookupByLibrary.simpleMessage("Who paid, or who was paid"),
        "finance_record_method_placeholder":
            MessageLookupByLibrary.simpleMessage("How did it move?"),
        "finance_record_no_account":
            MessageLookupByLibrary.simpleMessage("No account"),
        "finance_record_note_placeholder": MessageLookupByLibrary.simpleMessage(
            "What should be remembered about it"),
        "finance_record_reference_placeholder":
            MessageLookupByLibrary.simpleMessage("Confirmation number"),
        "finance_record_save": MessageLookupByLibrary.simpleMessage("Record"),
        "finance_record_subtitle": MessageLookupByLibrary.simpleMessage(
            "Money the company received or paid outside the counter. A sale\'s own payment is already on its ticket."),
        "finance_record_ticket_placeholder":
            MessageLookupByLibrary.simpleMessage("Ticket code"),
        "finance_record_title":
            MessageLookupByLibrary.simpleMessage("Record a payment"),
        "finance_retry": MessageLookupByLibrary.simpleMessage("Try again"),
        "finance_select_empty": MessageLookupByLibrary.simpleMessage(
            "No option matches your search"),
        "finance_summary_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "Nothing came in and nothing went out in this period."),
        "finance_summary_empty_title":
            MessageLookupByLibrary.simpleMessage("No money moved"),
        "finance_summary_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "The money of this period could not be read. Try again in a moment."),
        "finance_summary_error_title": MessageLookupByLibrary.simpleMessage(
            "The figures could not be loaded"),
        "finance_tab_methods":
            MessageLookupByLibrary.simpleMessage("Payment methods"),
        "finance_tab_overview":
            MessageLookupByLibrary.simpleMessage("Overview"),
        "finance_tab_payments":
            MessageLookupByLibrary.simpleMessage("Payments"),
        "finance_tab_receivables":
            MessageLookupByLibrary.simpleMessage("Receivables"),
        "finance_window": m21,
        "first_name_input": MessageLookupByLibrary.simpleMessage("First name"),
        "form_empty_ma": m22,
        "form_incomplete_ma": m23,
        "form_invalid_ma": m24,
        "form_long_ma": m25,
        "hide_keyboard": MessageLookupByLibrary.simpleMessage("Hide keyboard"),
        "home": MessageLookupByLibrary.simpleMessage("Home"),
        "how_often_pay":
            MessageLookupByLibrary.simpleMessage("How often do you pay?"),
        "image_crop_failed": MessageLookupByLibrary.simpleMessage(
            "That image couldn\'t be prepared. Try another one."),
        "image_crop_hint": MessageLookupByLibrary.simpleMessage(
            "Drag the image to move it and zoom in to leave out what you don\'t want."),
        "image_crop_title":
            MessageLookupByLibrary.simpleMessage("Frame the image"),
        "image_viewer_close":
            MessageLookupByLibrary.simpleMessage("Close image"),
        "import_source_airtable":
            MessageLookupByLibrary.simpleMessage("Airtable"),
        "import_source_airtable_hint": MessageLookupByLibrary.simpleMessage(
            "A table from one of your bases"),
        "import_source_apps":
            MessageLookupByLibrary.simpleMessage("Apps and stores"),
        "import_source_device":
            MessageLookupByLibrary.simpleMessage("From this device"),
        "import_source_formats":
            MessageLookupByLibrary.simpleMessage("Other formats"),
        "import_source_google_sheets":
            MessageLookupByLibrary.simpleMessage("Google Sheets"),
        "import_source_google_sheets_hint":
            MessageLookupByLibrary.simpleMessage(
                "A sheet from your Google Drive"),
        "import_source_json": MessageLookupByLibrary.simpleMessage("JSON"),
        "import_source_json_hint": MessageLookupByLibrary.simpleMessage(
            "A products file exported as JSON"),
        "import_source_magento":
            MessageLookupByLibrary.simpleMessage("Magento"),
        "import_source_magento_hint":
            MessageLookupByLibrary.simpleMessage("The catalog of your store"),
        "import_source_notion": MessageLookupByLibrary.simpleMessage("Notion"),
        "import_source_notion_hint": MessageLookupByLibrary.simpleMessage(
            "A database from your workspace"),
        "import_source_ods":
            MessageLookupByLibrary.simpleMessage("OpenDocument"),
        "import_source_ods_hint": MessageLookupByLibrary.simpleMessage(
            "A sheet from LibreOffice or OpenOffice"),
        "import_source_search":
            MessageLookupByLibrary.simpleMessage("Search a source"),
        "import_source_search_empty": MessageLookupByLibrary.simpleMessage(
            "No source matches your search"),
        "import_source_shopify":
            MessageLookupByLibrary.simpleMessage("Shopify"),
        "import_source_shopify_hint":
            MessageLookupByLibrary.simpleMessage("The catalog of your store"),
        "import_source_smartsheet":
            MessageLookupByLibrary.simpleMessage("Smartsheet"),
        "import_source_smartsheet_hint":
            MessageLookupByLibrary.simpleMessage("A sheet from your workspace"),
        "import_source_soon": MessageLookupByLibrary.simpleMessage("Soon"),
        "import_source_spreadsheet":
            MessageLookupByLibrary.simpleMessage("Upload spreadsheet"),
        "import_source_spreadsheet_hint": MessageLookupByLibrary.simpleMessage(
            "An Excel, CSV or ODS file from this device"),
        "import_source_subtitle": MessageLookupByLibrary.simpleMessage(
            "Choose where this table\'s products come from"),
        "import_source_trello": MessageLookupByLibrary.simpleMessage("Trello"),
        "import_source_trello_hint": MessageLookupByLibrary.simpleMessage(
            "The cards of one of your boards"),
        "import_source_woocommerce":
            MessageLookupByLibrary.simpleMessage("WooCommerce"),
        "import_source_woocommerce_hint":
            MessageLookupByLibrary.simpleMessage("The catalog of your store"),
        "import_source_xml": MessageLookupByLibrary.simpleMessage("XML"),
        "import_source_xml_hint":
            MessageLookupByLibrary.simpleMessage("A products feed in XML"),
        "import_table": MessageLookupByLibrary.simpleMessage("Import table"),
        "import_table_busy": MessageLookupByLibrary.simpleMessage(
            "This table is still being imported. It opens once its columns and rows are in"),
        "import_table_done":
            MessageLookupByLibrary.simpleMessage("Table imported"),
        "import_table_file_type":
            MessageLookupByLibrary.simpleMessage("Spreadsheets and CSV"),
        "import_table_loading":
            MessageLookupByLibrary.simpleMessage("Loading rows"),
        "import_table_partial": MessageLookupByLibrary.simpleMessage(
            "The table was created, but its rows could not be imported"),
        "import_table_preparing":
            MessageLookupByLibrary.simpleMessage("Setting up columns"),
        "import_table_started": MessageLookupByLibrary.simpleMessage(
            "Table created. Its columns and rows are still loading"),
        "import_table_unsupported": MessageLookupByLibrary.simpleMessage(
            "Only spreadsheet and CSV files can be imported"),
        "inbox": MessageLookupByLibrary.simpleMessage("Inbox"),
        "inventory": MessageLookupByLibrary.simpleMessage("Inventory"),
        "last_name_input": MessageLookupByLibrary.simpleMessage("Last name"),
        "login": MessageLookupByLibrary.simpleMessage("Login"),
        "marketing": MessageLookupByLibrary.simpleMessage("Marketing"),
        "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
        "new_service": MessageLookupByLibrary.simpleMessage("New service"),
        "next": MessageLookupByLibrary.simpleMessage("Next"),
        "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
        "once_a_year": MessageLookupByLibrary.simpleMessage("Once a year"),
        "or_login_with":
            MessageLookupByLibrary.simpleMessage("or log in with:"),
        "password_input": MessageLookupByLibrary.simpleMessage("Password"),
        "password_mismatch":
            MessageLookupByLibrary.simpleMessage("Passwords don\'t match"),
        "past_due": MessageLookupByLibrary.simpleMessage("Past"),
        "pending_funds":
            MessageLookupByLibrary.simpleMessage("Pending Payments"),
        "plan_basic": MessageLookupByLibrary.simpleMessage("Basic"),
        "plan_duo": MessageLookupByLibrary.simpleMessage("Duo"),
        "plan_family": MessageLookupByLibrary.simpleMessage("Family"),
        "plan_freemium": MessageLookupByLibrary.simpleMessage("Freemium"),
        "plan_normal": MessageLookupByLibrary.simpleMessage("Normal"),
        "plan_plus": MessageLookupByLibrary.simpleMessage("Plus"),
        "plan_pro": MessageLookupByLibrary.simpleMessage("Pro"),
        "plan_simple": MessageLookupByLibrary.simpleMessage("Simple"),
        "plan_suggestions":
            MessageLookupByLibrary.simpleMessage("Description suggestions"),
        "pos": MessageLookupByLibrary.simpleMessage("POS"),
        "pos_amount_add": MessageLookupByLibrary.simpleMessage("Add to ticket"),
        "pos_amount_concept": MessageLookupByLibrary.simpleMessage("Concept"),
        "pos_amount_concept_placeholder":
            MessageLookupByLibrary.simpleMessage("What is being charged"),
        "pos_amount_price": MessageLookupByLibrary.simpleMessage("Price"),
        "pos_amount_price_error": MessageLookupByLibrary.simpleMessage(
            "Write the price as a number, zero or more"),
        "pos_amount_price_placeholder":
            MessageLookupByLibrary.simpleMessage("0"),
        "pos_amount_subtitle": MessageLookupByLibrary.simpleMessage(
            "For something the catalog does not have: a delivery, a repair, a fee."),
        "pos_amount_title":
            MessageLookupByLibrary.simpleMessage("Charge an amount"),
        "pos_catalog_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "Import a price list from the inventory section and it will be sold from here"),
        "pos_catalog_empty_title":
            MessageLookupByLibrary.simpleMessage("There are no products yet"),
        "pos_catalog_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "The products did not arrive. Try again."),
        "pos_catalog_error_title": MessageLookupByLibrary.simpleMessage(
            "The catalog could not be loaded"),
        "pos_catalog_missing_subtitle": MessageLookupByLibrary.simpleMessage(
            "This business has no products table yet, so there is nothing to ring up"),
        "pos_catalog_missing_title": MessageLookupByLibrary.simpleMessage(
            "There is no catalog to sell from"),
        "pos_catalog_retry": MessageLookupByLibrary.simpleMessage("Try again"),
        "pos_catalog_search_empty":
            MessageLookupByLibrary.simpleMessage("No product matches"),
        "pos_category_all": MessageLookupByLibrary.simpleMessage("All"),
        "pos_checkout_confirm": MessageLookupByLibrary.simpleMessage("Charge"),
        "pos_checkout_done": m26,
        "pos_checkout_method":
            MessageLookupByLibrary.simpleMessage("Payment method"),
        "pos_checkout_method_empty":
            MessageLookupByLibrary.simpleMessage("No payment method"),
        "pos_checkout_method_placeholder":
            MessageLookupByLibrary.simpleMessage("How it is being paid"),
        "pos_checkout_methods_error": MessageLookupByLibrary.simpleMessage(
            "The payment methods have not been loaded, so nothing can be charged yet"),
        "pos_checkout_reference":
            MessageLookupByLibrary.simpleMessage("Reference"),
        "pos_checkout_reference_error": MessageLookupByLibrary.simpleMessage(
            "Write the payment\'s reference so it can be reconciled"),
        "pos_checkout_reference_placeholder":
            MessageLookupByLibrary.simpleMessage(
                "Confirmation or authorization number"),
        "pos_checkout_title":
            MessageLookupByLibrary.simpleMessage("Charge the ticket"),
        "pos_checkout_total": MessageLookupByLibrary.simpleMessage("To charge"),
        "pos_close": MessageLookupByLibrary.simpleMessage("Close POS"),
        "pos_mode": MessageLookupByLibrary.simpleMessage("POS mode"),
        "pos_product_no_price":
            MessageLookupByLibrary.simpleMessage("No price"),
        "pos_product_no_price_flag": MessageLookupByLibrary.simpleMessage(
            "That product has no price, so it cannot be rung up"),
        "pos_product_stock": m27,
        "pos_product_unnamed":
            MessageLookupByLibrary.simpleMessage("Unnamed product"),
        "pos_sales_today": m28,
        "pos_search_product":
            MessageLookupByLibrary.simpleMessage("Search products"),
        "pos_tax_error":
            MessageLookupByLibrary.simpleMessage("A rate between 0 and 100"),
        "pos_tax_input": MessageLookupByLibrary.simpleMessage("Percentage"),
        "pos_tax_placeholder": MessageLookupByLibrary.simpleMessage("0"),
        "pos_tax_subtitle": MessageLookupByLibrary.simpleMessage(
            "The percentage charged on this ticket. Written as 16, not as 0.16."),
        "pos_tax_title": MessageLookupByLibrary.simpleMessage("VAT rate"),
        "pos_ticket_add_amount":
            MessageLookupByLibrary.simpleMessage("Charge an amount"),
        "pos_ticket_checkout":
            MessageLookupByLibrary.simpleMessage("Complete purchase"),
        "pos_ticket_clear":
            MessageLookupByLibrary.simpleMessage("Delete ticket"),
        "pos_ticket_clear_confirm":
            MessageLookupByLibrary.simpleMessage("Delete it"),
        "pos_ticket_clear_message": MessageLookupByLibrary.simpleMessage(
            "Everything on it comes off, the units it was holding go back on sale and nothing is charged."),
        "pos_ticket_clear_title":
            MessageLookupByLibrary.simpleMessage("Delete this ticket?"),
        "pos_ticket_cleared":
            MessageLookupByLibrary.simpleMessage("Ticket deleted"),
        "pos_ticket_dropped": MessageLookupByLibrary.simpleMessage(
            "This ticket was just cancelled from another screen"),
        "pos_ticket_each": m29,
        "pos_ticket_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "Pick a product from the catalog and it lands here"),
        "pos_ticket_empty_title":
            MessageLookupByLibrary.simpleMessage("The ticket is empty"),
        "pos_ticket_less": MessageLookupByLibrary.simpleMessage("One less"),
        "pos_ticket_more": MessageLookupByLibrary.simpleMessage("One more"),
        "pos_ticket_number": m30,
        "pos_ticket_released": m31,
        "pos_ticket_remove":
            MessageLookupByLibrary.simpleMessage("Take it off the ticket"),
        "pos_ticket_subtotal": MessageLookupByLibrary.simpleMessage("Subtotal"),
        "pos_ticket_taken": MessageLookupByLibrary.simpleMessage(
            "This ticket was just charged from another register"),
        "pos_ticket_tax": m32,
        "pos_ticket_tax_edit": MessageLookupByLibrary.simpleMessage(
            "Change the rate charged on this ticket"),
        "pos_ticket_total": MessageLookupByLibrary.simpleMessage("Total"),
        "pos_ticket_unheld":
            MessageLookupByLibrary.simpleMessage("No longer set aside"),
        "pos_ticket_units": m33,
        "price_title":
            MessageLookupByLibrary.simpleMessage("What\'s the price?"),
        "product_table_view_add_item":
            MessageLookupByLibrary.simpleMessage("Add item"),
        "product_table_view_date_full":
            MessageLookupByLibrary.simpleMessage("Full date"),
        "product_table_view_date_full_hint":
            MessageLookupByLibrary.simpleMessage(
                "Show this column with its numbers and its time"),
        "product_table_view_date_short":
            MessageLookupByLibrary.simpleMessage("Written date"),
        "product_table_view_date_short_hint":
            MessageLookupByLibrary.simpleMessage(
                "Show this column written out, as Feb 12, 2026"),
        "product_table_view_empty_row": MessageLookupByLibrary.simpleMessage(
            "Fill in at least one field to add an item"),
        "product_table_view_empty_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "Add stock to see its rows here."),
        "product_table_view_empty_title":
            MessageLookupByLibrary.simpleMessage("This table is empty"),
        "product_table_view_error_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "Something went wrong. Please try again."),
        "product_table_view_error_title":
            MessageLookupByLibrary.simpleMessage("Couldn\'t load this table"),
        "product_table_view_image_files":
            MessageLookupByLibrary.simpleMessage("Images"),
        "product_table_view_image_large": MessageLookupByLibrary.simpleMessage(
            "That image is over 10 MB. Pick a lighter one."),
        "product_table_view_image_library":
            MessageLookupByLibrary.simpleMessage("Pick an image"),
        "product_table_view_image_remove":
            MessageLookupByLibrary.simpleMessage("Remove image"),
        "product_table_view_image_unsaved":
            MessageLookupByLibrary.simpleMessage(
                "Save this item first to add a picture to it"),
        "product_table_view_image_upload":
            MessageLookupByLibrary.simpleMessage("Upload image"),
        "product_table_view_image_view":
            MessageLookupByLibrary.simpleMessage("View image"),
        "product_table_view_item_added":
            MessageLookupByLibrary.simpleMessage("Item added"),
        "product_table_view_next":
            MessageLookupByLibrary.simpleMessage("Next page"),
        "product_table_view_page": m34,
        "product_table_view_previous":
            MessageLookupByLibrary.simpleMessage("Previous page"),
        "product_table_view_search_count": m35,
        "product_table_view_sku_generate":
            MessageLookupByLibrary.simpleMessage("Generate SKU"),
        "product_table_view_sku_generate_hint":
            MessageLookupByLibrary.simpleMessage(
                "Create a new random code for this item"),
        "product_table_view_title":
            MessageLookupByLibrary.simpleMessage("Table"),
        "product_tables_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "Create your first table to organize your products here."),
        "product_tables_empty_title":
            MessageLookupByLibrary.simpleMessage("No tables yet"),
        "product_tables_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "Something went wrong. Please try again."),
        "product_tables_error_title":
            MessageLookupByLibrary.simpleMessage("Couldn\'t load your tables"),
        "product_tables_retry":
            MessageLookupByLibrary.simpleMessage("Try again"),
        "product_tables_search_empty":
            MessageLookupByLibrary.simpleMessage("No tables match your search"),
        "products": MessageLookupByLibrary.simpleMessage("Products"),
        "rename_table": MessageLookupByLibrary.simpleMessage("Rename table"),
        "rename_table_subtitle": MessageLookupByLibrary.simpleMessage(
            "Change what this table is called. Everything else about it lives in its settings"),
        "report": MessageLookupByLibrary.simpleMessage("Report"),
        "resend_code": MessageLookupByLibrary.simpleMessage("Resend code"),
        "resend_code_timer": m36,
        "sales": MessageLookupByLibrary.simpleMessage("Sales"),
        "sales_all_stages": MessageLookupByLibrary.simpleMessage("Every state"),
        "sales_any_channel":
            MessageLookupByLibrary.simpleMessage("Every channel"),
        "sales_approve_action":
            MessageLookupByLibrary.simpleMessage("Approve the sale"),
        "sales_approve_cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
        "sales_approve_confirm":
            MessageLookupByLibrary.simpleMessage("Approve"),
        "sales_approve_done":
            MessageLookupByLibrary.simpleMessage("Sale approved"),
        "sales_approve_message": MessageLookupByLibrary.simpleMessage(
            "It says the money arrived and closes the sale. Nothing here can see a bank, so this is your word on it: look at the payment proof first."),
        "sales_approve_title":
            MessageLookupByLibrary.simpleMessage("Approve this payment?"),
        "sales_catalog_error": MessageLookupByLibrary.simpleMessage(
            "The states could not be read"),
        "sales_channel": MessageLookupByLibrary.simpleMessage("Channel"),
        "sales_clear": MessageLookupByLibrary.simpleMessage("Clear filters"),
        "sales_column_channel":
            MessageLookupByLibrary.simpleMessage("Came in through"),
        "sales_column_customer":
            MessageLookupByLibrary.simpleMessage("Customer"),
        "sales_column_outstanding":
            MessageLookupByLibrary.simpleMessage("Outstanding"),
        "sales_column_seller": MessageLookupByLibrary.simpleMessage("Sold by"),
        "sales_column_stage": MessageLookupByLibrary.simpleMessage("State"),
        "sales_column_ticket": MessageLookupByLibrary.simpleMessage("Ticket"),
        "sales_column_total": MessageLookupByLibrary.simpleMessage("Total"),
        "sales_column_units": MessageLookupByLibrary.simpleMessage("Units"),
        "sales_column_wait": MessageLookupByLibrary.simpleMessage("Waiting"),
        "sales_count": m37,
        "sales_detail_address":
            MessageLookupByLibrary.simpleMessage("On the number"),
        "sales_detail_attention":
            MessageLookupByLibrary.simpleMessage("Waiting on you"),
        "sales_detail_bot": MessageLookupByLibrary.simpleMessage("Answered by"),
        "sales_detail_channel":
            MessageLookupByLibrary.simpleMessage("Came in through"),
        "sales_detail_chat":
            MessageLookupByLibrary.simpleMessage("Conversation"),
        "sales_detail_closed": MessageLookupByLibrary.simpleMessage("Charged"),
        "sales_detail_collected":
            MessageLookupByLibrary.simpleMessage("Collected"),
        "sales_detail_contact": MessageLookupByLibrary.simpleMessage("Contact"),
        "sales_detail_credit":
            MessageLookupByLibrary.simpleMessage("Sold on credit"),
        "sales_detail_customer_unknown":
            MessageLookupByLibrary.simpleMessage("No name given"),
        "sales_detail_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "Check the connection and try again."),
        "sales_detail_error_title":
            MessageLookupByLibrary.simpleMessage("The sale could not be read"),
        "sales_detail_handover":
            MessageLookupByLibrary.simpleMessage("The handover"),
        "sales_detail_handover_at":
            MessageLookupByLibrary.simpleMessage("Recorded"),
        "sales_detail_handover_by":
            MessageLookupByLibrary.simpleMessage("Recorded by"),
        "sales_detail_handover_mode":
            MessageLookupByLibrary.simpleMessage("How they get it"),
        "sales_detail_handover_none": MessageLookupByLibrary.simpleMessage(
            "There is nothing to hand over yet"),
        "sales_detail_handover_none_deal": MessageLookupByLibrary.simpleMessage(
            "Nobody has rung this up: there is no document to hand over."),
        "sales_detail_handover_none_open": MessageLookupByLibrary.simpleMessage(
            "The ticket has not been charged, so nothing has left the shelf for good."),
        "sales_detail_handover_note":
            MessageLookupByLibrary.simpleMessage("Note"),
        "sales_detail_handover_state":
            MessageLookupByLibrary.simpleMessage("Where it got to"),
        "sales_detail_handover_unstored": MessageLookupByLibrary.simpleMessage(
            "Nobody has recorded this: it is how the sale reads, not what somebody said."),
        "sales_detail_held": MessageLookupByLibrary.simpleMessage("Units held"),
        "sales_detail_hold_expires":
            MessageLookupByLibrary.simpleMessage("Lapses"),
        "sales_detail_hold_units": m38,
        "sales_detail_holds":
            MessageLookupByLibrary.simpleMessage("What the shelf is keeping"),
        "sales_detail_holds_empty": MessageLookupByLibrary.simpleMessage(
            "Nothing is set aside for this customer."),
        "sales_detail_id": MessageLookupByLibrary.simpleMessage("Sale id"),
        "sales_detail_item_available": m39,
        "sales_detail_item_concept":
            MessageLookupByLibrary.simpleMessage("Not a product"),
        "sales_detail_item_gone":
            MessageLookupByLibrary.simpleMessage("No longer sold"),
        "sales_detail_item_held": m40,
        "sales_detail_item_list": m41,
        "sales_detail_item_price":
            MessageLookupByLibrary.simpleMessage("Price"),
        "sales_detail_item_product":
            MessageLookupByLibrary.simpleMessage("Product"),
        "sales_detail_item_qty": MessageLookupByLibrary.simpleMessage("Qty"),
        "sales_detail_item_total":
            MessageLookupByLibrary.simpleMessage("Total"),
        "sales_detail_item_unheld": MessageLookupByLibrary.simpleMessage(
            "Said to be held, and nothing is"),
        "sales_detail_items":
            MessageLookupByLibrary.simpleMessage("What is on it"),
        "sales_detail_items_empty":
            MessageLookupByLibrary.simpleMessage("Nothing on it yet"),
        "sales_detail_items_flags":
            MessageLookupByLibrary.simpleMessage("Worth checking"),
        "sales_detail_items_gone_count": m42,
        "sales_detail_items_lines":
            MessageLookupByLibrary.simpleMessage("Lines"),
        "sales_detail_items_no_match":
            MessageLookupByLibrary.simpleMessage("No line matches the search"),
        "sales_detail_items_open":
            MessageLookupByLibrary.simpleMessage("See the products"),
        "sales_detail_items_search": MessageLookupByLibrary.simpleMessage(
            "Search a product or its code"),
        "sales_detail_items_unheld_count": m43,
        "sales_detail_method":
            MessageLookupByLibrary.simpleMessage("Paid with"),
        "sales_detail_method_offered":
            MessageLookupByLibrary.simpleMessage("Offered to pay with"),
        "sales_detail_missing_subtitle": MessageLookupByLibrary.simpleMessage(
            "Nothing is held for it and nothing was agreed on the money, or it was rung up under another record. Refresh the board to see where it went."),
        "sales_detail_missing_title":
            MessageLookupByLibrary.simpleMessage("This is no longer a sale"),
        "sales_detail_money": MessageLookupByLibrary.simpleMessage("The money"),
        "sales_detail_none": MessageLookupByLibrary.simpleMessage("Not said"),
        "sales_detail_note":
            MessageLookupByLibrary.simpleMessage("Note on the ticket"),
        "sales_detail_open":
            MessageLookupByLibrary.simpleMessage("Open the sale"),
        "sales_detail_opened": MessageLookupByLibrary.simpleMessage("Opened"),
        "sales_detail_outstanding":
            MessageLookupByLibrary.simpleMessage("Still owed"),
        "sales_detail_proof":
            MessageLookupByLibrary.simpleMessage("Payment proof"),
        "sales_detail_proof_at": MessageLookupByLibrary.simpleMessage("Sent"),
        "sales_detail_proof_count": m44,
        "sales_detail_proof_empty": MessageLookupByLibrary.simpleMessage(
            "Nothing has been sent for this sale yet."),
        "sales_detail_proof_file":
            MessageLookupByLibrary.simpleMessage("File sent"),
        "sales_detail_proof_file_failed": MessageLookupByLibrary.simpleMessage(
            "The file could not be opened"),
        "sales_detail_proof_file_open":
            MessageLookupByLibrary.simpleMessage("Open the file"),
        "sales_detail_proof_image":
            MessageLookupByLibrary.simpleMessage("Picture sent"),
        "sales_detail_proof_lost": MessageLookupByLibrary.simpleMessage(
            "A picture came and could not be stored. This is what came with it."),
        "sales_detail_proof_open":
            MessageLookupByLibrary.simpleMessage("See it full size"),
        "sales_detail_proof_reference":
            MessageLookupByLibrary.simpleMessage("Reference given"),
        "sales_detail_proof_said":
            MessageLookupByLibrary.simpleMessage("What they wrote"),
        "sales_detail_proof_subtitle": MessageLookupByLibrary.simpleMessage(
            "What the customer sent to show the money went out. It is what they said and showed, not something anybody here checked."),
        "sales_detail_reference":
            MessageLookupByLibrary.simpleMessage("Reference"),
        "sales_detail_seller": MessageLookupByLibrary.simpleMessage("Sold by"),
        "sales_detail_settled":
            MessageLookupByLibrary.simpleMessage("Nothing owed"),
        "sales_detail_source_chat":
            MessageLookupByLibrary.simpleMessage("Being arranged"),
        "sales_detail_source_invoice":
            MessageLookupByLibrary.simpleMessage("Open at the till"),
        "sales_detail_source_ticket":
            MessageLookupByLibrary.simpleMessage("Charged"),
        "sales_detail_stage_since":
            MessageLookupByLibrary.simpleMessage("At this state since"),
        "sales_detail_status_cancelled":
            MessageLookupByLibrary.simpleMessage("Cancelled"),
        "sales_detail_status_completed":
            MessageLookupByLibrary.simpleMessage("Charged"),
        "sales_detail_status_failed":
            MessageLookupByLibrary.simpleMessage("Failed"),
        "sales_detail_status_open":
            MessageLookupByLibrary.simpleMessage("Open"),
        "sales_detail_subtotal":
            MessageLookupByLibrary.simpleMessage("Subtotal"),
        "sales_detail_tax": MessageLookupByLibrary.simpleMessage("Tax"),
        "sales_detail_tax_rate": m45,
        "sales_detail_terminal": MessageLookupByLibrary.simpleMessage("Till"),
        "sales_detail_title": MessageLookupByLibrary.simpleMessage("Sale"),
        "sales_detail_total": MessageLookupByLibrary.simpleMessage("Total"),
        "sales_detail_trace":
            MessageLookupByLibrary.simpleMessage("Where it comes from"),
        "sales_detail_units": MessageLookupByLibrary.simpleMessage("Units"),
        "sales_detail_unpriced":
            MessageLookupByLibrary.simpleMessage("Nobody has priced it"),
        "sales_detail_untaxed":
            MessageLookupByLibrary.simpleMessage("Nothing has been rung up"),
        "sales_detail_updated":
            MessageLookupByLibrary.simpleMessage("Last movement"),
        "sales_empty_done_subtitle": MessageLookupByLibrary.simpleMessage(
            "A sale lands here once the money has arrived and the customer has the goods."),
        "sales_empty_done_title":
            MessageLookupByLibrary.simpleMessage("No sale finished yet"),
        "sales_empty_filter_subtitle": MessageLookupByLibrary.simpleMessage(
            "Nothing is at that state, or came in through that channel."),
        "sales_empty_filter_title":
            MessageLookupByLibrary.simpleMessage("No sale matches"),
        "sales_empty_process_subtitle": MessageLookupByLibrary.simpleMessage(
            "No sale is waiting on anybody: nothing to charge, nothing to verify, nothing to hand over."),
        "sales_empty_process_title":
            MessageLookupByLibrary.simpleMessage("Nothing pending"),
        "sales_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "Check the connection and try again."),
        "sales_error_title":
            MessageLookupByLibrary.simpleMessage("The sales could not be read"),
        "sales_handover_action":
            MessageLookupByLibrary.simpleMessage("Record the handover"),
        "sales_handover_mode":
            MessageLookupByLibrary.simpleMessage("How they get it"),
        "sales_handover_mode_error": MessageLookupByLibrary.simpleMessage(
            "Choose how the customer gets it"),
        "sales_handover_mode_placeholder": MessageLookupByLibrary.simpleMessage(
            "Handed over, collected or delivered"),
        "sales_handover_note": MessageLookupByLibrary.simpleMessage("Note"),
        "sales_handover_note_placeholder": MessageLookupByLibrary.simpleMessage(
            "A tracking number, who collected it"),
        "sales_handover_same_error": MessageLookupByLibrary.simpleMessage(
            "That is what the sale already says"),
        "sales_handover_save": MessageLookupByLibrary.simpleMessage("Record"),
        "sales_handover_saved":
            MessageLookupByLibrary.simpleMessage("Handover recorded"),
        "sales_handover_state":
            MessageLookupByLibrary.simpleMessage("Where it got to"),
        "sales_handover_state_placeholder":
            MessageLookupByLibrary.simpleMessage(
                "Not sent, dispatched or delivered"),
        "sales_handover_subtitle": MessageLookupByLibrary.simpleMessage(
            "Say how the customer gets this sale and how far that got. Nobody else can: the shelf knows the units left and the ticket knows the money arrived, but only a person knows whether the delivery went out or the customer came for it."),
        "sales_handover_title":
            MessageLookupByLibrary.simpleMessage("Handover"),
        "sales_mine": MessageLookupByLibrary.simpleMessage("Sold by me"),
        "sales_more": MessageLookupByLibrary.simpleMessage("Load more"),
        "sales_pending": m46,
        "sales_retry": MessageLookupByLibrary.simpleMessage("Try again"),
        "sales_search_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "Nothing read so far carries that ticket code, customer or seller. The sale may be further down: load more and search again."),
        "sales_search_empty_title":
            MessageLookupByLibrary.simpleMessage("No sale matches the search"),
        "sales_search_scope": MessageLookupByLibrary.simpleMessage(
            "The search narrows the sales already read, by ticket code, customer and seller."),
        "sales_select_empty":
            MessageLookupByLibrary.simpleMessage("Nothing to choose from"),
        "sales_tab_done": MessageLookupByLibrary.simpleMessage("Completed"),
        "sales_tab_process":
            MessageLookupByLibrary.simpleMessage("In progress"),
        "sales_tickets_only": MessageLookupByLibrary.simpleMessage(
            "Filtering by channel or by seller answers with tickets only: a conversation the assistant is still holding has neither."),
        "sales_wait_days": m47,
        "sales_wait_hours": m48,
        "sales_wait_minutes": m49,
        "sales_wait_now": MessageLookupByLibrary.simpleMessage("just now"),
        "save": MessageLookupByLibrary.simpleMessage("Save"),
        "search": MessageLookupByLibrary.simpleMessage("Search"),
        "search_in_app":
            MessageLookupByLibrary.simpleMessage("Search in the app"),
        "search_subscription":
            MessageLookupByLibrary.simpleMessage("Search for a subscription"),
        "section_connections":
            MessageLookupByLibrary.simpleMessage("Connections"),
        "section_no_business_subtitle": MessageLookupByLibrary.simpleMessage(
            "Create your business to start using this section."),
        "section_no_business_title":
            MessageLookupByLibrary.simpleMessage("No business yet"),
        "section_products": MessageLookupByLibrary.simpleMessage("Products"),
        "section_reports": MessageLookupByLibrary.simpleMessage("Reports"),
        "section_transactions":
            MessageLookupByLibrary.simpleMessage("Transactions"),
        "select_a_service":
            MessageLookupByLibrary.simpleMessage("Select a service"),
        "services": MessageLookupByLibrary.simpleMessage("Services"),
        "shop": MessageLookupByLibrary.simpleMessage("Shop"),
        "sign_in": MessageLookupByLibrary.simpleMessage("Sign in"),
        "sign_in_subtitle": MessageLookupByLibrary.simpleMessage(
            "Log in with your email address"),
        "sign_out": MessageLookupByLibrary.simpleMessage("Sign out"),
        "sign_up": MessageLookupByLibrary.simpleMessage("Sign up"),
        "sign_up_email_title":
            MessageLookupByLibrary.simpleMessage("Email address"),
        "sign_up_first_name_title":
            MessageLookupByLibrary.simpleMessage("First name"),
        "sign_up_last_name_title":
            MessageLookupByLibrary.simpleMessage("Last name"),
        "sign_up_password_title":
            MessageLookupByLibrary.simpleMessage("Create a new password"),
        "sign_up_subtitle": MessageLookupByLibrary.simpleMessage(
            "Create an account with your email address"),
        "sign_up_terms_link":
            MessageLookupByLibrary.simpleMessage("Terms and Conditions"),
        "sign_up_terms_prefix": MessageLookupByLibrary.simpleMessage(
            "By signing up, you agree to our "),
        "stock_move_add_action": MessageLookupByLibrary.simpleMessage("Add"),
        "stock_move_add_hint":
            MessageLookupByLibrary.simpleMessage("Add units"),
        "stock_move_add_reserved":
            MessageLookupByLibrary.simpleMessage("Reserve units"),
        "stock_move_add_stock":
            MessageLookupByLibrary.simpleMessage("Add to stock"),
        "stock_move_available": m50,
        "stock_move_dest_leave":
            MessageLookupByLibrary.simpleMessage("They leave"),
        "stock_move_dest_leave_hint": MessageLookupByLibrary.simpleMessage(
            "Sold, damaged, lost or miscounted: they are not coming back."),
        "stock_move_dest_reserve":
            MessageLookupByLibrary.simpleMessage("To reservations"),
        "stock_move_dest_reserve_hint": MessageLookupByLibrary.simpleMessage(
            "Held for someone. They stop being available to sell."),
        "stock_move_dest_returns":
            MessageLookupByLibrary.simpleMessage("To returns"),
        "stock_move_dest_returns_hint": MessageLookupByLibrary.simpleMessage(
            "Units a customer brought back. They wait there until somebody checks them."),
        "stock_move_destination":
            MessageLookupByLibrary.simpleMessage("What happens with them"),
        "stock_move_note": MessageLookupByLibrary.simpleMessage("Note"),
        "stock_move_note_placeholder": MessageLookupByLibrary.simpleMessage(
            "Explain the movement for whoever audits it later"),
        "stock_move_quantity": MessageLookupByLibrary.simpleMessage("Quantity"),
        "stock_move_quantity_error": m51,
        "stock_move_quantity_error_free": MessageLookupByLibrary.simpleMessage(
            "Enter a whole number greater than zero"),
        "stock_move_quantity_placeholder":
            MessageLookupByLibrary.simpleMessage("How many units"),
        "stock_move_reason": MessageLookupByLibrary.simpleMessage("Reason"),
        "stock_move_reason_empty":
            MessageLookupByLibrary.simpleMessage("No reasons"),
        "stock_move_reason_placeholder":
            MessageLookupByLibrary.simpleMessage("Pick one"),
        "stock_move_release_hint":
            MessageLookupByLibrary.simpleMessage("They go back on sale."),
        "stock_move_reserved": m52,
        "stock_move_saved":
            MessageLookupByLibrary.simpleMessage("Stock updated"),
        "stock_move_step_less": m53,
        "stock_move_step_more": m54,
        "stock_move_take_action":
            MessageLookupByLibrary.simpleMessage("Take out"),
        "stock_move_take_hint":
            MessageLookupByLibrary.simpleMessage("Take units out"),
        "stock_move_take_reserved":
            MessageLookupByLibrary.simpleMessage("Release reservations"),
        "stock_move_take_stock":
            MessageLookupByLibrary.simpleMessage("Take out of stock"),
        "stock_reason_cancelled":
            MessageLookupByLibrary.simpleMessage("Customer cancelled"),
        "stock_reason_correction":
            MessageLookupByLibrary.simpleMessage("Count correction"),
        "stock_reason_customer":
            MessageLookupByLibrary.simpleMessage("Customer return"),
        "stock_reason_damage": MessageLookupByLibrary.simpleMessage("Damaged"),
        "stock_reason_defective":
            MessageLookupByLibrary.simpleMessage("Defective"),
        "stock_reason_expiration":
            MessageLookupByLibrary.simpleMessage("Expired"),
        "stock_reason_hold_expired":
            MessageLookupByLibrary.simpleMessage("The hold ran out"),
        "stock_reason_loss": MessageLookupByLibrary.simpleMessage("Lost"),
        "stock_reason_reintegration":
            MessageLookupByLibrary.simpleMessage("Back on sale"),
        "stock_reason_restock": MessageLookupByLibrary.simpleMessage("Restock"),
        "stock_reason_return_approved":
            MessageLookupByLibrary.simpleMessage("Approved return"),
        "stock_reason_sale": MessageLookupByLibrary.simpleMessage("Sale"),
        "stock_reason_theft": MessageLookupByLibrary.simpleMessage("Theft"),
        "stock_reason_warranty":
            MessageLookupByLibrary.simpleMessage("Warranty"),
        "stock_reason_wrong_item":
            MessageLookupByLibrary.simpleMessage("Wrong item"),
        "stock_summary_count": m55,
        "stock_summary_empty_subtitle": MessageLookupByLibrary.simpleMessage(
            "The products of your main table show up here, with what\'s left of each one."),
        "stock_summary_empty_title":
            MessageLookupByLibrary.simpleMessage("Nothing to count yet"),
        "stock_summary_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "Something went wrong. Please try again."),
        "stock_summary_error_title":
            MessageLookupByLibrary.simpleMessage("Couldn\'t load your stock"),
        "stock_summary_performance":
            MessageLookupByLibrary.simpleMessage("Performance"),
        "stock_summary_reserved":
            MessageLookupByLibrary.simpleMessage("Reserved"),
        "stock_summary_retry":
            MessageLookupByLibrary.simpleMessage("Try again"),
        "stock_summary_search_empty": MessageLookupByLibrary.simpleMessage(
            "No products match your search"),
        "stock_summary_stock": MessageLookupByLibrary.simpleMessage("Stock"),
        "stock_summary_title":
            MessageLookupByLibrary.simpleMessage("Stock summary"),
        "subscription_details_delete":
            MessageLookupByLibrary.simpleMessage("Delete subscription"),
        "subscription_details_domain":
            MessageLookupByLibrary.simpleMessage("Domain"),
        "subscription_details_next_billing":
            MessageLookupByLibrary.simpleMessage("Next billing"),
        "subscription_details_no": MessageLookupByLibrary.simpleMessage("No"),
        "subscription_details_overdue":
            MessageLookupByLibrary.simpleMessage("Overdue"),
        "subscription_details_section_about":
            MessageLookupByLibrary.simpleMessage("About"),
        "subscription_details_section_billing":
            MessageLookupByLibrary.simpleMessage("Billing"),
        "subscription_details_section_details":
            MessageLookupByLibrary.simpleMessage("Details"),
        "subscription_details_service_id":
            MessageLookupByLibrary.simpleMessage("Service ID"),
        "subscription_details_synced":
            MessageLookupByLibrary.simpleMessage("Synced"),
        "subscription_details_yes": MessageLookupByLibrary.simpleMessage("Yes"),
        "summary_date": MessageLookupByLibrary.simpleMessage("Billing date"),
        "summary_period": MessageLookupByLibrary.simpleMessage("Period"),
        "summary_price": MessageLookupByLibrary.simpleMessage("Price"),
        "summary_service": MessageLookupByLibrary.simpleMessage("Service"),
        "summary_title": MessageLookupByLibrary.simpleMessage("All set!"),
        "table_color_title": MessageLookupByLibrary.simpleMessage("Color"),
        "table_created": MessageLookupByLibrary.simpleMessage("Table created"),
        "table_delete_message": m56,
        "table_delete_title":
            MessageLookupByLibrary.simpleMessage("Delete this table?"),
        "table_deleted": MessageLookupByLibrary.simpleMessage("Table deleted"),
        "table_description_placeholder": MessageLookupByLibrary.simpleMessage(
            "What does this table contain?"),
        "table_description_title":
            MessageLookupByLibrary.simpleMessage("Description (optional)"),
        "table_field_count": m57,
        "table_field_delete_confirm":
            MessageLookupByLibrary.simpleMessage("Delete field"),
        "table_field_delete_message": m58,
        "table_field_delete_title":
            MessageLookupByLibrary.simpleMessage("Delete this field?"),
        "table_field_name_placeholder":
            MessageLookupByLibrary.simpleMessage("Name of the field"),
        "table_field_name_title":
            MessageLookupByLibrary.simpleMessage("Field name"),
        "table_field_option_create":
            MessageLookupByLibrary.simpleMessage("New option"),
        "table_field_option_empty": MessageLookupByLibrary.simpleMessage(
            "No option matches your search"),
        "table_field_option_none":
            MessageLookupByLibrary.simpleMessage("No value"),
        "table_field_option_placeholder":
            MessageLookupByLibrary.simpleMessage("Name of the option"),
        "table_field_option_search":
            MessageLookupByLibrary.simpleMessage("Search options"),
        "table_field_remove":
            MessageLookupByLibrary.simpleMessage("Remove field"),
        "table_field_reorder":
            MessageLookupByLibrary.simpleMessage("Drag to reorder"),
        "table_field_type_empty":
            MessageLookupByLibrary.simpleMessage("No type matches your search"),
        "table_field_type_placeholder":
            MessageLookupByLibrary.simpleMessage("Type of information"),
        "table_field_type_title":
            MessageLookupByLibrary.simpleMessage("Field type"),
        "table_fields_empty": MessageLookupByLibrary.simpleMessage(
            "No fields yet. Add the first one to define what each product stores."),
        "table_fields_required": MessageLookupByLibrary.simpleMessage(
            "Add at least one field before creating the table"),
        "table_fields_subtitle": MessageLookupByLibrary.simpleMessage(
            "Each field is a column of the table. Its type tells the AI what information it holds and shapes how it is filled in when adding stock."),
        "table_fields_title": MessageLookupByLibrary.simpleMessage("Fields"),
        "table_normalize":
            MessageLookupByLibrary.simpleMessage("Normalize columns"),
        "table_normalize_confirm":
            MessageLookupByLibrary.simpleMessage("Normalize"),
        "table_normalize_message": MessageLookupByLibrary.simpleMessage(
            "We read a sample of every column and give it the type it should have — a price that compares as a number, a date that sorts, a description the AI can search by meaning — and set how much of each one a bot may see. Columns you already typed or marked yourself are left alone."),
        "table_normalize_narrowed": m59,
        "table_normalize_none": MessageLookupByLibrary.simpleMessage(
            "Every column was already right"),
        "table_normalize_renamed": m60,
        "table_normalize_retyped": m61,
        "table_normalize_running":
            MessageLookupByLibrary.simpleMessage("Normalizing this table"),
        "table_normalize_summarized": m62,
        "table_normalize_title":
            MessageLookupByLibrary.simpleMessage("Normalize this table?"),
        "table_options": MessageLookupByLibrary.simpleMessage("Table options"),
        "table_primary": MessageLookupByLibrary.simpleMessage("Primary"),
        "table_primary_hint": MessageLookupByLibrary.simpleMessage(
            "Your main table. The stock summary always reads this one, so it\'s the table whose columns show up below."),
        "table_record_count": m63,
        "table_renamed": MessageLookupByLibrary.simpleMessage("Table renamed"),
        "table_settings_add": m64,
        "table_settings_agent_filterable":
            MessageLookupByLibrary.simpleMessage("Filterable columns"),
        "table_settings_agent_filterable_hint":
            MessageLookupByLibrary.simpleMessage(
                "What the AI can filter and sort by: every column it\'s told exists"),
        "table_settings_agent_image":
            MessageLookupByLibrary.simpleMessage("Images"),
        "table_settings_agent_image_off":
            MessageLookupByLibrary.simpleMessage("No image column"),
        "table_settings_agent_image_on": MessageLookupByLibrary.simpleMessage(
            "The AI can send pictures of these records"),
        "table_settings_agent_searchable":
            MessageLookupByLibrary.simpleMessage("Search by meaning"),
        "table_settings_agent_searchable_off": MessageLookupByLibrary.simpleMessage(
            "No column is indexed by meaning: the AI can filter this table, but it can\'t be asked for something described in words"),
        "table_settings_agent_searchable_on": MessageLookupByLibrary.simpleMessage(
            "A column is indexed by meaning, so the AI can be asked for something described in words"),
        "table_settings_agent_stock":
            MessageLookupByLibrary.simpleMessage("Stock"),
        "table_settings_agent_stock_off": MessageLookupByLibrary.simpleMessage(
            "No stock column, so nothing here is counted against inventory"),
        "table_settings_agent_stock_on": MessageLookupByLibrary.simpleMessage(
            "A stock column ties this table to the inventory ledger, so the AI can also reserve products"),
        "table_settings_agent_subtitle": MessageLookupByLibrary.simpleMessage(
            "How much of this table a bot reading it can use"),
        "table_settings_agent_title":
            MessageLookupByLibrary.simpleMessage("What the AI sees"),
        "table_settings_agent_visibility":
            MessageLookupByLibrary.simpleMessage("Visibility"),
        "table_settings_agent_visibility_hint":
            MessageLookupByLibrary.simpleMessage(
                "How many columns the AI can quote, use without saying, or doesn\'t know about"),
        "table_settings_available":
            MessageLookupByLibrary.simpleMessage("Available"),
        "table_settings_channels_linked":
            MessageLookupByLibrary.simpleMessage("Chose this table"),
        "table_settings_channels_none":
            MessageLookupByLibrary.simpleMessage("No bot reads this table"),
        "table_settings_channels_none_hint": MessageLookupByLibrary.simpleMessage(
            "Pick it as a channel\'s data source to have that bot answer with it"),
        "table_settings_channels_open":
            MessageLookupByLibrary.simpleMessage("Read every table"),
        "table_settings_channels_open_hint": MessageLookupByLibrary.simpleMessage(
            "These bots have no data source configured, so they read every table this business has — including this one, without anybody having chosen it"),
        "table_settings_channels_subtitle":
            MessageLookupByLibrary.simpleMessage(
                "The bots answering with this table"),
        "table_settings_channels_title":
            MessageLookupByLibrary.simpleMessage("Connected channels"),
        "table_settings_column_count": m65,
        "table_settings_column_field":
            MessageLookupByLibrary.simpleMessage("Column"),
        "table_settings_column_options":
            MessageLookupByLibrary.simpleMessage("Options"),
        "table_settings_column_summary":
            MessageLookupByLibrary.simpleMessage("Inventory summary"),
        "table_settings_column_summary_hide":
            MessageLookupByLibrary.simpleMessage(
                "Leave this column out of the inventory summary"),
        "table_settings_column_summary_off":
            MessageLookupByLibrary.simpleMessage("Excluded"),
        "table_settings_column_summary_on":
            MessageLookupByLibrary.simpleMessage("Shown"),
        "table_settings_column_summary_show":
            MessageLookupByLibrary.simpleMessage(
                "Show this column in the inventory summary"),
        "table_settings_column_type":
            MessageLookupByLibrary.simpleMessage("Type"),
        "table_settings_column_unit":
            MessageLookupByLibrary.simpleMessage("Unit"),
        "table_settings_column_visibility":
            MessageLookupByLibrary.simpleMessage("Visibility"),
        "table_settings_columns_empty": MessageLookupByLibrary.simpleMessage(
            "This table has no columns yet. Write a title in the first free column of the sheet to create one"),
        "table_settings_columns_subtitle": MessageLookupByLibrary.simpleMessage(
            "What each one holds, how much of it the AI sees and which ones the inventory summary shows. All of it is changed right here"),
        "table_settings_columns_summary_count": m66,
        "table_settings_columns_title":
            MessageLookupByLibrary.simpleMessage("Columns"),
        "table_settings_created":
            MessageLookupByLibrary.simpleMessage("Created"),
        "table_settings_dates_subtitle": MessageLookupByLibrary.simpleMessage(
            "A table has two: when its structure last changed and when data last arrived"),
        "table_settings_dates_title":
            MessageLookupByLibrary.simpleMessage("Dates"),
        "table_settings_description":
            MessageLookupByLibrary.simpleMessage("Description"),
        "table_settings_description_empty":
            MessageLookupByLibrary.simpleMessage("No description"),
        "table_settings_edit": m67,
        "table_settings_error_subtitle": MessageLookupByLibrary.simpleMessage(
            "It may have been deleted, or it belongs to another business"),
        "table_settings_error_title": MessageLookupByLibrary.simpleMessage(
            "We couldn\'t open this table"),
        "table_settings_id": MessageLookupByLibrary.simpleMessage("Identifier"),
        "table_settings_id_copied":
            MessageLookupByLibrary.simpleMessage("Identifier copied"),
        "table_settings_id_copy":
            MessageLookupByLibrary.simpleMessage("Copy identifier"),
        "table_settings_id_hide":
            MessageLookupByLibrary.simpleMessage("Hide identifier"),
        "table_settings_id_hint": MessageLookupByLibrary.simpleMessage(
            "The id this table travels under. You\'ll need it to point anything outside the app at it"),
        "table_settings_id_show":
            MessageLookupByLibrary.simpleMessage("Show identifier"),
        "table_settings_last_record":
            MessageLookupByLibrary.simpleMessage("Last record"),
        "table_settings_last_record_hint": MessageLookupByLibrary.simpleMessage(
            "When a row was last stored. Editing an existing row doesn\'t move it"),
        "table_settings_name": MessageLookupByLibrary.simpleMessage("Title"),
        "table_settings_name_hint": MessageLookupByLibrary.simpleMessage(
            "What this table is called everywhere it shows up: the listing, the sheet header and whatever a bot says about it"),
        "table_settings_no_records":
            MessageLookupByLibrary.simpleMessage("No records yet"),
        "table_settings_options": m68,
        "table_settings_options_empty":
            MessageLookupByLibrary.simpleMessage("No options yet"),
        "table_settings_pick_options": MessageLookupByLibrary.simpleMessage(
            "The options this column offers"),
        "table_settings_pick_type": MessageLookupByLibrary.simpleMessage(
            "Change what this column holds"),
        "table_settings_pick_unit": MessageLookupByLibrary.simpleMessage(
            "The symbol this column\'s numbers are written in"),
        "table_settings_pick_visibility": MessageLookupByLibrary.simpleMessage(
            "Change how much the AI sees of this column"),
        "table_settings_records_unknown_hint": MessageLookupByLibrary.simpleMessage(
            "The rows live in a different database than the columns, so the count can fail on its own. It doesn\'t mean the table is empty"),
        "table_settings_refresh":
            MessageLookupByLibrary.simpleMessage("Refresh"),
        "table_settings_stat_channels":
            MessageLookupByLibrary.simpleMessage("Channels"),
        "table_settings_stat_columns":
            MessageLookupByLibrary.simpleMessage("Columns"),
        "table_settings_stat_records":
            MessageLookupByLibrary.simpleMessage("Records"),
        "table_settings_summary_subtitle": MessageLookupByLibrary.simpleMessage(
            "What this table holds and how big it is"),
        "table_settings_summary_title":
            MessageLookupByLibrary.simpleMessage("Table"),
        "table_settings_title":
            MessageLookupByLibrary.simpleMessage("Table settings"),
        "table_settings_type_count": m69,
        "table_settings_types": MessageLookupByLibrary.simpleMessage("Types"),
        "table_settings_unavailable":
            MessageLookupByLibrary.simpleMessage("Not available"),
        "table_settings_unit_create":
            MessageLookupByLibrary.simpleMessage("Set unit"),
        "table_settings_unit_empty":
            MessageLookupByLibrary.simpleMessage("No unit"),
        "table_settings_unit_none":
            MessageLookupByLibrary.simpleMessage("Without unit"),
        "table_settings_unit_placeholder":
            MessageLookupByLibrary.simpleMessage("USD, Bs., kg"),
        "table_settings_unknown":
            MessageLookupByLibrary.simpleMessage("Unknown"),
        "table_settings_untyped": m70,
        "table_settings_untyped_hint": MessageLookupByLibrary.simpleMessage(
            "A column imported from a file is born as text. Giving it its real type is what lets the AI compare it, filter by it and quote it properly. You can change it in the Type column below"),
        "table_settings_updated":
            MessageLookupByLibrary.simpleMessage("Structure updated"),
        "table_settings_updated_hint": MessageLookupByLibrary.simpleMessage(
            "The last change to the table or to any of its columns. Renaming a column or changing its type counts, and neither touches the rows"),
        "table_template_accessories":
            MessageLookupByLibrary.simpleMessage("Accessories"),
        "table_template_appliances":
            MessageLookupByLibrary.simpleMessage("Home appliances"),
        "table_template_beauty":
            MessageLookupByLibrary.simpleMessage("Beauty & personal care"),
        "table_template_blank":
            MessageLookupByLibrary.simpleMessage("Blank template"),
        "table_template_clothing":
            MessageLookupByLibrary.simpleMessage("Clothing"),
        "table_template_electronics":
            MessageLookupByLibrary.simpleMessage("Smartphones & electronics"),
        "table_template_empty": MessageLookupByLibrary.simpleMessage(
            "No template matches your search"),
        "table_template_food":
            MessageLookupByLibrary.simpleMessage("Food & beverages"),
        "table_template_health": MessageLookupByLibrary.simpleMessage("Health"),
        "table_template_home":
            MessageLookupByLibrary.simpleMessage("Home & decor"),
        "table_template_placeholder":
            MessageLookupByLibrary.simpleMessage("Choose a template"),
        "table_template_shoes": MessageLookupByLibrary.simpleMessage("Shoes"),
        "table_template_title":
            MessageLookupByLibrary.simpleMessage("Template"),
        "table_title_input": MessageLookupByLibrary.simpleMessage("Title"),
        "table_title_placeholder":
            MessageLookupByLibrary.simpleMessage("Name of the table"),
        "title": MessageLookupByLibrary.simpleMessage("Title"),
        "title_of_subscription":
            MessageLookupByLibrary.simpleMessage("Title of subscription"),
        "total_expenses":
            MessageLookupByLibrary.simpleMessage("Total Expenses"),
        "trial_duration": MessageLookupByLibrary.simpleMessage("Duration"),
        "trial_period": MessageLookupByLibrary.simpleMessage("Trial period"),
        "trial_price": MessageLookupByLibrary.simpleMessage("Trial price"),
        "upcoming": MessageLookupByLibrary.simpleMessage("Upcoming"),
        "verify_code_subtitle": MessageLookupByLibrary.simpleMessage(
            "Enter the code we sent to your email address"),
        "verify_code_title":
            MessageLookupByLibrary.simpleMessage("Verify your email"),
        "version": MessageLookupByLibrary.simpleMessage("Version"),
        "wallet": MessageLookupByLibrary.simpleMessage("Wallet"),
        "weekly": MessageLookupByLibrary.simpleMessage("Weekly"),
        "write_a_description":
            MessageLookupByLibrary.simpleMessage("Optional description..."),
        "write_a_name": MessageLookupByLibrary.simpleMessage("Write a name"),
        "write_here": MessageLookupByLibrary.simpleMessage("Write here..."),
        "you_decide": MessageLookupByLibrary.simpleMessage("You decide")
      };
}
