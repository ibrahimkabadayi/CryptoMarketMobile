import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';

/// Home scaffold with bottom navigation bar.
/// This wraps all main tab screens (Market, Portfolio, News, Settings).
class HomeView extends StatelessWidget {
  final Widget child;

  const HomeView({super.key, required this.child});

  static const _tabs = [
    _NavTab(path: '/market', label: 'Market', icon: Icons.candlestick_chart_outlined, activeIcon: Icons.candlestick_chart),
    _NavTab(path: '/portfolio', label: 'Portfolio', icon: Icons.account_balance_wallet_outlined, activeIcon: Icons.account_balance_wallet),
    _NavTab(path: '/news', label: 'News', icon: Icons.newspaper_outlined, activeIcon: Icons.newspaper),
    _NavTab(path: '/settings', label: 'More', icon: Icons.settings_outlined, activeIcon: Icons.settings),
  ];

  int _currentIndex(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;
    for (int i = 0; i < _tabs.length; i++) {
      if (location.startsWith(_tabs[i].path)) return i;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndex(context);

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(
            top: BorderSide(color: AppColors.borderSubtle, width: 1),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: currentIndex,
          onTap: (index) {
            if (index != currentIndex) {
              context.go(_tabs[index].path);
            }
          },
          items: _tabs
              .map(
                (tab) => BottomNavigationBarItem(
                  icon: Icon(tab.icon),
                  activeIcon: Icon(tab.activeIcon),
                  label: tab.label,
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _NavTab {
  final String path;
  final String label;
  final IconData icon;
  final IconData activeIcon;

  const _NavTab({
    required this.path,
    required this.label,
    required this.icon,
    required this.activeIcon,
  });
}