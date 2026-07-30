import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_spacing.dart';
import '../../../../core/widgets/borrowly_category_chip.dart';
import '../../domain/entities/item_category.dart';
import '../providers/home_items_provider.dart';

class CategorySelector extends ConsumerWidget {
  const CategorySelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);

    return SizedBox(
      height: 44,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
        itemCount: ItemCategory.values.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.xs + 2),
        itemBuilder: (context, index) {
          final category = ItemCategory.values[index];
          final isSelected = selectedCategory == category;

          return BorrowlyCategoryChip(
            label: category.label,
            icon: category.icon,
            isSelected: isSelected,
            onTap: () {
              ref.read(selectedCategoryProvider.notifier).state = category;
            },
          );
        },
      ),
    );
  }
}
