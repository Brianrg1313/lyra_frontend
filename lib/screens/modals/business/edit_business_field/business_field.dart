// WIDGETS
import 'package:core/form.dart';

/// An editable business data point: with what key it travels to the backend,
/// what is saved today and what it is written with.
///
/// It lives here and not in the profile card because it is what the form needs
/// to build itself: whoever draws a row describes its data point once and does
/// not have to know anything about the modal that changes it.
///
/// A data point with options is **chosen** and one without them is **written**:
/// that is the only difference between the two, and the data point itself
/// decides it. It also decides where it is changed: the ones that are written
/// open the single-field modal (`EditBusinessFieldModal`), the ones that are
/// chosen unfold their list in the same row of the card
/// (`ProfileSelectField`).
class BusinessField {
  const BusinessField.text({
    required this.key,
    required this.value,
    this.pattern = "IGNORE",
    this.hint,
    this.min,
    this.max,
    this.type = InputType.text,
    this.obligatory = false
  }) : options = const [];

  /// A data point chosen from a closed list (the sector, the language, the
  /// currency). It is always obligatory: the list does not have a "none"
  /// option, and unfolding it to choose nothing is closing it, not emptying
  /// the data point.
  const BusinessField.select({
    required this.key,
    required this.value,
    required this.options
  }) : pattern = "IGNORE",
       hint = null,
       min = null,
       max = null,
       type = InputType.select,
       obligatory = true;

  /// Key with which the data point travels in `PUT /business/profile/`
  /// (`LEGAL_NAME`, `ACTIVITY_TYPE`...). It is the same key with which it is
  /// created.
  final String key;

  /// What is saved, **in the form in which it travels**: the code of the
  /// option in the chosen ones (`RETAIL`) and not the translated label that is
  /// read in the card. It is what opens the form filled.
  final String value;

  /// The options, when the data point is chosen. Empty is a text field.
  final List<SelectOption> options;

  final String pattern;

  /// What shape what is expected has, for the data points where the field name
  /// is not enough (a date, a country code).
  final String? hint;

  final int? min;
  final int? max;
  final InputType type;

  /// Whether the data point can be left empty. Almost the whole profile can
  /// be: a newly created business has the name, the sector and little else.
  final bool obligatory;
}