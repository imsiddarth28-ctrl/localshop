import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/elder_friendly_button.dart';
import '../../../../core/widgets/elder_friendly_text_field.dart';
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
            _colonyError = 'Invalid join code. Please get the 6-character code from your colony admin.';
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your full name and flat number.'),
          backgroundColor: AppColors.error,
        ),
      );
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

    if (_verifiedColony == null) {
      setState(() {
        _colonyError = 'Please enter a valid 6-character colony join code (e.g. GRN101)';
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please verify your colony code (e.g. GRN101) before continuing.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).completeCustomerOnboarding(
          name: _nameController.text.trim(),
          colonyId: _verifiedColony!.colonyId,
          flatNumber: _flatController.text.trim(),
          avatarUrl: _avatarImageFile?.path,
        );

    if (success && mounted) {
      context.go('/home');
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage ?? 'Failed to complete profile. Please try again.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error),
          backgroundColor: AppColors.error,
        ),
      );
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
        title: Text(tr.customerOnboardingTitle),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tr.customerOnboardingTitle,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr.customerOnboardingSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Avatar Picker (Optional)
                Center(
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: AppColors.primaryContainer,
                        backgroundImage: _avatarImageFile != null ? FileImage(_avatarImageFile!) : null,
                        child: _avatarImageFile == null
                            ? const Icon(Icons.person, size: 54, color: AppColors.primary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: InkWell(
                          onTap: _pickAvatar,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.secondary,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.camera_alt, color: Colors.white, size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Center(
                  child: Text(
                    '${tr.addPhoto} (${tr.optional})',
                    style: TextStyle(
                      fontSize: 14,
                      color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Full Name
                ElderFriendlyTextField(
                  controller: _nameController,
                  label: tr.fullNameLabel,
                  hint: tr.fullNameHint,
                  prefixIcon: Icons.badge_outlined,
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return tr.enterFullName;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Colony Join Code
                ElderFriendlyTextField(
                  controller: _joinCodeController,
                  label: tr.colonyCodeLabel,
                  hint: tr.colonyCodeHint,
                  prefixIcon: Icons.apartment_rounded,
                  textCapitalization: TextCapitalization.characters,
                  onChanged: _onJoinCodeChanged,
                  suffixIcon: _isValidatingCode
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : (_verifiedColony != null
                          ? const Icon(Icons.check_circle, color: AppColors.success, size: 28)
                          : null),
                ),
                const SizedBox(height: 6),

                // Verified Colony Banner or Helper
                if (_verifiedColony != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.primaryLight),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified, color: AppColors.primary, size: 22),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Colony: ${_verifiedColony!.colonyName} (${_verifiedColony!.approvedShopsCount} shops available)',
                            style: const TextStyle(
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else if (_colonyError != null) ...[
                  Text(
                    _colonyError!,
                    style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ] else ...[
                  Row(
                    children: [
                      const Icon(Icons.info_outline, size: 16, color: AppColors.textMutedLight),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          '${tr.colonyCodeHelp} (Default demo: GRN101)',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 20),

                // Block / Flat Number
                ElderFriendlyTextField(
                  controller: _flatController,
                  label: tr.flatLabel,
                  hint: tr.flatHint,
                  prefixIcon: Icons.home_rounded,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) {
                      return tr.enterFlatNumber;
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElderFriendlyButton(
                  text: tr.completeProfileBtn,
                  isLoading: authState.isLoading,
                  onPressed: _submit,
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
