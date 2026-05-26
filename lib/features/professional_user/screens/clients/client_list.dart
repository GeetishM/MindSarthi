import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:appwrite/appwrite.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';
import 'package:shimmer/shimmer.dart';
import 'package:intl/intl.dart';
import 'package:mindsarthi/core/widgets/premium_search_bar.dart';
import 'package:mindsarthi/core/widgets/neumorphic_container.dart';

class ClientList extends ConsumerStatefulWidget {
  const ClientList({super.key});

  @override
  ConsumerState<ClientList> createState() => _ClientListState();
}

class _ClientListState extends ConsumerState<ClientList> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  List<_ClientInfo> _allClients = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadClients();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadClients() async {
    final user = ref.read(authStateProvider).value;
    if (user == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

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
      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());

      for (var doc in response.documents) {
        final data = Map<String, dynamic>.from(doc.data);
        data['id'] = doc.$id;
        final clientId = data['clientUid'] ?? data['clientName'] ?? 'unknown';
        final name = data['clientName'] ?? 'Client';
        final phone = data['clientPhone'] ?? '';

        if (!clients.containsKey(clientId)) {
          clients[clientId] = _ClientInfo(
            clientId: clientId,
            name: name,
            phone: phone,
            totalSessions: 0,
            lastDate: '',
            sessions: [],
          );
        }
        clients[clientId]!.totalSessions++;
        clients[clientId]!.sessions.add(data);

        final date = data['date'] ?? '';
        if (date.compareTo(clients[clientId]!.lastDate) > 0) {
          clients[clientId]!.lastDate = date;
        }

        if (date.compareTo(todayStr) >= 0 && data['status'] == 'upcoming') {
          clients[clientId]!.hasUpcoming = true;
        }
      }

      for (var client in clients.values) {
        client.sessions.sort((a, b) => (b['date'] as String).compareTo(a['date'] as String));
      }

      final clientList = clients.values.toList()
        ..sort((a, b) => b.lastDate.compareTo(a.lastDate));

      if (mounted) {
        setState(() {
          _allClients = clientList;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching clients: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showClientDetails(BuildContext context, _ClientInfo client) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.75,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : AppColors.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(color: borderCol, width: 0.8),
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 36,
                height: 5,
                decoration: BoxDecoration(
                  color: borderCol,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 20),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
                      child: Text(
                        client.name[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w900,
                          fontSize: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            client.name,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          if (client.phone.isNotEmpty)
                            Text(
                              client.phone,
                              style: TextStyle(
                                fontSize: 14,
                                color: textSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              Divider(color: borderCol, height: 1),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                      child: Text(
                        'SESSION HISTORY',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ),
                    Expanded(
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: client.sessions.length,
                        itemBuilder: (context, index) {
                          final session = client.sessions[index];
                          final status = session['status'] ?? 'upcoming';
                          final statusColor = status == 'completed'
                              ? AppColors.success
                              : status == 'cancelled'
                                  ? AppColors.error
                                  : theme.colorScheme.primary;

                          return Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface2 : AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: borderCol),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${session['date'] ?? ''}',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                        color: textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '${session['startTime'] ?? ''} - ${session['endTime'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    status[0].toUpperCase() + status.substring(1),
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;

    final filteredClients = _allClients.where((client) {
      final nameMatches = client.name.toLowerCase().contains(_searchQuery.toLowerCase());
      final phoneMatches = client.phone.toLowerCase().contains(_searchQuery.toLowerCase());
      return nameMatches || phoneMatches;
    }).toList();

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          'Clients',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: theme.scaffoldBackgroundColor,
        elevation: 0,
        automaticallyImplyLeading: false,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: PremiumSearchBar(
              controller: _searchController,
              hintText: 'Search by client name or phone...',
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              onClear: () {
                setState(() {
                  _searchQuery = '';
                });
              },
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildShimmer(theme, isDark)
          : filteredClients.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.people_outline_rounded,
                        size: 56,
                        color: textSecondary.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _searchQuery.isEmpty ? 'No clients yet' : 'No clients found',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: textPrimary,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Add sessions to see your clients here'
                            : 'Try adjusting your search keywords',
                        style: TextStyle(
                          fontSize: 13,
                          color: textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadClients,
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
                    itemCount: filteredClients.length,
                    itemBuilder: (context, index) {
                      final client = filteredClients[index];
                      return _ClientCard(
                        client: client,
                        isDark: isDark,
                        onTap: () => _showClientDetails(context, client),
                      );
                    },
                  ),
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
  final String clientId;
  final String name;
  final String phone;
  int totalSessions;
  String lastDate;
  final List<Map<String, dynamic>> sessions;
  bool hasUpcoming;

  _ClientInfo({
    required this.clientId,
    required this.name,
    required this.phone,
    required this.totalSessions,
    required this.lastDate,
    required this.sessions,
    this.hasUpcoming = false,
  });
}

class _ClientCard extends StatelessWidget {
  final _ClientInfo client;
  final bool isDark;
  final VoidCallback onTap;

  const _ClientCard({
    required this.client,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textPrimary = isDark ? AppColors.darkTextPrimary : AppColors.textPrimary;
    final textSecondary = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    final borderCol = isDark ? AppColors.darkBorder : AppColors.border;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTap: onTap,
        child: NeumorphicContainer(
          borderRadius: BorderRadius.circular(20),
          padding: const EdgeInsets.all(16),
          color: isDark ? AppColors.darkSurface : AppColors.surface,
          border: Border.all(color: borderCol, width: 1.0),
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
                    Row(
                      children: [
                        Text(
                          client.name,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        if (client.hasUpcoming) ...[
                          const SizedBox(width: 8),
                          Container(
                            width: 8,
                            height: 8,
                            decoration: const BoxDecoration(
                              color: AppColors.primary,
                              shape: BoxShape.circle,
                            ),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (client.phone.isNotEmpty) ...[
                          Icon(
                            Icons.phone_outlined,
                            size: 13,
                            color: textSecondary,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            client.phone,
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                          const SizedBox(width: 12),
                        ],
                        Icon(
                          Icons.event_rounded,
                          size: 13,
                          color: textSecondary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${client.totalSessions} sessions',
                          style: TextStyle(
                            fontSize: 12,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
