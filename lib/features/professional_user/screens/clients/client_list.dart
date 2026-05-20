import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

class ClientList extends StatelessWidget {
  const ClientList({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Clients',
          style: TextStyle(
            fontWeight: FontWeight.w800,
            color: isDark ? AppColors.darkTextPrimary : AppColors.textPrimary,
            letterSpacing: -0.5,
          ),
        ),
        backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('sessions')
            .where('professionalUid', isEqualTo: uid)
            .snapshots(),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return _buildShimmer(isDark);
          }

          if (!snap.hasData || snap.data!.docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.people_outline_rounded,
                    size: 56,
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No clients yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Add sessions to see your clients here',
                    style: TextStyle(
                      fontSize: 13,
                      color:
                          isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                  ),
                ],
              ),
            );
          }

          // Group sessions by client
          final Map<String, _ClientInfo> clients = {};
          for (var doc in snap.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
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

  Widget _buildShimmer(bool isDark) {
    return ListView.builder(
      padding: const EdgeInsets.all(24),
      itemCount: 5,
      itemBuilder: (_, __) => Shimmer.fromColors(
        baseColor: isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase,
        highlightColor: isDark
            ? AppColors.darkShimmerHighlight
            : AppColors.shimmerHighlight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          height: 80,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
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
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor:
                isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
            child: Text(
              client.name[0].toUpperCase(),
              style: TextStyle(
                color: isDark ? AppColors.darkPrimary : AppColors.primary,
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
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    if (client.phone.isNotEmpty) ...[
                      Icon(
                        Icons.phone_outlined,
                        size: 13,
                        color: isDark
                            ? AppColors.darkTextHint
                            : AppColors.textHint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        client.phone,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? AppColors.darkTextSecondary
                              : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Icon(
                      Icons.event_rounded,
                      size: 13,
                      color:
                          isDark ? AppColors.darkTextHint : AppColors.textHint,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${client.totalSessions} sessions',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppColors.darkTextSecondary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Icon(
            Icons.chevron_right_rounded,
            color: isDark ? AppColors.darkTextHint : AppColors.textHint,
          ),
        ],
      ),
    );
  }
}
