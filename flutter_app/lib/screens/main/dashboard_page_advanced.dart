import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/pln_colors.dart';
import '../../models/pemakaian_bbm.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pemakaian_bbm_provider.dart';
import '../../widgets/advanced_stat_card.dart';
import '../../widgets/advanced_header.dart';
import '../../widgets/advanced_quick_action.dart';
import '../../widgets/advanced_chart_widget.dart';
import '../../widgets/advanced_transaction_card.dart';
import '../input_bbm/input_step1_screen.dart';

class DashboardPageAdvanced extends StatefulWidget {
  const DashboardPageAdvanced({super.key});

  @override
  State<DashboardPageAdvanced> createState() => _DashboardPageAdvancedState();
}

class _DashboardPageAdvancedState extends State<DashboardPageAdvanced>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
  List<PemakaianBbm> _recentTransactions = [];
  int? _expandedTransactionIndex;

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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );

    _animationController.forward();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);

    try {
      final provider = context.read<PemakaianBbmProvider>();
      await provider.loadPemakaian(reset: true);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final thisMonth = DateTime(now.year, now.month);
      final lastMonth = now.month == 1
          ? DateTime(now.year - 1, 12)
          : DateTime(now.year, now.month - 1);

      final allData = provider.items;

      // Today statistics
      final todayData =
          allData.where((item) {
            final itemDate =
                DateTime(item.tanggal.year, item.tanggal.month, item.tanggal.day);
            return itemDate == today;
          }).toList();

      final todayTotal = todayData.fold<double>(0, (sum, item) => sum + item.jumlah);
      final todayLiter = todayData.fold<double>(0, (sum, item) => sum + item.liter);

      // Month statistics
      final monthData = allData
          .where((item) =>
              item.tanggal.year == thisMonth.year &&
              item.tanggal.month == thisMonth.month)
          .toList();

      final monthTotal = monthData.fold<double>(0, (sum, item) => sum + item.jumlah);
      final monthLiter = monthData.fold<double>(0, (sum, item) => sum + item.liter);

      // Last month for comparison
      final lastMonthData = allData
          .where((item) =>
              item.tanggal.year == lastMonth.year &&
              item.tanggal.month == lastMonth.month)
          .toList();

      final lastMonthTotal =
          lastMonthData.fold<double>(0, (sum, item) => sum + item.jumlah);

      final percentageChange = lastMonthTotal > 0
          ? ((monthTotal - lastMonthTotal) / lastMonthTotal) * 100
          : 0.0;

      if (mounted) {
        setState(() {
          _stats = {
            'todayTotal': todayTotal,
            'todayLiter': todayLiter,
            'todayCount': todayData.length,
            'monthTotal': monthTotal,
            'monthLiter': monthLiter,
            'monthCount': monthData.length,
            'percentageChange': percentageChange,
            'totalVehicles': allData.map((e) => e.kendaraanId).toSet().length,
          };
          _recentTransactions = allData.take(6).toList();
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
            margin: const EdgeInsets.all(16),
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
                child: CustomScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  slivers: [
                    // Header
                    SliverToBoxAdapter(
                      child: AdvancedHeader(
                        user: context.watch<AuthProvider>().user,
                        onSettingsTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Settings akan segera tersedia'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        onNotificationTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Notifikasi akan segera tersedia'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                    // Content
                    SliverToBoxAdapter(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 24),
                          // Stats Section
                          _buildStatsSection(),
                          const SizedBox(height: 32),
                          // Quick Actions Section
                          _buildQuickActionsSection(),
                          const SizedBox(height: 32),
                          // Chart Section
                          _buildChartSection(),
                          const SizedBox(height: 32),
                          // Recent Transactions Section
                          _buildRecentTransactionsSection(),
                          const SizedBox(height: 40),
                        ],
                      ),
                    ),
                  ],
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  PlnColors.primaryBlue,
                  PlnColors.darkNavy,
                ],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: PlnColors.primaryBlue.withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                strokeWidth: 3,
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Memuat Dashboard Advance...',
            style: GoogleFonts.poppins(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: PlnColors.primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ringkasan Hari Ini',
                    style: GoogleFonts.poppins(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: PlnColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lihat performa pemakaian BBM Anda',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: PlnColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: PlnColors.primaryBlue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: PlnColors.primaryBlue.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: PlnColors.primaryBlue,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM', 'id_ID').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: PlnColors.primaryBlue,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          GridView.count(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AdvancedStatCard(
                label: 'Total Pengeluaran',
                value: NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(_stats['todayTotal'] ?? 0),
                icon: Icons.attach_money,
                primaryColor: PlnColors.primaryBlue,
                backgroundColor: const Color(0xFFE8F4FF),
              ),
              AdvancedStatCard(
                label: 'Total Liter',
                value: '${(_stats['todayLiter'] as double? ?? 0).toStringAsFixed(1)} L',
                icon: Icons.local_gas_station,
                primaryColor: PlnColors.success,
                backgroundColor: const Color(0xFFE8F9F5),
              ),
              AdvancedStatCard(
                label: 'Bulan Ini',
                value: NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(_stats['monthTotal'] ?? 0),
                subtitle: '${(_stats['monthCount'] ?? 0)} transaksi',
                icon: Icons.receipt_long,
                primaryColor: PlnColors.accentYellow,
                backgroundColor: const Color(0xFFFEF3E2),
                change: _stats['percentageChange'] as double?,
                isPositive: (_stats['percentageChange'] as double? ?? 0) >= 0,
              ),
              AdvancedStatCard(
                label: 'Kendaraan Aktif',
                value: '${_stats['totalVehicles'] ?? 0} Unit',
                subtitle: 'tersedia',
                icon: Icons.directions_car,
                primaryColor: PlnColors.primaryBlue,
                backgroundColor: const Color(0xFFE8F4FF),
              ),
            ],
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
              fontWeight: FontWeight.w700,
              color: PlnColors.textPrimary,
              letterSpacing: -0.3,
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
              AdvancedQuickAction(
                label: 'Catat BBM',
                description: 'Input pemakaian baru',
                icon: Icons.local_gas_station,
                primaryColor: PlnColors.primaryBlue,
                backgroundColor: const Color(0xFFE8F4FF),
                isPrimary: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InputStep1Screen(),
                    ),
                  ).then((_) => _loadDashboardData());
                },
              ),
              AdvancedQuickAction(
                label: 'Riwayat',
                description: 'Lihat semua transaksi',
                icon: Icons.history,
                primaryColor: PlnColors.success,
                backgroundColor: const Color(0xFFE8F9F5),
                onTap: () {
                  // Navigate ke tab History
                  setState(() {
                    // Trigger parent to change tab
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Gunakan tab History di bawah untuk melihat riwayat'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: PlnColors.primaryBlue,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              AdvancedQuickAction(
                label: 'Statistik',
                description: 'Analisis pemakaian',
                icon: Icons.bar_chart,
                primaryColor: PlnColors.accentYellow,
                backgroundColor: const Color(0xFFFEF3E2),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Scroll ke bawah untuk melihat grafik detail'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: PlnColors.primaryBlue,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                },
              ),
              AdvancedQuickAction(
                label: 'Kendaraan',
                description: 'Kelola kendaraan Anda',
                icon: Icons.directions_car,
                primaryColor: PlnColors.primaryBlue,
                backgroundColor: const Color(0xFFE8F4FF),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Fitur kendaraan akan segera tersedia'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: PlnColors.warning,
                      duration: const Duration(seconds: 2),
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

  Widget _buildChartSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AdvancedChartWidget(
        pemakaianList: context.watch<PemakaianBbmProvider>().items,
      ),
    );
  }

  Widget _buildRecentTransactionsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat Pengisian',
                    style: GoogleFonts.poppins(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: PlnColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_recentTransactions.length} transaksi terakhir',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: PlnColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (_recentTransactions.length > 3)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Gunakan tab History di bawah untuk melihat semua riwayat'),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: PlnColors.primaryBlue,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: PlnColors.primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          if (_recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: PlnColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: PlnColors.border,
                  width: 1,
                ),
              ),
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
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: PlnColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mulai dengan catat BBM untuk melihat riwayat',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: PlnColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentTransactions.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final tx = _recentTransactions[index];
                return AdvancedTransactionCard(
                  pemakaian: tx,
                  isExpanded: _expandedTransactionIndex == index,
                  onEdit: () {
                    // Edit action
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Edit transaksi akan segera tersedia'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  onDelete: () {
                    // Delete action
                    showDialog(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Hapus Transaksi'),
                        content: const Text(
                          'Apakah Anda yakin ingin menghapus transaksi ini?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Batal'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Delete transaksi akan segera tersedia'),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            },
                            child: const Text(
                              'Hapus',
                              style: TextStyle(color: PlnColors.danger),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
        ],
      ),
    );
  }
}
