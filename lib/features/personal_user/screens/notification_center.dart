import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/widgets/neumorphic_container.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';

class NotificationCenter extends StatefulWidget {
  const NotificationCenter({super.key});

  @override
  State<NotificationCenter> createState() => _NotificationCenterState();
}

class _NotificationCenterState extends State<NotificationCenter> {
  late final Box _notificationsBox;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();
    _initHive();
  }

  Future<void> _initHive() async {
    _notificationsBox = Hive.box('notificationsBox');
    setState(() => _isInitialized = true);
  }

  void _markAllAsRead() async {
    final Map<dynamic, dynamic> data = _notificationsBox.toMap();
    for (var entry in data.entries) {
      final value = Map<String, dynamic>.from(entry.value as Map);
      if (value['isRead'] == false) {
        value['isRead'] = true;
        await _notificationsBox.put(entry.key, value);
      }
    }
    if (mounted) {
      AppToast.success(context, 'All notifications marked as read');
    }
  }

  void _clearAll() async {
    await _notificationsBox.clear();
    if (mounted) {
      AppToast.success(context, 'All notifications cleared');
    }
  }

  void _deleteNotification(String id) async {
    await _notificationsBox.delete(id);
  }

  void _toggleReadStatus(String id, Map<String, dynamic> notification) async {
    notification['isRead'] = !(notification['isRead'] as bool? ?? false);
    await _notificationsBox.put(id, notification);
  }

  String _formatGroupHeader(String group) {
    switch (group) {
      case 'today':
        return 'Today';
      case 'yesterday':
        return 'Yesterday';
      case 'this_week':
        return 'This Week';
      default:
        return 'Earlier';
    }
  }

  Map<String, List<MapEntry<dynamic, Map<String, dynamic>>>> _groupNotifications(List<MapEntry<dynamic, dynamic>> entries) {
    final Map<String, List<MapEntry<dynamic, Map<String, dynamic>>>> groups = {
      'today': [],
      'yesterday': [],
      'this_week': [],
      'earlier': [],
    };

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final sixDaysAgo = today.subtract(const Duration(days: 6));

    for (var entry in entries) {
      final notif = Map<String, dynamic>.from(entry.value as Map);
      final timestampStr = notif['timestamp'] as String?;
      if (timestampStr == null) {
        groups['earlier']!.add(MapEntry(entry.key, notif));
        continue;
      }

      final date = DateTime.tryParse(timestampStr) ?? DateTime.now();
      final compareDate = DateTime(date.year, date.month, date.day);

      if (compareDate == today) {
        groups['today']!.add(MapEntry(entry.key, notif));
      } else if (compareDate == yesterday) {
        groups['yesterday']!.add(MapEntry(entry.key, notif));
      } else if (compareDate.isAfter(sixDaysAgo)) {
        groups['this_week']!.add(MapEntry(entry.key, notif));
      } else {
        groups['earlier']!.add(MapEntry(entry.key, notif));
      }
    }

    return groups;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    if (!_isInitialized) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return ValueListenableBuilder(
      valueListenable: _notificationsBox.listenable(),
      builder: (context, Box box, _) {
        final rawEntries = box.toMap().entries.toList();
        rawEntries.sort((a, b) {
          final tA = Map<String, dynamic>.from(a.value as Map)['timestamp'] as String? ?? '';
          final tB = Map<String, dynamic>.from(b.value as Map)['timestamp'] as String? ?? '';
          return tB.compareTo(tA); // Descending order
        });

        final grouped = _groupNotifications(rawEntries);
        final bool hasNotifications = rawEntries.isNotEmpty;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: AppBar(
            backgroundColor: theme.scaffoldBackgroundColor,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios_new_rounded, color: textPrimary, size: 20),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'Notification Center',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 18,
                color: textPrimary,
              ),
            ),
            actions: hasNotifications
                ? [
                    PopupMenuButton<String>(
                      onSelected: (val) {
                        if (val == 'read') _markAllAsRead();
                        if (val == 'clear') _clearAll();
                      },
                      icon: Icon(Icons.more_vert_rounded, color: textPrimary),
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'read',
                          child: Row(
                            children: [
                              Icon(Icons.done_all_rounded, size: 18),
                              SizedBox(width: 8),
                              Text('Mark all as read'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'clear',
                          child: Row(
                            children: [
                              Icon(Icons.delete_sweep_rounded, size: 18, color: AppColors.error),
                              SizedBox(width: 8),
                              Text('Clear all', style: TextStyle(color: AppColors.error)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ]
                : null,
          ),
          body: !hasNotifications
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.notifications_off_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'All caught up!',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You don\'t have any notifications right now.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  children: [
                    ...grouped.entries.where((g) => g.value.isNotEmpty).map((g) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(left: 8, top: 12, bottom: 8),
                            child: Text(
                              _formatGroupHeader(g.key).toUpperCase(),
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                                color: theme.colorScheme.primary,
                                letterSpacing: 0.8,
                              ),
                            ),
                          ),
                          ...g.value.map((entry) {
                            final notif = entry.value;
                            final id = entry.key.toString();
                            final isRead = notif['isRead'] as bool? ?? false;
                            final title = notif['title'] as String? ?? '';
                            final body = notif['body'] as String? ?? '';
                            final timestampStr = notif['timestamp'] as String?;
                            String timeString = '';
                            if (timestampStr != null) {
                              final dt = DateTime.tryParse(timestampStr) ?? DateTime.now();
                              timeString = DateFormat('h:mm a').format(dt);
                            }

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              child: Dismissible(
                                key: Key(id),
                                direction: DismissDirection.endToStart,
                                onDismissed: (_) => _deleteNotification(id),
                                background: Container(
                                  alignment: Alignment.centerRight,
                                  padding: const EdgeInsets.only(right: 20),
                                  decoration: BoxDecoration(
                                    color: AppColors.error,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: const Icon(Icons.delete_rounded, color: Colors.white),
                                ),
                                child: NeumorphicContainer(
                                  borderRadius: BorderRadius.circular(16),
                                  padding: const EdgeInsets.all(14),
                                  color: isDark ? AppColors.darkSurface : AppColors.surface,
                                  border: Border.all(
                                    color: isRead
                                        ? (isDark ? AppColors.darkBorder : AppColors.border)
                                        : theme.colorScheme.primary.withValues(alpha: 0.4),
                                    width: isRead ? 1.0 : 1.5,
                                  ),
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Unread indicator dot
                                      if (!isRead)
                                        Padding(
                                          padding: const EdgeInsets.only(top: 6, right: 10),
                                          child: Container(
                                            width: 8,
                                            height: 8,
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme.primary,
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                        ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                              children: [
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: TextStyle(
                                                      fontWeight: isRead ? FontWeight.w600 : FontWeight.w800,
                                                      fontSize: 14,
                                                      color: textPrimary,
                                                    ),
                                                  ),
                                                ),
                                                Text(
                                                  timeString,
                                                  style: TextStyle(
                                                    fontSize: 11,
                                                    color: textSecondary,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 6),
                                            Text(
                                              body,
                                              style: TextStyle(
                                                fontSize: 13,
                                                color: isRead ? textSecondary : textPrimary.withValues(alpha: 0.9),
                                                height: 1.35,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      );
                    }),
                  ],
                ),
        );
      },
    );
  }
}
