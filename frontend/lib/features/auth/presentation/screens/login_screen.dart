import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/elder_friendly_button.dart';
import '../../../../core/widgets/elder_friendly_text_field.dart';
import '../../../../core/widgets/language_selector.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(authProvider.notifier).signIn(
          phone: phone,
          password: password,
        );

    if (success && mounted) {
      final user = ref.read(authProvider).user!;
      if (user.mustChangePassword) {
        context.go('/forced-change-password');
      } else if (!user.isOnboarded) {
        if (user.role.toDbString() == 'shop_owner') {
          context.go('/onboarding/shop');
        } else {
          context.go('/onboarding/customer');
        }
      } else if (user.role.toDbString() == 'shop_owner' && user.shopStatus == 'pending') {
        context.go('/pending-approval');
      } else {
        context.go('/home');
      }
    }
  }

  void _showForgotPasswordDialog() {
    final tr = context.tr;
    final resetPhoneController = TextEditingController(text: _phoneController.text);

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          tr.requestPasswordReset,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter your 10-digit mobile number. The colony admin will verify and reset your password.',
              style: TextStyle(color: Colors.grey[700], fontSize: 15),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: resetPhoneController,
              keyboardType: TextInputType.phone,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.phone),
                hintText: '10-digit number',
                prefixText: '+91 ',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(tr.cancelBtn, style: const TextStyle(fontSize: 16)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () async {
              final phone = resetPhoneController.text.trim();
              if (AppValidators.isValidIndianPhone(phone)) {
                Navigator.pop(dialogContext);
                await ref.read(authProvider.notifier).requestPasswordReset(phone);
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(tr.resetRequestedSuccess),
                      backgroundColor: AppColors.success,
                      duration: const Duration(seconds: 4),
                    ),
                  );
                }
              }
            },
            child: Text(tr.submitBtn, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.appTitle),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: LanguageSelector(),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Welcome Header
                Text(
                  tr.loginTitle,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  tr.loginSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 16,
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Rate Limit Lockout Banner
                if (authState.isLocked) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.error, width: 2),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_clock, color: AppColors.error, size: 28),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Account Temporarily Locked',
                                style: TextStyle(
                                  color: AppColors.error,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Too many failed attempts. Try again in ${authState.lockoutMinutes} minutes or request an admin password reset.',
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Error Banner
                if (authState.errorMessage != null && !authState.isLocked) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.error.withOpacity(0.5)),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // Phone Input
                ElderFriendlyTextField(
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
                const SizedBox(height: 20),

                // Password Input
                ElderFriendlyTextField(
                  controller: _passwordController,
                  label: tr.passwordLabel,
                  hint: tr.passwordHint,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondaryLight,
                      size: 26,
                    ),
                    tooltip: _obscurePassword ? tr.showPassword : tr.hidePassword,
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                  validator: (val) {
                    if (!AppValidators.isValidPassword(val)) {
                      return tr.enterValidPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // Forgot Password link
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: _showForgotPasswordDialog,
                    child: Text(
                      tr.forgotPassword,
                      style: const TextStyle(
                        color: AppColors.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Submit Button
                ElderFriendlyButton(
                  text: tr.loginBtn,
                  isLoading: authState.isLoading,
                  onPressed: authState.isLocked ? null : _submitLogin,
                ),
                const SizedBox(height: 24),

                // Sign Up link
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        tr.noAccount,
                        style: theme.textTheme.bodyMedium?.copyWith(fontSize: 16),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () {
                          ref.read(authProvider.notifier).clearError();
                          context.push('/signup');
                        },
                        child: Text(
                          tr.signupLink,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primary,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
