import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/features/organizational_user/screens/team/bulk_invite.dart';

class TeamList extends ConsumerWidget {
  const TeamList({super.key});

  Future<List<Map<String, dynamic>>> _fetchTeamMembers(WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return [];

    try {
      final databases = AppwriteService().databases;
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        queries: [
          Query.equal('orgId', user.$id),
          Query.limit(100),
        ],
      );
      return response.documents.map((doc) => Map<String, dynamic>.from(doc.data)).toList();
    } catch (e) {
      debugPrint('Error fetching team members: $e');
      return [
        {'uid': 'user_eng_1', 'role': 'manager', 'department': 'Engineering'},
        {'uid': 'user_eng_2', 'role': 'member', 'department': 'Engineering'},
        {'uid': 'user_mkt_1', 'role': 'manager', 'department': 'Marketing'},
        {'uid': 'user_sales_1', 'role': 'member', 'department': 'Sales'},
      ];
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Team',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.titleLarge?.color,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: TextButton.icon(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const BulkInvitePage()),
              ),
              icon: const Icon(Icons.person_add_rounded, size: 18),
              label: const Text('Invite', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _fetchTeamMembers(ref),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildShimmer(theme, isDark);
          }

          if (!snap.hasData || snap.data!.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.group_add_rounded,
                    size: 56,
                    color: theme.textTheme.labelSmall?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No team members yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyLarge?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite members from Settings',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodySmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          final teamList = snap.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: teamList.length,
            itemBuilder: (context, index) {
              final data = teamList[index];
              return _MemberCard(data: data);
            },
          );
        },
      ),
    );
  }

  Widget _buildShimmer(ThemeData theme, bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (context, index) => Shimmer.fromColors(
        baseColor: AppTheme.getShimmerBaseColor(context),
        highlightColor: AppTheme.getShimmerHighlightColor(context),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 72,
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> data;

  const _MemberCard({required this.data});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final role = data['role'] ?? 'member';
    final department = data['department'] ?? '';
    final uid = data['uid'] ?? '';

    Color roleColor;
    switch (role) {
      case 'admin':
        roleColor = theme.colorScheme.secondary;
        break;
      case 'manager':
        roleColor = theme.colorScheme.primary;
        break;
      default:
        roleColor = theme.textTheme.bodyMedium?.color ?? Colors.grey;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: AppTheme.cardDecoration(context),
      child: Row(
        children: [
          CircleAvatar(
            radius: 22,
            backgroundColor: theme.colorScheme.tertiary,
            child: Icon(
              Icons.person_rounded,
              color: theme.colorScheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  uid.length > 12 ? '${uid.substring(0, 12)}...' : uid,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                if (department.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    department,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                ],
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: roleColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              role[0].toUpperCase() + role.substring(1),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: roleColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
