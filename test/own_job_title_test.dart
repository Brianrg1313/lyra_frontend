import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/business/business_employee_model.dart';
import 'package:app/services/business/own_job_title_service.dart';
import 'package:app/services/business/sources/employees_source.dart';

/// The side bar's job title is the viewer's own row (`me`) of each company's staff list, read
/// once per company: a business switch back must not reread it, and a list the employees
/// section reads replaces it (a title edited there shows at once).
void main() {
  late _Source source;
  final service = OwnJobTitleService();

  setUp(() {
    source = _Source();
    service.source = source;
    service.clear();
  });

  tearDown(() => service.source = null);

  test("reads the viewer's row once per company", () async {
    source.rows = const [
      BusinessEmployeeModel(id: "1", jobTitle: "Cashier"),
      BusinessEmployeeModel(id: "2", me: true, jobTitle: " Manager ")
    ];

    await service.load("a");
    await service.load("a");

    expect(service.of("a"), "Manager");
    expect(source.reads, 1);
  });

  test("a failed read stays unknown, to retry", () async {
    source.fails = true;
    await service.load("a");
    expect(service.of("a"), isNull);

    source.fails = false;
    source.rows = const [BusinessEmployeeModel(me: true, jobTitle: "Owner")];
    await service.load("a");
    expect(service.of("a"), "Owner");
  });

  test("a list the section read replaces the title", () {
    service.remember("a", const [BusinessEmployeeModel(me: true, jobTitle: "Cashier")]);
    service.remember("a", const [BusinessEmployeeModel(me: true, jobTitle: "Manager")]);

    expect(service.of("a"), "Manager");
    expect(service.of("b"), isNull);
  });
}

class _Source extends Fake implements EmployeesSource {
  List<BusinessEmployeeModel> rows = const [];
  bool fails = false;
  int reads = 0;

  @override
  Future<(List<BusinessEmployeeModel>, int)> current() async {
    reads++;
    if (fails) throw {"message": "down"};
    return (rows, rows.length);
  }
}
