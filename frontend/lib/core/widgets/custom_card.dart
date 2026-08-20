import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool isGlassmorphic;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.isGlassmorphic = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isGlassmorphic
            ? Colors.white.withOpacity(0.7)
            : (backgroundColor ?? Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: isGlassmorphic
            ? Border.all(color: Colors.white.withOpacity(0.5), width: 1.5)
            : null,
      ),
      child: child,
    );

    Widget card = Card(
      elevation: isGlassmorphic ? 0 : 8,
      shadowColor: isGlassmorphic ? Colors.transparent : Colors.black.withOpacity(0.05),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: cardContent,
      ),
    );

    if (onTap != null) {
      return Stack(
        children: [
          card,
          Positioned.fill(
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(24),
                onTap: onTap,
                splashColor: AppColors.primary.withOpacity(0.1),
                highlightColor: AppColors.primary.withOpacity(0.05),
              ),
            ),
          ),
        ],
      );
    }

    return card;
  }
}
