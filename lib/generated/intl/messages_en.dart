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

  static String m3(email) => "The ${email} is empty";

  static String m4(email) => "The ${email} is incomplete";

  static String m5(email) => "The ${email} is invalid";

  static String m6(email) => "The ${email} is very long";

  static String m7(page) => "Page ${page}";

  static String m8(time) => "Resend code in ${time}";

  static String m9(count) =>
      "${Intl.plural(count, zero: 'No fields', one: '1 field', other: '${count} fields')}";

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
    "business_profile_id": MessageLookupByLibrary.simpleMessage("Identifier"),
    "business_profile_membership": MessageLookupByLibrary.simpleMessage(
      "Your access",
    ),
    "business_profile_not_found_subtitle": MessageLookupByLibrary.simpleMessage(
      "This business is no longer in your list.",
    ),
    "business_profile_not_found_title": MessageLookupByLibrary.simpleMessage(
      "Business not found",
    ),
    "business_profile_rank": MessageLookupByLibrary.simpleMessage("Your role"),
    "business_profile_state": MessageLookupByLibrary.simpleMessage(
      "Operating state",
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
    "business_status_active": MessageLookupByLibrary.simpleMessage("Active"),
    "business_status_pending": MessageLookupByLibrary.simpleMessage("Pending"),
    "business_status_restricted": MessageLookupByLibrary.simpleMessage(
      "Restricted",
    ),
    "business_status_unknown": MessageLookupByLibrary.simpleMessage("Unknown"),
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
    "business_type_input": MessageLookupByLibrary.simpleMessage(
      "Type of activity",
    ),
    "business_type_other": MessageLookupByLibrary.simpleMessage("Other"),
    "business_type_placeholder": MessageLookupByLibrary.simpleMessage(
      "Select the main activity",
    ),
    "business_type_professional": MessageLookupByLibrary.simpleMessage(
      "Professional services",
    ),
    "business_type_retail": MessageLookupByLibrary.simpleMessage("Retail"),
    "business_type_technology": MessageLookupByLibrary.simpleMessage(
      "Technology",
    ),
    "business_type_transport": MessageLookupByLibrary.simpleMessage(
      "Transport and logistics",
    ),
    "cancel": MessageLookupByLibrary.simpleMessage("Cancel"),
    "code_input": MessageLookupByLibrary.simpleMessage("Code"),
    "collapse": MessageLookupByLibrary.simpleMessage("Collapse"),
    "confirm": MessageLookupByLibrary.simpleMessage("Confirm"),
    "confirm_password_input": MessageLookupByLibrary.simpleMessage(
      "Confirm password",
    ),
    "connectionError": MessageLookupByLibrary.simpleMessage(
      "Sorry, there was a connection error, please try again later",
    ),
    "create_business": MessageLookupByLibrary.simpleMessage("Create business"),
    "create_business_subtitle": MessageLookupByLibrary.simpleMessage(
      "Tell us about the business you want to manage",
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
    "finance": MessageLookupByLibrary.simpleMessage("Finance"),
    "first_name_input": MessageLookupByLibrary.simpleMessage("First name"),
    "form_empty_ma": m3,
    "form_incomplete_ma": m4,
    "form_invalid_ma": m5,
    "form_long_ma": m6,
    "hide_keyboard": MessageLookupByLibrary.simpleMessage("Hide keyboard"),
    "home": MessageLookupByLibrary.simpleMessage("Home"),
    "how_often_pay": MessageLookupByLibrary.simpleMessage(
      "How often do you pay?",
    ),
    "import_table": MessageLookupByLibrary.simpleMessage("Import table"),
    "last_name_input": MessageLookupByLibrary.simpleMessage("Last name"),
    "login": MessageLookupByLibrary.simpleMessage("Login"),
    "marketing": MessageLookupByLibrary.simpleMessage("Marketing"),
    "monthly": MessageLookupByLibrary.simpleMessage("Monthly"),
    "my_bots": MessageLookupByLibrary.simpleMessage("My Bots"),
    "new_service": MessageLookupByLibrary.simpleMessage("New service"),
    "next": MessageLookupByLibrary.simpleMessage("Next"),
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
    "product_table_view_item_added": MessageLookupByLibrary.simpleMessage(
      "Item added",
    ),
    "product_table_view_next": MessageLookupByLibrary.simpleMessage(
      "Next page",
    ),
    "product_table_view_page": m7,
    "product_table_view_previous": MessageLookupByLibrary.simpleMessage(
      "Previous page",
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
    "report": MessageLookupByLibrary.simpleMessage("Report"),
    "resend_code": MessageLookupByLibrary.simpleMessage("Resend code"),
    "resend_code_timer": m8,
    "save": MessageLookupByLibrary.simpleMessage("Save"),
    "search": MessageLookupByLibrary.simpleMessage("Search"),
    "search_in_app": MessageLookupByLibrary.simpleMessage("Search in the app"),
    "search_subscription": MessageLookupByLibrary.simpleMessage(
      "Search for a subscription",
    ),
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
    "table_description_placeholder": MessageLookupByLibrary.simpleMessage(
      "What does this table contain?",
    ),
    "table_description_title": MessageLookupByLibrary.simpleMessage(
      "Description (optional)",
    ),
    "table_field_count": m9,
    "table_field_name_placeholder": MessageLookupByLibrary.simpleMessage(
      "Name of the field",
    ),
    "table_field_name_title": MessageLookupByLibrary.simpleMessage(
      "Field name",
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
