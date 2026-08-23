import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sign_up/sign_up_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/images.dart';
import 'package:core/button.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

class _DesktopBodyState extends State<DesktopBody> {
  final _form = FormController();

  // Letters (with accents/diaeresis), Ñ/ñ, spaces, apostrophes and hyphens for compound names.
  static const _namePattern = "[A-Za-zÀ-ÖØ-öø-ÿ' -]";

  late final _firstName = InputController(
    key: "FIRST_NAME",
    form: _form,
    pattern: _namePattern,
    max: 50,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).first_name_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).first_name_input),
      InputError.long: S.of(context).form_long_ma(S.of(context).first_name_input)
    }
  );

  late final _lastName = InputController(
    key: "LAST_NAME",
    form: _form,
    pattern: _namePattern,
    max: 50,
    obligatory: true,
    customErrors: {
      InputError.empty: S.of(context).form_empty_ma(S.of(context).last_name_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).last_name_input),
      InputError.long: S.of(context).form_long_ma(S.of(context).last_name_input)
    }
  );

  late final _email = InputController.email(
    form: _form,
    obligatory: true,
    customErrors: {
      InputError.long: S.of(context).form_long_ma(S.of(context).email_input),
      InputError.empty: S.of(context).form_empty_ma(S.of(context).email_input),
      InputError.invalid: S.of(context).form_invalid_ma(S.of(context).email_input),
      InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).email_input)
    }
  );

  @override
  void dispose() {
    _form.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Skeleton.simple(
    padding: EdgeInsets.all(AppSize.spaceM),
    body: Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: 300
        ),
        child: Column(
          mainAxisSize: MainAxisSize.max,
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            TextLarge(S.of(context).sign_up),
            Padding(
              padding: EdgeInsets.only(
                top: AppSize.gap,
                bottom: AppSize.action
              ),
              child: TextMedium(S.of(context).sign_up_subtitle)
            ),
            InputRow(
              spacing: AppSize.spaceXS,
              children: [
                Input(
                  placeholder: S.of(context).first_name_input,
                  controller: _firstName,
                  next: _lastName.focus
                ),
                Input(
                  placeholder: S.of(context).last_name_input,
                  controller: _lastName,
                  next: _email.focus
                )
              ]),
            Input(
              placeholder: S.of(context).email_input,
              controller: _email,
              onSubmit: _submit
            ),
            SizedBox(height: AppSize.spaceXS),
            Button(
              title: S.of(context).sign_up,
              loading: _form.loading,
              action: _submit
            ),
            Padding(
              padding: EdgeInsets.symmetric(vertical: AppSize.spaceM),
              child: Row(children: [
                Expanded(child: Separator.horizontal(
                  thickness: 1,
                  color: ThemeColor.of(context).surfaceFeedback
                )),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: AppSize.spaceS),
                  child: TextSmall("OR SIGN UP WITH")
                ),
                Expanded(child: Separator.horizontal(
                  thickness: 1,
                  color: ThemeColor.of(context).surfaceFeedback
                ))
              ])
            ),
            Row(children: [
              Expanded(child: Surface.line(
                height: AppSize.action,
                padding: EdgeInsets.all(AppSize.gap),
                child: Center(child: ImageDynamic(
                  "google.webp",
                ))
              )),
              SizedBox(width: AppSize.spaceS),
              Expanded(child: Surface.line(
                height: AppSize.action,
                padding: EdgeInsets.all(AppSize.gap),
                child: Center(child: ImageDynamic(
                  "facebook.webp",
                ))
              )),
              SizedBox(width: AppSize.spaceS),
              Expanded(child: Surface.line(
                height: AppSize.action,
                padding: EdgeInsets.all(AppSize.gap),
                child: Center(child: ImageDynamic(
                  "apple.webp"
                ))
              ))
            ]),
            SizedBox(height: AppSize.spaceS),
            FeedbackButton(
              color: ThemeColor.of(context).surface.withAlpha(0),
              feedbackColor: ThemeColor.of(context).surface,
              action: () => Navis.push(context, "/login"),
              padding: EdgeInsets.symmetric(
                vertical: AppSize.spaceXS,
                horizontal: AppSize.spaceS
              ),
              child: TextMedium(
                S.of(context).already_have_account,
                color: ThemeColor.of(context).primary
              )
            ),
            Padding(
              padding: EdgeInsets.only(top: AppSize.action),
              child: Wrap(
                alignment: WrapAlignment.center,
                children: [
                  TextSmall(S.of(context).sign_up_terms_prefix),
                  // TODO: link to the actual terms and conditions page
                  GestureDetector(
                    child: TextSmall(
                      S.of(context).sign_up_terms_link,
                      color: ThemeColor.of(context).primary
                    )
                  )
                ]
              )
            ),
          ])
      )
    )
  );

  void _submit() {
    if (!_form.validate()) return;

    _form.loading.value = true;

    context.read<SignUpService>().signUp(context, _form.data)
      .then((_) {
        if (!mounted) return;
        _form.loading.value = false;
        Navis.push(context, "/verify_code");
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;
      });
  }
}
