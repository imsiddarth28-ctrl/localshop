import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/widgets/glass/glass.dart';
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
      GlassSnackbar.showSuccess(context, 'Password updated successfully! Welcome to The Local Shop.');
      context.go('/home');
    } else if (mounted) {
      final err = ref.read(authProvider).errorMessage ?? 'Failed to update password. Please try again.';
      GlassSnackbar.showError(context, err);
    }
  }

  @override
  Widget build(BuildContext context) {
    final tr = context.tr;
    final authState = ref.watch(authProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GlassScaffold(
      extendBodyBehindAppBar: true,
      appBar: GlassAppBar(
        automaticallyImplyLeading: false,
        title: Text(tr.changePasswordTitle, style: AppTokens.headingSmall(isDark).copyWith(fontSize: 18)),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: GlassCard(
                padding: const EdgeInsets.all(AppTokens.space32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: (isDark ? AppTokens.accentDark : AppTokens.accentLight).withOpacity(0.18),
                            border: Border.all(
                              color: (isDark ? AppTokens.accentDark : AppTokens.accentLight).withOpacity(0.5),
                            ),
                          ),
                          child: Icon(
                            Icons.security_rounded,
                            size: 38,
                            color: isDark ? AppTokens.accentDark : AppTokens.accentLight,
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Center(
                        child: Text(
                          tr.changePasswordTitle,
                          textAlign: TextAlign.center,
                          style: AppTokens.headingMedium(isDark).copyWith(fontSize: 22),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Center(
                        child: Text(
                          tr.changePasswordSubtitle,
                          textAlign: TextAlign.center,
                          style: AppTokens.bodyMedium(isDark),
                        ),
                      ),
                      const SizedBox(height: 24),
                      GlassTextField(
                        controller: _newPasswordController,
                        label: tr.newPasswordLabel,
                        hint: tr.newPasswordHint,
                        prefixIcon: Icons.lock_outline_rounded,
                        obscureText: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                            size: 20,
                            color: isDark ? AppTokens.textSecondaryDark : AppTokens.textSecondaryLight,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        validator: (val) {
                          if (val == null || val.length < 6) return tr.enterValidPassword;
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      GlassTextField(
                        controller: _confirmPasswordController,
                        label: tr.confirmPasswordLabel,
                        hint: tr.confirmPasswordHint,
                        prefixIcon: Icons.lock_reset_rounded,
                        obscureText: _obscurePassword,
                        validator: (val) {
                          if (val != _newPasswordController.text) return tr.passwordsDoNotMatch;
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),
                      GlassButton(
                        text: tr.updatePasswordBtn,
                        isLoading: authState.isLoading,
                        onPressed: _submit,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
