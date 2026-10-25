import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../l10n/app_locale.dart';
import '../theme/app_colors.dart';

class LanguageSelector extends ConsumerWidget {
  final bool compact;

  const LanguageSelector({super.key, this.compact = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentLocale = ref.watch(localeProvider);
    final isTelugu = currentLocale.languageCode == 'te';
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.cardLight,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primaryLight.withOpacity(0.4), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildPill(
            label: 'English',
            isSelected: !isTelugu,
            onTap: () => ref.read(localeProvider.notifier).setLocale('en'),
          ),
          const SizedBox(width: 4),
          _buildPill(
            label: 'తెలుగు',
            isSelected: isTelugu,
            onTap: () => ref.read(localeProvider.notifier).setLocale('te'),
          ),
        ],
      ),
    );
  }

  Widget _buildPill({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textPrimaryLight,
          ),
        ),
      ),
    );
  }
}
