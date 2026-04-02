import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Primary Button
// ─────────────────────────────────────────────────────────────────────────────
class AppButton extends StatelessWidget {
  final String    label;
  final VoidCallback? onPressed;
  final bool      isLoading;
  final bool      isOutlined;
  final Widget?   leading;
  final double    height;
  final Color?    backgroundColor;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading  = false,
    this.isOutlined = false,
    this.leading,
    this.height     = 52,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final child = isLoading
        ? const SizedBox(
            width: 22, height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: 8)],
              Text(label),
            ],
          );

    if (isOutlined) {
      return SizedBox(
        width: double.infinity,
        height: height,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      height: height,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: backgroundColor != null
            ? ElevatedButton.styleFrom(backgroundColor: backgroundColor)
            : null,
        child: child,
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Social / Icon Button (for Google, Apple login)
// ─────────────────────────────────────────────────────────────────────────────
class AppIconButton extends StatelessWidget {
  final String    label;
  final String    assetPath;
  final VoidCallback? onPressed;

  const AppIconButton({
    super.key,
    required this.label,
    required this.assetPath,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 52,
    child: OutlinedButton(
      onPressed: onPressed,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(assetPath, width: 22, height: 22),
          const SizedBox(width: 12),
          Text(label),
        ],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Chip Button (for filters, tags)
// ─────────────────────────────────────────────────────────────────────────────
class AppChip extends StatelessWidget {
  final String label;
  final bool   selected;
  final VoidCallback? onTap;
  final Color? color;

  const AppChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? c : AppColors.bgCard,
          borderRadius: AppRadius.chip,
          border: Border.all(color: selected ? c : AppColors.border, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: selected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
