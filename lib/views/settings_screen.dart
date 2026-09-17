import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../providers/notification_provider.dart';
import '../providers/price_alert_provider.dart';

/// Settings / "More" screen.
/// Shows user info, logout, and app info.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final auth = ref.watch(authProvider);
    final notifState = ref.watch(notificationProvider);
    final alertState = ref.watch(priceAlertProvider);

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: RichText(
          text: TextSpan(children: [
            TextSpan(text: 'Settings', style: Theme.of(context).textTheme.headlineSmall),
          ]),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // ── User Info ──────────────────────────────────
          Card(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.deepBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.voltGreen),
                    ),
                    child: const Center(
                      child: Icon(Icons.person, color: AppColors.voltGreen, size: 24),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          auth.isLoggedIn ? 'Authenticated' : 'Not signed in',
                          style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                        ),
                        if (auth.userId != null)
                          Text(
                            'ID: ${auth.userId}',
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Menu Items ─────────────────────────────────
          Card(
            child: Column(
              children: [
                _menuItem(
                  context,
                  icon: Icons.notifications_outlined,
                  label: 'Notifications',
                  subtitle: notifState.unreadCount > 0
                      ? '${notifState.unreadCount} unread notification${notifState.unreadCount > 1 ? 's' : ''}'
                      : 'View and manage alerts',
                  trailing: notifState.unreadCount > 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.voltGreen,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${notifState.unreadCount}',
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                          ],
                        )
                      : null,
                  onTap: () => context.push('/notifications'),
                ),
                const Divider(height: 0),
                _menuItem(
                  context,
                  icon: Icons.notification_important_outlined,
                  label: 'Price Alerts',
                  subtitle: alertState.activeCount > 0
                      ? '${alertState.activeCount} active alert${alertState.activeCount > 1 ? 's' : ''}'
                      : 'Manage price thresholds',
                  trailing: alertState.activeCount > 0
                      ? Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.surfaceBg,
                                border: Border.all(color: AppColors.voltGreen),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '${alertState.activeCount}',
                                style: const TextStyle(
                                  color: AppColors.voltGreen,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
                          ],
                        )
                      : null,
                  onTap: () => context.push('/price-alerts'),
                ),
                const Divider(height: 0),
                _menuItem(
                  context,
                  icon: Icons.info_outline,
                  label: 'About',
                  subtitle: 'CryptoMarket v0.1.0',
                  onTap: () {
                    showAboutDialog(
                      context: context,
                      applicationName: 'CryptoMarket',
                      applicationVersion: 'v0.1.0',
                      applicationIcon: const Icon(Icons.currency_bitcoin, color: AppColors.voltGreen, size: 36),
                      children: const [
                        Text('Decentralized crypto trading terminal and market intelligence mobile client.'),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Logout ─────────────────────────────────────
          if (auth.isLoggedIn)
            SizedBox(
              height: 50,
              child: OutlinedButton.icon(
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) context.go('/login');
                },
                icon: const Icon(Icons.logout, color: AppColors.error),
                label: Text(
                  'Sign Out',
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: AppColors.error.withValues(alpha: 0.3)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _menuItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppColors.textSecondary, size: 22),
      title: Text(label, style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
      trailing: trailing ?? const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
      onTap: onTap,
    );
  }
}
