import 'package:appwrite/appwrite.dart';
import 'package:appwrite/models.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mindsarthi/core/services/appwrite_service.dart';

import 'package:appwrite/enums.dart';

class AuthRepository {
  final Account _account;
  final Databases _databases;

  AuthRepository(this._account, this._databases);

  /// Sends a 6-digit verification code to the user's email.
  /// Returns the `userId` associated with the token session.
  Future<String> sendEmailOtp(String email) async {
    final token = await _account.createEmailToken(
      userId: ID.unique(),
      email: email,
    );
    return token.userId;
  }

  /// Verifies the 6-digit OTP code using the `userId` and `secretCode`.
  /// Returns the logged-in user session.
  Future<Session> verifyEmailOtp({
    required String userId,
    required String secretCode,
  }) async {
    return await _account.createSession(
      userId: userId,
      secret: secretCode,
    );
  }

  /// Initiates Google OAuth2 login.
  Future<void> loginWithGoogle() async {
    await _account.createOAuth2Session(provider: OAuthProvider.google);
  }

  /// Signs the user out of the current session.
  Future<void> signOut() async {
    await _account.deleteSession(sessionId: 'current');
  }

  /// Retrieves the current authenticated user profile (if any).
  Future<User?> getCurrentUser() async {
    try {
      return await _account.get();
    } catch (_) {
      return null;
    }
  }
}

// ── Riverpod Providers ──────────────────────────────────────────────────────

/// Provider for AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final appwrite = AppwriteService();
  return AuthRepository(appwrite.account, appwrite.databases);
});

/// StateNotifier to manage user authentication state.
class AuthStateNotifier extends StateNotifier<AsyncValue<User?>> {
  final AuthRepository _repo;

  AuthStateNotifier(this._repo) : super(const AsyncValue.loading()) {
    checkAuth();
  }

  Future<void> checkAuth() async {
    try {
      final user = await _repo.getCurrentUser();
      state = AsyncValue.data(user);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<void> signOut() async {
    state = const AsyncValue.loading();
    try {
      await _repo.signOut();
      state = const AsyncValue.data(null);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  void setUser(User? user) {
    state = AsyncValue.data(user);
  }
}

/// Provider for AuthStateNotifier.
final authStateProvider = StateNotifierProvider<AuthStateNotifier, AsyncValue<User?>>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthStateNotifier(repo);
});
