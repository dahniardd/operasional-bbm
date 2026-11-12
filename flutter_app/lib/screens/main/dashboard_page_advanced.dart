import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../config/design_tokens.dart';
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
import '../../widgets/dashboard_skeleton.dart';
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
          .map(
            (e) => PemakaianBbm.fromJson(Map<String, dynamic>.from(e as Map)),
          )
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
          backgroundColor: AppTokens.danger,
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
        color: AppTokens.background,
        child: Column(
          children: [
            AdvancedHeader(
              user: context.watch<AuthProvider>().user,
              onProfileTap: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
            ),
            Expanded(
              child: _isLoading
                  ? const DashboardSkeleton()
                  : FadeTransition(
                      opacity: _fadeAnimation,
                      child: RefreshIndicator(
                        onRefresh: () => _loadDashboardData(silent: true),
                        color: AppTokens.brand,
                        backgroundColor: AppTokens.surface,
                        child: MediaQuery.removePadding(
                          context: context,
                          removeTop: true,
                          removeBottom: true,
                          child: CustomScrollView(
                            physics: const AlwaysScrollableScrollPhysics(),
                            slivers: [
                              SliverToBoxAdapter(
                                child: Center(
                                  child: ConstrainedBox(
                                    constraints: const BoxConstraints(
                                      maxWidth: AppTokens.contentMaxWidth,
                                    ),
                                    child: SizedBox(
                                      width: double.infinity,
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(
                                            height: AppTokens.space12,
                                          ),
                                          _buildStatsSection(stats),
                                          const SizedBox(
                                            height: AppTokens.space16,
                                          ),
                                          _buildQuickActionsSection(),
                                          const SizedBox(
                                            height: AppTokens.space16,
                                          ),
                                          _buildChartSection(),
                                          const SizedBox(
                                            height: AppTokens.space16,
                                          ),
                                          _buildRecentTransactionsSection(
                                            recent,
                                          ),
                                          const SizedBox(height: 120),
                                        ],
                                      ),
                                    ),
                                  ),
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

  Widget _buildStatsSection(Map<String, dynamic> stats) {
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 2.0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ringkasan Hari Ini',
                      style: GoogleFonts.poppins(
                        fontSize: AppTokens.fontTitle,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      'Pemakaian BBM seluruh driver',
                      style: GoogleFonts.poppins(
                        fontSize: AppTokens.fontCaption,
                        fontWeight: FontWeight.w400,
                        color: AppTokens.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: AppTokens.space8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTokens.space10,
                  vertical: AppTokens.space6,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.brand.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                  border: Border.all(
                    color: AppTokens.brand.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.calendar_today,
                      size: AppTokens.fontCaption,
                      color: AppTokens.brand,
                    ),
                    const SizedBox(width: AppTokens.space4),
                    Text(
                      DateFormat('d MMM', 'id_ID').format(DateTime.now()),
                      style: GoogleFonts.poppins(
                        fontSize: AppTokens.fontCaption,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.brand,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space10),
          LayoutBuilder(
            builder: (context, constraints) {
              final columns = constraints.maxWidth >= 680 ? 4 : 2;
              return GridView.count(
                padding: EdgeInsets.zero,
                crossAxisCount: columns,
                mainAxisSpacing: AppTokens.space10,
                crossAxisSpacing: AppTokens.space10,
                mainAxisExtent: 136 * textScale,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  AdvancedStatCard(
                    label: 'Pengeluaran Hari Ini',
                    value: NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(stats['todayTotal'] ?? 0),
                    icon: Icons.attach_money,
                    primaryColor: AppTokens.brand,
                    backgroundColor: const Color(0xFFE8F4FF),
                  ),
                  AdvancedStatCard(
                    label: 'Liter Hari Ini',
                    value:
                        '${(stats['todayLiter'] as double? ?? 0).toStringAsFixed(1)} L',
                    icon: Icons.local_gas_station,
                    primaryColor: AppTokens.success,
                    backgroundColor: const Color(0xFFE8F9F5),
                  ),
                  AdvancedStatCard(
                    label: 'Pengeluaran Bulan Ini',
                    value: NumberFormat.currency(
                      locale: 'id_ID',
                      symbol: 'Rp ',
                      decimalDigits: 0,
                    ).format(stats['monthTotal'] ?? 0),
                    subtitle: '${(stats['monthCount'] ?? 0)} transaksi',
                    icon: Icons.receipt_long,
                    primaryColor: AppTokens.accent,
                    valueColor: AppTokens.warningText,
                    backgroundColor: const Color(0xFFFEF3E2),
                    change: stats['percentageChange'] as double?,
                    isPositive:
                        (stats['percentageChange'] as double? ?? 0) >= 0,
                    positiveIsGood: false,
                    badTrendColor: AppTokens.warning,
                  ),
                  AdvancedStatCard(
                    label: 'Kendaraan Aktif',
                    value: '${stats['totalVehicles'] ?? 0} Unit',
                    subtitle: 'tersedia',
                    icon: Icons.directions_car,
                    primaryColor: AppTokens.brand,
                    backgroundColor: const Color(0xFFE8F4FF),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection() {
    final textScale = MediaQuery.textScalerOf(
      context,
    ).scale(1).clamp(1.0, 2.0).toDouble();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Aksi Cepat',
            style: GoogleFonts.poppins(
              fontSize: AppTokens.fontTitle,
              fontWeight: FontWeight.w700,
              color: AppTokens.textPrimary,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: AppTokens.space10),
          GridView.count(
            padding: EdgeInsets.zero,
            crossAxisCount: 2,
            mainAxisSpacing: AppTokens.space10,
            crossAxisSpacing: AppTokens.space10,
            mainAxisExtent: 76 * textScale,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              AdvancedQuickAction(
                label: 'Catat BBM',
                description: 'Input pemakaian baru',
                icon: Icons.local_gas_station,
                primaryColor: AppTokens.brand,
                backgroundColor: const Color(0xFFE8F4FF),
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
                primaryColor: AppTokens.success,
                backgroundColor: const Color(0xFFE8F9F5),
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
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space20),
      child: AdvancedChartWidget(
        pemakaianList: context.watch<PemakaianBbmProvider>().items,
      ),
    );
  }

  Widget _buildRecentTransactionsSection(
    List<PemakaianBbm> recentTransactions,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Riwayat Pengisian',
                      style: GoogleFonts.poppins(
                        fontSize: AppTokens.fontTitle,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.textPrimary,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: AppTokens.space2),
                    Text(
                      '${recentTransactions.length} transaksi terakhir',
                      style: GoogleFonts.poppins(
                        fontSize: AppTokens.fontCaption,
                        fontWeight: FontWeight.w400,
                        color: AppTokens.textSecondary,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              if (recentTransactions.isNotEmpty)
                Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () => widget.onOpenHistory?.call(),
                    borderRadius: BorderRadius.circular(AppTokens.radiusSm),
                    child: Container(
                      constraints: const BoxConstraints(
                        minHeight: AppTokens.minTapTarget,
                        minWidth: AppTokens.minTapTarget,
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTokens.space12,
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'Lihat Semua',
                        style: GoogleFonts.poppins(
                          fontSize: AppTokens.fontCaption,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.brand,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppTokens.space10),
          if (recentTransactions.isEmpty)
            Container(
              padding: const EdgeInsets.all(AppTokens.space24),
              decoration: BoxDecoration(
                color: AppTokens.surface,
                borderRadius: BorderRadius.circular(AppTokens.radiusLg),
                border: Border.all(color: AppTokens.border, width: 1),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.inbox_outlined,
                    size: AppTokens.minTapTarget,
                    color: AppTokens.border,
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Text(
                    'Belum ada riwayat pengisian',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space12),
                  Text(
                    'Mulai dengan catat BBM untuk melihat riwayat',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.poppins(
                      fontSize: AppTokens.fontCaption,
                      color: AppTokens.textSecondary,
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
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppTokens.space10),
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
