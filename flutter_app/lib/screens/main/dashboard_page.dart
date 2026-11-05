import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/pemakaian_bbm.dart';
import '../../models/user.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pemakaian_bbm_provider.dart';
import '../../widgets/dashboard_chart_card.dart';
import '../../widgets/dashboard_stat_card.dart';
import '../../widgets/recent_activity_card.dart';
import 'history_page.dart';
import '../input_bbm/input_step1_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  bool _isLoading = true;
  Map<String, dynamic> _stats = {};
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
      final thisMonth = DateTime(now.year, now.month);
      final lastMonth = DateTime(now.year, now.month - 1);

      final allData = provider.items;
      final thisMonthData = allData.where((item) {
        return item.tanggal.year == thisMonth.year && 
               item.tanggal.month == thisMonth.month;
      }).toList();

      final lastMonthData = allData.where((item) {
        return item.tanggal.year == lastMonth.year && 
               item.tanggal.month == lastMonth.month;
      }).toList();

      final thisMonthTotal = thisMonthData.fold<double>(
        0,
        (sum, item) => sum + item.jumlah,
      );

      final lastMonthTotal = lastMonthData.fold<double>(
        0,
        (sum, item) => sum + item.jumlah,
      );

      final thisMonthLiter = thisMonthData.fold<double>(
        0,
        (sum, item) => sum + item.liter,
      );

      final percentageChange = lastMonthTotal > 0
          ? ((thisMonthTotal - lastMonthTotal) / lastMonthTotal) * 100
          : 0.0;

      if (mounted) {
        setState(() {
          _stats = {
            'thisMonthTotal': thisMonthTotal,
            'thisMonthCount': thisMonthData.length,
            'thisMonthLiter': thisMonthLiter,
            'percentageChange': percentageChange,
            'totalVehicles': allData.map((e) => e.kendaraanId).toSet().length,
          };
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
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF667eea).withValues(alpha: 0.08),
              const Color(0xFF764ba2).withValues(alpha: 0.04),
            ],
          ),
        ),
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
                            const SizedBox(height: 24),
                            _buildChartSection(),
                            const SizedBox(height: 24),
                            _buildQuickActions(),
                            const SizedBox(height: 24),
                            _buildRecentActivities(),
                            const SizedBox(height: 100),
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
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF667eea), Color(0xFF764ba2)],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF667eea).withValues(alpha: 0.3),
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
            'Memuat Dashboard...',
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF667eea),
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
    IconData greetingIcon;

    if (hour < 12) {
      greeting = 'Selamat Pagi';
      greetingIcon = Icons.wb_sunny_outlined;
    } else if (hour < 15) {
      greeting = 'Selamat Siang';
      greetingIcon = Icons.wb_sunny;
    } else if (hour < 18) {
      greeting = 'Selamat Sore';
      greetingIcon = Icons.wb_twilight;
    } else {
      greeting = 'Selamat Malam';
      greetingIcon = Icons.nights_stay_outlined;
    }

    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF667eea), Color(0xFF764ba2)],
          ),
          borderRadius: const BorderRadius.only(
            bottomLeft: Radius.circular(32),
            bottomRight: Radius.circular(32),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF667eea).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: user?.photoUrl != null
                      ? ClipOval(
                          child: Image.network(
                            user!.photoUrl!,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Icon(
                              Icons.person,
                              color: Colors.white.withValues(alpha: 0.9),
                              size: 28,
                            ),
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.white.withValues(alpha: 0.9),
                          size: 28,
                        ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            greetingIcon,
                            color: Colors.white.withValues(alpha: 0.9),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            greeting,
                            style: GoogleFonts.poppins(
                              color: Colors.white.withValues(alpha: 0.9),
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        user?.username ?? 'User',
                        style: GoogleFonts.poppins(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.calendar_today,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(now),
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          'Hari ini',
                          style: GoogleFonts.poppins(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatsSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ringkasan Bulan Ini',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: DashboardStatCard(
                  title: 'Total Pengeluaran',
                  value: NumberFormat.currency(
                    locale: 'id_ID',
                    symbol: 'Rp ',
                    decimalDigits: 0,
                  ).format(_stats['thisMonthTotal'] ?? 0),
                  change: _stats['percentageChange'] ?? 0.0,
                  icon: Icons.attach_money,
                  gradientColors: const [Color(0xFF667eea), Color(0xFF764ba2)],
                  delay: 0,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardStatCard(
                  title: 'Total Transaksi',
                  value: '${_stats['thisMonthCount'] ?? 0}',
                  subtitle: 'transaksi',
                  icon: Icons.receipt_long,
                  gradientColors: const [Color(0xFFf093fb), Color(0xFFF5576c)],
                  delay: 100,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: DashboardStatCard(
                  title: 'Total Liter',
                  value: NumberFormat('#,##0.0', 'id_ID')
                      .format(_stats['thisMonthLiter'] ?? 0),
                  subtitle: 'liter',
                  icon: Icons.local_gas_station,
                  gradientColors: const [Color(0xFF4facfe), Color(0xFF00f2fe)],
                  delay: 200,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: DashboardStatCard(
                  title: 'Total Kendaraan',
                  value: '${_stats['totalVehicles'] ?? 0}',
                  subtitle: 'unit',
                  icon: Icons.directions_car,
                  gradientColors: const [Color(0xFF43e97b), Color(0xFF38f9d7)],
                  delay: 300,
                ),
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
      child: DashboardChartCard(
        pemakaianList: context.watch<PemakaianBbmProvider>().items,
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF2D3748),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
                  'Input BBM',
                  Icons.add_circle_outline,
                  const [Color(0xFF667eea), Color(0xFF764ba2)],
                  () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const HistoryPage(),
                      ),
                    ).then((_) => _loadDashboardData());
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildActionButton(
                  'Harga BBM',
                  Icons.price_change_outlined,
                  const [Color(0xFFf093fb), Color(0xFFF5576c)],
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Fitur Harga BBM akan segera hadir'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(
    String label,
    IconData icon,
    List<Color> colors,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 20),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: colors),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: colors[0].withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Aktivitas Terbaru',
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF2D3748),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const HistoryPage(),
                    ),
                  );
                },
                child: Text(
                  'Lihat Semua',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF667eea),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_recentActivities.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.inbox_outlined,
                      size: 48,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Belum ada data pemakaian BBM',
                      style: GoogleFonts.poppins(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _recentActivities.length,
              itemBuilder: (context, index) {
                return RecentActivityCard(
                  pemakaian: _recentActivities[index],
                  delay: index * 100,
                );
              },
            ),
        ],
      ),
    );
  }
}
