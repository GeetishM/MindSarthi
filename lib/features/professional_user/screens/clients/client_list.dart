import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:shimmer/shimmer.dart';

class ClientList extends ConsumerWidget {
  const ClientList({super.key});

  Future<List<_ClientInfo>> _fetchClients(WidgetRef ref) async {
    final user = ref.read(authStateProvider).value;
    if (user == null) return [];

    try {
      final databases = AppwriteService().databases;
      final response = await databases.listDocuments(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.sessionsCollectionId,
        queries: [
          Query.equal('professionalUid', user.$id),
          Query.limit(100),
        ],
      );

      final Map<String, _ClientInfo> clients = {};
      for (var doc in response.documents) {
        final data = doc.data;
        final clientId = data['clientUid'] ?? data['clientName'] ?? 'unknown';
        final name = data['clientName'] ?? 'Client';
        final phone = data['clientPhone'] ?? '';

        if (!clients.containsKey(clientId)) {
          clients[clientId] = _ClientInfo(
            name: name,
            phone: phone,
            totalSessions: 0,
            lastDate: '',
          );
        }
        clients[clientId]!.totalSessions++;

        final date = data['date'] ?? '';
        if (date.compareTo(clients[clientId]!.lastDate) > 0) {
          clients[clientId]!.lastDate = date;
        }
      }

      final clientList = clients.values.toList()
        ..sort((a, b) => b.lastDate.compareTo(a.lastDate));

      return clientList;
    } catch (e) {
      debugPrint('Error fetching clients: $e');
      return [];
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
          'Clients',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: theme.textTheme.bodyLarge?.color,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: FutureBuilder<List<_ClientInfo>>(
        future: _fetchClients(ref),
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
                    Icons.people_outline_rounded,
                    size: 56,
                    color: theme.textTheme.labelSmall?.color,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No clients yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: theme.textTheme.bodyMedium?.color,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add sessions to see your clients here',
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.textTheme.labelSmall?.color,
                    ),
                  ),
                ],
              ),
            );
          }

          final clientList = snap.data!;

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: clientList.length,
            itemBuilder: (context, index) {
              return _ClientCard(
                client: clientList[index],
                isDark: isDark,
              );
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
        baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
        highlightColor: isDark
            ? AppColors.darkShimmerHighlight
            : AppColors.shimmerHighlight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: theme.cardTheme.color ?? theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _ClientInfo {
  final String name;
  final String phone;
  int totalSessions;
  String lastDate;

  _ClientInfo({
    required this.name,
    required this.phone,
    required this.totalSessions,
    required this.lastDate,
  });
}

class _ClientCard extends StatelessWidget {
  final _ClientInfo client;
  final bool isDark;

  const _ClientCard({required this.client, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: theme.colorScheme.tertiary,
            child: Text(
              client.name[0].toUpperCase(),
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  client.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.bodyLarge?.color,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (client.phone.isNotEmpty) ...[
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: theme.textTheme.labelSmall?.color,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        client.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.textTheme.bodyMedium?.color,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      Icons.event_rounded,
                      size: 13,
                      color: theme.textTheme.labelSmall?.color,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${client.totalSessions} sessions',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.textTheme.bodyMedium?.color,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: theme.textTheme.labelSmall?.color,
          ),
        ],
      ),
    );
  }
}
