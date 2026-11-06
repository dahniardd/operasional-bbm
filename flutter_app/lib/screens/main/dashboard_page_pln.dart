import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/pln_colors.dart';
import '../../models/pemakaian_bbm.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pemakaian_bbm_provider.dart';
import '../input_bbm/input_bbm_screen.dart';
import 'history_page.dart';

class DashboardPagePln extends StatefulWidget {
  const DashboardPagePln({super.key});

  @override
  State<DashboardPagePln> createState() => _DashboardPagePlnState();
}

class _DashboardPagePlnState extends State<DashboardPagePln>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  PemakaianBbm? _lastTransaction;
  List<PemakaianBbm> _recentActivities = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  void _setupAnimations() {
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));

    _animationController.forward();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<PemakaianBbmProvider>();
      await provider.loadPemakaian(reset: true);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisWeek = today.subtract(Duration(days: today.weekday - 1));
      final thisMonth = DateTime(now.year, now.month);
      final thisYear = DateTime(now.year);

      final allData = provider.items;

      // Get statistics untuk berbagai periode
      final todayData = allData.where((item) {
        final date = DateTime(item.tanggal.year, item.tanggal.month, item.tanggal.day);
        return date == today;
      }).toList();

      final monthData = allData.where((item) {
        return item.tanggal.year == thisMonth.year && 
               item.tanggal.month == thisMonth.month;
      }).toList();

      // Calculate stats
      final todayTotal = todayData.fold<double>(0, (sum, item) => sum + item.jumlah);
      final todayLiter = todayData.fold<double>(0, (sum, item) => sum + item.liter);
      final todayCount = todayData.length;

      final monthTotal = monthData.fold<double>(0, (sum, item) => sum + item.jumlah);
      final monthLiter = monthData.fold<double>(0, (sum, item) => sum + item.liter);
      final monthCount = monthData.length;

      if (mounted) {
        setState(() {
          _stats = {
            'todayTotal': todayTotal,
            'todayLiter': todayLiter,
            'todayCount': todayCount,
            'monthTotal': monthTotal,
            'monthLiter': monthLiter,
            'monthCount': monthCount,
            'totalVehicles': allData.map((e) => e.kendaraanId).toSet().length,
          };
          _lastTransaction = allData.isNotEmpty ? allData.first : null;
          _recentActivities = allData.take(5).toList();
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: PlnColors.danger,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final user = context.watch<AuthProvider>().user;

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      color: PlnColors.primaryBlue,
      backgroundColor: Colors.white,
      child: Container(
        color: PlnColors.background,
        child: _isLoading
            ? _buildLoadingState()
            : FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: CustomScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    slivers: [
                      _buildHeader(user),
                      SliverToBoxAdapter(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildStatsSection(),
                            const SizedBox(height: 28),
                            _buildQuickActionsSection(),
                            const SizedBox(height: 28),
                            const SizedBox(height: 28),
                            if (_lastTransaction != null) ...[
                              _buildLastTransactionCard(),
                              const SizedBox(height: 28),
                            ],
                            _buildRecentActivitiesSection(),
                            const SizedBox(height: 32),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(PlnColors.primaryBlue),
            strokeWidth: 3,
          ),
          const SizedBox(height: 16),
          Text(
            'Memuat dashboard...',
            style: GoogleFonts.poppins(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: PlnColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(User? user) {
    final now = DateTime.now();
    final hour = now.hour;
    String greeting;

    if (hour < 12) {
      greeting = 'Selamat Pagi';
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
    } else {
      greeting = 'Selamat Malam';
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [PlnColors.primaryBlue, PlnColors.darkNavy],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        greeting,
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.username ?? 'Pengguna',
                        style: GoogleFonts.poppins(
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now),
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
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
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Hari Ini',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PlnColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Total Pengeluaran',
                  value: NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(_stats['todayTotal'] ?? 0),
                  icon: Icons.attach_money,
                  backgroundColor: const Color(0xFFE8F4FF),
                  borderColor: PlnColors.primaryBlue,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Liter',
                  value: '${(_stats['todayLiter'] as double? ?? 0).toStringAsFixed(1)} L',
                  icon: Icons.local_gas_station,
                  backgroundColor: const Color(0xFFE8F9F5),
                  borderColor: PlnColors.success,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: 'Jumlah Pengisian',
                  value: '${_stats['todayCount'] ?? 0}x',
                  icon: Icons.receipt_long,
                  backgroundColor: const Color(0xFFFEF3E2),
                  borderColor: PlnColors.accentYellow,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: 'Total Kendaraan',
                  value: '${_stats['totalVehicles'] ?? 0} Unit',
                  icon: Icons.directions_car,
                  backgroundColor: const Color(0xFFE8F4FF),
                  borderColor: PlnColors.primaryBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color backgroundColor,
    required Color borderColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: borderColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: borderColor, size: 24),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.poppins(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: PlnColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: borderColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PlnColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildQuickActionTile(
                label: 'Catat BBM',
                icon: Icons.local_gas_station,
                backgroundColor: const Color(0xFFE8F4FF),
                iconColor: PlnColors.primaryBlue,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const InputBbmScreen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
              _buildQuickActionTile(
                label: 'Riwayat\nPengisian',
                icon: Icons.history,
                backgroundColor: const Color(0xFFE8F9F5),
                iconColor: PlnColors.success,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistoryPage(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
              _buildQuickActionTile(
                label: 'Statistik\nBBM',
                icon: Icons.bar_chart,
                backgroundColor: const Color(0xFFFEF3E2),
                iconColor: PlnColors.accentYellow,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Lihat grafik di bagian Grafik Pemakaian BBM'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: PlnColors.primaryBlue,
                    ),
                  );
                },
              ),
              _buildQuickActionTile(
                label: 'Kendaraan',
                icon: Icons.directions_car,
                backgroundColor: const Color(0xFFE8F4FF),
                iconColor: PlnColors.primaryBlue,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Fitur kendaraan akan segera tersedia'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: PlnColors.warning,
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionTile({
    required String label,
    required IconData icon,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: iconColor.withValues(alpha: 0.2),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: iconColor.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  icon,
                  color: iconColor,
                  size: 28,
                ),
                Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: iconColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLastTransactionCard() {
    if (_lastTransaction == null) return const SizedBox.shrink();

    final tx = _lastTransaction!;
    final price = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(tx.jumlah);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Pengisian Terakhir',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: PlnColors.textPrimary,
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: PlnColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: PlnColors.border,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            tx.platNomor,
                            style: GoogleFonts.poppins(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: PlnColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                size: 14,
                                color: PlnColors.textSecondary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat('d MMM yyyy', 'id_ID')
                                    .format(tx.tanggal),
                                style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: PlnColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Text(
                      price,
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: PlnColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(
                  color: PlnColors.border,
                  height: 1,
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jenis BBM',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: PlnColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _formatBbmName(tx.jenisBbm),
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PlnColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Jumlah Liter',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: PlnColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${tx.liter.toStringAsFixed(1)} L',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PlnColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Lokasi',
                          style: GoogleFonts.poppins(
                            fontSize: 12,
                            color: PlnColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tx.lokasiPembelian == 'paiton' ? 'Paiton' : 'Luar Paiton',
                          style: GoogleFonts.poppins(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: PlnColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivitiesSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Riwayat Pengisian',
                style: GoogleFonts.poppins(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: PlnColors.textPrimary,
                ),
              ),
              if (_recentActivities.length > 3)
                TextButton(
                  onPressed: () {
                    // Navigate to full history
                  },
                  child: Text(
                    'Lihat Semua',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: PlnColors.primaryBlue,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentActivities.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: PlnColors.border,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada riwayat pengisian',
                      style: GoogleFonts.poppins(
                        fontSize: 13,
                        color: PlnColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivities.take(3).length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = _recentActivities[index];
                return _buildTransactionItem(tx);
              },
            ),
        ],
      ),
    );
  }

  Widget _buildTransactionItem(PemakaianBbm tx) {
    final price = NumberFormat.currency(
      locale: 'id_ID',
      symbol: 'Rp ',
      decimalDigits: 0,
    ).format(tx.jumlah);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: PlnColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: PlnColors.border,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.local_gas_station,
              color: PlnColors.primaryBlue,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tx.platNomor,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: PlnColors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${DateFormat('d MMM', 'id_ID').format(tx.tanggal)} • ${_formatBbmName(tx.jenisBbm)} • ${tx.liter.toStringAsFixed(1)}L',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: PlnColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price,
            style: GoogleFonts.poppins(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: PlnColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  String _formatBbmName(String jenisBbm) {
    switch (jenisBbm) {
      case 'pertamax':
        return 'Pertamax';
      case 'pertadex':
        return 'Pertadex';
      case 'dexlite':
        return 'Dexlite';
      case 'pertamax_turbo':
        return 'Pertamax Turbo';
      case 'solar':
        return 'Solar';
      default:
        return jenisBbm;
    }
  }
}
