import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/pln_colors.dart';

/// Advanced Stat Card dengan animasi dan glassmorphism effect
class AdvancedStatCard extends StatefulWidget {
  final String label;
  final String value;
  final String? subtitle;
  final IconData icon;
  final Color primaryColor;
  final Color backgroundColor;
  final double? change;
  final bool isPositive;
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
    this.onTap,
  });

  @override
  State<AdvancedStatCard> createState() => _AdvancedStatCardState();
}

class _AdvancedStatCardState extends State<AdvancedStatCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );

    _opacityAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnimation,
      child: FadeTransition(
        opacity: _opacityAnimation,
        child: GestureDetector(
          onTap: widget.onTap,
          child: MouseRegion(
            cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    widget.backgroundColor,
                    widget.backgroundColor.withValues(alpha: 0.5),
                  ],
                ),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: widget.primaryColor.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(alpha: 0.1),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background decoration
                  Positioned(
                    right: -20,
                    bottom: -20,
                    child: Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: widget.primaryColor.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Header dengan icon dan label
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.label,
                                    style: GoogleFonts.poppins(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: PlnColors.textSecondary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    widget.value,
                                    style: GoogleFonts.poppins(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w700,
                                      color: widget.primaryColor,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: widget.primaryColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(
                                widget.icon,
                                color: widget.primaryColor,
                                size: 24,
                              ),
                            ),
                          ],
                        ),
                        // Footer dengan subtitle atau change indicator
                        if (widget.subtitle != null || widget.change != null)
                          Row(
                            children: [
                              if (widget.change != null) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: widget.isPositive
                                        ? PlnColors.success.withValues(alpha: 0.1)
                                        : PlnColors.danger.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        widget.isPositive
                                            ? Icons.trending_up
                                            : Icons.trending_down,
                                        size: 14,
                                        color: widget.isPositive
                                            ? PlnColors.success
                                            : PlnColors.danger,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${widget.change!.toStringAsFixed(1)}%',
                                        style: GoogleFonts.poppins(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w600,
                                          color: widget.isPositive
                                              ? PlnColors.success
                                              : PlnColors.danger,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              if (widget.subtitle != null) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    widget.subtitle!,
                                    style: GoogleFonts.poppins(
                                      fontSize: 11,
                                      color: PlnColors.textSecondary,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ],
                          ),
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
