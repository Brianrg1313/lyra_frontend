import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

/// Aviso legal del alta de empresa.
///
/// Deja claro, antes de crear nada, que los datos deben ser los reales y que
/// no aportar la documentacion que se pida mas adelante alcanza tambien al
/// perfil que creo la empresa y a quienes la administran.
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
