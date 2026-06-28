import 'package:drift/drift.dart';
import 'categories_table.dart';

class Transactions extends Table {
  TextColumn get id => text()();
  TextColumn get type => text()();
  IntColumn get amount => integer()();
  TextColumn get categoryId => text().references(Categories, #id)();
  DateTimeColumn get date => dateTime()();
  TextColumn get note => text().nullable()();
  TextColumn get paymentMethod => text()();
  TextColumn get receiptImagePath => text().nullable()();
  TextColumn get aiRawResponse => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column> get primaryKey => {id};
}
