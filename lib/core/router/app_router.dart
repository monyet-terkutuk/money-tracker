import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../database/app_database.dart';
import '../../features/home/presentation/home_screen.dart';
import '../../features/insights/presentation/insights_hub_screen.dart';
import '../../features/splash/presentation/splash_screen.dart';
import '../../shared/widgets/main_shell.dart';
import '../../features/transactions/presentation/transaction_list_screen.dart';
import '../../features/transactions/presentation/add_transaction_screen.dart';
import '../../features/transactions/presentation/transaction_detail_screen.dart';
import '../../features/scan/presentation/scan_screen.dart';
import '../../features/categories/presentation/categories_screen.dart';
import '../../features/categories/presentation/category_detail_screen.dart';
import '../../features/price_memory/presentation/price_memory_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/recurring/presentation/recurring_screen.dart';
import '../../features/wishlist/presentation/wishlist_screen.dart';
import '../../features/wallets/presentation/wallets_screen.dart';
import '../../features/goals/presentation/savings_goals_screen.dart';
import '../../features/pending_income/presentation/pending_income_screen.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final appRouter = GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: '/splash',
  routes: [
    GoRoute(
      path: '/splash',
      name: 'splash',
      builder: (context, state) => const SplashScreen(),
    ),
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          MainShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/mutasi',
              name: 'mutasi',
              builder: (context, state) => const TransactionListScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/insights',
              name: 'insights',
              builder: (context, state) => const InsightsHubScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
    GoRoute(
      path: '/recurring',
      name: 'recurring',
      builder: (context, state) => const RecurringScreen(),
    ),
          ],
        ),
      ],
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
      path: '/transactions/:id/edit',
      name: 'editTransaction',
      builder: (context, state) {
        final existing = state.extra as Transaction?;
        return AddTransactionScreen(existingTransaction: existing);
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
      path: '/categories/:id',
      name: 'categoryDetail',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        return CategoryDetailScreen(categoryId: id);
      },
    ),
    GoRoute(
      path: '/wishlist',
      name: 'wishlist',
      builder: (context, state) => const WishlistScreen(),
    ),
    GoRoute(
      path: '/price-memory',
      name: 'priceMemory',
      builder: (context, state) => const PriceMemoryScreen(),
    ),
    GoRoute(
      path: '/wallets',
      name: 'wallets',
      builder: (context, state) => const WalletsScreen(),
    ),
    GoRoute(
      path: '/goals',
      name: 'goals',
      builder: (context, state) => const SavingsGoalsScreen(),
    ),
    GoRoute(
      path: '/pending-income',
      name: 'pendingIncome',
      builder: (context, state) => const PendingIncomeScreen(),
    ),
  ],
);
