import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:intl/intl.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/widgets/neumorphic_container.dart';
import 'package:mindsarthi/core/theme/app_toast.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';

class CommunityNotifications extends ConsumerStatefulWidget {
  const CommunityNotifications({super.key});

  @override
  ConsumerState<CommunityNotifications> createState() => _CommunityNotificationsState();
}

class _CommunityNotificationsState extends ConsumerState<CommunityNotifications> {
  bool _isLoading = true;
  List<dynamic> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) return;

      final databases = AppwriteService().databases;
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.communityNotificationsCollectionId,
        queries: [
          Query.equal('userId', user.$id),
          Query.orderDesc('timestamp'),
        ],
      );

      if (mounted) {
        setState(() {
          _notifications = response.documents;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading community notifications: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _markAllAsRead() async {
    try {
      final databases = AppwriteService().databases;
      for (var doc in _notifications) {
        if (doc.data['isRead'] == false) {
          await databases.updateDocument(
            databaseId: AppwriteConstants.databaseId,
            collectionId: AppwriteConstants.communityNotificationsCollectionId,
            documentId: doc.$id,
            data: {'isRead': true},
          );
        }
      }
      AppToast.success(context, 'All marked as read');
      _loadNotifications();
    } catch (e) {
      AppToast.error(context, 'Failed to update', description: e.toString());
    }
  }

  Future<void> _clearAll() async {
    try {
      final databases = AppwriteService().databases;
      for (var doc in _notifications) {
        await databases.deleteDocument(
          databaseId: AppwriteConstants.databaseId,
          collectionId: AppwriteConstants.communityNotificationsCollectionId,
          documentId: doc.$id,
        );
      }
      AppToast.success(context, 'Notifications cleared');
      _loadNotifications();
    } catch (e) {
      AppToast.error(context, 'Failed to clear notifications', description: e.toString());
    }
  }

  Future<void> _toggleRead(String docId, bool currentStatus) async {
    try {
      final databases = AppwriteService().databases;
      await databases.updateDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.communityNotificationsCollectionId,
        documentId: docId,
        data: {'isRead': !currentStatus},
      );
      _loadNotifications();
    } catch (e) {
      AppToast.error(context, 'Failed to update status', description: e.toString());
    }
  }

  Future<void> _deleteNotification(String docId) async {
    try {
      final databases = AppwriteService().databases;
      await databases.deleteDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.communityNotificationsCollectionId,
        documentId: docId,
      );
      _loadNotifications();
    } catch (e) {
      AppToast.error(context, 'Delete failed', description: e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

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
          'Community Activity',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: textPrimary,
          ),
        ),
        actions: _notifications.isNotEmpty
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
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _notifications.isEmpty
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
                          Icons.forum_outlined,
                          size: 64,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'No community activity',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Likes and comments on your posts will appear here.',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  itemCount: _notifications.length,
                  itemBuilder: (context, index) {
                    final doc = _notifications[index];
                    final data = doc.data;
                    final isRead = data['isRead'] as bool? ?? false;
                    final actorName = data['actorName'] ?? 'Someone';
                    final type = data['type'] ?? 'liked';
                    final timestampStr = data['timestamp'] as String?;

                    String timeString = '';
                    if (timestampStr != null) {
                      final dt = DateTime.tryParse(timestampStr) ?? DateTime.now();
                      timeString = DateFormat('h:mm a').format(dt);
                    }

                    String messageText = '';
                    IconData iconData = Icons.favorite_rounded;
                    Color iconColor = Colors.redAccent;

                    if (type == 'like') {
                      messageText = '$actorName liked your post';
                      iconData = Icons.favorite_rounded;
                      iconColor = Colors.redAccent;
                    } else {
                      messageText = '$actorName commented on your post';
                      iconData = Icons.comment_rounded;
                      iconColor = theme.colorScheme.primary;
                    }

                    return Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Dismissible(
                        key: Key(doc.$id),
                        direction: DismissDirection.endToStart,
                        onDismissed: (_) => _deleteNotification(doc.$id),
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
                                ? borderCol
                                : theme.colorScheme.primary.withValues(alpha: 0.4),
                            width: isRead ? 1.0 : 1.5,
                          ),
                          child: InkWell(
                            onTap: () => _toggleRead(doc.$id, isRead),
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: iconColor.withValues(alpha: 0.15),
                                  child: Icon(iconData, color: iconColor, size: 20),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        messageText,
                                        style: TextStyle(
                                          fontWeight: isRead ? FontWeight.w500 : FontWeight.bold,
                                          fontSize: 14,
                                          color: textPrimary,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        timeString,
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (!isRead)
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: theme.colorScheme.primary,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}
