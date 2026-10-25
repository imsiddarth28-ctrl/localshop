import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/theme/theme_provider.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/glass/glass.dart';
import '../../../../core/widgets/language_selector.dart';
import '../../domain/models/app_role.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  final bool initialIsSignUp;

  const LoginScreen({
    super.key,
    this.initialIsSignUp = false,
  });

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen>
    with SingleTickerProviderStateMixin {
  late bool _isSignUp;

  // Form Controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _signupFormKey = GlobalKey<FormState>();

  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();

  final _signupNameController = TextEditingController();
  final _signupPhoneController = TextEditingController();
  final _signupPasswordController = TextEditingController();
  final _signupConfirmPasswordController = TextEditingController();

  bool _obscureLoginPassword = true;
  bool _obscureSignupPassword = true;
  bool _obscureSignupConfirm = true;

  AppRole _selectedRole = AppRole.customer;
  bool _showSuccessCheck = false;

  @override
  void initState() {
    super.initState();
    _isSignUp = widget.initialIsSignUp;
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _signupNameController.dispose();
    _signupPhoneController.dispose();
    _signupPasswordController.dispose();
    _signupConfirmPasswordController.dispose();
    super.dispose();
  }

  // --- Password Strength Evaluator ---
  int _evaluatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 8) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[A-Za-z]').hasMatch(password)) score++;
    return score; // 0 to 4
  }

  // --- Submit Login ---
  Future<void> _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(authProvider.notifier).signIn(
          phone: phone,
          password: password,
        );

    if (success && mounted) {
      HapticFeedback.lightImpact();
      setState(() => _showSuccessCheck = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      final user = ref.read(authProvider).user!;
      if (user.mustChangePassword) {
        context.go('/forced-change-password');
      } else if (!user.isOnboarded) {
        if (user.role == AppRole.shopOwner) {
          context.go('/onboarding/shop');
        } else {
          context.go('/onboarding/customer');
        }
      } else if (user.role == AppRole.shopOwner && user.shopStatus == 'pending') {
        context.go('/pending-approval');
      } else {
        context.go('/home');
      }
    } else if (mounted) {
      final err = ref.read(authProvider).errorMessage ?? 'Login failed. Please verify credentials.';
      GlassSnackbar.showError(context, err);
      HapticFeedback.heavyImpact();
    }
  }

  // --- Submit Sign Up ---
  Future<void> _handleSignUp() async {
    if (!_signupFormKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    final phone = _signupPhoneController.text.trim();
    final password = _signupPasswordController.text;

    final success = await ref.read(authProvider.notifier).signUp(
          phone: phone,
          password: password,
          role: _selectedRole,
        );

    if (success && mounted) {
      HapticFeedback.lightImpact();
      setState(() => _showSuccessCheck = true);
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;

      if (_selectedRole == AppRole.shopOwner) {
        context.go('/onboarding/shop');
      } else {
        context.go('/onboarding/customer');
      }
    } else if (mounted) {
      final err = ref.read(authProvider).errorMessage ?? 'Registration failed. Please try again.';
      GlassSnackbar.showError(context, err);
      HapticFeedback.heavyImpact();
    }
  }

  // --- Forgot Password Sheet ---
  void _openForgotPasswordSheet() {
    final tr = context.tr;
    final resetPhoneController = TextEditingController(text: _phoneController.text);

    GlassBottomSheet.show(
      context: context,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_reset_rounded, color: AppTokens.primaryDark, size: 28),
              const SizedBox(width: 10),
              Text(
                tr.requestPasswordReset,
                style: AppTokens.headingSmall(Theme.of(context).brightness == Brightness.dark),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Enter your 10-digit mobile number. Colony admin will securely reset your access password.',
            style: AppTokens.bodyMedium(Theme.of(context).brightness == Brightness.dark),
          ),
          const SizedBox(height: 20),
          GlassTextField(
            controller: resetPhoneController,
            label: tr.phoneLabel,
            hint: '10-digit mobile number',
            prefixIcon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 24),
          GlassButton(
            text: tr.submitBtn,
            onPressed: () async {
              final phone = resetPhoneController.text.trim();
              if (AppValidators.isValidIndianPhone(phone)) {
                Navigator.pop(context);
                await ref.read(authProvider.notifier).requestPasswordReset(phone);
                if (mounted) {
                  GlassSnackbar.showSuccess(context, tr.resetRequestedSuccess);
                }
              } else {
                GlassSnackbar.showError(context, tr.enterValidPhone);
              }
            },
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  // --- Demo Credentials Auto-Fill ---
  void _fillDemoCredentials(String phone, String pass) {
    HapticFeedback.selectionClick();
    setState(() {
      _phoneController.text = phone;
      _passwordController.text = pass;
    });
    GlassSnackbar.showInfo(context, 'Filled demo account: $phone');
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeModeProvider);

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        title: Text(
          AppConstants.appName,
          style: AppTokens.headingSmall(isDark).copyWith(fontSize: 18),
        ),
        actions: [
          // Theme Toggle Icon
          IconButton(
            icon: Icon(
              isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
              size: 20,
              color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight,
            ),
            tooltip: 'Toggle Theme',
            onPressed: () => ref.read(themeModeProvider.notifier).toggleTheme(),
          ),
          // Language Selector
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // 1. Hero Logo
                  Hero(
                    tag: 'app_logo_hero',
                    child: Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isDark ? const Color(0x2934D399) : const Color(0x33059669),
                        border: Border.all(
                          color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                          width: 1.8,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(0.3),
                            blurRadius: 20,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.storefront_rounded,
                        size: 38,
                        color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Text(
                    tr.appTitle,
                    style: AppTokens.headingMedium(isDark).copyWith(letterSpacing: 0.3),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr.appTagline,
                    style: AppTokens.bodySmall(isDark),
                  ),
                  const SizedBox(height: 24),

                  // 2. Centered GlassCard with Segmented Toggle
                  GlassCard(
                    useRealBlur: true,
                    padding: const EdgeInsets.all(AppTokens.space24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Segmented Glass Slider (Login | Sign up)
                        Container(
                          height: 46,
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                            color: isDark ? const Color(0x1AFFFFFF) : const Color(0x330F172A),
                            border: Border.all(
                              color: isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight,
                              width: 1.0,
                            ),
                          ),
                          child: Stack(
                            children: [
                              // Sliding indicator pill
                              AnimatedAlign(
                                duration: AppTokens.durationMedium,
                                curve: AppTokens.curvePop,
                                alignment: _isSignUp ? Alignment.centerRight : Alignment.centerLeft,
                                child: FractionallySizedBox(
                                  widthFactor: 0.5,
                                  heightFactor: 1.0,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                                      color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                      boxShadow: [
                                        BoxShadow(
                                          color: (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(0.4),
                                          blurRadius: 10,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              // Labels
                              Row(
                                children: [
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (_isSignUp) {
                                          HapticFeedback.selectionClick();
                                          setState(() => _isSignUp = false);
                                        }
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Center(
                                        child: Text(
                                          'Login',
                                          style: AppTokens.label(
                                            isDark,
                                            color: !_isSignUp
                                                ? (isDark ? const Color(0xFF0A0F1C) : Colors.white)
                                                : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
                                          ).copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        if (!_isSignUp) {
                                          HapticFeedback.selectionClick();
                                          setState(() => _isSignUp = true);
                                        }
                                      },
                                      behavior: HitTestBehavior.opaque,
                                      child: Center(
                                        child: Text(
                                          'Sign up',
                                          style: AppTokens.label(
                                            isDark,
                                            color: _isSignUp
                                                ? (isDark ? const Color(0xFF0A0F1C) : Colors.white)
                                                : (isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight),
                                          ).copyWith(fontWeight: FontWeight.w700),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Form switcher with animated crossfade
                        AnimatedCrossFade(
                          crossFadeState: _isSignUp ? CrossFadeState.showSecond : CrossFadeState.showFirst,
                          duration: AppTokens.durationMedium,
                          firstChild: _buildLoginForm(tr, isDark, authState),
                          secondChild: _buildSignupForm(tr, isDark, authState),
                        ),
                      ],
                    ),
                  ),

                  // 3. Demo Account Auto-Fill Bar
                  if (!_isSignUp) ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Quick Demo: ', style: AppTokens.bodySmall(isDark)),
                        GestureDetector(
                          onTap: () => _fillDemoCredentials('9444444441', 'password123'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                              color: isDark ? const Color(0x1F34D399) : const Color(0x24059669),
                              border: Border.all(
                                color: (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              'Customer (4441)',
                              style: AppTokens.bodySmall(isDark).copyWith(
                                color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        GestureDetector(
                          onTap: () => _fillDemoCredentials('9444444440', 'password123'),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTokens.radiusChip),
                              color: isDark ? const Color(0x1FFBBF24) : const Color(0x24D97706),
                              border: Border.all(
                                color: (isDark ? AppTokens.accentDark : AppTokens.accentLight).withOpacity(0.4),
                              ),
                            ),
                            child: Text(
                              'Shopkeeper (4440)',
                              style: AppTokens.bodySmall(isDark).copyWith(
                                color: isDark ? AppTokens.accentDark : AppTokens.accentLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // --- LOGIN FORM ---
  Widget _buildLoginForm(dynamic tr, bool isDark, dynamic authState) {
    return Form(
      key: _loginFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassTextField(
            controller: _phoneController,
            label: tr.phoneLabel,
            hint: tr.phoneHint,
            prefixIcon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (!AppValidators.isValidIndianPhone(val)) {
                return tr.enterValidPhone;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _passwordController,
            label: tr.passwordLabel,
            hint: tr.passwordHint,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureLoginPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureLoginPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 20,
                color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
              ),
              onPressed: () => setState(() => _obscureLoginPassword = !_obscureLoginPassword),
            ),
            validator: (val) {
              if (val == null || val.length < 6) {
                return tr.enterValidPassword;
              }
              return null;
            },
            onSubmitted: (_) => _handleLogin(),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              style: TextButton.styleFrom(padding: EdgeInsets.zero),
              onPressed: _openForgotPasswordSheet,
              child: Text(
                tr.forgotPassword,
                style: AppTokens.bodySmall(isDark).copyWith(
                  color: isDark ? AppTokens.accentDark : AppTokens.accentLight,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          GlassButton(
            text: _showSuccessCheck ? 'Logged in! ✓' : tr.loginBtn,
            isLoading: authState.isLoading,
            onPressed: _showSuccessCheck ? null : _handleLogin,
          ),
        ],
      ),
    );
  }

  // --- SIGN UP FORM ---
  Widget _buildSignupForm(dynamic tr, bool isDark, dynamic authState) {
    final passwordScore = _evaluatePasswordStrength(_signupPasswordController.text);

    return Form(
      key: _signupFormKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GlassTextField(
            controller: _signupNameController,
            label: 'Full Name',
            hint: 'Your full name',
            prefixIcon: Icons.person_outline_rounded,
            validator: (val) {
              if (val == null || val.trim().isEmpty) return 'Please enter your name';
              return null;
            },
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _signupPhoneController,
            label: tr.phoneLabel,
            hint: tr.phoneHint,
            prefixIcon: Icons.phone_android_rounded,
            keyboardType: TextInputType.phone,
            validator: (val) {
              if (!AppValidators.isValidIndianPhone(val)) {
                return tr.enterValidPhone;
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          GlassTextField(
            controller: _signupPasswordController,
            label: tr.passwordLabel,
            hint: tr.passwordHint,
            prefixIcon: Icons.lock_outline_rounded,
            obscureText: _obscureSignupPassword,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignupPassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 20,
                color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
              ),
              onPressed: () => setState(() => _obscureSignupPassword = !_obscureSignupPassword),
            ),
            onChanged: (_) => setState(() {}),
            validator: (val) {
              if (val == null || val.length < 6) return tr.enterValidPassword;
              return null;
            },
          ),
          // Password Strength Bar
          if (_signupPasswordController.text.isNotEmpty) ...[
            const SizedBox(height: 6),
            Row(
              children: List.generate(4, (index) {
                final isFilled = index < passwordScore;
                Color color = AppTokens.dangerDark;
                if (passwordScore == 2) color = AppTokens.accentDark;
                if (passwordScore >= 3) color = AppTokens.primaryDark;

                return Expanded(
                  child: Container(
                    height: 3.5,
                    margin: const EdgeInsets.symmetric(horizontal: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(2),
                      color: isFilled ? color : (isDark ? Colors.white12 : Colors.black12),
                    ),
                  ),
                );
              }),
            ),
          ],
          const SizedBox(height: 16),
          GlassTextField(
            controller: _signupConfirmPasswordController,
            label: tr.confirmPasswordLabel,
            hint: tr.confirmPasswordHint,
            prefixIcon: Icons.lock_reset_rounded,
            obscureText: _obscureSignupConfirm,
            suffixIcon: IconButton(
              icon: Icon(
                _obscureSignupConfirm ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                size: 20,
                color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
              ),
              onPressed: () => setState(() => _obscureSignupConfirm = !_obscureSignupConfirm),
            ),
            validator: (val) {
              if (val != _signupPasswordController.text) return tr.passwordsDoNotMatch;
              return null;
            },
          ),
          const SizedBox(height: 18),
          // Role Selection Cards
          Text(
            tr.chooseRoleTitle,
            style: AppTokens.label(isDark).copyWith(fontSize: 13),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: GlassChip(
                  label: tr.customerRoleTitle,
                  subtitle: 'Colony Resident',
                  icon: Icons.shopping_basket_rounded,
                  isSelected: _selectedRole == AppRole.customer,
                  onTap: () => setState(() => _selectedRole = AppRole.customer),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: GlassChip(
                  label: tr.shopOwnerRoleTitle,
                  subtitle: 'Store Owner',
                  icon: Icons.storefront_rounded,
                  isSelected: _selectedRole == AppRole.shopOwner,
                  activeColor: isDark ? AppTokens.accentDark : AppTokens.accentLight,
                  onTap: () => setState(() => _selectedRole = AppRole.shopOwner),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          GlassButton(
            text: _showSuccessCheck ? 'Account Created! ✓' : tr.signupBtn,
            isLoading: authState.isLoading,
            onPressed: _showSuccessCheck ? null : _handleSignUp,
          ),
        ],
      ),
    );
  }
}
