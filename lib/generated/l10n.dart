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

  /// `Services`
  String get services {
    return Intl.message('Services', name: 'services', desc: '', args: []);
  }

  /// `My Bots`
  String get my_bots {
    return Intl.message('My Bots', name: 'my_bots', desc: '', args: []);
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

  /// `Food and beverage`
  String get business_type_food {
    return Intl.message(
      'Food and beverage',
      name: 'business_type_food',
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

  /// `Professional services`
  String get business_type_professional {
    return Intl.message(
      'Professional services',
      name: 'business_type_professional',
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

  /// `Construction`
  String get business_type_construction {
    return Intl.message(
      'Construction',
      name: 'business_type_construction',
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

  /// `Operating state`
  String get business_profile_state {
    return Intl.message(
      'Operating state',
      name: 'business_profile_state',
      desc: '',
      args: [],
    );
  }

  /// `Your access`
  String get business_profile_membership {
    return Intl.message(
      'Your access',
      name: 'business_profile_membership',
      desc: '',
      args: [],
    );
  }

  /// `Your role`
  String get business_profile_rank {
    return Intl.message(
      'Your role',
      name: 'business_profile_rank',
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
