import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Legal notice for business creation.
///
/// Makes clear, before anything is created, that the data must be real and
/// that failing to provide the documentation requested later also reaches the
/// profile created by the business and the people who administer it.
class CreateBusinessNotice extends StatelessWidget {
  const CreateBusinessNotice({super.key});

  @override
  Widget build(BuildContext context) => Surface.line(
    padding: EdgeInsets.all(AppSize.spaceS),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Icon(
            CI.info,
            size: AppSize.text,
            color: ThemeColor.of(context).text.primary
          ),
          SizedBox(width: AppSize.gap),
          Expanded(child: TextMedium(S.of(context).business_notice_title))
        ]),
        SizedBox(height: AppSize.spaceXS),
        _paragraph(context, S.of(context).business_notice_real),
        _paragraph(context, S.of(context).business_notice_unverified),
        _paragraph(context, S.of(context).business_notice_documents, last: true)
      ])
  );

  Widget _paragraph(BuildContext context, String text, {bool last = false}) => Padding(
    padding: EdgeInsets.only(bottom: last ? 0 : AppSize.gap),
    child: TextSmall(text)
  );
}