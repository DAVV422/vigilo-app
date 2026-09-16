// lib/presentation/widgets/alerts/category_filter_row.dart
import 'package:flutter/material.dart';
import '../../../domain/enums/alert_category.dart';
import '../../../theme/app_colors.dart';

class CategoryFilterRow extends StatelessWidget {
  final AlertCategory? selectedCategory;
  final ValueChanged<AlertCategory?> onCategorySelected;

  const CategoryFilterRow({
    Key? key,
    required this.selectedCategory,
    required this.onCategorySelected,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 48,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        children: [
          // Chip "Todos"
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: const Text('Todos'),
              selected: selectedCategory == null,
              onSelected: (_) => onCategorySelected(null),
              selectedColor: AppColors.primaryContainer,
              backgroundColor: AppColors.surfaceContainerHigh,
              checkmarkColor: AppColors.onPrimaryContainer,
              showCheckmark: selectedCategory == null,
              labelStyle: TextStyle(
                color: selectedCategory == null
                    ? AppColors.onPrimaryContainer
                    : AppColors.onSurfaceVariant,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20.0),
              ),
            ),
          ),
          // Chips de Categorías
          ...AlertCategory.values.map((category) {
            final isSelected = selectedCategory == category;
            return Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: FilterChip(
                label: Text(category.displayName),
                selected: isSelected,
                onSelected: (selected) {
                  onCategorySelected(selected ? category : null);
                },
                selectedColor: AppColors.primaryContainer,
                backgroundColor: AppColors.surfaceContainerHigh,
                checkmarkColor: AppColors.onPrimaryContainer,
                showCheckmark: isSelected,
                labelStyle: TextStyle(
                  color: isSelected
                      ? AppColors.onPrimaryContainer
                      : AppColors.onSurfaceVariant,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
                side: BorderSide.none,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20.0),
                ),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}
