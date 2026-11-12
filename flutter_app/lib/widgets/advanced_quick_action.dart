import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/design_tokens.dart';

/// Tombol aksi cepat dashboard tanpa AnimationController per kartu.
class AdvancedQuickAction extends StatelessWidget {
  final String label;
  final String? description;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final VoidCallback onTap;
  final bool isPrimary;

  const AdvancedQuickAction({
    super.key,
    required this.label,
    this.description,
    required this.icon,
    required this.primaryColor,
    required this.backgroundColor,
    required this.onTap,
    this.isPrimary = false,
  });

  @override
  Widget build(BuildContext context) {
    final labelColor = isPrimary ? AppTokens.onBrand : AppTokens.textPrimary;
    final descriptionColor = isPrimary
        ? AppTokens.onBrandMuted
        : AppTokens.textSecondary;
    final iconBackground = isPrimary
        ? AppTokens.onBrandAccent
        : primaryColor.withValues(alpha: 0.12);
    final iconColor = isPrimary ? AppTokens.onBrand : primaryColor;

    return Semantics(
      button: true,
      label: description == null ? label : '$label, $description',
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTokens.radiusCard),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isPrimary
                      ? AppTokens.brandGradient.colors
                      : [
                          backgroundColor,
                          backgroundColor.withValues(alpha: 0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                border: Border.all(
                  color: isPrimary
                      ? AppTokens.onBrandBorder
                      : primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: primaryColor.withValues(alpha: 0.07),
                    blurRadius: AppTokens.space10,
                    offset: const Offset(0, AppTokens.space4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  Positioned(
                    right: -AppTokens.space12,
                    top: -AppTokens.space12,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? AppTokens.onBrandOverlay
                            : primaryColor.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(AppTokens.space12),
                    child: Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: iconBackground,
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusMd,
                            ),
                          ),
                          child: Icon(icon, color: iconColor, size: 18),
                        ),
                        const SizedBox(width: AppTokens.space8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                label,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: labelColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  description!,
                                  style: GoogleFonts.poppins(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w400,
                                    color: descriptionColor,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ],
                          ),
                        ),
                        if (isPrimary) ...[
                          const SizedBox(width: AppTokens.space4),
                          Container(
                            width: AppTokens.space20,
                            height: AppTokens.space20,
                            decoration: BoxDecoration(
                              color: AppTokens.onBrandAccent,
                              borderRadius: BorderRadius.circular(
                                4,
                              ),
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: iconColor,
                              size: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
