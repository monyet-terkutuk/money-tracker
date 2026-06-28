import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/transactions/presentation/transaction_list_screen.dart';
import '../../features/transactions/presentation/add_transaction_screen.dart';
import '../../features/transactions/presentation/transaction_detail_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/transactions',
      name: 'transactionList',
      builder: (context, state) {
        final type = state.uri.queryParameters['type'];
        return TransactionListScreen(filterType: type);
      },
    ),
    GoRoute(
      path: '/transactions/add',
      name: 'addTransaction',
      builder: (context, state) => const AddTransactionScreen(),
    ),
    GoRoute(
      path: '/transactions/:id',
      name: 'transactionDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return TransactionDetailScreen(id: id);
      },
    ),
    GoRoute(
      path: '/scan',
      name: 'scan',
      builder: (context, state) => const ScanScreen(),
    ),
    GoRoute(
      path: '/categories',
      name: 'categories',
      builder: (context, state) => const CategoriesScreen(),
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
