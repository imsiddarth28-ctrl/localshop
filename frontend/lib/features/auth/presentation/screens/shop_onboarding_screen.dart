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
      debugPrint('Error picking photo: $e');
    }
  }

  void _submit() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in all required shop details.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (_verifiedColony == null) {
      setState(() {
        _colonyError = 'Please enter a valid 6-character colony join code (e.g. GRN101)';
      });
      return;
    }

    final success = await ref.read(authProvider.notifier).completeShopOnboarding(
          shopName: _shopNameController.text.trim(),
          ownerName: _ownerNameController.text.trim(),
          colonyId: _verifiedColony!.colonyId,
          category: _selectedCategory,
          address: _addressController.text.trim(),
          hours: _hoursController.text.trim(),
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
        title: Text(tr.shopOnboardingTitle),
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
                  tr.shopOnboardingTitle,
                  style: theme.textTheme.displayMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  tr.shopOnboardingSubtitle,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 24),

                // Shop Photo Upload Container
                GestureDetector(
                  onTap: _pickShopPhoto,
                  child: Container(
                    width: double.infinity,
                    height: 160,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppColors.dividerLight, width: 1.5),
                      image: _shopPhotoFile != null
                          ? DecorationImage(
                              image: FileImage(_shopPhotoFile!),
                              fit: BoxFit.cover,
                            )
                          : null,
                    ),
                    child: _shopPhotoFile == null
                        ? Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_rounded, size: 44, color: AppColors.secondary),
                              const SizedBox(height: 8),
                              Text(
                                'Tap to add Storefront Photo (${tr.optional})',
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                              ),
                            ],
                          )
                        : Align(
                            alignment: Alignment.topRight,
                            child: Container(
                              margin: const EdgeInsets.all(8),
                              padding: const EdgeInsets.all(6),
                              decoration: const BoxDecoration(
                                color: Colors.black54,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.edit, color: Colors.white, size: 20),
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Shop Name
                ElderFriendlyTextField(
                  controller: _shopNameController,
                  label: tr.shopNameLabel,
                  hint: tr.shopNameHint,
                  prefixIcon: Icons.store_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return tr.enterShopName;
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Owner Name
                ElderFriendlyTextField(
                  controller: _ownerNameController,
                  label: 'Owner Full Name',
                  hint: 'e.g. Balaji Sharma',
                  prefixIcon: Icons.person_outline_rounded,
                  textCapitalization: TextCapitalization.words,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return tr.enterFullName;
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
                            'Colony: ${_verifiedColony!.colonyName} (${_verifiedColony!.approvedShopsCount}/${_verifiedColony!.maxShops} shops)',
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
                  Text(
                    '${tr.colonyCodeHelp} (Default demo: GRN101)',
                    style: TextStyle(fontSize: 13, color: isDark ? AppColors.textMutedDark : AppColors.textMutedLight),
                  ),
                ],
                const SizedBox(height: 20),

                // Category Dropdown
                Text(
                  tr.categoryLabel,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.surfaceDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: AppColors.dividerLight, width: 1.5),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedCategory,
                      isExpanded: true,
                      icon: const Icon(Icons.arrow_drop_down, size: 30),
                      style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                      items: AppConstants.shopCategories.map((cat) {
                        return DropdownMenuItem<String>(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedCategory = val);
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Shop Address
                ElderFriendlyTextField(
                  controller: _addressController,
                  label: tr.addressLabel,
                  hint: tr.addressHint,
                  prefixIcon: Icons.location_on_outlined,
                  validator: (val) {
                    if (val == null || val.trim().isEmpty) return tr.enterShopAddress;
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Hours
                ElderFriendlyTextField(
                  controller: _hoursController,
                  label: tr.hoursLabel,
                  hint: tr.hoursHint,
                  prefixIcon: Icons.access_time_rounded,
                ),
                const SizedBox(height: 24),

                // Delivery Slots Configuration
                Text(
                  tr.deliverySlotsOffered,
                  style: theme.textTheme.titleMedium?.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: Text(tr.instantSlotDesc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: const Text('Direct delivery within 30-45 minutes'),
                  value: _instantSlot,
                  activeColor: AppColors.secondary,
                  onChanged: (val) => setState(() => _instantSlot = val ?? true),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                CheckboxListTile(
                  title: Text(tr.morningSlotDesc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: const Text('Batch delivery route at 7:00 AM (Order before 10 PM)'),
                  value: _morningSlot,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _morningSlot = val ?? true),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                CheckboxListTile(
                  title: Text(tr.eveningSlotDesc, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                  subtitle: const Text('Batch delivery route at 6:00 PM (Order before 4 PM)'),
                  value: _eveningSlot,
                  activeColor: AppColors.primary,
                  onChanged: (val) => setState(() => _eveningSlot = val ?? true),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                const SizedBox(height: 32),

                // Submit Button
                ElderFriendlyButton(
                  text: tr.submitForApprovalBtn,
                  isLoading: authState.isLoading,
                  isSecondary: true,
                  onPressed: _submit,
                ),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
