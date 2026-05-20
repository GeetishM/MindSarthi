import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:shimmer/shimmer.dart';

class TeamList extends StatelessWidget {
  const TeamList({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final uid = FirebaseAuth.instance.currentUser?.uid;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      appBar: AppBar(
        title: Text(
          'Team',
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
            .collection('org_members')
            .doc(uid)
            .collection('members')
            .orderBy('role')
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
                    Icons.group_add_rounded,
                    size: 56,
                    color: isDark ? AppColors.darkTextHint : AppColors.textHint,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No team members yet',
                    style: TextStyle(
                      fontSize: 16,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Invite members from Settings',
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

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 100),
            itemCount: snap.data!.docs.length,
            itemBuilder: (context, index) {
              final data =
                  snap.data!.docs[index].data() as Map<String, dynamic>;
              return _MemberCard(data: data, isDark: isDark);
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
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkSurface : Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final bool isDark;

  const _MemberCard({required this.data, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final role = data['role'] ?? 'member';
    final department = data['department'] ?? '';
    final uid = data['uid'] ?? '';

    Color roleColor;
    switch (role) {
      case 'admin':
        roleColor = AppColors.accent;
        break;
      case 'manager':
        roleColor = isDark ? AppColors.darkPrimary : AppColors.primary;
        break;
      default:
        roleColor = isDark ? AppColors.darkTextSecondary : AppColors.textSecondary;
    }

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
            radius: 22,
            backgroundColor:
                isDark ? AppColors.darkPrimaryLight : AppColors.primaryLight,
            child: Icon(
              Icons.person_rounded,
              color: isDark ? AppColors.darkPrimary : AppColors.primary,
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
                    color: isDark
                        ? AppColors.darkTextPrimary
                        : AppColors.textPrimary,
                  ),
                ),
                if (department.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    department,
                    style: TextStyle(
                      fontSize: 13,
                      color: isDark
                          ? AppColors.darkTextSecondary
                          : AppColors.textSecondary,
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
