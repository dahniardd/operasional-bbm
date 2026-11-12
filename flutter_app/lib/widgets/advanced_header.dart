import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../config/design_tokens.dart';
import '../models/user.dart';

/// Header utama dashboard: identitas aplikasi dan info driver dalam satu
/// komponen biru. Avatar driver dapat diketuk untuk membuka profil.
class AdvancedHeader extends StatelessWidget {
  final User? user;

  /// Dipanggil saat avatar profil di pojok kanan diketuk.
  final VoidCallback? onProfileTap;

  const AdvancedHeader({super.key, this.user, this.onProfileTap});

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

    return Semantics(
      header: true,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppTokens.brandGradient,
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(AppTokens.radiusXl),
            bottomRight: Radius.circular(AppTokens.radiusXl),
          ),
          boxShadow: [
            BoxShadow(
              color: AppTokens.brand.withValues(alpha: 0.2),
              blurRadius: AppTokens.space16,
              offset: const Offset(0, AppTokens.space8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -AppTokens.space24,
              top: -28,
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTokens.onBrandFaint,
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
                  color: AppTokens.accent.withValues(alpha: 0.06),
                ),
              ),
            ),
            SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppTokens.space16,
                  AppTokens.space10,
                  AppTokens.space16,
                  AppTokens.space20,
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          padding: const EdgeInsets.all(AppTokens.space4),
                          decoration: BoxDecoration(
                            color: AppTokens.onBrandAccent,
                            borderRadius: BorderRadius.circular(
                              AppTokens.radiusMd,
                            ),
                            border: Border.all(color: AppTokens.onBrandBorder),
                          ),
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.contain,
                            errorBuilder: (_, _, _) => const Icon(
                              Icons.bolt_rounded,
                              color: AppTokens.onBrand,
                              size: 20,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppTokens.space10),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PLN NP',
                              style: GoogleFonts.poppins(
                                fontSize: AppTokens.fontCaption,
                                fontWeight: FontWeight.w600,
                                height: 1.1,
                                color: AppTokens.onBrandMuted,
                              ),
                            ),
                            Text(
                              'e-Operasional',
                              style: GoogleFonts.poppins(
                                fontSize: AppTokens.fontBody,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                                color: AppTokens.onBrand,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: AppTokens.space14),
                    Row(
                      children: [
                        _buildProfileAvatar(),
                        const SizedBox(width: AppTokens.space12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    icon,
                                    color: AppTokens.accent,
                                    size: AppTokens.fontBody,
                                  ),
                                  const SizedBox(width: AppTokens.space4),
                                  Expanded(
                                    child: Text(
                                      greeting,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.poppins(
                                        fontSize: AppTokens.fontCaption,
                                        fontWeight: FontWeight.w500,
                                        color: AppTokens.onBrandMuted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppTokens.space2),
                              Text(
                                user?.username ?? 'Pengguna',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: AppTokens.fontHeading,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.onBrand,
                                  letterSpacing: -0.4,
                                ),
                              ),
                              const SizedBox(height: AppTokens.space2),
                              Text(
                                DateFormat(
                                  'EEEE, d MMMM yyyy',
                                  'id_ID',
                                ).format(now),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.poppins(
                                  fontSize: AppTokens.fontCaption,
                                  fontWeight: FontWeight.w400,
                                  color: AppTokens.onBrandMuted,
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
      ),
    );
  }

  Widget _buildProfileAvatar() {
    final photoUrl = user?.photoUrl;
    final avatar = Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onProfileTap,
        customBorder: const CircleBorder(),
        child: Ink(
          width: AppTokens.minTapTarget,
          height: AppTokens.minTapTarget,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [AppTokens.onBrandSoft, AppTokens.onBrandAccent],
            ),
            border: Border.all(color: AppTokens.onBrandBorder, width: 1.5),
          ),
          child: photoUrl != null
              ? ClipOval(
                  child: Image.network(
                    photoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => const Icon(
                      Icons.person,
                      color: AppTokens.onBrandMuted,
                      size: 24,
                    ),
                  ),
                )
              : const Icon(
                  Icons.person,
                  color: AppTokens.onBrandMuted,
                  size: 24,
                ),
        ),
      ),
    );

    return Semantics(
      button: true,
      label: 'Buka profil',
      child: Tooltip(message: 'Profil', child: avatar),
    );
  }
}
