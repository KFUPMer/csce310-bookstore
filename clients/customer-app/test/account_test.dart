import 'dart:io';

import 'package:bookstore_ui/bookstore_ui.dart';
import 'package:customer_app/models/account.dart';
import 'package:customer_app/models/preferences.dart';
import 'package:flutter_test/flutter_test.dart';

PlacedItem item(String title, ItemType type, {DateTime? dueBack}) =>
    PlacedItem(title: title, author: 'Someone', type: type, quantity: 1, unitPrice: 4, dueBack: dueBack);

Order order(int id, List<PlacedItem> items) =>
    Order(id: id, username: 'alice', createdAt: DateTime(2026, 11, 10), paymentStatus: Order.pending, total: 4, items: items);

void main() {
  group('rentals due back', () {
    test('only rented books, soonest due first, each with its order', () {
      final rentals = rentalsOf([
        order(1043, [item('Effective Java', ItemType.rent, dueBack: DateTime(2026, 11, 24)), item('Clean Code', ItemType.buy)]),
        order(1042, [item('Refactoring', ItemType.rent, dueBack: DateTime(2026, 11, 20))]),
      ]);
      expect([for (final r in rentals) (r.title, r.orderId)], [('Refactoring', 1042), ('Effective Java', 1043)]);
    });

    test('how long until a book is due, in plain words', () {
      final today = DateTime(2026, 11, 17, 15, 30);
      expect(dueText(DateTime(2026, 11, 24), today), 'Due back in 7 days');
      expect(dueText(DateTime(2026, 11, 18), today), 'Due back tomorrow');
      expect(dueText(DateTime(2026, 11, 17), today), 'Due back today');
      expect(dueText(DateTime(2026, 11, 16), today), 'Was due back yesterday');
      expect(dueText(DateTime(2026, 11, 14), today), 'Was due back 3 days ago');
    });
  });

  group('preferences', () {
    late Directory folder;
    late File file;

    setUp(() {
      folder = Directory.systemTemp.createTempSync('bookstore-prefs');
      file = File('${folder.path}${Platform.pathSeparator}preferences.json');
    });
    tearDown(() => folder.deleteSync(recursive: true));

    test('are kept for each customer and read back on the next start', () {
      Preferences(file: file)
        ..loadFor('alice')
        ..update(darkMode: true, listView: true);
      final again = Preferences(file: file)..loadFor('alice');
      expect((again.darkMode, again.listView), (true, true));
      final bob = Preferences(file: file)..loadFor('bob');
      expect((bob.darkMode, bob.listView), (false, false), reason: 'another customer starts with the defaults');
    });

    test('a damaged file is ignored, not a crash', () {
      file.writeAsStringSync('{not json');
      final prefs = Preferences(file: file)..loadFor('alice');
      expect((prefs.darkMode, prefs.listView), (false, false));
      prefs.update(darkMode: true);
      expect((Preferences(file: file)..loadFor('alice')).darkMode, isTrue, reason: 'and is replaced by a good one');
    });

    test('after logging out, a change is not saved for the last customer', () {
      final prefs = Preferences(file: file)..loadFor('alice');
      prefs
        ..forget()
        ..update(darkMode: true);
      expect(prefs.darkMode, isTrue, reason: 'it still applies now');
      expect((Preferences(file: file)..loadFor('alice')).darkMode, isFalse);
    });

    test('without a file they still work for this run', () {
      final prefs = Preferences()..loadFor('alice');
      prefs.update(listView: true);
      expect(prefs.listView, isTrue);
    });
  });
}
