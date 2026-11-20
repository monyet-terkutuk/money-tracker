import 'package:drift/drift.dart';
import 'transactions_table.dart';

class ReceiptItems extends Table {
  TextColumn get id => text()();
  TextColumn get transactionId =>
      text().references(Transactions, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  IntColumn get price => integer()();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  TextColumn get storeName => text().nullable()();
  IntColumn get position => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {id};
}
