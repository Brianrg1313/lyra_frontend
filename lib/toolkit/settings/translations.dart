import 'package:app/generated/l10n.dart';
import 'package:core/kit/translations.dart';

final translations = Translations(
  hideKeyboard: (context) => context == null
    ? S.current.hide_keyboard
    : S.of(context).hide_keyboard,
  connectionError: (context) => context == null
    ? S.current.connectionError
    : S.of(context).connectionError
);