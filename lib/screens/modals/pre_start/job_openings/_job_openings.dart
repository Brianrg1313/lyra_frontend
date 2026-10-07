import 'package:flutter/material.dart';
import 'package:app/toolkit/toolkit.dart';

// WIDGETS
import 'package:app/screens/home/sections/_section/section_message.dart';

/// Placeholder: the backend has no job openings endpoint yet.
class JobOpeningsModal extends StatelessWidget {
  const JobOpeningsModal({super.key});

  @override
  Widget build(BuildContext context) => ScrollableWidget(
    padding: EdgeInsets.only(bottom: AppSize.padding),
    children: [
      SectionMessage(
        icon: CI.employee_badge,
        title: S.of(context).welcome_jobs_modal_title,
        subtitle: S.of(context).welcome_jobs_body
      )
    ]
  );
}
