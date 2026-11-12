import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/app_theme.dart';
import '../../models/pemakaian_bbm.dart';
import '../../providers/auth_provider.dart';
import '../../providers/pemakaian_bbm_provider.dart';
import '../../services/api_service.dart';
import '../../utils/api_error.dart';
import '../../utils/display_format.dart';
import '../../widgets/advanced_stat_card.dart';
import '../../widgets/advanced_header.dart';
import '../../widgets/advanced_quick_action.dart';
import '../../widgets/advanced_chart_widget.dart';
import '../../widgets/advanced_transaction_card.dart';
import '../input_bbm/input_bbm_screen.dart';
import 'profile_screen.dart';

class DashboardPageAdvanced extends StatefulWidget {
  /// Dipanggil saat user ingin membuka tab Riwayat (diatur oleh MainShell).
  final VoidCallback? onOpenHistory;

  /// Naikkan nilainya untuk memuat ulang dashboard (opsional, dari MainShell).
  final int refreshTick;

  const DashboardPageAdvanced({
    super.key,
    this.onOpenHistory,
    this.refreshTick = 0,
  });

  @override
  State<DashboardPageAdvanced> createState() => _DashboardPageAdvancedState();
}

class _DashboardPageAdvancedState extends State<DashboardPageAdvanced>
    with AutomaticKeepAliveClientMixin, SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  /// Hanya untuk pemuatan awal (spinner layar penuh).
  bool _isLoading = true;

  /// Ringkasan dan transaksi terakhir berasal dari SERVER (semua data, semua
  /// driver), sama seperti total di Riwayat, bukan dihitung dari 20 data.
  Map<String, dynamic> _stats = {};
  List<PemakaianBbm> _recent = [];

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _setupAnimations();
    _loadDashboardData();
  }

  @override
  void didUpdateWidget(covariant DashboardPageAdvanced oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.refreshTick != widget.refreshTick) {
      _loadDashboardData(silent: true);
    }
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

  /// Ambil ringkasan dari server. Mengembalikan pesan error, atau null.
  Future<String?> _fetchRingkasan() async {
    try {
      final res = await ApiService().getRingkasanPemakaian();
      final d = Map<String, dynamic>.from(res.data['data'] as Map);

      _stats = {
        'todayTotal': asDouble(d['today_total']),
        'todayLiter': asDouble(d['today_liter']),
        'todayCount': asDouble(d['today_count']).toInt(),
        'monthTotal': asDouble(d['month_total']),
        'monthLiter': asDouble(d['month_liter']),
        'monthCount': asDouble(d['month_count']).toInt(),
        'percentageChange': asDouble(d['percentage_change']),
        'totalVehicles': asDouble(d['total_vehicles']).toInt(),
      };
      _recent = (d['recent'] as List)
          .map((e) =>
              PemakaianBbm.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
      return null;
    } on DioException catch (e) {
      return parseApiError(e, 'Gagal memuat ringkasan.');
    } catch (_) {
      return 'Gagal memuat ringkasan.';
    }
  }

  /// [silent] = true: muat ulang tanpa spinner layar penuh.
  Future<void> _loadDashboardData({bool silent = false}) async {
    if (!silent && !_isLoading) setState(() => _isLoading = true);

    final provider = context.read<PemakaianBbmProvider>();

    // Ringkasan (server) dan data grafik (provider) dimuat bersamaan.
    final results = await Future.wait<Object?>([
      _fetchRingkasan(),
      provider.loadPemakaian(reset: true),
    ]);

    if (!mounted) return;
    setState(() => _isLoading = false);

    final error = (results[0] as String?) ?? provider.error;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal memuat data: $error'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.danger,
          margin: const EdgeInsets.all(16),
        ),
      );
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

    final stats = _stats;
    final recent = _recent;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Container(
        color: AppColors.background,
        child: Column(
          children: [
            AdvancedHeader(
              user: context.watch<AuthProvider>().user,
              onProfileTap: () => Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const ProfileScreen()),
              ),
            ),
            Expanded(
              child: _isLoading
                  ? _buildLoadingState()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: () => _loadDashboardData(silent: true),
                        color: AppColors.primary,
                        backgroundColor: Colors.white,
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          removeBottom: true,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 12),
                                    // Stats Section
                                    _buildStatsSection(stats),
                                    const SizedBox(height: 16),
                                    // Quick Actions Section
                                    _buildQuickActionsSection(),
                                    const SizedBox(height: 16),
                                    // Chart Section
                                    _buildChartSection(),
                                    const SizedBox(height: 16),
                                    // Recent Transactions Section
                                    _buildRecentTransactionsSection(recent),
                                    // Ruang bawah agar tidak tertutup bottom nav.
                                    const SizedBox(height: 120),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ],
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
                colors: [AppColors.primary, AppColors.darkNavy],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
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
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats) {
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
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Pemakaian BBM seluruh driver',
                    style: GoogleFonts.poppins(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today,
                      size: 12,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('d MMM', 'id_ID').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 1.5,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AdvancedStatCard(
                label: 'Total Pengeluaran',
                value: NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(stats['todayTotal'] ?? 0),
                icon: Icons.attach_money,
                primaryColor: AppColors.primary,
                backgroundColor: AppColors.primarySoft,
              ),
              AdvancedStatCard(
                label: 'Total Liter',
                value:
                    '${(stats['todayLiter'] as double? ?? 0).toStringAsFixed(1)} L',
                icon: Icons.local_gas_station,
                primaryColor: AppColors.success,
                backgroundColor: AppColors.successSoft,
              ),
              AdvancedStatCard(
                label: 'Bulan Ini',
                value: NumberFormat.currency(
                  locale: 'id_ID',
                  symbol: 'Rp ',
                  decimalDigits: 0,
                ).format(stats['monthTotal'] ?? 0),
                subtitle: '${(stats['monthCount'] ?? 0)} transaksi',
                icon: Icons.receipt_long,
                primaryColor: AppColors.accentYellow,
                backgroundColor: AppColors.warningSoft,
                change: stats['percentageChange'] as double?,
                isPositive: (stats['percentageChange'] as double? ?? 0) >= 0,
              ),
              AdvancedStatCard(
                label: 'Kendaraan Aktif',
                value: '${stats['totalVehicles'] ?? 0} Unit',
                subtitle: 'tersedia',
                icon: Icons.directions_car,
                primaryColor: AppColors.primary,
                backgroundColor: AppColors.primarySoft,
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
              color: AppColors.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 10),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 2.1,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AdvancedQuickAction(
                label: 'Catat BBM',
                description: 'Input pemakaian baru',
                icon: Icons.local_gas_station,
                primaryColor: AppColors.primary,
                backgroundColor: AppColors.primarySoft,
                isPrimary: true,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const InputBbmScreen()),
                  ).then((_) => _loadDashboardData(silent: true));
                },
              ),
              AdvancedQuickAction(
                label: 'Riwayat',
                description: 'Lihat semua transaksi',
                icon: Icons.history,
                primaryColor: AppColors.success,
                backgroundColor: AppColors.successSoft,
                onTap: () => widget.onOpenHistory?.call(),
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

  Widget _buildRecentTransactionsSection(
      List<PemakaianBbm> recentTransactions) {
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
                      color: AppColors.textPrimary,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${recentTransactions.length} transaksi terakhir',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
              if (recentTransactions.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onOpenHistory?.call(),
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(40),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.border, width: 1),
              ),
              child: Column(
                children: [
                  Icon(Icons.inbox_outlined, size: 48, color: AppColors.border),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada riwayat pengisian',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Mulai dengan catat BBM untuk melihat riwayat',
                    style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: recentTransactions.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final tx = recentTransactions[index];
                return AdvancedTransactionCard(pemakaian: tx);
              },
            ),
        ],
      ),
    );
  }
}