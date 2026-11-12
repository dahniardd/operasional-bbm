import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _barHeight = 88;
  static const double _protrusion = 30; // tinggi tombol di atas bar
  static const double _buttonSize = 72;
  static const double _notchGap = 8; // jarak lekukan ke tombol

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).padding.bottom;
    final notchRadius = _buttonSize / 2 + _notchGap;
    final barColor = Color.alphaBlend(
      AppColors.primary.withValues(alpha: 0.05),
      AppColors.white,
    );

    return SizedBox(
      height: _protrusion + _barHeight + bottomInset,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Bar dengan lekukan di tengah
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: _barHeight + bottomInset,
            child: CustomPaint(
              painter: _BarPainter(
                color: barColor,
                shadowColor: AppColors.primary.withValues(alpha: 0.18),
                notchRadius: notchRadius,
                // pusat tombol sedikit di bawah tepi atas bar
                notchCenterY: _buttonSize / 2 - _protrusion,
              ),
              child: Padding(
                padding: EdgeInsets.fromLTRB(14, 14, 14, 14 + bottomInset),
                child: Row(
                  children: [
                    Expanded(
                      child: _NavPill(
                        icon: Icons.speed_rounded,
                        label: 'Dashboard',
                        active: currentIndex == 0,
                        onTap: () => onTap(0),
                      ),
                    ),
                    SizedBox(width: notchRadius * 2 + 8),
                    Expanded(
                      child: _NavPill(
                        icon: Icons.receipt_long_rounded,
                        label: 'Riwayat',
                        active: currentIndex == 2,
                        onTap: () => onTap(2),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Tombol tengah
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: Center(
              child: _CenterButton(
                size: _buttonSize,
                active: currentIndex == 1,
                onTap: () => onTap(1),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BarPainter extends CustomPainter {
  _BarPainter({
    required this.color,
    required this.shadowColor,
    required this.notchRadius,
    required this.notchCenterY,
  });

  final Color color;
  final Color shadowColor;
  final double notchRadius;
  final double notchCenterY;

  @override
  void paint(Canvas canvas, Size size) {
    final bar = Path()
      ..addRRect(
        RRect.fromRectAndCorners(
          Offset.zero & size,
          topLeft: const Radius.circular(32),
          topRight: const Radius.circular(32),
        ),
      );

    final notch = Path()
      ..addOval(
        Rect.fromCircle(
          center: Offset(size.width / 2, notchCenterY),
          radius: notchRadius,
        ),
      );

    final path = Path.combine(PathOperation.difference, bar, notch);

    // bayangan ke arah atas
    canvas.drawPath(
      path.shift(const Offset(0, -4)),
      Paint()
        ..color = shadowColor
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16),
    );

    canvas.drawPath(path, Paint()..color = color);

    // garis tepi putih tipis
    canvas.drawPath(
      path,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..color = Colors.white.withValues(alpha: 0.9),
    );
  }

  @override
  bool shouldRepaint(covariant _BarPainter old) =>
      old.color != color ||
      old.shadowColor != shadowColor ||
      old.notchRadius != notchRadius ||
      old.notchCenterY != notchCenterY;
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppColors.primary : AppColors.textSecondary;

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            color: active
                ? Color.alphaBlend(
                    AppColors.primary.withValues(alpha: 0.08),
                    AppColors.white,
                  )
                : AppColors.white,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(
              color: active
                  ? AppColors.primary.withValues(alpha: 0.15)
                  : Colors.transparent,
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              TweenAnimationBuilder<Color?>(
                tween: ColorTween(end: color),
                duration: const Duration(milliseconds: 180),
                builder: (context, value, _) =>
                    Icon(icon, size: 24, color: value ?? color),
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: GoogleFonts.poppins(
                    color: color,
                    fontSize: 11.5,
                    fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                    height: 1.1,
                  ),
                  child: Text(label, maxLines: 1),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CenterButton extends StatelessWidget {
  const _CenterButton({
    required this.size,
    required this.active,
    required this.onTap,
  });

  final double size;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: active,
      label: 'Input',
      child: AnimatedScale(
        scale: active ? 1.06 : 1.0,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutBack,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.40),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Material(
            color: AppColors.primary,
            shape: CircleBorder(
              side: BorderSide(
                color: AppColors.white.withValues(alpha: 0.95),
                width: 5,
              ),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              customBorder: const CircleBorder(),
              child: const Center(
                child: Icon(
                  Icons.local_gas_station_rounded,
                  color: AppColors.white,
                  size: 32,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}