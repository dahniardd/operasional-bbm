import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/pln_colors.dart';
import '../models/user.dart';

/// Header utama dashboard: identitas aplikasi, aksi, dan info driver
/// dalam satu komponen biru.
class AdvancedHeader extends StatelessWidget {
  final User? user;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNotificationTap;

  const AdvancedHeader({
    super.key,
    this.user,
    this.onSettingsTap,
    this.onNotificationTap,
  });

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Selamat Pagi';
    if (hour < 15) return 'Selamat Siang';
    if (hour < 18) return 'Selamat Sore';
    return 'Selamat Malam';
  }

  IconData _getGreetingIcon() {
    final hour = DateTime.now().hour;
    if (hour < 12) return Icons.wb_sunny_outlined;
    if (hour < 15) return Icons.wb_sunny;
    if (hour < 18) return Icons.wb_twilight;
    return Icons.nights_stay_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final greeting = _getGreeting();
    final icon = _getGreetingIcon();
    final now = DateTime.now();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [PlnColors.primaryBlue, PlnColors.darkNavy],
          stops: const [0.0, 1.0],
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
      child: Stack(
        children: [
          // Background pattern
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
          // Content
          SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 18),
              child: Column(
                children: [
                  // Identitas aplikasi + aksi
                  Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.14),
                          borderRadius: BorderRadius.circular(9),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                          ),
                        ),
                        child: Image.asset(
                          'assets/images/logo.png',
                          fit: BoxFit.contain,
                          errorBuilder: (_, _, _) => const Icon(
                            Icons.bolt_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PLN NP',
                            style: GoogleFonts.poppins(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              height: 1.1,
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          Text(
                            'e-Operasional',
                            style: GoogleFonts.poppins(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              height: 1.1,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      _buildIconButton(
                        Icons.notifications_outlined,
                        onNotificationTap,
                        showDot: true,
                      ),
                      const SizedBox(width: 8),
                      _buildIconButton(Icons.settings_outlined, onSettingsTap),
                    ],
                  ),
                  const SizedBox(height: 14),
                  // Info driver
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withValues(alpha: 0.3),
                              Colors.white.withValues(alpha: 0.1),
                            ],
                          ),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: user?.photoUrl != null
                            ? ClipOval(
                                child: Image.network(
                                  user!.photoUrl!,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, _, _) => Icon(
                                    Icons.person,
                                    color: Colors.white.withValues(alpha: 0.7),
                                    size: 24,
                                  ),
                                ),
                              )
                            : Icon(
                                Icons.person,
                                color: Colors.white.withValues(alpha: 0.7),
                                size: 24,
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(
                                  icon,
                                  color: PlnColors.accentYellow,
                                  size: 13,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  greeting,
                                  style: GoogleFonts.poppins(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.white.withValues(alpha: 0.85),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              user?.username ?? 'Pengguna',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.4,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              DateFormat(
                                'EEEE, d MMMM yyyy',
                                'id_ID',
                              ).format(now),
                              style: GoogleFonts.poppins(
                                fontSize: 11,
                                fontWeight: FontWeight.w400,
                                color: Colors.white.withValues(alpha: 0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIconButton(
    IconData icon,
    VoidCallback? onTap, {
    bool showDot = false,
  }) {
    return Material(
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
              width: 1,
            ),
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Center(
                child: Icon(
                  icon,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 18,
                ),
              ),
              if (showDot)
                Positioned(
                  right: 7,
                  top: 7,
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: PlnColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
