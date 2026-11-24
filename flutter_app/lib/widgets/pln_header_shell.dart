import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_theme.dart';

/// Kerangka header biru bersama: gradien, lingkaran dekorasi, SafeArea,
/// logo aplikasi, dan (opsional) tombol kembali / profil.
/// Isi spesifik halaman diberikan lewat [child] (mis. [PlnHeaderTitle]).
///
/// Letakkan di lib/widgets/pln_header_shell.dart.
class PlnHeaderShell extends StatelessWidget {
  /// Isi di bawah baris logo aplikasi.
  final Widget child;

  /// Kalau diisi, tombol profil tampil di kanan atas.
  final VoidCallback? onProfileTap;

  /// Kalau diisi, tombol kembali tampil di kiri atas.
  final VoidCallback? onBack;

  const PlnHeaderShell({
    super.key,
    required this.child,
    this.onProfileTap,
    this.onBack,
  });

  // Tinggi logo PLN (lebar otomatis mengikuti rasio asli gambar).
  static const double _logoHeight = 30;

  Widget _tombol(IconData icon, VoidCallback onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(9),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(9),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.18),
              ),
            ),
            child: Icon(
              icon,
              color: Colors.white.withValues(alpha: 0.9),
              size: 18,
            ),
          ),
        ),
      ),
    );
  }

  // Logo PLN dengan kotak kaca tipis, tanpa border dan tanpa teks.
  Widget _logoBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.16),
            Colors.white.withValues(alpha: 0.05),
          ],
        ),
      ),
      child: Image.asset(
        'assets/images/logo-pln1.png',
        height: _logoHeight,
        fit: BoxFit.fitHeight,
        errorBuilder: (_, __, ___) => const Icon(
          Icons.bolt_rounded,
          color: Colors.white,
          size: _logoHeight,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.darkNavy],
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Hiasan lingkaran (sama dengan header Dashboard)
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
                color: AppColors.accentYellow.withValues(alpha: 0.06),
              ),
            ),
          ),
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                children: [
                  // Logo aplikasi + tombol
                  Row(
                    children: [
                      if (onBack != null) ...[
                        _tombol(Icons.arrow_back_rounded, onBack!, 'Kembali'),
                        const SizedBox(width: 10),
                      ],
                      _logoBadge(),
                      const Spacer(),
                      if (onProfileTap != null)
                        _tombol(
                            Icons.person_outline_rounded, onProfileTap!, 'Profil'),
                    ],
                  ),
                  const SizedBox(height: 14),
                  SizedBox(width: double.infinity, child: child),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Baris judul halaman untuk dipasang di [PlnHeaderShell]:
/// kotak ikon + judul + subjudul.
class PlnHeaderTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;

  const PlnHeaderTitle({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: -0.4,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}