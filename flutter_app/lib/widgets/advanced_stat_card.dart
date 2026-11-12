import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/design_tokens.dart';

/// Kartu ringkasan dashboard.
///
/// Animasi masuk ditangani oleh halaman agar tidak ada satu
/// AnimationController per kartu.
class AdvancedStatCard extends StatelessWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final double? change;
  final bool isPositive;

  /// Apakah arah positif dianggap baik. Untuk biaya, kenaikan bukan hal baik.
  final bool positiveIsGood;

  /// Warna khusus untuk nilai, mis. amber gelap pada kartu biaya.
  final Color? valueColor;

  /// Warna indikator saat tren dianggap buruk.
  final Color badTrendColor;

  final VoidCallback? onTap;

  const AdvancedStatCard({
    super.key,
    required this.label,
    required this.value,
    this.subtitle,
    required this.icon,
    required this.primaryColor,
    required this.backgroundColor,
    this.change,
    this.isPositive = true,
    this.positiveIsGood = true,
    this.valueColor,
    this.badTrendColor = AppTokens.danger,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final resolvedValueColor = valueColor ?? primaryColor;
    final isGoodTrend = isPositive == positiveIsGood;
    final trendColor = isGoodTrend ? AppTokens.success : badTrendColor;

    final card = Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [backgroundColor, backgroundColor.withValues(alpha: 0.5)],
        ),
        borderRadius: BorderRadius.circular(AppTokens.radiusCard),
        border: Border.all(
          color: primaryColor.withValues(alpha: 0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withValues(alpha: 0.08),
            blurRadius: AppTokens.space10,
            offset: const Offset(0, AppTokens.space4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -AppTokens.space14,
            bottom: -AppTokens.space14,
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primaryColor.withValues(alpha: 0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(AppTokens.space12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            label,
                            style: GoogleFonts.poppins(
                              fontSize: AppTokens.fontCaption,
                              fontWeight: FontWeight.w500,
                              color: AppTokens.textSecondary,
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: AppTokens.space4),
                          Text(
                            value,
                            style: GoogleFonts.poppins(
                              fontSize: AppTokens.fontTitle,
                              fontWeight: FontWeight.w700,
                              color: resolvedValueColor,
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppTokens.space6),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(AppTokens.radiusMd),
                      ),
                      child: Icon(
                        icon,
                        color: primaryColor,
                        size: AppTokens.fontHeading,
                      ),
                    ),
                  ],
                ),
                if (subtitle != null || change != null) ...[
                  const SizedBox(height: AppTokens.space6),
                  Row(
                    children: [
                      if (change != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppTokens.space6,
                            vertical: AppTokens.space2,
                          ),
                          decoration: BoxDecoration(
                            color: trendColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(
                              AppTokens.space6,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isPositive
                                    ? Icons.trending_up
                                    : Icons.trending_down,
                                size: AppTokens.fontCaption,
                                color: trendColor,
                              ),
                              const SizedBox(width: AppTokens.space2),
                              Text(
                                '${change!.toStringAsFixed(1)}%',
                                style: GoogleFonts.poppins(
                                  fontSize: AppTokens.fontCaption,
                                  fontWeight: FontWeight.w600,
                                  color: trendColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (change != null && subtitle != null)
                        const SizedBox(width: AppTokens.space6),
                      if (subtitle != null)
                        Expanded(
                          child: Text(
                            subtitle!,
                            style: GoogleFonts.poppins(
                              fontSize: AppTokens.fontCaption,
                              color: AppTokens.textSecondary,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );

    final content = onTap == null
        ? card
        : Semantics(
            button: true,
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(AppTokens.radiusCard),
                child: card,
              ),
            ),
          );

    return Semantics(
      label: '$label: $value',
      child: MouseRegion(
        cursor: onTap != null
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        child: content,
      ),
    );
  }
}
