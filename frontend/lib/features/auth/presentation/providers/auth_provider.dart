import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/app_role.dart';
import '../../domain/models/user_profile.dart';
import '../../data/repositories/auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository();
});

class AuthState {
  final UserProfile? user;
  final bool isLoading;
  final String? errorMessage;
  final bool isLocked;
  final int lockoutMinutes;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.errorMessage,
    this.isLocked = false,
    this.lockoutMinutes = 0,
  });

  bool get isAuthenticated => user != null;

  AuthState copyWith({
    UserProfile? user,
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    bool? isLocked,
    int? lockoutMinutes,
    bool clearUser = false,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      isLocked: isLocked ?? this.isLocked,
      lockoutMinutes: lockoutMinutes ?? this.lockoutMinutes,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final AuthRepository _repo;

  AuthNotifier(this._repo) : super(const AuthState()) {
    _initSession();
  }

  Future<void> _initSession() async {
    // Automatically restore session if any
    try {
      state = state.copyWith(isLoading: true);
      // If supabase has current user, fetch profile
      // For now keep state cleared or load initial profile
      state = state.copyWith(isLoading: false);
    } catch (_) {
      state = state.copyWith(isLoading: false);
    }
  }

  Future<bool> signIn({required String phone, required String password}) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.signInWithPhone(phone: phone, password: password);
      state = state.copyWith(
        isLoading: false,
        user: user,
        isLocked: false,
        lockoutMinutes: 0,
      );
      return true;
    } catch (e) {
      final err = e.toString().replaceAll('Exception:', '').trim();
      final rateLimit = await _repo.checkRateLimit(phone);
      state = state.copyWith(
        isLoading: false,
        errorMessage: err,
        isLocked: rateLimit.isLocked,
        lockoutMinutes: rateLimit.minutesRemaining,
      );
      return false;
    }
  }

  Future<bool> signUp({
    required String phone,
    required String password,
    required AppRole role,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.signUpWithPhone(
        phone: phone,
        password: password,
        role: role,
      );
      state = state.copyWith(isLoading: false, user: user);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  Future<bool> completeCustomerOnboarding({
    required String name,
    required String colonyId,
    required String flatNumber,
    String? avatarUrl,
  }) async {
    if (state.user == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await _repo.completeCustomerOnboarding(
        userId: state.user!.id,
        name: name,
        colonyId: colonyId,
        flatNumber: flatNumber,
        avatarUrl: avatarUrl,
      );
      state = state.copyWith(isLoading: false, user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  Future<bool> completeShopOnboarding({
    required String shopName,
    required String ownerName,
    required String colonyId,
    required String category,
    required String address,
    required String hours,
    required Map<String, bool> slots,
    String? photoUrl,
  }) async {
    if (state.user == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final updatedUser = await _repo.completeShopOnboarding(
        userId: state.user!.id,
        shopName: shopName,
        ownerName: ownerName,
        colonyId: colonyId,
        category: category,
        address: address,
        hours: hours,
        slots: slots,
        photoUrl: photoUrl,
      );
      state = state.copyWith(isLoading: false, user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  Future<bool> changePassword(String newPassword) async {
    if (state.user == null) return false;
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      await _repo.changePassword(userId: state.user!.id, newPassword: newPassword);
      final updatedUser = state.user!.copyWith(mustChangePassword: false);
      state = state.copyWith(isLoading: false, user: updatedUser);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString().replaceAll('Exception:', '').trim(),
      );
      return false;
    }
  }

  Future<void> requestPasswordReset(String phone) async {
    try {
      await _repo.requestPasswordReset(phone);
    } catch (_) {}
  }

  Future<void> signOut() async {
    await _repo.signOut();
    state = const AuthState();
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  // Quick switch for demo testing in phase (a)
  void setDemoUser(UserProfile user) {
    state = state.copyWith(user: user, isLoading: false, clearError: true);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthNotifier(repo);
});
