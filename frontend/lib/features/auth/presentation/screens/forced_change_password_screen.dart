import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/elder_friendly_button.dart';
import '../../../../core/widgets/elder_friendly_text_field.dart';
import '../providers/auth_provider.dart';

class ForcedChangePasswordScreen extends ConsumerStatefulWidget {
  const ForcedChangePasswordScreen({super.key});

  @override
  ConsumerState<ForcedChangePasswordScreen> createState() => _ForcedChangePasswordScreenState();
}

class _ForcedChangePasswordScreenState extends ConsumerState<ForcedChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref.read(authProvider.notifier).changePassword(
          _newPasswordController.text,
        );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password updated successfully! Welcome to The Local Shop.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go('/home');
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
        title: Text(tr.changePasswordTitle),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryContainer.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.secondaryLight),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.security, color: AppColors.secondary, size: 32),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          tr.changePasswordSubtitle,
                          style: TextStyle(
                            color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),

                // Error Banner
                if (authState.errorMessage != null) ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      authState.errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                // New Password
                ElderFriendlyTextField(
                  controller: _newPasswordController,
                  label: tr.newPasswordLabel,
                  hint: tr.newPasswordHint,
                  prefixIcon: Icons.lock_outline_rounded,
                  obscureText: _obscurePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: (val) {
                    if (!AppValidators.isValidPassword(val)) {
                      return tr.enterValidPassword;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Confirm New Password
                ElderFriendlyTextField(
                  controller: _confirmPasswordController,
                  label: tr.confirmPasswordLabel,
                  hint: tr.confirmPasswordHint,
                  prefixIcon: Icons.lock_reset_rounded,
                  obscureText: _obscurePassword,
                  validator: (val) {
                    if (val != _newPasswordController.text) {
                      return tr.passwordsDoNotMatch;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 36),

                // Submit Button
                ElderFriendlyButton(
                  text: tr.updatePasswordBtn,
                  isLoading: authState.isLoading,
                  onPressed: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
