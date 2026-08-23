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

  static String m0(days) => "in ${days} days";

  static String m1(days) => "Every ${days} days";

  static String m2(day) => "Day ${day}";

  static String m3(name) =>
      "${name} and everything tied to it start the 60 days: 30 before the deletion period begins, and 30 more until nothing of it is left.";

  static String m4(email) =>
      "${email} stops being one of the addresses this business can be written to. If it\'s the primary one, the oldest of the rest takes its place.";

  static String m5(field) => "Add ${field}";

  static String m6(field) => "Edit ${field}";

  static String m7(provider) =>
      "What ${provider} needs to connect. You can save the channel without them and paste them later";

  static String m8(name) =>
      "Disconnecting ${name} deletes the tokens stored for it. The account can be connected again, but you\'ll have to set it up from scratch.";

  static String m9(count) =>
      "${Intl.plural(count, zero: 'No bots', one: '1 bot', other: '${count} bots')}";

  static String m10(provider) =>
      "What ${provider} needs to connect. You can save the account without them and paste them later";

  static String m11(count) =>
      "${Intl.plural(count, one: 'The bot answering through it is deleted too — pause the account instead to keep it.', other: 'The ${count} bots answering through it are deleted too — pause the account instead to keep them.')}";

  static String m12(name) =>
      "Disconnecting ${name} deletes the credentials stored for it. The account can be connected again, but you\'ll have to set it up from scratch.";

  static String m13(email) => "The ${email} is empty";

  static String m14(email) => "The ${email} is incomplete";

  static String m15(email) => "The ${email} is invalid";

  static String m16(email) => "The ${email} is very long";

  static String m17(page) => "Page ${page}";

  static String m18(count) =>
      "${Intl.plural(count, zero: 'No rows match your search', one: '1 row matches', other: '${count} rows match')}";

  static String m19(time) => "Resend code in ${time}";

  static String m20(name) =>
      "Deleting ${name} removes its fields and everything stored in it. This can\'t be undone.";

  static String m21(count) =>
      "${Intl.plural(count, zero: 'No fields', one: '1 field', other: '${count} fields')}";

  static String m22(name) =>
      "Leaving the name empty deletes ${name} and everything stored in it. This can\'t be undone.";

  static String m23(count) =>
      "${Intl.plural(count, zero: 'No records', one: '1 record', other: '${count} records')}";

  static String m24(field) => "Add ${field}";

  static String m25(count) =>
      "${Intl.plural(count, zero: 'No columns', one: '1 column', other: '${count} columns')}";

  static String m26(field) => "Edit ${field}";

  static String m27(count) =>
      "${Intl.plural(count, one: '1 option', other: '${count} options')}";

  static String m28(type, count) => "${type} · ${count}";

  static String m29(count) =>
      "${Intl.plural(count, one: '1 column is still plain text', other: '${count} columns are still plain text')}";

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
    "already_have_account": MessageLookupByLibrary.simpleMessage(
      "Already have an account?",
    ),
    "amount": MessageLookupByLibrary.simpleMessage("Amount"),
    "annual": MessageLookupByLibrary.simpleMessage("Annual"),
    "back": MessageLookupByLibrary.simpleMessage("Back"),
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
    "billing_days_left": m0,
    "billing_label_custom": m1,
    "billing_label_monthly": m2,
    "billing_period": MessageLookupByLibrary.simpleMessage("Billing period"),
    "billing_today": MessageLookupByLibrary.simpleMessage("Today"),
    "business": MessageLookupByLibrary.simpleMessage("Business"),
    "business_branches_soon": MessageLookupByLibrary.simpleMessage(
      "The locations of this business, each with its address and what it handles, will be listed here.",
    ),
    "business_clients_soon": MessageLookupByLibrary.simpleMessage(
      "The customers of this business and what they bought will be listed here.",
    ),
    "business_delete_action": MessageLookupByLibrary.simpleMessage(
      "Delete business",
    ),
    "business_delete_confirm_message": m3,
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
    "business_email_add": MessageLookupByLibrary.simpleMessage("Add address"),
    "business_email_address": MessageLookupByLibrary.simpleMessage(
      "Email address",
    ),
    "business_email_address_hint": MessageLookupByLibrary.simpleMessage(
      "name@business.com",
    ),
    "business_email_delete_message": m4,
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
    "business_employees_soon": MessageLookupByLibrary.simpleMessage(
      "The people who work in this business, with their role and what each one can do, will be listed here.",
    ),
    "business_employees_total": MessageLookupByLibrary.simpleMessage(
      "People with access",
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
    "business_profile_add": m5,
    "business_profile_address": MessageLookupByLibrary.simpleMessage("Address"),
    "business_profile_caption": MessageLookupByLibrary.simpleMessage("Tagline"),
    "business_profile_caption_note": MessageLookupByLibrary.simpleMessage(
      "One line about what this business does. It reads under its name, so it\'s what someone who doesn\'t know it yet reads first.",
    ),
    "business_profile_country": MessageLookupByLibrary.simpleMessage("Country"),
    "business_profile_country_hint": MessageLookupByLibrary.simpleMessage(
      "ISO code (US, ES, VE)",
    ),
    "business_profile_country_note": MessageLookupByLibrary.simpleMessage(
      "Where the business is registered, as its two-letter code. It sets which rules and taxes apply.",
    ),
    "business_profile_created": MessageLookupByLibrary.simpleMessage(
      "Registered on",
    ),
    "business_profile_currencies": MessageLookupByLibrary.simpleMessage(
      "Also quotes in",
    ),
    "business_profile_currencies_note": MessageLookupByLibrary.simpleMessage(
      "Other currencies this business also quotes prices in. They\'re changed where its currencies are set up.",
    ),
    "business_profile_currency": MessageLookupByLibrary.simpleMessage(
      "Currency",
    ),
    "business_profile_currency_note": MessageLookupByLibrary.simpleMessage(
      "The currency this business writes its prices in. Changing it wouldn\'t convert a single price, it would relabel every one of them, so it isn\'t changed from here.",
    ),
    "business_profile_edit": m6,
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
    "channel_created": MessageLookupByLibrary.simpleMessage(
      "Channel connected",
    ),
    "channel_credentials_subtitle": m7,
    "channel_credentials_title": MessageLookupByLibrary.simpleMessage(
      "Credentials",
    ),
    "channel_delete_message": m8,
    "channel_delete_title": MessageLookupByLibrary.simpleMessage(
      "Disconnect this channel?",
    ),
    "channel_deleted": MessageLookupByLibrary.simpleMessage(
      "Channel disconnected",
    ),
    "channel_description_input": MessageLookupByLibrary.simpleMessage(
      "Description",
    ),
    "channel_description_placeholder": MessageLookupByLibrary.simpleMessage(
      "Optional description...",
    ),
    "channel_field_required": MessageLookupByLibrary.simpleMessage(
      "required to run",
    ),
    "channel_identity_subtitle": MessageLookupByLibrary.simpleMessage(
      "How you\'ll recognize this channel in your list",
    ),
    "channel_identity_title": MessageLookupByLibrary.simpleMessage("Channel"),
    "channel_missing_title": MessageLookupByLibrary.simpleMessage(
      "This channel isn\'t running yet",
    ),
    "channel_name_input": MessageLookupByLibrary.simpleMessage("Name"),
    "channel_name_placeholder": MessageLookupByLibrary.simpleMessage(
      "Sales, Support...",
    ),
    "channel_open_error_subtitle": MessageLookupByLibrary.simpleMessage(
      "It may have been disconnected, or it belongs to another business",
    ),
    "channel_open_error_title": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t open this channel",
    ),
    "channel_options": MessageLookupByLibrary.simpleMessage("Channel options"),
    "channel_pause": MessageLookupByLibrary.simpleMessage("Pause channel"),
    "channel_paused": MessageLookupByLibrary.simpleMessage("Channel paused"),
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
    "channels_search_empty": MessageLookupByLibrary.simpleMessage(
      "No channel matches your search",
    ),
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
    "connection_bot_count": m9,
    "connection_catalog_error": MessageLookupByLibrary.simpleMessage(
      "We couldn\'t load the available services",
    ),
    "connection_created": MessageLookupByLibrary.simpleMessage(
      "Account connected",
    ),
    "connection_credentials_subtitle": m10,
    "connection_credentials_title": MessageLookupByLibrary.simpleMessage(
      "Credentials",
    ),
    "connection_delete_bots": m11,
    "connection_delete_message": m12,
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
    "conversations": MessageLookupByLibrary.simpleMessage("Conversations"),
    "conversations_empty_subtitle": MessageLookupByLibrary.simpleMessage(
      "Here you\'ll read what your channels are talking about with your customers",
    ),
    "conversations_empty_title": MessageLookupByLibrary.simpleMessage(
      "No conversations yet",
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
    "description": MessageLookupByLibrary.simpleMessage("Description"),
    "dont_have_account": MessageLookupByLibrary.simpleMessage(
      "Don\'t have an account yet?",
    ),
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
    "enter_days": MessageLookupByLibrary.simpleMessage("Number of days"),
    "expand": MessageLookupByLibrary.simpleMessage("Expand"),
    "external_services": MessageLookupByLibrary.simpleMessage(
      "External Services",
    ),
    "field_added": MessageLookupByLibrary.simpleMessage("Field added"),
    "field_type_boolean": MessageLookupByLibrary.simpleMessage("Yes / No"),
    "field_type_boolean_hint": MessageLookupByLibrary.simpleMessage(
      "Something that is either on or off",
    ),
    "field_type_counter": MessageLookupByLibrary.simpleMessage("Counter"),
    "field_type_counter_hint": MessageLookupByLibrary.simpleMessage(
      "A number that goes up on its own",
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
      "Numbers with decimals: weights and measures",
    ),
    "field_type_email": MessageLookupByLibrary.simpleMessage("Email"),
    "field_type_email_hint": MessageLookupByLibrary.simpleMessage(
      "An email address",
    ),
    "field_type_image": MessageLookupByLibrary.simpleMessage("Image"),
    "field_type_image_hint": MessageLookupByLibrary.simpleMessage(
      "Photos of the product",
    ),
    "field_type_number": MessageLookupByLibrary.simpleMessage("Number"),
    "field_type_number_hint": MessageLookupByLibrary.simpleMessage(
      "Whole numbers: units, sizes, quantities",
    ),
    "field_type_phone": MessageLookupByLibrary.simpleMessage("Phone"),
    "field_type_phone_hint": MessageLookupByLibrary.simpleMessage(
      "A phone number",
    ),
    "field_type_price": MessageLookupByLibrary.simpleMessage("Price"),
    "field_type_price_hint": MessageLookupByLibrary.simpleMessage(
      "A monetary amount",
    ),
    "field_type_select": MessageLookupByLibrary.simpleMessage("Options list"),
    "field_type_select_hint": MessageLookupByLibrary.simpleMessage(
      "A closed list of options to pick from",
    ),
    "field_type_sku": MessageLookupByLibrary.simpleMessage("SKU"),
    "field_type_sku_hint": MessageLookupByLibrary.simpleMessage(
      "Reference or article code, like a barcode",
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
      "Multiline text: descriptions and notes",
    ),
    "field_type_url": MessageLookupByLibrary.simpleMessage("Link"),
    "field_type_url_hint": MessageLookupByLibrary.simpleMessage(
      "A web address",
    ),
    "field_type_vector": MessageLookupByLibrary.simpleMessage("Smart text"),
    "field_type_vector_hint": MessageLookupByLibrary.simpleMessage(
      "Free text the AI reads and searches by meaning",
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
    "first_name_input": MessageLookupByLibrary.simpleMessage("First name"),
    "form_empty_ma": m13,
    "form_incomplete_ma": m14,
    "form_invalid_ma": m15,
    "form_long_ma": m16,
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
    "import_table": MessageLookupByLibrary.simpleMessage("Import table"),
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
    "last_name_input": MessageLookupByLibrary.simpleMessage("Last name"),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "marketing": MessageLookupByLibrary.simpleMessage("Marketing"),
    "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
    "new_service": MessageLookupByLibrary.simpleMessage("New service"),
    "next": MessageLookupByLibrary.simpleMessage("Next"),
    "notifications": MessageLookupByLibrary.simpleMessage("Notifications"),
    "once_a_year": MessageLookupByLibrary.simpleMessage("Once a year"),
    "or_login_with": MessageLookupByLibrary.simpleMessage("or log in with:"),
    "password_input": MessageLookupByLibrary.simpleMessage("Password"),
    "password_mismatch": MessageLookupByLibrary.simpleMessage(
      "Passwords don\'t match",
    ),
    "past_due": MessageLookupByLibrary.simpleMessage("Past"),
    "pending_funds": MessageLookupByLibrary.simpleMessage("Pending Payments"),
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
    "product_table_view_page": m17,
    "product_table_view_previous": MessageLookupByLibrary.simpleMessage(
      "Previous page",
    ),
    "product_table_view_search_count": m18,
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
    "resend_code_timer": m19,
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "search_channel": MessageLookupByLibrary.simpleMessage("Search channels"),
    "search_in_app": MessageLookupByLibrary.simpleMessage("Search in the app"),
    "search_subscription": MessageLookupByLibrary.simpleMessage(
      "Search for a subscription",
    ),
    "section_connections": MessageLookupByLibrary.simpleMessage("Connections"),
    "section_no_business_subtitle": MessageLookupByLibrary.simpleMessage(
      "Create your business to start using this section.",
    ),
    "section_no_business_title": MessageLookupByLibrary.simpleMessage(
      "No business yet",
    ),
    "section_products": MessageLookupByLibrary.simpleMessage("Products"),
    "section_reports": MessageLookupByLibrary.simpleMessage("Reports"),
    "select_a_service": MessageLookupByLibrary.simpleMessage(
      "Select a service",
    ),
    "services": MessageLookupByLibrary.simpleMessage("Services"),
    "shop": MessageLookupByLibrary.simpleMessage("Shop"),
    "sign_in": MessageLookupByLibrary.simpleMessage("Sign in"),
    "sign_in_subtitle": MessageLookupByLibrary.simpleMessage(
      "Log in with your email address",
    ),
    "sign_out": MessageLookupByLibrary.simpleMessage("Sign out"),
    "sign_up": MessageLookupByLibrary.simpleMessage("Sign up"),
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
    "sign_up_subtitle": MessageLookupByLibrary.simpleMessage(
      "Create an account with your email address",
    ),
    "sign_up_terms_link": MessageLookupByLibrary.simpleMessage(
      "Terms and Conditions",
    ),
    "sign_up_terms_prefix": MessageLookupByLibrary.simpleMessage(
      "By signing up, you agree to our ",
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
    "table_delete_message": m20,
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
    "table_field_count": m21,
    "table_field_delete_confirm": MessageLookupByLibrary.simpleMessage(
      "Delete field",
    ),
    "table_field_delete_message": m22,
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
    "table_options": MessageLookupByLibrary.simpleMessage("Table options"),
    "table_record_count": m23,
    "table_renamed": MessageLookupByLibrary.simpleMessage("Table renamed"),
    "table_settings_add": m24,
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
    "table_settings_agent_visibility_hint":
        MessageLookupByLibrary.simpleMessage(
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
    "table_settings_column_count": m25,
    "table_settings_column_field": MessageLookupByLibrary.simpleMessage(
      "Column",
    ),
    "table_settings_column_options": MessageLookupByLibrary.simpleMessage(
      "Options",
    ),
    "table_settings_column_type": MessageLookupByLibrary.simpleMessage("Type"),
    "table_settings_column_visibility": MessageLookupByLibrary.simpleMessage(
      "Visibility",
    ),
    "table_settings_columns_empty": MessageLookupByLibrary.simpleMessage(
      "This table has no columns yet. Write a title in the first free column of the sheet to create one",
    ),
    "table_settings_columns_subtitle": MessageLookupByLibrary.simpleMessage(
      "What each one holds and how much of it the AI sees. Both are changed right here",
    ),
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
    "table_settings_edit": m26,
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
    "table_settings_options": m27,
    "table_settings_options_empty": MessageLookupByLibrary.simpleMessage(
      "No options yet",
    ),
    "table_settings_pick_options": MessageLookupByLibrary.simpleMessage(
      "The options this column offers",
    ),
    "table_settings_pick_type": MessageLookupByLibrary.simpleMessage(
      "Change what this column holds",
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
    "table_settings_type_count": m28,
    "table_settings_types": MessageLookupByLibrary.simpleMessage("Types"),
    "table_settings_unavailable": MessageLookupByLibrary.simpleMessage(
      "Not available",
    ),
    "table_settings_unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
    "table_settings_untyped": m29,
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
    "verify_code_subtitle": MessageLookupByLibrary.simpleMessage(
      "Enter the code we sent to your email address",
    ),
    "verify_code_title": MessageLookupByLibrary.simpleMessage(
      "Verify your email",
    ),
    "version": MessageLookupByLibrary.simpleMessage("Version"),
    "wallet": MessageLookupByLibrary.simpleMessage("Wallet"),
    "weekly": MessageLookupByLibrary.simpleMessage("Weekly"),
    "write_a_description": MessageLookupByLibrary.simpleMessage(
      "Optional description...",
    ),
    "write_a_name": MessageLookupByLibrary.simpleMessage("Write a name"),
    "write_here": MessageLookupByLibrary.simpleMessage("Write here..."),
    "you_decide": MessageLookupByLibrary.simpleMessage("You decide"),
  };
}
