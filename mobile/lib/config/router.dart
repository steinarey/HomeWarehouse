import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile/presentation/screens/scaffold_with_navbar.dart';
import 'package:mobile/presentation/screens/home_screen.dart';
import 'package:mobile/presentation/screens/use_restock_screen.dart';
import 'package:mobile/presentation/screens/low_stock_screen.dart';
import 'package:mobile/presentation/screens/activity_log_screen.dart';
import 'package:mobile/presentation/screens/settings_screen.dart';
import 'package:mobile/presentation/screens/onboarding_screen.dart';
import 'package:mobile/presentation/screens/categories_screen.dart';
import 'package:mobile/presentation/screens/login_screen.dart';
import 'package:mobile/presentation/screens/register_screen.dart';
import 'package:mobile/presentation/screens/user_management_screen.dart';
import 'package:mobile/presentation/screens/settings/connectors_screen.dart';
import 'package:mobile/presentation/screens/settings/microsoft_todo_connector_screen.dart';
import 'package:mobile/domain/providers/auth_provider.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/',
    redirect: (context, state) {
      // OAuth deep link: the system browser hits the backend callback, which
      // 302s to `pantrykeeper://connector/microsoft-todo/done?status=...`.
      // Android delivers that URI to the app and GoRouter tries to match it
      // by path. Map it onto the connector screen so the lifecycle-resume
      // refresh on that screen reflects the new connection state.
      if (state.uri.scheme == 'pantrykeeper' ||
          state.uri.host == 'connector') {
        final query = state.uri.query.isEmpty ? '' : '?${state.uri.query}';
        return '/settings/connectors/microsoft-todo$query';
      }

      final isLoggedIn = authState.asData?.value ?? false;
      final isLoggingIn = state.uri.path == '/login';
      final isRegistering = state.uri.path == '/register';
      final isOnboarding = state.uri.path == '/onboarding';

      // If not logged in and not on login or onboarding, redirect to login
      if (!isLoggedIn && !isLoggingIn && !isOnboarding && !isRegistering) {
        return '/login';
      }

      // If logged in and on login/register, redirect to home
      if (isLoggedIn && (isLoggingIn || isRegistering)) {
        return '/';
      }

      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return ScaffoldWithNavbar(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const HomeScreen(),
              ),
              GoRoute(
                path: '/categories',
                builder: (context, state) => const CategoriesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/use-restock',
                builder: (context, state) => const UseRestockScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/low-stock',
                builder: (context, state) => const LowStockScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/activity',
                builder: (context, state) => const ActivityLogScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsScreen(),
                routes: [
                  GoRoute(
                    path: 'users',
                    builder: (context, state) => const UserManagementScreen(),
                  ),
                  GoRoute(
                    path: 'connectors',
                    builder: (context, state) => const ConnectorsScreen(),
                    routes: [
                      GoRoute(
                        path: 'microsoft-todo',
                        builder: (context, state) =>
                            const MicrosoftTodoConnectorScreen(),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
});
