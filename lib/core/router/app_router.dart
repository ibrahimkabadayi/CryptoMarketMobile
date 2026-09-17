import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../providers/auth_provider.dart';
import '../../views/splash_screen.dart';
import '../../views/login_view.dart';
import '../../views/register_screen.dart';
import '../../views/home_view.dart';
import '../../views/market_screen.dart';
import '../../views/coin_detail_screen.dart';
import '../../views/portfolio_screen.dart';
import '../../views/market_news_screen.dart';
import '../../views/news_detail_screen.dart';
import '../../views/settings_screen.dart';

/// App router configuration using GoRouter.
/// Mirrors the route structure from: frontend/src/routers/index.ts

final _rootNavigatorKey = GlobalKey<NavigatorState>();
final _shellNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginView(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),

      // Main app shell with bottom nav
      ShellRoute(
        navigatorKey: _shellNavigatorKey,
        builder: (context, state, child) => HomeView(child: child),
        routes: [
          GoRoute(
            path: '/',
            redirect: (_, __) => '/market',
          ),
          GoRoute(
            path: '/market',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MarketScreen(),
            ),
            routes: [
              GoRoute(
                path: ':symbol',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => CoinDetailScreen(
                  symbol: state.pathParameters['symbol']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/portfolio',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: PortfolioScreen(),
            ),
          ),
          GoRoute(
            path: '/news',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: MarketNewsScreen(),
            ),
            routes: [
              GoRoute(
                path: ':title',
                parentNavigatorKey: _rootNavigatorKey,
                builder: (context, state) => NewsDetailScreen(
                  title: state.pathParameters['title']!,
                ),
              ),
            ],
          ),
          GoRoute(
            path: '/settings',
            pageBuilder: (context, state) => const NoTransitionPage(
              child: SettingsScreen(),
            ),
          ),
        ],
      ),
    ],

    redirect: (context, state) {
      final isOnSplash = state.matchedLocation == '/splash';
      final isOnAuth = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (isOnSplash) return null;

      if (!authState.isLoggedIn && !isOnAuth) {
        return '/login';
      }

      if (authState.isLoggedIn && isOnAuth) {
        return '/market';
      }

      return null;
    },
  );
});
