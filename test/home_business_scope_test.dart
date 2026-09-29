import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:app/screens/home/sections/_sections.dart';
import 'package:app/screens/home/sections/page_switcher.dart';
import 'package:app/screens/home/sections/business/_business_detail.dart';
import 'package:app/screens/home/sections/business/business_tab.dart';
import 'package:app/screens/home/sections/inventory/table_list/_table_list.dart';
import 'package:app/screens/home/sections/inventory/table_view/_table_view.dart';

Key? _keyOf(String currentKey, HomeSection section, String? businessId) =>
  homeContent(currentKey, section, businessId).key;

PageSwitcher _switcherOf(String currentKey, HomeSection section) =>
  (homeContent(currentKey, section, "1842") as KeyedSubtree).child
    as PageSwitcher;

void main() {
  test('the content changes identity when the business changes', () {
    // This is what makes the section mount again instead of updating, and with
    // that request its data again: without it, it keeps showing the previous
    // business's.
    final one = _keyOf("inventory", HomeSection.inventory, "1842");
    final other = _keyOf("inventory", HomeSection.inventory, "77");

    expect(one, isNotNull);
    expect(one, isNot(other));
  });

  test('the same business keeps the identity of the content', () {
    // Otherwise any rebuild of the shell (collapsing the side bar, switching
    // section and back) would unmount the section and drop what it had loaded.
    expect(
      _keyOf("inventory", HomeSection.inventory, "1842"),
      _keyOf("inventory", HomeSection.inventory, "1842")
    );
  });

  test('every section stays inside the business scope', () {
    for (final section in HomeSection.values) {
      expect(
        _keyOf(section.key, section, "1842"),
        isNot(_keyOf(section.key, section, "77")),
        reason: "${section.key} does not follow the business"
      );
    }
  });

  test('the content is still the open screen', () {
    // The business scope and the page switcher wrap the content, they do not
    // replace it.
    Widget childOf(String currentKey, HomeSection section) =>
      _switcherOf(currentKey, section).child;

    expect(
      childOf(HomeSection.inventory.key, HomeSection.inventory),
      isA<InventorySection>()
    );
    expect(
      childOf(TableViewSection.routeKey, HomeSection.inventory),
      isA<TableViewSection>()
    );
    expect(
      childOf(BusinessDetailSection.routeKey, HomeSection.business),
      isA<BusinessDetailSection>()
    );
    // The business section is the business's page: there is no list in front
    // of it, and its tabs are the same screen.
    expect(
      childOf(HomeSection.business.key, HomeSection.business),
      isA<BusinessDetailSection>()
    );
    expect(
      childOf(BusinessTab.settings.routeKey, HomeSection.business),
      isA<BusinessDetailSection>()
    );
  });

  test('pages of one section animate, sections and tabs do not', () {
    // A sub-page is a new page id inside the same switcher: that is the swap
    // that fades.
    final list = _switcherOf(HomeSection.inventory.key, HomeSection.inventory);
    final table = _switcherOf(TableViewSection.routeKey, HomeSection.inventory);

    expect(list.key, table.key);
    expect(list.id, isNot(table.id));

    // Another section is another switcher, which mounts without animating.
    final channels = _switcherOf(HomeSection.channels.key, HomeSection.channels);
    expect(channels.key, isNot(list.key));

    // The tabs of the business are one page for the shell: the section animates
    // its own body, below the tab bar.
    expect(
      _switcherOf(HomeSection.business.key, HomeSection.business).id,
      _switcherOf(BusinessTab.settings.routeKey, HomeSection.business).id
    );
  });
}
