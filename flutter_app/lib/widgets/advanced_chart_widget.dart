import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../config/app_theme.dart';
import '../models/pemakaian_bbm.dart';

/// Advanced Chart Widget dengan period selector dan animasi
class AdvancedChartWidget extends StatefulWidget {
  final List<PemakaianBbm> pemakaianList;

  const AdvancedChartWidget({super.key, required this.pemakaianList});

  @override
  State<AdvancedChartWidget> createState() => _AdvancedChartWidgetState();
}

class _AdvancedChartWidgetState extends State<AdvancedChartWidget>
    with SingleTickerProviderStateMixin {
  String _selectedPeriod = '7days'; // 7days, 30days, month
  String _selectedMetric = 'liter'; // liter, cost
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(begin: 0.97, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutCubic),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _selectPeriod(String value) {
    if (_selectedPeriod == value) return;
    setState(() => _selectedPeriod = value);
    _animationController.forward(from: 0);
  }

  void _selectMetric(String value) {
    if (_selectedMetric == value) return;
    setState(() => _selectedMetric = value);
    _animationController.forward(from: 0);
  }

  Map<String, dynamic> _calculateChartData() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    List<PemakaianBbm> filteredData = [];
    String periodLabel = '';
    int daysSpan = 7;

    switch (_selectedPeriod) {
      case '7days':
        final start = today.subtract(const Duration(days: 6));
        filteredData = widget.pemakaianList
            .where((item) => !_dateOnly(item.tanggal).isBefore(start))
            .toList();
        periodLabel = 'Terakhir 7 Hari';
        daysSpan = 7;
        break;
      case '30days':
        final start = today.subtract(const Duration(days: 29));
        filteredData = widget.pemakaianList
            .where((item) => !_dateOnly(item.tanggal).isBefore(start))
            .toList();
        periodLabel = 'Terakhir 30 Hari';
        daysSpan = 30;
        break;
      case 'month':
        filteredData = widget.pemakaianList
            .where(
              (item) =>
                  item.tanggal.year == now.year &&
                  item.tanggal.month == now.month,
            )
            .toList();
        periodLabel = 'Bulan ${DateFormat('MMMM', 'id_ID').format(now)}';
        daysSpan = now.day;
        break;
    }

    final totalLiter = filteredData.fold<double>(
      0,
      (sum, item) => sum + item.liter,
    );
    final totalCost = filteredData.fold<double>(
      0,
      (sum, item) => sum + item.jumlah,
    );
    final avgDaily = daysSpan <= 0 ? 0.0 : totalLiter / daysSpan;

    return {
      'data': filteredData,
      'totalLiter': totalLiter,
      'totalCost': totalCost,
      'avgDaily': avgDaily,
      'count': filteredData.length,
      'periodLabel': periodLabel,
    };
  }

  DateTime _dateOnly(DateTime date) =>
      DateTime(date.year, date.month, date.day);

  List<_BarData> _buildBars(List<PemakaianBbm> data) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final bars = <_BarData>[];

    double sumBetween(DateTime start, DateTime endExclusive) {
      var sum = 0.0;
      for (final item in data) {
        final date = _dateOnly(item.tanggal);
        if (!date.isBefore(start) && date.isBefore(endExclusive)) {
          sum += _selectedMetric == 'liter' ? item.liter : item.jumlah;
        }
      }
      return sum;
    }

    if (_selectedPeriod == '7days') {
      for (var i = 6; i >= 0; i--) {
        final start = today.subtract(Duration(days: i));
        final end = start.add(const Duration(days: 1));
        bars.add(
          _BarData(
            DateFormat('E', 'id_ID').format(start),
            sumBetween(start, end),
          ),
        );
      }
      return bars;
    }

    if (_selectedPeriod == '30days') {
      final start = today.subtract(const Duration(days: 29));
      for (var i = 0; i < 5; i++) {
        final bucketStart = start.add(Duration(days: i * 6));
        final bucketEnd = bucketStart.add(const Duration(days: 6));
        bars.add(
          _BarData(
            DateFormat('d/M', 'id_ID').format(bucketStart),
            sumBetween(bucketStart, bucketEnd),
          ),
        );
      }
      return bars;
    }

    final monthStart = DateTime(now.year, now.month, 1);
    final nextMonth = DateTime(now.year, now.month + 1, 1);
    var bucketStart = monthStart;
    var week = 1;
    while (bucketStart.isBefore(nextMonth)) {
      final bucketEnd = bucketStart.add(const Duration(days: 7));
      final cappedEnd = bucketEnd.isAfter(nextMonth) ? nextMonth : bucketEnd;
      bars.add(_BarData('M$week', sumBetween(bucketStart, cappedEnd)));
      bucketStart = cappedEnd;
      week++;
    }
    return bars;
  }

  @override
  Widget build(BuildContext context) {
    final chartData = _calculateChartData();
    final data = chartData['data'] as List<PemakaianBbm>;
    final totalLiter = chartData['totalLiter'] as double;
    final totalCost = chartData['totalCost'] as double;
    final avgDaily = chartData['avgDaily'] as double;
    final periodLabel = chartData['periodLabel'] as String;
    final bars = _buildBars(data);
    final hasPeriodData = bars.any((bar) => bar.value > 0);

    return ScaleTransition(
      scale: _scaleAnimation,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Grafik Pemakaian BBM',
                        style: GoogleFonts.poppins(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$periodLabel • ${_selectedMetric == 'liter' ? 'Liter' : 'Rupiah'}',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  // Icon
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.bar_chart_rounded,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Period selector
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  children: [
                    _buildPeriodButton('7 Hari', '7days'),
                    const SizedBox(width: 3),
                    _buildPeriodButton('30 Hari', '30days'),
                    const SizedBox(width: 3),
                    _buildPeriodButton('Bulan Ini', 'month'),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // Metrik grafik
              Row(
                children: [
                  Text(
                    'Tampilkan',
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildMetricButton('Liter', 'liter'),
                        const SizedBox(width: 2),
                        _buildMetricButton('Rupiah', 'cost'),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Chart representation
              if (!hasPeriodData)
                Container(
                  height: 150,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.bar_chart_outlined,
                        size: 40,
                        color: AppColors.border,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'Belum ada data pemakaian BBM',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Grafik akan muncul setelah ada transaksi tercatat.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Column(
                  children: [
                    _buildBarChart(bars),
                    const SizedBox(height: 16),
                    // Stats grid
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Total Liter',
                            '${totalLiter.toStringAsFixed(1)} L',
                            Icons.local_gas_station,
                            AppColors.primary,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatItem(
                            'Total Biaya',
                            NumberFormat.currency(
                              locale: 'id_ID',
                              symbol: 'Rp ',
                              decimalDigits: 0,
                            ).format(totalCost),
                            Icons.attach_money,
                            AppColors.accentYellow,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: _buildStatItem(
                            'Rata-rata/Hari',
                            '${avgDaily.toStringAsFixed(1)} L',
                            Icons.trending_up,
                            AppColors.success,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _buildStatItem(
                            'Jumlah Isi',
                            '${data.length}x',
                            Icons.receipt_long,
                            AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPeriodButton(String label, String value) {
    final isSelected = _selectedPeriod == value;
    return Expanded(
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _selectPeriod(value),
          borderRadius: BorderRadius.circular(7),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 7),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.primary : Colors.transparent,
              borderRadius: BorderRadius.circular(7),
            ),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.poppins(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textSecondary,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricButton(String label, String value) {
    final isSelected = _selectedMetric == value;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _selectMetric(value),
        borderRadius: BorderRadius.circular(6),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
          ),
          child: Text(
            label,
            style: GoogleFonts.poppins(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isSelected ? Colors.white : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBarChart(List<_BarData> bars) {
    var maxValue = 0.0;
    for (final bar in bars) {
      if (bar.value > maxValue) maxValue = bar.value;
    }
    if (maxValue <= 0) maxValue = 1;

    return SizedBox(
      height: 150,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: bars.map((bar) {
          final ratio = (bar.value / maxValue).clamp(0.0, 1.0);
          final isMax = bar.value > 0 && bar.value == maxValue;
          final gap = bars.length > 5 ? 3.0 : 6.0;

          return Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: gap),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      _compactValue(bar.value),
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w600,
                        color: isMax
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    height: 100 * ratio + (bar.value > 0 ? 3 : 0),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          AppColors.primary,
                          AppColors.primary.withValues(
                            alpha: isMax ? 0.7 : 0.45,
                          ),
                        ],
                      ),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(6),
                      ),
                    ),
                  ),
                  const SizedBox(height: 5),
                  SizedBox(
                    height: 14,
                    child: Text(
                      bar.label,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 9,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _compactValue(double value) {
    if (value <= 0) return '0';

    if (_selectedMetric == 'cost') {
      if (value >= 1000000) {
        return '${(value / 1000000).toStringAsFixed(value >= 10000000 ? 0 : 1)}jt';
      }
      if (value >= 1000) {
        return '${(value / 1000).toStringAsFixed(0)}rb';
      }
      return value.toStringAsFixed(0);
    }

    if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(1)}rb';
    }
    return value.toStringAsFixed(value >= 10 ? 0 : 1);
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.15), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BarData {
  final String label;
  final double value;

  const _BarData(this.label, this.value);
}
