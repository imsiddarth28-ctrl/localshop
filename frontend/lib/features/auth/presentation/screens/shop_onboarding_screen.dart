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

class ShopOnboardingScreen extends ConsumerStatefulWidget {
  const ShopOnboardingScreen({super.key});

  @override
  ConsumerState<ShopOnboardingScreen> createState() => _ShopOnboardingScreenState();
}

class _ShopOnboardingScreenState extends ConsumerState<ShopOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _shopNameController = TextEditingController();
  final _ownerNameController = TextEditingController();
  final _joinCodeController = TextEditingController();
  final _addressController = TextEditingController();
  final _hoursController = TextEditingController(text: '7:00 AM - 9:30 PM');

  String _selectedCategory = AppConstants.shopCategories.first;
  bool _instantSlot = true;
  bool _morningSlot = true;
  bool _eveningSlot = true;

  File? _shopPhotoFile;
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
    _shopNameController.dispose();
    _ownerNameController.dispose();
    _joinCodeController.dispose();
    _addressController.dispose();
    _hoursController.dispose();
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
            _colonyError = 'Invalid join code. Get the 6-character code from your colony admin.';
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

  Future<void> _pickShopPhoto() async {
    try {
      final picker = ImagePicker();
      final picked = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1200,
        maxHeight: 900,
        imageQuality: 85,
      );
      if (picked != null) {
        setState(() {
          _shopPhotoFile = File(picked.path);
        });
      }
    } catch (e) {
      debugPrint('Error picking shop photo: $e');
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      GlassSnackbar.showError(context, 'Please fill in all required shop details.');
      return;
    }

    if (_verifiedColony == null) {
      setState(() {
        _colonyError = 'Please enter a valid 6-character colony join code (e.g. GRN101)';
      });
      GlassSnackbar.showError(context, 'Please verify your colony join code first.');
      return;
    }

    final sanitizedShopName = AppValidators.sanitizeText(_shopNameController.text);
    final sanitizedOwnerName = AppValidators.sanitizeText(_ownerNameController.text);
    final sanitizedAddress = AppValidators.sanitizeText(_addressController.text);
    final sanitizedHours = AppValidators.sanitizeText(_hoursController.text);

    final success = await ref.read(authProvider.notifier).completeShopOnboarding(
          shopName: sanitizedShopName,
          ownerName: sanitizedOwnerName,
          colonyId: _verifiedColony!.colonyId,
          category: _selectedCategory,
          address: sanitizedAddress,
          hours: sanitizedHours,
          slots: {
            'instant': _instantSlot,
            'morning': _morningSlot,
            'evening': _eveningSlot,
          },
          photoUrl: _shopPhotoFile?.path,
        );

    if (success && mounted) {
      context.go('/pending-approval');
    } else if (mounted) {
      final error = ref.read(authProvider).errorMessage ?? 'Failed to submit shop details. Please try again.';
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
          tr.shopOnboardingTitle,
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
            constraints: const BoxConstraints(maxWidth: 540),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    tr.shopOnboardingTitle,
                    style: AppTokens.headingMedium(isDark),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tr.shopOnboardingSubtitle,
                    style: AppTokens.bodyMedium(isDark),
                  ),
                  const SizedBox(height: 20),

                  // Storefront Photo Glass Box
                  GestureDetector(
                    onTap: _pickShopPhoto,
                    child: GlassCard(
                      padding: EdgeInsets.zero,
                      height: 140,
                      child: _shopPhotoFile != null
                          ? Image.file(_shopPhotoFile!, fit: BoxFit.cover, width: double.infinity)
                          : Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_a_photo_rounded, size: 38, color: isDark ? AppTokens.accentDark : AppTokens.accentLight),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload Storefront Photo (Optional)',
                                  style: AppTokens.bodySmall(isDark).copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Shop Details Glass Card
                  GlassCard(
                    padding: const EdgeInsets.all(AppTokens.space24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GlassTextField(
                          controller: _shopNameController,
                          label: tr.shopNameLabel,
                          hint: tr.shopNameHint,
                          prefixIcon: Icons.store_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return tr.enterShopName;
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        GlassTextField(
                          controller: _ownerNameController,
                          label: tr.fullNameLabel,
                          hint: tr.fullNameHint,
                          prefixIcon: Icons.person_outline_rounded,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return tr.enterFullName;
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        // Join Code with live check
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
                            if (val == null || val.trim().length != 6) return tr.enterColonyCode;
                            return null;
                          },
                        ),

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
                                Icon(Icons.verified_rounded, size: 18, color: isDark ? AppTokens.primaryDark : AppTokens.primaryLight),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Verified: ${_verifiedColony!.colonyName} (${_verifiedColony!.approvedShopsCount}/${_verifiedColony!.maxShops} registered)',
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
                        ],
                        const SizedBox(height: 18),

                        // Category Dropdown
                        Text('Shop Category', style: AppTokens.label(isDark).copyWith(fontSize: 13)),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(AppTokens.radiusField),
                            color: isDark ? AppTokens.glassFillDark : AppTokens.glassFillLight,
                            border: Border.all(
                              color: isDark ? AppTokens.glassBorderDark : AppTokens.glassBorderLight,
                            ),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: _selectedCategory,
                              isExpanded: true,
                              dropdownColor: isDark ? AppTokens.bgDarkEnd : Colors.white,
                              style: AppTokens.bodyLarge(isDark).copyWith(fontSize: 15),
                              items: AppConstants.shopCategories.map((cat) {
                                return DropdownMenuItem(value: cat, child: Text(cat));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => _selectedCategory = val);
                              },
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),

                        GlassTextField(
                          controller: _addressController,
                          label: tr.addressLabel,
                          hint: tr.addressHint,
                          prefixIcon: Icons.place_outlined,
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return tr.enterShopAddress;
                            return null;
                          },
                        ),
                        const SizedBox(height: 18),

                        GlassTextField(
                          controller: _hoursController,
                          label: tr.hoursLabel,
                          hint: 'e.g. 7:00 AM - 9:30 PM',
                          prefixIcon: Icons.access_time_rounded,
                        ),
                        const SizedBox(height: 22),

                        // Delivery Slots Config
                        Text(tr.deliverySlotsOffered, style: AppTokens.label(isDark).copyWith(fontSize: 14)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            GlassChip(
                              label: 'Instant Delivery (+₹10)',
                              subtitle: 'Within 30 mins',
                              icon: Icons.bolt_rounded,
                              isSelected: _instantSlot,
                              onTap: () => setState(() => _instantSlot = !_instantSlot),
                            ),
                            GlassChip(
                              label: 'Morning Slot (+₹5)',
                              subtitle: '7:00 AM - 9:00 AM',
                              icon: Icons.wb_sunny_outlined,
                              isSelected: _morningSlot,
                              onTap: () => setState(() => _morningSlot = !_morningSlot),
                            ),
                            GlassChip(
                              label: 'Evening Slot (+₹5)',
                              subtitle: '6:00 PM - 8:00 PM',
                              icon: Icons.nights_stay_outlined,
                              isSelected: _eveningSlot,
                              onTap: () => setState(() => _eveningSlot = !_eveningSlot),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        GlassButton(
                          text: tr.submitForApprovalBtn,
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
