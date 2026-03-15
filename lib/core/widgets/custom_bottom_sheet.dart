import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Item de ação para o bottom sheet
class BottomSheetAction {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? iconColor;
  final Color? textColor;
  final bool visible;

  const BottomSheetAction({
    required this.icon,
    required this.label,
    required this.onTap,
    this.iconColor,
    this.textColor,
    this.visible = true,
  });
}

/// Bottom sheet customizado com lista de ações
class CustomBottomSheet extends StatelessWidget {
  final List<BottomSheetAction> actions;

  const CustomBottomSheet({
    super.key,
    required this.actions,
  });

  /// Método estático para mostrar o bottom sheet
  static void show({
    required BuildContext context,
    required List<BottomSheetAction> actions,
  }) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => CustomBottomSheet(actions: actions),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Filtra apenas as ações visíveis
    final visibleActions = actions.where((action) => action.visible).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: visibleActions.asMap().entries.map((entry) {
          final index = entry.key;
          final action = entry.value;

          return Column(
            children: [
              if (index > 0) const SizedBox(height: 8),
              InkWell(
                onTap: () {
                  Navigator.pop(context);
                  action.onTap();
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
                  child: Row(
                    children: [
                      Icon(
                        action.icon,
                        color: action.iconColor ?? AppColors.textPrimary,
                        size: 24,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        action.label,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: action.textColor ?? AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

