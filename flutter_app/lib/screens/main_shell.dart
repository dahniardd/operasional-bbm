import 'package:flutter/material.dart';

import '../config/app_colors.dart';
import '../widgets/custom_bottom_nav.dart';
import 'main/dashboard_page_advanced.dart' show DashboardPageAdvanced;
import 'main/history_page.dart';
import 'main/input_page.dart';
import 'input_bbm/input_bbm_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  static const int _tabDashboard = 0;
  static const int _tabHistory = 2;

  int _currentIndex = _tabDashboard;

  /// Naik setiap kali data perlu dimuat ulang (pindah tab, atau selesai input).
  /// Satu penanda yang sama untuk Dashboard dan Riwayat; keduanya mengambil
  /// ulang dari server, jadi angkanya selalu berasal dari data yang sama.
  int _dataTick = 0;

  void _openHistory() {
    setState(() {
      _currentIndex = _tabHistory;
      _dataTick++;
    });
  }

  Future<void> _openInput() async {
    await Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => const InputBbmScreen()));
    // Setelah kembali dari form input, data baru harus muncul di Dashboard
    // dan Riwayat.
    if (mounted) setState(() => _dataTick++);
  }

  @override
  Widget build(BuildContext context) {
    // Tidak ada AppBar di sini: Dashboard dan Riwayat sama-sama punya header
    // biru sendiri (identitas aplikasi + tombol profil).
    return Scaffold(
      extendBody: true,
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          DashboardPageAdvanced(
            onOpenHistory: _openHistory,
            refreshTick: _dataTick,
          ),
          const InputPage(),
          HistoryPage(refreshTick: _dataTick),
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
            // Muat ulang diam-diam saat membuka Dashboard atau Riwayat.
            _dataTick++;
          });
        },
      ),
    );
  }
}