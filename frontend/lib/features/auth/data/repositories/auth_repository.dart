import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:the_local_shop/core/constants/app_constants.dart';
import 'package:the_local_shop/core/supabase/supabase_config.dart';
import 'package:the_local_shop/core/utils/validators.dart';
import '../../domain/models/app_role.dart';
import '../../domain/models/user_profile.dart';

class RateLimitResult {
  final bool isLocked;
  final int minutesRemaining;
  final int failedAttempts;

  const RateLimitResult({
    required this.isLocked,
    required this.minutesRemaining,
    required this.failedAttempts,
  });
}

class ColonyValidationResult {
  final String colonyId;
  final String colonyName;
  final int maxShops;
  final int approvedShopsCount;

  const ColonyValidationResult({
    required this.colonyId,
    required this.colonyName,
    required this.maxShops,
    required this.approvedShopsCount,
  });
}

class AuthRepository {
  SupabaseClient get _client => SupabaseConfig.client;

  // Local keys for rate limit fallback
  static const String _prefFailedAttemptsPrefix = 'rl_attempts_';
  static const String _prefLockUntilPrefix = 'rl_lock_';

  // ---------------------------------------------------------------------------
  // 1. RATE LIMITING (5 wrong attempts -> 15 min lock)
  // ---------------------------------------------------------------------------
  Future<RateLimitResult> checkRateLimit(String phone) async {
    final e164Phone = AppValidators.formatToE164(phone);

    // 1. Try backend RPC if connected
    if (SupabaseConfig.isInitialized) {
      try {
        final res = await _client.rpc('check_login_rate_limit', params: {
          'p_phone': e164Phone,
        });

        if (res is List && res.isNotEmpty) {
          final row = res.first;
          return RateLimitResult(
            isLocked: row['is_locked'] as bool? ?? false,
            minutesRemaining: (row['minutes_remaining'] as num?)?.toInt() ?? 0,
            failedAttempts: (row['failed_attempts'] as num?)?.toInt() ?? 0,
          );
        }
      } catch (e) {
        debugPrint('Rate limit RPC check failed, checking local cache: $e');
      }
    }

    // 2. Local fallback using SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    final lockUntil = prefs.getInt('$_prefLockUntilPrefix$e164Phone') ?? 0;
    final now = DateTime.now().millisecondsSinceEpoch;

    if (lockUntil > now) {
      final remMinutes = ((lockUntil - now) / 60000).ceil();
      final attempts = prefs.getInt('$_prefFailedAttemptsPrefix$e164Phone') ?? 5;
      return RateLimitResult(isLocked: true, minutesRemaining: remMinutes, failedAttempts: attempts);
    }

    final attempts = prefs.getInt('$_prefFailedAttemptsPrefix$e164Phone') ?? 0;
    return RateLimitResult(isLocked: false, minutesRemaining: 0, failedAttempts: attempts);
  }

  Future<RateLimitResult> recordLoginFailure(String phone) async {
    final e164Phone = AppValidators.formatToE164(phone);

    if (SupabaseConfig.isInitialized) {
      try {
        final res = await _client.rpc('record_login_attempt', params: {
          'p_phone': e164Phone,
          'p_success': false,
        });
        if (res is List && res.isNotEmpty) {
          final row = res.first;
          return RateLimitResult(
            isLocked: row['is_locked'] as bool? ?? false,
            minutesRemaining: (row['minutes_remaining'] as num?)?.toInt() ?? 0,
            failedAttempts: (row['current_failed_attempts'] as num?)?.toInt() ?? 1,
          );
        }
      } catch (e) {
        debugPrint('Failed to record attempt on server: $e');
      }
    }

    // Local record
    final prefs = await SharedPreferences.getInstance();
    final key = '$_prefFailedAttemptsPrefix$e164Phone';
    int attempts = (prefs.getInt(key) ?? 0) + 1;
    await prefs.setInt(key, attempts);

    if (attempts >= AppConstants.maxFailedLoginAttempts) {
      final lockUntil = DateTime.now().add(AppConstants.lockoutDuration).millisecondsSinceEpoch;
      await prefs.setInt('$_prefLockUntilPrefix$e164Phone', lockUntil);
      return RateLimitResult(isLocked: true, minutesRemaining: 15, failedAttempts: attempts);
    }

    return RateLimitResult(isLocked: false, minutesRemaining: 0, failedAttempts: attempts);
  }

  Future<void> clearLoginRateLimit(String phone) async {
    final e164Phone = AppValidators.formatToE164(phone);
    if (SupabaseConfig.isInitialized) {
      try {
        await _client.rpc('record_login_attempt', params: {
          'p_phone': e164Phone,
          'p_success': true,
        });
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_prefFailedAttemptsPrefix$e164Phone');
    await prefs.remove('$_prefLockUntilPrefix$e164Phone');
  }

  // ---------------------------------------------------------------------------
  // 2. SIGN IN & SIGN UP (Phone + Password via synthetic email)
  // ---------------------------------------------------------------------------
  Future<UserProfile> signInWithPhone({
    required String phone,
    required String password,
  }) async {
    final rateLimit = await checkRateLimit(phone);
    if (rateLimit.isLocked) {
      throw Exception('Account locked for ${rateLimit.minutesRemaining} more minutes due to multiple failed attempts.');
    }

    final syntheticEmail = AppValidators.generateSyntheticEmail(phone);
    final e164Phone = AppValidators.formatToE164(phone);

    try {
      if (SupabaseConfig.isInitialized) {
        try {
          final authResponse = await _client.auth.signInWithPassword(
            email: syntheticEmail,
            password: password,
          );

          if (authResponse.user == null) {
            throw Exception('Login failed: Invalid credentials');
          }

          await clearLoginRateLimit(phone);
          return await fetchUserProfile(authResponse.user!.id);
        } catch (e) {
          final errStr = e.toString();
          if (errStr.contains('Failed to fetch') ||
              errStr.contains('AuthRetryableFetchException') ||
              errStr.contains('SocketException')) {
            debugPrint('Supabase connection failed, falling back to demo mode: $e');
            await clearLoginRateLimit(phone);
            return _getDemoMockProfile(e164Phone);
          }
          rethrow;
        }
      } else {
        // Mock demo login for seamless local testing
        await Future.delayed(const Duration(milliseconds: 600));
        await clearLoginRateLimit(phone);
        return _getDemoMockProfile(e164Phone);
      }
    } catch (e) {
      await recordLoginFailure(phone);
      rethrow;
    }
  }

  Future<UserProfile> signUpWithPhone({
    required String phone,
    required String password,
    required AppRole role,
  }) async {
    final syntheticEmail = AppValidators.generateSyntheticEmail(phone);
    final e164Phone = AppValidators.formatToE164(phone);

    if (SupabaseConfig.isInitialized) {
      final authResponse = await _client.auth.signUp(
        email: syntheticEmail,
        password: password,
        data: {
          'phone': e164Phone,
          'role': role.toDbString(),
          'name': 'New User',
        },
      );

      final user = authResponse.user;
      if (user == null) {
        throw Exception('Signup failed. Please try again.');
      }

      // Upsert into public.profiles
      await _client.from('profiles').upsert({
        'id': user.id,
        'role': role.toDbString(),
        'phone': e164Phone,
        'name': 'New User',
        'must_change_password': false,
        'suspended': false,
      });

      return await fetchUserProfile(user.id);
    } else {
      // Demo mock profile
      await Future.delayed(const Duration(milliseconds: 600));
      return UserProfile(
        id: 'mock-user-id-${DateTime.now().millisecondsSinceEpoch}',
        role: role,
        phone: e164Phone,
        name: 'New User',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 3. JOIN CODE RPC VALIDATION
  // ---------------------------------------------------------------------------
  Future<ColonyValidationResult?> validateColonyJoinCode(String code) async {
    final normalized = code.trim().toUpperCase();

    if (SupabaseConfig.isInitialized) {
      try {
        final res = await _client.rpc('validate_colony_join_code', params: {
          'p_join_code': normalized,
        });

        if (res is List && res.isNotEmpty) {
          final row = res.first;
          return ColonyValidationResult(
            colonyId: row['colony_id'] as String,
            colonyName: row['colony_name'] as String,
            maxShops: (row['max_shops'] as num?)?.toInt() ?? 3,
            approvedShopsCount: (row['approved_shops_count'] as num?)?.toInt() ?? 0,
          );
        }
      } catch (e) {
        debugPrint('Colony validation error: $e');
      }
    }

    // Demo fallback for default colony code GRN101
    if (normalized == AppConstants.demoColonyJoinCode) {
      return const ColonyValidationResult(
        colonyId: 'c0000000-0000-0000-0000-000000000001',
        colonyName: 'Greenwood Heights',
        maxShops: 3,
        approvedShopsCount: 3,
      );
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // 4. ONBOARDING COMPLETION
  // ---------------------------------------------------------------------------
  Future<UserProfile> completeCustomerOnboarding({
    required String userId,
    required String name,
    required String colonyId,
    required String flatNumber,
    String? avatarUrl,
  }) async {
    if (SupabaseConfig.isInitialized) {
      try {
        await _client.from('profiles').update({
          'name': name.trim(),
          'colony_id': colonyId,
          'address': flatNumber.trim(),
          'avatar_url': avatarUrl,
          'updated_at': DateTime.now().toIso8601String(),
        }).eq('id', userId);

        return await fetchUserProfile(userId);
      } catch (e) {
        debugPrint('Profile update error: $e');
        // Handle case where colony was not seeded in colonies table
        if (e.toString().contains('foreign key') || e.toString().contains('colony_id') || e.toString().contains('23503')) {
          try {
            await _client.from('colonies').upsert({
              'id': colonyId,
              'name': 'Greenwood Heights',
              'join_code': 'GRN101',
              'max_shops': 3,
            });
            await _client.from('profiles').update({
              'name': name.trim(),
              'colony_id': colonyId,
              'address': flatNumber.trim(),
              'avatar_url': avatarUrl,
              'updated_at': DateTime.now().toIso8601String(),
            }).eq('id', userId);
            return await fetchUserProfile(userId);
          } catch (inner) {
            debugPrint('Colony recovery error: $inner');
            rethrow;
          }
        }
        rethrow;
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      return UserProfile(
        id: userId,
        role: AppRole.customer,
        phone: '+919444444441',
        name: name,
        colonyId: colonyId,
        colonyName: 'Greenwood Heights',
        address: flatNumber,
        avatarUrl: avatarUrl,
      );
    }
  }

  Future<UserProfile> completeShopOnboarding({
    required String userId,
    required String shopName,
    required String ownerName,
    required String colonyId,
    required String category,
    required String address,
    required String hours,
    required Map<String, bool> slots,
    String? photoUrl,
  }) async {
    if (SupabaseConfig.isInitialized) {
      // 1. Update owner profile name & colony
      await _client.from('profiles').update({
        'name': ownerName.trim(),
        'colony_id': colonyId,
        'address': address.trim(),
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);

      // 2. Insert into shops table with status 'pending'
      await _client.from('shops').insert({
        'owner_id': userId,
        'colony_id': colonyId,
        'name': shopName.trim(),
        'category': category,
        'hours': hours.trim(),
        'slots': slots,
        'photo_url': photoUrl,
        'status': 'pending',
      });

      return await fetchUserProfile(userId);
    } else {
      await Future.delayed(const Duration(milliseconds: 500));
      return UserProfile(
        id: userId,
        role: AppRole.shopOwner,
        phone: '+919111111111',
        name: ownerName,
        colonyId: colonyId,
        colonyName: 'Greenwood Heights',
        address: address,
        shopStatus: 'pending',
        shopName: shopName,
      );
    }
  }

  // ---------------------------------------------------------------------------
  // 5. PASSWORD RESET & CHANGE
  // ---------------------------------------------------------------------------
  Future<void> requestPasswordReset(String phone) async {
    final e164Phone = AppValidators.formatToE164(phone);

    if (SupabaseConfig.isInitialized) {
      // Lookup user_id from profiles if exists
      final profile = await _client
          .from('profiles')
          .select('id')
          .eq('phone', e164Phone)
          .maybeSingle();

      if (profile != null) {
        await _client.from('password_reset_requests').insert({
          'user_id': profile['id'],
          'phone': e164Phone,
          'status': 'pending',
        });
      } else {
        // Unregistered number or silent success for security
        debugPrint('Password reset requested for unlinked phone: $e164Phone');
      }
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  Future<void> changePassword({
    required String userId,
    required String newPassword,
  }) async {
    if (SupabaseConfig.isInitialized) {
      await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );

      await _client.from('profiles').update({
        'must_change_password': false,
        'updated_at': DateTime.now().toIso8601String(),
      }).eq('id', userId);
    } else {
      await Future.delayed(const Duration(milliseconds: 400));
    }
  }

  // ---------------------------------------------------------------------------
  // 6. PROFILE FETCH & LOGOUT
  // ---------------------------------------------------------------------------
  Future<UserProfile> fetchUserProfile(String userId) async {
    if (SupabaseConfig.isInitialized) {
      final profileRes = await _client
          .from('profiles')
          .select('*, colonies(name)')
          .eq('id', userId)
          .single();

      // Check if user is shop owner to fetch shop info
      Map<String, dynamic>? shopRes;
      if (profileRes['role'] == 'shop_owner') {
        shopRes = await _client
            .from('shops')
            .select('id, name, status')
            .eq('owner_id', userId)
            .maybeSingle();
      }

      return UserProfile.fromJson(profileRes, shopJson: shopRes);
    } else {
      return _getDemoMockProfile('+919444444441');
    }
  }

  Future<void> signOut() async {
    if (SupabaseConfig.isInitialized) {
      await _client.auth.signOut();
    }
  }

  Future<void> deleteAccount(String userId) async {
    if (SupabaseConfig.isInitialized) {
      await _client.from('profiles').update({'suspended': true}).eq('id', userId);
      await _client.auth.signOut();
    }
  }

  UserProfile _getDemoMockProfile(String phone) {
    final cleanPhone = AppValidators.formatToE164(phone);
    if (phone.contains('9000000000')) {
      return UserProfile(
        id: 'usr_admin',
        role: AppRole.admin,
        phone: cleanPhone,
        name: 'Administrator',
        address: 'Colony Management Desk',
      );
    } else if (phone.contains('9111111111')) {
      return UserProfile(
        id: 'usr_shopowner',
        role: AppRole.shopOwner,
        phone: cleanPhone,
        name: 'Store Owner',
        colonyId: 'c0000000-0000-0000-0000-000000000001',
        colonyName: 'Greenwood Heights',
        address: 'Shop 1, Community Center',
        shopStatus: 'approved',
        shopId: 'e0000000-0000-0000-0000-000000000001',
        shopName: 'Sri Balaji Kirana & General Store',
      );
    } else {
      return UserProfile(
        id: 'usr_${phone.replaceAll(RegExp(r'\D'), '')}',
        role: AppRole.customer,
        phone: cleanPhone,
        name: 'Resident',
        colonyId: 'c0000000-0000-0000-0000-000000000001',
        colonyName: 'Greenwood Heights',
        address: 'Flat Resident',
      );
    }
  }
}
