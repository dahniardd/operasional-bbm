import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../config/pln_colors.dart';

/// Advanced Quick Action Button dengan hover dan ripple effect
class AdvancedQuickAction extends StatefulWidget {
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
  State<AdvancedQuickAction> createState() => _AdvancedQuickActionState();
}

class _AdvancedQuickActionState extends State<AdvancedQuickAction>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.05,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPrimary = widget.isPrimary;
    final labelColor = isPrimary ? Colors.white : PlnColors.textPrimary;
    final descriptionColor = isPrimary
        ? Colors.white.withValues(alpha: 0.78)
        : PlnColors.textSecondary;
    final iconBackground = isPrimary
        ? Colors.white.withValues(alpha: 0.16)
        : widget.primaryColor.withValues(alpha: 0.12);
    final iconColor = isPrimary ? Colors.white : widget.primaryColor;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        _controller.forward();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.onTap,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isPrimary
                      ? [PlnColors.primaryBlue, PlnColors.darkNavy]
                      : [
                          widget.backgroundColor,
                          widget.backgroundColor.withValues(alpha: 0.6),
                        ],
                ),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isPrimary
                      ? Colors.white.withValues(alpha: 0.16)
                      : widget.primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.primaryColor.withValues(
                      alpha: _isHovered ? 0.18 : 0.07,
                    ),
                    blurRadius: _isHovered ? 14 : 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  // Background accent
                  Positioned(
                    right: -12,
                    top: -12,
                    child: Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: isPrimary
                            ? Colors.white.withValues(alpha: 0.06)
                            : widget.primaryColor.withValues(alpha: 0.05),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                  // Content
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        // Icon container
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(
                            color: iconBackground,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(widget.icon, color: iconColor, size: 20),
                        ),
                        const SizedBox(width: 10),
                        // Label dan description
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                widget.label,
                                style: GoogleFonts.poppins(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: labelColor,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (widget.description != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  widget.description!,
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
                        // Arrow indicator
                        if (widget.isPrimary) ...[
                          const SizedBox(width: 6),
                          Container(
                            width: 22,
                            height: 22,
                            decoration: BoxDecoration(
                              color: isPrimary
                                  ? Colors.white.withValues(alpha: 0.18)
                                  : widget.primaryColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Icon(
                              Icons.arrow_forward,
                              color: iconColor,
                              size: 13,
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
