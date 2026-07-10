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

  /// `password_input`
  String get password_input {
    return Intl.message(
      'password_input',
      name: 'password_input',
      desc: '',
      args: [],
    );
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
