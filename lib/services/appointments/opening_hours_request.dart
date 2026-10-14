// SERVICES
import 'package:app/services/appointments/opening_hours_model.dart';

/// `PUT /appointments/hours`: the **whole** week of [branch]. The backend
/// replaces every row of the branch, so the rows of its services ([kept]) go
/// back as they were beside the branch's own [week]; an empty week leaves it
/// closed every day.
Map<String, dynamic> setWeekRequest(
  String branch,
  List<OpeningStretch> week, {
  List<OpeningStretch> kept = const []
}) => {
  "BRANCH": branch,
  "HOURS": [
    for (final row in [...week, ...kept]) {
      "WEEKDAY": row.weekday,
      "OPENS": row.opens,
      "CLOSES": row.closes,
      if (row.service != null) "SERVICE": row.service
    }
  ]
};

/// `POST /appointments/closures`: [day] closed in [branch], or in every branch
/// with none. Closing it again rewrites the reason.
Map<String, dynamic> closeDayRequest(String day, {String reason = "", String? branch}) => {
  "DAY": day,
  if (reason.trim().isNotEmpty) "REASON": reason.trim(),
  "BRANCH": ?branch
};

/// `DELETE /appointments/closures`: [closed] opens again where it was closed.
Map<String, dynamic> reopenDayRequest(ClosedDay closed) => {
  "DAY": closed.day,
  "BRANCH": ?closed.branch
};
