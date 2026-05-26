import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';
import 'package:mindsarthi/core/constants/appwrite_constants.dart';
import 'package:mindsarthi/features/auth/auth_repository.dart';

class ProfileCompletionGate extends ConsumerStatefulWidget {
  final Widget child;
  final VoidCallback onNavigateToProfile;

  const ProfileCompletionGate({
    super.key,
    required this.child,
    required this.onNavigateToProfile,
  });

  @override
  ConsumerState<ProfileCompletionGate> createState() => _ProfileCompletionGateState();
}

class _ProfileCompletionGateState extends ConsumerState<ProfileCompletionGate> {
  bool _isLoading = true;
  bool _isComplete = false;

  @override
  void initState() {
    super.initState();
    _checkProfileStatus();
  }

  Future<void> _checkProfileStatus() async {
    setState(() => _isLoading = true);
    try {
      final user = ref.read(authStateProvider).value;
      if (user == null) {
        setState(() => _isComplete = false);
        return;
      }

      final databases = AppwriteService().databases;
      final doc = await databases.getDocument(
        databaseId: AppwriteConstants.databaseId,
        collectionId: AppwriteConstants.professionalProfilesCollectionId,
        documentId: user.$id,
      );

      final data = doc.data;
      final complete = data['profileComplete'] as bool? ?? false;
      setState(() => _isComplete = complete);
    } catch (e) {
      // Document might not exist yet, meaning profile is definitely not complete
      setState(() => _isComplete = false);
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_isComplete) {
      return widget.child;
    }

    final theme = Theme.of(context);
    final fontScale = MediaQuery.of(context).size.width / 375;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_person_rounded,
                    size: 80,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Profile Setup Required',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24 * fontScale,
                    fontWeight: FontWeight.w800,
                    color: theme.colorScheme.onSurface,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'To publish insights, write articles in the CMS, and appear in counselling search results, you must complete your profile and upload at least one verified certificate/degree.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14 * fontScale,
                    color: theme.textTheme.bodyMedium?.color,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 32),
                // Checklist visual representation
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.cardTheme.color ?? theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: theme.dividerTheme.color ?? theme.colorScheme.outlineVariant,
                    ),
                  ),
                  child: Column(
                    children: [
                      _buildCheckItem('Basic profile details (Name, Bio, Experience)', theme),
                      const SizedBox(height: 10),
                      _buildCheckItem('At least one specialization tag', theme),
                      const SizedBox(height: 10),
                      _buildCheckItem('Upload degree or certification documents', theme),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: widget.onNavigateToProfile,
                    icon: const Icon(Icons.arrow_forward_rounded),
                    label: const Text(
                      'Complete Profile Now',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: _checkProfileStatus,
                  child: const Text('Refresh Status'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCheckItem(String text, ThemeData theme) {
    return Row(
      children: [
        Icon(
          Icons.info_outline_rounded,
          size: 20,
          color: theme.colorScheme.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: theme.textTheme.bodyMedium?.color,
            ),
          ),
        ),
      ],
    );
  }
}
