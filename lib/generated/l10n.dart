// GENERATED CODE - DO NOT MODIFY BY HAND
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'intl/messages_all.dart';

// **************************************************************************
// Generator: Flutter Intl IDE plugin
// Made by Localizely
// **************************************************************************

// ignore_for_file: non_constant_identifier_names, lines_longer_than_80_chars
// ignore_for_file: join_return_with_assignment, prefer_final_in_for_each
// ignore_for_file: avoid_redundant_argument_values, avoid_escaping_inner_quotes

class S {
  S();

  static S? _current;

  static S get current {
    assert(
      _current != null,
      'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.',
    );
    return _current!;
  }

  static const AppLocalizationDelegate delegate = AppLocalizationDelegate();

  static Future<S> load(Locale locale) {
    final name = (locale.countryCode?.isEmpty ?? false)
        ? locale.languageCode
        : locale.toString();
    final localeName = Intl.canonicalizedLocale(name);
    return initializeMessages(localeName).then((_) {
      Intl.defaultLocale = localeName;
      final instance = S();
      S._current = instance;

      return instance;
    });
  }

  static S of(BuildContext context) {
    final instance = S.maybeOf(context);
    assert(
      instance != null,
      'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?',
    );
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Search`
  String get search {
    return Intl.message('Search', name: 'search', desc: '', args: []);
  }

  /// `Hide keyboard`
  String get hide_keyboard {
    return Intl.message(
      'Hide keyboard',
      name: 'hide_keyboard',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get email_input {
    return Intl.message('Email', name: 'email_input', desc: '', args: []);
  }

  /// `Password`
  String get password_input {
    return Intl.message('Password', name: 'password_input', desc: '', args: []);
  }

  /// `Version`
  String get version {
    return Intl.message('Version', name: 'version', desc: '', args: []);
  }

  /// `Login`
  String get login {
    return Intl.message('Login', name: 'login', desc: '', args: []);
  }

  /// `The {email} is very long`
  String form_long_ma(Object email) {
    return Intl.message(
      'The $email is very long',
      name: 'form_long_ma',
      desc: '',
      args: [email],
    );
  }

  /// `The {email} is empty`
  String form_empty_ma(Object email) {
    return Intl.message(
      'The $email is empty',
      name: 'form_empty_ma',
      desc: '',
      args: [email],
    );
  }

  /// `The {email} is invalid`
  String form_invalid_ma(Object email) {
    return Intl.message(
      'The $email is invalid',
      name: 'form_invalid_ma',
      desc: '',
      args: [email],
    );
  }

  /// `The {email} is incomplete`
  String form_incomplete_ma(Object email) {
    return Intl.message(
      'The $email is incomplete',
      name: 'form_incomplete_ma',
      desc: '',
      args: [email],
    );
  }

  /// `Sign in`
  String get sign_in {
    return Intl.message('Sign in', name: 'sign_in', desc: '', args: []);
  }

  /// `Edit`
  String get edit {
    return Intl.message('Edit', name: 'edit', desc: '', args: []);
  }

  /// `Cancel`
  String get cancel {
    return Intl.message('Cancel', name: 'cancel', desc: '', args: []);
  }

  /// `Save`
  String get save {
    return Intl.message('Save', name: 'save', desc: '', args: []);
  }

  /// `Title and description`
  String get edit_about_title {
    return Intl.message(
      'Title and description',
      name: 'edit_about_title',
      desc: '',
      args: [],
    );
  }

  /// `Edit price`
  String get edit_price_title {
    return Intl.message(
      'Edit price',
      name: 'edit_price_title',
      desc: '',
      args: [],
    );
  }

  /// `Edit currency`
  String get edit_currency_title {
    return Intl.message(
      'Edit currency',
      name: 'edit_currency_title',
      desc: '',
      args: [],
    );
  }

  /// `Billing period`
  String get edit_billing_title {
    return Intl.message(
      'Billing period',
      name: 'edit_billing_title',
      desc: '',
      args: [],
    );
  }

  /// `Log in with your email address`
  String get sign_in_subtitle {
    return Intl.message(
      'Log in with your email address',
      name: 'sign_in_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `or log in with:`
  String get or_login_with {
    return Intl.message(
      'or log in with:',
      name: 'or_login_with',
      desc: '',
      args: [],
    );
  }

  /// `Pending Payments`
  String get pending_funds {
    return Intl.message(
      'Pending Payments',
      name: 'pending_funds',
      desc: '',
      args: [],
    );
  }

  /// `Don't have an account yet?`
  String get dont_have_account {
    return Intl.message(
      'Don\'t have an account yet?',
      name: 'dont_have_account',
      desc: '',
      args: [],
    );
  }

  /// `Sorry, there was a connection error, please try again later`
  String get connectionError {
    return Intl.message(
      'Sorry, there was a connection error, please try again later',
      name: 'connectionError',
      desc: '',
      args: [],
    );
  }

  /// `Sign up`
  String get sign_up {
    return Intl.message('Sign up', name: 'sign_up', desc: '', args: []);
  }

  /// `Create an account with your email address`
  String get sign_up_subtitle {
    return Intl.message(
      'Create an account with your email address',
      name: 'sign_up_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Confirm password`
  String get confirm_password_input {
    return Intl.message(
      'Confirm password',
      name: 'confirm_password_input',
      desc: '',
      args: [],
    );
  }

  /// `Passwords don't match`
  String get password_mismatch {
    return Intl.message(
      'Passwords don\'t match',
      name: 'password_mismatch',
      desc: '',
      args: [],
    );
  }

  /// `Already have an account?`
  String get already_have_account {
    return Intl.message(
      'Already have an account?',
      name: 'already_have_account',
      desc: '',
      args: [],
    );
  }

  /// `Email address`
  String get sign_up_email_title {
    return Intl.message(
      'Email address',
      name: 'sign_up_email_title',
      desc: '',
      args: [],
    );
  }

  /// `First name`
  String get sign_up_first_name_title {
    return Intl.message(
      'First name',
      name: 'sign_up_first_name_title',
      desc: '',
      args: [],
    );
  }

  /// `Last name`
  String get sign_up_last_name_title {
    return Intl.message(
      'Last name',
      name: 'sign_up_last_name_title',
      desc: '',
      args: [],
    );
  }

  /// `First name`
  String get first_name_input {
    return Intl.message(
      'First name',
      name: 'first_name_input',
      desc: '',
      args: [],
    );
  }

  /// `Last name`
  String get last_name_input {
    return Intl.message(
      'Last name',
      name: 'last_name_input',
      desc: '',
      args: [],
    );
  }

  /// `Create a new password`
  String get sign_up_password_title {
    return Intl.message(
      'Create a new password',
      name: 'sign_up_password_title',
      desc: '',
      args: [],
    );
  }

  /// `By signing up, you agree to our `
  String get sign_up_terms_prefix {
    return Intl.message(
      'By signing up, you agree to our ',
      name: 'sign_up_terms_prefix',
      desc: '',
      args: [],
    );
  }

  /// `Terms and Conditions`
  String get sign_up_terms_link {
    return Intl.message(
      'Terms and Conditions',
      name: 'sign_up_terms_link',
      desc: '',
      args: [],
    );
  }

  /// `Verify your email`
  String get verify_code_title {
    return Intl.message(
      'Verify your email',
      name: 'verify_code_title',
      desc: '',
      args: [],
    );
  }

  /// `Enter the code we sent to your email address`
  String get verify_code_subtitle {
    return Intl.message(
      'Enter the code we sent to your email address',
      name: 'verify_code_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Code`
  String get code_input {
    return Intl.message('Code', name: 'code_input', desc: '', args: []);
  }

  /// `Resend code in {time}`
  String resend_code_timer(Object time) {
    return Intl.message(
      'Resend code in $time',
      name: 'resend_code_timer',
      desc: '',
      args: [time],
    );
  }

  /// `Resend code`
  String get resend_code {
    return Intl.message('Resend code', name: 'resend_code', desc: '', args: []);
  }

  /// `Title`
  String get title {
    return Intl.message('Title', name: 'title', desc: '', args: []);
  }

  /// `Wallet`
  String get wallet {
    return Intl.message('Wallet', name: 'wallet', desc: '', args: []);
  }

  /// `Add`
  String get add {
    return Intl.message('Add', name: 'add', desc: '', args: []);
  }

  /// `Add subscription`
  String get add_subscription {
    return Intl.message(
      'Add subscription',
      name: 'add_subscription',
      desc: '',
      args: [],
    );
  }

  /// `Add new subscription`
  String get add_new_subscription {
    return Intl.message(
      'Add new subscription',
      name: 'add_new_subscription',
      desc: '',
      args: [],
    );
  }

  /// `Search for a subscription`
  String get search_subscription {
    return Intl.message(
      'Search for a subscription',
      name: 'search_subscription',
      desc: '',
      args: [],
    );
  }

  /// `Search in the app`
  String get search_in_app {
    return Intl.message(
      'Search in the app',
      name: 'search_in_app',
      desc: '',
      args: [],
    );
  }

  /// `Total Expenses`
  String get total_expenses {
    return Intl.message(
      'Total Expenses',
      name: 'total_expenses',
      desc: '',
      args: [],
    );
  }

  /// `Title of subscription`
  String get title_of_subscription {
    return Intl.message(
      'Title of subscription',
      name: 'title_of_subscription',
      desc: '',
      args: [],
    );
  }

  /// `Write here...`
  String get write_here {
    return Intl.message(
      'Write here...',
      name: 'write_here',
      desc: '',
      args: [],
    );
  }

  /// `Select a service`
  String get select_a_service {
    return Intl.message(
      'Select a service',
      name: 'select_a_service',
      desc: '',
      args: [],
    );
  }

  /// `Create business`
  String get create_business {
    return Intl.message(
      'Create business',
      name: 'create_business',
      desc: '',
      args: [],
    );
  }

  /// `Write a name`
  String get write_a_name {
    return Intl.message(
      'Write a name',
      name: 'write_a_name',
      desc: '',
      args: [],
    );
  }

  /// `Day`
  String get billing_day {
    return Intl.message('Day', name: 'billing_day', desc: '', args: []);
  }

  /// `Amount`
  String get amount {
    return Intl.message('Amount', name: 'amount', desc: '', args: []);
  }

  /// `Home`
  String get home {
    return Intl.message('Home', name: 'home', desc: '', args: []);
  }

  /// `Shop`
  String get shop {
    return Intl.message('Shop', name: 'shop', desc: '', args: []);
  }

  /// `Account`
  String get account {
    return Intl.message('Account', name: 'account', desc: '', args: []);
  }

  /// `Billing period`
  String get billing_period {
    return Intl.message(
      'Billing period',
      name: 'billing_period',
      desc: '',
      args: [],
    );
  }

  /// `Weekly`
  String get weekly {
    return Intl.message('Weekly', name: 'weekly', desc: '', args: []);
  }

  /// `Monthly`
  String get monthly {
    return Intl.message('Monthly', name: 'monthly', desc: '', args: []);
  }

  /// `Annual`
  String get annual {
    return Intl.message('Annual', name: 'annual', desc: '', args: []);
  }

  /// `Custom`
  String get custom {
    return Intl.message('Custom', name: 'custom', desc: '', args: []);
  }

  /// `Days`
  String get custom_days {
    return Intl.message('Days', name: 'custom_days', desc: '', args: []);
  }

  /// `New service`
  String get new_service {
    return Intl.message('New service', name: 'new_service', desc: '', args: []);
  }

  /// `Trial period`
  String get trial_period {
    return Intl.message(
      'Trial period',
      name: 'trial_period',
      desc: '',
      args: [],
    );
  }

  /// `Duration`
  String get trial_duration {
    return Intl.message('Duration', name: 'trial_duration', desc: '', args: []);
  }

  /// `Trial price`
  String get trial_price {
    return Intl.message('Trial price', name: 'trial_price', desc: '', args: []);
  }

  /// `Back`
  String get back {
    return Intl.message('Back', name: 'back', desc: '', args: []);
  }

  /// `a`
  String get a {
    return Intl.message('a', name: 'a', desc: '', args: []);
  }

  /// `Next`
  String get next {
    return Intl.message('Next', name: 'next', desc: '', args: []);
  }

  /// `Currency`
  String get currency {
    return Intl.message('Currency', name: 'currency', desc: '', args: []);
  }

  /// `USD`
  String get currency_usd {
    return Intl.message('USD', name: 'currency_usd', desc: '', args: []);
  }

  /// `EUR`
  String get currency_eur {
    return Intl.message('EUR', name: 'currency_eur', desc: '', args: []);
  }

  /// `Local`
  String get currency_local {
    return Intl.message('Local', name: 'currency_local', desc: '', args: []);
  }

  /// `How often do you pay?`
  String get how_often_pay {
    return Intl.message(
      'How often do you pay?',
      name: 'how_often_pay',
      desc: '',
      args: [],
    );
  }

  /// `Once a year`
  String get once_a_year {
    return Intl.message('Once a year', name: 'once_a_year', desc: '', args: []);
  }

  /// `You decide`
  String get you_decide {
    return Intl.message('You decide', name: 'you_decide', desc: '', args: []);
  }

  /// `Number of days`
  String get enter_days {
    return Intl.message(
      'Number of days',
      name: 'enter_days',
      desc: '',
      args: [],
    );
  }

  /// `When do you get charged?`
  String get billing_date_title {
    return Intl.message(
      'When do you get charged?',
      name: 'billing_date_title',
      desc: '',
      args: [],
    );
  }

  /// `Day of the week`
  String get billing_date_weekday_label {
    return Intl.message(
      'Day of the week',
      name: 'billing_date_weekday_label',
      desc: '',
      args: [],
    );
  }

  /// `Day of the month`
  String get billing_date_monthday_label {
    return Intl.message(
      'Day of the month',
      name: 'billing_date_monthday_label',
      desc: '',
      args: [],
    );
  }

  /// `Month`
  String get billing_date_month_label {
    return Intl.message(
      'Month',
      name: 'billing_date_month_label',
      desc: '',
      args: [],
    );
  }

  /// `Day {day}`
  String billing_label_monthly(Object day) {
    return Intl.message(
      'Day $day',
      name: 'billing_label_monthly',
      desc: '',
      args: [day],
    );
  }

  /// `Every {days} days`
  String billing_label_custom(Object days) {
    return Intl.message(
      'Every $days days',
      name: 'billing_label_custom',
      desc: '',
      args: [days],
    );
  }

  /// `Date of first charge`
  String get billing_date_custom_label {
    return Intl.message(
      'Date of first charge',
      name: 'billing_date_custom_label',
      desc: '',
      args: [],
    );
  }

  /// `What's the price?`
  String get price_title {
    return Intl.message(
      'What\'s the price?',
      name: 'price_title',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get confirm {
    return Intl.message('Confirm', name: 'confirm', desc: '', args: []);
  }

  /// `All set!`
  String get summary_title {
    return Intl.message('All set!', name: 'summary_title', desc: '', args: []);
  }

  /// `Service`
  String get summary_service {
    return Intl.message('Service', name: 'summary_service', desc: '', args: []);
  }

  /// `Period`
  String get summary_period {
    return Intl.message('Period', name: 'summary_period', desc: '', args: []);
  }

  /// `Billing date`
  String get summary_date {
    return Intl.message(
      'Billing date',
      name: 'summary_date',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get summary_price {
    return Intl.message('Price', name: 'summary_price', desc: '', args: []);
  }

  /// `Description`
  String get description {
    return Intl.message('Description', name: 'description', desc: '', args: []);
  }

  /// `Optional description...`
  String get write_a_description {
    return Intl.message(
      'Optional description...',
      name: 'write_a_description',
      desc: '',
      args: [],
    );
  }

  /// `Upcoming`
  String get upcoming {
    return Intl.message('Upcoming', name: 'upcoming', desc: '', args: []);
  }

  /// `Past`
  String get past_due {
    return Intl.message('Past', name: 'past_due', desc: '', args: []);
  }

  /// `Today`
  String get billing_today {
    return Intl.message('Today', name: 'billing_today', desc: '', args: []);
  }

  /// `in {days} days`
  String billing_days_left(Object days) {
    return Intl.message(
      'in $days days',
      name: 'billing_days_left',
      desc: '',
      args: [days],
    );
  }

  /// `Description suggestions`
  String get plan_suggestions {
    return Intl.message(
      'Description suggestions',
      name: 'plan_suggestions',
      desc: '',
      args: [],
    );
  }

  /// `Simple`
  String get plan_simple {
    return Intl.message('Simple', name: 'plan_simple', desc: '', args: []);
  }

  /// `Normal`
  String get plan_normal {
    return Intl.message('Normal', name: 'plan_normal', desc: '', args: []);
  }

  /// `Freemium`
  String get plan_freemium {
    return Intl.message('Freemium', name: 'plan_freemium', desc: '', args: []);
  }

  /// `Basic`
  String get plan_basic {
    return Intl.message('Basic', name: 'plan_basic', desc: '', args: []);
  }

  /// `Plus`
  String get plan_plus {
    return Intl.message('Plus', name: 'plan_plus', desc: '', args: []);
  }

  /// `Pro`
  String get plan_pro {
    return Intl.message('Pro', name: 'plan_pro', desc: '', args: []);
  }

  /// `Duo`
  String get plan_duo {
    return Intl.message('Duo', name: 'plan_duo', desc: '', args: []);
  }

  /// `Family`
  String get plan_family {
    return Intl.message('Family', name: 'plan_family', desc: '', args: []);
  }

  /// `Next billing`
  String get subscription_details_next_billing {
    return Intl.message(
      'Next billing',
      name: 'subscription_details_next_billing',
      desc: '',
      args: [],
    );
  }

  /// `Overdue`
  String get subscription_details_overdue {
    return Intl.message(
      'Overdue',
      name: 'subscription_details_overdue',
      desc: '',
      args: [],
    );
  }

  /// `Domain`
  String get subscription_details_domain {
    return Intl.message(
      'Domain',
      name: 'subscription_details_domain',
      desc: '',
      args: [],
    );
  }

  /// `Synced`
  String get subscription_details_synced {
    return Intl.message(
      'Synced',
      name: 'subscription_details_synced',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get subscription_details_yes {
    return Intl.message(
      'Yes',
      name: 'subscription_details_yes',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get subscription_details_no {
    return Intl.message(
      'No',
      name: 'subscription_details_no',
      desc: '',
      args: [],
    );
  }

  /// `Service ID`
  String get subscription_details_service_id {
    return Intl.message(
      'Service ID',
      name: 'subscription_details_service_id',
      desc: '',
      args: [],
    );
  }

  /// `Billing`
  String get subscription_details_section_billing {
    return Intl.message(
      'Billing',
      name: 'subscription_details_section_billing',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get subscription_details_section_about {
    return Intl.message(
      'About',
      name: 'subscription_details_section_about',
      desc: '',
      args: [],
    );
  }

  /// `Details`
  String get subscription_details_section_details {
    return Intl.message(
      'Details',
      name: 'subscription_details_section_details',
      desc: '',
      args: [],
    );
  }

  /// `Delete subscription`
  String get subscription_details_delete {
    return Intl.message(
      'Delete subscription',
      name: 'subscription_details_delete',
      desc: '',
      args: [],
    );
  }

  /// `Business`
  String get business {
    return Intl.message('Business', name: 'business', desc: '', args: []);
  }

  /// `Products`
  String get products {
    return Intl.message('Products', name: 'products', desc: '', args: []);
  }

  /// `Inventory`
  String get inventory {
    return Intl.message('Inventory', name: 'inventory', desc: '', args: []);
  }

  /// `Services`
  String get services {
    return Intl.message('Services', name: 'services', desc: '', args: []);
  }

  /// `Channels`
  String get channels {
    return Intl.message('Channels', name: 'channels', desc: '', args: []);
  }

  /// `Finance`
  String get finance {
    return Intl.message('Finance', name: 'finance', desc: '', args: []);
  }

  /// `Marketing`
  String get marketing {
    return Intl.message('Marketing', name: 'marketing', desc: '', args: []);
  }

  /// `Report`
  String get report {
    return Intl.message('Report', name: 'report', desc: '', args: []);
  }

  /// `External Services`
  String get external_services {
    return Intl.message(
      'External Services',
      name: 'external_services',
      desc: '',
      args: [],
    );
  }

  /// `Sign out`
  String get sign_out {
    return Intl.message('Sign out', name: 'sign_out', desc: '', args: []);
  }

  /// `Expand`
  String get expand {
    return Intl.message('Expand', name: 'expand', desc: '', args: []);
  }

  /// `Collapse`
  String get collapse {
    return Intl.message('Collapse', name: 'collapse', desc: '', args: []);
  }

  /// `Tell us about the business you want to manage`
  String get create_business_subtitle {
    return Intl.message(
      'Tell us about the business you want to manage',
      name: 'create_business_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Legal name`
  String get business_legal_name_input {
    return Intl.message(
      'Legal name',
      name: 'business_legal_name_input',
      desc: '',
      args: [],
    );
  }

  /// `Type of activity`
  String get business_type_input {
    return Intl.message(
      'Type of activity',
      name: 'business_type_input',
      desc: '',
      args: [],
    );
  }

  /// `Select the main activity`
  String get business_type_placeholder {
    return Intl.message(
      'Select the main activity',
      name: 'business_type_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `No activity matches your search`
  String get business_type_empty {
    return Intl.message(
      'No activity matches your search',
      name: 'business_type_empty',
      desc: '',
      args: [],
    );
  }

  /// `Retail`
  String get business_type_retail {
    return Intl.message(
      'Retail',
      name: 'business_type_retail',
      desc: '',
      args: [],
    );
  }

  /// `Wholesale`
  String get business_type_wholesale {
    return Intl.message(
      'Wholesale',
      name: 'business_type_wholesale',
      desc: '',
      args: [],
    );
  }

  /// `Food and beverage`
  String get business_type_food {
    return Intl.message(
      'Food and beverage',
      name: 'business_type_food',
      desc: '',
      args: [],
    );
  }

  /// `Hospitality and tourism`
  String get business_type_hospitality {
    return Intl.message(
      'Hospitality and tourism',
      name: 'business_type_hospitality',
      desc: '',
      args: [],
    );
  }

  /// `Professional services`
  String get business_type_services {
    return Intl.message(
      'Professional services',
      name: 'business_type_services',
      desc: '',
      args: [],
    );
  }

  /// `Technology`
  String get business_type_technology {
    return Intl.message(
      'Technology',
      name: 'business_type_technology',
      desc: '',
      args: [],
    );
  }

  /// `Health and wellness`
  String get business_type_health {
    return Intl.message(
      'Health and wellness',
      name: 'business_type_health',
      desc: '',
      args: [],
    );
  }

  /// `Beauty and personal care`
  String get business_type_beauty {
    return Intl.message(
      'Beauty and personal care',
      name: 'business_type_beauty',
      desc: '',
      args: [],
    );
  }

  /// `Education`
  String get business_type_education {
    return Intl.message(
      'Education',
      name: 'business_type_education',
      desc: '',
      args: [],
    );
  }

  /// `Manufacturing`
  String get business_type_manufacturing {
    return Intl.message(
      'Manufacturing',
      name: 'business_type_manufacturing',
      desc: '',
      args: [],
    );
  }

  /// `Construction`
  String get business_type_construction {
    return Intl.message(
      'Construction',
      name: 'business_type_construction',
      desc: '',
      args: [],
    );
  }

  /// `Agriculture and livestock`
  String get business_type_agriculture {
    return Intl.message(
      'Agriculture and livestock',
      name: 'business_type_agriculture',
      desc: '',
      args: [],
    );
  }

  /// `Transport and logistics`
  String get business_type_transport {
    return Intl.message(
      'Transport and logistics',
      name: 'business_type_transport',
      desc: '',
      args: [],
    );
  }

  /// `Automotive`
  String get business_type_automotive {
    return Intl.message(
      'Automotive',
      name: 'business_type_automotive',
      desc: '',
      args: [],
    );
  }

  /// `Entertainment`
  String get business_type_entertainment {
    return Intl.message(
      'Entertainment',
      name: 'business_type_entertainment',
      desc: '',
      args: [],
    );
  }

  /// `Finance`
  String get business_type_finance {
    return Intl.message(
      'Finance',
      name: 'business_type_finance',
      desc: '',
      args: [],
    );
  }

  /// `Real estate`
  String get business_type_real_estate {
    return Intl.message(
      'Real estate',
      name: 'business_type_real_estate',
      desc: '',
      args: [],
    );
  }

  /// `Legal`
  String get business_type_legal {
    return Intl.message(
      'Legal',
      name: 'business_type_legal',
      desc: '',
      args: [],
    );
  }

  /// `Nonprofit`
  String get business_type_nonprofit {
    return Intl.message(
      'Nonprofit',
      name: 'business_type_nonprofit',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get business_type_other {
    return Intl.message(
      'Other',
      name: 'business_type_other',
      desc: '',
      args: [],
    );
  }

  /// `Before you continue`
  String get business_notice_title {
    return Intl.message(
      'Before you continue',
      name: 'business_notice_title',
      desc: '',
      args: [],
    );
  }

  /// `The legal name and the type of activity must match the real business. Businesses whose activity looks suspicious can be restricted.`
  String get business_notice_real {
    return Intl.message(
      'The legal name and the type of activity must match the real business. Businesses whose activity looks suspicious can be restricted.',
      name: 'business_notice_real',
      desc: '',
      args: [],
    );
  }

  /// `Unverified businesses have significant limitations until their information is confirmed.`
  String get business_notice_unverified {
    return Intl.message(
      'Unverified businesses have significant limitations until their information is confirmed.',
      name: 'business_notice_unverified',
      desc: '',
      args: [],
    );
  }

  /// `Legal documents may be requested at any time. Failing to provide them can restrict the business, the profile that created it and everyone who administers it.`
  String get business_notice_documents {
    return Intl.message(
      'Legal documents may be requested at any time. Failing to provide them can restrict the business, the profile that created it and everyone who administers it.',
      name: 'business_notice_documents',
      desc: '',
      args: [],
    );
  }

  /// `No businesses yet`
  String get business_list_empty_title {
    return Intl.message(
      'No businesses yet',
      name: 'business_list_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Create your first business to start managing it here.`
  String get business_list_empty_subtitle {
    return Intl.message(
      'Create your first business to start managing it here.',
      name: 'business_list_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load your businesses`
  String get business_list_error_title {
    return Intl.message(
      'Couldn\'t load your businesses',
      name: 'business_list_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get business_list_error_subtitle {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'business_list_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get business_list_retry {
    return Intl.message(
      'Try again',
      name: 'business_list_retry',
      desc: '',
      args: [],
    );
  }

  /// `No businesses match your search`
  String get business_list_search_empty {
    return Intl.message(
      'No businesses match your search',
      name: 'business_list_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `No business yet`
  String get section_no_business_title {
    return Intl.message(
      'No business yet',
      name: 'section_no_business_title',
      desc: '',
      args: [],
    );
  }

  /// `Create your business to start using this section.`
  String get section_no_business_subtitle {
    return Intl.message(
      'Create your business to start using this section.',
      name: 'section_no_business_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Active`
  String get business_status_active {
    return Intl.message(
      'Active',
      name: 'business_status_active',
      desc: '',
      args: [],
    );
  }

  /// `Restricted`
  String get business_status_restricted {
    return Intl.message(
      'Restricted',
      name: 'business_status_restricted',
      desc: '',
      args: [],
    );
  }

  /// `Pending`
  String get business_status_pending {
    return Intl.message(
      'Pending',
      name: 'business_status_pending',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get business_status_unknown {
    return Intl.message(
      'Unknown',
      name: 'business_status_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Seller`
  String get business_rank_seller {
    return Intl.message(
      'Seller',
      name: 'business_rank_seller',
      desc: '',
      args: [],
    );
  }

  /// `Manager`
  String get business_rank_manager {
    return Intl.message(
      'Manager',
      name: 'business_rank_manager',
      desc: '',
      args: [],
    );
  }

  /// `Advertiser`
  String get business_rank_advertiser {
    return Intl.message(
      'Advertiser',
      name: 'business_rank_advertiser',
      desc: '',
      args: [],
    );
  }

  /// `Administrator`
  String get business_rank_administrator {
    return Intl.message(
      'Administrator',
      name: 'business_rank_administrator',
      desc: '',
      args: [],
    );
  }

  /// `Member`
  String get business_rank_unknown {
    return Intl.message(
      'Member',
      name: 'business_rank_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Open`
  String get business_state_open {
    return Intl.message(
      'Open',
      name: 'business_state_open',
      desc: '',
      args: [],
    );
  }

  /// `Closed`
  String get business_state_closed {
    return Intl.message(
      'Closed',
      name: 'business_state_closed',
      desc: '',
      args: [],
    );
  }

  /// `Inquiries only`
  String get business_state_inquiries {
    return Intl.message(
      'Inquiries only',
      name: 'business_state_inquiries',
      desc: '',
      args: [],
    );
  }

  /// `Online orders only`
  String get business_state_orders {
    return Intl.message(
      'Online orders only',
      name: 'business_state_orders',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get business_state_unknown {
    return Intl.message(
      'Unknown',
      name: 'business_state_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Not verified`
  String get business_verification_untrusted {
    return Intl.message(
      'Not verified',
      name: 'business_verification_untrusted',
      desc: '',
      args: [],
    );
  }

  /// `Trusted`
  String get business_verification_trusted {
    return Intl.message(
      'Trusted',
      name: 'business_verification_trusted',
      desc: '',
      args: [],
    );
  }

  /// `Under review`
  String get business_verification_pending {
    return Intl.message(
      'Under review',
      name: 'business_verification_pending',
      desc: '',
      args: [],
    );
  }

  /// `Verified`
  String get business_verification_verified {
    return Intl.message(
      'Verified',
      name: 'business_verification_verified',
      desc: '',
      args: [],
    );
  }

  /// `Rejected`
  String get business_verification_rejected {
    return Intl.message(
      'Rejected',
      name: 'business_verification_rejected',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get business_tab_settings {
    return Intl.message(
      'Settings',
      name: 'business_tab_settings',
      desc: '',
      args: [],
    );
  }

  /// `Employees`
  String get business_tab_employees {
    return Intl.message(
      'Employees',
      name: 'business_tab_employees',
      desc: '',
      args: [],
    );
  }

  /// `Branches`
  String get business_tab_branches {
    return Intl.message(
      'Branches',
      name: 'business_tab_branches',
      desc: '',
      args: [],
    );
  }

  /// `Clients`
  String get business_tab_clients {
    return Intl.message(
      'Clients',
      name: 'business_tab_clients',
      desc: '',
      args: [],
    );
  }

  /// `Statistics`
  String get business_tab_statistics {
    return Intl.message(
      'Statistics',
      name: 'business_tab_statistics',
      desc: '',
      args: [],
    );
  }

  /// `Owner`
  String get business_profile_owner {
    return Intl.message(
      'Owner',
      name: 'business_profile_owner',
      desc: '',
      args: [],
    );
  }

  /// `Identity`
  String get business_profile_section_identity {
    return Intl.message(
      'Identity',
      name: 'business_profile_section_identity',
      desc: '',
      args: [],
    );
  }

  /// `Operation`
  String get business_profile_section_operation {
    return Intl.message(
      'Operation',
      name: 'business_profile_section_operation',
      desc: '',
      args: [],
    );
  }

  /// `Contact`
  String get business_profile_section_contact {
    return Intl.message(
      'Contact',
      name: 'business_profile_section_contact',
      desc: '',
      args: [],
    );
  }

  /// `Email addresses`
  String get business_profile_section_emails {
    return Intl.message(
      'Email addresses',
      name: 'business_profile_section_emails',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get business_profile_section_account {
    return Intl.message(
      'Account',
      name: 'business_profile_section_account',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get business_profile_name {
    return Intl.message(
      'Name',
      name: 'business_profile_name',
      desc: '',
      args: [],
    );
  }

  /// `What this business is called day to day: the name in your list, in the selector and on every screen of the app.`
  String get business_profile_name_note {
    return Intl.message(
      'What this business is called day to day: the name in your list, in the selector and on every screen of the app.',
      name: 'business_profile_name_note',
      desc: '',
      args: [],
    );
  }

  /// `Tagline`
  String get business_profile_caption {
    return Intl.message(
      'Tagline',
      name: 'business_profile_caption',
      desc: '',
      args: [],
    );
  }

  /// `One line about what this business does. It reads under its name, so it's what someone who doesn't know it yet reads first.`
  String get business_profile_caption_note {
    return Intl.message(
      'One line about what this business does. It reads under its name, so it\'s what someone who doesn\'t know it yet reads first.',
      name: 'business_profile_caption_note',
      desc: '',
      args: [],
    );
  }

  /// `Legal name`
  String get business_profile_legal_name {
    return Intl.message(
      'Legal name',
      name: 'business_profile_legal_name',
      desc: '',
      args: [],
    );
  }

  /// `The name this business is registered under. It's the one that goes on invoices, contracts and anything legal.`
  String get business_profile_legal_name_note {
    return Intl.message(
      'The name this business is registered under. It\'s the one that goes on invoices, contracts and anything legal.',
      name: 'business_profile_legal_name_note',
      desc: '',
      args: [],
    );
  }

  /// `Handle`
  String get business_profile_nickname {
    return Intl.message(
      'Handle',
      name: 'business_profile_nickname',
      desc: '',
      args: [],
    );
  }

  /// `The short public handle this business is found and linked by. No spaces, no accents.`
  String get business_profile_nickname_note {
    return Intl.message(
      'The short public handle this business is found and linked by. No spaces, no accents.',
      name: 'business_profile_nickname_note',
      desc: '',
      args: [],
    );
  }

  /// `Activity`
  String get business_profile_activity {
    return Intl.message(
      'Activity',
      name: 'business_profile_activity',
      desc: '',
      args: [],
    );
  }

  /// `What this business sells or does. It's what places it in searches and reports.`
  String get business_profile_activity_note {
    return Intl.message(
      'What this business sells or does. It\'s what places it in searches and reports.',
      name: 'business_profile_activity_note',
      desc: '',
      args: [],
    );
  }

  /// `Tax ID`
  String get business_profile_tax_id {
    return Intl.message(
      'Tax ID',
      name: 'business_profile_tax_id',
      desc: '',
      args: [],
    );
  }

  /// `The number the tax authority identifies this business by, printed on every invoice it issues.`
  String get business_profile_tax_id_note {
    return Intl.message(
      'The number the tax authority identifies this business by, printed on every invoice it issues.',
      name: 'business_profile_tax_id_note',
      desc: '',
      args: [],
    );
  }

  /// `Incorporated on`
  String get business_profile_incorporation {
    return Intl.message(
      'Incorporated on',
      name: 'business_profile_incorporation',
      desc: '',
      args: [],
    );
  }

  /// `Verified on`
  String get business_profile_verified_date {
    return Intl.message(
      'Verified on',
      name: 'business_profile_verified_date',
      desc: '',
      args: [],
    );
  }

  /// `The day the platform checked these details. It's granted by verification, so it can't be edited here.`
  String get business_profile_verified_date_note {
    return Intl.message(
      'The day the platform checked these details. It\'s granted by verification, so it can\'t be edited here.',
      name: 'business_profile_verified_date_note',
      desc: '',
      args: [],
    );
  }

  /// `Country`
  String get business_profile_country {
    return Intl.message(
      'Country',
      name: 'business_profile_country',
      desc: '',
      args: [],
    );
  }

  /// `Where the business is registered, as its two-letter code. It sets which rules and taxes apply.`
  String get business_profile_country_note {
    return Intl.message(
      'Where the business is registered, as its two-letter code. It sets which rules and taxes apply.',
      name: 'business_profile_country_note',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get business_profile_address {
    return Intl.message(
      'Address',
      name: 'business_profile_address',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get business_profile_language {
    return Intl.message(
      'Language',
      name: 'business_profile_language',
      desc: '',
      args: [],
    );
  }

  /// `The language this business writes in: the one used in what it sends to its customers.`
  String get business_profile_language_note {
    return Intl.message(
      'The language this business writes in: the one used in what it sends to its customers.',
      name: 'business_profile_language_note',
      desc: '',
      args: [],
    );
  }

  /// `Currency`
  String get business_profile_currency {
    return Intl.message(
      'Currency',
      name: 'business_profile_currency',
      desc: '',
      args: [],
    );
  }

  /// `The currency this business writes its prices in. Changing it wouldn't convert a single price, it would relabel every one of them, so it isn't changed from here.`
  String get business_profile_currency_note {
    return Intl.message(
      'The currency this business writes its prices in. Changing it wouldn\'t convert a single price, it would relabel every one of them, so it isn\'t changed from here.',
      name: 'business_profile_currency_note',
      desc: '',
      args: [],
    );
  }

  /// `Also quotes in`
  String get business_profile_currencies {
    return Intl.message(
      'Also quotes in',
      name: 'business_profile_currencies',
      desc: '',
      args: [],
    );
  }

  /// `Other currencies this business also quotes prices in. They're changed where its currencies are set up.`
  String get business_profile_currencies_note {
    return Intl.message(
      'Other currencies this business also quotes prices in. They\'re changed where its currencies are set up.',
      name: 'business_profile_currencies_note',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get business_profile_phone {
    return Intl.message(
      'Phone',
      name: 'business_profile_phone',
      desc: '',
      args: [],
    );
  }

  /// `The number a customer calls when they'd rather talk to someone than write.`
  String get business_profile_phone_note {
    return Intl.message(
      'The number a customer calls when they\'d rather talk to someone than write.',
      name: 'business_profile_phone_note',
      desc: '',
      args: [],
    );
  }

  /// `Primary`
  String get business_email_main {
    return Intl.message(
      'Primary',
      name: 'business_email_main',
      desc: '',
      args: [],
    );
  }

  /// `This business has no email addresses yet.`
  String get business_email_empty {
    return Intl.message(
      'This business has no email addresses yet.',
      name: 'business_email_empty',
      desc: '',
      args: [],
    );
  }

  /// `Add address`
  String get business_email_add {
    return Intl.message(
      'Add address',
      name: 'business_email_add',
      desc: '',
      args: [],
    );
  }

  /// `Edit address`
  String get business_email_edit_title {
    return Intl.message(
      'Edit address',
      name: 'business_email_edit_title',
      desc: '',
      args: [],
    );
  }

  /// `Email address`
  String get business_email_address {
    return Intl.message(
      'Email address',
      name: 'business_email_address',
      desc: '',
      args: [],
    );
  }

  /// `name@business.com`
  String get business_email_address_hint {
    return Intl.message(
      'name@business.com',
      name: 'business_email_address_hint',
      desc: '',
      args: [],
    );
  }

  /// `Used for`
  String get business_email_purpose {
    return Intl.message(
      'Used for',
      name: 'business_email_purpose',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get business_email_label {
    return Intl.message(
      'Name',
      name: 'business_email_label',
      desc: '',
      args: [],
    );
  }

  /// `Billing Colombia`
  String get business_email_label_hint {
    return Intl.message(
      'Billing Colombia',
      name: 'business_email_label_hint',
      desc: '',
      args: [],
    );
  }

  /// `Make primary`
  String get business_email_promote {
    return Intl.message(
      'Make primary',
      name: 'business_email_promote',
      desc: '',
      args: [],
    );
  }

  /// `Primary address updated`
  String get business_email_promoted {
    return Intl.message(
      'Primary address updated',
      name: 'business_email_promoted',
      desc: '',
      args: [],
    );
  }

  /// `Delete address`
  String get delete_business_email {
    return Intl.message(
      'Delete address',
      name: 'delete_business_email',
      desc: '',
      args: [],
    );
  }

  /// `Delete this address?`
  String get business_email_delete_title {
    return Intl.message(
      'Delete this address?',
      name: 'business_email_delete_title',
      desc: '',
      args: [],
    );
  }

  /// `{email} stops being one of the addresses this business can be written to. If it's the primary one, the oldest of the rest takes its place.`
  String business_email_delete_message(Object email) {
    return Intl.message(
      '$email stops being one of the addresses this business can be written to. If it\'s the primary one, the oldest of the rest takes its place.',
      name: 'business_email_delete_message',
      desc: '',
      args: [email],
    );
  }

  /// `Address deleted`
  String get business_email_deleted {
    return Intl.message(
      'Address deleted',
      name: 'business_email_deleted',
      desc: '',
      args: [],
    );
  }

  /// `General`
  String get business_email_purpose_general {
    return Intl.message(
      'General',
      name: 'business_email_purpose_general',
      desc: '',
      args: [],
    );
  }

  /// `The everyday address. Anything that doesn't belong to another one lands here.`
  String get business_email_purpose_general_note {
    return Intl.message(
      'The everyday address. Anything that doesn\'t belong to another one lands here.',
      name: 'business_email_purpose_general_note',
      desc: '',
      args: [],
    );
  }

  /// `Support`
  String get business_email_purpose_support {
    return Intl.message(
      'Support',
      name: 'business_email_purpose_support',
      desc: '',
      args: [],
    );
  }

  /// `Where a customer writes when something doesn't work or they need help with a product or service.`
  String get business_email_purpose_support_note {
    return Intl.message(
      'Where a customer writes when something doesn\'t work or they need help with a product or service.',
      name: 'business_email_purpose_support_note',
      desc: '',
      args: [],
    );
  }

  /// `Sales`
  String get business_email_purpose_sales {
    return Intl.message(
      'Sales',
      name: 'business_email_purpose_sales',
      desc: '',
      args: [],
    );
  }

  /// `Where someone writes to buy, ask for a quote or start a deal.`
  String get business_email_purpose_sales_note {
    return Intl.message(
      'Where someone writes to buy, ask for a quote or start a deal.',
      name: 'business_email_purpose_sales_note',
      desc: '',
      args: [],
    );
  }

  /// `Billing`
  String get business_email_purpose_billing {
    return Intl.message(
      'Billing',
      name: 'business_email_purpose_billing',
      desc: '',
      args: [],
    );
  }

  /// `Where invoices, receipts and anything about a payment are sent.`
  String get business_email_purpose_billing_note {
    return Intl.message(
      'Where invoices, receipts and anything about a payment are sent.',
      name: 'business_email_purpose_billing_note',
      desc: '',
      args: [],
    );
  }

  /// `People`
  String get business_email_purpose_hr {
    return Intl.message(
      'People',
      name: 'business_email_purpose_hr',
      desc: '',
      args: [],
    );
  }

  /// `Where job applications and anything about the people who work here arrive.`
  String get business_email_purpose_hr_note {
    return Intl.message(
      'Where job applications and anything about the people who work here arrive.',
      name: 'business_email_purpose_hr_note',
      desc: '',
      args: [],
    );
  }

  /// `Legal`
  String get business_email_purpose_legal {
    return Intl.message(
      'Legal',
      name: 'business_email_purpose_legal',
      desc: '',
      args: [],
    );
  }

  /// `Where contracts, claims and formal notices are received.`
  String get business_email_purpose_legal_note {
    return Intl.message(
      'Where contracts, claims and formal notices are received.',
      name: 'business_email_purpose_legal_note',
      desc: '',
      args: [],
    );
  }

  /// `Press`
  String get business_email_purpose_press {
    return Intl.message(
      'Press',
      name: 'business_email_purpose_press',
      desc: '',
      args: [],
    );
  }

  /// `Where media and partners write about the business itself.`
  String get business_email_purpose_press_note {
    return Intl.message(
      'Where media and partners write about the business itself.',
      name: 'business_email_purpose_press_note',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get business_email_purpose_other {
    return Intl.message(
      'Other',
      name: 'business_email_purpose_other',
      desc: '',
      args: [],
    );
  }

  /// `Verified`
  String get business_email_verified {
    return Intl.message(
      'Verified',
      name: 'business_email_verified',
      desc: '',
      args: [],
    );
  }

  /// `Unverified`
  String get business_email_unverified {
    return Intl.message(
      'Unverified',
      name: 'business_email_unverified',
      desc: '',
      args: [],
    );
  }

  /// `Verify`
  String get business_email_verify {
    return Intl.message(
      'Verify',
      name: 'business_email_verify',
      desc: '',
      args: [],
    );
  }

  /// `Verify address`
  String get business_email_verify_title {
    return Intl.message(
      'Verify address',
      name: 'business_email_verify_title',
      desc: '',
      args: [],
    );
  }

  /// `We mailed a 6-digit code to this address. Type it in to prove the business reads it.`
  String get business_email_verify_sent {
    return Intl.message(
      'We mailed a 6-digit code to this address. Type it in to prove the business reads it.',
      name: 'business_email_verify_sent',
      desc: '',
      args: [],
    );
  }

  /// `Address verified`
  String get business_email_verified_done {
    return Intl.message(
      'Address verified',
      name: 'business_email_verified_done',
      desc: '',
      args: [],
    );
  }

  /// `Website`
  String get business_profile_website {
    return Intl.message(
      'Website',
      name: 'business_profile_website',
      desc: '',
      args: [],
    );
  }

  /// `Where a customer finds the business on its own: its site, its store or its page.`
  String get business_profile_website_note {
    return Intl.message(
      'Where a customer finds the business on its own: its site, its store or its page.',
      name: 'business_profile_website_note',
      desc: '',
      args: [],
    );
  }

  /// `Identifier`
  String get business_profile_id {
    return Intl.message(
      'Identifier',
      name: 'business_profile_id',
      desc: '',
      args: [],
    );
  }

  /// `How this business is named outside the app: paste it when you write to support or wire an integration.`
  String get business_profile_id_note {
    return Intl.message(
      'How this business is named outside the app: paste it when you write to support or wire an integration.',
      name: 'business_profile_id_note',
      desc: '',
      args: [],
    );
  }

  /// `Registered on`
  String get business_profile_created {
    return Intl.message(
      'Registered on',
      name: 'business_profile_created',
      desc: '',
      args: [],
    );
  }

  /// `Edit {field}`
  String business_profile_edit(Object field) {
    return Intl.message(
      'Edit $field',
      name: 'business_profile_edit',
      desc: '',
      args: [field],
    );
  }

  /// `Add {field}`
  String business_profile_add(Object field) {
    return Intl.message(
      'Add $field',
      name: 'business_profile_add',
      desc: '',
      args: [field],
    );
  }

  /// `Not set`
  String get business_profile_empty {
    return Intl.message(
      'Not set',
      name: 'business_profile_empty',
      desc: '',
      args: [],
    );
  }

  /// `Business updated`
  String get business_profile_saved {
    return Intl.message(
      'Business updated',
      name: 'business_profile_saved',
      desc: '',
      args: [],
    );
  }

  /// `Select an option`
  String get business_profile_select {
    return Intl.message(
      'Select an option',
      name: 'business_profile_select',
      desc: '',
      args: [],
    );
  }

  /// `No option matches your search`
  String get business_profile_select_empty {
    return Intl.message(
      'No option matches your search',
      name: 'business_profile_select_empty',
      desc: '',
      args: [],
    );
  }

  /// `Year`
  String get business_profile_incorporation_year {
    return Intl.message(
      'Year',
      name: 'business_profile_incorporation_year',
      desc: '',
      args: [],
    );
  }

  /// `Month`
  String get business_profile_incorporation_month {
    return Intl.message(
      'Month',
      name: 'business_profile_incorporation_month',
      desc: '',
      args: [],
    );
  }

  /// `Day`
  String get business_profile_incorporation_day {
    return Intl.message(
      'Day',
      name: 'business_profile_incorporation_day',
      desc: '',
      args: [],
    );
  }

  /// `ISO code (US, ES, VE)`
  String get business_profile_country_hint {
    return Intl.message(
      'ISO code (US, ES, VE)',
      name: 'business_profile_country_hint',
      desc: '',
      args: [],
    );
  }

  /// `Digits, with the country code (+584121234567)`
  String get business_profile_phone_hint {
    return Intl.message(
      'Digits, with the country code (+584121234567)',
      name: 'business_profile_phone_hint',
      desc: '',
      args: [],
    );
  }

  /// `Code`
  String get business_profile_phone_code {
    return Intl.message(
      'Code',
      name: 'business_profile_phone_code',
      desc: '',
      args: [],
    );
  }

  /// `Number`
  String get business_profile_phone_number {
    return Intl.message(
      'Number',
      name: 'business_profile_phone_number',
      desc: '',
      args: [],
    );
  }

  /// `Open website`
  String get business_profile_website_open {
    return Intl.message(
      'Open website',
      name: 'business_profile_website_open',
      desc: '',
      args: [],
    );
  }

  /// `That address couldn't be opened. Check that it's written correctly.`
  String get business_profile_website_failed {
    return Intl.message(
      'That address couldn\'t be opened. Check that it\'s written correctly.',
      name: 'business_profile_website_failed',
      desc: '',
      args: [],
    );
  }

  /// `ryzer.com`
  String get business_profile_website_hint {
    return Intl.message(
      'ryzer.com',
      name: 'business_profile_website_hint',
      desc: '',
      args: [],
    );
  }

  /// `Show identifier`
  String get business_profile_id_show {
    return Intl.message(
      'Show identifier',
      name: 'business_profile_id_show',
      desc: '',
      args: [],
    );
  }

  /// `Hide identifier`
  String get business_profile_id_hide {
    return Intl.message(
      'Hide identifier',
      name: 'business_profile_id_hide',
      desc: '',
      args: [],
    );
  }

  /// `Copy identifier`
  String get business_profile_id_copy {
    return Intl.message(
      'Copy identifier',
      name: 'business_profile_id_copy',
      desc: '',
      args: [],
    );
  }

  /// `Identifier copied`
  String get business_profile_id_copied {
    return Intl.message(
      'Identifier copied',
      name: 'business_profile_id_copied',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load this business`
  String get business_profile_error_title {
    return Intl.message(
      'Couldn\'t load this business',
      name: 'business_profile_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get business_profile_error_subtitle {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'business_profile_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Business not found`
  String get business_profile_not_found_title {
    return Intl.message(
      'Business not found',
      name: 'business_profile_not_found_title',
      desc: '',
      args: [],
    );
  }

  /// `This business is no longer in your list.`
  String get business_profile_not_found_subtitle {
    return Intl.message(
      'This business is no longer in your list.',
      name: 'business_profile_not_found_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Go to your business`
  String get business_profile_active {
    return Intl.message(
      'Go to your business',
      name: 'business_profile_active',
      desc: '',
      args: [],
    );
  }

  /// `Add logo`
  String get business_logo_add {
    return Intl.message(
      'Add logo',
      name: 'business_logo_add',
      desc: '',
      args: [],
    );
  }

  /// `Change logo`
  String get business_logo_change {
    return Intl.message(
      'Change logo',
      name: 'business_logo_change',
      desc: '',
      args: [],
    );
  }

  /// `Images`
  String get business_logo_files {
    return Intl.message(
      'Images',
      name: 'business_logo_files',
      desc: '',
      args: [],
    );
  }

  /// `That image is over 10 MB. Pick a lighter one.`
  String get business_logo_large {
    return Intl.message(
      'That image is over 10 MB. Pick a lighter one.',
      name: 'business_logo_large',
      desc: '',
      args: [],
    );
  }

  /// `Logo updated`
  String get business_logo_saved {
    return Intl.message(
      'Logo updated',
      name: 'business_logo_saved',
      desc: '',
      args: [],
    );
  }

  /// `Frame the image`
  String get image_crop_title {
    return Intl.message(
      'Frame the image',
      name: 'image_crop_title',
      desc: '',
      args: [],
    );
  }

  /// `Drag the image to move it and zoom in to leave out what you don't want.`
  String get image_crop_hint {
    return Intl.message(
      'Drag the image to move it and zoom in to leave out what you don\'t want.',
      name: 'image_crop_hint',
      desc: '',
      args: [],
    );
  }

  /// `That image couldn't be prepared. Try another one.`
  String get image_crop_failed {
    return Intl.message(
      'That image couldn\'t be prepared. Try another one.',
      name: 'image_crop_failed',
      desc: '',
      args: [],
    );
  }

  /// `Delete business`
  String get business_delete_section {
    return Intl.message(
      'Delete business',
      name: 'business_delete_section',
      desc: '',
      args: [],
    );
  }

  /// `Deleting this business erases everything tied to it: its profile, its people, its branches, its catalog, its customers and its history. None of it is kept.`
  String get business_delete_warning {
    return Intl.message(
      'Deleting this business erases everything tied to it: its profile, its people, its branches, its catalog, its customers and its history. None of it is kept.',
      name: 'business_delete_warning',
      desc: '',
      args: [],
    );
  }

  /// `It doesn't happen right away. The business waits 30 days before it enters the deletion period, and 30 more while it's being deleted.`
  String get business_delete_schedule {
    return Intl.message(
      'It doesn\'t happen right away. The business waits 30 days before it enters the deletion period, and 30 more while it\'s being deleted.',
      name: 'business_delete_schedule',
      desc: '',
      args: [],
    );
  }

  /// `Delete business`
  String get business_delete_action {
    return Intl.message(
      'Delete business',
      name: 'business_delete_action',
      desc: '',
      args: [],
    );
  }

  /// `Delete this business?`
  String get business_delete_confirm_title {
    return Intl.message(
      'Delete this business?',
      name: 'business_delete_confirm_title',
      desc: '',
      args: [],
    );
  }

  /// `{name} and everything tied to it start the 60 days: 30 before the deletion period begins, and 30 more until nothing of it is left.`
  String business_delete_confirm_message(Object name) {
    return Intl.message(
      '$name and everything tied to it start the 60 days: 30 before the deletion period begins, and 30 more until nothing of it is left.',
      name: 'business_delete_confirm_message',
      desc: '',
      args: [name],
    );
  }

  /// `People with access`
  String get business_employees_total {
    return Intl.message(
      'People with access',
      name: 'business_employees_total',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load the people`
  String get business_employees_error_title {
    return Intl.message(
      'Couldn\'t load the people',
      name: 'business_employees_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get business_employees_error_subtitle {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'business_employees_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `The people who work in this business, with their role and what each one can do, will be listed here.`
  String get business_employees_soon {
    return Intl.message(
      'The people who work in this business, with their role and what each one can do, will be listed here.',
      name: 'business_employees_soon',
      desc: '',
      args: [],
    );
  }

  /// `The locations of this business, each with its address and what it handles, will be listed here.`
  String get business_branches_soon {
    return Intl.message(
      'The locations of this business, each with its address and what it handles, will be listed here.',
      name: 'business_branches_soon',
      desc: '',
      args: [],
    );
  }

  /// `The customers of this business and what they bought will be listed here.`
  String get business_clients_soon {
    return Intl.message(
      'The customers of this business and what they bought will be listed here.',
      name: 'business_clients_soon',
      desc: '',
      args: [],
    );
  }

  /// `How this business is doing —sales, activity and growth— will be shown here.`
  String get business_statistics_soon {
    return Intl.message(
      'How this business is doing —sales, activity and growth— will be shown here.',
      name: 'business_statistics_soon',
      desc: '',
      args: [],
    );
  }

  /// `Create table`
  String get create_table {
    return Intl.message(
      'Create table',
      name: 'create_table',
      desc: '',
      args: [],
    );
  }

  /// `Import table`
  String get import_table {
    return Intl.message(
      'Import table',
      name: 'import_table',
      desc: '',
      args: [],
    );
  }

  /// `Spreadsheets and CSV`
  String get import_table_file_type {
    return Intl.message(
      'Spreadsheets and CSV',
      name: 'import_table_file_type',
      desc: '',
      args: [],
    );
  }

  /// `Table imported`
  String get import_table_done {
    return Intl.message(
      'Table imported',
      name: 'import_table_done',
      desc: '',
      args: [],
    );
  }

  /// `Table created. Its columns and rows are still loading`
  String get import_table_started {
    return Intl.message(
      'Table created. Its columns and rows are still loading',
      name: 'import_table_started',
      desc: '',
      args: [],
    );
  }

  /// `The table was created, but its rows could not be imported`
  String get import_table_partial {
    return Intl.message(
      'The table was created, but its rows could not be imported',
      name: 'import_table_partial',
      desc: '',
      args: [],
    );
  }

  /// `Only spreadsheet and CSV files can be imported`
  String get import_table_unsupported {
    return Intl.message(
      'Only spreadsheet and CSV files can be imported',
      name: 'import_table_unsupported',
      desc: '',
      args: [],
    );
  }

  /// `Setting up columns`
  String get import_table_preparing {
    return Intl.message(
      'Setting up columns',
      name: 'import_table_preparing',
      desc: '',
      args: [],
    );
  }

  /// `Loading rows`
  String get import_table_loading {
    return Intl.message(
      'Loading rows',
      name: 'import_table_loading',
      desc: '',
      args: [],
    );
  }

  /// `No tables yet`
  String get product_tables_empty_title {
    return Intl.message(
      'No tables yet',
      name: 'product_tables_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Create your first table to organize your products here.`
  String get product_tables_empty_subtitle {
    return Intl.message(
      'Create your first table to organize your products here.',
      name: 'product_tables_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No tables match your search`
  String get product_tables_search_empty {
    return Intl.message(
      'No tables match your search',
      name: 'product_tables_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load your tables`
  String get product_tables_error_title {
    return Intl.message(
      'Couldn\'t load your tables',
      name: 'product_tables_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get product_tables_error_subtitle {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'product_tables_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get product_tables_retry {
    return Intl.message(
      'Try again',
      name: 'product_tables_retry',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{No fields} =1{1 field} other{{count} fields}}`
  String table_field_count(num count) {
    return Intl.plural(
      count,
      zero: 'No fields',
      one: '1 field',
      other: '$count fields',
      name: 'table_field_count',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =0{No records} =1{1 record} other{{count} records}}`
  String table_record_count(num count) {
    return Intl.plural(
      count,
      zero: 'No records',
      one: '1 record',
      other: '$count records',
      name: 'table_record_count',
      desc: '',
      args: [count],
    );
  }

  /// `Table`
  String get product_table_view_title {
    return Intl.message(
      'Table',
      name: 'product_table_view_title',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load this table`
  String get product_table_view_error_title {
    return Intl.message(
      'Couldn\'t load this table',
      name: 'product_table_view_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get product_table_view_error_subtitle {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'product_table_view_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `This table is empty`
  String get product_table_view_empty_title {
    return Intl.message(
      'This table is empty',
      name: 'product_table_view_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Add stock to see its rows here.`
  String get product_table_view_empty_subtitle {
    return Intl.message(
      'Add stock to see its rows here.',
      name: 'product_table_view_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Page {page}`
  String product_table_view_page(Object page) {
    return Intl.message(
      'Page $page',
      name: 'product_table_view_page',
      desc: '',
      args: [page],
    );
  }

  /// `Previous page`
  String get product_table_view_previous {
    return Intl.message(
      'Previous page',
      name: 'product_table_view_previous',
      desc: '',
      args: [],
    );
  }

  /// `Next page`
  String get product_table_view_next {
    return Intl.message(
      'Next page',
      name: 'product_table_view_next',
      desc: '',
      args: [],
    );
  }

  /// `Add item`
  String get product_table_view_add_item {
    return Intl.message(
      'Add item',
      name: 'product_table_view_add_item',
      desc: '',
      args: [],
    );
  }

  /// `Fill in at least one field to add an item`
  String get product_table_view_empty_row {
    return Intl.message(
      'Fill in at least one field to add an item',
      name: 'product_table_view_empty_row',
      desc: '',
      args: [],
    );
  }

  /// `Item added`
  String get product_table_view_item_added {
    return Intl.message(
      'Item added',
      name: 'product_table_view_item_added',
      desc: '',
      args: [],
    );
  }

  /// `Generate SKU`
  String get product_table_view_sku_generate {
    return Intl.message(
      'Generate SKU',
      name: 'product_table_view_sku_generate',
      desc: '',
      args: [],
    );
  }

  /// `Create a new random code for this item`
  String get product_table_view_sku_generate_hint {
    return Intl.message(
      'Create a new random code for this item',
      name: 'product_table_view_sku_generate_hint',
      desc: '',
      args: [],
    );
  }

  /// `Full date`
  String get product_table_view_date_full {
    return Intl.message(
      'Full date',
      name: 'product_table_view_date_full',
      desc: '',
      args: [],
    );
  }

  /// `Show this column with its numbers and its time`
  String get product_table_view_date_full_hint {
    return Intl.message(
      'Show this column with its numbers and its time',
      name: 'product_table_view_date_full_hint',
      desc: '',
      args: [],
    );
  }

  /// `Written date`
  String get product_table_view_date_short {
    return Intl.message(
      'Written date',
      name: 'product_table_view_date_short',
      desc: '',
      args: [],
    );
  }

  /// `Show this column written out, as Feb 12, 2026`
  String get product_table_view_date_short_hint {
    return Intl.message(
      'Show this column written out, as Feb 12, 2026',
      name: 'product_table_view_date_short_hint',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{No rows match your search} =1{1 row matches} other{{count} rows match}}`
  String product_table_view_search_count(num count) {
    return Intl.plural(
      count,
      zero: 'No rows match your search',
      one: '1 row matches',
      other: '$count rows match',
      name: 'product_table_view_search_count',
      desc: '',
      args: [count],
    );
  }

  /// `View image`
  String get product_table_view_image_view {
    return Intl.message(
      'View image',
      name: 'product_table_view_image_view',
      desc: '',
      args: [],
    );
  }

  /// `Upload image`
  String get product_table_view_image_upload {
    return Intl.message(
      'Upload image',
      name: 'product_table_view_image_upload',
      desc: '',
      args: [],
    );
  }

  /// `Pick an image`
  String get product_table_view_image_library {
    return Intl.message(
      'Pick an image',
      name: 'product_table_view_image_library',
      desc: '',
      args: [],
    );
  }

  /// `Remove image`
  String get product_table_view_image_remove {
    return Intl.message(
      'Remove image',
      name: 'product_table_view_image_remove',
      desc: '',
      args: [],
    );
  }

  /// `Images`
  String get product_table_view_image_files {
    return Intl.message(
      'Images',
      name: 'product_table_view_image_files',
      desc: '',
      args: [],
    );
  }

  /// `That image is over 10 MB. Pick a lighter one.`
  String get product_table_view_image_large {
    return Intl.message(
      'That image is over 10 MB. Pick a lighter one.',
      name: 'product_table_view_image_large',
      desc: '',
      args: [],
    );
  }

  /// `Save this item first to add a picture to it`
  String get product_table_view_image_unsaved {
    return Intl.message(
      'Save this item first to add a picture to it',
      name: 'product_table_view_image_unsaved',
      desc: '',
      args: [],
    );
  }

  /// `Close image`
  String get image_viewer_close {
    return Intl.message(
      'Close image',
      name: 'image_viewer_close',
      desc: '',
      args: [],
    );
  }

  /// `Define the table where your products will live`
  String get create_table_subtitle {
    return Intl.message(
      'Define the table where your products will live',
      name: 'create_table_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get table_title_input {
    return Intl.message('Title', name: 'table_title_input', desc: '', args: []);
  }

  /// `Name of the table`
  String get table_title_placeholder {
    return Intl.message(
      'Name of the table',
      name: 'table_title_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Description (optional)`
  String get table_description_title {
    return Intl.message(
      'Description (optional)',
      name: 'table_description_title',
      desc: '',
      args: [],
    );
  }

  /// `What does this table contain?`
  String get table_description_placeholder {
    return Intl.message(
      'What does this table contain?',
      name: 'table_description_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Color`
  String get table_color_title {
    return Intl.message('Color', name: 'table_color_title', desc: '', args: []);
  }

  /// `Template`
  String get table_template_title {
    return Intl.message(
      'Template',
      name: 'table_template_title',
      desc: '',
      args: [],
    );
  }

  /// `Choose a template`
  String get table_template_placeholder {
    return Intl.message(
      'Choose a template',
      name: 'table_template_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `No template matches your search`
  String get table_template_empty {
    return Intl.message(
      'No template matches your search',
      name: 'table_template_empty',
      desc: '',
      args: [],
    );
  }

  /// `Blank template`
  String get table_template_blank {
    return Intl.message(
      'Blank template',
      name: 'table_template_blank',
      desc: '',
      args: [],
    );
  }

  /// `Clothing`
  String get table_template_clothing {
    return Intl.message(
      'Clothing',
      name: 'table_template_clothing',
      desc: '',
      args: [],
    );
  }

  /// `Shoes`
  String get table_template_shoes {
    return Intl.message(
      'Shoes',
      name: 'table_template_shoes',
      desc: '',
      args: [],
    );
  }

  /// `Smartphones & electronics`
  String get table_template_electronics {
    return Intl.message(
      'Smartphones & electronics',
      name: 'table_template_electronics',
      desc: '',
      args: [],
    );
  }

  /// `Home appliances`
  String get table_template_appliances {
    return Intl.message(
      'Home appliances',
      name: 'table_template_appliances',
      desc: '',
      args: [],
    );
  }

  /// `Home & decor`
  String get table_template_home {
    return Intl.message(
      'Home & decor',
      name: 'table_template_home',
      desc: '',
      args: [],
    );
  }

  /// `Health`
  String get table_template_health {
    return Intl.message(
      'Health',
      name: 'table_template_health',
      desc: '',
      args: [],
    );
  }

  /// `Beauty & personal care`
  String get table_template_beauty {
    return Intl.message(
      'Beauty & personal care',
      name: 'table_template_beauty',
      desc: '',
      args: [],
    );
  }

  /// `Food & beverages`
  String get table_template_food {
    return Intl.message(
      'Food & beverages',
      name: 'table_template_food',
      desc: '',
      args: [],
    );
  }

  /// `Accessories`
  String get table_template_accessories {
    return Intl.message(
      'Accessories',
      name: 'table_template_accessories',
      desc: '',
      args: [],
    );
  }

  /// `Fields`
  String get table_fields_title {
    return Intl.message(
      'Fields',
      name: 'table_fields_title',
      desc: '',
      args: [],
    );
  }

  /// `Each field is a column of the table. Its type tells the AI what information it holds and shapes how it is filled in when adding stock.`
  String get table_fields_subtitle {
    return Intl.message(
      'Each field is a column of the table. Its type tells the AI what information it holds and shapes how it is filled in when adding stock.',
      name: 'table_fields_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No fields yet. Add the first one to define what each product stores.`
  String get table_fields_empty {
    return Intl.message(
      'No fields yet. Add the first one to define what each product stores.',
      name: 'table_fields_empty',
      desc: '',
      args: [],
    );
  }

  /// `Add at least one field before creating the table`
  String get table_fields_required {
    return Intl.message(
      'Add at least one field before creating the table',
      name: 'table_fields_required',
      desc: '',
      args: [],
    );
  }

  /// `Field name`
  String get table_field_name_title {
    return Intl.message(
      'Field name',
      name: 'table_field_name_title',
      desc: '',
      args: [],
    );
  }

  /// `Name of the field`
  String get table_field_name_placeholder {
    return Intl.message(
      'Name of the field',
      name: 'table_field_name_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Field type`
  String get table_field_type_title {
    return Intl.message(
      'Field type',
      name: 'table_field_type_title',
      desc: '',
      args: [],
    );
  }

  /// `Type of information`
  String get table_field_type_placeholder {
    return Intl.message(
      'Type of information',
      name: 'table_field_type_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `No type matches your search`
  String get table_field_type_empty {
    return Intl.message(
      'No type matches your search',
      name: 'table_field_type_empty',
      desc: '',
      args: [],
    );
  }

  /// `Search options`
  String get table_field_option_search {
    return Intl.message(
      'Search options',
      name: 'table_field_option_search',
      desc: '',
      args: [],
    );
  }

  /// `No option matches your search`
  String get table_field_option_empty {
    return Intl.message(
      'No option matches your search',
      name: 'table_field_option_empty',
      desc: '',
      args: [],
    );
  }

  /// `No value`
  String get table_field_option_none {
    return Intl.message(
      'No value',
      name: 'table_field_option_none',
      desc: '',
      args: [],
    );
  }

  /// `New option`
  String get table_field_option_create {
    return Intl.message(
      'New option',
      name: 'table_field_option_create',
      desc: '',
      args: [],
    );
  }

  /// `Name of the option`
  String get table_field_option_placeholder {
    return Intl.message(
      'Name of the option',
      name: 'table_field_option_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Remove field`
  String get table_field_remove {
    return Intl.message(
      'Remove field',
      name: 'table_field_remove',
      desc: '',
      args: [],
    );
  }

  /// `Drag to reorder`
  String get table_field_reorder {
    return Intl.message(
      'Drag to reorder',
      name: 'table_field_reorder',
      desc: '',
      args: [],
    );
  }

  /// `Delete this field?`
  String get table_field_delete_title {
    return Intl.message(
      'Delete this field?',
      name: 'table_field_delete_title',
      desc: '',
      args: [],
    );
  }

  /// `Leaving the name empty deletes {name} and everything stored in it. This can't be undone.`
  String table_field_delete_message(Object name) {
    return Intl.message(
      'Leaving the name empty deletes $name and everything stored in it. This can\'t be undone.',
      name: 'table_field_delete_message',
      desc: '',
      args: [name],
    );
  }

  /// `Delete field`
  String get table_field_delete_confirm {
    return Intl.message(
      'Delete field',
      name: 'table_field_delete_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Add field`
  String get add_field {
    return Intl.message('Add field', name: 'add_field', desc: '', args: []);
  }

  /// `Add a column and choose the kind of information it holds`
  String get add_field_subtitle {
    return Intl.message(
      'Add a column and choose the kind of information it holds',
      name: 'add_field_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Field added`
  String get field_added {
    return Intl.message('Field added', name: 'field_added', desc: '', args: []);
  }

  /// `Table created`
  String get table_created {
    return Intl.message(
      'Table created',
      name: 'table_created',
      desc: '',
      args: [],
    );
  }

  /// `Table options`
  String get table_options {
    return Intl.message(
      'Table options',
      name: 'table_options',
      desc: '',
      args: [],
    );
  }

  /// `Rename table`
  String get rename_table {
    return Intl.message(
      'Rename table',
      name: 'rename_table',
      desc: '',
      args: [],
    );
  }

  /// `Change what this table is called. Everything else about it lives in its settings`
  String get rename_table_subtitle {
    return Intl.message(
      'Change what this table is called. Everything else about it lives in its settings',
      name: 'rename_table_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Table renamed`
  String get table_renamed {
    return Intl.message(
      'Table renamed',
      name: 'table_renamed',
      desc: '',
      args: [],
    );
  }

  /// `Delete table`
  String get delete_table {
    return Intl.message(
      'Delete table',
      name: 'delete_table',
      desc: '',
      args: [],
    );
  }

  /// `Delete this table?`
  String get table_delete_title {
    return Intl.message(
      'Delete this table?',
      name: 'table_delete_title',
      desc: '',
      args: [],
    );
  }

  /// `Deleting {name} removes its fields and everything stored in it. This can't be undone.`
  String table_delete_message(Object name) {
    return Intl.message(
      'Deleting $name removes its fields and everything stored in it. This can\'t be undone.',
      name: 'table_delete_message',
      desc: '',
      args: [name],
    );
  }

  /// `Table deleted`
  String get table_deleted {
    return Intl.message(
      'Table deleted',
      name: 'table_deleted',
      desc: '',
      args: [],
    );
  }

  /// `Text`
  String get field_type_text {
    return Intl.message('Text', name: 'field_type_text', desc: '', args: []);
  }

  /// `Short one-line text: names, brands, references`
  String get field_type_text_hint {
    return Intl.message(
      'Short one-line text: names, brands, references',
      name: 'field_type_text_hint',
      desc: '',
      args: [],
    );
  }

  /// `Long text`
  String get field_type_textarea {
    return Intl.message(
      'Long text',
      name: 'field_type_textarea',
      desc: '',
      args: [],
    );
  }

  /// `Multiline text: descriptions and notes`
  String get field_type_textarea_hint {
    return Intl.message(
      'Multiline text: descriptions and notes',
      name: 'field_type_textarea_hint',
      desc: '',
      args: [],
    );
  }

  /// `Number`
  String get field_type_number {
    return Intl.message(
      'Number',
      name: 'field_type_number',
      desc: '',
      args: [],
    );
  }

  /// `Whole numbers: units, sizes, quantities`
  String get field_type_number_hint {
    return Intl.message(
      'Whole numbers: units, sizes, quantities',
      name: 'field_type_number_hint',
      desc: '',
      args: [],
    );
  }

  /// `Decimal`
  String get field_type_decimal {
    return Intl.message(
      'Decimal',
      name: 'field_type_decimal',
      desc: '',
      args: [],
    );
  }

  /// `Numbers with decimals: weights and measures`
  String get field_type_decimal_hint {
    return Intl.message(
      'Numbers with decimals: weights and measures',
      name: 'field_type_decimal_hint',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get field_type_price {
    return Intl.message('Price', name: 'field_type_price', desc: '', args: []);
  }

  /// `A monetary amount`
  String get field_type_price_hint {
    return Intl.message(
      'A monetary amount',
      name: 'field_type_price_hint',
      desc: '',
      args: [],
    );
  }

  /// `SKU`
  String get field_type_sku {
    return Intl.message('SKU', name: 'field_type_sku', desc: '', args: []);
  }

  /// `Reference or article code, like a barcode`
  String get field_type_sku_hint {
    return Intl.message(
      'Reference or article code, like a barcode',
      name: 'field_type_sku_hint',
      desc: '',
      args: [],
    );
  }

  /// `Counter`
  String get field_type_counter {
    return Intl.message(
      'Counter',
      name: 'field_type_counter',
      desc: '',
      args: [],
    );
  }

  /// `A number that goes up on its own`
  String get field_type_counter_hint {
    return Intl.message(
      'A number that goes up on its own',
      name: 'field_type_counter_hint',
      desc: '',
      args: [],
    );
  }

  /// `Yes / No`
  String get field_type_boolean {
    return Intl.message(
      'Yes / No',
      name: 'field_type_boolean',
      desc: '',
      args: [],
    );
  }

  /// `Something that is either on or off`
  String get field_type_boolean_hint {
    return Intl.message(
      'Something that is either on or off',
      name: 'field_type_boolean_hint',
      desc: '',
      args: [],
    );
  }

  /// `Date`
  String get field_type_date {
    return Intl.message('Date', name: 'field_type_date', desc: '', args: []);
  }

  /// `A day: expiry, arrival or release`
  String get field_type_date_hint {
    return Intl.message(
      'A day: expiry, arrival or release',
      name: 'field_type_date_hint',
      desc: '',
      args: [],
    );
  }

  /// `Date and time`
  String get field_type_datetime {
    return Intl.message(
      'Date and time',
      name: 'field_type_datetime',
      desc: '',
      args: [],
    );
  }

  /// `A day and the time of day`
  String get field_type_datetime_hint {
    return Intl.message(
      'A day and the time of day',
      name: 'field_type_datetime_hint',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get field_type_email {
    return Intl.message('Email', name: 'field_type_email', desc: '', args: []);
  }

  /// `An email address`
  String get field_type_email_hint {
    return Intl.message(
      'An email address',
      name: 'field_type_email_hint',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get field_type_phone {
    return Intl.message('Phone', name: 'field_type_phone', desc: '', args: []);
  }

  /// `A phone number`
  String get field_type_phone_hint {
    return Intl.message(
      'A phone number',
      name: 'field_type_phone_hint',
      desc: '',
      args: [],
    );
  }

  /// `Link`
  String get field_type_url {
    return Intl.message('Link', name: 'field_type_url', desc: '', args: []);
  }

  /// `A web address`
  String get field_type_url_hint {
    return Intl.message(
      'A web address',
      name: 'field_type_url_hint',
      desc: '',
      args: [],
    );
  }

  /// `Options list`
  String get field_type_select {
    return Intl.message(
      'Options list',
      name: 'field_type_select',
      desc: '',
      args: [],
    );
  }

  /// `A closed list of options to pick from`
  String get field_type_select_hint {
    return Intl.message(
      'A closed list of options to pick from',
      name: 'field_type_select_hint',
      desc: '',
      args: [],
    );
  }

  /// `Image`
  String get field_type_image {
    return Intl.message('Image', name: 'field_type_image', desc: '', args: []);
  }

  /// `Photos of the product`
  String get field_type_image_hint {
    return Intl.message(
      'Photos of the product',
      name: 'field_type_image_hint',
      desc: '',
      args: [],
    );
  }

  /// `Smart text`
  String get field_type_vector {
    return Intl.message(
      'Smart text',
      name: 'field_type_vector',
      desc: '',
      args: [],
    );
  }

  /// `Free text the AI reads and searches by meaning`
  String get field_type_vector_hint {
    return Intl.message(
      'Free text the AI reads and searches by meaning',
      name: 'field_type_vector_hint',
      desc: '',
      args: [],
    );
  }

  /// `Stock`
  String get field_type_stock {
    return Intl.message('Stock', name: 'field_type_stock', desc: '', args: []);
  }

  /// `Units on hand, kept by the inventory engine`
  String get field_type_stock_hint {
    return Intl.message(
      'Units on hand, kept by the inventory engine',
      name: 'field_type_stock_hint',
      desc: '',
      args: [],
    );
  }

  /// `Products`
  String get section_products {
    return Intl.message(
      'Products',
      name: 'section_products',
      desc: '',
      args: [],
    );
  }

  /// `Reports`
  String get section_reports {
    return Intl.message('Reports', name: 'section_reports', desc: '', args: []);
  }

  /// `Connections`
  String get section_connections {
    return Intl.message(
      'Connections',
      name: 'section_connections',
      desc: '',
      args: [],
    );
  }

  /// `Connect channel`
  String get create_channel {
    return Intl.message(
      'Connect channel',
      name: 'create_channel',
      desc: '',
      args: [],
    );
  }

  /// `Configure channel`
  String get edit_channel {
    return Intl.message(
      'Configure channel',
      name: 'edit_channel',
      desc: '',
      args: [],
    );
  }

  /// `Disconnect channel`
  String get delete_channel {
    return Intl.message(
      'Disconnect channel',
      name: 'delete_channel',
      desc: '',
      args: [],
    );
  }

  /// `Channel options`
  String get channel_options {
    return Intl.message(
      'Channel options',
      name: 'channel_options',
      desc: '',
      args: [],
    );
  }

  /// `Search channels`
  String get search_channel {
    return Intl.message(
      'Search channels',
      name: 'search_channel',
      desc: '',
      args: [],
    );
  }

  /// `Conversations`
  String get conversations {
    return Intl.message(
      'Conversations',
      name: 'conversations',
      desc: '',
      args: [],
    );
  }

  /// `No conversations yet`
  String get conversations_empty_title {
    return Intl.message(
      'No conversations yet',
      name: 'conversations_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Here you'll read what your channels are talking about with your customers`
  String get conversations_empty_subtitle {
    return Intl.message(
      'Here you\'ll read what your channels are talking about with your customers',
      name: 'conversations_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't load your channels`
  String get channels_error_title {
    return Intl.message(
      'We couldn\'t load your channels',
      name: 'channels_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Check your connection and try again`
  String get channels_error_subtitle {
    return Intl.message(
      'Check your connection and try again',
      name: 'channels_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get channels_retry {
    return Intl.message(
      'Try again',
      name: 'channels_retry',
      desc: '',
      args: [],
    );
  }

  /// `No channels connected yet`
  String get channels_empty_title {
    return Intl.message(
      'No channels connected yet',
      name: 'channels_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Connect a WhatsApp number, a Facebook page or an Instagram account and let an agent answer for you`
  String get channels_empty_subtitle {
    return Intl.message(
      'Connect a WhatsApp number, a Facebook page or an Instagram account and let an agent answer for you',
      name: 'channels_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No channel matches your search`
  String get channels_search_empty {
    return Intl.message(
      'No channel matches your search',
      name: 'channels_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `Connected`
  String get channel_state_ready {
    return Intl.message(
      'Connected',
      name: 'channel_state_ready',
      desc: '',
      args: [],
    );
  }

  /// `Needs setup`
  String get channel_state_pending {
    return Intl.message(
      'Needs setup',
      name: 'channel_state_pending',
      desc: '',
      args: [],
    );
  }

  /// `Paused`
  String get channel_state_paused {
    return Intl.message(
      'Paused',
      name: 'channel_state_paused',
      desc: '',
      args: [],
    );
  }

  /// `Pause channel`
  String get channel_pause {
    return Intl.message(
      'Pause channel',
      name: 'channel_pause',
      desc: '',
      args: [],
    );
  }

  /// `Resume channel`
  String get channel_resume {
    return Intl.message(
      'Resume channel',
      name: 'channel_resume',
      desc: '',
      args: [],
    );
  }

  /// `Channel paused`
  String get channel_paused {
    return Intl.message(
      'Channel paused',
      name: 'channel_paused',
      desc: '',
      args: [],
    );
  }

  /// `Channel resumed`
  String get channel_resumed {
    return Intl.message(
      'Channel resumed',
      name: 'channel_resumed',
      desc: '',
      args: [],
    );
  }

  /// `Disconnect this channel?`
  String get channel_delete_title {
    return Intl.message(
      'Disconnect this channel?',
      name: 'channel_delete_title',
      desc: '',
      args: [],
    );
  }

  /// `Disconnecting {name} deletes the tokens stored for it. The account can be connected again, but you'll have to set it up from scratch.`
  String channel_delete_message(Object name) {
    return Intl.message(
      'Disconnecting $name deletes the tokens stored for it. The account can be connected again, but you\'ll have to set it up from scratch.',
      name: 'channel_delete_message',
      desc: '',
      args: [name],
    );
  }

  /// `Channel disconnected`
  String get channel_deleted {
    return Intl.message(
      'Channel disconnected',
      name: 'channel_deleted',
      desc: '',
      args: [],
    );
  }

  /// `Channel connected`
  String get channel_created {
    return Intl.message(
      'Channel connected',
      name: 'channel_created',
      desc: '',
      args: [],
    );
  }

  /// `Channel updated`
  String get channel_saved {
    return Intl.message(
      'Channel updated',
      name: 'channel_saved',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't open this channel`
  String get channel_open_error_title {
    return Intl.message(
      'We couldn\'t open this channel',
      name: 'channel_open_error_title',
      desc: '',
      args: [],
    );
  }

  /// `It may have been disconnected, or it belongs to another business`
  String get channel_open_error_subtitle {
    return Intl.message(
      'It may have been disconnected, or it belongs to another business',
      name: 'channel_open_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Channel`
  String get channel_identity_title {
    return Intl.message(
      'Channel',
      name: 'channel_identity_title',
      desc: '',
      args: [],
    );
  }

  /// `How you'll recognize this channel in your list`
  String get channel_identity_subtitle {
    return Intl.message(
      'How you\'ll recognize this channel in your list',
      name: 'channel_identity_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get channel_name_input {
    return Intl.message('Name', name: 'channel_name_input', desc: '', args: []);
  }

  /// `Sales, Support...`
  String get channel_name_placeholder {
    return Intl.message(
      'Sales, Support...',
      name: 'channel_name_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get channel_description_input {
    return Intl.message(
      'Description',
      name: 'channel_description_input',
      desc: '',
      args: [],
    );
  }

  /// `Optional description...`
  String get channel_description_placeholder {
    return Intl.message(
      'Optional description...',
      name: 'channel_description_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Channel type`
  String get channel_type_title {
    return Intl.message(
      'Channel type',
      name: 'channel_type_title',
      desc: '',
      args: [],
    );
  }

  /// `Which network this channel connects to. It decides which credentials you'll need below`
  String get channel_type_subtitle {
    return Intl.message(
      'Which network this channel connects to. It decides which credentials you\'ll need below',
      name: 'channel_type_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `The network can't be changed: its stored credentials belong to it. To use another one, connect a new channel`
  String get channel_type_locked {
    return Intl.message(
      'The network can\'t be changed: its stored credentials belong to it. To use another one, connect a new channel',
      name: 'channel_type_locked',
      desc: '',
      args: [],
    );
  }

  /// `Soon`
  String get channel_type_soon {
    return Intl.message('Soon', name: 'channel_type_soon', desc: '', args: []);
  }

  /// `Choose the type of channel you want to connect`
  String get channel_type_missing {
    return Intl.message(
      'Choose the type of channel you want to connect',
      name: 'channel_type_missing',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't load the available networks`
  String get channel_catalog_error {
    return Intl.message(
      'We couldn\'t load the available networks',
      name: 'channel_catalog_error',
      desc: '',
      args: [],
    );
  }

  /// `Messages`
  String get channel_capability_messages {
    return Intl.message(
      'Messages',
      name: 'channel_capability_messages',
      desc: '',
      args: [],
    );
  }

  /// `Comments`
  String get channel_capability_comments {
    return Intl.message(
      'Comments',
      name: 'channel_capability_comments',
      desc: '',
      args: [],
    );
  }

  /// `Posts`
  String get channel_capability_posts {
    return Intl.message(
      'Posts',
      name: 'channel_capability_posts',
      desc: '',
      args: [],
    );
  }

  /// `Mentions`
  String get channel_capability_mentions {
    return Intl.message(
      'Mentions',
      name: 'channel_capability_mentions',
      desc: '',
      args: [],
    );
  }

  /// `Calls`
  String get channel_capability_calls {
    return Intl.message(
      'Calls',
      name: 'channel_capability_calls',
      desc: '',
      args: [],
    );
  }

  /// `Agent role`
  String get channel_role_title {
    return Intl.message(
      'Agent role',
      name: 'channel_role_title',
      desc: '',
      args: [],
    );
  }

  /// `What the agent does when it answers on this channel`
  String get channel_role_subtitle {
    return Intl.message(
      'What the agent does when it answers on this channel',
      name: 'channel_role_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Seller`
  String get channel_role_seller {
    return Intl.message(
      'Seller',
      name: 'channel_role_seller',
      desc: '',
      args: [],
    );
  }

  /// `Presents products, answers prices and stock, and closes the order`
  String get channel_role_seller_hint {
    return Intl.message(
      'Presents products, answers prices and stock, and closes the order',
      name: 'channel_role_seller_hint',
      desc: '',
      args: [],
    );
  }

  /// `Support`
  String get channel_role_support {
    return Intl.message(
      'Support',
      name: 'channel_role_support',
      desc: '',
      args: [],
    );
  }

  /// `Solves problems with something the customer already bought`
  String get channel_role_support_hint {
    return Intl.message(
      'Solves problems with something the customer already bought',
      name: 'channel_role_support_hint',
      desc: '',
      args: [],
    );
  }

  /// `Agent`
  String get channel_role_agent {
    return Intl.message(
      'Agent',
      name: 'channel_role_agent',
      desc: '',
      args: [],
    );
  }

  /// `Answers whatever comes, without pushing towards a sale`
  String get channel_role_agent_hint {
    return Intl.message(
      'Answers whatever comes, without pushing towards a sale',
      name: 'channel_role_agent_hint',
      desc: '',
      args: [],
    );
  }

  /// `Data`
  String get channel_source_title {
    return Intl.message(
      'Data',
      name: 'channel_source_title',
      desc: '',
      args: [],
    );
  }

  /// `Where the agent reads from. Without a source it answers from memory, which means it makes prices up`
  String get channel_source_subtitle {
    return Intl.message(
      'Where the agent reads from. Without a source it answers from memory, which means it makes prices up',
      name: 'channel_source_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Product table`
  String get channel_source_table {
    return Intl.message(
      'Product table',
      name: 'channel_source_table',
      desc: '',
      args: [],
    );
  }

  /// `Answers prices, stock and product details from one of your tables`
  String get channel_source_table_hint {
    return Intl.message(
      'Answers prices, stock and product details from one of your tables',
      name: 'channel_source_table_hint',
      desc: '',
      args: [],
    );
  }

  /// `Service calendar`
  String get channel_source_calendar {
    return Intl.message(
      'Service calendar',
      name: 'channel_source_calendar',
      desc: '',
      args: [],
    );
  }

  /// `Books appointments on a calendar of services`
  String get channel_source_calendar_hint {
    return Intl.message(
      'Books appointments on a calendar of services',
      name: 'channel_source_calendar_hint',
      desc: '',
      args: [],
    );
  }

  /// `Knowledge base`
  String get channel_source_knowledge {
    return Intl.message(
      'Knowledge base',
      name: 'channel_source_knowledge',
      desc: '',
      args: [],
    );
  }

  /// `Answers questions and spreads marketing from information you write`
  String get channel_source_knowledge_hint {
    return Intl.message(
      'Answers questions and spreads marketing from information you write',
      name: 'channel_source_knowledge_hint',
      desc: '',
      args: [],
    );
  }

  /// `Soon`
  String get channel_source_soon {
    return Intl.message(
      'Soon',
      name: 'channel_source_soon',
      desc: '',
      args: [],
    );
  }

  /// `Which table`
  String get channel_source_table_select {
    return Intl.message(
      'Which table',
      name: 'channel_source_table_select',
      desc: '',
      args: [],
    );
  }

  /// `Choose a product table`
  String get channel_source_table_placeholder {
    return Intl.message(
      'Choose a product table',
      name: 'channel_source_table_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `No table matches your search`
  String get channel_source_table_empty {
    return Intl.message(
      'No table matches your search',
      name: 'channel_source_table_empty',
      desc: '',
      args: [],
    );
  }

  /// `This business has no product tables yet. Create one in Products and come back`
  String get channel_source_no_tables {
    return Intl.message(
      'This business has no product tables yet. Create one in Products and come back',
      name: 'channel_source_no_tables',
      desc: '',
      args: [],
    );
  }

  /// `Choose which product table the agent reads from`
  String get channel_source_missing {
    return Intl.message(
      'Choose which product table the agent reads from',
      name: 'channel_source_missing',
      desc: '',
      args: [],
    );
  }

  /// `Tools`
  String get channel_tools_title {
    return Intl.message(
      'Tools',
      name: 'channel_tools_title',
      desc: '',
      args: [],
    );
  }

  /// `What the agent can process and produce besides text`
  String get channel_tools_subtitle {
    return Intl.message(
      'What the agent can process and produce besides text',
      name: 'channel_tools_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Each tool you turn on raises the processing cost of this channel, charged per conversation answered. Audio and video cost noticeably more than text.`
  String get channel_tools_cost {
    return Intl.message(
      'Each tool you turn on raises the processing cost of this channel, charged per conversation answered. Audio and video cost noticeably more than text.',
      name: 'channel_tools_cost',
      desc: '',
      args: [],
    );
  }

  /// `Voice`
  String get channel_tool_voice {
    return Intl.message(
      'Voice',
      name: 'channel_tool_voice',
      desc: '',
      args: [],
    );
  }

  /// `Transcribes voice notes and answers out loud`
  String get channel_tool_voice_hint {
    return Intl.message(
      'Transcribes voice notes and answers out loud',
      name: 'channel_tool_voice_hint',
      desc: '',
      args: [],
    );
  }

  /// `Images`
  String get channel_tool_images {
    return Intl.message(
      'Images',
      name: 'channel_tool_images',
      desc: '',
      args: [],
    );
  }

  /// `Reads the pictures customers send, and generates its own`
  String get channel_tool_images_hint {
    return Intl.message(
      'Reads the pictures customers send, and generates its own',
      name: 'channel_tool_images_hint',
      desc: '',
      args: [],
    );
  }

  /// `Video`
  String get channel_tool_video {
    return Intl.message(
      'Video',
      name: 'channel_tool_video',
      desc: '',
      args: [],
    );
  }

  /// `Watches videos customers send`
  String get channel_tool_video_hint {
    return Intl.message(
      'Watches videos customers send',
      name: 'channel_tool_video_hint',
      desc: '',
      args: [],
    );
  }

  /// `Documents`
  String get channel_tool_documents {
    return Intl.message(
      'Documents',
      name: 'channel_tool_documents',
      desc: '',
      args: [],
    );
  }

  /// `Reads attached files`
  String get channel_tool_documents_hint {
    return Intl.message(
      'Reads attached files',
      name: 'channel_tool_documents_hint',
      desc: '',
      args: [],
    );
  }

  /// `Credentials`
  String get channel_credentials_title {
    return Intl.message(
      'Credentials',
      name: 'channel_credentials_title',
      desc: '',
      args: [],
    );
  }

  /// `What {provider} needs to connect. You can save the channel without them and paste them later`
  String channel_credentials_subtitle(Object provider) {
    return Intl.message(
      'What $provider needs to connect. You can save the channel without them and paste them later',
      name: 'channel_credentials_subtitle',
      desc: '',
      args: [provider],
    );
  }

  /// `required to run`
  String get channel_field_required {
    return Intl.message(
      'required to run',
      name: 'channel_field_required',
      desc: '',
      args: [],
    );
  }

  /// `Already set — write to replace it`
  String get channel_secret_stored {
    return Intl.message(
      'Already set — write to replace it',
      name: 'channel_secret_stored',
      desc: '',
      args: [],
    );
  }

  /// `This channel isn't running yet`
  String get channel_missing_title {
    return Intl.message(
      'This channel isn\'t running yet',
      name: 'channel_missing_title',
      desc: '',
      args: [],
    );
  }

  /// `Connections`
  String get connections {
    return Intl.message('Connections', name: 'connections', desc: '', args: []);
  }

  /// `Connect account`
  String get create_connection {
    return Intl.message(
      'Connect account',
      name: 'create_connection',
      desc: '',
      args: [],
    );
  }

  /// `Disconnect`
  String get delete_connection {
    return Intl.message(
      'Disconnect',
      name: 'delete_connection',
      desc: '',
      args: [],
    );
  }

  /// `Connection options`
  String get connection_options {
    return Intl.message(
      'Connection options',
      name: 'connection_options',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't load your connections`
  String get connections_error_title {
    return Intl.message(
      'We couldn\'t load your connections',
      name: 'connections_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Check your connection and try again`
  String get connections_error_subtitle {
    return Intl.message(
      'Check your connection and try again',
      name: 'connections_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get connections_retry {
    return Intl.message(
      'Try again',
      name: 'connections_retry',
      desc: '',
      args: [],
    );
  }

  /// `No accounts connected yet`
  String get connections_empty_title {
    return Intl.message(
      'No accounts connected yet',
      name: 'connections_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Connect a WhatsApp number, a Facebook page or an Instagram account. Once connected, you can put bots to work on it`
  String get connections_empty_subtitle {
    return Intl.message(
      'Connect a WhatsApp number, a Facebook page or an Instagram account. Once connected, you can put bots to work on it',
      name: 'connections_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No connection matches your search`
  String get connections_search_empty {
    return Intl.message(
      'No connection matches your search',
      name: 'connections_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `Connected`
  String get connection_state_ready {
    return Intl.message(
      'Connected',
      name: 'connection_state_ready',
      desc: '',
      args: [],
    );
  }

  /// `Needs setup`
  String get connection_state_pending {
    return Intl.message(
      'Needs setup',
      name: 'connection_state_pending',
      desc: '',
      args: [],
    );
  }

  /// `Paused`
  String get connection_state_paused {
    return Intl.message(
      'Paused',
      name: 'connection_state_paused',
      desc: '',
      args: [],
    );
  }

  /// `Pause account`
  String get connection_pause {
    return Intl.message(
      'Pause account',
      name: 'connection_pause',
      desc: '',
      args: [],
    );
  }

  /// `Resume account`
  String get connection_resume {
    return Intl.message(
      'Resume account',
      name: 'connection_resume',
      desc: '',
      args: [],
    );
  }

  /// `Account paused`
  String get connection_paused {
    return Intl.message(
      'Account paused',
      name: 'connection_paused',
      desc: '',
      args: [],
    );
  }

  /// `Account resumed`
  String get connection_resumed {
    return Intl.message(
      'Account resumed',
      name: 'connection_resumed',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{No bots} =1{1 bot} other{{count} bots}}`
  String connection_bot_count(num count) {
    return Intl.plural(
      count,
      zero: 'No bots',
      one: '1 bot',
      other: '$count bots',
      name: 'connection_bot_count',
      desc: '',
      args: [count],
    );
  }

  /// `Disconnect this account?`
  String get connection_delete_title {
    return Intl.message(
      'Disconnect this account?',
      name: 'connection_delete_title',
      desc: '',
      args: [],
    );
  }

  /// `Disconnecting {name} deletes the credentials stored for it. The account can be connected again, but you'll have to set it up from scratch.`
  String connection_delete_message(Object name) {
    return Intl.message(
      'Disconnecting $name deletes the credentials stored for it. The account can be connected again, but you\'ll have to set it up from scratch.',
      name: 'connection_delete_message',
      desc: '',
      args: [name],
    );
  }

  /// `{count, plural, =1{The bot answering through it is deleted too — pause the account instead to keep it.} other{The {count} bots answering through it are deleted too — pause the account instead to keep them.}}`
  String connection_delete_bots(num count) {
    return Intl.plural(
      count,
      one: 'The bot answering through it is deleted too — pause the account instead to keep it.',
      other:
          'The $count bots answering through it are deleted too — pause the account instead to keep them.',
      name: 'connection_delete_bots',
      desc: '',
      args: [count],
    );
  }

  /// `Account disconnected`
  String get connection_deleted {
    return Intl.message(
      'Account disconnected',
      name: 'connection_deleted',
      desc: '',
      args: [],
    );
  }

  /// `Account connected`
  String get connection_created {
    return Intl.message(
      'Account connected',
      name: 'connection_created',
      desc: '',
      args: [],
    );
  }

  /// `Connection updated`
  String get connection_saved {
    return Intl.message(
      'Connection updated',
      name: 'connection_saved',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't open this connection`
  String get connection_open_error_title {
    return Intl.message(
      'We couldn\'t open this connection',
      name: 'connection_open_error_title',
      desc: '',
      args: [],
    );
  }

  /// `It may have been disconnected, or it belongs to another business`
  String get connection_open_error_subtitle {
    return Intl.message(
      'It may have been disconnected, or it belongs to another business',
      name: 'connection_open_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get connection_identity_title {
    return Intl.message(
      'Account',
      name: 'connection_identity_title',
      desc: '',
      args: [],
    );
  }

  /// `How you'll recognize this account in your list`
  String get connection_identity_subtitle {
    return Intl.message(
      'How you\'ll recognize this account in your list',
      name: 'connection_identity_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get connection_name_input {
    return Intl.message(
      'Name',
      name: 'connection_name_input',
      desc: '',
      args: [],
    );
  }

  /// `Main account, Sales...`
  String get connection_name_placeholder {
    return Intl.message(
      'Main account, Sales...',
      name: 'connection_name_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get connection_description_input {
    return Intl.message(
      'Description',
      name: 'connection_description_input',
      desc: '',
      args: [],
    );
  }

  /// `Optional description...`
  String get connection_description_placeholder {
    return Intl.message(
      'Optional description...',
      name: 'connection_description_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Service`
  String get connection_provider_title {
    return Intl.message(
      'Service',
      name: 'connection_provider_title',
      desc: '',
      args: [],
    );
  }

  /// `Which service this account belongs to. It decides which credentials you'll need below`
  String get connection_provider_subtitle {
    return Intl.message(
      'Which service this account belongs to. It decides which credentials you\'ll need below',
      name: 'connection_provider_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `The service can't be changed: the stored credentials belong to it. To use another one, connect a new account`
  String get connection_provider_locked {
    return Intl.message(
      'The service can\'t be changed: the stored credentials belong to it. To use another one, connect a new account',
      name: 'connection_provider_locked',
      desc: '',
      args: [],
    );
  }

  /// `Soon`
  String get connection_provider_soon {
    return Intl.message(
      'Soon',
      name: 'connection_provider_soon',
      desc: '',
      args: [],
    );
  }

  /// `Choose which service you want to connect`
  String get connection_provider_missing {
    return Intl.message(
      'Choose which service you want to connect',
      name: 'connection_provider_missing',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't load the available services`
  String get connection_catalog_error {
    return Intl.message(
      'We couldn\'t load the available services',
      name: 'connection_catalog_error',
      desc: '',
      args: [],
    );
  }

  /// `Direct messages`
  String get connection_scope_messages {
    return Intl.message(
      'Direct messages',
      name: 'connection_scope_messages',
      desc: '',
      args: [],
    );
  }

  /// `Comments on posts`
  String get connection_scope_comments {
    return Intl.message(
      'Comments on posts',
      name: 'connection_scope_comments',
      desc: '',
      args: [],
    );
  }

  /// `Comments on ads`
  String get connection_scope_ad_comments {
    return Intl.message(
      'Comments on ads',
      name: 'connection_scope_ad_comments',
      desc: '',
      args: [],
    );
  }

  /// `Mentions and tags`
  String get connection_scope_mentions {
    return Intl.message(
      'Mentions and tags',
      name: 'connection_scope_mentions',
      desc: '',
      args: [],
    );
  }

  /// `Posts`
  String get connection_scope_posts {
    return Intl.message(
      'Posts',
      name: 'connection_scope_posts',
      desc: '',
      args: [],
    );
  }

  /// `Calls`
  String get connection_scope_calls {
    return Intl.message(
      'Calls',
      name: 'connection_scope_calls',
      desc: '',
      args: [],
    );
  }

  /// `Credentials`
  String get connection_credentials_title {
    return Intl.message(
      'Credentials',
      name: 'connection_credentials_title',
      desc: '',
      args: [],
    );
  }

  /// `What {provider} needs to connect. You can save the account without them and paste them later`
  String connection_credentials_subtitle(Object provider) {
    return Intl.message(
      'What $provider needs to connect. You can save the account without them and paste them later',
      name: 'connection_credentials_subtitle',
      desc: '',
      args: [provider],
    );
  }

  /// `required to run`
  String get connection_field_required {
    return Intl.message(
      'required to run',
      name: 'connection_field_required',
      desc: '',
      args: [],
    );
  }

  /// `Already set — write to replace it`
  String get connection_secret_stored {
    return Intl.message(
      'Already set — write to replace it',
      name: 'connection_secret_stored',
      desc: '',
      args: [],
    );
  }

  /// `This account isn't ready yet`
  String get connection_missing_title {
    return Intl.message(
      'This account isn\'t ready yet',
      name: 'connection_missing_title',
      desc: '',
      args: [],
    );
  }

  /// `Notifications`
  String get notifications {
    return Intl.message(
      'Notifications',
      name: 'notifications',
      desc: '',
      args: [],
    );
  }

  /// `Inbox`
  String get inbox {
    return Intl.message('Inbox', name: 'inbox', desc: '', args: []);
  }

  /// `Coming soon`
  String get coming_soon {
    return Intl.message('Coming soon', name: 'coming_soon', desc: '', args: []);
  }

  /// `Visible`
  String get field_visibility_visible {
    return Intl.message(
      'Visible',
      name: 'field_visibility_visible',
      desc: '',
      args: [],
    );
  }

  /// `Declared`
  String get field_visibility_declared {
    return Intl.message(
      'Declared',
      name: 'field_visibility_declared',
      desc: '',
      args: [],
    );
  }

  /// `Hidden`
  String get field_visibility_hidden {
    return Intl.message(
      'Hidden',
      name: 'field_visibility_hidden',
      desc: '',
      args: [],
    );
  }

  /// `The AI reads this column and can quote what it says`
  String get field_visibility_visible_hint {
    return Intl.message(
      'The AI reads this column and can quote what it says',
      name: 'field_visibility_visible_hint',
      desc: '',
      args: [],
    );
  }

  /// `The AI knows the column exists and can filter by it, but never says what it holds. This is where a cost price belongs`
  String get field_visibility_declared_hint {
    return Intl.message(
      'The AI knows the column exists and can filter by it, but never says what it holds. This is where a cost price belongs',
      name: 'field_visibility_declared_hint',
      desc: '',
      args: [],
    );
  }

  /// `The AI doesn't know this column exists`
  String get field_visibility_hidden_hint {
    return Intl.message(
      'The AI doesn\'t know this column exists',
      name: 'field_visibility_hidden_hint',
      desc: '',
      args: [],
    );
  }

  /// `Table settings`
  String get table_settings_title {
    return Intl.message(
      'Table settings',
      name: 'table_settings_title',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get table_settings_refresh {
    return Intl.message(
      'Refresh',
      name: 'table_settings_refresh',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't open this table`
  String get table_settings_error_title {
    return Intl.message(
      'We couldn\'t open this table',
      name: 'table_settings_error_title',
      desc: '',
      args: [],
    );
  }

  /// `It may have been deleted, or it belongs to another business`
  String get table_settings_error_subtitle {
    return Intl.message(
      'It may have been deleted, or it belongs to another business',
      name: 'table_settings_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Table`
  String get table_settings_summary_title {
    return Intl.message(
      'Table',
      name: 'table_settings_summary_title',
      desc: '',
      args: [],
    );
  }

  /// `What this table holds and how big it is`
  String get table_settings_summary_subtitle {
    return Intl.message(
      'What this table holds and how big it is',
      name: 'table_settings_summary_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Records`
  String get table_settings_stat_records {
    return Intl.message(
      'Records',
      name: 'table_settings_stat_records',
      desc: '',
      args: [],
    );
  }

  /// `Columns`
  String get table_settings_stat_columns {
    return Intl.message(
      'Columns',
      name: 'table_settings_stat_columns',
      desc: '',
      args: [],
    );
  }

  /// `Channels`
  String get table_settings_stat_channels {
    return Intl.message(
      'Channels',
      name: 'table_settings_stat_channels',
      desc: '',
      args: [],
    );
  }

  /// `Unknown`
  String get table_settings_unknown {
    return Intl.message(
      'Unknown',
      name: 'table_settings_unknown',
      desc: '',
      args: [],
    );
  }

  /// `The rows live in a different database than the columns, so the count can fail on its own. It doesn't mean the table is empty`
  String get table_settings_records_unknown_hint {
    return Intl.message(
      'The rows live in a different database than the columns, so the count can fail on its own. It doesn\'t mean the table is empty',
      name: 'table_settings_records_unknown_hint',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get table_settings_name {
    return Intl.message(
      'Title',
      name: 'table_settings_name',
      desc: '',
      args: [],
    );
  }

  /// `What this table is called everywhere it shows up: the listing, the sheet header and whatever a bot says about it`
  String get table_settings_name_hint {
    return Intl.message(
      'What this table is called everywhere it shows up: the listing, the sheet header and whatever a bot says about it',
      name: 'table_settings_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Edit {field}`
  String table_settings_edit(Object field) {
    return Intl.message(
      'Edit $field',
      name: 'table_settings_edit',
      desc: '',
      args: [field],
    );
  }

  /// `Add {field}`
  String table_settings_add(Object field) {
    return Intl.message(
      'Add $field',
      name: 'table_settings_add',
      desc: '',
      args: [field],
    );
  }

  /// `Description`
  String get table_settings_description {
    return Intl.message(
      'Description',
      name: 'table_settings_description',
      desc: '',
      args: [],
    );
  }

  /// `No description`
  String get table_settings_description_empty {
    return Intl.message(
      'No description',
      name: 'table_settings_description_empty',
      desc: '',
      args: [],
    );
  }

  /// `Identifier`
  String get table_settings_id {
    return Intl.message(
      'Identifier',
      name: 'table_settings_id',
      desc: '',
      args: [],
    );
  }

  /// `The id this table travels under. You'll need it to point anything outside the app at it`
  String get table_settings_id_hint {
    return Intl.message(
      'The id this table travels under. You\'ll need it to point anything outside the app at it',
      name: 'table_settings_id_hint',
      desc: '',
      args: [],
    );
  }

  /// `Show identifier`
  String get table_settings_id_show {
    return Intl.message(
      'Show identifier',
      name: 'table_settings_id_show',
      desc: '',
      args: [],
    );
  }

  /// `Hide identifier`
  String get table_settings_id_hide {
    return Intl.message(
      'Hide identifier',
      name: 'table_settings_id_hide',
      desc: '',
      args: [],
    );
  }

  /// `Copy identifier`
  String get table_settings_id_copy {
    return Intl.message(
      'Copy identifier',
      name: 'table_settings_id_copy',
      desc: '',
      args: [],
    );
  }

  /// `Identifier copied`
  String get table_settings_id_copied {
    return Intl.message(
      'Identifier copied',
      name: 'table_settings_id_copied',
      desc: '',
      args: [],
    );
  }

  /// `Dates`
  String get table_settings_dates_title {
    return Intl.message(
      'Dates',
      name: 'table_settings_dates_title',
      desc: '',
      args: [],
    );
  }

  /// `A table has two: when its structure last changed and when data last arrived`
  String get table_settings_dates_subtitle {
    return Intl.message(
      'A table has two: when its structure last changed and when data last arrived',
      name: 'table_settings_dates_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Created`
  String get table_settings_created {
    return Intl.message(
      'Created',
      name: 'table_settings_created',
      desc: '',
      args: [],
    );
  }

  /// `Structure updated`
  String get table_settings_updated {
    return Intl.message(
      'Structure updated',
      name: 'table_settings_updated',
      desc: '',
      args: [],
    );
  }

  /// `The last change to the table or to any of its columns. Renaming a column or changing its type counts, and neither touches the rows`
  String get table_settings_updated_hint {
    return Intl.message(
      'The last change to the table or to any of its columns. Renaming a column or changing its type counts, and neither touches the rows',
      name: 'table_settings_updated_hint',
      desc: '',
      args: [],
    );
  }

  /// `Last record`
  String get table_settings_last_record {
    return Intl.message(
      'Last record',
      name: 'table_settings_last_record',
      desc: '',
      args: [],
    );
  }

  /// `When a row was last stored. Editing an existing row doesn't move it`
  String get table_settings_last_record_hint {
    return Intl.message(
      'When a row was last stored. Editing an existing row doesn\'t move it',
      name: 'table_settings_last_record_hint',
      desc: '',
      args: [],
    );
  }

  /// `No records yet`
  String get table_settings_no_records {
    return Intl.message(
      'No records yet',
      name: 'table_settings_no_records',
      desc: '',
      args: [],
    );
  }

  /// `Columns`
  String get table_settings_columns_title {
    return Intl.message(
      'Columns',
      name: 'table_settings_columns_title',
      desc: '',
      args: [],
    );
  }

  /// `What each one holds and how much of it the AI sees. Both are changed right here`
  String get table_settings_columns_subtitle {
    return Intl.message(
      'What each one holds and how much of it the AI sees. Both are changed right here',
      name: 'table_settings_columns_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `This table has no columns yet. Write a title in the first free column of the sheet to create one`
  String get table_settings_columns_empty {
    return Intl.message(
      'This table has no columns yet. Write a title in the first free column of the sheet to create one',
      name: 'table_settings_columns_empty',
      desc: '',
      args: [],
    );
  }

  /// `Types`
  String get table_settings_types {
    return Intl.message(
      'Types',
      name: 'table_settings_types',
      desc: '',
      args: [],
    );
  }

  /// `{type} · {count}`
  String table_settings_type_count(Object type, Object count) {
    return Intl.message(
      '$type · $count',
      name: 'table_settings_type_count',
      desc: '',
      args: [type, count],
    );
  }

  /// `{count, plural, =1{1 option} other{{count} options}}`
  String table_settings_options(num count) {
    return Intl.plural(
      count,
      one: '1 option',
      other: '$count options',
      name: 'table_settings_options',
      desc: '',
      args: [count],
    );
  }

  /// `No options yet`
  String get table_settings_options_empty {
    return Intl.message(
      'No options yet',
      name: 'table_settings_options_empty',
      desc: '',
      args: [],
    );
  }

  /// `Column`
  String get table_settings_column_field {
    return Intl.message(
      'Column',
      name: 'table_settings_column_field',
      desc: '',
      args: [],
    );
  }

  /// `Type`
  String get table_settings_column_type {
    return Intl.message(
      'Type',
      name: 'table_settings_column_type',
      desc: '',
      args: [],
    );
  }

  /// `Visibility`
  String get table_settings_column_visibility {
    return Intl.message(
      'Visibility',
      name: 'table_settings_column_visibility',
      desc: '',
      args: [],
    );
  }

  /// `Options`
  String get table_settings_column_options {
    return Intl.message(
      'Options',
      name: 'table_settings_column_options',
      desc: '',
      args: [],
    );
  }

  /// `Change what this column holds`
  String get table_settings_pick_type {
    return Intl.message(
      'Change what this column holds',
      name: 'table_settings_pick_type',
      desc: '',
      args: [],
    );
  }

  /// `Change how much the AI sees of this column`
  String get table_settings_pick_visibility {
    return Intl.message(
      'Change how much the AI sees of this column',
      name: 'table_settings_pick_visibility',
      desc: '',
      args: [],
    );
  }

  /// `The options this column offers`
  String get table_settings_pick_options {
    return Intl.message(
      'The options this column offers',
      name: 'table_settings_pick_options',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 column is still plain text} other{{count} columns are still plain text}}`
  String table_settings_untyped(num count) {
    return Intl.plural(
      count,
      one: '1 column is still plain text',
      other: '$count columns are still plain text',
      name: 'table_settings_untyped',
      desc: '',
      args: [count],
    );
  }

  /// `A column imported from a file is born as text. Giving it its real type is what lets the AI compare it, filter by it and quote it properly. You can change it in the Type column below`
  String get table_settings_untyped_hint {
    return Intl.message(
      'A column imported from a file is born as text. Giving it its real type is what lets the AI compare it, filter by it and quote it properly. You can change it in the Type column below',
      name: 'table_settings_untyped_hint',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{No columns} =1{1 column} other{{count} columns}}`
  String table_settings_column_count(num count) {
    return Intl.plural(
      count,
      zero: 'No columns',
      one: '1 column',
      other: '$count columns',
      name: 'table_settings_column_count',
      desc: '',
      args: [count],
    );
  }

  /// `Available`
  String get table_settings_available {
    return Intl.message(
      'Available',
      name: 'table_settings_available',
      desc: '',
      args: [],
    );
  }

  /// `Not available`
  String get table_settings_unavailable {
    return Intl.message(
      'Not available',
      name: 'table_settings_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `What the AI sees`
  String get table_settings_agent_title {
    return Intl.message(
      'What the AI sees',
      name: 'table_settings_agent_title',
      desc: '',
      args: [],
    );
  }

  /// `How much of this table a bot reading it can use`
  String get table_settings_agent_subtitle {
    return Intl.message(
      'How much of this table a bot reading it can use',
      name: 'table_settings_agent_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Visibility`
  String get table_settings_agent_visibility {
    return Intl.message(
      'Visibility',
      name: 'table_settings_agent_visibility',
      desc: '',
      args: [],
    );
  }

  /// `How many columns the AI can quote, use without saying, or doesn't know about`
  String get table_settings_agent_visibility_hint {
    return Intl.message(
      'How many columns the AI can quote, use without saying, or doesn\'t know about',
      name: 'table_settings_agent_visibility_hint',
      desc: '',
      args: [],
    );
  }

  /// `Search by meaning`
  String get table_settings_agent_searchable {
    return Intl.message(
      'Search by meaning',
      name: 'table_settings_agent_searchable',
      desc: '',
      args: [],
    );
  }

  /// `A column is indexed by meaning, so the AI can be asked for something described in words`
  String get table_settings_agent_searchable_on {
    return Intl.message(
      'A column is indexed by meaning, so the AI can be asked for something described in words',
      name: 'table_settings_agent_searchable_on',
      desc: '',
      args: [],
    );
  }

  /// `No column is indexed by meaning: the AI can filter this table, but it can't be asked for something described in words`
  String get table_settings_agent_searchable_off {
    return Intl.message(
      'No column is indexed by meaning: the AI can filter this table, but it can\'t be asked for something described in words',
      name: 'table_settings_agent_searchable_off',
      desc: '',
      args: [],
    );
  }

  /// `Filterable columns`
  String get table_settings_agent_filterable {
    return Intl.message(
      'Filterable columns',
      name: 'table_settings_agent_filterable',
      desc: '',
      args: [],
    );
  }

  /// `What the AI can filter and sort by: every column it's told exists`
  String get table_settings_agent_filterable_hint {
    return Intl.message(
      'What the AI can filter and sort by: every column it\'s told exists',
      name: 'table_settings_agent_filterable_hint',
      desc: '',
      args: [],
    );
  }

  /// `Stock`
  String get table_settings_agent_stock {
    return Intl.message(
      'Stock',
      name: 'table_settings_agent_stock',
      desc: '',
      args: [],
    );
  }

  /// `A stock column ties this table to the inventory ledger, so the AI can also reserve products`
  String get table_settings_agent_stock_on {
    return Intl.message(
      'A stock column ties this table to the inventory ledger, so the AI can also reserve products',
      name: 'table_settings_agent_stock_on',
      desc: '',
      args: [],
    );
  }

  /// `No stock column, so nothing here is counted against inventory`
  String get table_settings_agent_stock_off {
    return Intl.message(
      'No stock column, so nothing here is counted against inventory',
      name: 'table_settings_agent_stock_off',
      desc: '',
      args: [],
    );
  }

  /// `Images`
  String get table_settings_agent_image {
    return Intl.message(
      'Images',
      name: 'table_settings_agent_image',
      desc: '',
      args: [],
    );
  }

  /// `The AI can send pictures of these records`
  String get table_settings_agent_image_on {
    return Intl.message(
      'The AI can send pictures of these records',
      name: 'table_settings_agent_image_on',
      desc: '',
      args: [],
    );
  }

  /// `No image column`
  String get table_settings_agent_image_off {
    return Intl.message(
      'No image column',
      name: 'table_settings_agent_image_off',
      desc: '',
      args: [],
    );
  }

  /// `Connected channels`
  String get table_settings_channels_title {
    return Intl.message(
      'Connected channels',
      name: 'table_settings_channels_title',
      desc: '',
      args: [],
    );
  }

  /// `The bots answering with this table`
  String get table_settings_channels_subtitle {
    return Intl.message(
      'The bots answering with this table',
      name: 'table_settings_channels_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No bot reads this table`
  String get table_settings_channels_none {
    return Intl.message(
      'No bot reads this table',
      name: 'table_settings_channels_none',
      desc: '',
      args: [],
    );
  }

  /// `Pick it as a channel's data source to have that bot answer with it`
  String get table_settings_channels_none_hint {
    return Intl.message(
      'Pick it as a channel\'s data source to have that bot answer with it',
      name: 'table_settings_channels_none_hint',
      desc: '',
      args: [],
    );
  }

  /// `Chose this table`
  String get table_settings_channels_linked {
    return Intl.message(
      'Chose this table',
      name: 'table_settings_channels_linked',
      desc: '',
      args: [],
    );
  }

  /// `Read every table`
  String get table_settings_channels_open {
    return Intl.message(
      'Read every table',
      name: 'table_settings_channels_open',
      desc: '',
      args: [],
    );
  }

  /// `These bots have no data source configured, so they read every table this business has — including this one, without anybody having chosen it`
  String get table_settings_channels_open_hint {
    return Intl.message(
      'These bots have no data source configured, so they read every table this business has — including this one, without anybody having chosen it',
      name: 'table_settings_channels_open_hint',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[Locale.fromSubtags(languageCode: 'en')];
  }

  @override
  bool isSupported(Locale locale) => _isSupported(locale);
  @override
  Future<S> load(Locale locale) => S.load(locale);
  @override
  bool shouldReload(AppLocalizationDelegate old) => false;

  bool _isSupported(Locale locale) {
    for (var supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return true;
      }
    }
    return false;
  }
}
