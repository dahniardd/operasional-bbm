import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';

class CustomBottomNav extends StatelessWidget {
  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  final int currentIndex;
  final ValueChanged<int> onTap;

  static const double _referenceWidth = 390;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context);
    final width = media.size.width;
    final scale = (width / _referenceWidth).clamp(0.85, 1.2);
    final bottomInset = media.padding.bottom;

    final navHeight = (140 * scale).clamp(130.0, 148.0);
    final fabDiameter = (110 * scale).clamp(104.0, 112.0);
    final fabBorder = (9 * scale).clamp(8.0, 10.0);
    final protrusion = (68 * scale).clamp(62.0, 70.0);
    final navIconSize = (28 * scale).clamp(24.0, 30.0);
    final fabIconSize = (34 * scale).clamp(30.0, 36.0);
    final labelSize = (width * 0.030).clamp(10.5, 13.0);
    final totalHeight = protrusion + navHeight + bottomInset;

    return SizedBox(
      height: totalHeight,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.bottomCenter,
        children: [
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: navHeight + bottomInset,
            child: const _NavBackground(),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: bottomInset,
            height: navHeight,
            child: Row(
              children: [
                Expanded(
                  child: _SideItem(
                    icon: Icons.speed_rounded,
                    label: 'Dashboard',
                    active: currentIndex == 0,
                    activeColor: AppColors.darkTeal,
                    iconSize: navIconSize,
                    labelSize: labelSize,
                    onTap: () => onTap(0),
                  ),
                ),
                Expanded(
                  child: _InputLabel(
                    active: currentIndex == 1,
                    labelSize: labelSize,
                    topOffset: (fabDiameter - protrusion) + 6,
                    onTap: () => onTap(1),
                  ),
                ),
                Expanded(
                  child: _SideItem(
                    icon: Icons.receipt_long_rounded,
                    label: 'Riwayat',
                    active: currentIndex == 2,
                    activeColor: AppColors.slateBlue,
                    iconSize: navIconSize,
                    labelSize: labelSize,
                    onTap: () => onTap(2),
                  ),
                ),
              ],
            ),
          ),
          Align(
            alignment: Alignment.topCenter,
            child: _InputButton(
              diameter: fabDiameter,
              borderWidth: fabBorder,
              iconSize: fabIconSize,
              onTap: () => onTap(1),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavBackground extends StatelessWidget {
  const _NavBackground();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Color(0x0F000000),
            blurRadius: 24,
            offset: Offset(0, -6),
          ),
        ],
      ),
    );
  }
}

class _SideItem extends StatelessWidget {
  const _SideItem({
    required this.icon,
    required this.label,
    required this.active,
    required this.activeColor,
    required this.iconSize,
    required this.labelSize,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final Color activeColor;
  final double iconSize;
  final double labelSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = activeColor.withValues(alpha: active ? 1 : 0.45);

    return Semantics(
      button: true,
      selected: active,
      label: label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<Color?>(
              tween: ColorTween(end: color),
              duration: const Duration(milliseconds: 180),
              builder: (context, value, child) {
                return Icon(icon, size: iconSize, color: value ?? color);
              },
            ),
            const SizedBox(height: 6),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                  child: Text(label, maxLines: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputLabel extends StatelessWidget {
  const _InputLabel({
    required this.active,
    required this.labelSize,
    required this.topOffset,
    required this.onTap,
  });

  final bool active;
  final double labelSize;
  final double topOffset;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.navy.withValues(alpha: active ? 1 : 0.55);

    return Semantics(
      button: true,
      selected: active,
      label: 'Input',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(top: topOffset),
          child: Align(
            alignment: Alignment.topCenter,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 180),
                  style: GoogleFonts.inter(
                    color: color,
                    fontSize: labelSize,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                  child: const Text('Input', maxLines: 1),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InputButton extends StatelessWidget {
  const _InputButton({
    required this.diameter,
    required this.borderWidth,
    required this.iconSize,
    required this.onTap,
  });

  final double diameter;
  final double borderWidth;
  final double iconSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Input',
      child: Container(
        width: diameter,
        height: diameter,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.32),
              blurRadius: 28,
              offset: const Offset(0, 12),
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.12),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Material(
          color: AppColors.primary,
          shape: CircleBorder(
            side: BorderSide(color: AppColors.white, width: borderWidth),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Center(
              child: Icon(
                Icons.local_gas_station_rounded,
                color: AppColors.white,
                size: iconSize,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
