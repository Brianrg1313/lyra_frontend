import 'package:flutter_test/flutter_test.dart';

import 'package:app/services/catalog/phone_plan.dart';

void main() {
  test('drops the trunk zero written at home', () {
    expect(PhonePlan.national("58", "04126766990"), "4126766990");
    expect(PhonePlan.national("58", "0412-676 6990"), "4126766990");
  });

  test('keeps the zero where the plan dials it from abroad', () {
    expect(PhonePlan.national("39", "0612345678"), "0612345678");
  });

  test('a Venezuelan number has ten digits after the code', () {
    final plan = PhonePlan.of("58");

    expect(plan.fits("4126766990"), isTrue);
    expect(plan.fits(PhonePlan.national("58", "0412676690")), isFalse);
    expect(plan.fits("41267669901"), isFalse);
  });

  test('a code written with its area still reads its plan', () {
    final plan = PhonePlan.of("1809");

    expect(plan.min, 7);
    expect(plan.max, 7);
  });

  test('an unknown code gets the E.164 bounds', () {
    final plan = PhonePlan.of("999");

    expect(plan.min, 4);
    expect(plan.max, 12);
  });
}
