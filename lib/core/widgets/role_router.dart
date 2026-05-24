import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindsarthi/core/theme/app_theme.dart';
import 'package:mindsarthi/core/theme/theme_provider.dart';
import 'package:mindsarthi/features/organizational_user/screens/org_nav.dart';
import 'package:mindsarthi/features/personal_user/screens/nav.dart';
import 'package:mindsarthi/features/professional_user/screens/professional_nav.dart';
import 'package:provider/provider.dart' as provider_pkg;
import 'package:shimmer/shimmer.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';

/// Routes the authenticated user to the correct Nav screen based on their
/// Appwrite [userRole] field.
///
/// Supported roles:
///   - `personal`       → NavBar (personal user)
///   - `professional`   → NavBar (fallback until ProfessionalNavBar exists)
///   - `org`            → NavBar (fallback until OrgNavBar exists)
///   - missing / null   → NavBar (defaults to personal)
class RoleRouter extends ConsumerStatefulWidget {
  const RoleRouter({super.key});

  @override
  ConsumerState<RoleRouter> createState() => _RoleRouterState();
}

class _RoleRouterState extends ConsumerState<RoleRouter> {
  String? _role;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRole();
  }

  Future<void> _fetchRole() async {
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        if (mounted) {
          setState(() {
            _role = 'personal';
            _loading = false;
          });
        }
        return;
      }

      final databases = AppwriteService().databases;
      final doc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.usersCollectionId,
        documentId: user.$id,
      );

      if (!mounted) return;

      final data = doc.data;
      final role = data['userRole'] as String?;
      final resolvedRole = role ?? 'personal';

      if (mounted) {
        provider_pkg.Provider.of<ThemeProvider>(context, listen: false).setRole(resolvedRole);
      }

      setState(() {
        _role = resolvedRole;
        _loading = false;
      });
    } catch (e) {
      if (mounted) {
        provider_pkg.Provider.of<ThemeProvider>(context, listen: false).setRole('personal');
        setState(() {
          _role = 'personal';
          _loading = false;
        });
      }
      debugPrint('RoleRouter: Failed to fetch user role — $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const _RoleLoadingScreen();

    // Route based on Firestore userRole
    switch (_role) {
      case 'professional':
        return const ProfessionalNav();
      case 'org':
        return const OrgNav();
      case 'personal':
      default:
        return const NavBar();
    }
  }
}

class _RoleLoadingScreen extends StatelessWidget {
  const _RoleLoadingScreen();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final shimmerBase =
        isDark ? AppColors.darkShimmerBase : AppColors.shimmerBase;
    final shimmerHighlight =
        isDark ? AppColors.darkShimmerHighlight : AppColors.shimmerHighlight;

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header shimmer
              Shimmer.fromColors(
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 120,
                      height: 16,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 200,
                      height: 28,
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.darkSurface : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Hero card shimmer
              Shimmer.fromColors(
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                child: Container(
                  width: double.infinity,
                  height: 200,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : Colors.white,
                    borderRadius: BorderRadius.circular(32),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // Content shimmer rows
              Shimmer.fromColors(
                baseColor: shimmerBase,
                highlightColor: shimmerHighlight,
                child: Column(
                  children: List.generate(4, (i) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        width: double.infinity,
                        height: 80,
                        decoration: BoxDecoration(
                          color:
                              isDark ? AppColors.darkSurface : Colors.white,
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                    );
                  }),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
