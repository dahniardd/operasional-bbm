import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../config/theme.dart';

class InputStepperHeader extends StatelessWidget {
  final String title;
  final List<String> steps;
  final int currentStep;
  final VoidCallback? onBack;

  const InputStepperHeader({
    super.key,
    required this.title,
    required this.steps,
    required this.currentStep,
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(
        16,
        MediaQuery.of(context).padding.top + 12,
        16,
        16,
      ),
      child: Column(
        children: [
          Row(
            children: [
              _BackButton(
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              ),
              const SizedBox(width: 8),
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(5),
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        Icons.bolt_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: AppColors.navy,
                ),
              ),
              const Spacer(),
            ],
          ),
          const SizedBox(height: 20),
          _buildStepper(),
        ],
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
                  ? Container(height: 2, color: AppColors.primary)
                  : _DashedLine(
                      color: AppColors.slateBlue.withValues(alpha: 0.3),
                    ),
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
                    ? AppColors.darkTeal
                    : (isActive ? AppColors.navy : Colors.white),
                shape: BoxShape.circle,
                border: Border.all(
                  color: isCompleted
                      ? AppColors.darkTeal
                      : (isActive
                          ? AppColors.navy
                          : AppColors.slateBlue.withValues(alpha: 0.35)),
                  width: 1.4,
                ),
              ),
              child: Center(
                child: isCompleted
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : Text(
                        '${stepIdx + 1}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isActive
                              ? Colors.white
                              : AppColors.slateBlue.withValues(alpha: 0.7),
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              steps[stepIdx],
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight:
                    isActive || isCompleted ? FontWeight.w700 : FontWeight.w400,
                color: isActive || isCompleted
                    ? AppColors.navy
                    : AppColors.slateBlue.withValues(alpha: 0.7),
              ),
            ),
          ],
        );
      }),
    );
  }
}

class _BackButton extends StatelessWidget {
  final VoidCallback onTap;

  const _BackButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.navy.withValues(alpha: 0.06),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: const SizedBox(
          width: 34,
          height: 34,
          child: Icon(
            Icons.arrow_back_rounded,
            color: AppColors.navy,
            size: 18,
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
        final dashCount =
            (constraints.maxWidth / (dashWidth + dashSpace)).floor();

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
