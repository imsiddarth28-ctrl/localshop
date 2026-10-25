import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_tokens.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/glass/glass.dart';
import '../../data/repositories/auth_repository.dart';
import '../providers/auth_provider.dart';

class CustomerOnboardingScreen extends ConsumerStatefulWidget {
  const CustomerOnboardingScreen({super.key});

  @override
  ConsumerState<CustomerOnboardingScreen> createState() => _CustomerOnboardingScreenState();
}

class _CustomerOnboardingScreenState extends ConsumerState<CustomerOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _joinCodeController = TextEditingController();
  final _flatController = TextEditingController();

  File? _avatarImageFile;
  bool _isValidatingCode = false;
  ColonyValidationResult? _verifiedColony;
  String? _colonyError;

  @override
  void initState() {
    super.initState();
    _joinCodeController.text = AppConstants.demoColonyJoinCode;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _onJoinCodeChanged(AppConstants.demoColonyJoinCode);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _joinCodeController.dispose();
    _flatController.dispose();
    super.dispose();
  }

  void _onJoinCodeChanged(String value) async {
    final cleanCode = value.trim().toUpperCase();
    if (cleanCode.length == 6) {
      setState(() {
        _isValidatingCode = true;
        _colonyError = null;
      });

      final repo = ref.read(authRepositoryProvider);
      final res = await repo.validateColonyJoinCode(cleanCode);

      if (mounted) {
        setState(() {
          _isValidatingCode = false;
          if (res != null) {
            _verifiedColony = res;
            _colonyError = null;
          } else {
            _verifiedColony = null;
            _colonyError = 'Invalid join code. Please get 6-character code from colony admin.';
          }
        });
      }
    } else {
      if (_verifiedColony != null || _colonyError != null) {
        setState(() {
          _verifiedColony = null;
          _colonyError = null;
        });
      }
    }
  }

  Future<void> _pickAvatar() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 800,
        maxHeight: 800,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _avatarImageFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking avatar: $e');
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      GlassSnackbar.showError(context, 'Please enter your full name and flat number.');
      return;
    }

    if (_verifiedColony == null) {
      final cleanCode = _joinCodeController.text.trim().toUpperCase();
      if (cleanCode.length == 6) {
        setState(() => _isValidatingCode = true);
        final repo = ref.read(authRepositoryProvider);
        final res = await repo.validateColonyJoinCode(cleanCode);
        if (mounted) {
          setState(() {
            _isValidatingCode = false;
            _verifiedColony = res;
          });
        }
      }
    }

    if (!mounted) return;

    if (_verifiedColony == null) {
      setState(() {
        _colonyError = 'Please enter a valid 6-character colony join code (e.g. GRN101)';
      });
      GlassSnackbar.showError(context, 'Please verify your colony code (e.g. GRN101) before continuing.');
      return;
    }

    final sanitizedName = AppValidators.sanitizeText(_nameController.text);
    final sanitizedFlat = AppValidators.sanitizeText(_flatController.text);

    final success = await ref.read(authProvider.notifier).completeCustomerOnboarding(
          name: sanitizedName,
          colonyId: _verifiedColony!.colonyId,
          flatNumber: sanitizedFlat,
          avatarUrl: _avatarImageFile?.path,
        );

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage ?? 'Failed to complete profile. Please try again.';
      GlassSnackbar.showError(context, error);
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
        title: Text(
          tr.customerOnboardingTitle,
          style: AppTokens.headingSmall(isDark).copyWith(fontSize: 18),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.logout_rounded, color: isDark ? AppTokens.textPrimaryDark : AppTokens.textPrimaryLight),
            tooltip: tr.logout,
            onPressed: () async {
              await ref.read(authProvider.notifier).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.customerOnboardingTitle,
                    style: AppTokens.headingMedium(isDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr.customerOnboardingSubtitle,
                    style: AppTokens.bodyMedium(isDark),
                  ),
                  const SizedBox(height: 20),

                  // Avatar Picker Glass Box
                  Center(
                    child: Stack(
                      children: [
                        Container(
                          width: 88,
                          height: 88,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? const Color(0x2934D399) : const Color(0x33059669),
                            border: Border.all(
                              color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                              width: 1.5,
                            ),
                          ),
                          child: ClipOval(
                            child: _avatarImageFile != null
                                ? Image.file(_avatarImageFile!, fit: BoxFit.cover)
                                : Icon(
                                    Icons.person_rounded,
                                    size: 48,
                                    color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                  ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: InkWell(
                            onTap: _pickAvatar,
                            child: Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: isDark ? AppTokens.accentDark : AppTokens.accentLight,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Onboarding Fields Card
                  GlassCard(
                    padding: const EdgeInsets.all(AppTokens.space24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Full Name
                        GlassTextField(
                          controller: _nameController,
                          label: tr.fullNameLabel,
                          hint: tr.fullNameHint,
                          prefixIcon: Icons.badge_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return tr.enterFullName;
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Join Code
                        GlassTextField(
                          controller: _joinCodeController,
                          label: tr.colonyCodeLabel,
                          hint: tr.colonyCodeHint,
                          prefixIcon: Icons.vpn_key_outlined,
                          onChanged: _onJoinCodeChanged,
                          suffixIcon: _isValidatingCode
                              ? const Padding(
                                  padding: EdgeInsets.all(12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                )
                              : (_verifiedColony != null
                                  ? const Icon(Icons.check_circle_rounded, color: AppTokens.primaryDark)
                                  : null),
                          validator: (val) {
                            if (val == null || val.trim().length != 6) {
                              return tr.enterColonyCode;
                            }
                            return null;
                          },
                        ),

                        // Verified Colony Banner
                        if (_verifiedColony != null) ...[
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(AppTokens.radiusButton),
                              color: (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(0.15),
                              border: Border.all(
                                color: (isDark ? AppTokens.primaryDark : AppTokens.primaryLight).withOpacity(0.5),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.location_city_rounded, size: 18, color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Colony: ${_verifiedColony!.colonyName} (${_verifiedColony!.approvedShopsCount} shops available)',
                                    style: AppTokens.bodySmall(isDark).copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ] else if (_colonyError != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _colonyError!,
                            style: AppTokens.bodySmall(isDark).copyWith(color: AppTokens.dangerDark, fontWeight: FontWeight.w600),
                          ),
                        ] else ...[
                          const SizedBox(height: 8),
                          Text(
                            '${tr.colonyCodeHelp} (Default demo: GRN101)',
                            style: AppTokens.bodySmall(isDark),
                          ),
                        ],
                        const SizedBox(height: 18),

                        // Flat Number
                        GlassTextField(
                          controller: _flatController,
                          label: tr.flatLabel,
                          hint: tr.flatHint,
                          prefixIcon: Icons.home_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return tr.enterFlatNumber;
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),

                        // Submit Button
                        GlassButton(
                          text: tr.completeProfileBtn,
                          isLoading: authState.isLoading,
                          onPressed: _submit,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
