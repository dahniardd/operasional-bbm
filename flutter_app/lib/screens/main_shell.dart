import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../config/app_colors.dart';
import '../widgets/custom_bottom_nav.dart';
import 'main/dashboard_page_advanced.dart' show DashboardPageAdvanced;
import 'main/history_page.dart';
import 'main/profile_screen.dart';
import 'main/input_page.dart';
import 'input_bbm/input_step1_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _tabDashboard = 0;
  static const int _tabHistory = 2;

  int _currentIndex = _tabDashboard;

  /// Naik setiap kali Riwayat perlu dimuat ulang (buka tab, atau selesai input).
  int _historyTick = 0;

  void _openHistory() {
    setState(() {
      _currentIndex = _tabHistory;
      _historyTick++;
    });
  }

  Future<void> _openInput() async {
    await Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const InputStep1Screen()),
    );
    // Setelah kembali dari form input, data baru harus muncul di Riwayat.
    if (mounted) setState(() => _historyTick++);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        toolbarHeight: 76,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background,
        surfaceTintColor: Colors.transparent,
        systemOverlayStyle: SystemUiOverlayStyle.dark,
        titleSpacing: 20,
        title: Row(
          children: [
            // Logo PLN
            SizedBox(
              width: 48,
              height: 48,
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  decoration: BoxDecoration(
                    color: AppColors.darkTeal,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.bolt_rounded,
                    color: AppColors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'PLN NP',
                  style: GoogleFonts.inter(
                    color: AppColors.darkTeal,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 1.15,
                  ),
                ),
                Text(
                  'e-Operasional',
                  style: GoogleFonts.inter(
                    color: AppColors.navy,
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    height: 1.15,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Lonceng notifikasi
          IconButton(
            tooltip: 'Notifikasi',
            onPressed: () {
              // TODO: buka halaman notifikasi
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(
                  Icons.notifications_none_rounded,
                  color: AppColors.slateBlue,
                  size: 28,
                ),
                Positioned(
                  right: 1,
                  top: 0,
                  child: Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: AppColors.danger,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),

          // Avatar: ketuk untuk membuka profil
          Tooltip(
            message: 'Profil',
            child: Material(
              color: AppColors.darkTeal,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const ProfileScreen()),
                ),
                child: const SizedBox(
                  width: 48,
                  height: 48,
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.white,
                    size: 26,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardPageAdvanced(onOpenHistory: _openHistory),
          const InputPage(),
          HistoryPage(refreshTick: _historyTick),
        ],
      ),
      bottomNavigationBar: CustomBottomNav(
        currentIndex: _currentIndex,
        onTap: (index) {
          if (index == 1) {
            _openInput();
            return;
          }

          setState(() {
            _currentIndex = index;
            if (index == _tabHistory) _historyTick++;
          });
        },
      ),
    );
  }
}