import 'package:drift/drift.dart';

class Categories extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text()();
  TextColumn get type => text()();
  BoolColumn get isDefault => boolean()();
  TextColumn get parentId => text().nullable()();
  IntColumn get sortOrder => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
