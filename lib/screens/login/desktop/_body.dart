import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app/toolkit/toolkit.dart';

// SERVICES
import 'package:app/services/sign_in/sign_in_service.dart';

// WIDGETS
import 'package:core/form.dart';
import 'package:core/buttons.dart';

class DesktopBody extends StatefulWidget {
  const DesktopBody({super.key});

  @override
  State<DesktopBody> createState() => _DesktopBodyState();
}

class _DesktopBodyState extends State<DesktopBody> {
  final _form = FormController();

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
            TextLarge(S.of(context).sign_in),
            Padding(
              padding: EdgeInsets.only(
                top: AppSize.gap,
                bottom: AppSize.action
              ),
              child: TextMedium(S.of(context).sign_in_subtitle)
            ),
            Input(
              placeholder: S.of(context).email_input,
              controller: InputController.email(
                form: _form,
                obligatory: true,
                customErrors: {
                  InputError.long: S.of(context).form_long_ma(S.of(context).email_input),
                  InputError.empty: S.of(context).form_empty_ma(S.of(context).email_input),
                  InputError.invalid: S.of(context).form_invalid_ma(S.of(context).email_input),
                  InputError.incomplete: S.of(context).form_incomplete_ma(S.of(context).email_input)
                }
              )
            ),
            Input(
              placeholder: S.of(context).password_input,
              controller: InputController.password(
                form: _form,
                obligatory: true
              )
            ),
            SizedBox(height: AppSize.padding),
            Button(
              title: S.of(context).login,
              loading: _form.loading,
              action: _submit
            ),
            SizedBox(height: AppSize.action),
            FeedbackButton(
              color: ThemeColor.of(context).surface.withAlpha(0),
              action: () => Navis.push(context, "/sign_up"),
              feedbackColor: ThemeColor.of(context).surface,
              padding: EdgeInsets.symmetric(
                vertical: AppSize.spaceXS,
                horizontal: AppSize.spaceS
              ),
              child: TextMedium(
                S.of(context).dont_have_account,
                color: ThemeColor.of(context).primary
              )
            )
          ])
      )
    )
  );

  void _submit() {
    if (!_form.validate()) return;
    _form.loading.value = true;

    context.read<SignInService>().signIn(context, _form.data)
      .then((_) {
        if (!mounted) return;
        _form.loading.value = false;
      })
      .catchError((E) {
        if (!mounted) return;
        _form.loading.value = false;

        if (E is! String) return;

        _form.inputs["PASSWORD"]?.status.setStatus(InputStatus.error, InputError.invalid);
      });
  }
}
