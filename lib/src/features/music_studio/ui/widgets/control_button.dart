import 'package:flutter/material.dart';
import '../../../../core/theme/dimens.dart';

class ControlButton extends StatelessWidget {
  final IconData icon;
  final String? label;
  final bool isActive;
  final Color activeColor;
  final VoidCallback onTap;

  const ControlButton({
    super.key,
    required this.icon,
    this.label,
    required this.isActive,
    required this.activeColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = isActive ? activeColor : Theme.of(context).colorScheme.onSurface.withValues(alpha: 153);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(Dimens.radiusSmall),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? activeColor.withValues(alpha: 26) : Colors.transparent,
          borderRadius: BorderRadius.circular(Dimens.radiusSmall),
          border: Border.all(
            color: isActive
                ? activeColor.withValues(alpha: 77)
                : Theme.of(context).colorScheme.outline.withValues(alpha: 51),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            if (label != null) ...[
              const SizedBox(width: 4),
              Text(label!, style: Theme.of(context).textTheme.labelMedium),
            ]
          ],
        ),
      ),
    );
  }
}
