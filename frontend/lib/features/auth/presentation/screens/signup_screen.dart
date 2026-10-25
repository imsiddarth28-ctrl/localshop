import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/elder_friendly_button.dart';
import '../../../../core/widgets/elder_friendly_text_field.dart';
import '../../domain/models/app_role.dart';
import '../providers/auth_provider.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  AppRole _selectedRole = AppRole.customer;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submitSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final password = _passwordController.text;

    final success = await ref.read(authProvider.notifier).signUp(
          phone: phone,
          password: password,
          role: _selectedRole,
        );

    if (success && mounted) {
      if (_selectedRole == AppRole.shopOwner) {
        context.go('/onboarding/shop');
      } else {
        context.go('/onboarding/customer');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final authState = ref.watch(authProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(tr.signupTitle),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.signupTitle,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr.signupSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Error Banner
                if (authState.errorMessage != null) ...[
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
                const SizedBox(height: 18),

                // Password
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
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (!AppValidators.isValidPassword(val)) {
                      return tr.enterValidPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),

                // Confirm Password
                ElderFriendlyTextField(
                  controller: _confirmPasswordController,
                  label: tr.confirmPasswordLabel,
                  hint: tr.confirmPasswordHint,
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: _obscureConfirmPassword,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                      color: AppColors.textSecondaryLight,
                    ),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                  validator: (val) {
                    if (val != _passwordController.text) {
                      return tr.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Role Picker Section
                Text(
                  tr.chooseRoleTitle,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr.chooseRoleSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(fontSize: 14),
                ),
                const SizedBox(height: 14),

                // Customer Option Card
                _buildRoleCard(
                  role: AppRole.customer,
                  title: tr.customerRoleTitle,
                  description: tr.customerRoleDesc,
                  icon: Icons.shopping_basket_rounded,
                  iconColor: AppColors.primary,
                  isSelected: _selectedRole == AppRole.customer,
                  onTap: () => setState(() => _selectedRole = AppRole.customer),
                ),
                const SizedBox(height: 12),

                // Shop Owner Option Card
                _buildRoleCard(
                  role: AppRole.shopOwner,
                  title: tr.shopOwnerRoleTitle,
                  description: tr.shopOwnerRoleDesc,
                  icon: Icons.storefront_rounded,
                  iconColor: AppColors.secondary,
                  isSelected: _selectedRole == AppRole.shopOwner,
                  onTap: () => setState(() => _selectedRole = AppRole.shopOwner),
                ),
                const SizedBox(height: 28),

                // Submit Button
                ElderFriendlyButton(
                  text: tr.continueBtn,
                  isLoading: authState.isLoading,
                  onPressed: _submitSignup,
                ),
                const SizedBox(height: 20),

                // Back to login
                Center(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(tr.alreadyHaveAccount, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => context.pop(),
                        child: Text(
                          tr.loginLink,
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

  Widget _buildRoleCard({
    required AppRole role,
    required String title,
    required String description,
    required IconData icon,
    required Color iconColor,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? (role == AppRole.customer
                  ? AppColors.primaryContainer.withOpacity(0.5)
                  : AppColors.secondaryContainer.withOpacity(0.5))
              : (isDark ? AppColors.surfaceDark : Colors.white),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? (role == AppRole.customer ? AppColors.primary : AppColors.secondary)
                : AppColors.dividerLight,
            width: isSelected ? 2.5 : 1.2,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: (role == AppRole.customer ? AppColors.primary : AppColors.secondary).withOpacity(0.15),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isSelected ? iconColor.withOpacity(0.15) : AppColors.dividerLight.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 28),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                          ),
                        ),
                      ),
                      Radio<AppRole>(
                        value: role,
                        groupValue: _selectedRole,
                        activeColor: role == AppRole.customer ? AppColors.primary : AppColors.secondary,
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedRole = val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
