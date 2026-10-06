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
    assert(_current != null,
        'No instance of S was loaded. Try to initialize the S delegate before accessing S.current.');
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
    assert(instance != null,
        'No instance of S present in the widget tree. Did you add S.delegate in localizationsDelegates?');
    return instance!;
  }

  static S? maybeOf(BuildContext context) {
    return Localizations.of<S>(context, S);
  }

  /// `Search`
  String get search {
    return Intl.message(
      'Search',
      name: 'search',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Email',
      name: 'email_input',
      desc: '',
      args: [],
    );
  }

  /// `Password`
  String get password_input {
    return Intl.message(
      'Password',
      name: 'password_input',
      desc: '',
      args: [],
    );
  }

  /// `Version`
  String get version {
    return Intl.message(
      'Version',
      name: 'version',
      desc: '',
      args: [],
    );
  }

  /// `Login`
  String get login {
    return Intl.message(
      'Login',
      name: 'login',
      desc: '',
      args: [],
    );
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

  /// `Edit`
  String get edit {
    return Intl.message(
      'Edit',
      name: 'edit',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get cancel {
    return Intl.message(
      'Cancel',
      name: 'cancel',
      desc: '',
      args: [],
    );
  }

  /// `Save`
  String get save {
    return Intl.message(
      'Save',
      name: 'save',
      desc: '',
      args: [],
    );
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

  /// `Pending Payments`
  String get pending_funds {
    return Intl.message(
      'Pending Payments',
      name: 'pending_funds',
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

  /// `Lyra`
  String get auth_brand {
    return Intl.message(
      'Lyra',
      name: 'auth_brand',
      desc: '',
      args: [],
    );
  }

  /// `Sign in or create your account`
  String get auth_title {
    return Intl.message(
      'Sign in or create your account',
      name: 'auth_title',
      desc: '',
      args: [],
    );
  }

  /// `Enter your email. If it's new to Lyra, we'll create your account with it.`
  String get auth_subtitle {
    return Intl.message(
      'Enter your email. If it\'s new to Lyra, we\'ll create your account with it.',
      name: 'auth_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get auth_continue {
    return Intl.message(
      'Continue',
      name: 'auth_continue',
      desc: '',
      args: [],
    );
  }

  /// `or continue with`
  String get auth_or_with {
    return Intl.message(
      'or continue with',
      name: 'auth_or_with',
      desc: '',
      args: [],
    );
  }

  /// `By continuing, you agree to our `
  String get auth_terms_prefix {
    return Intl.message(
      'By continuing, you agree to our ',
      name: 'auth_terms_prefix',
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

  /// `© {year} Lyra. All rights reserved.`
  String auth_footer_copyright(Object year) {
    return Intl.message(
      '© $year Lyra. All rights reserved.',
      name: 'auth_footer_copyright',
      desc: '',
      args: [year],
    );
  }

  /// `Privacy policy`
  String get auth_footer_privacy {
    return Intl.message(
      'Privacy policy',
      name: 'auth_footer_privacy',
      desc: '',
      args: [],
    );
  }

  /// `Terms and conditions`
  String get auth_footer_terms {
    return Intl.message(
      'Terms and conditions',
      name: 'auth_footer_terms',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get auth_footer_language {
    return Intl.message(
      'Language',
      name: 'auth_footer_language',
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
    return Intl.message(
      'Code',
      name: 'code_input',
      desc: '',
      args: [],
    );
  }

  /// `Check your inbox`
  String get verify_code_inbox_title {
    return Intl.message(
      'Check your inbox',
      name: 'verify_code_inbox_title',
      desc: '',
      args: [],
    );
  }

  /// `Enter the {length}-digit code we sent to`
  String verify_code_inbox_subtitle(Object length) {
    return Intl.message(
      'Enter the $length-digit code we sent to',
      name: 'verify_code_inbox_subtitle',
      desc: '',
      args: [length],
    );
  }

  /// `Change`
  String get verify_code_change_email {
    return Intl.message(
      'Change',
      name: 'verify_code_change_email',
      desc: '',
      args: [],
    );
  }

  /// `Didn't get it?`
  String get verify_code_not_received {
    return Intl.message(
      'Didn\'t get it?',
      name: 'verify_code_not_received',
      desc: '',
      args: [],
    );
  }

  /// `Resend in {time}`
  String verify_code_resend_in(Object time) {
    return Intl.message(
      'Resend in $time',
      name: 'verify_code_resend_in',
      desc: '',
      args: [time],
    );
  }

  /// `Signing you in…`
  String get verify_code_signing_in {
    return Intl.message(
      'Signing you in…',
      name: 'verify_code_signing_in',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Resend code',
      name: 'resend_code',
      desc: '',
      args: [],
    );
  }

  /// `A password isn't required, but we recommend creating one. Your account will be as secure as you want it to be: we offer several ways to protect it, and you decide how far to go.`
  String get verify_code_password_notice {
    return Intl.message(
      'A password isn\'t required, but we recommend creating one. Your account will be as secure as you want it to be: we offer several ways to protect it, and you decide how far to go.',
      name: 'verify_code_password_notice',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get verify_code_continue {
    return Intl.message(
      'Continue',
      name: 'verify_code_continue',
      desc: '',
      args: [],
    );
  }

  /// `Continue and create a password`
  String get verify_code_continue_with_password {
    return Intl.message(
      'Continue and create a password',
      name: 'verify_code_continue_with_password',
      desc: '',
      args: [],
    );
  }

  /// `Create your account`
  String get sign_up_code_title {
    return Intl.message(
      'Create your account',
      name: 'sign_up_code_title',
      desc: '',
      args: [],
    );
  }

  /// `We sent a code to {email}. Enter it with your name and your account is ready.`
  String sign_up_code_subtitle(Object email) {
    return Intl.message(
      'We sent a code to $email. Enter it with your name and your account is ready.',
      name: 'sign_up_code_subtitle',
      desc: '',
      args: [email],
    );
  }

  /// `Code from your email`
  String get sign_up_step_code {
    return Intl.message(
      'Code from your email',
      name: 'sign_up_step_code',
      desc: '',
      args: [],
    );
  }

  /// `Not there? Check your spam folder.`
  String get sign_up_step_code_hint {
    return Intl.message(
      'Not there? Check your spam folder.',
      name: 'sign_up_step_code_hint',
      desc: '',
      args: [],
    );
  }

  /// `Your name`
  String get sign_up_step_name {
    return Intl.message(
      'Your name',
      name: 'sign_up_step_name',
      desc: '',
      args: [],
    );
  }

  /// `Your team sees it next to everything you do.`
  String get sign_up_step_name_hint {
    return Intl.message(
      'Your team sees it next to everything you do.',
      name: 'sign_up_step_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Title`
  String get title {
    return Intl.message(
      'Title',
      name: 'title',
      desc: '',
      args: [],
    );
  }

  /// `Wallet`
  String get wallet {
    return Intl.message(
      'Wallet',
      name: 'wallet',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get add {
    return Intl.message(
      'Add',
      name: 'add',
      desc: '',
      args: [],
    );
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

  /// `Invited you · Review`
  String get business_selector_invitation {
    return Intl.message(
      'Invited you · Review',
      name: 'business_selector_invitation',
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
    return Intl.message(
      'Day',
      name: 'billing_day',
      desc: '',
      args: [],
    );
  }

  /// `Amount`
  String get amount {
    return Intl.message(
      'Amount',
      name: 'amount',
      desc: '',
      args: [],
    );
  }

  /// `Home`
  String get home {
    return Intl.message(
      'Home',
      name: 'home',
      desc: '',
      args: [],
    );
  }

  /// `Shop`
  String get shop {
    return Intl.message(
      'Shop',
      name: 'shop',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get account {
    return Intl.message(
      'Account',
      name: 'account',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Weekly',
      name: 'weekly',
      desc: '',
      args: [],
    );
  }

  /// `Monthly`
  String get monthly {
    return Intl.message(
      'Monthly',
      name: 'monthly',
      desc: '',
      args: [],
    );
  }

  /// `Annual`
  String get annual {
    return Intl.message(
      'Annual',
      name: 'annual',
      desc: '',
      args: [],
    );
  }

  /// `Custom`
  String get custom {
    return Intl.message(
      'Custom',
      name: 'custom',
      desc: '',
      args: [],
    );
  }

  /// `Days`
  String get custom_days {
    return Intl.message(
      'Days',
      name: 'custom_days',
      desc: '',
      args: [],
    );
  }

  /// `New service`
  String get new_service {
    return Intl.message(
      'New service',
      name: 'new_service',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Duration',
      name: 'trial_duration',
      desc: '',
      args: [],
    );
  }

  /// `Trial price`
  String get trial_price {
    return Intl.message(
      'Trial price',
      name: 'trial_price',
      desc: '',
      args: [],
    );
  }

  /// `Back`
  String get back {
    return Intl.message(
      'Back',
      name: 'back',
      desc: '',
      args: [],
    );
  }

  /// `a`
  String get a {
    return Intl.message(
      'a',
      name: 'a',
      desc: '',
      args: [],
    );
  }

  /// `Next`
  String get next {
    return Intl.message(
      'Next',
      name: 'next',
      desc: '',
      args: [],
    );
  }

  /// `Currency`
  String get currency {
    return Intl.message(
      'Currency',
      name: 'currency',
      desc: '',
      args: [],
    );
  }

  /// `USD`
  String get currency_usd {
    return Intl.message(
      'USD',
      name: 'currency_usd',
      desc: '',
      args: [],
    );
  }

  /// `EUR`
  String get currency_eur {
    return Intl.message(
      'EUR',
      name: 'currency_eur',
      desc: '',
      args: [],
    );
  }

  /// `Local`
  String get currency_local {
    return Intl.message(
      'Local',
      name: 'currency_local',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Once a year',
      name: 'once_a_year',
      desc: '',
      args: [],
    );
  }

  /// `You decide`
  String get you_decide {
    return Intl.message(
      'You decide',
      name: 'you_decide',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Confirm',
      name: 'confirm',
      desc: '',
      args: [],
    );
  }

  /// `All set!`
  String get summary_title {
    return Intl.message(
      'All set!',
      name: 'summary_title',
      desc: '',
      args: [],
    );
  }

  /// `Service`
  String get summary_service {
    return Intl.message(
      'Service',
      name: 'summary_service',
      desc: '',
      args: [],
    );
  }

  /// `Period`
  String get summary_period {
    return Intl.message(
      'Period',
      name: 'summary_period',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Price',
      name: 'summary_price',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get description {
    return Intl.message(
      'Description',
      name: 'description',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Upcoming',
      name: 'upcoming',
      desc: '',
      args: [],
    );
  }

  /// `Past`
  String get past_due {
    return Intl.message(
      'Past',
      name: 'past_due',
      desc: '',
      args: [],
    );
  }

  /// `Today`
  String get billing_today {
    return Intl.message(
      'Today',
      name: 'billing_today',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Simple',
      name: 'plan_simple',
      desc: '',
      args: [],
    );
  }

  /// `Normal`
  String get plan_normal {
    return Intl.message(
      'Normal',
      name: 'plan_normal',
      desc: '',
      args: [],
    );
  }

  /// `Freemium`
  String get plan_freemium {
    return Intl.message(
      'Freemium',
      name: 'plan_freemium',
      desc: '',
      args: [],
    );
  }

  /// `Basic`
  String get plan_basic {
    return Intl.message(
      'Basic',
      name: 'plan_basic',
      desc: '',
      args: [],
    );
  }

  /// `Plus`
  String get plan_plus {
    return Intl.message(
      'Plus',
      name: 'plan_plus',
      desc: '',
      args: [],
    );
  }

  /// `Pro`
  String get plan_pro {
    return Intl.message(
      'Pro',
      name: 'plan_pro',
      desc: '',
      args: [],
    );
  }

  /// `Duo`
  String get plan_duo {
    return Intl.message(
      'Duo',
      name: 'plan_duo',
      desc: '',
      args: [],
    );
  }

  /// `Family`
  String get plan_family {
    return Intl.message(
      'Family',
      name: 'plan_family',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Business',
      name: 'business',
      desc: '',
      args: [],
    );
  }

  /// `Products`
  String get products {
    return Intl.message(
      'Products',
      name: 'products',
      desc: '',
      args: [],
    );
  }

  /// `Inventory`
  String get inventory {
    return Intl.message(
      'Inventory',
      name: 'inventory',
      desc: '',
      args: [],
    );
  }

  /// `Services`
  String get services {
    return Intl.message(
      'Services',
      name: 'services',
      desc: '',
      args: [],
    );
  }

  /// `Channels`
  String get channels {
    return Intl.message(
      'Channels',
      name: 'channels',
      desc: '',
      args: [],
    );
  }

  /// `Finance`
  String get finance {
    return Intl.message(
      'Finance',
      name: 'finance',
      desc: '',
      args: [],
    );
  }

  /// `Marketing`
  String get marketing {
    return Intl.message(
      'Marketing',
      name: 'marketing',
      desc: '',
      args: [],
    );
  }

  /// `Report`
  String get report {
    return Intl.message(
      'Report',
      name: 'report',
      desc: '',
      args: [],
    );
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

  /// `Server`
  String get local_server {
    return Intl.message(
      'Server',
      name: 'local_server',
      desc: '',
      args: [],
    );
  }

  /// `Sign out`
  String get sign_out {
    return Intl.message(
      'Sign out',
      name: 'sign_out',
      desc: '',
      args: [],
    );
  }

  /// `Your profile`
  String get side_bar_profile {
    return Intl.message(
      'Your profile',
      name: 'side_bar_profile',
      desc: '',
      args: [],
    );
  }

  /// `Your session ended. Sign in again to continue.`
  String get session_expired {
    return Intl.message(
      'Your session ended. Sign in again to continue.',
      name: 'session_expired',
      desc: '',
      args: [],
    );
  }

  /// `Could not sign out. Check your connection and try again.`
  String get sign_out_failed {
    return Intl.message(
      'Could not sign out. Check your connection and try again.',
      name: 'sign_out_failed',
      desc: '',
      args: [],
    );
  }

  /// `Expand`
  String get expand {
    return Intl.message(
      'Expand',
      name: 'expand',
      desc: '',
      args: [],
    );
  }

  /// `Collapse`
  String get collapse {
    return Intl.message(
      'Collapse',
      name: 'collapse',
      desc: '',
      args: [],
    );
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

  /// `You don't have access to this section in this business.`
  String get section_no_permission {
    return Intl.message(
      'You don\'t have access to this section in this business.',
      name: 'section_no_permission',
      desc: '',
      args: [],
    );
  }

  /// `Needs the internet`
  String get section_needs_internet_title {
    return Intl.message(
      'Needs the internet',
      name: 'section_needs_internet_title',
      desc: '',
      args: [],
    );
  }

  /// `This section works through the cloud. It opens as soon as Lyra is connected to the internet.`
  String get section_needs_internet_subtitle {
    return Intl.message(
      'This section works through the cloud. It opens as soon as Lyra is connected to the internet.',
      name: 'section_needs_internet_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Join with your company online`
  String get section_needs_link_title {
    return Intl.message(
      'Join with your company online',
      name: 'section_needs_link_title',
      desc: '',
      args: [],
    );
  }

  /// `This section works online. Join this server with your company online, in the Server section, to use it here.`
  String get section_needs_link_subtitle {
    return Intl.message(
      'This section works online. Join this server with your company online, in the Server section, to use it here.',
      name: 'section_needs_link_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Not available here`
  String get section_unavailable_title {
    return Intl.message(
      'Not available here',
      name: 'section_unavailable_title',
      desc: '',
      args: [],
    );
  }

  /// `This section is not part of Lyra on a local network.`
  String get section_unavailable_subtitle {
    return Intl.message(
      'This section is not part of Lyra on a local network.',
      name: 'section_unavailable_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `You don't have access to {section}`
  String permission_denied_title(Object section) {
    return Intl.message(
      'You don\'t have access to $section',
      name: 'permission_denied_title',
      desc: '',
      args: [section],
    );
  }

  /// `Your role in {business} doesn't include this section. Request access and whoever manages the business will review it.`
  String permission_denied_subtitle(Object business) {
    return Intl.message(
      'Your role in $business doesn\'t include this section. Request access and whoever manages the business will review it.',
      name: 'permission_denied_subtitle',
      desc: '',
      args: [business],
    );
  }

  /// `You already requested access to this section in {business}. You'll be able to open it as soon as it's granted.`
  String permission_denied_pending(Object business) {
    return Intl.message(
      'You already requested access to this section in $business. You\'ll be able to open it as soon as it\'s granted.',
      name: 'permission_denied_pending',
      desc: '',
      args: [business],
    );
  }

  /// `Request access`
  String get permission_request_action {
    return Intl.message(
      'Request access',
      name: 'permission_request_action',
      desc: '',
      args: [],
    );
  }

  /// `Request access`
  String get permission_request_title {
    return Intl.message(
      'Request access',
      name: 'permission_request_title',
      desc: '',
      args: [],
    );
  }

  /// `You're asking for access to {section} in {business}. You can add a note to explain why you need it.`
  String permission_request_subtitle(Object section, Object business) {
    return Intl.message(
      'You\'re asking for access to $section in $business. You can add a note to explain why you need it.',
      name: 'permission_request_subtitle',
      desc: '',
      args: [section, business],
    );
  }

  /// `Note (optional)`
  String get permission_request_reason {
    return Intl.message(
      'Note (optional)',
      name: 'permission_request_reason',
      desc: '',
      args: [],
    );
  }

  /// `E.g. I handle the night shift's sales`
  String get permission_request_reason_hint {
    return Intl.message(
      'E.g. I handle the night shift\'s sales',
      name: 'permission_request_reason_hint',
      desc: '',
      args: [],
    );
  }

  /// `The note can't be longer than {max} characters.`
  String permission_request_reason_long(Object max) {
    return Intl.message(
      'The note can\'t be longer than $max characters.',
      name: 'permission_request_reason_long',
      desc: '',
      args: [max],
    );
  }

  /// `Send request`
  String get permission_request_send {
    return Intl.message(
      'Send request',
      name: 'permission_request_send',
      desc: '',
      args: [],
    );
  }

  /// `Request sent. You'll be able to open {section} once it's granted.`
  String permission_request_sent(Object section) {
    return Intl.message(
      'Request sent. You\'ll be able to open $section once it\'s granted.',
      name: 'permission_request_sent',
      desc: '',
      args: [section],
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

  /// `People`
  String get employees_title {
    return Intl.message(
      'People',
      name: 'employees_title',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{Nobody active} =1{1 active} other{{count} active}}`
  String employees_active_count(num count) {
    return Intl.plural(
      count,
      zero: 'Nobody active',
      one: '1 active',
      other: '$count active',
      name: 'employees_active_count',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 invitation pending} other{{count} invitations pending}}`
  String employees_invited_count(num count) {
    return Intl.plural(
      count,
      one: '1 invitation pending',
      other: '$count invitations pending',
      name: 'employees_invited_count',
      desc: '',
      args: [count],
    );
  }

  /// `You`
  String get employees_you {
    return Intl.message(
      'You',
      name: 'employees_you',
      desc: '',
      args: [],
    );
  }

  /// `Former employees`
  String get employees_former_title {
    return Intl.message(
      'Former employees',
      name: 'employees_former_title',
      desc: '',
      args: [],
    );
  }

  /// `Working today`
  String get employees_group_working {
    return Intl.message(
      'Working today',
      name: 'employees_group_working',
      desc: '',
      args: [],
    );
  }

  /// `Away today`
  String get employees_group_away {
    return Intl.message(
      'Away today',
      name: 'employees_group_away',
      desc: '',
      args: [],
    );
  }

  /// `Starting later`
  String get employees_group_not_started {
    return Intl.message(
      'Starting later',
      name: 'employees_group_not_started',
      desc: '',
      args: [],
    );
  }

  /// `Waiting to accept`
  String get employees_group_invited {
    return Intl.message(
      'Waiting to accept',
      name: 'employees_group_invited',
      desc: '',
      args: [],
    );
  }

  /// `Person`
  String get employees_column_person {
    return Intl.message(
      'Person',
      name: 'employees_column_person',
      desc: '',
      args: [],
    );
  }

  /// `Contract`
  String get employees_column_contract {
    return Intl.message(
      'Contract',
      name: 'employees_column_contract',
      desc: '',
      args: [],
    );
  }

  /// `Since`
  String get employees_column_since {
    return Intl.message(
      'Since',
      name: 'employees_column_since',
      desc: '',
      args: [],
    );
  }

  /// `Status`
  String get employees_column_status {
    return Intl.message(
      'Status',
      name: 'employees_column_status',
      desc: '',
      args: [],
    );
  }

  /// `Pick someone`
  String get employees_select_title {
    return Intl.message(
      'Pick someone',
      name: 'employees_select_title',
      desc: '',
      args: [],
    );
  }

  /// `Select a person on the list to see everything about them here.`
  String get employees_select_subtitle {
    return Intl.message(
      'Select a person on the list to see everything about them here.',
      name: 'employees_select_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Invite`
  String get employees_invite {
    return Intl.message(
      'Invite',
      name: 'employees_invite',
      desc: '',
      args: [],
    );
  }

  /// `Invite someone`
  String get employees_invite_title {
    return Intl.message(
      'Invite someone',
      name: 'employees_invite_title',
      desc: '',
      args: [],
    );
  }

  /// `They don't need an account: when they sign up with this email, the invitation will be waiting for them.`
  String get employees_invite_subtitle {
    return Intl.message(
      'They don\'t need an account: when they sign up with this email, the invitation will be waiting for them.',
      name: 'employees_invite_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get employees_invite_email {
    return Intl.message(
      'Email',
      name: 'employees_invite_email',
      desc: '',
      args: [],
    );
  }

  /// `name@example.com`
  String get employees_invite_email_hint {
    return Intl.message(
      'name@example.com',
      name: 'employees_invite_email_hint',
      desc: '',
      args: [],
    );
  }

  /// `Job title`
  String get employees_invite_job {
    return Intl.message(
      'Job title',
      name: 'employees_invite_job',
      desc: '',
      args: [],
    );
  }

  /// `Cashier, accountant, driver…`
  String get employees_invite_job_hint {
    return Intl.message(
      'Cashier, accountant, driver…',
      name: 'employees_invite_job_hint',
      desc: '',
      args: [],
    );
  }

  /// `Send invitation`
  String get employees_invite_send {
    return Intl.message(
      'Send invitation',
      name: 'employees_invite_send',
      desc: '',
      args: [],
    );
  }

  /// `Permissions`
  String get employees_invite_permissions {
    return Intl.message(
      'Permissions',
      name: 'employees_invite_permissions',
      desc: '',
      args: [],
    );
  }

  /// `Pick a template`
  String get employees_invite_permissions_hint {
    return Intl.message(
      'Pick a template',
      name: 'employees_invite_permissions_hint',
      desc: '',
      args: [],
    );
  }

  /// `No permissions yet`
  String get employees_invite_permissions_none {
    return Intl.message(
      'No permissions yet',
      name: 'employees_invite_permissions_none',
      desc: '',
      args: [],
    );
  }

  /// `Give them access later, from their profile.`
  String get employees_invite_permissions_none_description {
    return Intl.message(
      'Give them access later, from their profile.',
      name: 'employees_invite_permissions_none_description',
      desc: '',
      args: [],
    );
  }

  /// `Lyra makes their account on this server and gives you a code to hand them. They use it, with a password of their own, the first time they sign in.`
  String get employees_invite_subtitle_local {
    return Intl.message(
      'Lyra makes their account on this server and gives you a code to hand them. They use it, with a password of their own, the first time they sign in.',
      name: 'employees_invite_subtitle_local',
      desc: '',
      args: [],
    );
  }

  /// `Give this code to the person you invited. On a device connected to this server, they type their email when signing in, then this code and a password of their own. It is shown only this once.`
  String get employees_invite_code_subtitle {
    return Intl.message(
      'Give this code to the person you invited. On a device connected to this server, they type their email when signing in, then this code and a password of their own. It is shown only this once.',
      name: 'employees_invite_code_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Valid until {date}, {time}.`
  String employees_invite_code_expires(String date, String time) {
    return Intl.message(
      'Valid until $date, $time.',
      name: 'employees_invite_code_expires',
      desc: '',
      args: [date, time],
    );
  }

  /// `Copy code`
  String get employees_invite_code_copy {
    return Intl.message(
      'Copy code',
      name: 'employees_invite_code_copy',
      desc: '',
      args: [],
    );
  }

  /// `Code copied.`
  String get employees_invite_code_copied {
    return Intl.message(
      'Code copied.',
      name: 'employees_invite_code_copied',
      desc: '',
      args: [],
    );
  }

  /// `Done`
  String get employees_invite_code_done {
    return Intl.message(
      'Done',
      name: 'employees_invite_code_done',
      desc: '',
      args: [],
    );
  }

  /// `No job filed`
  String get employee_state_unfiled {
    return Intl.message(
      'No job filed',
      name: 'employee_state_unfiled',
      desc: '',
      args: [],
    );
  }

  /// `Invitation pending`
  String get employee_state_invited {
    return Intl.message(
      'Invitation pending',
      name: 'employee_state_invited',
      desc: '',
      args: [],
    );
  }

  /// `Former`
  String get employee_state_ended {
    return Intl.message(
      'Former',
      name: 'employee_state_ended',
      desc: '',
      args: [],
    );
  }

  /// `Declined`
  String get employee_state_declined {
    return Intl.message(
      'Declined',
      name: 'employee_state_declined',
      desc: '',
      args: [],
    );
  }

  /// `Invitation withdrawn`
  String get employee_state_cancelled {
    return Intl.message(
      'Invitation withdrawn',
      name: 'employee_state_cancelled',
      desc: '',
      args: [],
    );
  }

  /// `Working`
  String get employee_work_working {
    return Intl.message(
      'Working',
      name: 'employee_work_working',
      desc: '',
      args: [],
    );
  }

  /// `Not started yet`
  String get employee_work_not_started {
    return Intl.message(
      'Not started yet',
      name: 'employee_work_not_started',
      desc: '',
      args: [],
    );
  }

  /// `On vacation`
  String get employee_leave_vacation {
    return Intl.message(
      'On vacation',
      name: 'employee_leave_vacation',
      desc: '',
      args: [],
    );
  }

  /// `Sick leave`
  String get employee_leave_sick {
    return Intl.message(
      'Sick leave',
      name: 'employee_leave_sick',
      desc: '',
      args: [],
    );
  }

  /// `Maternity leave`
  String get employee_leave_maternity {
    return Intl.message(
      'Maternity leave',
      name: 'employee_leave_maternity',
      desc: '',
      args: [],
    );
  }

  /// `Paternity leave`
  String get employee_leave_paternity {
    return Intl.message(
      'Paternity leave',
      name: 'employee_leave_paternity',
      desc: '',
      args: [],
    );
  }

  /// `Personal leave`
  String get employee_leave_personal {
    return Intl.message(
      'Personal leave',
      name: 'employee_leave_personal',
      desc: '',
      args: [],
    );
  }

  /// `Unpaid leave`
  String get employee_leave_unpaid {
    return Intl.message(
      'Unpaid leave',
      name: 'employee_leave_unpaid',
      desc: '',
      args: [],
    );
  }

  /// `Suspended`
  String get employee_leave_suspension {
    return Intl.message(
      'Suspended',
      name: 'employee_leave_suspension',
      desc: '',
      args: [],
    );
  }

  /// `Away`
  String get employee_leave_other {
    return Intl.message(
      'Away',
      name: 'employee_leave_other',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 day} other{{count} days}}`
  String employee_leave_days(num count) {
    return Intl.plural(
      count,
      one: '1 day',
      other: '$count days',
      name: 'employee_leave_days',
      desc: '',
      args: [count],
    );
  }

  /// `Away today`
  String get employee_leave_now_title {
    return Intl.message(
      'Away today',
      name: 'employee_leave_now_title',
      desc: '',
      args: [],
    );
  }

  /// `Permanent`
  String get employee_contract_permanent {
    return Intl.message(
      'Permanent',
      name: 'employee_contract_permanent',
      desc: '',
      args: [],
    );
  }

  /// `Fixed term`
  String get employee_contract_fixed_term {
    return Intl.message(
      'Fixed term',
      name: 'employee_contract_fixed_term',
      desc: '',
      args: [],
    );
  }

  /// `Probation`
  String get employee_contract_probation {
    return Intl.message(
      'Probation',
      name: 'employee_contract_probation',
      desc: '',
      args: [],
    );
  }

  /// `Internship`
  String get employee_contract_internship {
    return Intl.message(
      'Internship',
      name: 'employee_contract_internship',
      desc: '',
      args: [],
    );
  }

  /// `Freelance`
  String get employee_contract_freelance {
    return Intl.message(
      'Freelance',
      name: 'employee_contract_freelance',
      desc: '',
      args: [],
    );
  }

  /// `Temporary`
  String get employee_contract_temporary {
    return Intl.message(
      'Temporary',
      name: 'employee_contract_temporary',
      desc: '',
      args: [],
    );
  }

  /// `Contract ending soon`
  String get employee_contract_expiring {
    return Intl.message(
      'Contract ending soon',
      name: 'employee_contract_expiring',
      desc: '',
      args: [],
    );
  }

  /// `Contract expired`
  String get employee_contract_expired {
    return Intl.message(
      'Contract expired',
      name: 'employee_contract_expired',
      desc: '',
      args: [],
    );
  }

  /// `Full time`
  String get employee_workday_full_time {
    return Intl.message(
      'Full time',
      name: 'employee_workday_full_time',
      desc: '',
      args: [],
    );
  }

  /// `Part time`
  String get employee_workday_part_time {
    return Intl.message(
      'Part time',
      name: 'employee_workday_part_time',
      desc: '',
      args: [],
    );
  }

  /// `By the hour`
  String get employee_workday_hourly {
    return Intl.message(
      'By the hour',
      name: 'employee_workday_hourly',
      desc: '',
      args: [],
    );
  }

  /// `Shifts`
  String get employee_workday_shifts {
    return Intl.message(
      'Shifts',
      name: 'employee_workday_shifts',
      desc: '',
      args: [],
    );
  }

  /// `hour`
  String get employee_period_hour {
    return Intl.message(
      'hour',
      name: 'employee_period_hour',
      desc: '',
      args: [],
    );
  }

  /// `day`
  String get employee_period_day {
    return Intl.message(
      'day',
      name: 'employee_period_day',
      desc: '',
      args: [],
    );
  }

  /// `week`
  String get employee_period_week {
    return Intl.message(
      'week',
      name: 'employee_period_week',
      desc: '',
      args: [],
    );
  }

  /// `fortnight`
  String get employee_period_fortnight {
    return Intl.message(
      'fortnight',
      name: 'employee_period_fortnight',
      desc: '',
      args: [],
    );
  }

  /// `month`
  String get employee_period_month {
    return Intl.message(
      'month',
      name: 'employee_period_month',
      desc: '',
      args: [],
    );
  }

  /// `year`
  String get employee_period_year {
    return Intl.message(
      'year',
      name: 'employee_period_year',
      desc: '',
      args: [],
    );
  }

  /// `Resignation`
  String get employee_end_resignation {
    return Intl.message(
      'Resignation',
      name: 'employee_end_resignation',
      desc: '',
      args: [],
    );
  }

  /// `Dismissal`
  String get employee_end_dismissal {
    return Intl.message(
      'Dismissal',
      name: 'employee_end_dismissal',
      desc: '',
      args: [],
    );
  }

  /// `End of contract`
  String get employee_end_contract_end {
    return Intl.message(
      'End of contract',
      name: 'employee_end_contract_end',
      desc: '',
      args: [],
    );
  }

  /// `Mutual agreement`
  String get employee_end_mutual {
    return Intl.message(
      'Mutual agreement',
      name: 'employee_end_mutual',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get employee_end_other {
    return Intl.message(
      'Other',
      name: 'employee_end_other',
      desc: '',
      args: [],
    );
  }

  /// `National ID`
  String get employee_document_national_id {
    return Intl.message(
      'National ID',
      name: 'employee_document_national_id',
      desc: '',
      args: [],
    );
  }

  /// `Passport`
  String get employee_document_passport {
    return Intl.message(
      'Passport',
      name: 'employee_document_passport',
      desc: '',
      args: [],
    );
  }

  /// `Foreigner ID`
  String get employee_document_foreign_id {
    return Intl.message(
      'Foreigner ID',
      name: 'employee_document_foreign_id',
      desc: '',
      args: [],
    );
  }

  /// `Tax ID`
  String get employee_document_tax_id {
    return Intl.message(
      'Tax ID',
      name: 'employee_document_tax_id',
      desc: '',
      args: [],
    );
  }

  /// `Female`
  String get employee_sex_female {
    return Intl.message(
      'Female',
      name: 'employee_sex_female',
      desc: '',
      args: [],
    );
  }

  /// `Male`
  String get employee_sex_male {
    return Intl.message(
      'Male',
      name: 'employee_sex_male',
      desc: '',
      args: [],
    );
  }

  /// `Other`
  String get employee_sex_other {
    return Intl.message(
      'Other',
      name: 'employee_sex_other',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 year} other{{count} years}}`
  String employee_years(num count) {
    return Intl.plural(
      count,
      one: '1 year',
      other: '$count years',
      name: 'employee_years',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 month} other{{count} months}}`
  String employee_months(num count) {
    return Intl.plural(
      count,
      one: '1 month',
      other: '$count months',
      name: 'employee_months',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 day} other{{count} days}}`
  String employee_days(num count) {
    return Intl.plural(
      count,
      one: '1 day',
      other: '$count days',
      name: 'employee_days',
      desc: '',
      args: [count],
    );
  }

  /// `Less than a day`
  String get employee_span_none {
    return Intl.message(
      'Less than a day',
      name: 'employee_span_none',
      desc: '',
      args: [],
    );
  }

  /// `Not set`
  String get employee_value_none {
    return Intl.message(
      'Not set',
      name: 'employee_value_none',
      desc: '',
      args: [],
    );
  }

  /// `Not filed`
  String get employee_value_not_filed {
    return Intl.message(
      'Not filed',
      name: 'employee_value_not_filed',
      desc: '',
      args: [],
    );
  }

  /// `No answer yet`
  String get employee_value_waiting {
    return Intl.message(
      'No answer yet',
      name: 'employee_value_waiting',
      desc: '',
      args: [],
    );
  }

  /// `Job`
  String get employee_job_title {
    return Intl.message(
      'Job',
      name: 'employee_job_title',
      desc: '',
      args: [],
    );
  }

  /// `Job title`
  String get employee_field_job_title {
    return Intl.message(
      'Job title',
      name: 'employee_field_job_title',
      desc: '',
      args: [],
    );
  }

  /// `Department`
  String get employee_field_department {
    return Intl.message(
      'Department',
      name: 'employee_field_department',
      desc: '',
      args: [],
    );
  }

  /// `Employee code`
  String get employee_field_code {
    return Intl.message(
      'Employee code',
      name: 'employee_field_code',
      desc: '',
      args: [],
    );
  }

  /// `Branch`
  String get employee_field_branch {
    return Intl.message(
      'Branch',
      name: 'employee_field_branch',
      desc: '',
      args: [],
    );
  }

  /// `Reports to`
  String get employee_field_manager {
    return Intl.message(
      'Reports to',
      name: 'employee_field_manager',
      desc: '',
      args: [],
    );
  }

  /// `Contract`
  String get employee_field_contract {
    return Intl.message(
      'Contract',
      name: 'employee_field_contract',
      desc: '',
      args: [],
    );
  }

  /// `Workday`
  String get employee_field_workday {
    return Intl.message(
      'Workday',
      name: 'employee_field_workday',
      desc: '',
      args: [],
    );
  }

  /// `Start date`
  String get employee_field_start {
    return Intl.message(
      'Start date',
      name: 'employee_field_start',
      desc: '',
      args: [],
    );
  }

  /// `Contract ends`
  String get employee_field_contract_end {
    return Intl.message(
      'Contract ends',
      name: 'employee_field_contract_end',
      desc: '',
      args: [],
    );
  }

  /// `Salary`
  String get employee_field_salary {
    return Intl.message(
      'Salary',
      name: 'employee_field_salary',
      desc: '',
      args: [],
    );
  }

  /// `Time here`
  String get employee_tenure_title {
    return Intl.message(
      'Time here',
      name: 'employee_tenure_title',
      desc: '',
      args: [],
    );
  }

  /// `In this job`
  String get employee_tenure_job {
    return Intl.message(
      'In this job',
      name: 'employee_tenure_job',
      desc: '',
      args: [],
    );
  }

  /// `In the company`
  String get employee_tenure_company {
    return Intl.message(
      'In the company',
      name: 'employee_tenure_company',
      desc: '',
      args: [],
    );
  }

  /// `In the company, since {date}`
  String employee_tenure_company_since(Object date) {
    return Intl.message(
      'In the company, since $date',
      name: 'employee_tenure_company_since',
      desc: '',
      args: [date],
    );
  }

  /// `Work contact`
  String get employee_work_contact_title {
    return Intl.message(
      'Work contact',
      name: 'employee_work_contact_title',
      desc: '',
      args: [],
    );
  }

  /// `Email`
  String get employee_field_email {
    return Intl.message(
      'Email',
      name: 'employee_field_email',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get employee_field_phone {
    return Intl.message(
      'Phone',
      name: 'employee_field_phone',
      desc: '',
      args: [],
    );
  }

  /// `Personal data`
  String get employee_person_title {
    return Intl.message(
      'Personal data',
      name: 'employee_person_title',
      desc: '',
      args: [],
    );
  }

  /// `A person's own profile is visible to the company only while they work here.`
  String get employee_person_hidden {
    return Intl.message(
      'A person\'s own profile is visible to the company only while they work here.',
      name: 'employee_person_hidden',
      desc: '',
      args: [],
    );
  }

  /// `Personal details are protected. Type your password on the server to see them.`
  String get employee_person_sealed {
    return Intl.message(
      'Personal details are protected. Type your password on the server to see them.',
      name: 'employee_person_sealed',
      desc: '',
      args: [],
    );
  }

  /// `These are the person's own details: what you change here changes in their account too.`
  String get employee_person_editable {
    return Intl.message(
      'These are the person\'s own details: what you change here changes in their account too.',
      name: 'employee_person_editable',
      desc: '',
      args: [],
    );
  }

  /// `The person's own profile: only they can change it.`
  String get employee_person_owned {
    return Intl.message(
      'The person\'s own profile: only they can change it.',
      name: 'employee_person_owned',
      desc: '',
      args: [],
    );
  }

  /// `Birthday`
  String get employee_field_birthday {
    return Intl.message(
      'Birthday',
      name: 'employee_field_birthday',
      desc: '',
      args: [],
    );
  }

  /// `Sex`
  String get employee_field_sex {
    return Intl.message(
      'Sex',
      name: 'employee_field_sex',
      desc: '',
      args: [],
    );
  }

  /// `Identity document`
  String get employee_field_document {
    return Intl.message(
      'Identity document',
      name: 'employee_field_document',
      desc: '',
      args: [],
    );
  }

  /// `Nationality`
  String get employee_field_nationality {
    return Intl.message(
      'Nationality',
      name: 'employee_field_nationality',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get employee_field_address {
    return Intl.message(
      'Address',
      name: 'employee_field_address',
      desc: '',
      args: [],
    );
  }

  /// `About`
  String get employee_field_about {
    return Intl.message(
      'About',
      name: 'employee_field_about',
      desc: '',
      args: [],
    );
  }

  /// `First name`
  String get employee_field_first_name {
    return Intl.message(
      'First name',
      name: 'employee_field_first_name',
      desc: '',
      args: [],
    );
  }

  /// `Last name`
  String get employee_field_last_name {
    return Intl.message(
      'Last name',
      name: 'employee_field_last_name',
      desc: '',
      args: [],
    );
  }

  /// `City`
  String get employee_field_city {
    return Intl.message(
      'City',
      name: 'employee_field_city',
      desc: '',
      args: [],
    );
  }

  /// `State or region`
  String get employee_field_region {
    return Intl.message(
      'State or region',
      name: 'employee_field_region',
      desc: '',
      args: [],
    );
  }

  /// `Postal code`
  String get employee_field_postal_code {
    return Intl.message(
      'Postal code',
      name: 'employee_field_postal_code',
      desc: '',
      args: [],
    );
  }

  /// `Country`
  String get employee_field_country {
    return Intl.message(
      'Country',
      name: 'employee_field_country',
      desc: '',
      args: [],
    );
  }

  /// `Document type`
  String get employee_field_document_type {
    return Intl.message(
      'Document type',
      name: 'employee_field_document_type',
      desc: '',
      args: [],
    );
  }

  /// `Document number`
  String get employee_field_document_number {
    return Intl.message(
      'Document number',
      name: 'employee_field_document_number',
      desc: '',
      args: [],
    );
  }

  /// `Relation`
  String get employee_field_emergency_relation {
    return Intl.message(
      'Relation',
      name: 'employee_field_emergency_relation',
      desc: '',
      args: [],
    );
  }

  /// `Paid per`
  String get employee_field_pay_period {
    return Intl.message(
      'Paid per',
      name: 'employee_field_pay_period',
      desc: '',
      args: [],
    );
  }

  /// `Salary currency`
  String get employee_field_currency {
    return Intl.message(
      'Salary currency',
      name: 'employee_field_currency',
      desc: '',
      args: [],
    );
  }

  /// `Click to edit {label}`
  String employee_edit_hint(Object label) {
    return Intl.message(
      'Click to edit $label',
      name: 'employee_edit_hint',
      desc: '',
      args: [label],
    );
  }

  /// `{label} can't be empty`
  String employee_edit_required(Object label) {
    return Intl.message(
      '$label can\'t be empty',
      name: 'employee_edit_required',
      desc: '',
      args: [label],
    );
  }

  /// `No matches`
  String get employee_edit_no_match {
    return Intl.message(
      'No matches',
      name: 'employee_edit_no_match',
      desc: '',
      args: [],
    );
  }

  /// `Add a new one`
  String get employee_edit_create {
    return Intl.message(
      'Add a new one',
      name: 'employee_edit_create',
      desc: '',
      args: [],
    );
  }

  /// `New {label}, then Enter`
  String employee_edit_create_hint(Object label) {
    return Intl.message(
      'New $label, then Enter',
      name: 'employee_edit_create_hint',
      desc: '',
      args: [label],
    );
  }

  /// `Save`
  String get employee_edit_confirm {
    return Intl.message(
      'Save',
      name: 'employee_edit_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Search a detail: phone, address, salary...`
  String get employee_search_hint {
    return Intl.message(
      'Search a detail: phone, address, salary...',
      name: 'employee_search_hint',
      desc: '',
      args: [],
    );
  }

  /// `Permissions`
  String get employee_action_permissions {
    return Intl.message(
      'Permissions',
      name: 'employee_action_permissions',
      desc: '',
      args: [],
    );
  }

  /// `What this person can see and do in the business.`
  String get employee_action_permissions_description {
    return Intl.message(
      'What this person can see and do in the business.',
      name: 'employee_action_permissions_description',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get employee_action_settings {
    return Intl.message(
      'Settings',
      name: 'employee_action_settings',
      desc: '',
      args: [],
    );
  }

  /// `How this person works here: schedule, notices and preferences.`
  String get employee_action_settings_description {
    return Intl.message(
      'How this person works here: schedule, notices and preferences.',
      name: 'employee_action_settings_description',
      desc: '',
      args: [],
    );
  }

  /// `Activity`
  String get employee_action_activity {
    return Intl.message(
      'Activity',
      name: 'employee_action_activity',
      desc: '',
      args: [],
    );
  }

  /// `What this person did lately, newest first.`
  String get employee_action_activity_description {
    return Intl.message(
      'What this person did lately, newest first.',
      name: 'employee_action_activity_description',
      desc: '',
      args: [],
    );
  }

  /// `Sales`
  String get employee_action_sales {
    return Intl.message(
      'Sales',
      name: 'employee_action_sales',
      desc: '',
      args: [],
    );
  }

  /// `The sales this person handled and how they went.`
  String get employee_action_sales_description {
    return Intl.message(
      'The sales this person handled and how they went.',
      name: 'employee_action_sales_description',
      desc: '',
      args: [],
    );
  }

  /// `Coming soon`
  String get employee_action_soon_title {
    return Intl.message(
      'Coming soon',
      name: 'employee_action_soon_title',
      desc: '',
      args: [],
    );
  }

  /// `Day`
  String get employee_edit_day {
    return Intl.message(
      'Day',
      name: 'employee_edit_day',
      desc: '',
      args: [],
    );
  }

  /// `Month`
  String get employee_edit_month {
    return Intl.message(
      'Month',
      name: 'employee_edit_month',
      desc: '',
      args: [],
    );
  }

  /// `Year`
  String get employee_edit_year {
    return Intl.message(
      'Year',
      name: 'employee_edit_year',
      desc: '',
      args: [],
    );
  }

  /// `That date doesn't exist: check the day, month and year`
  String get employee_edit_invalid_day {
    return Intl.message(
      'That date doesn\'t exist: check the day, month and year',
      name: 'employee_edit_invalid_day',
      desc: '',
      args: [],
    );
  }

  /// `Code`
  String get employee_edit_phone_code {
    return Intl.message(
      'Code',
      name: 'employee_edit_phone_code',
      desc: '',
      args: [],
    );
  }

  /// `Number`
  String get employee_edit_phone_number {
    return Intl.message(
      'Number',
      name: 'employee_edit_phone_number',
      desc: '',
      args: [],
    );
  }

  /// `Choose the country code first`
  String get employee_edit_phone_no_code {
    return Intl.message(
      'Choose the country code first',
      name: 'employee_edit_phone_no_code',
      desc: '',
      args: [],
    );
  }

  /// `Numbers from {dial} have {count} digits after the code`
  String employee_edit_phone_digits(Object dial, Object count) {
    return Intl.message(
      'Numbers from $dial have $count digits after the code',
      name: 'employee_edit_phone_digits',
      desc: '',
      args: [dial, count],
    );
  }

  /// `Numbers from {dial} have {min} to {max} digits after the code`
  String employee_edit_phone_digits_range(Object dial, Object min, Object max) {
    return Intl.message(
      'Numbers from $dial have $min to $max digits after the code',
      name: 'employee_edit_phone_digits_range',
      desc: '',
      args: [dial, min, max],
    );
  }

  /// `That isn't an email, like name@company.com`
  String get employee_edit_invalid_email {
    return Intl.message(
      'That isn\'t an email, like name@company.com',
      name: 'employee_edit_invalid_email',
      desc: '',
      args: [],
    );
  }

  /// `{label} takes only letters, spaces, hyphens and apostrophes`
  String employee_edit_invalid_name(Object label) {
    return Intl.message(
      '$label takes only letters, spaces, hyphens and apostrophes',
      name: 'employee_edit_invalid_name',
      desc: '',
      args: [label],
    );
  }

  /// `A birthday can't be today or later`
  String get employee_edit_birthday_future {
    return Intl.message(
      'A birthday can\'t be today or later',
      name: 'employee_edit_birthday_future',
      desc: '',
      args: [],
    );
  }

  /// `They must be at least {years} years old`
  String employee_edit_birthday_young(Object years) {
    return Intl.message(
      'They must be at least $years years old',
      name: 'employee_edit_birthday_young',
      desc: '',
      args: [years],
    );
  }

  /// `The contract can't end before it starts`
  String get employee_edit_end_before_start {
    return Intl.message(
      'The contract can\'t end before it starts',
      name: 'employee_edit_end_before_start',
      desc: '',
      args: [],
    );
  }

  /// `The job can't start after the contract ends`
  String get employee_edit_start_after_end {
    return Intl.message(
      'The job can\'t start after the contract ends',
      name: 'employee_edit_start_after_end',
      desc: '',
      args: [],
    );
  }

  /// `Search the address or type it`
  String get employee_edit_address_hint {
    return Intl.message(
      'Search the address or type it',
      name: 'employee_edit_address_hint',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't read that place. Type the address instead.`
  String get employee_edit_place_failed {
    return Intl.message(
      'Couldn\'t read that place. Type the address instead.',
      name: 'employee_edit_place_failed',
      desc: '',
      args: [],
    );
  }

  /// `Write an amount, like 1200.50`
  String get employee_edit_invalid_amount {
    return Intl.message(
      'Write an amount, like 1200.50',
      name: 'employee_edit_invalid_amount',
      desc: '',
      args: [],
    );
  }

  /// `Emergency contact`
  String get employee_emergency_title {
    return Intl.message(
      'Emergency contact',
      name: 'employee_emergency_title',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get employee_field_emergency_name {
    return Intl.message(
      'Name',
      name: 'employee_field_emergency_name',
      desc: '',
      args: [],
    );
  }

  /// `Upcoming absences`
  String get employee_upcoming_title {
    return Intl.message(
      'Upcoming absences',
      name: 'employee_upcoming_title',
      desc: '',
      args: [],
    );
  }

  /// `How it ended`
  String get employee_ending_title {
    return Intl.message(
      'How it ended',
      name: 'employee_ending_title',
      desc: '',
      args: [],
    );
  }

  /// `Last day`
  String get employee_field_ended {
    return Intl.message(
      'Last day',
      name: 'employee_field_ended',
      desc: '',
      args: [],
    );
  }

  /// `Reason`
  String get employee_field_end_reason {
    return Intl.message(
      'Reason',
      name: 'employee_field_end_reason',
      desc: '',
      args: [],
    );
  }

  /// `Note`
  String get employee_field_note {
    return Intl.message(
      'Note',
      name: 'employee_field_note',
      desc: '',
      args: [],
    );
  }

  /// `Record`
  String get employee_record_title {
    return Intl.message(
      'Record',
      name: 'employee_record_title',
      desc: '',
      args: [],
    );
  }

  /// `Filed`
  String get employee_field_invited {
    return Intl.message(
      'Filed',
      name: 'employee_field_invited',
      desc: '',
      args: [],
    );
  }

  /// `Answered`
  String get employee_field_responded {
    return Intl.message(
      'Answered',
      name: 'employee_field_responded',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get employee_notes_title {
    return Intl.message(
      'Notes',
      name: 'employee_notes_title',
      desc: '',
      args: [],
    );
  }

  /// `The business's own notes. The person does not see them.`
  String get employee_notes_subtitle {
    return Intl.message(
      'The business\'s own notes. The person does not see them.',
      name: 'employee_notes_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `You have no job filed here`
  String get employee_unfiled_title {
    return Intl.message(
      'You have no job filed here',
      name: 'employee_unfiled_title',
      desc: '',
      args: [],
    );
  }

  /// `Your card is listed so the team shows complete, but this business has no job on record for you yet.`
  String get employee_unfiled_subtitle {
    return Intl.message(
      'Your card is listed so the team shows complete, but this business has no job on record for you yet.',
      name: 'employee_unfiled_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load this person`
  String get employee_detail_error_title {
    return Intl.message(
      'Couldn\'t load this person',
      name: 'employee_detail_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get employee_detail_error_subtitle {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'employee_detail_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Click to copy`
  String get employee_copy {
    return Intl.message(
      'Click to copy',
      name: 'employee_copy',
      desc: '',
      args: [],
    );
  }

  /// `{label} copied`
  String employee_copied(Object label) {
    return Intl.message(
      '$label copied',
      name: 'employee_copied',
      desc: '',
      args: [label],
    );
  }

  /// `Branches`
  String get business_branches_title {
    return Intl.message(
      'Branches',
      name: 'business_branches_title',
      desc: '',
      args: [],
    );
  }

  /// `The places this business works from: stores, offices and warehouses.`
  String get business_branches_subtitle {
    return Intl.message(
      'The places this business works from: stores, offices and warehouses.',
      name: 'business_branches_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Add branch`
  String get business_branches_add {
    return Intl.message(
      'Add branch',
      name: 'business_branches_add',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load the branches`
  String get business_branches_error_title {
    return Intl.message(
      'Couldn\'t load the branches',
      name: 'business_branches_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get business_branches_error_subtitle {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'business_branches_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No branches yet`
  String get business_branches_empty_title {
    return Intl.message(
      'No branches yet',
      name: 'business_branches_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Add the places this business works from.`
  String get business_branches_empty_subtitle {
    return Intl.message(
      'Add the places this business works from.',
      name: 'business_branches_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Main`
  String get business_branch_main {
    return Intl.message(
      'Main',
      name: 'business_branch_main',
      desc: '',
      args: [],
    );
  }

  /// `Bot orders`
  String get business_branch_online {
    return Intl.message(
      'Bot orders',
      name: 'business_branch_online',
      desc: '',
      args: [],
    );
  }

  /// `No address yet`
  String get business_branch_no_address {
    return Intl.message(
      'No address yet',
      name: 'business_branch_no_address',
      desc: '',
      args: [],
    );
  }

  /// `New branch`
  String get business_branch_create_title {
    return Intl.message(
      'New branch',
      name: 'business_branch_create_title',
      desc: '',
      args: [],
    );
  }

  /// `Every branch is in the country of the business: its phone code and the address search come from it.`
  String get business_branch_create_subtitle {
    return Intl.message(
      'Every branch is in the country of the business: its phone code and the address search come from it.',
      name: 'business_branch_create_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get business_branch_name {
    return Intl.message(
      'Name',
      name: 'business_branch_name',
      desc: '',
      args: [],
    );
  }

  /// `Downtown store`
  String get business_branch_name_hint {
    return Intl.message(
      'Downtown store',
      name: 'business_branch_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Phone`
  String get business_branch_phone {
    return Intl.message(
      'Phone',
      name: 'business_branch_phone',
      desc: '',
      args: [],
    );
  }

  /// `4121234567`
  String get business_branch_phone_hint {
    return Intl.message(
      '4121234567',
      name: 'business_branch_phone_hint',
      desc: '',
      args: [],
    );
  }

  /// `Point on the map`
  String get business_branch_point {
    return Intl.message(
      'Point on the map',
      name: 'business_branch_point',
      desc: '',
      args: [],
    );
  }

  /// `Search the address over the map, or tap the map where the branch is. It's optional.`
  String get business_branch_point_help {
    return Intl.message(
      'Search the address over the map, or tap the map where the branch is. It\'s optional.',
      name: 'business_branch_point_help',
      desc: '',
      args: [],
    );
  }

  /// `Remove point`
  String get business_branch_point_clear {
    return Intl.message(
      'Remove point',
      name: 'business_branch_point_clear',
      desc: '',
      args: [],
    );
  }

  /// `Edit branch`
  String get business_branch_edit_title {
    return Intl.message(
      'Edit branch',
      name: 'business_branch_edit_title',
      desc: '',
      args: [],
    );
  }

  /// `Save changes`
  String get business_branch_save {
    return Intl.message(
      'Save changes',
      name: 'business_branch_save',
      desc: '',
      args: [],
    );
  }

  /// `Type`
  String get business_branch_kind {
    return Intl.message(
      'Type',
      name: 'business_branch_kind',
      desc: '',
      args: [],
    );
  }

  /// `Store`
  String get business_branch_kind_store {
    return Intl.message(
      'Store',
      name: 'business_branch_kind_store',
      desc: '',
      args: [],
    );
  }

  /// `Customers can come to it`
  String get business_branch_kind_store_note {
    return Intl.message(
      'Customers can come to it',
      name: 'business_branch_kind_store_note',
      desc: '',
      args: [],
    );
  }

  /// `Warehouse`
  String get business_branch_kind_warehouse {
    return Intl.message(
      'Warehouse',
      name: 'business_branch_kind_warehouse',
      desc: '',
      args: [],
    );
  }

  /// `Stock only, customers don't visit it`
  String get business_branch_kind_warehouse_note {
    return Intl.message(
      'Stock only, customers don\'t visit it',
      name: 'business_branch_kind_warehouse_note',
      desc: '',
      args: [],
    );
  }

  /// `Takes orders from the bot`
  String get business_branch_online_on {
    return Intl.message(
      'Takes orders from the bot',
      name: 'business_branch_online_on',
      desc: '',
      args: [],
    );
  }

  /// `Doesn't take orders from the bot`
  String get business_branch_online_off {
    return Intl.message(
      'Doesn\'t take orders from the bot',
      name: 'business_branch_online_off',
      desc: '',
      args: [],
    );
  }

  /// `Orders that arrive through your channels can be fulfilled from this branch`
  String get business_branch_online_note {
    return Intl.message(
      'Orders that arrive through your channels can be fulfilled from this branch',
      name: 'business_branch_online_note',
      desc: '',
      args: [],
    );
  }

  /// `Main branch`
  String get business_branch_main_toggle {
    return Intl.message(
      'Main branch',
      name: 'business_branch_main_toggle',
      desc: '',
      args: [],
    );
  }

  /// `The branch a customer is given when they don't ask for one. Only one branch is the main one.`
  String get business_branch_main_note {
    return Intl.message(
      'The branch a customer is given when they don\'t ask for one. Only one branch is the main one.',
      name: 'business_branch_main_note',
      desc: '',
      args: [],
    );
  }

  /// `Contact`
  String get business_branch_section_contact {
    return Intl.message(
      'Contact',
      name: 'business_branch_section_contact',
      desc: '',
      args: [],
    );
  }

  /// `+584121234567`
  String get business_branch_phone_full_hint {
    return Intl.message(
      '+584121234567',
      name: 'business_branch_phone_full_hint',
      desc: '',
      args: [],
    );
  }

  /// `Invoicing`
  String get business_branch_section_invoicing {
    return Intl.message(
      'Invoicing',
      name: 'business_branch_section_invoicing',
      desc: '',
      args: [],
    );
  }

  /// `Leave them empty if this branch invoices as the business itself.`
  String get business_branch_invoicing_note {
    return Intl.message(
      'Leave them empty if this branch invoices as the business itself.',
      name: 'business_branch_invoicing_note',
      desc: '',
      args: [],
    );
  }

  /// `Legal name`
  String get business_branch_legal_name {
    return Intl.message(
      'Legal name',
      name: 'business_branch_legal_name',
      desc: '',
      args: [],
    );
  }

  /// `Inversiones Sol C.A.`
  String get business_branch_legal_name_hint {
    return Intl.message(
      'Inversiones Sol C.A.',
      name: 'business_branch_legal_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Tax ID`
  String get business_branch_tax_id {
    return Intl.message(
      'Tax ID',
      name: 'business_branch_tax_id',
      desc: '',
      args: [],
    );
  }

  /// `J-12345678-9`
  String get business_branch_tax_id_hint {
    return Intl.message(
      'J-12345678-9',
      name: 'business_branch_tax_id_hint',
      desc: '',
      args: [],
    );
  }

  /// `Address`
  String get business_branch_section_address {
    return Intl.message(
      'Address',
      name: 'business_branch_section_address',
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

  /// `This table is still being imported. It opens once its columns and rows are in`
  String get import_table_busy {
    return Intl.message(
      'This table is still being imported. It opens once its columns and rows are in',
      name: 'import_table_busy',
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

  /// `Choose where this table's products come from`
  String get import_source_subtitle {
    return Intl.message(
      'Choose where this table\'s products come from',
      name: 'import_source_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Search a source`
  String get import_source_search {
    return Intl.message(
      'Search a source',
      name: 'import_source_search',
      desc: '',
      args: [],
    );
  }

  /// `No source matches your search`
  String get import_source_search_empty {
    return Intl.message(
      'No source matches your search',
      name: 'import_source_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `From this device`
  String get import_source_device {
    return Intl.message(
      'From this device',
      name: 'import_source_device',
      desc: '',
      args: [],
    );
  }

  /// `Apps and stores`
  String get import_source_apps {
    return Intl.message(
      'Apps and stores',
      name: 'import_source_apps',
      desc: '',
      args: [],
    );
  }

  /// `Other formats`
  String get import_source_formats {
    return Intl.message(
      'Other formats',
      name: 'import_source_formats',
      desc: '',
      args: [],
    );
  }

  /// `Soon`
  String get import_source_soon {
    return Intl.message(
      'Soon',
      name: 'import_source_soon',
      desc: '',
      args: [],
    );
  }

  /// `Upload spreadsheet`
  String get import_source_spreadsheet {
    return Intl.message(
      'Upload spreadsheet',
      name: 'import_source_spreadsheet',
      desc: '',
      args: [],
    );
  }

  /// `An Excel, CSV or ODS file from this device`
  String get import_source_spreadsheet_hint {
    return Intl.message(
      'An Excel, CSV or ODS file from this device',
      name: 'import_source_spreadsheet_hint',
      desc: '',
      args: [],
    );
  }

  /// `Google Sheets`
  String get import_source_google_sheets {
    return Intl.message(
      'Google Sheets',
      name: 'import_source_google_sheets',
      desc: '',
      args: [],
    );
  }

  /// `A sheet from your Google Drive`
  String get import_source_google_sheets_hint {
    return Intl.message(
      'A sheet from your Google Drive',
      name: 'import_source_google_sheets_hint',
      desc: '',
      args: [],
    );
  }

  /// `JSON`
  String get import_source_json {
    return Intl.message(
      'JSON',
      name: 'import_source_json',
      desc: '',
      args: [],
    );
  }

  /// `A products file exported as JSON`
  String get import_source_json_hint {
    return Intl.message(
      'A products file exported as JSON',
      name: 'import_source_json_hint',
      desc: '',
      args: [],
    );
  }

  /// `XML`
  String get import_source_xml {
    return Intl.message(
      'XML',
      name: 'import_source_xml',
      desc: '',
      args: [],
    );
  }

  /// `A products feed in XML`
  String get import_source_xml_hint {
    return Intl.message(
      'A products feed in XML',
      name: 'import_source_xml_hint',
      desc: '',
      args: [],
    );
  }

  /// `OpenDocument`
  String get import_source_ods {
    return Intl.message(
      'OpenDocument',
      name: 'import_source_ods',
      desc: '',
      args: [],
    );
  }

  /// `A sheet from LibreOffice or OpenOffice`
  String get import_source_ods_hint {
    return Intl.message(
      'A sheet from LibreOffice or OpenOffice',
      name: 'import_source_ods_hint',
      desc: '',
      args: [],
    );
  }

  /// `Airtable`
  String get import_source_airtable {
    return Intl.message(
      'Airtable',
      name: 'import_source_airtable',
      desc: '',
      args: [],
    );
  }

  /// `A table from one of your bases`
  String get import_source_airtable_hint {
    return Intl.message(
      'A table from one of your bases',
      name: 'import_source_airtable_hint',
      desc: '',
      args: [],
    );
  }

  /// `Notion`
  String get import_source_notion {
    return Intl.message(
      'Notion',
      name: 'import_source_notion',
      desc: '',
      args: [],
    );
  }

  /// `A database from your workspace`
  String get import_source_notion_hint {
    return Intl.message(
      'A database from your workspace',
      name: 'import_source_notion_hint',
      desc: '',
      args: [],
    );
  }

  /// `Smartsheet`
  String get import_source_smartsheet {
    return Intl.message(
      'Smartsheet',
      name: 'import_source_smartsheet',
      desc: '',
      args: [],
    );
  }

  /// `A sheet from your workspace`
  String get import_source_smartsheet_hint {
    return Intl.message(
      'A sheet from your workspace',
      name: 'import_source_smartsheet_hint',
      desc: '',
      args: [],
    );
  }

  /// `Trello`
  String get import_source_trello {
    return Intl.message(
      'Trello',
      name: 'import_source_trello',
      desc: '',
      args: [],
    );
  }

  /// `The cards of one of your boards`
  String get import_source_trello_hint {
    return Intl.message(
      'The cards of one of your boards',
      name: 'import_source_trello_hint',
      desc: '',
      args: [],
    );
  }

  /// `Shopify`
  String get import_source_shopify {
    return Intl.message(
      'Shopify',
      name: 'import_source_shopify',
      desc: '',
      args: [],
    );
  }

  /// `The catalog of your store`
  String get import_source_shopify_hint {
    return Intl.message(
      'The catalog of your store',
      name: 'import_source_shopify_hint',
      desc: '',
      args: [],
    );
  }

  /// `WooCommerce`
  String get import_source_woocommerce {
    return Intl.message(
      'WooCommerce',
      name: 'import_source_woocommerce',
      desc: '',
      args: [],
    );
  }

  /// `The catalog of your store`
  String get import_source_woocommerce_hint {
    return Intl.message(
      'The catalog of your store',
      name: 'import_source_woocommerce_hint',
      desc: '',
      args: [],
    );
  }

  /// `Magento`
  String get import_source_magento {
    return Intl.message(
      'Magento',
      name: 'import_source_magento',
      desc: '',
      args: [],
    );
  }

  /// `The catalog of your store`
  String get import_source_magento_hint {
    return Intl.message(
      'The catalog of your store',
      name: 'import_source_magento_hint',
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

  /// `Primary`
  String get table_primary {
    return Intl.message(
      'Primary',
      name: 'table_primary',
      desc: '',
      args: [],
    );
  }

  /// `Your main table. The stock summary always reads this one, so it's the table whose columns show up below.`
  String get table_primary_hint {
    return Intl.message(
      'Your main table. The stock summary always reads this one, so it\'s the table whose columns show up below.',
      name: 'table_primary_hint',
      desc: '',
      args: [],
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
    return Intl.message(
      'Title',
      name: 'table_title_input',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Color',
      name: 'table_color_title',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Add field',
      name: 'add_field',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Field added',
      name: 'field_added',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Text',
      name: 'field_type_text',
      desc: '',
      args: [],
    );
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

  /// `Multiline text customers don't search by`
  String get field_type_textarea_hint {
    return Intl.message(
      'Multiline text customers don\'t search by',
      name: 'field_type_textarea_hint',
      desc: '',
      args: [],
    );
  }

  /// `Product name`
  String get field_type_title {
    return Intl.message(
      'Product name',
      name: 'field_type_title',
      desc: '',
      args: [],
    );
  }

  /// `What the product is called. The AI searches by it and names the product with it`
  String get field_type_title_hint {
    return Intl.message(
      'What the product is called. The AI searches by it and names the product with it',
      name: 'field_type_title_hint',
      desc: '',
      args: [],
    );
  }

  /// `Description`
  String get field_type_description {
    return Intl.message(
      'Description',
      name: 'field_type_description',
      desc: '',
      args: [],
    );
  }

  /// `What the product is, in words. The AI reads it and searches by meaning`
  String get field_type_description_hint {
    return Intl.message(
      'What the product is, in words. The AI reads it and searches by meaning',
      name: 'field_type_description_hint',
      desc: '',
      args: [],
    );
  }

  /// `SKU`
  String get field_type_sku {
    return Intl.message(
      'SKU',
      name: 'field_type_sku',
      desc: '',
      args: [],
    );
  }

  /// `Your own reference or part number`
  String get field_type_sku_hint {
    return Intl.message(
      'Your own reference or part number',
      name: 'field_type_sku_hint',
      desc: '',
      args: [],
    );
  }

  /// `Barcode`
  String get field_type_barcode {
    return Intl.message(
      'Barcode',
      name: 'field_type_barcode',
      desc: '',
      args: [],
    );
  }

  /// `The code printed on the product: EAN, UPC, ISBN`
  String get field_type_barcode_hint {
    return Intl.message(
      'The code printed on the product: EAN, UPC, ISBN',
      name: 'field_type_barcode_hint',
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

  /// `Numbers with decimals`
  String get field_type_decimal_hint {
    return Intl.message(
      'Numbers with decimals',
      name: 'field_type_decimal_hint',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get field_type_price {
    return Intl.message(
      'Price',
      name: 'field_type_price',
      desc: '',
      args: [],
    );
  }

  /// `The selling price: what a customer pays`
  String get field_type_price_hint {
    return Intl.message(
      'The selling price: what a customer pays',
      name: 'field_type_price_hint',
      desc: '',
      args: [],
    );
  }

  /// `Other amount`
  String get field_type_currency {
    return Intl.message(
      'Other amount',
      name: 'field_type_currency',
      desc: '',
      args: [],
    );
  }

  /// `Money that is not the selling price: cost, wholesale, margin`
  String get field_type_currency_hint {
    return Intl.message(
      'Money that is not the selling price: cost, wholesale, margin',
      name: 'field_type_currency_hint',
      desc: '',
      args: [],
    );
  }

  /// `Discount`
  String get field_type_discount {
    return Intl.message(
      'Discount',
      name: 'field_type_discount',
      desc: '',
      args: [],
    );
  }

  /// `The percent taken off the price at checkout, from 0 to 100`
  String get field_type_discount_hint {
    return Intl.message(
      'The percent taken off the price at checkout, from 0 to 100',
      name: 'field_type_discount_hint',
      desc: '',
      args: [],
    );
  }

  /// `Percentage`
  String get field_type_percentage {
    return Intl.message(
      'Percentage',
      name: 'field_type_percentage',
      desc: '',
      args: [],
    );
  }

  /// `A rate written as 16, not as 0.16: tax, margin, commission`
  String get field_type_percentage_hint {
    return Intl.message(
      'A rate written as 16, not as 0.16: tax, margin, commission',
      name: 'field_type_percentage_hint',
      desc: '',
      args: [],
    );
  }

  /// `Measure`
  String get field_type_measure {
    return Intl.message(
      'Measure',
      name: 'field_type_measure',
      desc: '',
      args: [],
    );
  }

  /// `A magnitude with a unit: weight, volume, length`
  String get field_type_measure_hint {
    return Intl.message(
      'A magnitude with a unit: weight, volume, length',
      name: 'field_type_measure_hint',
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
    return Intl.message(
      'Date',
      name: 'field_type_date',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Email',
      name: 'field_type_email',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Phone',
      name: 'field_type_phone',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Link',
      name: 'field_type_url',
      desc: '',
      args: [],
    );
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
  String get field_type_options {
    return Intl.message(
      'Options list',
      name: 'field_type_options',
      desc: '',
      args: [],
    );
  }

  /// `A closed list of labels, one per product: size, colour, condition`
  String get field_type_options_hint {
    return Intl.message(
      'A closed list of labels, one per product: size, colour, condition',
      name: 'field_type_options_hint',
      desc: '',
      args: [],
    );
  }

  /// `Categories`
  String get field_type_categories {
    return Intl.message(
      'Categories',
      name: 'field_type_categories',
      desc: '',
      args: [],
    );
  }

  /// `A closed list of labels, several per product`
  String get field_type_categories_hint {
    return Intl.message(
      'A closed list of labels, several per product',
      name: 'field_type_categories_hint',
      desc: '',
      args: [],
    );
  }

  /// `Image`
  String get field_type_image {
    return Intl.message(
      'Image',
      name: 'field_type_image',
      desc: '',
      args: [],
    );
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

  /// `Stock`
  String get field_type_stock {
    return Intl.message(
      'Stock',
      name: 'field_type_stock',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Reports',
      name: 'section_reports',
      desc: '',
      args: [],
    );
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
    return Intl.message(
      'Soon',
      name: 'channel_type_soon',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp Personal`
  String get channel_type_whatsapp_personal {
    return Intl.message(
      'WhatsApp Personal',
      name: 'channel_type_whatsapp_personal',
      desc: '',
      args: [],
    );
  }

  /// `A personal number, without a Meta business account`
  String get channel_type_whatsapp_personal_hint {
    return Intl.message(
      'A personal number, without a Meta business account',
      name: 'channel_type_whatsapp_personal_hint',
      desc: '',
      args: [],
    );
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

  /// `Link your number`
  String get channel_whatsapp_personal_notice_title {
    return Intl.message(
      'Link your number',
      name: 'channel_whatsapp_personal_notice_title',
      desc: '',
      args: [],
    );
  }

  /// `There are no tokens to paste. Once this channel is created, turn it on from the channels list to scan a QR code and link your WhatsApp`
  String get channel_whatsapp_personal_notice_subtitle {
    return Intl.message(
      'There are no tokens to paste. Once this channel is created, turn it on from the channels list to scan a QR code and link your WhatsApp',
      name: 'channel_whatsapp_personal_notice_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Off`
  String get baileys_status_stopped {
    return Intl.message(
      'Off',
      name: 'baileys_status_stopped',
      desc: '',
      args: [],
    );
  }

  /// `Starting…`
  String get baileys_status_starting {
    return Intl.message(
      'Starting…',
      name: 'baileys_status_starting',
      desc: '',
      args: [],
    );
  }

  /// `Scan the QR to link`
  String get baileys_status_qr_pending {
    return Intl.message(
      'Scan the QR to link',
      name: 'baileys_status_qr_pending',
      desc: '',
      args: [],
    );
  }

  /// `Connected`
  String get baileys_status_connected {
    return Intl.message(
      'Connected',
      name: 'baileys_status_connected',
      desc: '',
      args: [],
    );
  }

  /// `Reconnecting…`
  String get baileys_status_reconnecting {
    return Intl.message(
      'Reconnecting…',
      name: 'baileys_status_reconnecting',
      desc: '',
      args: [],
    );
  }

  /// `Unlinked — scan a new QR`
  String get baileys_status_logged_out {
    return Intl.message(
      'Unlinked — scan a new QR',
      name: 'baileys_status_logged_out',
      desc: '',
      args: [],
    );
  }

  /// `Connection error`
  String get baileys_status_error {
    return Intl.message(
      'Connection error',
      name: 'baileys_status_error',
      desc: '',
      args: [],
    );
  }

  /// `Off`
  String get baileys_status_unknown {
    return Intl.message(
      'Off',
      name: 'baileys_status_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't start the WhatsApp service`
  String get baileys_start_error {
    return Intl.message(
      'Couldn\'t start the WhatsApp service',
      name: 'baileys_start_error',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't stop the WhatsApp service`
  String get baileys_stop_error {
    return Intl.message(
      'Couldn\'t stop the WhatsApp service',
      name: 'baileys_stop_error',
      desc: '',
      args: [],
    );
  }

  /// `Link WhatsApp`
  String get baileys_pairing_title {
    return Intl.message(
      'Link WhatsApp',
      name: 'baileys_pairing_title',
      desc: '',
      args: [],
    );
  }

  /// `Open WhatsApp on your phone, go to Linked Devices and scan this code`
  String get baileys_pairing_instructions {
    return Intl.message(
      'Open WhatsApp on your phone, go to Linked Devices and scan this code',
      name: 'baileys_pairing_instructions',
      desc: '',
      args: [],
    );
  }

  /// `Preparing the QR code…`
  String get baileys_pairing_waiting {
    return Intl.message(
      'Preparing the QR code…',
      name: 'baileys_pairing_waiting',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp linked`
  String get baileys_pairing_connected {
    return Intl.message(
      'WhatsApp linked',
      name: 'baileys_pairing_connected',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't link WhatsApp: {error}`
  String baileys_pairing_error(Object error) {
    return Intl.message(
      'Couldn\'t link WhatsApp: $error',
      name: 'baileys_pairing_error',
      desc: '',
      args: [error],
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

  /// `No data source`
  String get channel_source_none {
    return Intl.message(
      'No data source',
      name: 'channel_source_none',
      desc: '',
      args: [],
    );
  }

  /// `Payment methods`
  String get channel_payments_title {
    return Intl.message(
      'Payment methods',
      name: 'channel_payments_title',
      desc: '',
      args: [],
    );
  }

  /// `Which of your accounts the agent may give a customer to pay into. It offers these and no others`
  String get channel_payments_subtitle {
    return Intl.message(
      'Which of your accounts the agent may give a customer to pay into. It offers these and no others',
      name: 'channel_payments_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `This business has no payment accounts yet. Add one in Finance and come back`
  String get channel_payments_empty {
    return Intl.message(
      'This business has no payment accounts yet. Add one in Finance and come back',
      name: 'channel_payments_empty',
      desc: '',
      args: [],
    );
  }

  /// `We couldn't load your payment accounts`
  String get channel_payments_error {
    return Intl.message(
      'We couldn\'t load your payment accounts',
      name: 'channel_payments_error',
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

  /// `Account`
  String get channel_account_title {
    return Intl.message(
      'Account',
      name: 'channel_account_title',
      desc: '',
      args: [],
    );
  }

  /// `On the network`
  String get channel_account_id {
    return Intl.message(
      'On the network',
      name: 'channel_account_id',
      desc: '',
      args: [],
    );
  }

  /// `Channel id`
  String get channel_own_id {
    return Intl.message(
      'Channel id',
      name: 'channel_own_id',
      desc: '',
      args: [],
    );
  }

  /// `You have unsaved changes on this channel`
  String get channel_changes_pending {
    return Intl.message(
      'You have unsaved changes on this channel',
      name: 'channel_changes_pending',
      desc: '',
      args: [],
    );
  }

  /// `Undoing this channel`
  String get channel_danger_section {
    return Intl.message(
      'Undoing this channel',
      name: 'channel_danger_section',
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

  /// `Disconnecting deletes the credentials stored for this channel and takes it off the list. The account can be connected again, but you'll have to set it up from scratch.`
  String get channel_delete_explanation {
    return Intl.message(
      'Disconnecting deletes the credentials stored for this channel and takes it off the list. The account can be connected again, but you\'ll have to set it up from scratch.',
      name: 'channel_delete_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Unlink WhatsApp`
  String get baileys_unlink_action {
    return Intl.message(
      'Unlink WhatsApp',
      name: 'baileys_unlink_action',
      desc: '',
      args: [],
    );
  }

  /// `Unlinking drops this computer's link to your phone. The channel stays exactly as it is — its role, its data and its place here — and turning it back on asks for a new QR code.`
  String get baileys_unlink_explanation {
    return Intl.message(
      'Unlinking drops this computer\'s link to your phone. The channel stays exactly as it is — its role, its data and its place here — and turning it back on asks for a new QR code.',
      name: 'baileys_unlink_explanation',
      desc: '',
      args: [],
    );
  }

  /// `Unlink this WhatsApp?`
  String get baileys_unlink_title {
    return Intl.message(
      'Unlink this WhatsApp?',
      name: 'baileys_unlink_title',
      desc: '',
      args: [],
    );
  }

  /// `This channel stops answering on WhatsApp until you scan a new QR code. Nothing you set up on it is lost.`
  String get baileys_unlink_message {
    return Intl.message(
      'This channel stops answering on WhatsApp until you scan a new QR code. Nothing you set up on it is lost.',
      name: 'baileys_unlink_message',
      desc: '',
      args: [],
    );
  }

  /// `WhatsApp unlinked`
  String get baileys_unlinked {
    return Intl.message(
      'WhatsApp unlinked',
      name: 'baileys_unlinked',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't unlink WhatsApp`
  String get baileys_unlink_error {
    return Intl.message(
      'Couldn\'t unlink WhatsApp',
      name: 'baileys_unlink_error',
      desc: '',
      args: [],
    );
  }

  /// `Connections`
  String get connections {
    return Intl.message(
      'Connections',
      name: 'connections',
      desc: '',
      args: [],
    );
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
      one:
          'The bot answering through it is deleted too — pause the account instead to keep it.',
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
    return Intl.message(
      'Inbox',
      name: 'inbox',
      desc: '',
      args: [],
    );
  }

  /// `Coming soon`
  String get coming_soon {
    return Intl.message(
      'Coming soon',
      name: 'coming_soon',
      desc: '',
      args: [],
    );
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

  /// `Normalize columns`
  String get table_normalize {
    return Intl.message(
      'Normalize columns',
      name: 'table_normalize',
      desc: '',
      args: [],
    );
  }

  /// `Normalize this table?`
  String get table_normalize_title {
    return Intl.message(
      'Normalize this table?',
      name: 'table_normalize_title',
      desc: '',
      args: [],
    );
  }

  /// `We read a sample of every column and give it the type it should have — a price that compares as a number, a date that sorts, a description the AI can search by meaning — and set how much of each one a bot may see. Columns you already typed or marked yourself are left alone.`
  String get table_normalize_message {
    return Intl.message(
      'We read a sample of every column and give it the type it should have — a price that compares as a number, a date that sorts, a description the AI can search by meaning — and set how much of each one a bot may see. Columns you already typed or marked yourself are left alone.',
      name: 'table_normalize_message',
      desc: '',
      args: [],
    );
  }

  /// `Normalize`
  String get table_normalize_confirm {
    return Intl.message(
      'Normalize',
      name: 'table_normalize_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Normalizing this table`
  String get table_normalize_running {
    return Intl.message(
      'Normalizing this table',
      name: 'table_normalize_running',
      desc: '',
      args: [],
    );
  }

  /// `Every column was already right`
  String get table_normalize_none {
    return Intl.message(
      'Every column was already right',
      name: 'table_normalize_none',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{1 column retyped} other{{count} columns retyped}}`
  String table_normalize_retyped(num count) {
    return Intl.plural(
      count,
      one: '1 column retyped',
      other: '$count columns retyped',
      name: 'table_normalize_retyped',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{visibility set on 1 column} other{visibility set on {count} columns}}`
  String table_normalize_narrowed(num count) {
    return Intl.plural(
      count,
      one: 'visibility set on 1 column',
      other: 'visibility set on $count columns',
      name: 'table_normalize_narrowed',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 column renamed} other{{count} columns renamed}}`
  String table_normalize_renamed(num count) {
    return Intl.plural(
      count,
      one: '1 column renamed',
      other: '$count columns renamed',
      name: 'table_normalize_renamed',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 column added to the summary} other{{count} columns added to the summary}}`
  String table_normalize_summarized(num count) {
    return Intl.plural(
      count,
      one: '1 column added to the summary',
      other: '$count columns added to the summary',
      name: 'table_normalize_summarized',
      desc: '',
      args: [count],
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

  /// `What each one holds, how much of it the AI sees and which ones the inventory summary shows. All of it is changed right here`
  String get table_settings_columns_subtitle {
    return Intl.message(
      'What each one holds, how much of it the AI sees and which ones the inventory summary shows. All of it is changed right here',
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

  /// `Unit`
  String get table_settings_column_unit {
    return Intl.message(
      'Unit',
      name: 'table_settings_column_unit',
      desc: '',
      args: [],
    );
  }

  /// `Inventory summary`
  String get table_settings_column_summary {
    return Intl.message(
      'Inventory summary',
      name: 'table_settings_column_summary',
      desc: '',
      args: [],
    );
  }

  /// `Shown`
  String get table_settings_column_summary_on {
    return Intl.message(
      'Shown',
      name: 'table_settings_column_summary_on',
      desc: '',
      args: [],
    );
  }

  /// `Excluded`
  String get table_settings_column_summary_off {
    return Intl.message(
      'Excluded',
      name: 'table_settings_column_summary_off',
      desc: '',
      args: [],
    );
  }

  /// `Show this column in the inventory summary`
  String get table_settings_column_summary_show {
    return Intl.message(
      'Show this column in the inventory summary',
      name: 'table_settings_column_summary_show',
      desc: '',
      args: [],
    );
  }

  /// `Leave this column out of the inventory summary`
  String get table_settings_column_summary_hide {
    return Intl.message(
      'Leave this column out of the inventory summary',
      name: 'table_settings_column_summary_hide',
      desc: '',
      args: [],
    );
  }

  /// `Inventory summary: {count} of {total} columns`
  String table_settings_columns_summary_count(Object count, Object total) {
    return Intl.message(
      'Inventory summary: $count of $total columns',
      name: 'table_settings_columns_summary_count',
      desc: '',
      args: [count, total],
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

  /// `The symbol this column's numbers are written in`
  String get table_settings_pick_unit {
    return Intl.message(
      'The symbol this column\'s numbers are written in',
      name: 'table_settings_pick_unit',
      desc: '',
      args: [],
    );
  }

  /// `No unit`
  String get table_settings_unit_empty {
    return Intl.message(
      'No unit',
      name: 'table_settings_unit_empty',
      desc: '',
      args: [],
    );
  }

  /// `Without unit`
  String get table_settings_unit_none {
    return Intl.message(
      'Without unit',
      name: 'table_settings_unit_none',
      desc: '',
      args: [],
    );
  }

  /// `Set unit`
  String get table_settings_unit_create {
    return Intl.message(
      'Set unit',
      name: 'table_settings_unit_create',
      desc: '',
      args: [],
    );
  }

  /// `USD, Bs., kg`
  String get table_settings_unit_placeholder {
    return Intl.message(
      'USD, Bs., kg',
      name: 'table_settings_unit_placeholder',
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

  /// `POS`
  String get pos {
    return Intl.message(
      'POS',
      name: 'pos',
      desc: '',
      args: [],
    );
  }

  /// `Close POS`
  String get pos_close {
    return Intl.message(
      'Close POS',
      name: 'pos_close',
      desc: '',
      args: [],
    );
  }

  /// `POS mode`
  String get pos_mode {
    return Intl.message(
      'POS mode',
      name: 'pos_mode',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{No sales today} =1{1 sale today} other{{count} sales today}}`
  String pos_sales_today(num count) {
    return Intl.plural(
      count,
      zero: 'No sales today',
      one: '1 sale today',
      other: '$count sales today',
      name: 'pos_sales_today',
      desc: '',
      args: [count],
    );
  }

  /// `All`
  String get pos_category_all {
    return Intl.message(
      'All',
      name: 'pos_category_all',
      desc: '',
      args: [],
    );
  }

  /// `Search products`
  String get pos_search_product {
    return Intl.message(
      'Search products',
      name: 'pos_search_product',
      desc: '',
      args: [],
    );
  }

  /// `The catalog could not be loaded`
  String get pos_catalog_error_title {
    return Intl.message(
      'The catalog could not be loaded',
      name: 'pos_catalog_error_title',
      desc: '',
      args: [],
    );
  }

  /// `The products did not arrive. Try again.`
  String get pos_catalog_error_subtitle {
    return Intl.message(
      'The products did not arrive. Try again.',
      name: 'pos_catalog_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get pos_catalog_retry {
    return Intl.message(
      'Try again',
      name: 'pos_catalog_retry',
      desc: '',
      args: [],
    );
  }

  /// `There are no products yet`
  String get pos_catalog_empty_title {
    return Intl.message(
      'There are no products yet',
      name: 'pos_catalog_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Import a price list from the inventory section and it will be sold from here`
  String get pos_catalog_empty_subtitle {
    return Intl.message(
      'Import a price list from the inventory section and it will be sold from here',
      name: 'pos_catalog_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No product matches`
  String get pos_catalog_search_empty {
    return Intl.message(
      'No product matches',
      name: 'pos_catalog_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `There is no catalog to sell from`
  String get pos_catalog_missing_title {
    return Intl.message(
      'There is no catalog to sell from',
      name: 'pos_catalog_missing_title',
      desc: '',
      args: [],
    );
  }

  /// `This business has no products table yet, so there is nothing to ring up`
  String get pos_catalog_missing_subtitle {
    return Intl.message(
      'This business has no products table yet, so there is nothing to ring up',
      name: 'pos_catalog_missing_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Unnamed product`
  String get pos_product_unnamed {
    return Intl.message(
      'Unnamed product',
      name: 'pos_product_unnamed',
      desc: '',
      args: [],
    );
  }

  /// `No price`
  String get pos_product_no_price {
    return Intl.message(
      'No price',
      name: 'pos_product_no_price',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{Out of stock} =1{1 left} other{{count} left}}`
  String pos_product_stock(num count) {
    return Intl.plural(
      count,
      zero: 'Out of stock',
      one: '1 left',
      other: '$count left',
      name: 'pos_product_stock',
      desc: '',
      args: [count],
    );
  }

  /// `That product has no price, so it cannot be rung up`
  String get pos_product_no_price_flag {
    return Intl.message(
      'That product has no price, so it cannot be rung up',
      name: 'pos_product_no_price_flag',
      desc: '',
      args: [],
    );
  }

  /// `Ticket #{number}`
  String pos_ticket_number(Object number) {
    return Intl.message(
      'Ticket #$number',
      name: 'pos_ticket_number',
      desc: '',
      args: [number],
    );
  }

  /// `{count, plural, =0{Nothing on it yet} =1{1 product} other{{count} products}}`
  String pos_ticket_units(num count) {
    return Intl.plural(
      count,
      zero: 'Nothing on it yet',
      one: '1 product',
      other: '$count products',
      name: 'pos_ticket_units',
      desc: '',
      args: [count],
    );
  }

  /// `The ticket is empty`
  String get pos_ticket_empty_title {
    return Intl.message(
      'The ticket is empty',
      name: 'pos_ticket_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Pick a product from the catalog and it lands here`
  String get pos_ticket_empty_subtitle {
    return Intl.message(
      'Pick a product from the catalog and it lands here',
      name: 'pos_ticket_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `{price} each`
  String pos_ticket_each(Object price) {
    return Intl.message(
      '$price each',
      name: 'pos_ticket_each',
      desc: '',
      args: [price],
    );
  }

  /// `One less`
  String get pos_ticket_less {
    return Intl.message(
      'One less',
      name: 'pos_ticket_less',
      desc: '',
      args: [],
    );
  }

  /// `One more`
  String get pos_ticket_more {
    return Intl.message(
      'One more',
      name: 'pos_ticket_more',
      desc: '',
      args: [],
    );
  }

  /// `Take it off the ticket`
  String get pos_ticket_remove {
    return Intl.message(
      'Take it off the ticket',
      name: 'pos_ticket_remove',
      desc: '',
      args: [],
    );
  }

  /// `Charge an amount`
  String get pos_ticket_add_amount {
    return Intl.message(
      'Charge an amount',
      name: 'pos_ticket_add_amount',
      desc: '',
      args: [],
    );
  }

  /// `VAT {rate}%`
  String pos_ticket_tax(Object rate) {
    return Intl.message(
      'VAT $rate%',
      name: 'pos_ticket_tax',
      desc: '',
      args: [rate],
    );
  }

  /// `Change the rate charged on this ticket`
  String get pos_ticket_tax_edit {
    return Intl.message(
      'Change the rate charged on this ticket',
      name: 'pos_ticket_tax_edit',
      desc: '',
      args: [],
    );
  }

  /// `Subtotal`
  String get pos_ticket_subtotal {
    return Intl.message(
      'Subtotal',
      name: 'pos_ticket_subtotal',
      desc: '',
      args: [],
    );
  }

  /// `Total`
  String get pos_ticket_total {
    return Intl.message(
      'Total',
      name: 'pos_ticket_total',
      desc: '',
      args: [],
    );
  }

  /// `Delete ticket`
  String get pos_ticket_clear {
    return Intl.message(
      'Delete ticket',
      name: 'pos_ticket_clear',
      desc: '',
      args: [],
    );
  }

  /// `Delete this ticket?`
  String get pos_ticket_clear_title {
    return Intl.message(
      'Delete this ticket?',
      name: 'pos_ticket_clear_title',
      desc: '',
      args: [],
    );
  }

  /// `Everything on it comes off, the units it was holding go back on sale and nothing is charged.`
  String get pos_ticket_clear_message {
    return Intl.message(
      'Everything on it comes off, the units it was holding go back on sale and nothing is charged.',
      name: 'pos_ticket_clear_message',
      desc: '',
      args: [],
    );
  }

  /// `Delete it`
  String get pos_ticket_clear_confirm {
    return Intl.message(
      'Delete it',
      name: 'pos_ticket_clear_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Ticket deleted`
  String get pos_ticket_cleared {
    return Intl.message(
      'Ticket deleted',
      name: 'pos_ticket_cleared',
      desc: '',
      args: [],
    );
  }

  /// `No longer set aside`
  String get pos_ticket_unheld {
    return Intl.message(
      'No longer set aside',
      name: 'pos_ticket_unheld',
      desc: '',
      args: [],
    );
  }

  /// `The units of {product} were released from the stock screen and are no longer set aside for this ticket`
  String pos_ticket_released(Object product) {
    return Intl.message(
      'The units of $product were released from the stock screen and are no longer set aside for this ticket',
      name: 'pos_ticket_released',
      desc: '',
      args: [product],
    );
  }

  /// `This ticket was just charged from another register`
  String get pos_ticket_taken {
    return Intl.message(
      'This ticket was just charged from another register',
      name: 'pos_ticket_taken',
      desc: '',
      args: [],
    );
  }

  /// `This ticket was just cancelled from another screen`
  String get pos_ticket_dropped {
    return Intl.message(
      'This ticket was just cancelled from another screen',
      name: 'pos_ticket_dropped',
      desc: '',
      args: [],
    );
  }

  /// `Complete purchase`
  String get pos_ticket_checkout {
    return Intl.message(
      'Complete purchase',
      name: 'pos_ticket_checkout',
      desc: '',
      args: [],
    );
  }

  /// `Charge the ticket`
  String get pos_checkout_title {
    return Intl.message(
      'Charge the ticket',
      name: 'pos_checkout_title',
      desc: '',
      args: [],
    );
  }

  /// `To charge`
  String get pos_checkout_total {
    return Intl.message(
      'To charge',
      name: 'pos_checkout_total',
      desc: '',
      args: [],
    );
  }

  /// `Payment method`
  String get pos_checkout_method {
    return Intl.message(
      'Payment method',
      name: 'pos_checkout_method',
      desc: '',
      args: [],
    );
  }

  /// `How it is being paid`
  String get pos_checkout_method_placeholder {
    return Intl.message(
      'How it is being paid',
      name: 'pos_checkout_method_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `No payment method`
  String get pos_checkout_method_empty {
    return Intl.message(
      'No payment method',
      name: 'pos_checkout_method_empty',
      desc: '',
      args: [],
    );
  }

  /// `Reference`
  String get pos_checkout_reference {
    return Intl.message(
      'Reference',
      name: 'pos_checkout_reference',
      desc: '',
      args: [],
    );
  }

  /// `Confirmation or authorization number`
  String get pos_checkout_reference_placeholder {
    return Intl.message(
      'Confirmation or authorization number',
      name: 'pos_checkout_reference_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Write the payment's reference so it can be reconciled`
  String get pos_checkout_reference_error {
    return Intl.message(
      'Write the payment\'s reference so it can be reconciled',
      name: 'pos_checkout_reference_error',
      desc: '',
      args: [],
    );
  }

  /// `Charge`
  String get pos_checkout_confirm {
    return Intl.message(
      'Charge',
      name: 'pos_checkout_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Ticket {ticket} charged`
  String pos_checkout_done(Object ticket) {
    return Intl.message(
      'Ticket $ticket charged',
      name: 'pos_checkout_done',
      desc: '',
      args: [ticket],
    );
  }

  /// `The payment methods have not been loaded, so nothing can be charged yet`
  String get pos_checkout_methods_error {
    return Intl.message(
      'The payment methods have not been loaded, so nothing can be charged yet',
      name: 'pos_checkout_methods_error',
      desc: '',
      args: [],
    );
  }

  /// `Charge an amount`
  String get pos_amount_title {
    return Intl.message(
      'Charge an amount',
      name: 'pos_amount_title',
      desc: '',
      args: [],
    );
  }

  /// `For something the catalog does not have: a delivery, a repair, a fee.`
  String get pos_amount_subtitle {
    return Intl.message(
      'For something the catalog does not have: a delivery, a repair, a fee.',
      name: 'pos_amount_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Concept`
  String get pos_amount_concept {
    return Intl.message(
      'Concept',
      name: 'pos_amount_concept',
      desc: '',
      args: [],
    );
  }

  /// `What is being charged`
  String get pos_amount_concept_placeholder {
    return Intl.message(
      'What is being charged',
      name: 'pos_amount_concept_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get pos_amount_price {
    return Intl.message(
      'Price',
      name: 'pos_amount_price',
      desc: '',
      args: [],
    );
  }

  /// `0`
  String get pos_amount_price_placeholder {
    return Intl.message(
      '0',
      name: 'pos_amount_price_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Write the price as a number, zero or more`
  String get pos_amount_price_error {
    return Intl.message(
      'Write the price as a number, zero or more',
      name: 'pos_amount_price_error',
      desc: '',
      args: [],
    );
  }

  /// `Add to ticket`
  String get pos_amount_add {
    return Intl.message(
      'Add to ticket',
      name: 'pos_amount_add',
      desc: '',
      args: [],
    );
  }

  /// `VAT rate`
  String get pos_tax_title {
    return Intl.message(
      'VAT rate',
      name: 'pos_tax_title',
      desc: '',
      args: [],
    );
  }

  /// `The percentage charged on this ticket. Written as 16, not as 0.16.`
  String get pos_tax_subtitle {
    return Intl.message(
      'The percentage charged on this ticket. Written as 16, not as 0.16.',
      name: 'pos_tax_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Percentage`
  String get pos_tax_input {
    return Intl.message(
      'Percentage',
      name: 'pos_tax_input',
      desc: '',
      args: [],
    );
  }

  /// `0`
  String get pos_tax_placeholder {
    return Intl.message(
      '0',
      name: 'pos_tax_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `A rate between 0 and 100`
  String get pos_tax_error {
    return Intl.message(
      'A rate between 0 and 100',
      name: 'pos_tax_error',
      desc: '',
      args: [],
    );
  }

  /// `Stock summary`
  String get stock_summary_title {
    return Intl.message(
      'Stock summary',
      name: 'stock_summary_title',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{No products} =1{1 product} other{{count} products}}`
  String stock_summary_count(num count) {
    return Intl.plural(
      count,
      zero: 'No products',
      one: '1 product',
      other: '$count products',
      name: 'stock_summary_count',
      desc: '',
      args: [count],
    );
  }

  /// `Stock`
  String get stock_summary_stock {
    return Intl.message(
      'Stock',
      name: 'stock_summary_stock',
      desc: '',
      args: [],
    );
  }

  /// `Reserved`
  String get stock_summary_reserved {
    return Intl.message(
      'Reserved',
      name: 'stock_summary_reserved',
      desc: '',
      args: [],
    );
  }

  /// `Performance`
  String get stock_summary_performance {
    return Intl.message(
      'Performance',
      name: 'stock_summary_performance',
      desc: '',
      args: [],
    );
  }

  /// `Nothing to count yet`
  String get stock_summary_empty_title {
    return Intl.message(
      'Nothing to count yet',
      name: 'stock_summary_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `The products of your main table show up here, with what's left of each one.`
  String get stock_summary_empty_subtitle {
    return Intl.message(
      'The products of your main table show up here, with what\'s left of each one.',
      name: 'stock_summary_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No products match your search`
  String get stock_summary_search_empty {
    return Intl.message(
      'No products match your search',
      name: 'stock_summary_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load your stock`
  String get stock_summary_error_title {
    return Intl.message(
      'Couldn\'t load your stock',
      name: 'stock_summary_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get stock_summary_error_subtitle {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'stock_summary_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get stock_summary_retry {
    return Intl.message(
      'Try again',
      name: 'stock_summary_retry',
      desc: '',
      args: [],
    );
  }

  /// `Take out of stock`
  String get stock_move_take_stock {
    return Intl.message(
      'Take out of stock',
      name: 'stock_move_take_stock',
      desc: '',
      args: [],
    );
  }

  /// `Add to stock`
  String get stock_move_add_stock {
    return Intl.message(
      'Add to stock',
      name: 'stock_move_add_stock',
      desc: '',
      args: [],
    );
  }

  /// `Release reservations`
  String get stock_move_take_reserved {
    return Intl.message(
      'Release reservations',
      name: 'stock_move_take_reserved',
      desc: '',
      args: [],
    );
  }

  /// `Reserve units`
  String get stock_move_add_reserved {
    return Intl.message(
      'Reserve units',
      name: 'stock_move_add_reserved',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =0{Nothing available right now} =1{1 unit available} other{{count} units available}}`
  String stock_move_available(num count) {
    return Intl.plural(
      count,
      zero: 'Nothing available right now',
      one: '1 unit available',
      other: '$count units available',
      name: 'stock_move_available',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =0{Nothing reserved right now} =1{1 unit reserved} other{{count} units reserved}}`
  String stock_move_reserved(num count) {
    return Intl.plural(
      count,
      zero: 'Nothing reserved right now',
      one: '1 unit reserved',
      other: '$count units reserved',
      name: 'stock_move_reserved',
      desc: '',
      args: [count],
    );
  }

  /// `Quantity`
  String get stock_move_quantity {
    return Intl.message(
      'Quantity',
      name: 'stock_move_quantity',
      desc: '',
      args: [],
    );
  }

  /// `How many units`
  String get stock_move_quantity_placeholder {
    return Intl.message(
      'How many units',
      name: 'stock_move_quantity_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Enter a whole number between 1 and {max}`
  String stock_move_quantity_error(Object max) {
    return Intl.message(
      'Enter a whole number between 1 and $max',
      name: 'stock_move_quantity_error',
      desc: '',
      args: [max],
    );
  }

  /// `Enter a whole number greater than zero`
  String get stock_move_quantity_error_free {
    return Intl.message(
      'Enter a whole number greater than zero',
      name: 'stock_move_quantity_error_free',
      desc: '',
      args: [],
    );
  }

  /// `What happens with them`
  String get stock_move_destination {
    return Intl.message(
      'What happens with them',
      name: 'stock_move_destination',
      desc: '',
      args: [],
    );
  }

  /// `Reason`
  String get stock_move_reason {
    return Intl.message(
      'Reason',
      name: 'stock_move_reason',
      desc: '',
      args: [],
    );
  }

  /// `Pick one`
  String get stock_move_reason_placeholder {
    return Intl.message(
      'Pick one',
      name: 'stock_move_reason_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `No reasons`
  String get stock_move_reason_empty {
    return Intl.message(
      'No reasons',
      name: 'stock_move_reason_empty',
      desc: '',
      args: [],
    );
  }

  /// `Note`
  String get stock_move_note {
    return Intl.message(
      'Note',
      name: 'stock_move_note',
      desc: '',
      args: [],
    );
  }

  /// `Explain the movement for whoever audits it later`
  String get stock_move_note_placeholder {
    return Intl.message(
      'Explain the movement for whoever audits it later',
      name: 'stock_move_note_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Take out`
  String get stock_move_take_action {
    return Intl.message(
      'Take out',
      name: 'stock_move_take_action',
      desc: '',
      args: [],
    );
  }

  /// `Add`
  String get stock_move_add_action {
    return Intl.message(
      'Add',
      name: 'stock_move_add_action',
      desc: '',
      args: [],
    );
  }

  /// `Stock updated`
  String get stock_move_saved {
    return Intl.message(
      'Stock updated',
      name: 'stock_move_saved',
      desc: '',
      args: [],
    );
  }

  /// `Take units out`
  String get stock_move_take_hint {
    return Intl.message(
      'Take units out',
      name: 'stock_move_take_hint',
      desc: '',
      args: [],
    );
  }

  /// `Add units`
  String get stock_move_add_hint {
    return Intl.message(
      'Add units',
      name: 'stock_move_add_hint',
      desc: '',
      args: [],
    );
  }

  /// `{count, plural, =1{One less} other{{count} less}}`
  String stock_move_step_less(num count) {
    return Intl.plural(
      count,
      one: 'One less',
      other: '$count less',
      name: 'stock_move_step_less',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{One more} other{{count} more}}`
  String stock_move_step_more(num count) {
    return Intl.plural(
      count,
      one: 'One more',
      other: '$count more',
      name: 'stock_move_step_more',
      desc: '',
      args: [count],
    );
  }

  /// `They leave`
  String get stock_move_dest_leave {
    return Intl.message(
      'They leave',
      name: 'stock_move_dest_leave',
      desc: '',
      args: [],
    );
  }

  /// `Sold, damaged, lost or miscounted: they are not coming back.`
  String get stock_move_dest_leave_hint {
    return Intl.message(
      'Sold, damaged, lost or miscounted: they are not coming back.',
      name: 'stock_move_dest_leave_hint',
      desc: '',
      args: [],
    );
  }

  /// `To reservations`
  String get stock_move_dest_reserve {
    return Intl.message(
      'To reservations',
      name: 'stock_move_dest_reserve',
      desc: '',
      args: [],
    );
  }

  /// `Held for someone. They stop being available to sell.`
  String get stock_move_dest_reserve_hint {
    return Intl.message(
      'Held for someone. They stop being available to sell.',
      name: 'stock_move_dest_reserve_hint',
      desc: '',
      args: [],
    );
  }

  /// `To returns`
  String get stock_move_dest_returns {
    return Intl.message(
      'To returns',
      name: 'stock_move_dest_returns',
      desc: '',
      args: [],
    );
  }

  /// `Units a customer brought back. They wait there until somebody checks them.`
  String get stock_move_dest_returns_hint {
    return Intl.message(
      'Units a customer brought back. They wait there until somebody checks them.',
      name: 'stock_move_dest_returns_hint',
      desc: '',
      args: [],
    );
  }

  /// `They go back on sale.`
  String get stock_move_release_hint {
    return Intl.message(
      'They go back on sale.',
      name: 'stock_move_release_hint',
      desc: '',
      args: [],
    );
  }

  /// `Restock`
  String get stock_reason_restock {
    return Intl.message(
      'Restock',
      name: 'stock_reason_restock',
      desc: '',
      args: [],
    );
  }

  /// `Approved return`
  String get stock_reason_return_approved {
    return Intl.message(
      'Approved return',
      name: 'stock_reason_return_approved',
      desc: '',
      args: [],
    );
  }

  /// `Count correction`
  String get stock_reason_correction {
    return Intl.message(
      'Count correction',
      name: 'stock_reason_correction',
      desc: '',
      args: [],
    );
  }

  /// `Sale`
  String get stock_reason_sale {
    return Intl.message(
      'Sale',
      name: 'stock_reason_sale',
      desc: '',
      args: [],
    );
  }

  /// `Damaged`
  String get stock_reason_damage {
    return Intl.message(
      'Damaged',
      name: 'stock_reason_damage',
      desc: '',
      args: [],
    );
  }

  /// `Lost`
  String get stock_reason_loss {
    return Intl.message(
      'Lost',
      name: 'stock_reason_loss',
      desc: '',
      args: [],
    );
  }

  /// `Expired`
  String get stock_reason_expiration {
    return Intl.message(
      'Expired',
      name: 'stock_reason_expiration',
      desc: '',
      args: [],
    );
  }

  /// `Theft`
  String get stock_reason_theft {
    return Intl.message(
      'Theft',
      name: 'stock_reason_theft',
      desc: '',
      args: [],
    );
  }

  /// `Customer return`
  String get stock_reason_customer {
    return Intl.message(
      'Customer return',
      name: 'stock_reason_customer',
      desc: '',
      args: [],
    );
  }

  /// `Defective`
  String get stock_reason_defective {
    return Intl.message(
      'Defective',
      name: 'stock_reason_defective',
      desc: '',
      args: [],
    );
  }

  /// `Wrong item`
  String get stock_reason_wrong_item {
    return Intl.message(
      'Wrong item',
      name: 'stock_reason_wrong_item',
      desc: '',
      args: [],
    );
  }

  /// `Warranty`
  String get stock_reason_warranty {
    return Intl.message(
      'Warranty',
      name: 'stock_reason_warranty',
      desc: '',
      args: [],
    );
  }

  /// `Back on sale`
  String get stock_reason_reintegration {
    return Intl.message(
      'Back on sale',
      name: 'stock_reason_reintegration',
      desc: '',
      args: [],
    );
  }

  /// `The hold ran out`
  String get stock_reason_hold_expired {
    return Intl.message(
      'The hold ran out',
      name: 'stock_reason_hold_expired',
      desc: '',
      args: [],
    );
  }

  /// `Customer cancelled`
  String get stock_reason_cancelled {
    return Intl.message(
      'Customer cancelled',
      name: 'stock_reason_cancelled',
      desc: '',
      args: [],
    );
  }

  /// `Overview`
  String get finance_tab_overview {
    return Intl.message(
      'Overview',
      name: 'finance_tab_overview',
      desc: '',
      args: [],
    );
  }

  /// `Payments`
  String get finance_tab_payments {
    return Intl.message(
      'Payments',
      name: 'finance_tab_payments',
      desc: '',
      args: [],
    );
  }

  /// `Receivables`
  String get finance_tab_receivables {
    return Intl.message(
      'Receivables',
      name: 'finance_tab_receivables',
      desc: '',
      args: [],
    );
  }

  /// `Payment methods`
  String get finance_tab_methods {
    return Intl.message(
      'Payment methods',
      name: 'finance_tab_methods',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get finance_retry {
    return Intl.message(
      'Try again',
      name: 'finance_retry',
      desc: '',
      args: [],
    );
  }

  /// `No option matches your search`
  String get finance_select_empty {
    return Intl.message(
      'No option matches your search',
      name: 'finance_select_empty',
      desc: '',
      args: [],
    );
  }

  /// `Load {count} more`
  String finance_more(Object count) {
    return Intl.message(
      'Load $count more',
      name: 'finance_more',
      desc: '',
      args: [count],
    );
  }

  /// `Today`
  String get finance_range_today {
    return Intl.message(
      'Today',
      name: 'finance_range_today',
      desc: '',
      args: [],
    );
  }

  /// `Last 7 days`
  String get finance_range_week {
    return Intl.message(
      'Last 7 days',
      name: 'finance_range_week',
      desc: '',
      args: [],
    );
  }

  /// `Last 30 days`
  String get finance_range_month {
    return Intl.message(
      'Last 30 days',
      name: 'finance_range_month',
      desc: '',
      args: [],
    );
  }

  /// `Last 12 months`
  String get finance_range_year {
    return Intl.message(
      'Last 12 months',
      name: 'finance_range_year',
      desc: '',
      args: [],
    );
  }

  /// `From {from} to {to}`
  String finance_window(Object from, Object to) {
    return Intl.message(
      'From $from to $to',
      name: 'finance_window',
      desc: '',
      args: [from, to],
    );
  }

  /// `Received`
  String get finance_income {
    return Intl.message(
      'Received',
      name: 'finance_income',
      desc: '',
      args: [],
    );
  }

  /// `Sales`
  String get finance_income_sales {
    return Intl.message(
      'Sales',
      name: 'finance_income_sales',
      desc: '',
      args: [],
    );
  }

  /// `Other income`
  String get finance_income_payments {
    return Intl.message(
      'Other income',
      name: 'finance_income_payments',
      desc: '',
      args: [],
    );
  }

  /// `Paid`
  String get finance_expenses {
    return Intl.message(
      'Paid',
      name: 'finance_expenses',
      desc: '',
      args: [],
    );
  }

  /// `Net`
  String get finance_net {
    return Intl.message(
      'Net',
      name: 'finance_net',
      desc: '',
      args: [],
    );
  }

  /// `Received minus paid`
  String get finance_net_hint {
    return Intl.message(
      'Received minus paid',
      name: 'finance_net_hint',
      desc: '',
      args: [],
    );
  }

  /// `Sold on credit`
  String get finance_credit {
    return Intl.message(
      'Sold on credit',
      name: 'finance_credit',
      desc: '',
      args: [],
    );
  }

  /// `Not collected yet, so it is not income`
  String get finance_credit_hint {
    return Intl.message(
      'Not collected yet, so it is not income',
      name: 'finance_credit_hint',
      desc: '',
      args: [],
    );
  }

  /// `{count} movements`
  String finance_movements(Object count) {
    return Intl.message(
      '$count movements',
      name: 'finance_movements',
      desc: '',
      args: [count],
    );
  }

  /// `By method`
  String get finance_by_method {
    return Intl.message(
      'By method',
      name: 'finance_by_method',
      desc: '',
      args: [],
    );
  }

  /// `By concept`
  String get finance_by_concept {
    return Intl.message(
      'By concept',
      name: 'finance_by_concept',
      desc: '',
      args: [],
    );
  }

  /// `Nothing moved in this period`
  String get finance_breakdown_empty {
    return Intl.message(
      'Nothing moved in this period',
      name: 'finance_breakdown_empty',
      desc: '',
      args: [],
    );
  }

  /// `The figures could not be loaded`
  String get finance_summary_error_title {
    return Intl.message(
      'The figures could not be loaded',
      name: 'finance_summary_error_title',
      desc: '',
      args: [],
    );
  }

  /// `The money of this period could not be read. Try again in a moment.`
  String get finance_summary_error_subtitle {
    return Intl.message(
      'The money of this period could not be read. Try again in a moment.',
      name: 'finance_summary_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No money moved`
  String get finance_summary_empty_title {
    return Intl.message(
      'No money moved',
      name: 'finance_summary_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Nothing came in and nothing went out in this period.`
  String get finance_summary_empty_subtitle {
    return Intl.message(
      'Nothing came in and nothing went out in this period.',
      name: 'finance_summary_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Lyra spend`
  String get finance_bot_title {
    return Intl.message(
      'Lyra spend',
      name: 'finance_bot_title',
      desc: '',
      args: [],
    );
  }

  /// `What Lyra, the bot that answers your customers, cost to run — billed in {currency}. It is measured and not recorded, so it is not part of the money above.`
  String finance_bot_hint(Object currency) {
    return Intl.message(
      'What Lyra, the bot that answers your customers, cost to run — billed in $currency. It is measured and not recorded, so it is not part of the money above.',
      name: 'finance_bot_hint',
      desc: '',
      args: [currency],
    );
  }

  /// `Answering messages`
  String get finance_bot_answers {
    return Intl.message(
      'Answering messages',
      name: 'finance_bot_answers',
      desc: '',
      args: [],
    );
  }

  /// `Replies`
  String get finance_bot_text {
    return Intl.message(
      'Replies',
      name: 'finance_bot_text',
      desc: '',
      args: [],
    );
  }

  /// `Images and audio`
  String get finance_bot_media {
    return Intl.message(
      'Images and audio',
      name: 'finance_bot_media',
      desc: '',
      args: [],
    );
  }

  /// `Web lookups`
  String get finance_bot_research {
    return Intl.message(
      'Web lookups',
      name: 'finance_bot_research',
      desc: '',
      args: [],
    );
  }

  /// `Reading your tables`
  String get finance_bot_tables {
    return Intl.message(
      'Reading your tables',
      name: 'finance_bot_tables',
      desc: '',
      args: [],
    );
  }

  /// `{count} runs`
  String finance_bot_tables_hint(Object count) {
    return Intl.message(
      '$count runs',
      name: 'finance_bot_tables_hint',
      desc: '',
      args: [count],
    );
  }

  /// `Search index`
  String get finance_bot_vectors {
    return Intl.message(
      'Search index',
      name: 'finance_bot_vectors',
      desc: '',
      args: [],
    );
  }

  /// `Catalog`
  String get finance_bot_catalog {
    return Intl.message(
      'Catalog',
      name: 'finance_bot_catalog',
      desc: '',
      args: [],
    );
  }

  /// `Searches`
  String get finance_bot_queries {
    return Intl.message(
      'Searches',
      name: 'finance_bot_queries',
      desc: '',
      args: [],
    );
  }

  /// `Unattributed`
  String get finance_bot_other {
    return Intl.message(
      'Unattributed',
      name: 'finance_bot_other',
      desc: '',
      args: [],
    );
  }

  /// `Spend of no known area`
  String get finance_bot_other_hint {
    return Intl.message(
      'Spend of no known area',
      name: 'finance_bot_other_hint',
      desc: '',
      args: [],
    );
  }

  /// `{conversations} conversations · {messages} replies`
  String finance_bot_activity(Object conversations, Object messages) {
    return Intl.message(
      '$conversations conversations · $messages replies',
      name: 'finance_bot_activity',
      desc: '',
      args: [conversations, messages],
    );
  }

  /// `What Lyra cost could not be read`
  String get finance_bot_error_title {
    return Intl.message(
      'What Lyra cost could not be read',
      name: 'finance_bot_error_title',
      desc: '',
      args: [],
    );
  }

  /// `The figures behind the bot could not be measured, which is not the same as it having cost nothing. Try again in a moment.`
  String get finance_bot_error_subtitle {
    return Intl.message(
      'The figures behind the bot could not be measured, which is not the same as it having cost nothing. Try again in a moment.',
      name: 'finance_bot_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Lyra cost nothing in this period`
  String get finance_bot_empty {
    return Intl.message(
      'Lyra cost nothing in this period',
      name: 'finance_bot_empty',
      desc: '',
      args: [],
    );
  }

  /// `Record payment`
  String get finance_payments_record {
    return Intl.message(
      'Record payment',
      name: 'finance_payments_record',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get finance_payments_all {
    return Intl.message(
      'All',
      name: 'finance_payments_all',
      desc: '',
      args: [],
    );
  }

  /// `Received`
  String get finance_payments_in {
    return Intl.message(
      'Received',
      name: 'finance_payments_in',
      desc: '',
      args: [],
    );
  }

  /// `Paid`
  String get finance_payments_out {
    return Intl.message(
      'Paid',
      name: 'finance_payments_out',
      desc: '',
      args: [],
    );
  }

  /// `Any`
  String get finance_payments_any {
    return Intl.message(
      'Any',
      name: 'finance_payments_any',
      desc: '',
      args: [],
    );
  }

  /// `Recorded and voided`
  String get finance_payments_any_state {
    return Intl.message(
      'Recorded and voided',
      name: 'finance_payments_any_state',
      desc: '',
      args: [],
    );
  }

  /// `Recorded`
  String get finance_payments_recorded {
    return Intl.message(
      'Recorded',
      name: 'finance_payments_recorded',
      desc: '',
      args: [],
    );
  }

  /// `Voided`
  String get finance_payments_voided {
    return Intl.message(
      'Voided',
      name: 'finance_payments_voided',
      desc: '',
      args: [],
    );
  }

  /// `Clear filters`
  String get finance_payments_clear {
    return Intl.message(
      'Clear filters',
      name: 'finance_payments_clear',
      desc: '',
      args: [],
    );
  }

  /// `The history could not be loaded`
  String get finance_payments_error_title {
    return Intl.message(
      'The history could not be loaded',
      name: 'finance_payments_error_title',
      desc: '',
      args: [],
    );
  }

  /// `The movements of this company could not be read. Try again in a moment.`
  String get finance_payments_error_subtitle {
    return Intl.message(
      'The movements of this company could not be read. Try again in a moment.',
      name: 'finance_payments_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No payments recorded yet`
  String get finance_payments_empty_title {
    return Intl.message(
      'No payments recorded yet',
      name: 'finance_payments_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Money paid to a supplier or collected outside the counter is recorded here.`
  String get finance_payments_empty_subtitle {
    return Intl.message(
      'Money paid to a supplier or collected outside the counter is recorded here.',
      name: 'finance_payments_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No movement matches`
  String get finance_payments_none_title {
    return Intl.message(
      'No movement matches',
      name: 'finance_payments_none_title',
      desc: '',
      args: [],
    );
  }

  /// `Nothing was received or paid under these filters.`
  String get finance_payments_none_subtitle {
    return Intl.message(
      'Nothing was received or paid under these filters.',
      name: 'finance_payments_none_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Date`
  String get finance_payment_date {
    return Intl.message(
      'Date',
      name: 'finance_payment_date',
      desc: '',
      args: [],
    );
  }

  /// `Concept`
  String get finance_payment_concept {
    return Intl.message(
      'Concept',
      name: 'finance_payment_concept',
      desc: '',
      args: [],
    );
  }

  /// `Counterpart`
  String get finance_payment_counterpart {
    return Intl.message(
      'Counterpart',
      name: 'finance_payment_counterpart',
      desc: '',
      args: [],
    );
  }

  /// `Method`
  String get finance_payment_method {
    return Intl.message(
      'Method',
      name: 'finance_payment_method',
      desc: '',
      args: [],
    );
  }

  /// `Reference`
  String get finance_payment_reference {
    return Intl.message(
      'Reference',
      name: 'finance_payment_reference',
      desc: '',
      args: [],
    );
  }

  /// `Amount`
  String get finance_payment_amount {
    return Intl.message(
      'Amount',
      name: 'finance_payment_amount',
      desc: '',
      args: [],
    );
  }

  /// `Ticket`
  String get finance_payment_ticket {
    return Intl.message(
      'Ticket',
      name: 'finance_payment_ticket',
      desc: '',
      args: [],
    );
  }

  /// `Note`
  String get finance_payment_note {
    return Intl.message(
      'Note',
      name: 'finance_payment_note',
      desc: '',
      args: [],
    );
  }

  /// `Void`
  String get finance_payment_void {
    return Intl.message(
      'Void',
      name: 'finance_payment_void',
      desc: '',
      args: [],
    );
  }

  /// `Void this payment?`
  String get finance_payment_void_title {
    return Intl.message(
      'Void this payment?',
      name: 'finance_payment_void_title',
      desc: '',
      args: [],
    );
  }

  /// `The payment of {amount} stops counting, but stays in the history. It cannot be undone: a mistake is voided and recorded again.`
  String finance_payment_void_message(Object amount) {
    return Intl.message(
      'The payment of $amount stops counting, but stays in the history. It cannot be undone: a mistake is voided and recorded again.',
      name: 'finance_payment_void_message',
      desc: '',
      args: [amount],
    );
  }

  /// `Record a payment`
  String get finance_record_title {
    return Intl.message(
      'Record a payment',
      name: 'finance_record_title',
      desc: '',
      args: [],
    );
  }

  /// `Money the company received or paid outside the counter. A sale's own payment is already on its ticket.`
  String get finance_record_subtitle {
    return Intl.message(
      'Money the company received or paid outside the counter. A sale\'s own payment is already on its ticket.',
      name: 'finance_record_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Record`
  String get finance_record_save {
    return Intl.message(
      'Record',
      name: 'finance_record_save',
      desc: '',
      args: [],
    );
  }

  /// `Write how much money moved`
  String get finance_record_amount_error {
    return Intl.message(
      'Write how much money moved',
      name: 'finance_record_amount_error',
      desc: '',
      args: [],
    );
  }

  /// `What was it for?`
  String get finance_record_concept_placeholder {
    return Intl.message(
      'What was it for?',
      name: 'finance_record_concept_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Ticket code`
  String get finance_record_ticket_placeholder {
    return Intl.message(
      'Ticket code',
      name: 'finance_record_ticket_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get finance_record_account {
    return Intl.message(
      'Account',
      name: 'finance_record_account',
      desc: '',
      args: [],
    );
  }

  /// `Where did the money land?`
  String get finance_record_account_placeholder {
    return Intl.message(
      'Where did the money land?',
      name: 'finance_record_account_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `No account`
  String get finance_record_no_account {
    return Intl.message(
      'No account',
      name: 'finance_record_no_account',
      desc: '',
      args: [],
    );
  }

  /// `How did it move?`
  String get finance_record_method_placeholder {
    return Intl.message(
      'How did it move?',
      name: 'finance_record_method_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Confirmation number`
  String get finance_record_reference_placeholder {
    return Intl.message(
      'Confirmation number',
      name: 'finance_record_reference_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Who paid, or who was paid`
  String get finance_record_counterpart_placeholder {
    return Intl.message(
      'Who paid, or who was paid',
      name: 'finance_record_counterpart_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `What should be remembered about it`
  String get finance_record_note_placeholder {
    return Intl.message(
      'What should be remembered about it',
      name: 'finance_record_note_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `The debts could not be loaded`
  String get finance_receivables_error_title {
    return Intl.message(
      'The debts could not be loaded',
      name: 'finance_receivables_error_title',
      desc: '',
      args: [],
    );
  }

  /// `The credit sales of this company could not be read. Try again in a moment.`
  String get finance_receivables_error_subtitle {
    return Intl.message(
      'The credit sales of this company could not be read. Try again in a moment.',
      name: 'finance_receivables_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Nobody owes anything`
  String get finance_receivables_empty_title {
    return Intl.message(
      'Nobody owes anything',
      name: 'finance_receivables_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Every credit sale has been collected.`
  String get finance_receivables_empty_subtitle {
    return Intl.message(
      'Every credit sale has been collected.',
      name: 'finance_receivables_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Only unpaid`
  String get finance_receivables_open_only {
    return Intl.message(
      'Only unpaid',
      name: 'finance_receivables_open_only',
      desc: '',
      args: [],
    );
  }

  /// `Sold on credit`
  String get finance_receivables_sold {
    return Intl.message(
      'Sold on credit',
      name: 'finance_receivables_sold',
      desc: '',
      args: [],
    );
  }

  /// `Collected`
  String get finance_receivables_collected {
    return Intl.message(
      'Collected',
      name: 'finance_receivables_collected',
      desc: '',
      args: [],
    );
  }

  /// `Outstanding`
  String get finance_receivables_outstanding {
    return Intl.message(
      'Outstanding',
      name: 'finance_receivables_outstanding',
      desc: '',
      args: [],
    );
  }

  /// `Ticket`
  String get finance_receivable_ticket {
    return Intl.message(
      'Ticket',
      name: 'finance_receivable_ticket',
      desc: '',
      args: [],
    );
  }

  /// `Customer`
  String get finance_receivable_customer {
    return Intl.message(
      'Customer',
      name: 'finance_receivable_customer',
      desc: '',
      args: [],
    );
  }

  /// `Sold on`
  String get finance_receivable_date {
    return Intl.message(
      'Sold on',
      name: 'finance_receivable_date',
      desc: '',
      args: [],
    );
  }

  /// `Total`
  String get finance_receivable_total {
    return Intl.message(
      'Total',
      name: 'finance_receivable_total',
      desc: '',
      args: [],
    );
  }

  /// `Collected`
  String get finance_receivable_collected {
    return Intl.message(
      'Collected',
      name: 'finance_receivable_collected',
      desc: '',
      args: [],
    );
  }

  /// `Outstanding`
  String get finance_receivable_outstanding {
    return Intl.message(
      'Outstanding',
      name: 'finance_receivable_outstanding',
      desc: '',
      args: [],
    );
  }

  /// `Record collection`
  String get finance_receivable_collect {
    return Intl.message(
      'Record collection',
      name: 'finance_receivable_collect',
      desc: '',
      args: [],
    );
  }

  /// `Add method`
  String get finance_methods_add {
    return Intl.message(
      'Add method',
      name: 'finance_methods_add',
      desc: '',
      args: [],
    );
  }

  /// `The payment methods could not be loaded`
  String get finance_methods_error_title {
    return Intl.message(
      'The payment methods could not be loaded',
      name: 'finance_methods_error_title',
      desc: '',
      args: [],
    );
  }

  /// `The accounts of this company could not be read. Try again in a moment.`
  String get finance_methods_error_subtitle {
    return Intl.message(
      'The accounts of this company could not be read. Try again in a moment.',
      name: 'finance_methods_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Account details are protected`
  String get finance_methods_locked_title {
    return Intl.message(
      'Account details are protected',
      name: 'finance_methods_locked_title',
      desc: '',
      args: [],
    );
  }

  /// `Type your password on the server to see the payment accounts.`
  String get finance_methods_locked_subtitle {
    return Intl.message(
      'Type your password on the server to see the payment accounts.',
      name: 'finance_methods_locked_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Type password`
  String get finance_methods_unlock {
    return Intl.message(
      'Type password',
      name: 'finance_methods_unlock',
      desc: '',
      args: [],
    );
  }

  /// `Export`
  String get finance_export {
    return Intl.message(
      'Export',
      name: 'finance_export',
      desc: '',
      args: [],
    );
  }

  /// `Accounting export`
  String get finance_export_title {
    return Intl.message(
      'Accounting export',
      name: 'finance_export_title',
      desc: '',
      args: [],
    );
  }

  /// `Sales, payments and stock movements for your accounting software. Every row carries its Lyra ID, so exporting a period again matches what was already imported.`
  String get finance_export_subtitle {
    return Intl.message(
      'Sales, payments and stock movements for your accounting software. Every row carries its Lyra ID, so exporting a period again matches what was already imported.',
      name: 'finance_export_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Period`
  String get finance_export_period {
    return Intl.message(
      'Period',
      name: 'finance_export_period',
      desc: '',
      args: [],
    );
  }

  /// `This month`
  String get finance_export_this_month {
    return Intl.message(
      'This month',
      name: 'finance_export_this_month',
      desc: '',
      args: [],
    );
  }

  /// `Last month`
  String get finance_export_last_month {
    return Intl.message(
      'Last month',
      name: 'finance_export_last_month',
      desc: '',
      args: [],
    );
  }

  /// `This year`
  String get finance_export_this_year {
    return Intl.message(
      'This year',
      name: 'finance_export_this_year',
      desc: '',
      args: [],
    );
  }

  /// `Last year`
  String get finance_export_last_year {
    return Intl.message(
      'Last year',
      name: 'finance_export_last_year',
      desc: '',
      args: [],
    );
  }

  /// `What to include`
  String get finance_export_datasets {
    return Intl.message(
      'What to include',
      name: 'finance_export_datasets',
      desc: '',
      args: [],
    );
  }

  /// `Pick at least one.`
  String get finance_export_datasets_empty {
    return Intl.message(
      'Pick at least one.',
      name: 'finance_export_datasets_empty',
      desc: '',
      args: [],
    );
  }

  /// `Sales`
  String get finance_export_sales {
    return Intl.message(
      'Sales',
      name: 'finance_export_sales',
      desc: '',
      args: [],
    );
  }

  /// `Sale lines`
  String get finance_export_sale_lines {
    return Intl.message(
      'Sale lines',
      name: 'finance_export_sale_lines',
      desc: '',
      args: [],
    );
  }

  /// `Payments`
  String get finance_export_payments {
    return Intl.message(
      'Payments',
      name: 'finance_export_payments',
      desc: '',
      args: [],
    );
  }

  /// `Receivables`
  String get finance_export_receivables {
    return Intl.message(
      'Receivables',
      name: 'finance_export_receivables',
      desc: '',
      args: [],
    );
  }

  /// `Stock movements`
  String get finance_export_stock_movements {
    return Intl.message(
      'Stock movements',
      name: 'finance_export_stock_movements',
      desc: '',
      args: [],
    );
  }

  /// `Format`
  String get finance_export_format {
    return Intl.message(
      'Format',
      name: 'finance_export_format',
      desc: '',
      args: [],
    );
  }

  /// `Excel (.xlsx)`
  String get finance_export_xlsx {
    return Intl.message(
      'Excel (.xlsx)',
      name: 'finance_export_xlsx',
      desc: '',
      args: [],
    );
  }

  /// `One sheet per dataset`
  String get finance_export_xlsx_hint {
    return Intl.message(
      'One sheet per dataset',
      name: 'finance_export_xlsx_hint',
      desc: '',
      args: [],
    );
  }

  /// `CSV (.zip)`
  String get finance_export_csv {
    return Intl.message(
      'CSV (.zip)',
      name: 'finance_export_csv',
      desc: '',
      args: [],
    );
  }

  /// `One file per dataset, for importing`
  String get finance_export_csv_hint {
    return Intl.message(
      'One file per dataset, for importing',
      name: 'finance_export_csv_hint',
      desc: '',
      args: [],
    );
  }

  /// `Export saved`
  String get finance_export_saved {
    return Intl.message(
      'Export saved',
      name: 'finance_export_saved',
      desc: '',
      args: [],
    );
  }

  /// `No payment method yet`
  String get finance_methods_empty_title {
    return Intl.message(
      'No payment method yet',
      name: 'finance_methods_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Add the account a customer is told to send money to.`
  String get finance_methods_empty_subtitle {
    return Intl.message(
      'Add the account a customer is told to send money to.',
      name: 'finance_methods_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Add a payment method`
  String get finance_method_create_title {
    return Intl.message(
      'Add a payment method',
      name: 'finance_method_create_title',
      desc: '',
      args: [],
    );
  }

  /// `Edit payment method`
  String get finance_method_edit_title {
    return Intl.message(
      'Edit payment method',
      name: 'finance_method_edit_title',
      desc: '',
      args: [],
    );
  }

  /// `What a customer is told when they ask how to pay. Each method asks only for what it needs to receive money.`
  String get finance_method_subtitle {
    return Intl.message(
      'What a customer is told when they ask how to pay. Each method asks only for what it needs to receive money.',
      name: 'finance_method_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Method`
  String get finance_method_rail {
    return Intl.message(
      'Method',
      name: 'finance_method_rail',
      desc: '',
      args: [],
    );
  }

  /// `Which one do you accept?`
  String get finance_method_rail_placeholder {
    return Intl.message(
      'Which one do you accept?',
      name: 'finance_method_rail_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Cannot be changed`
  String get finance_method_rail_fixed {
    return Intl.message(
      'Cannot be changed',
      name: 'finance_method_rail_fixed',
      desc: '',
      args: [],
    );
  }

  /// `The available methods could not be read. Go back to the tab and try again.`
  String get finance_method_no_rails {
    return Intl.message(
      'The available methods could not be read. Go back to the tab and try again.',
      name: 'finance_method_no_rails',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get finance_method_label {
    return Intl.message(
      'Name',
      name: 'finance_method_label',
      desc: '',
      args: [],
    );
  }

  /// `How you call this account`
  String get finance_method_label_placeholder {
    return Intl.message(
      'How you call this account',
      name: 'finance_method_label_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Holder`
  String get finance_method_holder {
    return Intl.message(
      'Holder',
      name: 'finance_method_holder',
      desc: '',
      args: [],
    );
  }

  /// `Name the account is under`
  String get finance_method_holder_placeholder {
    return Intl.message(
      'Name the account is under',
      name: 'finance_method_holder_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Id number`
  String get finance_method_document {
    return Intl.message(
      'Id number',
      name: 'finance_method_document',
      desc: '',
      args: [],
    );
  }

  /// `Tax or personal id`
  String get finance_method_document_placeholder {
    return Intl.message(
      'Tax or personal id',
      name: 'finance_method_document_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Institution`
  String get finance_method_institution {
    return Intl.message(
      'Institution',
      name: 'finance_method_institution',
      desc: '',
      args: [],
    );
  }

  /// `Bank, wallet or network`
  String get finance_method_institution_placeholder {
    return Intl.message(
      'Bank, wallet or network',
      name: 'finance_method_institution_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Account`
  String get finance_method_account {
    return Intl.message(
      'Account',
      name: 'finance_method_account',
      desc: '',
      args: [],
    );
  }

  /// `Number, phone, email or address`
  String get finance_method_account_placeholder {
    return Intl.message(
      'Number, phone, email or address',
      name: 'finance_method_account_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Instructions`
  String get finance_method_instructions {
    return Intl.message(
      'Instructions',
      name: 'finance_method_instructions',
      desc: '',
      args: [],
    );
  }

  /// `What the customer has to do besides sending it`
  String get finance_method_instructions_placeholder {
    return Intl.message(
      'What the customer has to do besides sending it',
      name: 'finance_method_instructions_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `optional`
  String get finance_method_optional {
    return Intl.message(
      'optional',
      name: 'finance_method_optional',
      desc: '',
      args: [],
    );
  }

  /// `Type`
  String get finance_method_document_type {
    return Intl.message(
      'Type',
      name: 'finance_method_document_type',
      desc: '',
      args: [],
    );
  }

  /// `This method needs no account details: name it if you want and save it.`
  String get finance_method_nothing {
    return Intl.message(
      'This method needs no account details: name it if you want and save it.',
      name: 'finance_method_nothing',
      desc: '',
      args: [],
    );
  }

  /// `Turn off`
  String get finance_method_remove {
    return Intl.message(
      'Turn off',
      name: 'finance_method_remove',
      desc: '',
      args: [],
    );
  }

  /// `Turn this method off?`
  String get finance_method_remove_title {
    return Intl.message(
      'Turn this method off?',
      name: 'finance_method_remove_title',
      desc: '',
      args: [],
    );
  }

  /// `{name} stops being offered. The payments already recorded through it stay in the history.`
  String finance_method_remove_message(Object name) {
    return Intl.message(
      '$name stops being offered. The payments already recorded through it stay in the history.',
      name: 'finance_method_remove_message',
      desc: '',
      args: [name],
    );
  }

  /// `Payment methods`
  String get finance_methods_title {
    return Intl.message(
      'Payment methods',
      name: 'finance_methods_title',
      desc: '',
      args: [],
    );
  }

  /// `Each method takes money in one currency and can add its own commission to the charge.`
  String get finance_methods_subtitle {
    return Intl.message(
      'Each method takes money in one currency and can add its own commission to the charge.',
      name: 'finance_methods_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Currency`
  String get finance_method_currency {
    return Intl.message(
      'Currency',
      name: 'finance_method_currency',
      desc: '',
      args: [],
    );
  }

  /// `Which currency does it receive?`
  String get finance_method_currency_placeholder {
    return Intl.message(
      'Which currency does it receive?',
      name: 'finance_method_currency_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `This method only moves {currency}.`
  String finance_method_currency_fixed(Object currency) {
    return Intl.message(
      'This method only moves $currency.',
      name: 'finance_method_currency_fixed',
      desc: '',
      args: [currency],
    );
  }

  /// `{currency} has no exchange rate. Add it under Currencies so the charge can be converted into it.`
  String finance_method_currency_missing(Object currency) {
    return Intl.message(
      '$currency has no exchange rate. Add it under Currencies so the charge can be converted into it.',
      name: 'finance_method_currency_missing',
      desc: '',
      args: [currency],
    );
  }

  /// `Commission`
  String get finance_method_fee {
    return Intl.message(
      'Commission',
      name: 'finance_method_fee',
      desc: '',
      args: [],
    );
  }

  /// `No commission`
  String get finance_method_fee_none {
    return Intl.message(
      'No commission',
      name: 'finance_method_fee_none',
      desc: '',
      args: [],
    );
  }

  /// `Percentage`
  String get finance_method_fee_percent {
    return Intl.message(
      'Percentage',
      name: 'finance_method_fee_percent',
      desc: '',
      args: [],
    );
  }

  /// `Fixed amount`
  String get finance_method_fee_fixed {
    return Intl.message(
      'Fixed amount',
      name: 'finance_method_fee_fixed',
      desc: '',
      args: [],
    );
  }

  /// `Fixed amount in {currency}`
  String finance_method_fee_fixed_in(Object currency) {
    return Intl.message(
      'Fixed amount in $currency',
      name: 'finance_method_fee_fixed_in',
      desc: '',
      args: [currency],
    );
  }

  /// `{value}%`
  String finance_method_fee_percent_value(Object value) {
    return Intl.message(
      '$value%',
      name: 'finance_method_fee_percent_value',
      desc: '',
      args: [value],
    );
  }

  /// `Write a commission above zero (a percentage below 100)`
  String get finance_method_fee_error {
    return Intl.message(
      'Write a commission above zero (a percentage below 100)',
      name: 'finance_method_fee_error',
      desc: '',
      args: [],
    );
  }

  /// `Currencies`
  String get finance_currencies_title {
    return Intl.message(
      'Currencies',
      name: 'finance_currencies_title',
      desc: '',
      args: [],
    );
  }

  /// `The main currency your catalog is priced in, and the exchange currencies you also take.`
  String get finance_currencies_subtitle {
    return Intl.message(
      'The main currency your catalog is priced in, and the exchange currencies you also take.',
      name: 'finance_currencies_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Add currency`
  String get finance_currencies_add {
    return Intl.message(
      'Add currency',
      name: 'finance_currencies_add',
      desc: '',
      args: [],
    );
  }

  /// `You only take your main currency. Add an exchange currency to charge in another one.`
  String get finance_currencies_empty {
    return Intl.message(
      'You only take your main currency. Add an exchange currency to charge in another one.',
      name: 'finance_currencies_empty',
      desc: '',
      args: [],
    );
  }

  /// `The currencies could not be loaded`
  String get finance_currencies_error_title {
    return Intl.message(
      'The currencies could not be loaded',
      name: 'finance_currencies_error_title',
      desc: '',
      args: [],
    );
  }

  /// `The currencies of this company could not be read. Try again in a moment.`
  String get finance_currencies_error_subtitle {
    return Intl.message(
      'The currencies of this company could not be read. Try again in a moment.',
      name: 'finance_currencies_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Currency`
  String get finance_currency {
    return Intl.message(
      'Currency',
      name: 'finance_currency',
      desc: '',
      args: [],
    );
  }

  /// `Which currency do you also take?`
  String get finance_currency_placeholder {
    return Intl.message(
      'Which currency do you also take?',
      name: 'finance_currency_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Main currency`
  String get finance_currency_main {
    return Intl.message(
      'Main currency',
      name: 'finance_currency_main',
      desc: '',
      args: [],
    );
  }

  /// `Your stock, services and prices are in this currency. It cannot be changed here: changing it would relabel your prices without converting them.`
  String get finance_currency_main_hint {
    return Intl.message(
      'Your stock, services and prices are in this currency. It cannot be changed here: changing it would relabel your prices without converting them.',
      name: 'finance_currency_main_hint',
      desc: '',
      args: [],
    );
  }

  /// `Add an exchange currency`
  String get finance_currency_create_title {
    return Intl.message(
      'Add an exchange currency',
      name: 'finance_currency_create_title',
      desc: '',
      args: [],
    );
  }

  /// `Edit exchange rate`
  String get finance_currency_edit_title {
    return Intl.message(
      'Edit exchange rate',
      name: 'finance_currency_edit_title',
      desc: '',
      args: [],
    );
  }

  /// `A currency you also charge in. Its rate says how much of it one {main} is worth.`
  String finance_currency_form_subtitle(Object main) {
    return Intl.message(
      'A currency you also charge in. Its rate says how much of it one $main is worth.',
      name: 'finance_currency_form_subtitle',
      desc: '',
      args: [main],
    );
  }

  /// `Exchange rate`
  String get finance_currency_mode {
    return Intl.message(
      'Exchange rate',
      name: 'finance_currency_mode',
      desc: '',
      args: [],
    );
  }

  /// `Official rate`
  String get finance_currency_mode_official {
    return Intl.message(
      'Official rate',
      name: 'finance_currency_mode_official',
      desc: '',
      args: [],
    );
  }

  /// `Updated on its own from the published rate`
  String get finance_currency_mode_official_hint {
    return Intl.message(
      'Updated on its own from the published rate',
      name: 'finance_currency_mode_official_hint',
      desc: '',
      args: [],
    );
  }

  /// `Custom rate`
  String get finance_currency_mode_custom {
    return Intl.message(
      'Custom rate',
      name: 'finance_currency_mode_custom',
      desc: '',
      args: [],
    );
  }

  /// `A rate you set, until you change it`
  String get finance_currency_mode_custom_hint {
    return Intl.message(
      'A rate you set, until you change it',
      name: 'finance_currency_mode_custom_hint',
      desc: '',
      args: [],
    );
  }

  /// `1 {main} in {currency}`
  String finance_currency_rate(Object main, Object currency) {
    return Intl.message(
      '1 $main in $currency',
      name: 'finance_currency_rate',
      desc: '',
      args: [main, currency],
    );
  }

  /// `Write a rate above zero`
  String get finance_currency_rate_error {
    return Intl.message(
      'Write a rate above zero',
      name: 'finance_currency_rate_error',
      desc: '',
      args: [],
    );
  }

  /// `A custom rate is set by your business alone. You are solely responsible for the rate you assign and for the prices and charges that come from it.`
  String get finance_currency_custom_disclaimer {
    return Intl.message(
      'A custom rate is set by your business alone. You are solely responsible for the rate you assign and for the prices and charges that come from it.',
      name: 'finance_currency_custom_disclaimer',
      desc: '',
      args: [],
    );
  }

  /// `Official rate: {rate}`
  String finance_currency_official_today(Object rate) {
    return Intl.message(
      'Official rate: $rate',
      name: 'finance_currency_official_today',
      desc: '',
      args: [rate],
    );
  }

  /// `The official rate appears once the currency is saved.`
  String get finance_currency_official_pending {
    return Intl.message(
      'The official rate appears once the currency is saved.',
      name: 'finance_currency_official_pending',
      desc: '',
      args: [],
    );
  }

  /// `No rate available right now`
  String get finance_currency_no_rate {
    return Intl.message(
      'No rate available right now',
      name: 'finance_currency_no_rate',
      desc: '',
      args: [],
    );
  }

  /// `Updated {date}`
  String finance_currency_updated(Object date) {
    return Intl.message(
      'Updated $date',
      name: 'finance_currency_updated',
      desc: '',
      args: [date],
    );
  }

  /// `Remove`
  String get finance_currency_remove {
    return Intl.message(
      'Remove',
      name: 'finance_currency_remove',
      desc: '',
      args: [],
    );
  }

  /// `Remove this currency?`
  String get finance_currency_remove_title {
    return Intl.message(
      'Remove this currency?',
      name: 'finance_currency_remove_title',
      desc: '',
      args: [],
    );
  }

  /// `{currency} stops being offered. Payment methods in {currency} stay, with no rate to convert their charge.`
  String finance_currency_remove_message(Object currency) {
    return Intl.message(
      '$currency stops being offered. Payment methods in $currency stay, with no rate to convert their charge.',
      name: 'finance_currency_remove_message',
      desc: '',
      args: [currency],
    );
  }

  /// `Deliveries`
  String get deliveries {
    return Intl.message(
      'Deliveries',
      name: 'deliveries',
      desc: '',
      args: [],
    );
  }

  /// `Here you will see every order still on its way to the customer.`
  String get deliveries_pending_soon {
    return Intl.message(
      'Here you will see every order still on its way to the customer.',
      name: 'deliveries_pending_soon',
      desc: '',
      args: [],
    );
  }

  /// `© OpenStreetMap contributors`
  String get deliveries_map_attribution {
    return Intl.message(
      '© OpenStreetMap contributors',
      name: 'deliveries_map_attribution',
      desc: '',
      args: [],
    );
  }

  /// `Here you will see your deliveries on the map.`
  String get deliveries_map_soon {
    return Intl.message(
      'Here you will see your deliveries on the map.',
      name: 'deliveries_map_soon',
      desc: '',
      args: [],
    );
  }

  /// `The map did not load`
  String get deliveries_map_error_title {
    return Intl.message(
      'The map did not load',
      name: 'deliveries_map_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Check your connection and try again.`
  String get deliveries_map_error_subtitle {
    return Intl.message(
      'Check your connection and try again.',
      name: 'deliveries_map_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get deliveries_map_retry {
    return Intl.message(
      'Try again',
      name: 'deliveries_map_retry',
      desc: '',
      args: [],
    );
  }

  /// `Zoom in`
  String get deliveries_map_zoom_in {
    return Intl.message(
      'Zoom in',
      name: 'deliveries_map_zoom_in',
      desc: '',
      args: [],
    );
  }

  /// `Zoom out`
  String get deliveries_map_zoom_out {
    return Intl.message(
      'Zoom out',
      name: 'deliveries_map_zoom_out',
      desc: '',
      args: [],
    );
  }

  /// `Center`
  String get deliveries_center {
    return Intl.message(
      'Center',
      name: 'deliveries_center',
      desc: '',
      args: [],
    );
  }

  /// `Refresh`
  String get deliveries_refresh {
    return Intl.message(
      'Refresh',
      name: 'deliveries_refresh',
      desc: '',
      args: [],
    );
  }

  /// `New delivery`
  String get deliveries_create {
    return Intl.message(
      'New delivery',
      name: 'deliveries_create',
      desc: '',
      args: [],
    );
  }

  /// `Settings`
  String get deliveries_settings {
    return Intl.message(
      'Settings',
      name: 'deliveries_settings',
      desc: '',
      args: [],
    );
  }

  /// `Delivery settings`
  String get deliveries_settings_title {
    return Intl.message(
      'Delivery settings',
      name: 'deliveries_settings_title',
      desc: '',
      args: [],
    );
  }

  /// `Select delivery area`
  String get deliveries_area {
    return Intl.message(
      'Select delivery area',
      name: 'deliveries_area',
      desc: '',
      args: [],
    );
  }

  /// `Delivery area`
  String get deliveries_area_title {
    return Intl.message(
      'Delivery area',
      name: 'deliveries_area_title',
      desc: '',
      args: [],
    );
  }

  /// `Add area`
  String get deliveries_area_add {
    return Intl.message(
      'Add area',
      name: 'deliveries_area_add',
      desc: '',
      args: [],
    );
  }

  /// `Radius around your business`
  String get deliveries_area_method_radius {
    return Intl.message(
      'Radius around your business',
      name: 'deliveries_area_method_radius',
      desc: '',
      args: [],
    );
  }

  /// `Everything within some kilometres of your location`
  String get deliveries_area_method_radius_note {
    return Intl.message(
      'Everything within some kilometres of your location',
      name: 'deliveries_area_method_radius_note',
      desc: '',
      args: [],
    );
  }

  /// `Draw on the map`
  String get deliveries_area_method_draw {
    return Intl.message(
      'Draw on the map',
      name: 'deliveries_area_method_draw',
      desc: '',
      args: [],
    );
  }

  /// `Any shape: a whole city, or only some neighbourhoods`
  String get deliveries_area_method_draw_note {
    return Intl.message(
      'Any shape: a whole city, or only some neighbourhoods',
      name: 'deliveries_area_method_draw_note',
      desc: '',
      args: [],
    );
  }

  /// `By travel time`
  String get deliveries_area_method_travel {
    return Intl.message(
      'By travel time',
      name: 'deliveries_area_method_travel',
      desc: '',
      args: [],
    );
  }

  /// `As far as a courier gets in some minutes, then adjust it`
  String get deliveries_area_method_travel_note {
    return Intl.message(
      'As far as a courier gets in some minutes, then adjust it',
      name: 'deliveries_area_method_travel_note',
      desc: '',
      args: [],
    );
  }

  /// `Wait for your areas to load before adding one.`
  String get deliveries_area_not_ready {
    return Intl.message(
      'Wait for your areas to load before adding one.',
      name: 'deliveries_area_not_ready',
      desc: '',
      args: [],
    );
  }

  /// `You can have up to {count} areas.`
  String deliveries_area_limit(Object count) {
    return Intl.message(
      'You can have up to $count areas.',
      name: 'deliveries_area_limit',
      desc: '',
      args: [count],
    );
  }

  /// `Couldn't load your delivery areas`
  String get deliveries_area_error_title {
    return Intl.message(
      'Couldn\'t load your delivery areas',
      name: 'deliveries_area_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get deliveries_area_error_subtitle {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'deliveries_area_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Tap the map to check whether a point is inside your areas.`
  String get deliveries_area_probe_hint {
    return Intl.message(
      'Tap the map to check whether a point is inside your areas.',
      name: 'deliveries_area_probe_hint',
      desc: '',
      args: [],
    );
  }

  /// `Inside your areas`
  String get deliveries_area_probe_in {
    return Intl.message(
      'Inside your areas',
      name: 'deliveries_area_probe_in',
      desc: '',
      args: [],
    );
  }

  /// `Outside your areas`
  String get deliveries_area_probe_out {
    return Intl.message(
      'Outside your areas',
      name: 'deliveries_area_probe_out',
      desc: '',
      args: [],
    );
  }

  /// `No active area reaches this point.`
  String get deliveries_area_probe_out_note {
    return Intl.message(
      'No active area reaches this point.',
      name: 'deliveries_area_probe_out_note',
      desc: '',
      args: [],
    );
  }

  /// `Several areas reach it. The cheapest is listed first, which is the one a customer pays.`
  String get deliveries_area_probe_overlap {
    return Intl.message(
      'Several areas reach it. The cheapest is listed first, which is the one a customer pays.',
      name: 'deliveries_area_probe_overlap',
      desc: '',
      args: [],
    );
  }

  /// `Clear the point`
  String get deliveries_area_probe_clear {
    return Intl.message(
      'Clear the point',
      name: 'deliveries_area_probe_clear',
      desc: '',
      args: [],
    );
  }

  /// `No areas yet`
  String get deliveries_area_empty_title {
    return Intl.message(
      'No areas yet',
      name: 'deliveries_area_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Add one from the top: a radius around your business, a shape drawn on the map, or how far a courier gets in some minutes.`
  String get deliveries_area_empty_subtitle {
    return Intl.message(
      'Add one from the top: a radius around your business, a shape drawn on the map, or how far a courier gets in some minutes.',
      name: 'deliveries_area_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Show on the map`
  String get deliveries_area_focus {
    return Intl.message(
      'Show on the map',
      name: 'deliveries_area_focus',
      desc: '',
      args: [],
    );
  }

  /// `Edit area`
  String get deliveries_area_edit {
    return Intl.message(
      'Edit area',
      name: 'deliveries_area_edit',
      desc: '',
      args: [],
    );
  }

  /// `Pause area`
  String get deliveries_area_pause {
    return Intl.message(
      'Pause area',
      name: 'deliveries_area_pause',
      desc: '',
      args: [],
    );
  }

  /// `Resume area`
  String get deliveries_area_resume {
    return Intl.message(
      'Resume area',
      name: 'deliveries_area_resume',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get deliveries_area_remove {
    return Intl.message(
      'Remove',
      name: 'deliveries_area_remove',
      desc: '',
      args: [],
    );
  }

  /// `Remove this area?`
  String get deliveries_area_remove_title {
    return Intl.message(
      'Remove this area?',
      name: 'deliveries_area_remove_title',
      desc: '',
      args: [],
    );
  }

  /// `{name} stops being part of where you deliver. To stop delivering there for a while, pause it instead.`
  String deliveries_area_remove_message(Object name) {
    return Intl.message(
      '$name stops being part of where you deliver. To stop delivering there for a while, pause it instead.',
      name: 'deliveries_area_remove_message',
      desc: '',
      args: [name],
    );
  }

  /// `Paused`
  String get deliveries_area_paused {
    return Intl.message(
      'Paused',
      name: 'deliveries_area_paused',
      desc: '',
      args: [],
    );
  }

  /// `Price of the delivery option`
  String get deliveries_area_fee_option {
    return Intl.message(
      'Price of the delivery option',
      name: 'deliveries_area_fee_option',
      desc: '',
      args: [],
    );
  }

  /// `Min. order {amount}`
  String deliveries_area_minimum_tag(Object amount) {
    return Intl.message(
      'Min. order $amount',
      name: 'deliveries_area_minimum_tag',
      desc: '',
      args: [amount],
    );
  }

  /// `{km} km²`
  String deliveries_area_size(Object km) {
    return Intl.message(
      '$km km²',
      name: 'deliveries_area_size',
      desc: '',
      args: [km],
    );
  }

  /// `Drawn on the map`
  String get deliveries_area_drawn {
    return Intl.message(
      'Drawn on the map',
      name: 'deliveries_area_drawn',
      desc: '',
      args: [],
    );
  }

  /// `New area`
  String get deliveries_area_new_title {
    return Intl.message(
      'New area',
      name: 'deliveries_area_new_title',
      desc: '',
      args: [],
    );
  }

  /// `Edit area`
  String get deliveries_area_edit_title {
    return Intl.message(
      'Edit area',
      name: 'deliveries_area_edit_title',
      desc: '',
      args: [],
    );
  }

  /// `Area {number}`
  String deliveries_area_default_name(Object number) {
    return Intl.message(
      'Area $number',
      name: 'deliveries_area_default_name',
      desc: '',
      args: [number],
    );
  }

  /// `Name`
  String get deliveries_area_name {
    return Intl.message(
      'Name',
      name: 'deliveries_area_name',
      desc: '',
      args: [],
    );
  }

  /// `All of Caracas`
  String get deliveries_area_name_hint {
    return Intl.message(
      'All of Caracas',
      name: 'deliveries_area_name_hint',
      desc: '',
      args: [],
    );
  }

  /// `Delivery price here`
  String get deliveries_area_fee {
    return Intl.message(
      'Delivery price here',
      name: 'deliveries_area_fee',
      desc: '',
      args: [],
    );
  }

  /// `In {currency}. Empty to use the delivery option's, 0 if it's free`
  String deliveries_area_fee_hint(Object currency) {
    return Intl.message(
      'In $currency. Empty to use the delivery option\'s, 0 if it\'s free',
      name: 'deliveries_area_fee_hint',
      desc: '',
      args: [currency],
    );
  }

  /// `Minimum order`
  String get deliveries_area_minimum {
    return Intl.message(
      'Minimum order',
      name: 'deliveries_area_minimum',
      desc: '',
      args: [],
    );
  }

  /// `Order total below which you don't deliver here`
  String get deliveries_area_minimum_hint {
    return Intl.message(
      'Order total below which you don\'t deliver here',
      name: 'deliveries_area_minimum_hint',
      desc: '',
      args: [],
    );
  }

  /// `{km} km`
  String deliveries_area_km(Object km) {
    return Intl.message(
      '$km km',
      name: 'deliveries_area_km',
      desc: '',
      args: [km],
    );
  }

  /// `{count, plural, =1{1 point} other{{count} points}} · 3 at least`
  String deliveries_area_points(num count) {
    return Intl.message(
      '${Intl.plural(count, one: '1 point', other: '$count points')} · 3 at least',
      name: 'deliveries_area_points',
      desc: '',
      args: [count],
    );
  }

  /// `Undo`
  String get deliveries_area_undo {
    return Intl.message(
      'Undo',
      name: 'deliveries_area_undo',
      desc: '',
      args: [],
    );
  }

  /// `Remove point`
  String get deliveries_area_remove_point {
    return Intl.message(
      'Remove point',
      name: 'deliveries_area_remove_point',
      desc: '',
      args: [],
    );
  }

  /// `Clear`
  String get deliveries_area_clear {
    return Intl.message(
      'Clear',
      name: 'deliveries_area_clear',
      desc: '',
      args: [],
    );
  }

  /// `Travel time`
  String get deliveries_area_travel {
    return Intl.message(
      'Travel time',
      name: 'deliveries_area_travel',
      desc: '',
      args: [],
    );
  }

  /// `How`
  String get deliveries_area_travel_mode {
    return Intl.message(
      'How',
      name: 'deliveries_area_travel_mode',
      desc: '',
      args: [],
    );
  }

  /// `Minutes`
  String get deliveries_area_travel_minutes {
    return Intl.message(
      'Minutes',
      name: 'deliveries_area_travel_minutes',
      desc: '',
      args: [],
    );
  }

  /// `Calculate area`
  String get deliveries_area_travel_compute {
    return Intl.message(
      'Calculate area',
      name: 'deliveries_area_travel_compute',
      desc: '',
      args: [],
    );
  }

  /// `Calculate again`
  String get deliveries_area_travel_again {
    return Intl.message(
      'Calculate again',
      name: 'deliveries_area_travel_again',
      desc: '',
      args: [],
    );
  }

  /// `Write the minutes, from 1 to 120.`
  String get deliveries_area_travel_invalid {
    return Intl.message(
      'Write the minutes, from 1 to 120.',
      name: 'deliveries_area_travel_invalid',
      desc: '',
      args: [],
    );
  }

  /// `The area couldn't be calculated: the route service may be down, or no road leaves that point. You can still draw it by hand.`
  String get deliveries_area_travel_failed {
    return Intl.message(
      'The area couldn\'t be calculated: the route service may be down, or no road leaves that point. You can still draw it by hand.',
      name: 'deliveries_area_travel_failed',
      desc: '',
      args: [],
    );
  }

  /// `Put at least 3 points on the map.`
  String get deliveries_area_shape_missing {
    return Intl.message(
      'Put at least 3 points on the map.',
      name: 'deliveries_area_shape_missing',
      desc: '',
      args: [],
    );
  }

  /// `Tap the map or drag the center to move it, and type the kilometres or pick them.`
  String get deliveries_area_radius_note {
    return Intl.message(
      'Tap the map or drag the center to move it, and type the kilometres or pick them.',
      name: 'deliveries_area_radius_note',
      desc: '',
      args: [],
    );
  }

  /// `Tap the map to add points. Drag a point to move it, tap the ring in the middle of a side to add one there, or tap a point and remove it.`
  String get deliveries_area_draw_note {
    return Intl.message(
      'Tap the map to add points. Drag a point to move it, tap the ring in the middle of a side to add one there, or tap a point and remove it.',
      name: 'deliveries_area_draw_note',
      desc: '',
      args: [],
    );
  }

  /// `Tap the map or drag the center to choose where the courier leaves from, then pick how they travel and for how many minutes.`
  String get deliveries_area_travel_note {
    return Intl.message(
      'Tap the map or drag the center to choose where the courier leaves from, then pick how they travel and for how many minutes.',
      name: 'deliveries_area_travel_note',
      desc: '',
      args: [],
    );
  }

  /// `Motorcycle`
  String get deliveries_area_mode_motorcycle {
    return Intl.message(
      'Motorcycle',
      name: 'deliveries_area_mode_motorcycle',
      desc: '',
      args: [],
    );
  }

  /// `Car`
  String get deliveries_area_mode_car {
    return Intl.message(
      'Car',
      name: 'deliveries_area_mode_car',
      desc: '',
      args: [],
    );
  }

  /// `Bicycle`
  String get deliveries_area_mode_bicycle {
    return Intl.message(
      'Bicycle',
      name: 'deliveries_area_mode_bicycle',
      desc: '',
      args: [],
    );
  }

  /// `On foot`
  String get deliveries_area_mode_foot {
    return Intl.message(
      'On foot',
      name: 'deliveries_area_mode_foot',
      desc: '',
      args: [],
    );
  }

  /// `Sales`
  String get sales {
    return Intl.message(
      'Sales',
      name: 'sales',
      desc: '',
      args: [],
    );
  }

  /// `Transactions`
  String get section_transactions {
    return Intl.message(
      'Transactions',
      name: 'section_transactions',
      desc: '',
      args: [],
    );
  }

  /// `In progress`
  String get sales_tab_process {
    return Intl.message(
      'In progress',
      name: 'sales_tab_process',
      desc: '',
      args: [],
    );
  }

  /// `Completed`
  String get sales_tab_done {
    return Intl.message(
      'Completed',
      name: 'sales_tab_done',
      desc: '',
      args: [],
    );
  }

  /// `{count} sales`
  String sales_count(Object count) {
    return Intl.message(
      '$count sales',
      name: 'sales_count',
      desc: '',
      args: [count],
    );
  }

  /// `{count} moved`
  String sales_pending(Object count) {
    return Intl.message(
      '$count moved',
      name: 'sales_pending',
      desc: '',
      args: [count],
    );
  }

  /// `Load more`
  String get sales_more {
    return Intl.message(
      'Load more',
      name: 'sales_more',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get sales_retry {
    return Intl.message(
      'Try again',
      name: 'sales_retry',
      desc: '',
      args: [],
    );
  }

  /// `Every state`
  String get sales_all_stages {
    return Intl.message(
      'Every state',
      name: 'sales_all_stages',
      desc: '',
      args: [],
    );
  }

  /// `Channel`
  String get sales_channel {
    return Intl.message(
      'Channel',
      name: 'sales_channel',
      desc: '',
      args: [],
    );
  }

  /// `Every channel`
  String get sales_any_channel {
    return Intl.message(
      'Every channel',
      name: 'sales_any_channel',
      desc: '',
      args: [],
    );
  }

  /// `Sold by me`
  String get sales_mine {
    return Intl.message(
      'Sold by me',
      name: 'sales_mine',
      desc: '',
      args: [],
    );
  }

  /// `Clear filters`
  String get sales_clear {
    return Intl.message(
      'Clear filters',
      name: 'sales_clear',
      desc: '',
      args: [],
    );
  }

  /// `Nothing to choose from`
  String get sales_select_empty {
    return Intl.message(
      'Nothing to choose from',
      name: 'sales_select_empty',
      desc: '',
      args: [],
    );
  }

  /// `Filtering by channel or by seller answers with tickets only: a conversation the assistant is still holding has neither.`
  String get sales_tickets_only {
    return Intl.message(
      'Filtering by channel or by seller answers with tickets only: a conversation the assistant is still holding has neither.',
      name: 'sales_tickets_only',
      desc: '',
      args: [],
    );
  }

  /// `The states could not be read`
  String get sales_catalog_error {
    return Intl.message(
      'The states could not be read',
      name: 'sales_catalog_error',
      desc: '',
      args: [],
    );
  }

  /// `State`
  String get sales_column_stage {
    return Intl.message(
      'State',
      name: 'sales_column_stage',
      desc: '',
      args: [],
    );
  }

  /// `Customer`
  String get sales_column_customer {
    return Intl.message(
      'Customer',
      name: 'sales_column_customer',
      desc: '',
      args: [],
    );
  }

  /// `Came in through`
  String get sales_column_channel {
    return Intl.message(
      'Came in through',
      name: 'sales_column_channel',
      desc: '',
      args: [],
    );
  }

  /// `Waiting`
  String get sales_column_wait {
    return Intl.message(
      'Waiting',
      name: 'sales_column_wait',
      desc: '',
      args: [],
    );
  }

  /// `Ticket`
  String get sales_column_ticket {
    return Intl.message(
      'Ticket',
      name: 'sales_column_ticket',
      desc: '',
      args: [],
    );
  }

  /// `Units`
  String get sales_column_units {
    return Intl.message(
      'Units',
      name: 'sales_column_units',
      desc: '',
      args: [],
    );
  }

  /// `Total`
  String get sales_column_total {
    return Intl.message(
      'Total',
      name: 'sales_column_total',
      desc: '',
      args: [],
    );
  }

  /// `Outstanding`
  String get sales_column_outstanding {
    return Intl.message(
      'Outstanding',
      name: 'sales_column_outstanding',
      desc: '',
      args: [],
    );
  }

  /// `Sold by`
  String get sales_column_seller {
    return Intl.message(
      'Sold by',
      name: 'sales_column_seller',
      desc: '',
      args: [],
    );
  }

  /// `just now`
  String get sales_wait_now {
    return Intl.message(
      'just now',
      name: 'sales_wait_now',
      desc: '',
      args: [],
    );
  }

  /// `{count} min`
  String sales_wait_minutes(Object count) {
    return Intl.message(
      '$count min',
      name: 'sales_wait_minutes',
      desc: '',
      args: [count],
    );
  }

  /// `{count} h`
  String sales_wait_hours(Object count) {
    return Intl.message(
      '$count h',
      name: 'sales_wait_hours',
      desc: '',
      args: [count],
    );
  }

  /// `{count} d`
  String sales_wait_days(Object count) {
    return Intl.message(
      '$count d',
      name: 'sales_wait_days',
      desc: '',
      args: [count],
    );
  }

  /// `The sales could not be read`
  String get sales_error_title {
    return Intl.message(
      'The sales could not be read',
      name: 'sales_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Check the connection and try again.`
  String get sales_error_subtitle {
    return Intl.message(
      'Check the connection and try again.',
      name: 'sales_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Nothing pending`
  String get sales_empty_process_title {
    return Intl.message(
      'Nothing pending',
      name: 'sales_empty_process_title',
      desc: '',
      args: [],
    );
  }

  /// `No sale is waiting on anybody: nothing to charge, nothing to verify, nothing to hand over.`
  String get sales_empty_process_subtitle {
    return Intl.message(
      'No sale is waiting on anybody: nothing to charge, nothing to verify, nothing to hand over.',
      name: 'sales_empty_process_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No sale finished yet`
  String get sales_empty_done_title {
    return Intl.message(
      'No sale finished yet',
      name: 'sales_empty_done_title',
      desc: '',
      args: [],
    );
  }

  /// `A sale lands here once the money has arrived and the customer has the goods.`
  String get sales_empty_done_subtitle {
    return Intl.message(
      'A sale lands here once the money has arrived and the customer has the goods.',
      name: 'sales_empty_done_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No sale matches`
  String get sales_empty_filter_title {
    return Intl.message(
      'No sale matches',
      name: 'sales_empty_filter_title',
      desc: '',
      args: [],
    );
  }

  /// `Nothing is at that state, or came in through that channel.`
  String get sales_empty_filter_subtitle {
    return Intl.message(
      'Nothing is at that state, or came in through that channel.',
      name: 'sales_empty_filter_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `The search narrows the sales already read, by ticket code, customer and seller.`
  String get sales_search_scope {
    return Intl.message(
      'The search narrows the sales already read, by ticket code, customer and seller.',
      name: 'sales_search_scope',
      desc: '',
      args: [],
    );
  }

  /// `No sale matches the search`
  String get sales_search_empty_title {
    return Intl.message(
      'No sale matches the search',
      name: 'sales_search_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `Nothing read so far carries that ticket code, customer or seller. The sale may be further down: load more and search again.`
  String get sales_search_empty_subtitle {
    return Intl.message(
      'Nothing read so far carries that ticket code, customer or seller. The sale may be further down: load more and search again.',
      name: 'sales_search_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Record the handover`
  String get sales_handover_action {
    return Intl.message(
      'Record the handover',
      name: 'sales_handover_action',
      desc: '',
      args: [],
    );
  }

  /// `Handover`
  String get sales_handover_title {
    return Intl.message(
      'Handover',
      name: 'sales_handover_title',
      desc: '',
      args: [],
    );
  }

  /// `Say how the customer gets this sale and how far that got. Nobody else can: the shelf knows the units left and the ticket knows the money arrived, but only a person knows whether the delivery went out or the customer came for it.`
  String get sales_handover_subtitle {
    return Intl.message(
      'Say how the customer gets this sale and how far that got. Nobody else can: the shelf knows the units left and the ticket knows the money arrived, but only a person knows whether the delivery went out or the customer came for it.',
      name: 'sales_handover_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `How they get it`
  String get sales_handover_mode {
    return Intl.message(
      'How they get it',
      name: 'sales_handover_mode',
      desc: '',
      args: [],
    );
  }

  /// `Handed over, collected or delivered`
  String get sales_handover_mode_placeholder {
    return Intl.message(
      'Handed over, collected or delivered',
      name: 'sales_handover_mode_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Choose how the customer gets it`
  String get sales_handover_mode_error {
    return Intl.message(
      'Choose how the customer gets it',
      name: 'sales_handover_mode_error',
      desc: '',
      args: [],
    );
  }

  /// `That is what the sale already says`
  String get sales_handover_same_error {
    return Intl.message(
      'That is what the sale already says',
      name: 'sales_handover_same_error',
      desc: '',
      args: [],
    );
  }

  /// `Where it got to`
  String get sales_handover_state {
    return Intl.message(
      'Where it got to',
      name: 'sales_handover_state',
      desc: '',
      args: [],
    );
  }

  /// `Not sent, dispatched or delivered`
  String get sales_handover_state_placeholder {
    return Intl.message(
      'Not sent, dispatched or delivered',
      name: 'sales_handover_state_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Note`
  String get sales_handover_note {
    return Intl.message(
      'Note',
      name: 'sales_handover_note',
      desc: '',
      args: [],
    );
  }

  /// `A tracking number, who collected it`
  String get sales_handover_note_placeholder {
    return Intl.message(
      'A tracking number, who collected it',
      name: 'sales_handover_note_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Record`
  String get sales_handover_save {
    return Intl.message(
      'Record',
      name: 'sales_handover_save',
      desc: '',
      args: [],
    );
  }

  /// `Handover recorded`
  String get sales_handover_saved {
    return Intl.message(
      'Handover recorded',
      name: 'sales_handover_saved',
      desc: '',
      args: [],
    );
  }

  /// `Sale`
  String get sales_detail_title {
    return Intl.message(
      'Sale',
      name: 'sales_detail_title',
      desc: '',
      args: [],
    );
  }

  /// `Open the sale`
  String get sales_detail_open {
    return Intl.message(
      'Open the sale',
      name: 'sales_detail_open',
      desc: '',
      args: [],
    );
  }

  /// `The sale could not be read`
  String get sales_detail_error_title {
    return Intl.message(
      'The sale could not be read',
      name: 'sales_detail_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Check the connection and try again.`
  String get sales_detail_error_subtitle {
    return Intl.message(
      'Check the connection and try again.',
      name: 'sales_detail_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `This is no longer a sale`
  String get sales_detail_missing_title {
    return Intl.message(
      'This is no longer a sale',
      name: 'sales_detail_missing_title',
      desc: '',
      args: [],
    );
  }

  /// `Nothing is held for it and nothing was agreed on the money, or it was rung up under another record. Refresh the board to see where it went.`
  String get sales_detail_missing_subtitle {
    return Intl.message(
      'Nothing is held for it and nothing was agreed on the money, or it was rung up under another record. Refresh the board to see where it went.',
      name: 'sales_detail_missing_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Charged`
  String get sales_detail_source_ticket {
    return Intl.message(
      'Charged',
      name: 'sales_detail_source_ticket',
      desc: '',
      args: [],
    );
  }

  /// `Open at the till`
  String get sales_detail_source_invoice {
    return Intl.message(
      'Open at the till',
      name: 'sales_detail_source_invoice',
      desc: '',
      args: [],
    );
  }

  /// `Being arranged`
  String get sales_detail_source_chat {
    return Intl.message(
      'Being arranged',
      name: 'sales_detail_source_chat',
      desc: '',
      args: [],
    );
  }

  /// `Open`
  String get sales_detail_status_open {
    return Intl.message(
      'Open',
      name: 'sales_detail_status_open',
      desc: '',
      args: [],
    );
  }

  /// `Charged`
  String get sales_detail_status_completed {
    return Intl.message(
      'Charged',
      name: 'sales_detail_status_completed',
      desc: '',
      args: [],
    );
  }

  /// `Cancelled`
  String get sales_detail_status_cancelled {
    return Intl.message(
      'Cancelled',
      name: 'sales_detail_status_cancelled',
      desc: '',
      args: [],
    );
  }

  /// `Failed`
  String get sales_detail_status_failed {
    return Intl.message(
      'Failed',
      name: 'sales_detail_status_failed',
      desc: '',
      args: [],
    );
  }

  /// `Waiting on you`
  String get sales_detail_attention {
    return Intl.message(
      'Waiting on you',
      name: 'sales_detail_attention',
      desc: '',
      args: [],
    );
  }

  /// `No name given`
  String get sales_detail_customer_unknown {
    return Intl.message(
      'No name given',
      name: 'sales_detail_customer_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Not said`
  String get sales_detail_none {
    return Intl.message(
      'Not said',
      name: 'sales_detail_none',
      desc: '',
      args: [],
    );
  }

  /// `The money`
  String get sales_detail_money {
    return Intl.message(
      'The money',
      name: 'sales_detail_money',
      desc: '',
      args: [],
    );
  }

  /// `Units`
  String get sales_detail_units {
    return Intl.message(
      'Units',
      name: 'sales_detail_units',
      desc: '',
      args: [],
    );
  }

  /// `Subtotal`
  String get sales_detail_subtotal {
    return Intl.message(
      'Subtotal',
      name: 'sales_detail_subtotal',
      desc: '',
      args: [],
    );
  }

  /// `Tax`
  String get sales_detail_tax {
    return Intl.message(
      'Tax',
      name: 'sales_detail_tax',
      desc: '',
      args: [],
    );
  }

  /// `Total`
  String get sales_detail_total {
    return Intl.message(
      'Total',
      name: 'sales_detail_total',
      desc: '',
      args: [],
    );
  }

  /// `Nobody has priced it`
  String get sales_detail_unpriced {
    return Intl.message(
      'Nobody has priced it',
      name: 'sales_detail_unpriced',
      desc: '',
      args: [],
    );
  }

  /// `Nothing has been rung up`
  String get sales_detail_untaxed {
    return Intl.message(
      'Nothing has been rung up',
      name: 'sales_detail_untaxed',
      desc: '',
      args: [],
    );
  }

  /// `{rate}% on {base}`
  String sales_detail_tax_rate(Object rate, Object base) {
    return Intl.message(
      '$rate% on $base',
      name: 'sales_detail_tax_rate',
      desc: '',
      args: [rate, base],
    );
  }

  /// `Paid with`
  String get sales_detail_method {
    return Intl.message(
      'Paid with',
      name: 'sales_detail_method',
      desc: '',
      args: [],
    );
  }

  /// `Offered to pay with`
  String get sales_detail_method_offered {
    return Intl.message(
      'Offered to pay with',
      name: 'sales_detail_method_offered',
      desc: '',
      args: [],
    );
  }

  /// `Reference`
  String get sales_detail_reference {
    return Intl.message(
      'Reference',
      name: 'sales_detail_reference',
      desc: '',
      args: [],
    );
  }

  /// `Sold on credit`
  String get sales_detail_credit {
    return Intl.message(
      'Sold on credit',
      name: 'sales_detail_credit',
      desc: '',
      args: [],
    );
  }

  /// `Collected`
  String get sales_detail_collected {
    return Intl.message(
      'Collected',
      name: 'sales_detail_collected',
      desc: '',
      args: [],
    );
  }

  /// `Still owed`
  String get sales_detail_outstanding {
    return Intl.message(
      'Still owed',
      name: 'sales_detail_outstanding',
      desc: '',
      args: [],
    );
  }

  /// `Nothing owed`
  String get sales_detail_settled {
    return Intl.message(
      'Nothing owed',
      name: 'sales_detail_settled',
      desc: '',
      args: [],
    );
  }

  /// `What is on it`
  String get sales_detail_items {
    return Intl.message(
      'What is on it',
      name: 'sales_detail_items',
      desc: '',
      args: [],
    );
  }

  /// `Nothing on it yet`
  String get sales_detail_items_empty {
    return Intl.message(
      'Nothing on it yet',
      name: 'sales_detail_items_empty',
      desc: '',
      args: [],
    );
  }

  /// `Product`
  String get sales_detail_item_product {
    return Intl.message(
      'Product',
      name: 'sales_detail_item_product',
      desc: '',
      args: [],
    );
  }

  /// `Qty`
  String get sales_detail_item_qty {
    return Intl.message(
      'Qty',
      name: 'sales_detail_item_qty',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get sales_detail_item_price {
    return Intl.message(
      'Price',
      name: 'sales_detail_item_price',
      desc: '',
      args: [],
    );
  }

  /// `Total`
  String get sales_detail_item_total {
    return Intl.message(
      'Total',
      name: 'sales_detail_item_total',
      desc: '',
      args: [],
    );
  }

  /// `No longer sold`
  String get sales_detail_item_gone {
    return Intl.message(
      'No longer sold',
      name: 'sales_detail_item_gone',
      desc: '',
      args: [],
    );
  }

  /// `Said to be held, and nothing is`
  String get sales_detail_item_unheld {
    return Intl.message(
      'Said to be held, and nothing is',
      name: 'sales_detail_item_unheld',
      desc: '',
      args: [],
    );
  }

  /// `{count} held`
  String sales_detail_item_held(Object count) {
    return Intl.message(
      '$count held',
      name: 'sales_detail_item_held',
      desc: '',
      args: [count],
    );
  }

  /// `{count} left`
  String sales_detail_item_available(Object count) {
    return Intl.message(
      '$count left',
      name: 'sales_detail_item_available',
      desc: '',
      args: [count],
    );
  }

  /// `was {price}`
  String sales_detail_item_list(Object price) {
    return Intl.message(
      'was $price',
      name: 'sales_detail_item_list',
      desc: '',
      args: [price],
    );
  }

  /// `Not a product`
  String get sales_detail_item_concept {
    return Intl.message(
      'Not a product',
      name: 'sales_detail_item_concept',
      desc: '',
      args: [],
    );
  }

  /// `The handover`
  String get sales_detail_handover {
    return Intl.message(
      'The handover',
      name: 'sales_detail_handover',
      desc: '',
      args: [],
    );
  }

  /// `How they get it`
  String get sales_detail_handover_mode {
    return Intl.message(
      'How they get it',
      name: 'sales_detail_handover_mode',
      desc: '',
      args: [],
    );
  }

  /// `Where it got to`
  String get sales_detail_handover_state {
    return Intl.message(
      'Where it got to',
      name: 'sales_detail_handover_state',
      desc: '',
      args: [],
    );
  }

  /// `Recorded`
  String get sales_detail_handover_at {
    return Intl.message(
      'Recorded',
      name: 'sales_detail_handover_at',
      desc: '',
      args: [],
    );
  }

  /// `Recorded by`
  String get sales_detail_handover_by {
    return Intl.message(
      'Recorded by',
      name: 'sales_detail_handover_by',
      desc: '',
      args: [],
    );
  }

  /// `Note`
  String get sales_detail_handover_note {
    return Intl.message(
      'Note',
      name: 'sales_detail_handover_note',
      desc: '',
      args: [],
    );
  }

  /// `Nobody has recorded this: it is how the sale reads, not what somebody said.`
  String get sales_detail_handover_unstored {
    return Intl.message(
      'Nobody has recorded this: it is how the sale reads, not what somebody said.',
      name: 'sales_detail_handover_unstored',
      desc: '',
      args: [],
    );
  }

  /// `There is nothing to hand over yet`
  String get sales_detail_handover_none {
    return Intl.message(
      'There is nothing to hand over yet',
      name: 'sales_detail_handover_none',
      desc: '',
      args: [],
    );
  }

  /// `The ticket has not been charged, so nothing has left the shelf for good.`
  String get sales_detail_handover_none_open {
    return Intl.message(
      'The ticket has not been charged, so nothing has left the shelf for good.',
      name: 'sales_detail_handover_none_open',
      desc: '',
      args: [],
    );
  }

  /// `Nobody has rung this up: there is no document to hand over.`
  String get sales_detail_handover_none_deal {
    return Intl.message(
      'Nobody has rung this up: there is no document to hand over.',
      name: 'sales_detail_handover_none_deal',
      desc: '',
      args: [],
    );
  }

  /// `What the shelf is keeping`
  String get sales_detail_holds {
    return Intl.message(
      'What the shelf is keeping',
      name: 'sales_detail_holds',
      desc: '',
      args: [],
    );
  }

  /// `Units held`
  String get sales_detail_held {
    return Intl.message(
      'Units held',
      name: 'sales_detail_held',
      desc: '',
      args: [],
    );
  }

  /// `Nothing is set aside for this customer.`
  String get sales_detail_holds_empty {
    return Intl.message(
      'Nothing is set aside for this customer.',
      name: 'sales_detail_holds_empty',
      desc: '',
      args: [],
    );
  }

  /// `Lapses`
  String get sales_detail_hold_expires {
    return Intl.message(
      'Lapses',
      name: 'sales_detail_hold_expires',
      desc: '',
      args: [],
    );
  }

  /// `{count} units`
  String sales_detail_hold_units(Object count) {
    return Intl.message(
      '$count units',
      name: 'sales_detail_hold_units',
      desc: '',
      args: [count],
    );
  }

  /// `Where it comes from`
  String get sales_detail_trace {
    return Intl.message(
      'Where it comes from',
      name: 'sales_detail_trace',
      desc: '',
      args: [],
    );
  }

  /// `Came in through`
  String get sales_detail_channel {
    return Intl.message(
      'Came in through',
      name: 'sales_detail_channel',
      desc: '',
      args: [],
    );
  }

  /// `Till`
  String get sales_detail_terminal {
    return Intl.message(
      'Till',
      name: 'sales_detail_terminal',
      desc: '',
      args: [],
    );
  }

  /// `Answered by`
  String get sales_detail_bot {
    return Intl.message(
      'Answered by',
      name: 'sales_detail_bot',
      desc: '',
      args: [],
    );
  }

  /// `On the number`
  String get sales_detail_address {
    return Intl.message(
      'On the number',
      name: 'sales_detail_address',
      desc: '',
      args: [],
    );
  }

  /// `Sold by`
  String get sales_detail_seller {
    return Intl.message(
      'Sold by',
      name: 'sales_detail_seller',
      desc: '',
      args: [],
    );
  }

  /// `Contact`
  String get sales_detail_contact {
    return Intl.message(
      'Contact',
      name: 'sales_detail_contact',
      desc: '',
      args: [],
    );
  }

  /// `Note on the ticket`
  String get sales_detail_note {
    return Intl.message(
      'Note on the ticket',
      name: 'sales_detail_note',
      desc: '',
      args: [],
    );
  }

  /// `At this state since`
  String get sales_detail_stage_since {
    return Intl.message(
      'At this state since',
      name: 'sales_detail_stage_since',
      desc: '',
      args: [],
    );
  }

  /// `Opened`
  String get sales_detail_opened {
    return Intl.message(
      'Opened',
      name: 'sales_detail_opened',
      desc: '',
      args: [],
    );
  }

  /// `Charged`
  String get sales_detail_closed {
    return Intl.message(
      'Charged',
      name: 'sales_detail_closed',
      desc: '',
      args: [],
    );
  }

  /// `Last movement`
  String get sales_detail_updated {
    return Intl.message(
      'Last movement',
      name: 'sales_detail_updated',
      desc: '',
      args: [],
    );
  }

  /// `Sale id`
  String get sales_detail_id {
    return Intl.message(
      'Sale id',
      name: 'sales_detail_id',
      desc: '',
      args: [],
    );
  }

  /// `Conversation`
  String get sales_detail_chat {
    return Intl.message(
      'Conversation',
      name: 'sales_detail_chat',
      desc: '',
      args: [],
    );
  }

  /// `Payment proof`
  String get sales_detail_proof {
    return Intl.message(
      'Payment proof',
      name: 'sales_detail_proof',
      desc: '',
      args: [],
    );
  }

  /// `What the customer sent to show the money went out. It is what they said and showed, not something anybody here checked.`
  String get sales_detail_proof_subtitle {
    return Intl.message(
      'What the customer sent to show the money went out. It is what they said and showed, not something anybody here checked.',
      name: 'sales_detail_proof_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Nothing has been sent for this sale yet.`
  String get sales_detail_proof_empty {
    return Intl.message(
      'Nothing has been sent for this sale yet.',
      name: 'sales_detail_proof_empty',
      desc: '',
      args: [],
    );
  }

  /// `Picture sent`
  String get sales_detail_proof_image {
    return Intl.message(
      'Picture sent',
      name: 'sales_detail_proof_image',
      desc: '',
      args: [],
    );
  }

  /// `File sent`
  String get sales_detail_proof_file {
    return Intl.message(
      'File sent',
      name: 'sales_detail_proof_file',
      desc: '',
      args: [],
    );
  }

  /// `What they wrote`
  String get sales_detail_proof_said {
    return Intl.message(
      'What they wrote',
      name: 'sales_detail_proof_said',
      desc: '',
      args: [],
    );
  }

  /// `Reference given`
  String get sales_detail_proof_reference {
    return Intl.message(
      'Reference given',
      name: 'sales_detail_proof_reference',
      desc: '',
      args: [],
    );
  }

  /// `Sent`
  String get sales_detail_proof_at {
    return Intl.message(
      'Sent',
      name: 'sales_detail_proof_at',
      desc: '',
      args: [],
    );
  }

  /// `See it full size`
  String get sales_detail_proof_open {
    return Intl.message(
      'See it full size',
      name: 'sales_detail_proof_open',
      desc: '',
      args: [],
    );
  }

  /// `Open the file`
  String get sales_detail_proof_file_open {
    return Intl.message(
      'Open the file',
      name: 'sales_detail_proof_file_open',
      desc: '',
      args: [],
    );
  }

  /// `The file could not be opened`
  String get sales_detail_proof_file_failed {
    return Intl.message(
      'The file could not be opened',
      name: 'sales_detail_proof_file_failed',
      desc: '',
      args: [],
    );
  }

  /// `A picture came and could not be stored. This is what came with it.`
  String get sales_detail_proof_lost {
    return Intl.message(
      'A picture came and could not be stored. This is what came with it.',
      name: 'sales_detail_proof_lost',
      desc: '',
      args: [],
    );
  }

  /// `{count} sent in all`
  String sales_detail_proof_count(Object count) {
    return Intl.message(
      '$count sent in all',
      name: 'sales_detail_proof_count',
      desc: '',
      args: [count],
    );
  }

  /// `Approve the sale`
  String get sales_approve_action {
    return Intl.message(
      'Approve the sale',
      name: 'sales_approve_action',
      desc: '',
      args: [],
    );
  }

  /// `Approve this payment?`
  String get sales_approve_title {
    return Intl.message(
      'Approve this payment?',
      name: 'sales_approve_title',
      desc: '',
      args: [],
    );
  }

  /// `It says the money arrived and closes the sale. Nothing here can see a bank, so this is your word on it: look at the payment proof first.`
  String get sales_approve_message {
    return Intl.message(
      'It says the money arrived and closes the sale. Nothing here can see a bank, so this is your word on it: look at the payment proof first.',
      name: 'sales_approve_message',
      desc: '',
      args: [],
    );
  }

  /// `Approve`
  String get sales_approve_confirm {
    return Intl.message(
      'Approve',
      name: 'sales_approve_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get sales_approve_cancel {
    return Intl.message(
      'Cancel',
      name: 'sales_approve_cancel',
      desc: '',
      args: [],
    );
  }

  /// `Sale approved`
  String get sales_approve_done {
    return Intl.message(
      'Sale approved',
      name: 'sales_approve_done',
      desc: '',
      args: [],
    );
  }

  /// `Lines`
  String get sales_detail_items_lines {
    return Intl.message(
      'Lines',
      name: 'sales_detail_items_lines',
      desc: '',
      args: [],
    );
  }

  /// `See the products`
  String get sales_detail_items_open {
    return Intl.message(
      'See the products',
      name: 'sales_detail_items_open',
      desc: '',
      args: [],
    );
  }

  /// `Worth checking`
  String get sales_detail_items_flags {
    return Intl.message(
      'Worth checking',
      name: 'sales_detail_items_flags',
      desc: '',
      args: [],
    );
  }

  /// `{count} said to be held, and nothing is`
  String sales_detail_items_unheld_count(Object count) {
    return Intl.message(
      '$count said to be held, and nothing is',
      name: 'sales_detail_items_unheld_count',
      desc: '',
      args: [count],
    );
  }

  /// `{count} no longer sold`
  String sales_detail_items_gone_count(Object count) {
    return Intl.message(
      '$count no longer sold',
      name: 'sales_detail_items_gone_count',
      desc: '',
      args: [count],
    );
  }

  /// `Search a product or its code`
  String get sales_detail_items_search {
    return Intl.message(
      'Search a product or its code',
      name: 'sales_detail_items_search',
      desc: '',
      args: [],
    );
  }

  /// `No line matches the search`
  String get sales_detail_items_no_match {
    return Intl.message(
      'No line matches the search',
      name: 'sales_detail_items_no_match',
      desc: '',
      args: [],
    );
  }

  /// `Street address`
  String get business_location_address {
    return Intl.message(
      'Street address',
      name: 'business_location_address',
      desc: '',
      args: [],
    );
  }

  /// `Av. Francisco de Miranda, Torre Sol, floor 3`
  String get business_location_address_hint {
    return Intl.message(
      'Av. Francisco de Miranda, Torre Sol, floor 3',
      name: 'business_location_address_hint',
      desc: '',
      args: [],
    );
  }

  /// `Landmark`
  String get business_location_landmark {
    return Intl.message(
      'Landmark',
      name: 'business_location_landmark',
      desc: '',
      args: [],
    );
  }

  /// `Across from Altamira square`
  String get business_location_landmark_hint {
    return Intl.message(
      'Across from Altamira square',
      name: 'business_location_landmark_hint',
      desc: '',
      args: [],
    );
  }

  /// `City`
  String get business_location_city {
    return Intl.message(
      'City',
      name: 'business_location_city',
      desc: '',
      args: [],
    );
  }

  /// `Caracas`
  String get business_location_city_hint {
    return Intl.message(
      'Caracas',
      name: 'business_location_city_hint',
      desc: '',
      args: [],
    );
  }

  /// `State or region`
  String get business_location_region {
    return Intl.message(
      'State or region',
      name: 'business_location_region',
      desc: '',
      args: [],
    );
  }

  /// `Miranda`
  String get business_location_region_hint {
    return Intl.message(
      'Miranda',
      name: 'business_location_region_hint',
      desc: '',
      args: [],
    );
  }

  /// `Postal code`
  String get business_location_postal_code {
    return Intl.message(
      'Postal code',
      name: 'business_location_postal_code',
      desc: '',
      args: [],
    );
  }

  /// `1060`
  String get business_location_postal_code_hint {
    return Intl.message(
      '1060',
      name: 'business_location_postal_code_hint',
      desc: '',
      args: [],
    );
  }

  /// `Country`
  String get business_location_country {
    return Intl.message(
      'Country',
      name: 'business_location_country',
      desc: '',
      args: [],
    );
  }

  /// `Where the business is registered. It also sets its clock, the payment methods it's offered and the carriers it can deliver with.`
  String get business_location_country_note {
    return Intl.message(
      'Where the business is registered. It also sets its clock, the payment methods it\'s offered and the carriers it can deliver with.',
      name: 'business_location_country_note',
      desc: '',
      args: [],
    );
  }

  /// `Street, building or the name of your business`
  String get business_location_search_hint {
    return Intl.message(
      'Street, building or the name of your business',
      name: 'business_location_search_hint',
      desc: '',
      args: [],
    );
  }

  /// `No place matches that search. Write the address in the form.`
  String get business_location_search_empty {
    return Intl.message(
      'No place matches that search. Write the address in the form.',
      name: 'business_location_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `The address search isn't answering right now. Write the address in the form.`
  String get business_location_search_failed {
    return Intl.message(
      'The address search isn\'t answering right now. Write the address in the form.',
      name: 'business_location_search_failed',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't load delivery`
  String get business_delivery_error_title {
    return Intl.message(
      'Couldn\'t load delivery',
      name: 'business_delivery_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Something went wrong. Please try again.`
  String get business_delivery_error_subtitle {
    return Intl.message(
      'Something went wrong. Please try again.',
      name: 'business_delivery_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Delivery`
  String get business_delivery_section_general {
    return Intl.message(
      'Delivery',
      name: 'business_delivery_section_general',
      desc: '',
      args: [],
    );
  }

  /// `Ways you deliver`
  String get business_delivery_section_options {
    return Intl.message(
      'Ways you deliver',
      name: 'business_delivery_section_options',
      desc: '',
      args: [],
    );
  }

  /// `Delivers to customers`
  String get business_delivery_delivers {
    return Intl.message(
      'Delivers to customers',
      name: 'business_delivery_delivers',
      desc: '',
      args: [],
    );
  }

  /// `What your assistant answers when someone asks if you deliver. While it isn't set, it never tells a customer no.`
  String get business_delivery_delivers_note {
    return Intl.message(
      'What your assistant answers when someone asks if you deliver. While it isn\'t set, it never tells a customer no.',
      name: 'business_delivery_delivers_note',
      desc: '',
      args: [],
    );
  }

  /// `Pickup at the business`
  String get business_delivery_pickup {
    return Intl.message(
      'Pickup at the business',
      name: 'business_delivery_pickup',
      desc: '',
      args: [],
    );
  }

  /// `Whether a customer can collect the order at your location.`
  String get business_delivery_pickup_note {
    return Intl.message(
      'Whether a customer can collect the order at your location.',
      name: 'business_delivery_pickup_note',
      desc: '',
      args: [],
    );
  }

  /// `Yes`
  String get business_delivery_yes {
    return Intl.message(
      'Yes',
      name: 'business_delivery_yes',
      desc: '',
      args: [],
    );
  }

  /// `No`
  String get business_delivery_no {
    return Intl.message(
      'No',
      name: 'business_delivery_no',
      desc: '',
      args: [],
    );
  }

  /// `Not set yet`
  String get business_delivery_unset {
    return Intl.message(
      'Not set yet',
      name: 'business_delivery_unset',
      desc: '',
      args: [],
    );
  }

  /// `Listing a way to deliver already counts as yes`
  String get business_delivery_unset_note {
    return Intl.message(
      'Listing a way to deliver already counts as yes',
      name: 'business_delivery_unset_note',
      desc: '',
      args: [],
    );
  }

  /// `Change the answer`
  String get business_delivery_choose {
    return Intl.message(
      'Change the answer',
      name: 'business_delivery_choose',
      desc: '',
      args: [],
    );
  }

  /// `No option matches your search`
  String get business_delivery_select_empty {
    return Intl.message(
      'No option matches your search',
      name: 'business_delivery_select_empty',
      desc: '',
      args: [],
    );
  }

  /// `Delivery areas`
  String get business_delivery_meeting {
    return Intl.message(
      'Delivery areas',
      name: 'business_delivery_meeting',
      desc: '',
      args: [],
    );
  }

  /// `What your assistant does when a customer is outside every area you drew.`
  String get business_delivery_meeting_note {
    return Intl.message(
      'What your assistant does when a customer is outside every area you drew.',
      name: 'business_delivery_meeting_note',
      desc: '',
      args: [],
    );
  }

  /// `Fixed`
  String get business_delivery_meeting_fixed {
    return Intl.message(
      'Fixed',
      name: 'business_delivery_meeting_fixed',
      desc: '',
      args: [],
    );
  }

  /// `Only delivers inside your areas`
  String get business_delivery_meeting_fixed_note {
    return Intl.message(
      'Only delivers inside your areas',
      name: 'business_delivery_meeting_fixed_note',
      desc: '',
      args: [],
    );
  }

  /// `Flexible`
  String get business_delivery_meeting_flexible {
    return Intl.message(
      'Flexible',
      name: 'business_delivery_meeting_flexible',
      desc: '',
      args: [],
    );
  }

  /// `Agrees with the customer on a meeting spot, the nearest one your areas reach`
  String get business_delivery_meeting_flexible_note {
    return Intl.message(
      'Agrees with the customer on a meeting spot, the nearest one your areas reach',
      name: 'business_delivery_meeting_flexible_note',
      desc: '',
      args: [],
    );
  }

  /// `Delivery note`
  String get business_delivery_notes {
    return Intl.message(
      'Delivery note',
      name: 'business_delivery_notes',
      desc: '',
      args: [],
    );
  }

  /// `One sentence about delivery in general, in your own words.`
  String get business_delivery_notes_note {
    return Intl.message(
      'One sentence about delivery in general, in your own words.',
      name: 'business_delivery_notes_note',
      desc: '',
      args: [],
    );
  }

  /// `Orders placed before 2 pm leave the same day`
  String get business_delivery_notes_hint {
    return Intl.message(
      'Orders placed before 2 pm leave the same day',
      name: 'business_delivery_notes_hint',
      desc: '',
      args: [],
    );
  }

  /// `Add a way to deliver`
  String get business_delivery_add {
    return Intl.message(
      'Add a way to deliver',
      name: 'business_delivery_add',
      desc: '',
      args: [],
    );
  }

  /// `Way to deliver`
  String get business_delivery_empty {
    return Intl.message(
      'Way to deliver',
      name: 'business_delivery_empty',
      desc: '',
      args: [],
    );
  }

  /// `Nothing yet. Add your own riders, a delivery app or a parcel carrier.`
  String get business_delivery_empty_note {
    return Intl.message(
      'Nothing yet. Add your own riders, a delivery app or a parcel carrier.',
      name: 'business_delivery_empty_note',
      desc: '',
      args: [],
    );
  }

  /// `Delivery is turned off, so none of these is offered. They stay saved for when you turn it back on.`
  String get business_delivery_off_note {
    return Intl.message(
      'Delivery is turned off, so none of these is offered. They stay saved for when you turn it back on.',
      name: 'business_delivery_off_note',
      desc: '',
      args: [],
    );
  }

  /// `Own riders`
  String get business_delivery_own_default {
    return Intl.message(
      'Own riders',
      name: 'business_delivery_own_default',
      desc: '',
      args: [],
    );
  }

  /// `Own riders`
  String get business_delivery_mode_own {
    return Intl.message(
      'Own riders',
      name: 'business_delivery_mode_own',
      desc: '',
      args: [],
    );
  }

  /// `Your business's own couriers carry the order`
  String get business_delivery_mode_own_note {
    return Intl.message(
      'Your business\'s own couriers carry the order',
      name: 'business_delivery_mode_own_note',
      desc: '',
      args: [],
    );
  }

  /// `Delivery app`
  String get business_delivery_mode_platform {
    return Intl.message(
      'Delivery app',
      name: 'business_delivery_mode_platform',
      desc: '',
      args: [],
    );
  }

  /// `An app like PedidosYa, Yummy or Rappi carries it`
  String get business_delivery_mode_platform_note {
    return Intl.message(
      'An app like PedidosYa, Yummy or Rappi carries it',
      name: 'business_delivery_mode_platform_note',
      desc: '',
      args: [],
    );
  }

  /// `Parcel carrier`
  String get business_delivery_mode_courier {
    return Intl.message(
      'Parcel carrier',
      name: 'business_delivery_mode_courier',
      desc: '',
      args: [],
    );
  }

  /// `A shipping company like Zoom, MRW or DHL sends it`
  String get business_delivery_mode_courier_note {
    return Intl.message(
      'A shipping company like Zoom, MRW or DHL sends it',
      name: 'business_delivery_mode_courier_note',
      desc: '',
      args: [],
    );
  }

  /// `Local`
  String get business_delivery_coverage_local {
    return Intl.message(
      'Local',
      name: 'business_delivery_coverage_local',
      desc: '',
      args: [],
    );
  }

  /// `Some areas, or a radius around your location`
  String get business_delivery_coverage_local_note {
    return Intl.message(
      'Some areas, or a radius around your location',
      name: 'business_delivery_coverage_local_note',
      desc: '',
      args: [],
    );
  }

  /// `National`
  String get business_delivery_coverage_national {
    return Intl.message(
      'National',
      name: 'business_delivery_coverage_national',
      desc: '',
      args: [],
    );
  }

  /// `Anywhere in the country`
  String get business_delivery_coverage_national_note {
    return Intl.message(
      'Anywhere in the country',
      name: 'business_delivery_coverage_national_note',
      desc: '',
      args: [],
    );
  }

  /// `International`
  String get business_delivery_coverage_international {
    return Intl.message(
      'International',
      name: 'business_delivery_coverage_international',
      desc: '',
      args: [],
    );
  }

  /// `To other countries too`
  String get business_delivery_coverage_international_note {
    return Intl.message(
      'To other countries too',
      name: 'business_delivery_coverage_international_note',
      desc: '',
      args: [],
    );
  }

  /// `Free`
  String get business_delivery_fee_free {
    return Intl.message(
      'Free',
      name: 'business_delivery_fee_free',
      desc: '',
      args: [],
    );
  }

  /// `Price varies`
  String get business_delivery_fee_varies {
    return Intl.message(
      'Price varies',
      name: 'business_delivery_fee_varies',
      desc: '',
      args: [],
    );
  }

  /// `Free from {amount}`
  String business_delivery_free_from(Object amount) {
    return Intl.message(
      'Free from $amount',
      name: 'business_delivery_free_from',
      desc: '',
      args: [amount],
    );
  }

  /// `Within {km} km`
  String business_delivery_radius(Object km) {
    return Intl.message(
      'Within $km km',
      name: 'business_delivery_radius',
      desc: '',
      args: [km],
    );
  }

  /// `+{count} more`
  String business_delivery_zones_more(Object count) {
    return Intl.message(
      '+$count more',
      name: 'business_delivery_zones_more',
      desc: '',
      args: [count],
    );
  }

  /// `{count} min`
  String business_delivery_eta_minutes(Object count) {
    return Intl.message(
      '$count min',
      name: 'business_delivery_eta_minutes',
      desc: '',
      args: [count],
    );
  }

  /// `{count} h`
  String business_delivery_eta_hours(Object count) {
    return Intl.message(
      '$count h',
      name: 'business_delivery_eta_hours',
      desc: '',
      args: [count],
    );
  }

  /// `{count, plural, =1{1 day} other{{count} days}}`
  String business_delivery_eta_days(num count) {
    return Intl.plural(
      count,
      one: '1 day',
      other: '$count days',
      name: 'business_delivery_eta_days',
      desc: '',
      args: [count],
    );
  }

  /// `{from}–{to} min`
  String business_delivery_eta_range_minutes(Object from, Object to) {
    return Intl.message(
      '$from–$to min',
      name: 'business_delivery_eta_range_minutes',
      desc: '',
      args: [from, to],
    );
  }

  /// `{from}–{to} h`
  String business_delivery_eta_range_hours(Object from, Object to) {
    return Intl.message(
      '$from–$to h',
      name: 'business_delivery_eta_range_hours',
      desc: '',
      args: [from, to],
    );
  }

  /// `{from}–{to} days`
  String business_delivery_eta_range_days(Object from, Object to) {
    return Intl.message(
      '$from–$to days',
      name: 'business_delivery_eta_range_days',
      desc: '',
      args: [from, to],
    );
  }

  /// `From {time}`
  String business_delivery_eta_from(Object time) {
    return Intl.message(
      'From $time',
      name: 'business_delivery_eta_from',
      desc: '',
      args: [time],
    );
  }

  /// `Up to {time}`
  String business_delivery_eta_up_to(Object time) {
    return Intl.message(
      'Up to $time',
      name: 'business_delivery_eta_up_to',
      desc: '',
      args: [time],
    );
  }

  /// `Minutes`
  String get business_delivery_unit_minutes {
    return Intl.message(
      'Minutes',
      name: 'business_delivery_unit_minutes',
      desc: '',
      args: [],
    );
  }

  /// `Hours`
  String get business_delivery_unit_hours {
    return Intl.message(
      'Hours',
      name: 'business_delivery_unit_hours',
      desc: '',
      args: [],
    );
  }

  /// `Days`
  String get business_delivery_unit_days {
    return Intl.message(
      'Days',
      name: 'business_delivery_unit_days',
      desc: '',
      args: [],
    );
  }

  /// `Remove`
  String get business_delivery_remove {
    return Intl.message(
      'Remove',
      name: 'business_delivery_remove',
      desc: '',
      args: [],
    );
  }

  /// `Remove this way to deliver?`
  String get business_delivery_remove_title {
    return Intl.message(
      'Remove this way to deliver?',
      name: 'business_delivery_remove_title',
      desc: '',
      args: [],
    );
  }

  /// `{name} stops being offered to your customers. Removing the last one doesn't change whether your business says it delivers.`
  String business_delivery_remove_message(Object name) {
    return Intl.message(
      '$name stops being offered to your customers. Removing the last one doesn\'t change whether your business says it delivers.',
      name: 'business_delivery_remove_message',
      desc: '',
      args: [name],
    );
  }

  /// `New way to deliver`
  String get business_delivery_create_title {
    return Intl.message(
      'New way to deliver',
      name: 'business_delivery_create_title',
      desc: '',
      args: [],
    );
  }

  /// `Edit way to deliver`
  String get business_delivery_edit_title {
    return Intl.message(
      'Edit way to deliver',
      name: 'business_delivery_edit_title',
      desc: '',
      args: [],
    );
  }

  /// `Who carries the order, how far it goes, what it costs and how long it takes. It's what your customers are told when they ask.`
  String get business_delivery_form_subtitle {
    return Intl.message(
      'Who carries the order, how far it goes, what it costs and how long it takes. It\'s what your customers are told when they ask.',
      name: 'business_delivery_form_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `The list of apps and carriers couldn't be loaded. You can still write the name of yours.`
  String get business_delivery_no_catalog {
    return Intl.message(
      'The list of apps and carriers couldn\'t be loaded. You can still write the name of yours.',
      name: 'business_delivery_no_catalog',
      desc: '',
      args: [],
    );
  }

  /// `Your business has no country set, so only carriers that work everywhere are listed. Set it in Settings.`
  String get business_delivery_no_country {
    return Intl.message(
      'Your business has no country set, so only carriers that work everywhere are listed. Set it in Settings.',
      name: 'business_delivery_no_country',
      desc: '',
      args: [],
    );
  }

  /// `optional`
  String get business_delivery_optional {
    return Intl.message(
      'optional',
      name: 'business_delivery_optional',
      desc: '',
      args: [],
    );
  }

  /// `Who carries it`
  String get business_delivery_mode {
    return Intl.message(
      'Who carries it',
      name: 'business_delivery_mode',
      desc: '',
      args: [],
    );
  }

  /// `Pick who carries the order`
  String get business_delivery_mode_placeholder {
    return Intl.message(
      'Pick who carries the order',
      name: 'business_delivery_mode_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Company`
  String get business_delivery_provider {
    return Intl.message(
      'Company',
      name: 'business_delivery_provider',
      desc: '',
      args: [],
    );
  }

  /// `Pick the app or the carrier`
  String get business_delivery_provider_placeholder {
    return Intl.message(
      'Pick the app or the carrier',
      name: 'business_delivery_provider_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Another one`
  String get business_delivery_provider_other {
    return Intl.message(
      'Another one',
      name: 'business_delivery_provider_other',
      desc: '',
      args: [],
    );
  }

  /// `Not in the list: write its name below`
  String get business_delivery_provider_other_note {
    return Intl.message(
      'Not in the list: write its name below',
      name: 'business_delivery_provider_other_note',
      desc: '',
      args: [],
    );
  }

  /// `Works everywhere`
  String get business_delivery_provider_global {
    return Intl.message(
      'Works everywhere',
      name: 'business_delivery_provider_global',
      desc: '',
      args: [],
    );
  }

  /// `Name`
  String get business_delivery_label {
    return Intl.message(
      'Name',
      name: 'business_delivery_label',
      desc: '',
      args: [],
    );
  }

  /// `Company name`
  String get business_delivery_label_carrier {
    return Intl.message(
      'Company name',
      name: 'business_delivery_label_carrier',
      desc: '',
      args: [],
    );
  }

  /// `Downtown riders`
  String get business_delivery_label_hint {
    return Intl.message(
      'Downtown riders',
      name: 'business_delivery_label_hint',
      desc: '',
      args: [],
    );
  }

  /// `Pick the company that carries it, or write its name.`
  String get business_delivery_carrier_required {
    return Intl.message(
      'Pick the company that carries it, or write its name.',
      name: 'business_delivery_carrier_required',
      desc: '',
      args: [],
    );
  }

  /// `How far it reaches`
  String get business_delivery_coverage {
    return Intl.message(
      'How far it reaches',
      name: 'business_delivery_coverage',
      desc: '',
      args: [],
    );
  }

  /// `Pick how far it reaches`
  String get business_delivery_coverage_placeholder {
    return Intl.message(
      'Pick how far it reaches',
      name: 'business_delivery_coverage_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `{coverage}, unless you pick another`
  String business_delivery_coverage_default(Object coverage) {
    return Intl.message(
      '$coverage, unless you pick another',
      name: 'business_delivery_coverage_default',
      desc: '',
      args: [coverage],
    );
  }

  /// `Radius in km`
  String get business_delivery_radius_title {
    return Intl.message(
      'Radius in km',
      name: 'business_delivery_radius_title',
      desc: '',
      args: [],
    );
  }

  /// `5`
  String get business_delivery_radius_hint {
    return Intl.message(
      '5',
      name: 'business_delivery_radius_hint',
      desc: '',
      args: [],
    );
  }

  /// `The radius goes in kilometres, above 0 and up to 1000.`
  String get business_delivery_radius_invalid {
    return Intl.message(
      'The radius goes in kilometres, above 0 and up to 1000.',
      name: 'business_delivery_radius_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Zones`
  String get business_delivery_zones {
    return Intl.message(
      'Zones',
      name: 'business_delivery_zones',
      desc: '',
      args: [],
    );
  }

  /// `The areas it reaches, as your customers call them. A zone can have a price of its own.`
  String get business_delivery_zones_note {
    return Intl.message(
      'The areas it reaches, as your customers call them. A zone can have a price of its own.',
      name: 'business_delivery_zones_note',
      desc: '',
      args: [],
    );
  }

  /// `Zone`
  String get business_delivery_zone_name {
    return Intl.message(
      'Zone',
      name: 'business_delivery_zone_name',
      desc: '',
      args: [],
    );
  }

  /// `Own price`
  String get business_delivery_zone_fee {
    return Intl.message(
      'Own price',
      name: 'business_delivery_zone_fee',
      desc: '',
      args: [],
    );
  }

  /// `Add zone`
  String get business_delivery_zone_add {
    return Intl.message(
      'Add zone',
      name: 'business_delivery_zone_add',
      desc: '',
      args: [],
    );
  }

  /// `Remove zone`
  String get business_delivery_zone_remove {
    return Intl.message(
      'Remove zone',
      name: 'business_delivery_zone_remove',
      desc: '',
      args: [],
    );
  }

  /// `Every zone needs a name of up to 80 characters, and its own price has to be an amount.`
  String get business_delivery_zone_invalid {
    return Intl.message(
      'Every zone needs a name of up to 80 characters, and its own price has to be an amount.',
      name: 'business_delivery_zone_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Price`
  String get business_delivery_fee {
    return Intl.message(
      'Price',
      name: 'business_delivery_fee',
      desc: '',
      args: [],
    );
  }

  /// `In {currency}. Empty if it varies, 0 if it's free`
  String business_delivery_fee_hint(Object currency) {
    return Intl.message(
      'In $currency. Empty if it varies, 0 if it\'s free',
      name: 'business_delivery_fee_hint',
      desc: '',
      args: [currency],
    );
  }

  /// `Free from`
  String get business_delivery_free_from_title {
    return Intl.message(
      'Free from',
      name: 'business_delivery_free_from_title',
      desc: '',
      args: [],
    );
  }

  /// `Order total from which it's free`
  String get business_delivery_free_from_hint {
    return Intl.message(
      'Order total from which it\'s free',
      name: 'business_delivery_free_from_hint',
      desc: '',
      args: [],
    );
  }

  /// `Write amounts with digits and up to two decimals, without thousands separators.`
  String get business_delivery_amount_invalid {
    return Intl.message(
      'Write amounts with digits and up to two decimals, without thousands separators.',
      name: 'business_delivery_amount_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Delivery time`
  String get business_delivery_eta {
    return Intl.message(
      'Delivery time',
      name: 'business_delivery_eta',
      desc: '',
      args: [],
    );
  }

  /// `From`
  String get business_delivery_eta_min {
    return Intl.message(
      'From',
      name: 'business_delivery_eta_min',
      desc: '',
      args: [],
    );
  }

  /// `To`
  String get business_delivery_eta_max {
    return Intl.message(
      'To',
      name: 'business_delivery_eta_max',
      desc: '',
      args: [],
    );
  }

  /// `Unit`
  String get business_delivery_eta_unit {
    return Intl.message(
      'Unit',
      name: 'business_delivery_eta_unit',
      desc: '',
      args: [],
    );
  }

  /// `The delivery time goes from 1 minute to 30 days, and the first figure can't be larger than the second.`
  String get business_delivery_eta_invalid {
    return Intl.message(
      'The delivery time goes from 1 minute to 30 days, and the first figure can\'t be larger than the second.',
      name: 'business_delivery_eta_invalid',
      desc: '',
      args: [],
    );
  }

  /// `Notes`
  String get business_delivery_option_notes {
    return Intl.message(
      'Notes',
      name: 'business_delivery_option_notes',
      desc: '',
      args: [],
    );
  }

  /// `Cash on delivery`
  String get business_delivery_option_notes_hint {
    return Intl.message(
      'Cash on delivery',
      name: 'business_delivery_option_notes_hint',
      desc: '',
      args: [],
    );
  }

  /// `Messages`
  String get messages {
    return Intl.message(
      'Messages',
      name: 'messages',
      desc: '',
      args: [],
    );
  }

  /// `All`
  String get messages_filter_all {
    return Intl.message(
      'All',
      name: 'messages_filter_all',
      desc: '',
      args: [],
    );
  }

  /// `Unanswered`
  String get messages_filter_unanswered {
    return Intl.message(
      'Unanswered',
      name: 'messages_filter_unanswered',
      desc: '',
      args: [],
    );
  }

  /// `Attention`
  String get messages_filter_attention {
    return Intl.message(
      'Attention',
      name: 'messages_filter_attention',
      desc: '',
      args: [],
    );
  }

  /// `Mine`
  String get messages_filter_mine {
    return Intl.message(
      'Mine',
      name: 'messages_filter_mine',
      desc: '',
      args: [],
    );
  }

  /// `With a person`
  String get messages_filter_paused {
    return Intl.message(
      'With a person',
      name: 'messages_filter_paused',
      desc: '',
      args: [],
    );
  }

  /// `{count} conversations`
  String messages_count(Object count) {
    return Intl.message(
      '$count conversations',
      name: 'messages_count',
      desc: '',
      args: [count],
    );
  }

  /// `{count} new movements, refresh`
  String messages_pending(Object count) {
    return Intl.message(
      '$count new movements, refresh',
      name: 'messages_pending',
      desc: '',
      args: [count],
    );
  }

  /// `More conversations could not be read. Try again`
  String get messages_more_failed {
    return Intl.message(
      'More conversations could not be read. Try again',
      name: 'messages_more_failed',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get messages_retry {
    return Intl.message(
      'Try again',
      name: 'messages_retry',
      desc: '',
      args: [],
    );
  }

  /// `The conversations could not be read`
  String get messages_error_title {
    return Intl.message(
      'The conversations could not be read',
      name: 'messages_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Check the connection and try again.`
  String get messages_error_subtitle {
    return Intl.message(
      'Check the connection and try again.',
      name: 'messages_error_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `No conversations yet`
  String get messages_empty_title {
    return Intl.message(
      'No conversations yet',
      name: 'messages_empty_title',
      desc: '',
      args: [],
    );
  }

  /// `When a customer writes to one of your numbers, the conversation shows up here.`
  String get messages_empty_subtitle {
    return Intl.message(
      'When a customer writes to one of your numbers, the conversation shows up here.',
      name: 'messages_empty_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Nothing here`
  String get messages_empty_filter_title {
    return Intl.message(
      'Nothing here',
      name: 'messages_empty_filter_title',
      desc: '',
      args: [],
    );
  }

  /// `No conversation matches this tab or the search.`
  String get messages_empty_filter_subtitle {
    return Intl.message(
      'No conversation matches this tab or the search.',
      name: 'messages_empty_filter_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Choose a conversation`
  String get messages_select_title {
    return Intl.message(
      'Choose a conversation',
      name: 'messages_select_title',
      desc: '',
      args: [],
    );
  }

  /// `Its messages open on this side.`
  String get messages_select_subtitle {
    return Intl.message(
      'Its messages open on this side.',
      name: 'messages_select_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `The conversation could not be read`
  String get messages_thread_error_title {
    return Intl.message(
      'The conversation could not be read',
      name: 'messages_thread_error_title',
      desc: '',
      args: [],
    );
  }

  /// `No messages in this conversation yet`
  String get messages_thread_empty {
    return Intl.message(
      'No messages in this conversation yet',
      name: 'messages_thread_empty',
      desc: '',
      args: [],
    );
  }

  /// `Load older messages`
  String get messages_older {
    return Intl.message(
      'Load older messages',
      name: 'messages_older',
      desc: '',
      args: [],
    );
  }

  /// `Show earlier conversations`
  String get messages_all_sessions {
    return Intl.message(
      'Show earlier conversations',
      name: 'messages_all_sessions',
      desc: '',
      args: [],
    );
  }

  /// `Show only this conversation`
  String get messages_this_session {
    return Intl.message(
      'Show only this conversation',
      name: 'messages_this_session',
      desc: '',
      args: [],
    );
  }

  /// `just now`
  String get messages_wait_now {
    return Intl.message(
      'just now',
      name: 'messages_wait_now',
      desc: '',
      args: [],
    );
  }

  /// `{count} min`
  String messages_wait_minutes(Object count) {
    return Intl.message(
      '$count min',
      name: 'messages_wait_minutes',
      desc: '',
      args: [count],
    );
  }

  /// `{count} h`
  String messages_wait_hours(Object count) {
    return Intl.message(
      '$count h',
      name: 'messages_wait_hours',
      desc: '',
      args: [count],
    );
  }

  /// `{count} d`
  String messages_wait_days(Object count) {
    return Intl.message(
      '$count d',
      name: 'messages_wait_days',
      desc: '',
      args: [count],
    );
  }

  /// `Waiting {time}`
  String messages_waiting(Object time) {
    return Intl.message(
      'Waiting $time',
      name: 'messages_waiting',
      desc: '',
      args: [time],
    );
  }

  /// `Assistant`
  String get messages_author_bot {
    return Intl.message(
      'Assistant',
      name: 'messages_author_bot',
      desc: '',
      args: [],
    );
  }

  /// `Automatic message`
  String get messages_author_system {
    return Intl.message(
      'Automatic message',
      name: 'messages_author_system',
      desc: '',
      args: [],
    );
  }

  /// `Team`
  String get messages_author_team {
    return Intl.message(
      'Team',
      name: 'messages_author_team',
      desc: '',
      args: [],
    );
  }

  /// `Not sent`
  String get messages_status_failed {
    return Intl.message(
      'Not sent',
      name: 'messages_status_failed',
      desc: '',
      args: [],
    );
  }

  /// `Queued`
  String get messages_status_queued {
    return Intl.message(
      'Queued',
      name: 'messages_status_queued',
      desc: '',
      args: [],
    );
  }

  /// `Image`
  String get messages_image {
    return Intl.message(
      'Image',
      name: 'messages_image',
      desc: '',
      args: [],
    );
  }

  /// `Audio`
  String get messages_audio {
    return Intl.message(
      'Audio',
      name: 'messages_audio',
      desc: '',
      args: [],
    );
  }

  /// `Write a reply`
  String get messages_composer_placeholder {
    return Intl.message(
      'Write a reply',
      name: 'messages_composer_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `Replying takes the conversation from the assistant for 24 hours.`
  String get messages_composer_hint {
    return Intl.message(
      'Replying takes the conversation from the assistant for 24 hours.',
      name: 'messages_composer_hint',
      desc: '',
      args: [],
    );
  }

  /// `Send`
  String get messages_send {
    return Intl.message(
      'Send',
      name: 'messages_send',
      desc: '',
      args: [],
    );
  }

  /// `Message queued`
  String get messages_queued_title {
    return Intl.message(
      'Message queued',
      name: 'messages_queued_title',
      desc: '',
      args: [],
    );
  }

  /// `The phone of this number is offline: the message leaves when it reconnects.`
  String get messages_queued_subtitle {
    return Intl.message(
      'The phone of this number is offline: the message leaves when it reconnects.',
      name: 'messages_queued_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `The assistant is answering`
  String get messages_bot_active {
    return Intl.message(
      'The assistant is answering',
      name: 'messages_bot_active',
      desc: '',
      args: [],
    );
  }

  /// `The assistant is off on this number. Turn it on in the channel settings.`
  String get messages_bot_disabled {
    return Intl.message(
      'The assistant is off on this number. Turn it on in the channel settings.',
      name: 'messages_bot_disabled',
      desc: '',
      args: [],
    );
  }

  /// `Attended by {name}`
  String messages_bot_paused_by(Object name) {
    return Intl.message(
      'Attended by $name',
      name: 'messages_bot_paused_by',
      desc: '',
      args: [name],
    );
  }

  /// `Attended by a person`
  String get messages_bot_paused {
    return Intl.message(
      'Attended by a person',
      name: 'messages_bot_paused',
      desc: '',
      args: [],
    );
  }

  /// `until {date}`
  String messages_bot_until(Object date) {
    return Intl.message(
      'until $date',
      name: 'messages_bot_until',
      desc: '',
      args: [date],
    );
  }

  /// `Take over`
  String get messages_take {
    return Intl.message(
      'Take over',
      name: 'messages_take',
      desc: '',
      args: [],
    );
  }

  /// `Return to the assistant`
  String get messages_return {
    return Intl.message(
      'Return to the assistant',
      name: 'messages_return',
      desc: '',
      args: [],
    );
  }

  /// `For 30 minutes`
  String get messages_take_30m {
    return Intl.message(
      'For 30 minutes',
      name: 'messages_take_30m',
      desc: '',
      args: [],
    );
  }

  /// `For 2 hours`
  String get messages_take_2h {
    return Intl.message(
      'For 2 hours',
      name: 'messages_take_2h',
      desc: '',
      args: [],
    );
  }

  /// `For 24 hours`
  String get messages_take_24h {
    return Intl.message(
      'For 24 hours',
      name: 'messages_take_24h',
      desc: '',
      args: [],
    );
  }

  /// `Until I return it`
  String get messages_take_manual {
    return Intl.message(
      'Until I return it',
      name: 'messages_take_manual',
      desc: '',
      args: [],
    );
  }

  /// `Assign`
  String get messages_assign {
    return Intl.message(
      'Assign',
      name: 'messages_assign',
      desc: '',
      args: [],
    );
  }

  /// `Assigned to {name}`
  String messages_assigned_to(Object name) {
    return Intl.message(
      'Assigned to $name',
      name: 'messages_assigned_to',
      desc: '',
      args: [name],
    );
  }

  /// `Nobody assigned`
  String get messages_unassigned {
    return Intl.message(
      'Nobody assigned',
      name: 'messages_unassigned',
      desc: '',
      args: [],
    );
  }

  /// `Remove the assignment`
  String get messages_unassign {
    return Intl.message(
      'Remove the assignment',
      name: 'messages_unassign',
      desc: '',
      args: [],
    );
  }

  /// `More options`
  String get messages_options {
    return Intl.message(
      'More options',
      name: 'messages_options',
      desc: '',
      args: [],
    );
  }

  /// `Mark as sold`
  String get messages_mark_sold {
    return Intl.message(
      'Mark as sold',
      name: 'messages_mark_sold',
      desc: '',
      args: [],
    );
  }

  /// `Mark as ended`
  String get messages_mark_ended {
    return Intl.message(
      'Mark as ended',
      name: 'messages_mark_ended',
      desc: '',
      args: [],
    );
  }

  /// `Undo the manual state`
  String get messages_undo_stage {
    return Intl.message(
      'Undo the manual state',
      name: 'messages_undo_stage',
      desc: '',
      args: [],
    );
  }

  /// `Mark as read`
  String get messages_mark_read {
    return Intl.message(
      'Mark as read',
      name: 'messages_mark_read',
      desc: '',
      args: [],
    );
  }

  /// `Marked as read`
  String get messages_marked_read {
    return Intl.message(
      'Marked as read',
      name: 'messages_marked_read',
      desc: '',
      args: [],
    );
  }

  /// `Mark this conversation as sold?`
  String get messages_sold_confirm_title {
    return Intl.message(
      'Mark this conversation as sold?',
      name: 'messages_sold_confirm_title',
      desc: '',
      args: [],
    );
  }

  /// `It confirms the payment and sends the customer the confirmation of their purchase.`
  String get messages_sold_confirm_message {
    return Intl.message(
      'It confirms the payment and sends the customer the confirmation of their purchase.',
      name: 'messages_sold_confirm_message',
      desc: '',
      args: [],
    );
  }

  /// `Confirm`
  String get messages_confirm {
    return Intl.message(
      'Confirm',
      name: 'messages_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Cancel`
  String get messages_cancel {
    return Intl.message(
      'Cancel',
      name: 'messages_cancel',
      desc: '',
      args: [],
    );
  }

  /// `The assistant failed to answer`
  String get messages_attention_failure {
    return Intl.message(
      'The assistant failed to answer',
      name: 'messages_attention_failure',
      desc: '',
      args: [],
    );
  }

  /// `The customer received a cut-off message`
  String get messages_attention_partial {
    return Intl.message(
      'The customer received a cut-off message',
      name: 'messages_attention_partial',
      desc: '',
      args: [],
    );
  }

  /// `The assistant promised to confirm something`
  String get messages_attention_question {
    return Intl.message(
      'The assistant promised to confirm something',
      name: 'messages_attention_question',
      desc: '',
      args: [],
    );
  }

  /// `The customer wants to pay and the channel has no account set up`
  String get messages_attention_payment {
    return Intl.message(
      'The customer wants to pay and the channel has no account set up',
      name: 'messages_attention_payment',
      desc: '',
      args: [],
    );
  }

  /// `The customer could not be told their sale was approved`
  String get messages_attention_confirmation {
    return Intl.message(
      'The customer could not be told their sale was approved',
      name: 'messages_attention_confirmation',
      desc: '',
      args: [],
    );
  }

  /// `Work for a person`
  String get messages_attention_pending {
    return Intl.message(
      'Work for a person',
      name: 'messages_attention_pending',
      desc: '',
      args: [],
    );
  }

  /// `+{count} more`
  String messages_attention_more(Object count) {
    return Intl.message(
      '+$count more',
      name: 'messages_attention_more',
      desc: '',
      args: [count],
    );
  }

  /// `Mark as resolved`
  String get messages_resolve {
    return Intl.message(
      'Mark as resolved',
      name: 'messages_resolve',
      desc: '',
      args: [],
    );
  }

  /// `The assistant could not answer a customer`
  String get messages_notice_failure_title {
    return Intl.message(
      'The assistant could not answer a customer',
      name: 'messages_notice_failure_title',
      desc: '',
      args: [],
    );
  }

  /// `A conversation needs a person`
  String get messages_notice_pending_title {
    return Intl.message(
      'A conversation needs a person',
      name: 'messages_notice_pending_title',
      desc: '',
      args: [],
    );
  }

  /// `{name} is waiting for an answer`
  String messages_notice_waiting_title(Object name) {
    return Intl.message(
      '$name is waiting for an answer',
      name: 'messages_notice_waiting_title',
      desc: '',
      args: [name],
    );
  }

  /// `{name} was assigned to you`
  String messages_notice_assigned(Object name) {
    return Intl.message(
      '$name was assigned to you',
      name: 'messages_notice_assigned',
      desc: '',
      args: [name],
    );
  }

  /// `Since {date}`
  String messages_tag_since(Object date) {
    return Intl.message(
      'Since $date',
      name: 'messages_tag_since',
      desc: '',
      args: [date],
    );
  }

  /// `Tickets: {codes}`
  String messages_tag_tickets(Object codes) {
    return Intl.message(
      'Tickets: $codes',
      name: 'messages_tag_tickets',
      desc: '',
      args: [codes],
    );
  }

  /// `AI cost`
  String get messages_usage {
    return Intl.message(
      'AI cost',
      name: 'messages_usage',
      desc: '',
      args: [],
    );
  }

  /// `AI cost of this session`
  String get messages_usage_title {
    return Intl.message(
      'AI cost of this session',
      name: 'messages_usage_title',
      desc: '',
      args: [],
    );
  }

  /// `In USD, as the providers billed every model that ran for this session. The safety check before each burst is billed to the company's day, not here.`
  String get messages_usage_note {
    return Intl.message(
      'In USD, as the providers billed every model that ran for this session. The safety check before each burst is billed to the company\'s day, not here.',
      name: 'messages_usage_note',
      desc: '',
      args: [],
    );
  }

  /// `Spent`
  String get messages_usage_cost {
    return Intl.message(
      'Spent',
      name: 'messages_usage_cost',
      desc: '',
      args: [],
    );
  }

  /// `Tokens`
  String get messages_usage_tokens {
    return Intl.message(
      'Tokens',
      name: 'messages_usage_tokens',
      desc: '',
      args: [],
    );
  }

  /// `Model calls`
  String get messages_usage_requests {
    return Intl.message(
      'Model calls',
      name: 'messages_usage_requests',
      desc: '',
      args: [],
    );
  }

  /// `Tokens`
  String get messages_usage_tokens_title {
    return Intl.message(
      'Tokens',
      name: 'messages_usage_tokens_title',
      desc: '',
      args: [],
    );
  }

  /// `Input`
  String get messages_usage_input {
    return Intl.message(
      'Input',
      name: 'messages_usage_input',
      desc: '',
      args: [],
    );
  }

  /// `Includes the instructions, tools and history resent on every round`
  String get messages_usage_input_hint {
    return Intl.message(
      'Includes the instructions, tools and history resent on every round',
      name: 'messages_usage_input_hint',
      desc: '',
      args: [],
    );
  }

  /// `From the provider's cache`
  String get messages_usage_cached {
    return Intl.message(
      'From the provider\'s cache',
      name: 'messages_usage_cached',
      desc: '',
      args: [],
    );
  }

  /// `Part of the input, charged at the full rate`
  String get messages_usage_cached_hint {
    return Intl.message(
      'Part of the input, charged at the full rate',
      name: 'messages_usage_cached_hint',
      desc: '',
      args: [],
    );
  }

  /// `Output`
  String get messages_usage_output {
    return Intl.message(
      'Output',
      name: 'messages_usage_output',
      desc: '',
      args: [],
    );
  }

  /// `Includes the reasoning the model spent`
  String get messages_usage_output_hint {
    return Intl.message(
      'Includes the reasoning the model spent',
      name: 'messages_usage_output_hint',
      desc: '',
      args: [],
    );
  }

  /// `Where it went`
  String get messages_usage_areas_title {
    return Intl.message(
      'Where it went',
      name: 'messages_usage_areas_title',
      desc: '',
      args: [],
    );
  }

  /// `Replies`
  String get messages_usage_area_replies {
    return Intl.message(
      'Replies',
      name: 'messages_usage_area_replies',
      desc: '',
      args: [],
    );
  }

  /// `Routing and summaries`
  String get messages_usage_area_routing {
    return Intl.message(
      'Routing and summaries',
      name: 'messages_usage_area_routing',
      desc: '',
      args: [],
    );
  }

  /// `Images and voice notes`
  String get messages_usage_area_media {
    return Intl.message(
      'Images and voice notes',
      name: 'messages_usage_area_media',
      desc: '',
      args: [],
    );
  }

  /// `Web research`
  String get messages_usage_area_research {
    return Intl.message(
      'Web research',
      name: 'messages_usage_area_research',
      desc: '',
      args: [],
    );
  }

  /// `Catalog searches`
  String get messages_usage_area_embeddings {
    return Intl.message(
      'Catalog searches',
      name: 'messages_usage_area_embeddings',
      desc: '',
      args: [],
    );
  }

  /// `{requests} calls · {input} in · {output} out`
  String messages_usage_area_line(
      Object requests, Object input, Object output) {
    return Intl.message(
      '$requests calls · $input in · $output out',
      name: 'messages_usage_area_line',
      desc: '',
      args: [requests, input, output],
    );
  }

  /// `No model ran in this session: people answered it.`
  String get messages_usage_none {
    return Intl.message(
      'No model ran in this session: people answered it.',
      name: 'messages_usage_none',
      desc: '',
      args: [],
    );
  }

  /// `The cost of this session could not be read.`
  String get messages_usage_unavailable {
    return Intl.message(
      'The cost of this session could not be read.',
      name: 'messages_usage_unavailable',
      desc: '',
      args: [],
    );
  }

  /// `Welcome, {name}`
  String welcome_title(Object name) {
    return Intl.message(
      'Welcome, $name',
      name: 'welcome_title',
      desc: '',
      args: [name],
    );
  }

  /// `Lyra works around a company. Tell us how you want to start: you can change your mind later.`
  String get welcome_subtitle {
    return Intl.message(
      'Lyra works around a company. Tell us how you want to start: you can change your mind later.',
      name: 'welcome_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `{company} invited you`
  String welcome_invitation_title(Object company) {
    return Intl.message(
      '$company invited you',
      name: 'welcome_invitation_title',
      desc: '',
      args: [company],
    );
  }

  /// `Review the invitation to join their team.`
  String get welcome_invitation_subtitle {
    return Intl.message(
      'Review the invitation to join their team.',
      name: 'welcome_invitation_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `{job} at {company}`
  String welcome_invitation_job(Object job, Object company) {
    return Intl.message(
      '$job at $company',
      name: 'welcome_invitation_job',
      desc: '',
      args: [job, company],
    );
  }

  /// `Review`
  String get welcome_invitation_action {
    return Intl.message(
      'Review',
      name: 'welcome_invitation_action',
      desc: '',
      args: [],
    );
  }

  /// `Or start another way`
  String get welcome_other_ways {
    return Intl.message(
      'Or start another way',
      name: 'welcome_other_ways',
      desc: '',
      args: [],
    );
  }

  /// `Create a company`
  String get welcome_create_title {
    return Intl.message(
      'Create a company',
      name: 'welcome_create_title',
      desc: '',
      args: [],
    );
  }

  /// `Register your first company and manage it from here.`
  String get welcome_create_subtitle {
    return Intl.message(
      'Register your first company and manage it from here.',
      name: 'welcome_create_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Create company`
  String get welcome_create_action {
    return Intl.message(
      'Create company',
      name: 'welcome_create_action',
      desc: '',
      args: [],
    );
  }

  /// `Join my company's team`
  String get welcome_awaiting_title {
    return Intl.message(
      'Join my company\'s team',
      name: 'welcome_awaiting_title',
      desc: '',
      args: [],
    );
  }

  /// `Your company already uses Lyra. See how to ask them to add you.`
  String get welcome_awaiting_subtitle {
    return Intl.message(
      'Your company already uses Lyra. See how to ask them to add you.',
      name: 'welcome_awaiting_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Browse open jobs`
  String get welcome_jobs_title {
    return Intl.message(
      'Browse open jobs',
      name: 'welcome_jobs_title',
      desc: '',
      args: [],
    );
  }

  /// `See the positions companies have open and apply to one.`
  String get welcome_jobs_subtitle {
    return Intl.message(
      'See the positions companies have open and apply to one.',
      name: 'welcome_jobs_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Coming soon`
  String get welcome_jobs_soon {
    return Intl.message(
      'Coming soon',
      name: 'welcome_jobs_soon',
      desc: '',
      args: [],
    );
  }

  /// `Invitation`
  String get welcome_invitation_modal_title {
    return Intl.message(
      'Invitation',
      name: 'welcome_invitation_modal_title',
      desc: '',
      args: [],
    );
  }

  /// `Company`
  String get welcome_invitation_company {
    return Intl.message(
      'Company',
      name: 'welcome_invitation_company',
      desc: '',
      args: [],
    );
  }

  /// `Position`
  String get welcome_invitation_role {
    return Intl.message(
      'Position',
      name: 'welcome_invitation_role',
      desc: '',
      args: [],
    );
  }

  /// `Department`
  String get welcome_invitation_department {
    return Intl.message(
      'Department',
      name: 'welcome_invitation_department',
      desc: '',
      args: [],
    );
  }

  /// `Branch`
  String get welcome_invitation_branch {
    return Intl.message(
      'Branch',
      name: 'welcome_invitation_branch',
      desc: '',
      args: [],
    );
  }

  /// `Invited on`
  String get welcome_invitation_date {
    return Intl.message(
      'Invited on',
      name: 'welcome_invitation_date',
      desc: '',
      args: [],
    );
  }

  /// `Accept invitation`
  String get welcome_invitation_accept {
    return Intl.message(
      'Accept invitation',
      name: 'welcome_invitation_accept',
      desc: '',
      args: [],
    );
  }

  /// `Once you accept, you join {company}'s team and they can see your profile.`
  String welcome_invitation_accept_notice(Object company) {
    return Intl.message(
      'Once you accept, you join $company\'s team and they can see your profile.',
      name: 'welcome_invitation_accept_notice',
      desc: '',
      args: [company],
    );
  }

  /// `Waiting for an invitation`
  String get welcome_awaiting_modal_title {
    return Intl.message(
      'Waiting for an invitation',
      name: 'welcome_awaiting_modal_title',
      desc: '',
      args: [],
    );
  }

  /// `Ask the company to invite you with this email. The invitation will show up on this page as soon as they send it.`
  String get welcome_awaiting_body {
    return Intl.message(
      'Ask the company to invite you with this email. The invitation will show up on this page as soon as they send it.',
      name: 'welcome_awaiting_body',
      desc: '',
      args: [],
    );
  }

  /// `Open jobs`
  String get welcome_jobs_modal_title {
    return Intl.message(
      'Open jobs',
      name: 'welcome_jobs_modal_title',
      desc: '',
      args: [],
    );
  }

  /// `Job openings are coming soon. You will be able to browse them and apply from here.`
  String get welcome_jobs_body {
    return Intl.message(
      'Job openings are coming soon. You will be able to browse them and apply from here.',
      name: 'welcome_jobs_body',
      desc: '',
      args: [],
    );
  }

  /// `Search a permission: sales, inventory, payments...`
  String get permission_search_hint {
    return Intl.message(
      'Search a permission: sales, inventory, payments...',
      name: 'permission_search_hint',
      desc: '',
      args: [],
    );
  }

  /// `These are your permissions in this business. Only someone who manages the team can change them.`
  String get permission_own_read_only {
    return Intl.message(
      'These are your permissions in this business. Only someone who manages the team can change them.',
      name: 'permission_own_read_only',
      desc: '',
      args: [],
    );
  }

  /// `No permission matches the search.`
  String get permission_search_empty {
    return Intl.message(
      'No permission matches the search.',
      name: 'permission_search_empty',
      desc: '',
      args: [],
    );
  }

  /// `This person created the business: they hold every permission, including the ones added later, and nobody can change them.`
  String get permission_owner_note {
    return Intl.message(
      'This person created the business: they hold every permission, including the ones added later, and nobody can change them.',
      name: 'permission_owner_note',
      desc: '',
      args: [],
    );
  }

  /// `Holds every permission, including the ones added later. Changing any of them keeps only what is ticked.`
  String get permission_all_note {
    return Intl.message(
      'Holds every permission, including the ones added later. Changing any of them keeps only what is ticked.',
      name: 'permission_all_note',
      desc: '',
      args: [],
    );
  }

  /// `Holds every permission. Only someone who also holds every permission can change them.`
  String get permission_all_locked {
    return Intl.message(
      'Holds every permission. Only someone who also holds every permission can change them.',
      name: 'permission_all_locked',
      desc: '',
      args: [],
    );
  }

  /// `This business is connected online, so its permissions are changed there: from Lyra on the web or signed in online. They reach this server by themselves.`
  String get permission_online_note {
    return Intl.message(
      'This business is connected online, so its permissions are changed there: from Lyra on the web or signed in online. They reach this server by themselves.',
      name: 'permission_online_note',
      desc: '',
      args: [],
    );
  }

  /// `Works here but can't enter the business yet. Giving access lets them in with what is ticked below.`
  String get permission_no_access_note {
    return Intl.message(
      'Works here but can\'t enter the business yet. Giving access lets them in with what is ticked below.',
      name: 'permission_no_access_note',
      desc: '',
      args: [],
    );
  }

  /// `Start from a template`
  String get permission_template_title {
    return Intl.message(
      'Start from a template',
      name: 'permission_template_title',
      desc: '',
      args: [],
    );
  }

  /// `Pick a template`
  String get permission_template_placeholder {
    return Intl.message(
      'Pick a template',
      name: 'permission_template_placeholder',
      desc: '',
      args: [],
    );
  }

  /// `No template matches.`
  String get permission_template_empty {
    return Intl.message(
      'No template matches.',
      name: 'permission_template_empty',
      desc: '',
      args: [],
    );
  }

  /// `From the template {name}`
  String permission_template_from(Object name) {
    return Intl.message(
      'From the template $name',
      name: 'permission_template_from',
      desc: '',
      args: [name],
    );
  }

  /// `From the template {name}, with changes`
  String permission_template_custom(Object name) {
    return Intl.message(
      'From the template $name, with changes',
      name: 'permission_template_custom',
      desc: '',
      args: [name],
    );
  }

  /// `The template {name} replaces their permissions when you save.`
  String permission_template_picked(Object name) {
    return Intl.message(
      'The template $name replaces their permissions when you save.',
      name: 'permission_template_picked',
      desc: '',
      args: [name],
    );
  }

  /// `Give access`
  String get permission_give_access {
    return Intl.message(
      'Give access',
      name: 'permission_give_access',
      desc: '',
      args: [],
    );
  }

  /// `Discard`
  String get permission_discard {
    return Intl.message(
      'Discard',
      name: 'permission_discard',
      desc: '',
      args: [],
    );
  }

  /// `Remove access`
  String get permission_revoke {
    return Intl.message(
      'Remove access',
      name: 'permission_revoke',
      desc: '',
      args: [],
    );
  }

  /// `Remove {name}'s access?`
  String permission_revoke_title(Object name) {
    return Intl.message(
      'Remove $name\'s access?',
      name: 'permission_revoke_title',
      desc: '',
      args: [name],
    );
  }

  /// `They won't be able to enter the business. Their permissions are kept for when you give access again.`
  String get permission_revoke_message {
    return Intl.message(
      'They won\'t be able to enter the business. Their permissions are kept for when you give access again.',
      name: 'permission_revoke_message',
      desc: '',
      args: [],
    );
  }

  /// `Remove access`
  String get permission_revoke_confirm {
    return Intl.message(
      'Remove access',
      name: 'permission_revoke_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Permissions saved.`
  String get permission_saved {
    return Intl.message(
      'Permissions saved.',
      name: 'permission_saved',
      desc: '',
      args: [],
    );
  }

  /// `{name} no longer has access to the business.`
  String permission_revoked(Object name) {
    return Intl.message(
      '$name no longer has access to the business.',
      name: 'permission_revoked',
      desc: '',
      args: [name],
    );
  }

  /// `You don't hold this permission, so you can't give or take it.`
  String get permission_locked {
    return Intl.message(
      'You don\'t hold this permission, so you can\'t give or take it.',
      name: 'permission_locked',
      desc: '',
      args: [],
    );
  }

  /// `The permissions couldn't be loaded.`
  String get permission_load_error {
    return Intl.message(
      'The permissions couldn\'t be loaded.',
      name: 'permission_load_error',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get permission_retry {
    return Intl.message(
      'Try again',
      name: 'permission_retry',
      desc: '',
      args: [],
    );
  }

  /// `{granted} of {total} on`
  String permission_group_count(Object granted, Object total) {
    return Intl.message(
      '$granted of $total on',
      name: 'permission_group_count',
      desc: '',
      args: [granted, total],
    );
  }

  /// `{action}: {section}`
  String permission_access_cell(Object action, Object section) {
    return Intl.message(
      '$action: $section',
      name: 'permission_access_cell',
      desc: '',
      args: [action, section],
    );
  }

  /// `Owner`
  String get permission_preset_owner {
    return Intl.message(
      'Owner',
      name: 'permission_preset_owner',
      desc: '',
      args: [],
    );
  }

  /// `Every permission, including the ones added later.`
  String get permission_preset_owner_description {
    return Intl.message(
      'Every permission, including the ones added later.',
      name: 'permission_preset_owner_description',
      desc: '',
      args: [],
    );
  }

  /// `Manager`
  String get permission_preset_manager {
    return Intl.message(
      'Manager',
      name: 'permission_preset_manager',
      desc: '',
      args: [],
    );
  }

  /// `Runs the whole business, except the accounts it receives money into and the templates.`
  String get permission_preset_manager_description {
    return Intl.message(
      'Runs the whole business, except the accounts it receives money into and the templates.',
      name: 'permission_preset_manager_description',
      desc: '',
      args: [],
    );
  }

  /// `Marketing`
  String get permission_preset_marketing {
    return Intl.message(
      'Marketing',
      name: 'permission_preset_marketing',
      desc: '',
      args: [],
    );
  }

  /// `The catalog, product pictures and the sales board.`
  String get permission_preset_marketing_description {
    return Intl.message(
      'The catalog, product pictures and the sales board.',
      name: 'permission_preset_marketing_description',
      desc: '',
      args: [],
    );
  }

  /// `Seller`
  String get permission_preset_seller {
    return Intl.message(
      'Seller',
      name: 'permission_preset_seller',
      desc: '',
      args: [],
    );
  }

  /// `Sells at the register, holds products and hands over orders.`
  String get permission_preset_seller_description {
    return Intl.message(
      'Sells at the register, holds products and hands over orders.',
      name: 'permission_preset_seller_description',
      desc: '',
      args: [],
    );
  }

  /// `Auditor`
  String get permission_preset_auditor {
    return Intl.message(
      'Auditor',
      name: 'permission_preset_auditor',
      desc: '',
      args: [],
    );
  }

  /// `Sees every section without changing anything.`
  String get permission_preset_auditor_description {
    return Intl.message(
      'Sees every section without changing anything.',
      name: 'permission_preset_auditor_description',
      desc: '',
      args: [],
    );
  }

  /// `Billing specialist`
  String get permission_preset_billing {
    return Intl.message(
      'Billing specialist',
      name: 'permission_preset_billing',
      desc: '',
      args: [],
    );
  }

  /// `Charges and cancels tickets and records the payments that settle them.`
  String get permission_preset_billing_description {
    return Intl.message(
      'Charges and cancels tickets and records the payments that settle them.',
      name: 'permission_preset_billing_description',
      desc: '',
      args: [],
    );
  }

  /// `Finance`
  String get permission_preset_finance {
    return Intl.message(
      'Finance',
      name: 'permission_preset_finance',
      desc: '',
      args: [],
    );
  }

  /// `All the money: payments, voids and the business's accounts.`
  String get permission_preset_finance_description {
    return Intl.message(
      'All the money: payments, voids and the business\'s accounts.',
      name: 'permission_preset_finance_description',
      desc: '',
      args: [],
    );
  }

  /// `Stock`
  String get permission_inventory_title {
    return Intl.message(
      'Stock',
      name: 'permission_inventory_title',
      desc: '',
      args: [],
    );
  }

  /// `Stock balances, movements and the stock summary.`
  String get permission_inventory_description {
    return Intl.message(
      'Stock balances, movements and the stock summary.',
      name: 'permission_inventory_description',
      desc: '',
      args: [],
    );
  }

  /// `Add stock`
  String get permission_inventory_restock {
    return Intl.message(
      'Add stock',
      name: 'permission_inventory_restock',
      desc: '',
      args: [],
    );
  }

  /// `Remove stock`
  String get permission_inventory_remove {
    return Intl.message(
      'Remove stock',
      name: 'permission_inventory_remove',
      desc: '',
      args: [],
    );
  }

  /// `Record returns`
  String get permission_inventory_return {
    return Intl.message(
      'Record returns',
      name: 'permission_inventory_return',
      desc: '',
      args: [],
    );
  }

  /// `Hold and release units`
  String get permission_inventory_hold {
    return Intl.message(
      'Hold and release units',
      name: 'permission_inventory_hold',
      desc: '',
      args: [],
    );
  }

  /// `Choose the summary's columns`
  String get permission_inventory_configure {
    return Intl.message(
      'Choose the summary\'s columns',
      name: 'permission_inventory_configure',
      desc: '',
      args: [],
    );
  }

  /// `Change product pictures`
  String get permission_inventory_pictures {
    return Intl.message(
      'Change product pictures',
      name: 'permission_inventory_pictures',
      desc: '',
      args: [],
    );
  }

  /// `Reservations`
  String get permission_reservations_title {
    return Intl.message(
      'Reservations',
      name: 'permission_reservations_title',
      desc: '',
      args: [],
    );
  }

  /// `Units reserved for a client from the panel.`
  String get permission_reservations_description {
    return Intl.message(
      'Units reserved for a client from the panel.',
      name: 'permission_reservations_description',
      desc: '',
      args: [],
    );
  }

  /// `Create reservations`
  String get permission_reservations_create {
    return Intl.message(
      'Create reservations',
      name: 'permission_reservations_create',
      desc: '',
      args: [],
    );
  }

  /// `Confirm and cancel reservations`
  String get permission_reservations_manage {
    return Intl.message(
      'Confirm and cancel reservations',
      name: 'permission_reservations_manage',
      desc: '',
      args: [],
    );
  }

  /// `Point of sale`
  String get permission_pos_title {
    return Intl.message(
      'Point of sale',
      name: 'permission_pos_title',
      desc: '',
      args: [],
    );
  }

  /// `The register: tickets and charges.`
  String get permission_pos_description {
    return Intl.message(
      'The register: tickets and charges.',
      name: 'permission_pos_description',
      desc: '',
      args: [],
    );
  }

  /// `Sell and charge tickets`
  String get permission_pos_sell {
    return Intl.message(
      'Sell and charge tickets',
      name: 'permission_pos_sell',
      desc: '',
      args: [],
    );
  }

  /// `Cancel tickets`
  String get permission_pos_cancel {
    return Intl.message(
      'Cancel tickets',
      name: 'permission_pos_cancel',
      desc: '',
      args: [],
    );
  }

  /// `Sales`
  String get permission_sales_title {
    return Intl.message(
      'Sales',
      name: 'permission_sales_title',
      desc: '',
      args: [],
    );
  }

  /// `The live sales board, in process and done.`
  String get permission_sales_description {
    return Intl.message(
      'The live sales board, in process and done.',
      name: 'permission_sales_description',
      desc: '',
      args: [],
    );
  }

  /// `Hand over orders`
  String get permission_sales_fulfill {
    return Intl.message(
      'Hand over orders',
      name: 'permission_sales_fulfill',
      desc: '',
      args: [],
    );
  }

  /// `Finance`
  String get permission_money_title {
    return Intl.message(
      'Finance',
      name: 'permission_money_title',
      desc: '',
      args: [],
    );
  }

  /// `Payments, receivables and the accounts the business receives money into.`
  String get permission_money_description {
    return Intl.message(
      'Payments, receivables and the accounts the business receives money into.',
      name: 'permission_money_description',
      desc: '',
      args: [],
    );
  }

  /// `Record payments and collect receivables`
  String get permission_money_charge {
    return Intl.message(
      'Record payments and collect receivables',
      name: 'permission_money_charge',
      desc: '',
      args: [],
    );
  }

  /// `Void payments`
  String get permission_money_void {
    return Intl.message(
      'Void payments',
      name: 'permission_money_void',
      desc: '',
      args: [],
    );
  }

  /// `Manage payment methods and currencies`
  String get permission_money_accounts {
    return Intl.message(
      'Manage payment methods and currencies',
      name: 'permission_money_accounts',
      desc: '',
      args: [],
    );
  }

  /// `Export the accounting`
  String get permission_money_export {
    return Intl.message(
      'Export the accounting',
      name: 'permission_money_export',
      desc: '',
      args: [],
    );
  }

  /// `Employees`
  String get permission_employees_title {
    return Intl.message(
      'Employees',
      name: 'permission_employees_title',
      desc: '',
      args: [],
    );
  }

  /// `Who works here, with their personal data and salary.`
  String get permission_employees_description {
    return Intl.message(
      'Who works here, with their personal data and salary.',
      name: 'permission_employees_description',
      desc: '',
      args: [],
    );
  }

  /// `Invite people and edit jobs and leaves`
  String get permission_employees_manage {
    return Intl.message(
      'Invite people and edit jobs and leaves',
      name: 'permission_employees_manage',
      desc: '',
      args: [],
    );
  }

  /// `Permissions`
  String get permission_permissions_title {
    return Intl.message(
      'Permissions',
      name: 'permission_permissions_title',
      desc: '',
      args: [],
    );
  }

  /// `Who can enter the business and what each person can do.`
  String get permission_permissions_description {
    return Intl.message(
      'Who can enter the business and what each person can do.',
      name: 'permission_permissions_description',
      desc: '',
      args: [],
    );
  }

  /// `Give and remove access and permissions`
  String get permission_permissions_assign {
    return Intl.message(
      'Give and remove access and permissions',
      name: 'permission_permissions_assign',
      desc: '',
      args: [],
    );
  }

  /// `Manage the business's templates`
  String get permission_permissions_templates {
    return Intl.message(
      'Manage the business\'s templates',
      name: 'permission_permissions_templates',
      desc: '',
      args: [],
    );
  }

  /// `Products`
  String get permission_products_title {
    return Intl.message(
      'Products',
      name: 'permission_products_title',
      desc: '',
      args: [],
    );
  }

  /// `The product tables and their records.`
  String get permission_products_description {
    return Intl.message(
      'The product tables and their records.',
      name: 'permission_products_description',
      desc: '',
      args: [],
    );
  }

  /// `Add records`
  String get permission_products_create {
    return Intl.message(
      'Add records',
      name: 'permission_products_create',
      desc: '',
      args: [],
    );
  }

  /// `Edit records`
  String get permission_products_edit {
    return Intl.message(
      'Edit records',
      name: 'permission_products_edit',
      desc: '',
      args: [],
    );
  }

  /// `Delete records`
  String get permission_products_delete {
    return Intl.message(
      'Delete records',
      name: 'permission_products_delete',
      desc: '',
      args: [],
    );
  }

  /// `Import from a file`
  String get permission_products_import {
    return Intl.message(
      'Import from a file',
      name: 'permission_products_import',
      desc: '',
      args: [],
    );
  }

  /// `Create and change tables and fields`
  String get permission_products_structure {
    return Intl.message(
      'Create and change tables and fields',
      name: 'permission_products_structure',
      desc: '',
      args: [],
    );
  }

  /// `Messages`
  String get permission_chats_title {
    return Intl.message(
      'Messages',
      name: 'permission_chats_title',
      desc: '',
      args: [],
    );
  }

  /// `The conversations with clients and the clients list.`
  String get permission_chats_description {
    return Intl.message(
      'The conversations with clients and the clients list.',
      name: 'permission_chats_description',
      desc: '',
      args: [],
    );
  }

  /// `Reply to clients`
  String get permission_chats_reply {
    return Intl.message(
      'Reply to clients',
      name: 'permission_chats_reply',
      desc: '',
      args: [],
    );
  }

  /// `Change stages and resolve alerts`
  String get permission_chats_manage {
    return Intl.message(
      'Change stages and resolve alerts',
      name: 'permission_chats_manage',
      desc: '',
      args: [],
    );
  }

  /// `Assign conversations`
  String get permission_chats_assign {
    return Intl.message(
      'Assign conversations',
      name: 'permission_chats_assign',
      desc: '',
      args: [],
    );
  }

  /// `Pause and resume the assistant`
  String get permission_chats_bot {
    return Intl.message(
      'Pause and resume the assistant',
      name: 'permission_chats_bot',
      desc: '',
      args: [],
    );
  }

  /// `Channels`
  String get permission_channels_title {
    return Intl.message(
      'Channels',
      name: 'permission_channels_title',
      desc: '',
      args: [],
    );
  }

  /// `The AI channels that talk to clients.`
  String get permission_channels_description {
    return Intl.message(
      'The AI channels that talk to clients.',
      name: 'permission_channels_description',
      desc: '',
      args: [],
    );
  }

  /// `Create channels`
  String get permission_channels_create {
    return Intl.message(
      'Create channels',
      name: 'permission_channels_create',
      desc: '',
      args: [],
    );
  }

  /// `Edit channels`
  String get permission_channels_edit {
    return Intl.message(
      'Edit channels',
      name: 'permission_channels_edit',
      desc: '',
      args: [],
    );
  }

  /// `Delete channels`
  String get permission_channels_delete {
    return Intl.message(
      'Delete channels',
      name: 'permission_channels_delete',
      desc: '',
      args: [],
    );
  }

  /// `Link and unlink phone numbers`
  String get permission_channels_connect {
    return Intl.message(
      'Link and unlink phone numbers',
      name: 'permission_channels_connect',
      desc: '',
      args: [],
    );
  }

  /// `Appointments`
  String get permission_appointments_title {
    return Intl.message(
      'Appointments',
      name: 'permission_appointments_title',
      desc: '',
      args: [],
    );
  }

  /// `The calendar of appointments.`
  String get permission_appointments_description {
    return Intl.message(
      'The calendar of appointments.',
      name: 'permission_appointments_description',
      desc: '',
      args: [],
    );
  }

  /// `Book and update appointments`
  String get permission_appointments_book {
    return Intl.message(
      'Book and update appointments',
      name: 'permission_appointments_book',
      desc: '',
      args: [],
    );
  }

  /// `Set services, hours and closures`
  String get permission_appointments_configure {
    return Intl.message(
      'Set services, hours and closures',
      name: 'permission_appointments_configure',
      desc: '',
      args: [],
    );
  }

  /// `Knowledge`
  String get permission_knowledge_title {
    return Intl.message(
      'Knowledge',
      name: 'permission_knowledge_title',
      desc: '',
      args: [],
    );
  }

  /// `What the business has already answered, for the assistant to reuse.`
  String get permission_knowledge_description {
    return Intl.message(
      'What the business has already answered, for the assistant to reuse.',
      name: 'permission_knowledge_description',
      desc: '',
      args: [],
    );
  }

  /// `Add answers`
  String get permission_knowledge_create {
    return Intl.message(
      'Add answers',
      name: 'permission_knowledge_create',
      desc: '',
      args: [],
    );
  }

  /// `Edit answers`
  String get permission_knowledge_edit {
    return Intl.message(
      'Edit answers',
      name: 'permission_knowledge_edit',
      desc: '',
      args: [],
    );
  }

  /// `Delete answers`
  String get permission_knowledge_delete {
    return Intl.message(
      'Delete answers',
      name: 'permission_knowledge_delete',
      desc: '',
      args: [],
    );
  }

  /// `Branches`
  String get permission_branches_title {
    return Intl.message(
      'Branches',
      name: 'permission_branches_title',
      desc: '',
      args: [],
    );
  }

  /// `Changing the business's branches. Everyone sees the list.`
  String get permission_branches_description {
    return Intl.message(
      'Changing the business\'s branches. Everyone sees the list.',
      name: 'permission_branches_description',
      desc: '',
      args: [],
    );
  }

  /// `Add branches`
  String get permission_branches_create {
    return Intl.message(
      'Add branches',
      name: 'permission_branches_create',
      desc: '',
      args: [],
    );
  }

  /// `Edit branches`
  String get permission_branches_edit {
    return Intl.message(
      'Edit branches',
      name: 'permission_branches_edit',
      desc: '',
      args: [],
    );
  }

  /// `Delete branches`
  String get permission_branches_delete {
    return Intl.message(
      'Delete branches',
      name: 'permission_branches_delete',
      desc: '',
      args: [],
    );
  }

  /// `Deliveries`
  String get permission_delivery_title {
    return Intl.message(
      'Deliveries',
      name: 'permission_delivery_title',
      desc: '',
      args: [],
    );
  }

  /// `Whether, how and where the business delivers.`
  String get permission_delivery_description {
    return Intl.message(
      'Whether, how and where the business delivers.',
      name: 'permission_delivery_description',
      desc: '',
      args: [],
    );
  }

  /// `Add delivery options and areas`
  String get permission_delivery_create {
    return Intl.message(
      'Add delivery options and areas',
      name: 'permission_delivery_create',
      desc: '',
      args: [],
    );
  }

  /// `Edit delivery settings, options and areas`
  String get permission_delivery_edit {
    return Intl.message(
      'Edit delivery settings, options and areas',
      name: 'permission_delivery_edit',
      desc: '',
      args: [],
    );
  }

  /// `Delete delivery options and areas`
  String get permission_delivery_delete {
    return Intl.message(
      'Delete delivery options and areas',
      name: 'permission_delivery_delete',
      desc: '',
      args: [],
    );
  }

  /// `Business`
  String get permission_business_title {
    return Intl.message(
      'Business',
      name: 'permission_business_title',
      desc: '',
      args: [],
    );
  }

  /// `The business's statistics and settings.`
  String get permission_business_description {
    return Intl.message(
      'The business\'s statistics and settings.',
      name: 'permission_business_description',
      desc: '',
      args: [],
    );
  }

  /// `Edit the profile, logo and location`
  String get permission_business_edit {
    return Intl.message(
      'Edit the profile, logo and location',
      name: 'permission_business_edit',
      desc: '',
      args: [],
    );
  }

  /// `Manage the business's emails`
  String get permission_business_emails {
    return Intl.message(
      'Manage the business\'s emails',
      name: 'permission_business_emails',
      desc: '',
      args: [],
    );
  }

  /// `Local server`
  String get permission_server_title {
    return Intl.message(
      'Local server',
      name: 'permission_server_title',
      desc: '',
      args: [],
    );
  }

  /// `The business's own server, for working offline.`
  String get permission_server_description {
    return Intl.message(
      'The business\'s own server, for working offline.',
      name: 'permission_server_description',
      desc: '',
      args: [],
    );
  }

  /// `Pair and remove devices`
  String get permission_server_devices {
    return Intl.message(
      'Pair and remove devices',
      name: 'permission_server_devices',
      desc: '',
      args: [],
    );
  }

  /// `Run and restore backups`
  String get permission_server_backups {
    return Intl.message(
      'Run and restore backups',
      name: 'permission_server_backups',
      desc: '',
      args: [],
    );
  }

  /// `Stop the server`
  String get permission_server_stop {
    return Intl.message(
      'Stop the server',
      name: 'permission_server_stop',
      desc: '',
      args: [],
    );
  }

  /// `No connection to Lyra`
  String get auth_offline_title {
    return Intl.message(
      'No connection to Lyra',
      name: 'auth_offline_title',
      desc: '',
      args: [],
    );
  }

  /// `This device can't reach Lyra's servers, and there's no Lyra server on this network. Check the connection and try again.`
  String get auth_offline_message {
    return Intl.message(
      'This device can\'t reach Lyra\'s servers, and there\'s no Lyra server on this network. Check the connection and try again.',
      name: 'auth_offline_message',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get auth_offline_retry {
    return Intl.message(
      'Try again',
      name: 'auth_offline_retry',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to your server`
  String get auth_lan_title {
    return Intl.message(
      'Sign in to your server',
      name: 'auth_lan_title',
      desc: '',
      args: [],
    );
  }

  /// `Sign in to Lyra`
  String get auth_master_title {
    return Intl.message(
      'Sign in to Lyra',
      name: 'auth_master_title',
      desc: '',
      args: [],
    );
  }

  /// `Enter the email of your account on your business's Lyra server.`
  String get auth_master_subtitle {
    return Intl.message(
      'Enter the email of your account on your business\'s Lyra server.',
      name: 'auth_master_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Your account isn't active yet. Type the code your company gave you and the password you want to use from now on.`
  String get auth_master_activate_subtitle {
    return Intl.message(
      'Your account isn\'t active yet. Type the code your company gave you and the password you want to use from now on.',
      name: 'auth_master_activate_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `There's no internet, but your business's Lyra server is on this network. Sign in with your account on it.`
  String get auth_lan_subtitle {
    return Intl.message(
      'There\'s no internet, but your business\'s Lyra server is on this network. Sign in with your account on it.',
      name: 'auth_lan_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Server`
  String get auth_lan_server {
    return Intl.message(
      'Server',
      name: 'auth_lan_server',
      desc: '',
      args: [],
    );
  }

  /// `Wrong email or password.`
  String get auth_lan_wrong {
    return Intl.message(
      'Wrong email or password.',
      name: 'auth_lan_wrong',
      desc: '',
      args: [],
    );
  }

  /// `Too many wrong passwords. Wait 15 minutes and try again.`
  String get auth_lan_locked {
    return Intl.message(
      'Too many wrong passwords. Wait 15 minutes and try again.',
      name: 'auth_lan_locked',
      desc: '',
      args: [],
    );
  }

  /// `Create your server`
  String get auth_create_title {
    return Intl.message(
      'Create your server',
      name: 'auth_create_title',
      desc: '',
      args: [],
    );
  }

  /// `There's no internet and no Lyra server on this network. Make this computer the server: this email and password will be its administrator.`
  String get auth_create_subtitle {
    return Intl.message(
      'There\'s no internet and no Lyra server on this network. Make this computer the server: this email and password will be its administrator.',
      name: 'auth_create_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Create Master Server`
  String get auth_create_button {
    return Intl.message(
      'Create Master Server',
      name: 'auth_create_button',
      desc: '',
      args: [],
    );
  }

  /// `Administrator: {email}`
  String lan_master_owner_email(Object email) {
    return Intl.message(
      'Administrator: $email',
      name: 'lan_master_owner_email',
      desc: '',
      args: [email],
    );
  }

  /// `Set up this computer as the server`
  String get lan_master_title {
    return Intl.message(
      'Set up this computer as the server',
      name: 'lan_master_title',
      desc: '',
      args: [],
    );
  }

  /// `You'll be the owner. Other people join later with invitations.`
  String get lan_master_subtitle {
    return Intl.message(
      'You\'ll be the owner. Other people join later with invitations.',
      name: 'lan_master_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Country`
  String get lan_master_country {
    return Intl.message(
      'Country',
      name: 'lan_master_country',
      desc: '',
      args: [],
    );
  }

  /// `Main currency`
  String get lan_master_currency {
    return Intl.message(
      'Main currency',
      name: 'lan_master_currency',
      desc: '',
      args: [],
    );
  }

  /// `Language`
  String get lan_master_language {
    return Intl.message(
      'Language',
      name: 'lan_master_language',
      desc: '',
      args: [],
    );
  }

  /// `Nothing matches`
  String get lan_master_no_match {
    return Intl.message(
      'Nothing matches',
      name: 'lan_master_no_match',
      desc: '',
      args: [],
    );
  }

  /// `Prices are written in the main currency. It can't be changed later.`
  String get lan_master_currency_note {
    return Intl.message(
      'Prices are written in the main currency. It can\'t be changed later.',
      name: 'lan_master_currency_note',
      desc: '',
      args: [],
    );
  }

  /// `Your account`
  String get lan_master_owner {
    return Intl.message(
      'Your account',
      name: 'lan_master_owner',
      desc: '',
      args: [],
    );
  }

  /// `Username`
  String get lan_username_input {
    return Intl.message(
      'Username',
      name: 'lan_username_input',
      desc: '',
      args: [],
    );
  }

  /// `Ask for a passphrase every time the server starts`
  String get lan_passphrase_toggle {
    return Intl.message(
      'Ask for a passphrase every time the server starts',
      name: 'lan_passphrase_toggle',
      desc: '',
      args: [],
    );
  }

  /// `Without one, this computer's own sign-in protects the data. With one, nobody can open the data without it: if you forget it, only the recovery key gets the data back.`
  String get lan_passphrase_hint {
    return Intl.message(
      'Without one, this computer\'s own sign-in protects the data. With one, nobody can open the data without it: if you forget it, only the recovery key gets the data back.',
      name: 'lan_passphrase_hint',
      desc: '',
      args: [],
    );
  }

  /// `Passphrase`
  String get lan_passphrase_input {
    return Intl.message(
      'Passphrase',
      name: 'lan_passphrase_input',
      desc: '',
      args: [],
    );
  }

  /// `I accept the Lyra licence agreement`
  String get lan_eula_accept {
    return Intl.message(
      'I accept the Lyra licence agreement',
      name: 'lan_eula_accept',
      desc: '',
      args: [],
    );
  }

  /// `Create the server`
  String get lan_master_create {
    return Intl.message(
      'Create the server',
      name: 'lan_master_create',
      desc: '',
      args: [],
    );
  }

  /// `Accept the licence agreement to continue.`
  String get lan_master_eula_required {
    return Intl.message(
      'Accept the licence agreement to continue.',
      name: 'lan_master_eula_required',
      desc: '',
      args: [],
    );
  }

  /// `The username must be 3 to 32 letters, digits, dots, dashes or underscores, starting with a letter.`
  String get lan_master_invalid_username {
    return Intl.message(
      'The username must be 3 to 32 letters, digits, dots, dashes or underscores, starting with a letter.',
      name: 'lan_master_invalid_username',
      desc: '',
      args: [],
    );
  }

  /// `The password must have at least 10 characters.`
  String get lan_master_weak_password {
    return Intl.message(
      'The password must have at least 10 characters.',
      name: 'lan_master_weak_password',
      desc: '',
      args: [],
    );
  }

  /// `{field} can't be empty.`
  String lan_field_empty(Object field) {
    return Intl.message(
      '$field can\'t be empty.',
      name: 'lan_field_empty',
      desc: '',
      args: [field],
    );
  }

  /// `{field} is too long.`
  String lan_field_long(Object field) {
    return Intl.message(
      '$field is too long.',
      name: 'lan_field_long',
      desc: '',
      args: [field],
    );
  }

  /// `The passphrase must have at least 10 characters.`
  String get lan_passphrase_short {
    return Intl.message(
      'The passphrase must have at least 10 characters.',
      name: 'lan_passphrase_short',
      desc: '',
      args: [],
    );
  }

  /// `This computer is already a server. Go back and choose it again to open it.`
  String get lan_master_exists {
    return Intl.message(
      'This computer is already a server. Go back and choose it again to open it.',
      name: 'lan_master_exists',
      desc: '',
      args: [],
    );
  }

  /// `Write down your recovery key`
  String get lan_recovery_title {
    return Intl.message(
      'Write down your recovery key',
      name: 'lan_recovery_title',
      desc: '',
      args: [],
    );
  }

  /// `These 24 words are the only way to get the data back if this computer's keys are lost. Lyra keeps no copy: without them the data is gone for good.`
  String get lan_recovery_subtitle {
    return Intl.message(
      'These 24 words are the only way to get the data back if this computer\'s keys are lost. Lyra keeps no copy: without them the data is gone for good.',
      name: 'lan_recovery_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `I wrote the 24 words down and keep them somewhere safe`
  String get lan_recovery_confirm {
    return Intl.message(
      'I wrote the 24 words down and keep them somewhere safe',
      name: 'lan_recovery_confirm',
      desc: '',
      args: [],
    );
  }

  /// `Confirm you wrote the words down first. They won't be shown again.`
  String get lan_recovery_required {
    return Intl.message(
      'Confirm you wrote the words down first. They won\'t be shown again.',
      name: 'lan_recovery_required',
      desc: '',
      args: [],
    );
  }

  /// `Start the server`
  String get lan_recovery_continue {
    return Intl.message(
      'Start the server',
      name: 'lan_recovery_continue',
      desc: '',
      args: [],
    );
  }

  /// `Pair with the server`
  String get lan_pair_title {
    return Intl.message(
      'Pair with the server',
      name: 'lan_pair_title',
      desc: '',
      args: [],
    );
  }

  /// `On the server, open Lyra and choose Add device. Then type here the code it shows.`
  String get lan_pair_subtitle {
    return Intl.message(
      'On the server, open Lyra and choose Add device. Then type here the code it shows.',
      name: 'lan_pair_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Looking for servers on this network…`
  String get lan_pair_searching {
    return Intl.message(
      'Looking for servers on this network…',
      name: 'lan_pair_searching',
      desc: '',
      args: [],
    );
  }

  /// `No server found. Type its address instead.`
  String get lan_pair_none {
    return Intl.message(
      'No server found. Type its address instead.',
      name: 'lan_pair_none',
      desc: '',
      args: [],
    );
  }

  /// `Servers on this network`
  String get lan_pair_found {
    return Intl.message(
      'Servers on this network',
      name: 'lan_pair_found',
      desc: '',
      args: [],
    );
  }

  /// `Server address`
  String get lan_pair_address_input {
    return Intl.message(
      'Server address',
      name: 'lan_pair_address_input',
      desc: '',
      args: [],
    );
  }

  /// `Port`
  String get lan_pair_port_input {
    return Intl.message(
      'Port',
      name: 'lan_pair_port_input',
      desc: '',
      args: [],
    );
  }

  /// `Name of this device`
  String get lan_pair_name_input {
    return Intl.message(
      'Name of this device',
      name: 'lan_pair_name_input',
      desc: '',
      args: [],
    );
  }

  /// `Pairing code`
  String get lan_pair_code {
    return Intl.message(
      'Pairing code',
      name: 'lan_pair_code',
      desc: '',
      args: [],
    );
  }

  /// `Pair`
  String get lan_pair_submit {
    return Intl.message(
      'Pair',
      name: 'lan_pair_submit',
      desc: '',
      args: [],
    );
  }

  /// `That code didn't work. Check it, or add the device again on the server for a new one.`
  String get lan_pair_wrong_code {
    return Intl.message(
      'That code didn\'t work. Check it, or add the device again on the server for a new one.',
      name: 'lan_pair_wrong_code',
      desc: '',
      args: [],
    );
  }

  /// `Something on this network answered in place of the server, so pairing was stopped to protect you. Check the address, and that you're on the right network.`
  String get lan_pair_wrong_master {
    return Intl.message(
      'Something on this network answered in place of the server, so pairing was stopped to protect you. Check the address, and that you\'re on the right network.',
      name: 'lan_pair_wrong_master',
      desc: '',
      args: [],
    );
  }

  /// `No Lyra server answered at that address.`
  String get lan_pair_unreachable {
    return Intl.message(
      'No Lyra server answered at that address.',
      name: 'lan_pair_unreachable',
      desc: '',
      args: [],
    );
  }

  /// `Search again`
  String get lan_search_again {
    return Intl.message(
      'Search again',
      name: 'lan_search_again',
      desc: '',
      args: [],
    );
  }

  /// `Use Lyra another way`
  String get lan_other_mode {
    return Intl.message(
      'Use Lyra another way',
      name: 'lan_other_mode',
      desc: '',
      args: [],
    );
  }

  /// `Connecting to the server…`
  String get lan_connecting {
    return Intl.message(
      'Connecting to the server…',
      name: 'lan_connecting',
      desc: '',
      args: [],
    );
  }

  /// `Opening Lyra…`
  String get lan_entering {
    return Intl.message(
      'Opening Lyra…',
      name: 'lan_entering',
      desc: '',
      args: [],
    );
  }

  /// `The server answered, but the business couldn't be opened. Update Lyra on the server computer, then try again.`
  String get lan_enter_failed {
    return Intl.message(
      'The server answered, but the business couldn\'t be opened. Update Lyra on the server computer, then try again.',
      name: 'lan_enter_failed',
      desc: '',
      args: [],
    );
  }

  /// `The server is locked`
  String get lan_locked_title {
    return Intl.message(
      'The server is locked',
      name: 'lan_locked_title',
      desc: '',
      args: [],
    );
  }

  /// `Type the passphrase to unlock the data.`
  String get lan_locked_master {
    return Intl.message(
      'Type the passphrase to unlock the data.',
      name: 'lan_locked_master',
      desc: '',
      args: [],
    );
  }

  /// `Ask someone to unlock it on the server computer.`
  String get lan_locked_client {
    return Intl.message(
      'Ask someone to unlock it on the server computer.',
      name: 'lan_locked_client',
      desc: '',
      args: [],
    );
  }

  /// `Unlock`
  String get lan_unlock {
    return Intl.message(
      'Unlock',
      name: 'lan_unlock',
      desc: '',
      args: [],
    );
  }

  /// `Connect this app to the server`
  String get lan_enroll_title {
    return Intl.message(
      'Connect this app to the server',
      name: 'lan_enroll_title',
      desc: '',
      args: [],
    );
  }

  /// `This computer is the server, but this app lost its key. It gets a new one now. If the server asks for a passphrase when it starts, type it; otherwise leave it empty.`
  String get lan_enroll_subtitle {
    return Intl.message(
      'This computer is the server, but this app lost its key. It gets a new one now. If the server asks for a passphrase when it starts, type it; otherwise leave it empty.',
      name: 'lan_enroll_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Connect`
  String get lan_enroll {
    return Intl.message(
      'Connect',
      name: 'lan_enroll',
      desc: '',
      args: [],
    );
  }

  /// `Activate your account`
  String get lan_activate_title {
    return Intl.message(
      'Activate your account',
      name: 'lan_activate_title',
      desc: '',
      args: [],
    );
  }

  /// `Activation code`
  String get lan_activate_code_input {
    return Intl.message(
      'Activation code',
      name: 'lan_activate_code_input',
      desc: '',
      args: [],
    );
  }

  /// `New password (10 characters or more)`
  String get lan_activate_password_input {
    return Intl.message(
      'New password (10 characters or more)',
      name: 'lan_activate_password_input',
      desc: '',
      args: [],
    );
  }

  /// `Activate and sign in`
  String get lan_activate_button {
    return Intl.message(
      'Activate and sign in',
      name: 'lan_activate_button',
      desc: '',
      args: [],
    );
  }

  /// `The server isn't answering`
  String get lan_unreachable_title {
    return Intl.message(
      'The server isn\'t answering',
      name: 'lan_unreachable_title',
      desc: '',
      args: [],
    );
  }

  /// `The server on this computer is stopped.`
  String get lan_unreachable_master {
    return Intl.message(
      'The server on this computer is stopped.',
      name: 'lan_unreachable_master',
      desc: '',
      args: [],
    );
  }

  /// `Ask someone to open Lyra on the server computer, and check this device is on the same network.`
  String get lan_unreachable_client {
    return Intl.message(
      'Ask someone to open Lyra on the server computer, and check this device is on the same network.',
      name: 'lan_unreachable_client',
      desc: '',
      args: [],
    );
  }

  /// `Try again`
  String get lan_retry {
    return Intl.message(
      'Try again',
      name: 'lan_retry',
      desc: '',
      args: [],
    );
  }

  /// `Start the server`
  String get lan_start_server {
    return Intl.message(
      'Start the server',
      name: 'lan_start_server',
      desc: '',
      args: [],
    );
  }

  /// `This device was removed`
  String get lan_revoked_title {
    return Intl.message(
      'This device was removed',
      name: 'lan_revoked_title',
      desc: '',
      args: [],
    );
  }

  /// `An admin removed it from the server. Pair it again to keep using it.`
  String get lan_revoked_subtitle {
    return Intl.message(
      'An admin removed it from the server. Pair it again to keep using it.',
      name: 'lan_revoked_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Pair again`
  String get lan_pair_again {
    return Intl.message(
      'Pair again',
      name: 'lan_pair_again',
      desc: '',
      args: [],
    );
  }

  /// `This device isn't paired`
  String get lan_unpaired_title {
    return Intl.message(
      'This device isn\'t paired',
      name: 'lan_unpaired_title',
      desc: '',
      args: [],
    );
  }

  /// `Pair it with the server, or use Lyra another way.`
  String get lan_unpaired_subtitle {
    return Intl.message(
      'Pair it with the server, or use Lyra another way.',
      name: 'lan_unpaired_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Update Lyra`
  String get lan_update_title {
    return Intl.message(
      'Update Lyra',
      name: 'lan_update_title',
      desc: '',
      args: [],
    );
  }

  /// `This app and the server don't speak the same version. Update Lyra on both.`
  String get lan_update_subtitle {
    return Intl.message(
      'This app and the server don\'t speak the same version. Update Lyra on both.',
      name: 'lan_update_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `The server couldn't start`
  String get lan_error_title {
    return Intl.message(
      'The server couldn\'t start',
      name: 'lan_error_title',
      desc: '',
      args: [],
    );
  }

  /// `Code: {code}`
  String lan_error_code(Object code) {
    return Intl.message(
      'Code: $code',
      name: 'lan_error_code',
      desc: '',
      args: [code],
    );
  }

  /// `Use Lyra another way`
  String get lan_leave {
    return Intl.message(
      'Use Lyra another way',
      name: 'lan_leave',
      desc: '',
      args: [],
    );
  }

  /// `Stop using this server here?`
  String get lan_leave_title {
    return Intl.message(
      'Stop using this server here?',
      name: 'lan_leave_title',
      desc: '',
      args: [],
    );
  }

  /// `This device forgets its pairing and goes back to the sign in. The server and its data stay as they are.`
  String get lan_leave_message {
    return Intl.message(
      'This device forgets its pairing and goes back to the sign in. The server and its data stay as they are.',
      name: 'lan_leave_message',
      desc: '',
      args: [],
    );
  }

  /// `This device: {code}`
  String lan_device_code(Object code) {
    return Intl.message(
      'This device: $code',
      name: 'lan_device_code',
      desc: '',
      args: [code],
    );
  }

  /// `Server fingerprint`
  String get lan_fingerprint {
    return Intl.message(
      'Server fingerprint',
      name: 'lan_fingerprint',
      desc: '',
      args: [],
    );
  }

  /// `Devices`
  String get lan_devices {
    return Intl.message(
      'Devices',
      name: 'lan_devices',
      desc: '',
      args: [],
    );
  }

  /// `online`
  String get lan_devices_online {
    return Intl.message(
      'online',
      name: 'lan_devices_online',
      desc: '',
      args: [],
    );
  }

  /// `removed`
  String get lan_devices_revoked {
    return Intl.message(
      'removed',
      name: 'lan_devices_revoked',
      desc: '',
      args: [],
    );
  }

  /// `server`
  String get lan_devices_master {
    return Intl.message(
      'server',
      name: 'lan_devices_master',
      desc: '',
      args: [],
    );
  }

  /// `offline`
  String get lan_devices_offline {
    return Intl.message(
      'offline',
      name: 'lan_devices_offline',
      desc: '',
      args: [],
    );
  }

  /// `this device`
  String get lan_devices_this {
    return Intl.message(
      'this device',
      name: 'lan_devices_this',
      desc: '',
      args: [],
    );
  }

  /// `{count} connected`
  String lan_devices_connected(int count) {
    return Intl.message(
      '$count connected',
      name: 'lan_devices_connected',
      desc: '',
      args: [count],
    );
  }

  /// `Remove`
  String get lan_devices_remove {
    return Intl.message(
      'Remove',
      name: 'lan_devices_remove',
      desc: '',
      args: [],
    );
  }

  /// `Remove {name}?`
  String lan_devices_remove_title(Object name) {
    return Intl.message(
      'Remove $name?',
      name: 'lan_devices_remove_title',
      desc: '',
      args: [name],
    );
  }

  /// `Its sessions end now, and it can't connect again until it's paired again.`
  String get lan_devices_remove_message {
    return Intl.message(
      'Its sessions end now, and it can\'t connect again until it\'s paired again.',
      name: 'lan_devices_remove_message',
      desc: '',
      args: [],
    );
  }

  /// `Add device`
  String get lan_add_device {
    return Intl.message(
      'Add device',
      name: 'lan_add_device',
      desc: '',
      args: [],
    );
  }

  /// `Type this code on the new device`
  String get lan_pairing_code {
    return Intl.message(
      'Type this code on the new device',
      name: 'lan_pairing_code',
      desc: '',
      args: [],
    );
  }

  /// `It works for one device, {time} left.`
  String lan_pairing_expires(String time) {
    return Intl.message(
      'It works for one device, $time left.',
      name: 'lan_pairing_expires',
      desc: '',
      args: [time],
    );
  }

  /// `This code expired. Ask for a new one to add the device.`
  String get lan_pairing_expired {
    return Intl.message(
      'This code expired. Ask for a new one to add the device.',
      name: 'lan_pairing_expired',
      desc: '',
      args: [],
    );
  }

  /// `New code`
  String get lan_pairing_new {
    return Intl.message(
      'New code',
      name: 'lan_pairing_new',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get lan_pairing_close {
    return Intl.message(
      'Close',
      name: 'lan_pairing_close',
      desc: '',
      args: [],
    );
  }

  /// `Or, on a phone, scan this QR with Lyra.`
  String get lan_pairing_scan {
    return Intl.message(
      'Or, on a phone, scan this QR with Lyra.',
      name: 'lan_pairing_scan',
      desc: '',
      args: [],
    );
  }

  /// `Scan the QR on the server`
  String get lan_scan_button {
    return Intl.message(
      'Scan the QR on the server',
      name: 'lan_scan_button',
      desc: '',
      args: [],
    );
  }

  /// `Scan the server's QR`
  String get lan_scan_title {
    return Intl.message(
      'Scan the server\'s QR',
      name: 'lan_scan_title',
      desc: '',
      args: [],
    );
  }

  /// `Point the camera at the QR on the server's screen.`
  String get lan_scan_hint {
    return Intl.message(
      'Point the camera at the QR on the server\'s screen.',
      name: 'lan_scan_hint',
      desc: '',
      args: [],
    );
  }

  /// `That QR isn't a Lyra pairing code. Scan the one on the server's screen.`
  String get lan_scan_foreign {
    return Intl.message(
      'That QR isn\'t a Lyra pairing code. Scan the one on the server\'s screen.',
      name: 'lan_scan_foreign',
      desc: '',
      args: [],
    );
  }

  /// `The camera isn't available. Allow Lyra to use it, or type the code instead.`
  String get lan_scan_no_camera {
    return Intl.message(
      'The camera isn\'t available. Allow Lyra to use it, or type the code instead.',
      name: 'lan_scan_no_camera',
      desc: '',
      args: [],
    );
  }

  /// `Or type the code it shows`
  String get lan_pair_or_code {
    return Intl.message(
      'Or type the code it shows',
      name: 'lan_pair_or_code',
      desc: '',
      args: [],
    );
  }

  /// `This browser will pair with the server at {address}.`
  String lan_pair_browser(String address) {
    return Intl.message(
      'This browser will pair with the server at $address.',
      name: 'lan_pair_browser',
      desc: '',
      args: [address],
    );
  }

  /// `Open Lyra in a browser on this network`
  String get lan_address_title {
    return Intl.message(
      'Open Lyra in a browser on this network',
      name: 'lan_address_title',
      desc: '',
      args: [],
    );
  }

  /// `Copy`
  String get lan_address_copy {
    return Intl.message(
      'Copy',
      name: 'lan_address_copy',
      desc: '',
      args: [],
    );
  }

  /// `Address copied`
  String get lan_address_copied {
    return Intl.message(
      'Address copied',
      name: 'lan_address_copied',
      desc: '',
      args: [],
    );
  }

  /// `Web browsers`
  String get lan_browsers_title {
    return Intl.message(
      'Web browsers',
      name: 'lan_browsers_title',
      desc: '',
      args: [],
    );
  }

  /// `A browser opens Lyra from the server only on a computer that trusts this server's certificate. Install it here, or save it and install it on the other computer.`
  String get lan_browsers_subtitle {
    return Intl.message(
      'A browser opens Lyra from the server only on a computer that trusts this server\'s certificate. Install it here, or save it and install it on the other computer.',
      name: 'lan_browsers_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Certificate fingerprint (SHA-256)`
  String get lan_browsers_fingerprint {
    return Intl.message(
      'Certificate fingerprint (SHA-256)',
      name: 'lan_browsers_fingerprint',
      desc: '',
      args: [],
    );
  }

  /// `Windows shows it as its thumbprint (SHA-1)`
  String get lan_browsers_thumbprint {
    return Intl.message(
      'Windows shows it as its thumbprint (SHA-1)',
      name: 'lan_browsers_thumbprint',
      desc: '',
      args: [],
    );
  }

  /// `Install on this computer`
  String get lan_browsers_install {
    return Intl.message(
      'Install on this computer',
      name: 'lan_browsers_install',
      desc: '',
      args: [],
    );
  }

  /// `Installed. Browsers on this computer now trust the server; restart any that were open.`
  String get lan_browsers_installed {
    return Intl.message(
      'Installed. Browsers on this computer now trust the server; restart any that were open.',
      name: 'lan_browsers_installed',
      desc: '',
      args: [],
    );
  }

  /// `It wasn't installed. You can save it and install it by hand.`
  String get lan_browsers_not_installed {
    return Intl.message(
      'It wasn\'t installed. You can save it and install it by hand.',
      name: 'lan_browsers_not_installed',
      desc: '',
      args: [],
    );
  }

  /// `Save the certificate`
  String get lan_browsers_save {
    return Intl.message(
      'Save the certificate',
      name: 'lan_browsers_save',
      desc: '',
      args: [],
    );
  }

  /// `Saved. When installing it on the other computer, check that the fingerprint it shows is the one above.`
  String get lan_browsers_saved {
    return Intl.message(
      'Saved. When installing it on the other computer, check that the fingerprint it shows is the one above.',
      name: 'lan_browsers_saved',
      desc: '',
      args: [],
    );
  }

  /// `Then open the address above in the browser.`
  String get lan_browsers_open {
    return Intl.message(
      'Then open the address above in the browser.',
      name: 'lan_browsers_open',
      desc: '',
      args: [],
    );
  }

  /// `If that name doesn't open, use {address}.`
  String lan_browsers_fallback(String address) {
    return Intl.message(
      'If that name doesn\'t open, use $address.',
      name: 'lan_browsers_fallback',
      desc: '',
      args: [address],
    );
  }

  /// `Sign out`
  String get lan_sign_out {
    return Intl.message(
      'Sign out',
      name: 'lan_sign_out',
      desc: '',
      args: [],
    );
  }

  /// `Stop the server`
  String get lan_stop_server {
    return Intl.message(
      'Stop the server',
      name: 'lan_stop_server',
      desc: '',
      args: [],
    );
  }

  /// `Stop the server?`
  String get lan_stop_server_title {
    return Intl.message(
      'Stop the server?',
      name: 'lan_stop_server_title',
      desc: '',
      args: [],
    );
  }

  /// `{count} other devices are connected. Every device stops working until the server starts again.`
  String lan_stop_server_message(Object count) {
    return Intl.message(
      '$count other devices are connected. Every device stops working until the server starts again.',
      name: 'lan_stop_server_message',
      desc: '',
      args: [count],
    );
  }

  /// `Use this server with {company}?`
  String hybrid_link_title(Object company) {
    return Intl.message(
      'Use this server with $company?',
      name: 'hybrid_link_title',
      desc: '',
      args: [company],
    );
  }

  /// `Which of your companies is this server?`
  String get hybrid_link_pick_title {
    return Intl.message(
      'Which of your companies is this server?',
      name: 'hybrid_link_pick_title',
      desc: '',
      args: [],
    );
  }

  /// `This computer keeps your company's information so Lyra keeps working when the internet goes down. Joining it with your company online keeps both the same, and lets you use messages and channels from here too.`
  String get hybrid_link_subtitle {
    return Intl.message(
      'This computer keeps your company\'s information so Lyra keeps working when the internet goes down. Joining it with your company online keeps both the same, and lets you use messages and channels from here too.',
      name: 'hybrid_link_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Join`
  String get hybrid_link_join {
    return Intl.message(
      'Join',
      name: 'hybrid_link_join',
      desc: '',
      args: [],
    );
  }

  /// `Not now`
  String get hybrid_link_later {
    return Intl.message(
      'Not now',
      name: 'hybrid_link_later',
      desc: '',
      args: [],
    );
  }

  /// `Done. This server and {company} now work together.`
  String hybrid_link_done(Object company) {
    return Intl.message(
      'Done. This server and $company now work together.',
      name: 'hybrid_link_done',
      desc: '',
      args: [company],
    );
  }

  /// `Your server password`
  String get hybrid_password_title {
    return Intl.message(
      'Your server password',
      name: 'hybrid_password_title',
      desc: '',
      args: [],
    );
  }

  /// `This computer works with a Lyra server. Type the password you use on it once, and you'll stay signed in here even without the internet.`
  String get hybrid_password_subtitle {
    return Intl.message(
      'This computer works with a Lyra server. Type the password you use on it once, and you\'ll stay signed in here even without the internet.',
      name: 'hybrid_password_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Not now`
  String get hybrid_password_later {
    return Intl.message(
      'Not now',
      name: 'hybrid_password_later',
      desc: '',
      args: [],
    );
  }

  /// `Continue`
  String get hybrid_password_button {
    return Intl.message(
      'Continue',
      name: 'hybrid_password_button',
      desc: '',
      args: [],
    );
  }

  /// `Protected details`
  String get unseal_title {
    return Intl.message(
      'Protected details',
      name: 'unseal_title',
      desc: '',
      args: [],
    );
  }

  /// `You signed in online, so the server opened your session without your password. Type your password on the server to see payment accounts, pay and documents.`
  String get unseal_subtitle {
    return Intl.message(
      'You signed in online, so the server opened your session without your password. Type your password on the server to see payment accounts, pay and documents.',
      name: 'unseal_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Unlock`
  String get unseal_button {
    return Intl.message(
      'Unlock',
      name: 'unseal_button',
      desc: '',
      args: [],
    );
  }

  /// `Working online`
  String get server_online_title {
    return Intl.message(
      'Working online',
      name: 'server_online_title',
      desc: '',
      args: [],
    );
  }

  /// `Your information is on this server, and the online sections (messages, channels) work through the internet.`
  String get server_online_subtitle {
    return Intl.message(
      'Your information is on this server, and the online sections (messages, channels) work through the internet.',
      name: 'server_online_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Working offline`
  String get server_offline_title {
    return Intl.message(
      'Working offline',
      name: 'server_offline_title',
      desc: '',
      args: [],
    );
  }

  /// `Only this server is used. The online sections stay locked until you go back online. You stay signed in.`
  String get server_offline_subtitle {
    return Intl.message(
      'Only this server is used. The online sections stay locked until you go back online. You stay signed in.',
      name: 'server_offline_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Work offline`
  String get server_work_offline {
    return Intl.message(
      'Work offline',
      name: 'server_work_offline',
      desc: '',
      args: [],
    );
  }

  /// `Work online`
  String get server_work_online {
    return Intl.message(
      'Work online',
      name: 'server_work_online',
      desc: '',
      args: [],
    );
  }

  /// `Join with your company online`
  String get server_link_button {
    return Intl.message(
      'Join with your company online',
      name: 'server_link_button',
      desc: '',
      args: [],
    );
  }

  /// `Synced with your company online at {time}.`
  String server_sync_done(Object time) {
    return Intl.message(
      'Synced with your company online at $time.',
      name: 'server_sync_done',
      desc: '',
      args: [time],
    );
  }

  /// `Getting ready to sync with your company online.`
  String get server_sync_starting {
    return Intl.message(
      'Getting ready to sync with your company online.',
      name: 'server_sync_starting',
      desc: '',
      args: [],
    );
  }

  /// `Couldn't sync with your company online. It keeps trying.`
  String get server_sync_failing {
    return Intl.message(
      'Couldn\'t sync with your company online. It keeps trying.',
      name: 'server_sync_failing',
      desc: '',
      args: [],
    );
  }

  /// `Another server already syncs your company online, so this one doesn't.`
  String get server_sync_taken {
    return Intl.message(
      'Another server already syncs your company online, so this one doesn\'t.',
      name: 'server_sync_taken',
      desc: '',
      args: [],
    );
  }

  /// `This server was unlinked from your company online. It keeps working here only.`
  String get server_sync_revoked {
    return Intl.message(
      'This server was unlinked from your company online. It keeps working here only.',
      name: 'server_sync_revoked',
      desc: '',
      args: [],
    );
  }

  /// `Use this server`
  String get server_sync_use_this {
    return Intl.message(
      'Use this server',
      name: 'server_sync_use_this',
      desc: '',
      args: [],
    );
  }

  /// `Sync again`
  String get server_sync_link_again {
    return Intl.message(
      'Sync again',
      name: 'server_sync_link_again',
      desc: '',
      args: [],
    );
  }

  /// `Sync this server instead?`
  String get server_sync_replace_title {
    return Intl.message(
      'Sync this server instead?',
      name: 'server_sync_replace_title',
      desc: '',
      args: [],
    );
  }

  /// `The other server stops syncing with your company online. It keeps its information and keeps working on its own.`
  String get server_sync_replace_message {
    return Intl.message(
      'The other server stops syncing with your company online. It keeps its information and keeps working on its own.',
      name: 'server_sync_replace_message',
      desc: '',
      args: [],
    );
  }

  /// `Make this computer your server`
  String get server_create_title {
    return Intl.message(
      'Make this computer your server',
      name: 'server_create_title',
      desc: '',
      args: [],
    );
  }

  /// `Lyra keeps a copy of {company} on this computer, so you keep working when the internet goes down. The other devices of your place connect to it.`
  String server_create_subtitle(Object company) {
    return Intl.message(
      'Lyra keeps a copy of $company on this computer, so you keep working when the internet goes down. The other devices of your place connect to it.',
      name: 'server_create_subtitle',
      desc: '',
      args: [company],
    );
  }

  /// `Create the server here`
  String get server_create_button {
    return Intl.message(
      'Create the server here',
      name: 'server_create_button',
      desc: '',
      args: [],
    );
  }

  /// `Only the owner of {company} can create its server.`
  String server_create_owner_only(Object company) {
    return Intl.message(
      'Only the owner of $company can create its server.',
      name: 'server_create_owner_only',
      desc: '',
      args: [company],
    );
  }

  /// `Your server isn't answering`
  String get server_away_title {
    return Intl.message(
      'Your server isn\'t answering',
      name: 'server_away_title',
      desc: '',
      args: [],
    );
  }

  /// `This device works with a Lyra server, but it doesn't answer right now. Meanwhile you keep working online.`
  String get server_away_subtitle {
    return Intl.message(
      'This device works with a Lyra server, but it doesn\'t answer right now. Meanwhile you keep working online.',
      name: 'server_away_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Lyra can't run the server on this computer.`
  String get server_cannot_host {
    return Intl.message(
      'Lyra can\'t run the server on this computer.',
      name: 'server_cannot_host',
      desc: '',
      args: [],
    );
  }

  /// `The internet is back`
  String get server_back_title {
    return Intl.message(
      'The internet is back',
      name: 'server_back_title',
      desc: '',
      args: [],
    );
  }

  /// `You're signed in on this server only. Sign in online to open the online sections (messages, channels) here too. You stay signed in on the server.`
  String get server_back_subtitle {
    return Intl.message(
      'You\'re signed in on this server only. Sign in online to open the online sections (messages, channels) here too. You stay signed in on the server.',
      name: 'server_back_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Sign in online`
  String get server_sign_in_online {
    return Intl.message(
      'Sign in online',
      name: 'server_sign_in_online',
      desc: '',
      args: [],
    );
  }

  /// `This section works through the cloud. The internet is back: sign in online to open it.`
  String get section_needs_sign_in_subtitle {
    return Intl.message(
      'This section works through the cloud. The internet is back: sign in online to open it.',
      name: 'section_needs_sign_in_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `This section works through the cloud. When the internet is back, sign in online to open it.`
  String get section_needs_internet_master_subtitle {
    return Intl.message(
      'This section works through the cloud. When the internet is back, sign in online to open it.',
      name: 'section_needs_internet_master_subtitle',
      desc: '',
      args: [],
    );
  }

  /// `Sign in online`
  String get online_sign_in_title {
    return Intl.message(
      'Sign in online',
      name: 'online_sign_in_title',
      desc: '',
      args: [],
    );
  }

  /// `Type your Lyra password for {email}. You stay signed in on this server.`
  String online_sign_in_password(Object email) {
    return Intl.message(
      'Type your Lyra password for $email. You stay signed in on this server.',
      name: 'online_sign_in_password',
      desc: '',
      args: [email],
    );
  }

  /// `We sent a code to {email}. Type it to sign in online. You stay signed in on this server.`
  String online_sign_in_code(Object email) {
    return Intl.message(
      'We sent a code to $email. Type it to sign in online. You stay signed in on this server.',
      name: 'online_sign_in_code',
      desc: '',
      args: [email],
    );
  }

  /// `Sign in`
  String get online_sign_in_button {
    return Intl.message(
      'Sign in',
      name: 'online_sign_in_button',
      desc: '',
      args: [],
    );
  }

  /// `There's no online Lyra account for {email} yet. We sent a code to it: type it to create one. You stay signed in on this server.`
  String online_sign_in_sign_up(Object email) {
    return Intl.message(
      'There\'s no online Lyra account for $email yet. We sent a code to it: type it to create one. You stay signed in on this server.',
      name: 'online_sign_in_sign_up',
      desc: '',
      args: [email],
    );
  }

  /// `Create account`
  String get online_sign_in_create {
    return Intl.message(
      'Create account',
      name: 'online_sign_in_create',
      desc: '',
      args: [],
    );
  }

  /// `This account signs in another way, which Lyra doesn't offer here yet.`
  String get online_sign_in_unsupported {
    return Intl.message(
      'This account signs in another way, which Lyra doesn\'t offer here yet.',
      name: 'online_sign_in_unsupported',
      desc: '',
      args: [],
    );
  }

  /// `You signed in online, but this server didn't take the session. Try again in a moment.`
  String get online_sign_in_failed {
    return Intl.message(
      'You signed in online, but this server didn\'t take the session. Try again in a moment.',
      name: 'online_sign_in_failed',
      desc: '',
      args: [],
    );
  }

  /// `You're online`
  String get online_sign_in_done {
    return Intl.message(
      'You\'re online',
      name: 'online_sign_in_done',
      desc: '',
      args: [],
    );
  }

  /// `Not now`
  String get online_sign_in_later {
    return Intl.message(
      'Not now',
      name: 'online_sign_in_later',
      desc: '',
      args: [],
    );
  }

  /// `Close`
  String get online_sign_in_close {
    return Intl.message(
      'Close',
      name: 'online_sign_in_close',
      desc: '',
      args: [],
    );
  }

  /// `Pending`
  String get badges_title {
    return Intl.message(
      'Pending',
      name: 'badges_title',
      desc: '',
      args: [],
    );
  }

  /// `Connected to the server`
  String get connection_live_online {
    return Intl.message(
      'Connected to the server',
      name: 'connection_live_online',
      desc: '',
      args: [],
    );
  }

  /// `Connecting to the server`
  String get connection_live_connecting {
    return Intl.message(
      'Connecting to the server',
      name: 'connection_live_connecting',
      desc: '',
      args: [],
    );
  }

  /// `No connection to the server`
  String get connection_live_offline {
    return Intl.message(
      'No connection to the server',
      name: 'connection_live_offline',
      desc: '',
      args: [],
    );
  }

  /// `Nothing pending`
  String get badges_empty {
    return Intl.message(
      'Nothing pending',
      name: 'badges_empty',
      desc: '',
      args: [],
    );
  }

  /// `Dismiss`
  String get badges_dismiss {
    return Intl.message(
      'Dismiss',
      name: 'badges_dismiss',
      desc: '',
      args: [],
    );
  }

  /// `Mark as read`
  String get badges_mark_read {
    return Intl.message(
      'Mark as read',
      name: 'badges_mark_read',
      desc: '',
      args: [],
    );
  }

  /// `Something needs your attention`
  String get badge_unknown {
    return Intl.message(
      'Something needs your attention',
      name: 'badge_unknown',
      desc: '',
      args: [],
    );
  }

  /// `Conversations waiting for a person`
  String get badge_chats_attention {
    return Intl.message(
      'Conversations waiting for a person',
      name: 'badge_chats_attention',
      desc: '',
      args: [],
    );
  }

  /// `Appointments today and tomorrow`
  String get badge_appointments_upcoming {
    return Intl.message(
      'Appointments today and tomorrow',
      name: 'badge_appointments_upcoming',
      desc: '',
      args: [],
    );
  }

  /// `Holds a customer is waiting on`
  String get badge_reservations_pending {
    return Intl.message(
      'Holds a customer is waiting on',
      name: 'badge_reservations_pending',
      desc: '',
      args: [],
    );
  }

  /// `Tickets left open on a till`
  String get badge_pos_invoices {
    return Intl.message(
      'Tickets left open on a till',
      name: 'badge_pos_invoices',
      desc: '',
      args: [],
    );
  }

  /// `Sales on credit still owed`
  String get badge_money_receivables {
    return Intl.message(
      'Sales on credit still owed',
      name: 'badge_money_receivables',
      desc: '',
      args: [],
    );
  }

  /// `Unseen notifications`
  String get badge_notifications_unseen {
    return Intl.message(
      'Unseen notifications',
      name: 'badge_notifications_unseen',
      desc: '',
      args: [],
    );
  }

  /// `Set the company's country`
  String get badge_setup_country {
    return Intl.message(
      'Set the company\'s country',
      name: 'badge_setup_country',
      desc: '',
      args: [],
    );
  }

  /// `Add a way to get paid`
  String get badge_setup_payments {
    return Intl.message(
      'Add a way to get paid',
      name: 'badge_setup_payments',
      desc: '',
      args: [],
    );
  }

  /// `Create your product catalog`
  String get badge_setup_catalog {
    return Intl.message(
      'Create your product catalog',
      name: 'badge_setup_catalog',
      desc: '',
      args: [],
    );
  }

  /// `Connect a channel for your assistant`
  String get badge_setup_channels {
    return Intl.message(
      'Connect a channel for your assistant',
      name: 'badge_setup_channels',
      desc: '',
      args: [],
    );
  }

  /// `Add your company's logo`
  String get badge_setup_logo {
    return Intl.message(
      'Add your company\'s logo',
      name: 'badge_setup_logo',
      desc: '',
      args: [],
    );
  }

  /// `New terms and conditions to accept`
  String get badge_legal_terms {
    return Intl.message(
      'New terms and conditions to accept',
      name: 'badge_legal_terms',
      desc: '',
      args: [],
    );
  }

  /// `New: Finance`
  String get badge_news_money {
    return Intl.message(
      'New: Finance',
      name: 'badge_news_money',
      desc: '',
      args: [],
    );
  }
}

class AppLocalizationDelegate extends LocalizationsDelegate<S> {
  const AppLocalizationDelegate();

  List<Locale> get supportedLocales {
    return const <Locale>[
      Locale.fromSubtags(languageCode: 'en'),
    ];
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
