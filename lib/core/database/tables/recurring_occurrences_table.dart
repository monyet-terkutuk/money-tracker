import 'package:drift/drift.dart';

class RecurringOccurrences extends Table {
  TextColumn get id => text()();
  TextColumn get recurringId => text()();
  TextColumn get periodKey => text()();
  TextColumn get transactionId => text()();

  @override
  Set<Column> get primaryKey => {id};

  @override
  List<Set<Column>> get uniqueKeys => [
        {recurringId, periodKey},
      ];
}
