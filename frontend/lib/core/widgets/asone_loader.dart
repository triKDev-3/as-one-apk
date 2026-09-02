import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Indicateur de chargement avec logo AS ONE.
class AsOneLoader extends StatelessWidget {
  final String? message;
  final double size;

  const AsOneLoader({
    super.key,
    this.message,
    this.size = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  width: size,
                  height: size,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.5,
                    color: AppColors.primary.withValues(alpha: 0.35),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.all(size * 0.18),
                  child: Image.asset(
                    'assets/images/logo_full.png',
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => Icon(
                      Icons.business_rounded,
                      size: size * 0.4,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 16),
            Text(
              message!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
