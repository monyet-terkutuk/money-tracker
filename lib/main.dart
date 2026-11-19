import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'app.dart';
import 'core/database/app_database.dart';
import 'features/transactions/domain/category_providers.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id', null);

  final db = AppDatabase();
  final notifier = CategoryNotifier(db);
  await notifier.seedDefaultCategories();
  await db.close();

  runApp(const ProviderScope(child: CatatUangApp()));
}
