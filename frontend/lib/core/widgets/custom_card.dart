import 'dart:ui';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class CustomCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final Gradient? gradient;
  final bool isGlassmorphic;
  final Border? border;
  final double borderRadius;
  final List<BoxShadow>? customShadow;

  const CustomCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.onTap,
    this.backgroundColor,
    this.gradient,
    this.isGlassmorphic = false,
    this.border,
    this.borderRadius = 20,
    this.customShadow,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBorder = border ??
        (isGlassmorphic
            ? Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.2)
            : Border.all(color: AppColors.borderLight, width: 1.0));

    final effectiveShadow = customShadow ??
        (isGlassmorphic ? [] : AppColors.softShadow);

    Widget content = Container(
      margin: margin,
      decoration: BoxDecoration(
        color: isGlassmorphic
            ? Colors.white.withValues(alpha: 0.65)
            : (backgroundColor ?? Colors.white),
        gradient: gradient,
        borderRadius: BorderRadius.circular(borderRadius),
        border: effectiveBorder,
        boxShadow: effectiveShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: isGlassmorphic
            ? BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(18),
                  child: child,
                ),
              )
            : Padding(
                padding: padding ?? const EdgeInsets.all(18),
                child: child,
              ),
      ),
    );

    if (onTap != null) {
      return Container(
        margin: margin,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          boxShadow: effectiveShadow,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(borderRadius),
            onTap: onTap,
            splashColor: AppColors.primary.withValues(alpha: 0.08),
            highlightColor: AppColors.primary.withValues(alpha: 0.04),
            child: Ink(
              decoration: BoxDecoration(
                color: isGlassmorphic
                    ? Colors.white.withValues(alpha: 0.65)
                    : (backgroundColor ?? Colors.white),
                gradient: gradient,
                borderRadius: BorderRadius.circular(borderRadius),
                border: effectiveBorder,
              ),
              child: isGlassmorphic
                  ? BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                      child: Padding(
                        padding: padding ?? const EdgeInsets.all(18),
                        child: child,
                      ),
                    )
                  : Padding(
                      padding: padding ?? const EdgeInsets.all(18),
                      child: child,
                    ),
            ),
          ),
        ),
      );
    }

    return content;
  }
}
