import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_colors.dart';
import '../models/notification_models.dart';
import '../providers/notification_provider.dart';

/// Notifications list screen.
/// Displays user alerts and notifications with read/unread filtering.
class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  bool _filterUnreadOnly = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).fetchNotifications();
    });
  }

  IconData _iconForType(String type) {
    switch (type.toLowerCase()) {
      case 'price_alert':
        return Icons.notification_important_outlined;
      case 'order':
      case 'limit_order':
        return Icons.receipt_long_outlined;
      case 'transaction':
      case 'wallet':
        return Icons.account_balance_wallet_outlined;
      case 'news':
        return Icons.newspaper_outlined;
      default:
        return Icons.notifications_outlined;
    }
  }

  Color _colorForType(String type) {
    switch (type.toLowerCase()) {
      case 'price_alert':
        return AppColors.voltGreen;
      case 'order':
      case 'limit_order':
        return const Color(0xFF64B5F6);
      case 'transaction':
      case 'wallet':
        return const Color(0xFFFFB74D);
      default:
        return AppColors.textSecondary;
    }
  }

  String _formatDate(String dateStr) {
    final date = DateTime.tryParse(dateStr);
    if (date == null) return '';
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationProvider);
    final allNotifications = state.sortedNotifications;
    final displayedList = _filterUnreadOnly
        ? allNotifications.where((n) => !n.isRead).toList()
        : allNotifications;

    return Scaffold(
      backgroundColor: AppColors.scaffoldBg,
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          if (state.unreadCount > 0)
            TextButton.icon(
              onPressed: () => ref.read(notificationProvider.notifier).markAllAsRead(),
              icon: const Icon(Icons.done_all, size: 18, color: AppColors.voltGreen),
              label: const Text(
                'Mark All Read',
                style: TextStyle(color: AppColors.voltGreen, fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // ── Filter Chips ───────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                ChoiceChip(
                  label: Text('All (${allNotifications.length})'),
                  selected: !_filterUnreadOnly,
                  onSelected: (selected) {
                    if (selected) setState(() => _filterUnreadOnly = false);
                  },
                  selectedColor: AppColors.voltGreen,
                  labelStyle: TextStyle(
                    color: !_filterUnreadOnly ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 8),
                ChoiceChip(
                  label: Text('Unread (${state.unreadCount})'),
                  selected: _filterUnreadOnly,
                  onSelected: (selected) {
                    if (selected) setState(() => _filterUnreadOnly = true);
                  },
                  selectedColor: AppColors.voltGreen,
                  labelStyle: TextStyle(
                    color: _filterUnreadOnly ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // ── Content ────────────────────────────────────
          Expanded(
            child: RefreshIndicator(
              color: AppColors.voltGreen,
              backgroundColor: AppColors.surfaceBg,
              onRefresh: () => ref.read(notificationProvider.notifier).fetchNotifications(),
              child: state.isLoading && allNotifications.isEmpty
                  ? const Center(
                      child: CircularProgressIndicator(color: AppColors.voltGreen),
                    )
                  : displayedList.isEmpty
                      ? ListView(
                          children: [
                            SizedBox(height: MediaQuery.of(context).size.height * 0.2),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    width: 64,
                                    height: 64,
                                    decoration: BoxDecoration(
                                      color: AppColors.deepBg,
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border.all(color: AppColors.borderSubtle),
                                    ),
                                    child: const Icon(
                                      Icons.notifications_off_outlined,
                                      color: AppColors.textMuted,
                                      size: 32,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    _filterUnreadOnly
                                        ? 'No unread notifications'
                                        : 'No notifications yet',
                                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                          color: AppColors.textSecondary,
                                        ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'When market events trigger, alerts will appear here.',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: displayedList.length,
                          separatorBuilder: (_, _) => const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final item = displayedList[index];
                            return _buildNotificationCard(context, item);
                          },
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationCard(BuildContext context, NotificationDto item) {
    final typeColor = _colorForType(item.type);

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () {
        if (!item.isRead) {
          ref.read(notificationProvider.notifier).markAsRead(item.id);
        }
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: item.isRead ? AppColors.surfaceBg : const Color(0xFF181D14),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: item.isRead ? AppColors.borderSubtle : AppColors.voltGreen.withValues(alpha: 0.4),
            width: item.isRead ? 1 : 1.5,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: typeColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(_iconForType(item.type), color: typeColor, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          item.title,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w700,
                                color: item.isRead ? AppColors.textPrimary : AppColors.voltGreen,
                              ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!item.isRead)
                        Container(
                          width: 8,
                          height: 8,
                          decoration: const BoxDecoration(
                            color: AppColors.voltGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    item.message,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _formatDate(item.createdAt),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 11,
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
