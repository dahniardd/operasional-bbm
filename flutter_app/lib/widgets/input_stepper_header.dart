import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/pln_colors.dart';
import '../screens/main/profile_screen.dart';

TextStyle _poppins(double size, FontWeight w, Color c, {double? ls}) =>
    GoogleFonts.poppins(
      fontSize: size,
      fontWeight: w,
      color: c,
      letterSpacing: ls,
    );

/// Header halaman input (gaya sama dengan header Riwayat Pengisian).
class InputStepperHeader extends StatelessWidget {
  final String title;

  /// Teks kecil di bawah judul (opsional).
  final String? subtitle;

  final List<String> steps;
  final int currentStep;
  final VoidCallback? onBack;

  const InputStepperHeader({
    super.key,
    required this.title,
    required this.steps,
    required this.currentStep,
    this.subtitle,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PlnColors.primaryBlue, PlnColors.darkNavy],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: PlnColors.primaryBlue.withValues(alpha: 0.2),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(24),
            bottomRight: Radius.circular(24),
          ),
          child: Stack(
            children: [
              // Hiasan lingkaran
              Positioned(
                right: -24,
                top: -28,
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.05),
                  ),
                ),
              ),
              Positioned(
                left: -40,
                bottom: -60,
                child: Container(
                  width: 150,
                  height: 150,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: PlnColors.accentYellow.withValues(alpha: 0.06),
                  ),
                ),
              ),
              SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
                  child: Column(
                    children: [
                      // Satu baris: back + judul ... profil (kanan)
                      Row(
                        children: [
                          _HeaderButton(
                            icon: Icons.arrow_back_rounded,
                            tooltip: 'Kembali',
                            onTap:
                                onBack ??
                                () => Navigator.of(context).maybePop(),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: _poppins(
                                    18,
                                    FontWeight.w700,
                                    Colors.white,
                                    ls: -0.4,
                                  ),
                                ),
                                if (subtitle != null &&
                                    subtitle!.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    subtitle!,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: _poppins(
                                      11,
                                      FontWeight.w400,
                                      Colors.white.withValues(alpha: 0.7),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 10),
                          _HeaderButton(
                            icon: Icons.person_outline_rounded,
                            tooltip: 'Profil',
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (steps.isNotEmpty) ...[
                        const SizedBox(height: 20),
                        _buildStepper(),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepper() {
    return Row(
      children: List.generate(steps.length * 2 - 1, (i) {
        if (i.isOdd) {
          final stepIdx = i ~/ 2;
          final isDone = stepIdx < currentStep;
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: isDone
                  ? Container(
                      height: 2,
                      color: Colors.white.withValues(alpha: 0.9),
                    )
                  : _DashedLine(color: Colors.white.withValues(alpha: 0.35)),
            ),
          );
        }

        final stepIdx = i ~/ 2;
        final isActive = stepIdx == currentStep;
        final isCompleted = stepIdx < currentStep;

        return Column(
          children: [
            Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: isCompleted
                    ? Colors.white
                    : (isActive
                          ? PlnColors.accentYellow
                          : Colors.white.withValues(alpha: 0.12)),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? Colors.white
                      : (isActive
                            ? PlnColors.accentYellow
                            : Colors.white.withValues(alpha: 0.35)),
                  width: 1.4,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? Icon(Icons.check, size: 14, color: PlnColors.primaryBlue)
                    : Text(
                        '${stepIdx + 1}',
                        style: _poppins(
                          12,
                          FontWeight.w700,
                          isActive
                              ? PlnColors.darkNavy
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[stepIdx],
              style: _poppins(
                11,
                isActive || isCompleted ? FontWeight.w600 : FontWeight.w400,
                isActive || isCompleted
                    ? Colors.white
                    : Colors.white.withValues(alpha: 0.65),
              ),
            ),
          ],
        );
      }),
    );
  }
}

/// Tombol kotak transparan di header (dipakai untuk back dan profil).
class _HeaderButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const _HeaderButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 48,
            height: 48,
            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.9),
              size: 20,
            ),
          ),
        ),
      ),
    );
  }
}

class _DashedLine extends StatelessWidget {
  final Color color;

  const _DashedLine({required this.color});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const dashWidth = 4.0;
        const dashSpace = 4.0;
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpace))
            .floor();

        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(dashCount, (_) {
            return SizedBox(
              width: dashWidth,
              height: 1.4,
              child: DecoratedBox(decoration: BoxDecoration(color: color)),
            );
          }),
        );
      },
    );
  }
}
